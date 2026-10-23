import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/data/models/slider_items/slider_item_model.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'product_by_category_banners_state.dart';

class ProductByCategoryBannersCubit
    extends Cubit<ProductByCategoryBannersState> {
  ProductByCategoryBannersCubit(this.homeRepository)
    : super(ProductByCategoryBannersInitial());

  final HomeRepository homeRepository;

  Future<void> getBanners({
    required String language,
    required String slug,
    String? parentSlug,
    bool forceRefresh = false,
  }) async {
    if (isClosed) return;
    emit(ProductByCategoryBannersLoading());

    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final result = await homeRepository.getGraphqlBannersByCategory(
      token: token,
      language: language,
      slug: slug,
      parentSlug: parentSlug,
      forceRefresh: forceRefresh,
    );

    if (isClosed) return;
    result.fold(
      (error) => emit(ProductByCategoryBannersError(error: error)),
      (banners) => emit(ProductByCategoryBannersLoaded(banners: banners)),
    );
  }
}
