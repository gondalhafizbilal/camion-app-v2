import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'category_feed_state.dart';

class CategoryFeedCubit extends Cubit<CategoryFeedState> {
  CategoryFeedCubit(this.homeRepository) : super(CategoryFeedInitial());

  final HomeRepository homeRepository;
  static final Map<String, HomeGraphqlCategoryFeedData> _feedCacheByLanguage =
      {};

  Future<void> getCategoryFeed({
    required String locale,
    bool forceRefresh = false,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final language = locale.split('-').first;
    final cached = _feedCacheByLanguage[language];
    if (!forceRefresh && cached != null) {
      if (!isClosed) {
        emit(CategoryFeedLoaded(feed: cached));
      }
      return;
    }
    if (isClosed) return;
    emit(CategoryFeedLoading());
    final result = await homeRepository.getCategoryFeedGraphql(
      token: token,
      language: language,
      placement: 'all-categories-mobile',
    );
    if (isClosed) return;
    result.fold((error) => emit(CategoryFeedError(error: error)), (feed) {
      _feedCacheByLanguage[language] = feed;
      emit(CategoryFeedLoaded(feed: feed));
    });
  }
}
