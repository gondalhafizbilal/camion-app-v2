import 'package:camion/core/services/app_update_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/services/startup_gate_service.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/routing/router_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  static const bool _showPopupForDesignTesting = false;

  final AppUpdateService _updateService = AppUpdateService(cacheHelper: sl());
  final StartupGateService _startupGate = sl<StartupGateService>();

  bool _checking = false;
  bool _dialogVisible = false;
  bool _performingImmediateUpdate = false;
  String? _promptedSignature;

  void _trace(String message) {
    appDebugPrint('[UPDATE_FLOW][GATE] $message');
    appLog('[UPDATE_FLOW][GATE] $message');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _evaluateStartupUpdate();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_checking || _dialogVisible || _performingImmediateUpdate) return;
    _trace('APP_RESUMED recheck=true');
    _evaluateStartupUpdate();
  }

  Future<void> _evaluateStartupUpdate() async {
    if (!mounted || _checking) return;
    _checking = true;
    _trace('EVALUATE_START');

    try {
      final decision = await _updateService.evaluate();
      if (!mounted) return;

      final effectiveDecision =
          !decision.hasUpdate && _showPopupForDesignTesting
          ? AppUpdateDecision(
              isProduction: decision.isProduction,
              platformName: decision.platformName,
              currentVersion: decision.currentVersion,
              currentBuildNumber: decision.currentBuildNumber,
              currentPackageName: decision.currentPackageName,
              hasUpdate: true,
              forceUpdate: false,
              canSkip: defaultTargetPlatform == TargetPlatform.iOS,
              immediateUpdateAllowed: false,
              storeVersion: decision.storeVersion ?? 'Design preview',
              storeLink: decision.storeLink,
              availableVersionCode: decision.availableVersionCode,
              releaseNotes: decision.releaseNotes,
              usedCacheFallback: decision.usedCacheFallback,
              updateCheckFailed: decision.updateCheckFailed,
            )
          : decision;

      if (!effectiveDecision.hasUpdate) {
        _promptedSignature = null;
        _startupGate.release();
        _trace(
          'POPUP_DECISION show=false reason=no_update local=${decision.currentVersion}+${decision.currentBuildNumber} store=${decision.storeVersion ?? "unknown"}',
        );
        return;
      }

      if (!decision.hasUpdate && _showPopupForDesignTesting) {
        _trace(
          'POPUP_DECISION override=true reason=design_testing local=${decision.currentVersion}+${decision.currentBuildNumber}',
        );
      }

      final signature = _signatureFor(effectiveDecision);
      if (_promptedSignature == signature) {
        _trace(
          'POPUP_DECISION show=false reason=already_prompted signature=$signature',
        );
        return;
      }

      _promptedSignature = signature;
      _trace(
        'POPUP_DECISION show=true platform=${defaultTargetPlatform.name} signature=$signature immediateAllowed=${effectiveDecision.immediateUpdateAllowed} forceUpdate=${effectiveDecision.forceUpdate} local=${effectiveDecision.currentVersion}+${effectiveDecision.currentBuildNumber} store=${effectiveDecision.storeVersion ?? "unknown"} playVersionCode=${effectiveDecision.availableVersionCode?.toString() ?? "unknown"}',
      );
      await _showUpdateDialog(effectiveDecision);
    } finally {
      _checking = false;
      _trace('EVALUATE_END');
    }
  }

  String _signatureFor(AppUpdateDecision decision) {
    return [
      defaultTargetPlatform.name,
      decision.storeVersion ?? '',
      decision.availableVersionCode?.toString() ?? '',
      decision.currentVersion,
      decision.currentBuildNumber,
    ].join('|');
  }

  BuildContext? get _dialogContext =>
      RouterGenerator.mainRouting.routerDelegate.navigatorKey.currentContext ??
      AppToast.messengerKey.currentContext;

  Future<void> _showUpdateDialog(AppUpdateDecision decision) async {
    final dialogContext = _dialogContext;
    if (dialogContext == null) {
      _trace('POPUP_SHOW_ABORTED reason=no_dialog_context');
      return;
    }

    _dialogVisible = true;
    _trace('POPUP_SHOWING platform=${defaultTargetPlatform.name}');
    try {
      await showDialog<void>(
        context: dialogContext,
        barrierDismissible: defaultTargetPlatform == TargetPlatform.iOS,
        builder: (context) {
          final copy = _UpdateCopy.of(context);
          if (defaultTargetPlatform == TargetPlatform.iOS) {
            return _IosUpdateDialog(
              copy: copy,
              decision: decision,
              onUpdateNow: () => _handleIosUpdateNow(context, decision),
              onSkip: () => _handleIosSkip(context, decision),
            );
          }

          return _AndroidUpdateDialog(
            copy: copy,
            decision: decision,
            onUpdateNow: () => _handleAndroidUpdateNow(context, decision),
          );
        },
      );
    } finally {
      _dialogVisible = false;
      _trace('POPUP_DISMISSED platform=${defaultTargetPlatform.name}');
    }
  }

  Future<void> _handleAndroidUpdateNow(
    BuildContext context,
    AppUpdateDecision decision,
  ) async {
    _promptedSignature = null;
    _trace(
      'ANDROID_ACTION update_now_clicked immediateAllowed=${decision.immediateUpdateAllowed}',
    );
    Navigator.of(context).pop();

    if (decision.immediateUpdateAllowed) {
      await _runAndroidImmediateUpdate(decision);
      return;
    }

    _trace('ANDROID_ACTION fallback=open_store reason=immediate_not_available');
    await _openStore(decision);
  }

  Future<void> _runAndroidImmediateUpdate(AppUpdateDecision decision) async {
    _performingImmediateUpdate = true;
    _trace('ANDROID_IMMEDIATE_START');
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      _trace('ANDROID_IMMEDIATE_RESULT result=$result');

      if (result != AppUpdateResult.success) {
        _trace('ANDROID_ACTION fallback=open_store reason=immediate_failed');
        await _openStore(decision);
      } else {
        _startupGate.release();
      }
    } catch (error, stackTrace) {
      appLog(
        '[UPDATE_FLOW][GATE] ANDROID_IMMEDIATE_FAILED error=$error',
        error: error,
        stackTrace: stackTrace,
      );
      _trace('ANDROID_ACTION fallback=open_store reason=immediate_exception');
      await _openStore(decision);
    } finally {
      _performingImmediateUpdate = false;
      _trace('ANDROID_IMMEDIATE_END');
    }
  }

  Future<void> _handleIosUpdateNow(
    BuildContext context,
    AppUpdateDecision decision,
  ) async {
    _promptedSignature = null;
    _trace('IOS_ACTION update_now_clicked');
    Navigator.of(context).pop();
    await _openStore(decision);
  }

  Future<void> _handleIosSkip(
    BuildContext context,
    AppUpdateDecision decision,
  ) async {
    await _updateService.markIosVersionSkipped(decision.storeVersion);
    if (!context.mounted) return;
    _trace('IOS_ACTION skip_clicked store=${decision.storeVersion ?? "unknown"}');
    Navigator.of(context).pop();
    _startupGate.release();
  }

  Future<void> _openStore(AppUpdateDecision decision) async {
    final link = decision.storeLink;
    if (link == null || link.trim().isEmpty) {
      _trace('STORE_OPEN failed reason=empty_link');
      await AppToast.show(msg: 'Store link is unavailable right now.');
      return;
    }

    final uri = Uri.tryParse(link.trim());
    if (uri == null) {
      _trace('STORE_OPEN failed reason=invalid_uri link=$link');
      await AppToast.show(msg: 'Could not open the store link.');
      return;
    }

    final launched =
        await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    _trace('STORE_OPEN launched=$launched link=$link');
    if (!launched) {
      await AppToast.show(msg: 'Could not open the store right now.');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AndroidUpdateDialog extends StatelessWidget {
  const _AndroidUpdateDialog({
    required this.copy,
    required this.decision,
    required this.onUpdateNow,
  });

  final _UpdateCopy copy;
  final AppUpdateDecision decision;
  final VoidCallback onUpdateNow;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(copy.updateAvailableTitle),
        content: Text(
          _buildMessage(
            copy: copy,
            platform: copy.googlePlayLabel,
            currentVersion: decision.currentVersion,
            currentCode: decision.currentBuildNumber,
            storeVersion: decision.storeVersion,
            storeCode: decision.availableVersionCode?.toString(),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: onUpdateNow,
            child: Text(copy.updateNowLabel),
          ),
        ],
      ),
    );
  }
}

