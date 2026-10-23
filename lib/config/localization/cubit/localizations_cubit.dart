import 'dart:ui';

import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'localizations_state.dart';

class LocalizationsCubit extends Cubit<Locale> {
  LocalizationsCubit() : super(_initialLocale());

  static Locale _initialLocale() {
    final savedLangCode =
        sl<CacheHelper>().getData(key: 'languageCode') ??
        AppDefaults.defaultLanguageCode;
    return Locale(savedLangCode.toString());
  }

  Future<void> loadSavedLanguage() async {
    final savedLangCode =
        sl<CacheHelper>().getData(key: 'languageCode') ??
        AppDefaults.defaultLanguageCode;
    emit(Locale(savedLangCode));
  }

  Future<void> changeLocale({required Locale locale}) async {
    await sl<CacheHelper>().saveData(
      key: 'languageCode',
      value: locale.languageCode,
    );
    await sl<CacheHelper>().saveData(
      key: 'languageSelectionSourceV1',
      value: 'manual',
    );
    await sl<CacheHelper>().saveData(
      key: 'languageAutoResolvedV1',
      value: true,
    );
    emit(locale);
  }
}
