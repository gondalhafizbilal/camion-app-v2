import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/data/models/stories_model.dart/stories_model.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'stories_state.dart';

class StoriesCubit extends Cubit<StoriesState> {
  StoriesCubit(this.homeRepository) : super(StoriesInitial());
  final HomeRepository homeRepository;
  static final Map<String, List<StoriesModel>> _storiesCacheByLanguage = {};
  Future<void>? _inFlightRequest;
  String? _inFlightLanguage;

  void clearCache() {
    _storiesCacheByLanguage.clear();
    _inFlightRequest = null;
    _inFlightLanguage = null;
  }

  Future<void> getStories({
    required String locale,
    bool forceRefresh = false,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final language = locale.split('-').first;
    final cached = _storiesCacheByLanguage[language];
    if (!forceRefresh && cached != null) {
      if (!isClosed) {
        emit(StoriesLoaded(storiesList: cached));
      }
      return;
    }
    if (!forceRefresh &&
        _inFlightRequest != null &&
        _inFlightLanguage == language) {
      await _inFlightRequest;
      return;
    }
    final request = _loadStories(
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

  Future<void> _loadStories({
    required String? token,
    required String language,
    required bool forceRefresh,
  }) async {
    if (isClosed) return;
    emit(StoriesLoading());
    final result = await homeRepository.getGraphqlStories(
      token: token,
      language: language,
      forceRefresh: forceRefresh,
    );
    result.fold(
      (error) {
        if (!isClosed) {
          emit(StoriesError(error: error));
        }
      },
      (stories) {
        if (!isClosed) {
          _storiesCacheByLanguage[language] = stories;
          emit(StoriesLoaded(storiesList: stories));
        }
      },
    );
  }

  Future<void> getStoryById({required String id}) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (isClosed) return;
    emit(StoriesIdLoading());
    final result = await homeRepository.getStoryById(id: id, token: token!);
    result.fold(
      (error) {
        if (!isClosed) {
          emit(StoriesIdError(error: error));
        }
      },
      (story) {
        if (!isClosed) {
          emit(StoriesIdLoaded(storiesModel: story));
        }
      },
    );
  }
}