class _IosUpdateDialog extends StatelessWidget {
  const _IosUpdateDialog({
    required this.copy,
    required this.decision,
    required this.onUpdateNow,
    required this.onSkip,
  });

  final _UpdateCopy copy;
  final AppUpdateDecision decision;
  final VoidCallback onUpdateNow;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(copy.updateAvailableTitle),
      content: Text(
        _buildMessage(
          copy: copy,
          platform: copy.appStoreLabel,
          currentVersion: decision.currentVersion,
          currentCode: decision.currentBuildNumber,
          storeVersion: decision.storeVersion,
          storeCode: decision.availableVersionCode?.toString(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: onSkip,
          child: Text(copy.skipLabel),
        ),
        FilledButton(
          onPressed: onUpdateNow,
          child: Text(copy.updateNowLabel),
        ),
      ],
    );
  }
}

String _buildMessage({
  required _UpdateCopy copy,
  required String platform,
  required String currentVersion,
  required String currentCode,
  required String? storeVersion,
  required String? storeCode,
}) {
  final normalizedStoreVersion =
      (storeVersion == null || storeVersion.trim().isEmpty)
      ? 'latest'
      : storeVersion.trim();
  final normalizedStoreCode =
      (storeCode == null || storeCode.trim().isEmpty) ? 'N/A' : storeCode.trim();
  return copy.buildBody(
    platform: platform,
    currentVersion: currentVersion.trim(),
    currentCode: currentCode.trim(),
    storeVersion: normalizedStoreVersion,
    storeCode: normalizedStoreCode,
  );
}

