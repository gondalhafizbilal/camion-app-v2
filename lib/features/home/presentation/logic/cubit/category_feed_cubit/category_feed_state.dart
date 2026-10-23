part of 'category_feed_cubit.dart';

sealed class CategoryFeedState {}

final class CategoryFeedInitial extends CategoryFeedState {}

final class CategoryFeedLoading extends CategoryFeedState {}

final class CategoryFeedLoaded extends CategoryFeedState {
  CategoryFeedLoaded({required this.feed});

  final HomeGraphqlCategoryFeedData feed;
}

final class CategoryFeedError extends CategoryFeedState {
  CategoryFeedError({required this.error});

  final ApiErrorModel error;
}
