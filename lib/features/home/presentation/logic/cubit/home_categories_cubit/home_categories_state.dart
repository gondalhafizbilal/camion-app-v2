part of 'home_categories_cubit.dart';

sealed class HomeCategoriesState {}

final class HomeCategoriesInitial extends HomeCategoriesState {}

final class HomeCategoriesLoading extends HomeCategoriesState {}

final class HomeCategoriesLoaded extends HomeCategoriesState {
  HomeCategoriesLoaded({required this.categories});

  final List<HomeGraphqlCategory> categories;
}

final class HomeCategoriesError extends HomeCategoriesState {
  HomeCategoriesError({required this.error});

  final ApiErrorModel error;
}
