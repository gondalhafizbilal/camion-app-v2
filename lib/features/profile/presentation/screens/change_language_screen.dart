import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangeLanguageScreen extends StatefulWidget {
  const ChangeLanguageScreen({super.key});

  @override
  State<ChangeLanguageScreen> createState() => _ChangeLanguageScreenState();
}

class _ApiLanguage {
  const _ApiLanguage({required this.code, required this.name});

  final String code;
  final String name;
}

class _ChangeLanguageScreenState extends State<ChangeLanguageScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<_ApiLanguage> _languages = const [];
  String? _pendingLanguageCode;
  final TextEditingController _searchController = TextEditingController();
  bool _searchVisible = false;
  String _searchQuery = '';

  String _tr(BuildContext context, {required String en, required String ar}) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'ar'
        ? ar
        : en;
  }

  @override
  void initState() {
    super.initState();
    _fetchLanguages();
  }

  Future<void> _fetchLanguages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      final result = await sl<HomeRepository>().getLanguagesGraphql(
        token: token,
      );
      final supportedCodes = S.delegate.supportedLocales
          .map((locale) => locale.languageCode.toLowerCase())
          .toSet();

      final parsed = result
          .fold(
            (_) => <_ApiLanguage>[],
            (graphqlLanguages) => graphqlLanguages
                .map(
                  (lang) => _ApiLanguage(code: lang.shortCode, name: lang.name),
                )
                .toList(),
          )
          .where(
            (lang) =>
                lang.code.isNotEmpty &&
                lang.name.isNotEmpty &&
                supportedCodes.contains(lang.code),
          )
          .toList();

      final byCode = <String, _ApiLanguage>{
        for (final lang in parsed) lang.code: lang,
      };
      byCode.putIfAbsent(
        'en',
        () => const _ApiLanguage(code: 'en', name: 'English'),
      );
      byCode.putIfAbsent(
        'ar',
        () => const _ApiLanguage(code: 'ar', name: 'Arabic'),
      );

      if (!mounted) return;
      setState(() {
        _languages = byCode.isEmpty
            ? _fallbackLanguages()
            : byCode.values.toList();
        _pendingLanguageCode ??= context
            .read<LocalizationsCubit>()
            .state
            .languageCode
            .toLowerCase();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = null;
        _languages = _fallbackLanguages();
        _pendingLanguageCode ??= context
            .read<LocalizationsCubit>()
            .state
            .languageCode
            .toLowerCase();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ApiLanguage> _fallbackLanguages() {
    return const <_ApiLanguage>[
      _ApiLanguage(code: 'en', name: 'English'),
      _ApiLanguage(code: 'ar', name: 'Arabic'),
    ];
  }

  Future<void> _onSelectLanguage(String code) async {
    setState(() => _pendingLanguageCode = code);
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  Future<void> _saveLanguage() async {
    if (_saving) return;
    final selectedCode = _pendingLanguageCode;
    if (selectedCode == null || selectedCode.isEmpty) return;

    final currentCode = context
        .read<LocalizationsCubit>()
        .state
        .languageCode
        .toLowerCase();
    if (selectedCode == currentCode) {
      AppNavigator.safePop(context);
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<LocalizationsCubit>().changeLocale(
        locale: Locale(selectedCode),
      );
      if (!mounted) return;
      AppNavigator.safePop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              context,
              en: 'Something went wrong. Please try again.',
              ar: 'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _localizedLanguageName(BuildContext context, _ApiLanguage language) {
    switch (language.code) {
      case 'ar':
        return S.of(context).arabic;
      case 'en':
        return S.of(context).english;
      case 'de':
        return S.of(context).german;
      case 'fr':
        return S.of(context).french;
      case 'es':
        return S.of(context).spanish;
      case 'it':
        return S.of(context).italian;
      case 'bn':
        return S.of(context).bengali;
      case 'nl':
        return S.of(context).dutch;
      case 'hi':
        return S.of(context).hindi;
      case 'id':
        return S.of(context).indonesian;
      case 'ja':
        return S.of(context).japanese;
      case 'jv':
        return S.of(context).javanese;
      case 'ko':
        return S.of(context).korean;
      case 'ms':
        return S.of(context).malay;
      case 'zh':
        return S.of(context).mandarin_chinese;
      case 'mr':
        return S.of(context).marathi;
      case 'fa':
        return S.of(context).persian;
      case 'pl':
        return S.of(context).polish;
      case 'pt':
        return S.of(context).portuguese;
      case 'pa':
        return S.of(context).punjabi;
      case 'ro':
        return S.of(context).romanian;
      case 'ru':
        return S.of(context).russian;
      case 'sw':
        return S.of(context).swahili;
      case 'ta':
        return S.of(context).tamil;
      case 'te':
        return S.of(context).telugu;
      case 'th':
        return S.of(context).thai;
      case 'tr':
        return S.of(context).turkish;
      case 'uk':
        return S.of(context).ukrainian;
      case 'ur':
        return S.of(context).urdu;
      case 'vi':
        return S.of(context).vietnamese;
      default:
        return language.name;
    }
  }

  List<_ApiLanguage> _filteredLanguages(BuildContext context) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _languages;
    return _languages.where((item) {
      final localized = _localizedLanguageName(context, item).toLowerCase();
      return localized.contains(q) ||
          item.name.toLowerCase().contains(q) ||
          item.code.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCode =
        _pendingLanguageCode ??
        context.watch<LocalizationsCubit>().state.languageCode.toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              Row(
                children: [
                  Opacity(
                    opacity: 0.8,
                    child: SizedBox(
                      width: 40.w,
                      height: 40.h,
                      child: AppTapFeedback(
                        onTap: () => AppNavigator.safePop(context),
                        customBorder: const CircleBorder(),
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.black,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      S.of(context).language,
                      style: AppStyle.styleAppBarTitle20Medium(context),
                    ),
                  ),
                  Opacity(
                    opacity: 0.8,
                    child: SizedBox(
                      width: 40.w,
                      height: 40.h,
                      child: AppTapFeedback(
                        onTap: _toggleSearch,
                        customBorder: const CircleBorder(),
                        child: _searchVisible
                            ? Icon(
                                Icons.close,
                                color: AppColors.primaryColor,
                                size: 24.sp,
                              )
                            : Image.asset(
                                'assets/images/searchicon.png',
                                width: 40.w,
                                height: 40.h,
                                fit: BoxFit.contain,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_searchVisible) ...[
                SizedBox(height: 8.h),
                SizedBox(
                  height: 40.h,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText:
                          '${S.of(context).search} ${S.of(context).language}',
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: Color(0xFFE3E7EE)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: Color(0xFFE3E7EE)),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 28.h),
              Text(
                _tr(
                  context,
                  en: 'Select Your Language',
                  ar: 'اختر لغتك',
                ),
                style: AppStyle.styleSectionTitle16Medium(context),
              ),
              SizedBox(height: 18.h),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      )
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: AppStyle.styleRegular16(
                                context,
                              ).copyWith(color: Colors.red),
                            ),
                            SizedBox(height: 12.h),
                            ElevatedButton(
                              onPressed: _fetchLanguages,
                              child: Text(S.of(context).retry),
                            ),
                          ],
                        ),
                      )
                    : _filteredLanguages(context).isEmpty
                    ? Center(
                        child: Text(
                          _tr(
                            context,
                            en: 'No matching languages found',
                            ar: 'لا توجد لغات مطابقة',
                          ),
                          style: AppStyle.styleRegular16(
                            context,
                          ).copyWith(color: Colors.black54),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredLanguages(context).length,
                        separatorBuilder: (_, __) => SizedBox(height: 6.h),
                        itemBuilder: (context, index) {
                          final item = _filteredLanguages(context)[index];
                          final isSelected = selectedCode == item.code;
                          return InkWell(
                            onTap: () => _onSelectLanguage(item.code),
                            borderRadius: BorderRadius.circular(8.r),
                            child: Container(
                              width: double.infinity,
                              height: 56.h,
                              padding: EdgeInsets.fromLTRB(
                                12.w,
                                8.h,
                                12.w,
                                8.h,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _localizedLanguageName(context, item),
                                      style: TextStyle(
                                        fontFamily: 'Montes',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16.sp,
                                        height: 1.5,
                                        color: isSelected
                                            ? AppColors.primaryColor
                                            : AppColors.black,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      width: 24.w,
                                      height: 24.w,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16.sp,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveLanguage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          S.of(context).save,
                          style: TextStyle(
                            fontFamily: 'Montes',
                            fontWeight: FontWeight.w600,
                            fontSize: 18.sp,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }
}
