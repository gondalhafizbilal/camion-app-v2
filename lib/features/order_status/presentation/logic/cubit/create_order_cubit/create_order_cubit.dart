import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/order_status/data/models/order_response_model/order_response_model.dart';

import 'package:camion/features/order_status/data/repository/order_status_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'create_order_state.dart';

class CreateOrderCubit extends Cubit<CreateOrderState> {
  CreateOrderCubit(this.orderStatusRepo) : super(CreateOrderInitial());
  final OrderStatusRepository orderStatusRepo;

  // Future<void> calculateShippingAddress({
  //   required List<GetCartModel> items,
  //   required String shippingFirstName,
  //   required String shippingLastName,
  //   required String shippingAddress1,
  //   required String shippingAddress2,
  //   required String shippingCity,
  //   required String shippingState,
  //   required String shippingPostcode,
  //   required String shippingCountry,
  // }) async {
  //   emit(CalculateShippingAddressLoading());
  //   final result = await orderStatusRepo.calculateShippingAddress(
  //     items: items,
  //     shippingFirstName: shippingFirstName,
  //     shippingLastName: shippingLastName,
  //     shippingAddress1: shippingAddress1,
  //     shippingAddress2: shippingAddress2,
  //     shippingCity: shippingCity,
  //     shippingState: shippingState,
  //     shippingPostcode: shippingPostcode,
  //     shippingCountry: shippingCountry,
  //   );
  //   result.fold(
  //     (l) => emit(CalculateShippingAddressError(error: l)),
  //     (r) => emit(CalculateShippingAddressSuccess(shippingMethods: r)),
  //   );
  // }

  Future<void> createOrder() async {
    emit(
      CreateOrderError(
        error: ApiErrorModel(
          message: 'Missing order payload. Use createOrderWithPayload.',
          statusCode: 400,
        ),
      ),
    );
  }

  Future<void> createOrderWithPayload({
    required List<String> cartItemUuids,
    required String paymentMethod,
    required String currency,
    String? couponCode,
  }) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final loginMethod = (sl<CacheHelper>().getData(key: 'loginMethod') ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final isGuest = loginMethod == 'guest';
    final hasToken = token != null && token.toString().trim().isNotEmpty;

    if (!hasToken || isGuest) {
      emit(
        CreateOrderError(
          error: ApiErrorModel(
            message: 'Please login to continue checkout.',
            statusCode: 401,
          ),
        ),
      );
      return;
    }

    if (isClosed) {
      return;
    }
    emit(CreateOrderLoading());

    final result = await orderStatusRepo.createOrder(
      token: token.toString(),
      cartItemUuids: cartItemUuids,
      paymentMethod: paymentMethod,
      currency: currency,
      couponCode: couponCode,
    );

    if (isClosed) {
      return;
    }

    result.fold(
      (l) => emit(CreateOrderError(error: l)),
      (r) => emit(CreateOrderSuccess(order: r)),
    );
  }
}
