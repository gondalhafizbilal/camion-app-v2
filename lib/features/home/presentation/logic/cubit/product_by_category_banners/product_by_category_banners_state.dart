part of 'product_by_category_banners_cubit.dart';

sealed class ProductByCategoryBannersState {}

final class ProductByCategoryBannersInitial
    extends ProductByCategoryBannersState {}

final class ProductByCategoryBannersLoading
    extends ProductByCategoryBannersState {}

final class ProductByCategoryBannersLoaded
    extends ProductByCategoryBannersState {
  ProductByCategoryBannersLoaded({required this.banners});

  final List<SliderItemModel> banners;
}

final class ProductByCategoryBannersError
    extends ProductByCategoryBannersState {
  ProductByCategoryBannersError({required this.error});

  final ApiErrorModel error;
}
