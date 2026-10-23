import 'dart:async';

import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/dashboard_badge_counts_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/services/tiktok_business_service.dart';
import 'package:camion/features/wish_list/data/repository/wish_list_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'wish_list_state.dart';

class AddToWishListCubit extends Cubit<AddToWishListState> {
  AddToWishListCubit(this.wishListRepository) : super(WishListInitial());
  final WishListRepository wishListRepository;

  final Set<String> _addedToWishListProducts = {};
  addtoWishList({
    required String productId,
    String? variantUuid,
    required String title,
    required String price,
    required String image,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (isClosed) return;
    if (token == null || token.isEmpty) {
      emit(
        WishListError(
          error: ApiErrorModel(message: 'Please login to manage your wishlist'),
          productId: productId,
        ),
      );
      return;
    }
    emit(WishListLoading(productId: productId));
    final result = await wishListRepository.addToWishList(
      token: token,

      productId: productId,
      variantUuid: variantUuid,
      title: title,
      price: price,
      image: image,
    );
    if (isClosed) return;
    result.fold((l) => emit(WishListError(error: l, productId: productId)), (
      r,
    ) {
      if (_addedToWishListProducts.contains(productId)) {
        _addedToWishListProducts.remove(productId);
        return;
      } else {
        _addedToWishListProducts.add(productId);
      }

      sl<DashboardBadgeCountsNotifier>().refresh();
      unawaited(
        sl<AppsFlyerService>().logAddToWishlist(
          contentId: productId,
          contentType: 'product',
          price: price,
        ),
      );
      unawaited(
        TikTokBusinessService.addToWishlist(eventId: productId),
      );
      emit(WishListSuccess(productId: productId));
    });
  }

  bool isProductInWishList(String productId) {
    return _addedToWishListProducts.contains(productId);
  }
}
