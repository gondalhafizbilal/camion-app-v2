import 'dart:io';

import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:new_version_plus/model/version_status.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateDecision {
  const AppUpdateDecision({
    required this.isProduction,
    required this.platformName,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.currentPackageName,
    required this.hasUpdate,
    required this.forceUpdate,
    required this.canSkip,
    required this.immediateUpdateAllowed,
    required this.storeVersion,
    required this.storeLink,
    required this.availableVersionCode,
    required this.releaseNotes,
    required this.usedCacheFallback,
    required this.updateCheckFailed,
  });

  final bool isProduction;
  final String platformName;
  final String currentVersion;
  final String currentBuildNumber;
  final String currentPackageName;
  final bool hasUpdate;
  final bool forceUpdate;
  final bool canSkip;
  final bool immediateUpdateAllowed;
  final String? storeVersion;
  final String? storeLink;
  final int? availableVersionCode;
  final String? releaseNotes;
  final bool usedCacheFallback;
  final bool updateCheckFailed;
}

class AppUpdateService {
  AppUpdateService({required this.cacheHelper});

  static const Duration _androidPlayCheckTimeout = Duration(seconds: 10);
  static const Duration _androidStoreLookupTimeout = Duration(seconds: 10);
  static const Duration _iosStoreLookupTimeout = Duration(seconds: 10);

  static const String _cacheStoreVersionKey = 'startupStoreVersionV1';
  static const String _cacheStoreLinkKey = 'startupStoreLinkV1';
  static const String _cacheReleaseNotesKey = 'startupReleaseNotesV1';
  static const String _cacheAvailableVersionCodeKey =
      'startupAvailableVersionCodeV1';
  static const String _cacheCheckedAtKey = 'startupStoreCheckedAtV1';
  static const String _cacheSkippedIosVersionKey = 'startupSkippedIosVersionV1';

  final CacheHelper cacheHelper;

  String _platformCacheSuffix(String platformName) =>
      platformName.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  String _platformCacheKey(String baseKey, String platformName) =>
      '${baseKey}_${_platformCacheSuffix(platformName)}';

  void _trace(String message) {
    appDebugPrint('[UPDATE_FLOW][SERVICE] $message');
    appLog('[UPDATE_FLOW][SERVICE] $message');
  }

  Future<AppUpdateDecision> evaluate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final isProduction = AppConfig.instance.flavor == AppFlavor.production;
    final platformName = Platform.operatingSystem;
    final currentVersion = packageInfo.version.trim();
    final currentBuildNumber = packageInfo.buildNumber.trim();
    final currentPackageName = packageInfo.packageName.trim();

    _trace(
      'CHECK_START package=$currentPackageName localVersion=$currentVersion localBuild=$currentBuildNumber platform=$platformName production=$isProduction',
    );

    if (!isProduction) {
      _trace('CHECK_RESULT showPopup=false reason=non_production_build');
      return AppUpdateDecision(
        isProduction: false,
        platformName: platformName,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        currentPackageName: currentPackageName,
        hasUpdate: false,
        forceUpdate: false,
        canSkip: false,
        immediateUpdateAllowed: false,
        storeVersion: null,
        storeLink: null,
        availableVersionCode: null,
        releaseNotes: null,
        usedCacheFallback: false,
        updateCheckFailed: false,
      );
    }

    final liveDecision = await _fetchLiveDecision(
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      currentPackageName: currentPackageName,
      platformName: platformName,
    );
    if (liveDecision != null) {
      await _cacheDecision(liveDecision);
      _trace(
        'CHECK_RESULT source=live showPopup=${liveDecision.hasUpdate} storeVersion=${liveDecision.storeVersion ?? "unknown"} playVersionCode=${liveDecision.availableVersionCode?.toString() ?? "unknown"} immediateAllowed=${liveDecision.immediateUpdateAllowed} forceUpdate=${liveDecision.forceUpdate}',
      );
      return liveDecision;
    }

    final cachedDecision = await _fallbackToCachedDecision(
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      currentPackageName: currentPackageName,
      platformName: platformName,
    );
    if (cachedDecision != null) {
      _trace(
        'CHECK_RESULT source=cache showPopup=${cachedDecision.hasUpdate} storeVersion=${cachedDecision.storeVersion ?? "unknown"} playVersionCode=${cachedDecision.availableVersionCode?.toString() ?? "unknown"} immediateAllowed=${cachedDecision.immediateUpdateAllowed} forceUpdate=${cachedDecision.forceUpdate}',
      );
      return cachedDecision;
    }

