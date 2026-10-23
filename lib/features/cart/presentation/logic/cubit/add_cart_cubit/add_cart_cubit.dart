import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/dashboard_badge_counts_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/cart/data/repository/cart_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'add_cart_state.dart';

class AddCartCubit extends Cubit<AddCartState> {
  AddCartCubit(this.cartRepository) : super(AddCartInitial());
  final CartRepository cartRepository;
  final Set<String> _addedToCartProducts = {};
  final Set<String> _activeAddRequests = {};

  Future<void> addToCart({
    required String productUuid,
    required String variantUuid,
    required int quantity,
  }) async {
    final normalizedProductUuid = productUuid.trim();
    final normalizedVariantUuid = variantUuid.trim();
    final requestKey = '$normalizedProductUuid|$normalizedVariantUuid';
    if (!_activeAddRequests.add(requestKey)) {
      return;
    }

    try {
      final token = await sl<SecureCacheHelper>().getData(key: 'token');
      if (isClosed) return;
      emit(AddCartLoading(normalizedProductUuid));
      final result = await cartRepository.addToCart(
        token: token,
        productUuid: normalizedProductUuid,
        variantUuid: normalizedVariantUuid,
        quantity: quantity,
      );

      if (isClosed) return;
      result.fold((l) => emit(AddCartError(l, normalizedProductUuid)), (r) {
        _addedToCartProducts.add(normalizedProductUuid);
        sl<DashboardBadgeCountsNotifier>().refresh();
        emit(AddCartSuccess(normalizedProductUuid));
      });
    } finally {
      _activeAddRequests.remove(requestKey);
    }
  }

  bool isProductInCart(String productId) {
    return _addedToCartProducts.contains(productId);
  }

  void syncProductInCart({required String productId, required bool isInCart}) {
    if (isInCart) {
      _addedToCartProducts.add(productId);
    } else {
      _addedToCartProducts.remove(productId);
    }
    if (isClosed) return;
    emit(AddCartInitial());
  }
}