class _UpdateCopy {
  const _UpdateCopy({
    required this.updateAvailableTitle,
    required this.updateNowLabel,
    required this.skipLabel,
    required this.googlePlayLabel,
    required this.appStoreLabel,
    required this.currentLabel,
    required this.storeLabel,
    required this.bodyTemplate,
  });

  final String updateAvailableTitle;
  final String updateNowLabel;
  final String skipLabel;
  final String googlePlayLabel;
  final String appStoreLabel;
  final String currentLabel;
  final String storeLabel;
  final String Function(
    String platform,
    String currentVersion,
    String currentCode,
    String storeVersion,
    String storeCode,
  )
  bodyTemplate;

  static _UpdateCopy of(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode
        .toLowerCase()
        .startsWith('ar');
    if (isArabic) {
      return _UpdateCopy(
        updateAvailableTitle: 'يوجد تحديث جديد',
        updateNowLabel: 'حدّث الآن',
        skipLabel: 'تخطي',
        googlePlayLabel: 'Google Play',
        appStoreLabel: 'App Store',
        currentLabel: 'الإصدار الحالي',
        storeLabel: 'إصدار المتجر',
        bodyTemplate:
            (platform, currentVersion, currentCode, storeVersion, storeCode) =>
                'يوجد إصدار أحدث على $platform.\n\nالإصدار الحالي: $currentVersion\nرمز الإصدار الحالي: $currentCode\nإصدار المتجر: $storeVersion\nرمز الإصدار في المتجر: $storeCode',
      );
    }
    return _UpdateCopy(
      updateAvailableTitle: 'Update available',
      updateNowLabel: 'Update now',
      skipLabel: 'Skip',
      googlePlayLabel: 'Google Play',
      appStoreLabel: 'App Store',
      currentLabel: 'Current',
      storeLabel: 'Store',
      bodyTemplate:
          (platform, currentVersion, currentCode, storeVersion, storeCode) =>
              'A newer version is available on $platform.\n\nCurrent version: $currentVersion\nCurrent code: $currentCode\nStore version: $storeVersion\nStore code: $storeCode',
    );
  }

  String buildBody({
    required String platform,
    required String currentVersion,
    required String currentCode,
    required String storeVersion,
    required String storeCode,
  }) => bodyTemplate(
    platform,
    currentVersion,
    currentCode,
    storeVersion,
    storeCode,
  );
}
