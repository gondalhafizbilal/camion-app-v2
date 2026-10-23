import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'home_categories_state.dart';

class HomeCategoriesCubit extends Cubit<HomeCategoriesState> {
  HomeCategoriesCubit(this.homeRepository) : super(HomeCategoriesInitial());

  final HomeRepository homeRepository;
  static final Map<String, List<HomeGraphqlCategory>>
  _categoriesCacheByLanguage = {};
  Future<void>? _inFlightRequest;
  String? _inFlightLanguage;

  void clearCache() {
    _categoriesCacheByLanguage.clear();
    _inFlightRequest = null;
    _inFlightLanguage = null;
  }

  Future<void> getCategories({
    required String locale,
    bool forceRefresh = false,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final language = locale.split('-').first;
    final cached = _categoriesCacheByLanguage[language];
    if (!forceRefresh && cached != null) {
      if (!isClosed) {
        emit(HomeCategoriesLoaded(categories: cached));
      }
      return;
    }
    if (!forceRefresh &&
        _inFlightRequest != null &&
        _inFlightLanguage == language) {
      await _inFlightRequest;
      return;
    }
    final request = _loadCategories(
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

  Future<void> _loadCategories({
    required String? token,
    required String language,
    required bool forceRefresh,
  }) async {
    if (isClosed) return;
    emit(HomeCategoriesLoading());
    final result = await homeRepository.getGraphqlCategories(
      token: token,
      language: language,
      forceRefresh: forceRefresh,
    );
    result.fold(
      (error) {
        if (!isClosed) {
          emit(HomeCategoriesError(error: error));
        }
      },
      (categories) {
        if (!isClosed) {
          _categoriesCacheByLanguage[language] = categories;
          emit(HomeCategoriesLoaded(categories: categories));
        }
      },
    );
  }
}
