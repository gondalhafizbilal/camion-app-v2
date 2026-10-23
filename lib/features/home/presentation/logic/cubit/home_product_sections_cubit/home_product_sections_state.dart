part of 'home_product_sections_cubit.dart';

sealed class HomeProductSectionsState {}

final class HomeProductSectionsInitial extends HomeProductSectionsState {}

final class HomeProductSectionsLoading extends HomeProductSectionsState {}

final class HomeProductSectionsLoaded extends HomeProductSectionsState {
  HomeProductSectionsLoaded({required this.sections});

  final HomeProductSections sections;
}

final class HomeProductSectionsError extends HomeProductSectionsState {
  HomeProductSectionsError({required this.error});

  final ApiErrorModel error;
}