    _trace(
      'CHECK_RESULT source=none showPopup=false reason=no_live_or_cached_update_data',
    );
    return AppUpdateDecision(
      isProduction: true,
      platformName: platformName,
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      currentPackageName: currentPackageName,
      hasUpdate: false,
      forceUpdate: false,
      canSkip: false,
      immediateUpdateAllowed: false,
      storeVersion: null,
      storeLink: null,
      availableVersionCode: null,
      releaseNotes: null,
      usedCacheFallback: false,
      updateCheckFailed: true,
    );
  }

  Future<AppUpdateDecision?> _fetchLiveDecision({
    required String currentVersion,
    required String currentBuildNumber,
    required String currentPackageName,
    required String platformName,
  }) async {
    try {
      if (Platform.isAndroid) {
        return _fetchAndroidDecision(
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          currentPackageName: currentPackageName,
          platformName: platformName,
        );
      }
      if (Platform.isIOS) {
        return _fetchIosDecision(
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          currentPackageName: currentPackageName,
          platformName: platformName,
        );
      }
      _trace('CHECK_RESULT showPopup=false reason=unsupported_platform');
      return null;
    } catch (error, stackTrace) {
      appLog(
        '[UPDATE_FLOW][SERVICE] LIVE_CHECK_FAILED platform=$platformName error=$error',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<AppUpdateDecision?> _fetchAndroidDecision({
    required String currentVersion,
    required String currentBuildNumber,
    required String currentPackageName,
    required String platformName,
  }) async {
    AppUpdateInfo? playInfo;
    VersionStatus? versionStatus;

    try {
      playInfo = await InAppUpdate.checkForUpdate()
          .timeout(_androidPlayCheckTimeout);
    } catch (error, stackTrace) {
      appLog(
        '[UPDATE_FLOW][SERVICE] ANDROID_PLAY_API_FAILED error=$error',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      versionStatus = await NewVersionPlus(
        androidId: currentPackageName,
      ).getVersionStatus().timeout(_androidStoreLookupTimeout);
    } catch (error, stackTrace) {
      appLog(
        '[UPDATE_FLOW][SERVICE] ANDROID_STORE_LOOKUP_FAILED error=$error',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final storeVersion = versionStatus?.originalStoreVersion;
    final storeLink = _resolveAndroidStoreLink(
      packageName: currentPackageName,
      fromStore: versionStatus?.appStoreLink,
    );
    final releaseNotes = versionStatus?.releaseNotes;
    final availableVersionCode = playInfo?.availableVersionCode;
    final immediateAllowed = playInfo?.immediateUpdateAllowed ?? false;

    final buildNumber = int.tryParse(currentBuildNumber) ?? 0;
    final availableBuild = availableVersionCode ?? 0;
    final hasPlayUpdate =
        playInfo?.updateAvailability == UpdateAvailability.updateAvailable;
    final hasBuildUpdate = availableBuild > buildNumber;
    final hasStoreUpdate = versionStatus?.canUpdate ?? false;
    final hasLiveSignal =
        playInfo != null ||
        (storeVersion != null && storeVersion.trim().isNotEmpty) ||
        storeLink.trim().isNotEmpty;
    if (!hasLiveSignal) {
      _trace(
        'ANDROID_DECISION liveSignal=false localVersion=$currentVersion localBuild=$currentBuildNumber storeVersion=${storeVersion ?? "unknown"} playVersionCode=${availableVersionCode?.toString() ?? "unknown"} immediateAllowed=$immediateAllowed',
      );
      return null;
    }
    final hasUpdate = hasPlayUpdate || hasBuildUpdate || hasStoreUpdate;

    _trace(
      'ANDROID_DECISION liveSignal=true localVersion=$currentVersion localBuild=$currentBuildNumber storeVersion=${storeVersion ?? "unknown"} playVersionCode=${availableVersionCode?.toString() ?? "unknown"} hasPlayUpdate=$hasPlayUpdate hasBuildUpdate=$hasBuildUpdate hasStoreUpdate=$hasStoreUpdate immediateAllowed=$immediateAllowed showPopup=$hasUpdate',
    );

    return AppUpdateDecision(
      isProduction: true,
      platformName: platformName,
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      currentPackageName: currentPackageName,
      hasUpdate: hasUpdate,
      forceUpdate: hasUpdate && immediateAllowed,
      canSkip: false,
      immediateUpdateAllowed: immediateAllowed,
      storeVersion: storeVersion,
      storeLink: storeLink,
      availableVersionCode: availableVersionCode,
      releaseNotes: releaseNotes,
      usedCacheFallback: false,
      updateCheckFailed: false,
    );
  }

  Future<AppUpdateDecision?> _fetchIosDecision({
    required String currentVersion,
    required String currentBuildNumber,
    required String currentPackageName,
    required String platformName,
  }) async {
    final skippedVersion = _normalizedString(
      await cacheHelper.getData(key: _cacheSkippedIosVersionKey),
    );

    final versionStatus = await NewVersionPlus(
      iOSId: currentPackageName,
    ).getVersionStatus().timeout(_iosStoreLookupTimeout);

    final storeVersion = versionStatus?.originalStoreVersion;
    final storeLink = versionStatus?.appStoreLink;
    final releaseNotes = versionStatus?.releaseNotes;
    final hasLiveSignal =
        (storeVersion != null && storeVersion.trim().isNotEmpty) ||
        (storeLink != null && storeLink.trim().isNotEmpty);
    if (!hasLiveSignal) {
      _trace(
        'IOS_DECISION liveSignal=false localVersion=$currentVersion localBuild=$currentBuildNumber storeVersion=${storeVersion ?? "unknown"} skippedVersion=${skippedVersion.isEmpty ? "none" : skippedVersion}',
      );
      return null;
    }
    final hasUpdate = versionStatus?.canUpdate ?? false;
    final normalizedStoreVersion = _normalizedString(storeVersion);
    final skipMatchesCurrentStore =
        skippedVersion.isNotEmpty &&
        normalizedStoreVersion.isNotEmpty &&
        skippedVersion == normalizedStoreVersion;
    final effectiveHasUpdate = hasUpdate && !skipMatchesCurrentStore;

    _trace(
      'IOS_DECISION liveSignal=true localVersion=$currentVersion localBuild=$currentBuildNumber storeVersion=${storeVersion ?? "unknown"} skippedVersion=${skippedVersion.isEmpty ? "none" : skippedVersion} canUpdate=$hasUpdate showPopup=$effectiveHasUpdate',
    );

    return AppUpdateDecision(
      isProduction: true,
      platformName: platformName,
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      currentPackageName: currentPackageName,
      hasUpdate: effectiveHasUpdate,
      forceUpdate: false,
      canSkip: true,
      immediateUpdateAllowed: false,
      storeVersion: storeVersion,
      storeLink: storeLink,
      availableVersionCode: null,
      releaseNotes: releaseNotes,
      usedCacheFallback: false,
      updateCheckFailed: false,
    );
  }

  Future<void> _cacheDecision(AppUpdateDecision decision) async {
    final storeVersionKey = _platformCacheKey(
      _cacheStoreVersionKey,
      decision.platformName,
    );
    final storeLinkKey = _platformCacheKey(
      _cacheStoreLinkKey,
      decision.platformName,
    );
    final releaseNotesKey = _platformCacheKey(
      _cacheReleaseNotesKey,
      decision.platformName,
    );
    final availableVersionCodeKey = _platformCacheKey(
      _cacheAvailableVersionCodeKey,
      decision.platformName,
    );
    final checkedAtKey = _platformCacheKey(
      _cacheCheckedAtKey,
      decision.platformName,
    );

    if (decision.storeVersion != null && decision.storeVersion!.isNotEmpty) {
      await cacheHelper.saveData(
        key: storeVersionKey,
        value: decision.storeVersion!,
      );
    }
    if (decision.storeLink != null && decision.storeLink!.isNotEmpty) {
      await cacheHelper.saveData(
        key: storeLinkKey,
        value: decision.storeLink!,
      );
    }
    if (decision.releaseNotes != null && decision.releaseNotes!.isNotEmpty) {
      await cacheHelper.saveData(
        key: releaseNotesKey,
        value: decision.releaseNotes!,
      );
    }
    if (decision.availableVersionCode != null) {
      await cacheHelper.saveData(
        key: availableVersionCodeKey,
        value: decision.availableVersionCode!,
      );
    }
    await cacheHelper.saveData(
      key: checkedAtKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<AppUpdateDecision?> _fallbackToCachedDecision({
    required String currentVersion,
    required String currentBuildNumber,
    required String currentPackageName,
    required String platformName,
  }) async {
    final cacheSuffix = _platformCacheSuffix(platformName);
    final cachedStoreVersion = _normalizedString(
      cacheHelper.getDataString(
        key: '${_cacheStoreVersionKey}_$cacheSuffix',
      ),
    );
    final cachedStoreLink = _normalizedString(
      cacheHelper.getDataString(key: '${_cacheStoreLinkKey}_$cacheSuffix'),
    );
    final cachedReleaseNotes = cacheHelper.getDataString(
      key: '${_cacheReleaseNotesKey}_$cacheSuffix',
    );
    final cachedAvailableVersionCode = int.tryParse(
      (cacheHelper.getDataString(
            key: '${_cacheAvailableVersionCodeKey}_$cacheSuffix',
          ) ??
          '')
          .trim(),
    );

    if (cachedStoreVersion.isEmpty && cachedStoreLink.isEmpty) {
      return null;
    }

    var hasUpdate = cachedStoreVersion.isNotEmpty
        ? _isStoreVersionNewer(
            currentVersion: currentVersion,
            currentBuildNumber: currentBuildNumber,
            storeVersion: cachedStoreVersion,
            cachedAvailableVersionCode: cachedAvailableVersionCode,
          )
        : Platform.isAndroid &&
            cachedAvailableVersionCode != null &&
            cachedAvailableVersionCode >
                (int.tryParse(currentBuildNumber) ?? 0);

    if (Platform.isIOS && hasUpdate) {
      final skippedVersion = _normalizedString(
        await cacheHelper.getData(key: _cacheSkippedIosVersionKey),
      );
      if (skippedVersion.isNotEmpty && skippedVersion == cachedStoreVersion) {
        hasUpdate = false;
      }
    }
    _trace(
      'CACHE_DECISION localVersion=$currentVersion localBuild=$currentBuildNumber storeVersion=${cachedStoreVersion.isEmpty ? "unknown" : cachedStoreVersion} playVersionCode=${cachedAvailableVersionCode?.toString() ?? "unknown"} showPopup=$hasUpdate platform=$platformName',
    );

    return AppUpdateDecision(
      isProduction: true,
      platformName: platformName,
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      currentPackageName: currentPackageName,
      hasUpdate: hasUpdate,
      forceUpdate: Platform.isAndroid ? hasUpdate : false,
      canSkip: Platform.isIOS,
      immediateUpdateAllowed: false,
      storeVersion: cachedStoreVersion.isEmpty ? null : cachedStoreVersion,
      storeLink: cachedStoreLink.isEmpty
          ? (Platform.isAndroid
                ? _resolveAndroidStoreLink(packageName: currentPackageName)
                : null)
          : cachedStoreLink,
      availableVersionCode: cachedAvailableVersionCode,
      releaseNotes: cachedReleaseNotes,
      usedCacheFallback: true,
      updateCheckFailed: true,
    );
  }

  bool _isStoreVersionNewer({
    required String currentVersion,
    required String currentBuildNumber,
    required String storeVersion,
    required int? cachedAvailableVersionCode,
  }) {
    final currentParts = _parseSemanticVersion(currentVersion);
    final storeParts = _parseSemanticVersion(storeVersion);

    if (Platform.isAndroid && cachedAvailableVersionCode != null) {
      final currentBuild = int.tryParse(currentBuildNumber) ?? 0;
      if (cachedAvailableVersionCode > currentBuild) {
        return true;
      }
    }

    if (currentParts.isNotEmpty && storeParts.isNotEmpty) {
      final maxLength = currentParts.length > storeParts.length
          ? currentParts.length
          : storeParts.length;
      for (var index = 0; index < maxLength; index++) {
        final currentPart = index < currentParts.length
            ? currentParts[index]
            : 0;
        final storePart = index < storeParts.length ? storeParts[index] : 0;
        if (storePart > currentPart) return true;
        if (currentPart > storePart) return false;
      }
    }

    return false;
  }

  List<int> _parseSemanticVersion(String version) {
    final cleaned = version.trim();
    if (cleaned.isEmpty) return <int>[];
    final parts = cleaned.split('.');
    final parsed = <int>[];
    for (final part in parts) {
      final value = int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), ''));
      if (value == null) break;
      parsed.add(value);
    }
    return parsed;
  }

  Future<void> markIosVersionSkipped(String? storeVersion) async {
    final normalized = (storeVersion ?? '').trim();
    if (normalized.isEmpty) return;
    await cacheHelper.saveData(
      key: _cacheSkippedIosVersionKey,
      value: normalized,
    );
    _trace('IOS_SKIP_SAVED skippedVersion=$normalized');
  }

  Future<void> clearIosSkippedVersion() async {
    await cacheHelper.removeData(key: _cacheSkippedIosVersionKey);
  }

  Future<void> clearStartupCache() async {
    final keys = <String>[
      for (final platformName in <String>['android', 'ios']) ...[
        _platformCacheKey(_cacheStoreVersionKey, platformName),
        _platformCacheKey(_cacheStoreLinkKey, platformName),
        _platformCacheKey(_cacheReleaseNotesKey, platformName),
        _platformCacheKey(_cacheAvailableVersionCodeKey, platformName),
        _platformCacheKey(_cacheCheckedAtKey, platformName),
      ],
      _cacheSkippedIosVersionKey,
    ];

    for (final key in keys) {
      await cacheHelper.removeData(key: key);
    }

    _trace('CLEAR_STARTUP_CACHE completed');
  }

  String _normalizedString(Object? value) => value?.toString().trim() ?? '';

  String _resolveAndroidStoreLink({
    required String packageName,
    String? fromStore,
  }) {
    final normalizedStore = _normalizedString(fromStore);
    if (normalizedStore.isNotEmpty) {
      return normalizedStore;
    }
    final normalizedPackage = packageName.trim();
    if (normalizedPackage.isEmpty) {
      return '';
    }
    return 'market://details?id=$normalizedPackage';
  }
}
