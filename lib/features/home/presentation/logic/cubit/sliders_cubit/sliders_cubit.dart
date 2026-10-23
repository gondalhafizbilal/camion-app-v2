import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/data/models/slider_items/slider_item_model.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'sliders_state.dart';

class SlidersCubit extends Cubit<SlidersState> {
  SlidersCubit(this.homeRepository) : super(SlidersInitial());
  final HomeRepository homeRepository;
  static final Map<String, List<SliderItemModel>> _slidersCacheByLanguage = {};
  Future<void>? _inFlightRequest;
  String? _inFlightLanguage;

  void clearCache() {
    _slidersCacheByLanguage.clear();
    _inFlightRequest = null;
    _inFlightLanguage = null;
  }

  Future<void> getSliders({
    required String locale,
    bool forceRefresh = false,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final language = locale.split('-').first;
    final cached = _slidersCacheByLanguage[language];
    if (!forceRefresh && cached != null) {
      if (!isClosed) {
        emit(GetAllSlidersLoaded(slidersList: cached));
      }
      return;
    }
    if (!forceRefresh &&
        _inFlightRequest != null &&
        _inFlightLanguage == language) {
      await _inFlightRequest;
      return;
    }
    final request = _loadSliders(
      token: token,
      language: language,
      forceRefresh: forceRefresh,
    );
    _inFlightLanguage = language;
    _inFlightRequest = request;
    try {
      await request;
    } finally {
      if (identical(_inFlightRequest, request)) {
        _inFlightRequest = null;
        _inFlightLanguage = null;
      }
    }
  }

  Future<void> _loadSliders({
    required String? token,
    required String language,
    required bool forceRefresh,
  }) async {
    if (isClosed) return;
    emit(GetAllSlidersLoading());
    final result = await homeRepository.getGraphqlBanners(
      token: token,
      language: language,
      placement: 'homepage',
      forceRefresh: forceRefresh,
    );
    if (isClosed) return;
    result.fold(
      (error) {
        emit(GetAllSlidersError(error: error));
      },
      (sliders) {
        _slidersCacheByLanguage[language] = sliders;
        emit(GetAllSlidersLoaded(slidersList: sliders));
      },
    );
  }
}
