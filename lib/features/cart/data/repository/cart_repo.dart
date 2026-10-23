import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/core/api/api_error_handler.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/features/cart/data/data_source/remote_data_source.dart';
import 'package:camion/features/cart/data/models/get_cart_model.dart';
import 'package:camion/features/cart/data/models/get_user_address_model.dart';
import 'package:dartz/dartz.dart';

class CartRepository {
  final CartRemoteDataSource cartRemoteDataSource;
  CartRepository({required this.cartRemoteDataSource});

  Future<Either<ApiErrorModel, dynamic>> addToCart({
    String? token,
    required String productUuid,
    required String variantUuid,
    required int quantity,
  }) async {
    try {
      final response = await cartRemoteDataSource.addToCart(
        token: token,
        productUuid: productUuid,
        variantUuid: variantUuid,
        quantity: quantity,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<GetCartModel>>> getCart({
    String? token,
    required String lang,
  }) async {
    try {
      final response = await cartRemoteDataSource.getCart(
        token: token,
        lang: lang,
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final rawCart = data['getCustomerCart'] as List? ?? const <dynamic>[];
      final List<GetCartModel> cart = rawCart
          .whereType<Map<String, dynamic>>()
          .map((cart) => GetCartModel.fromJson(cart))
          .toList();
      appLog(cart.toString());
      return Right(cart);
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, GetCartModel>> updateCart({
    String? token,
    required String cartItemUuid,
    required String productUuid,
    required String variantUuid,
    required int quantity,
  }) async {
    try {
      final response = await cartRemoteDataSource.updateCart(
        token: token,
        cartItemUuid: cartItemUuid,
        productUuid: productUuid,
        variantUuid: variantUuid,
        quantity: quantity,
      );

      return Right(GetCartModel.fromJson(response.data));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, GetCartModel>> deleteFromCart({
    String? token,
    required String cartItemUuid,
  }) async {
    try {
      final response = await cartRemoteDataSource.deleteFromCart(
        token: token,
        cartItemUuid: cartItemUuid,
      );
      return Right(GetCartModel.fromJson(response.data));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, GetUserAddressModel>> getUserAddress({
    required String token,
  }) async {
    try {
      final response = await cartRemoteDataSource.getUserAddress(token: token);
      return Right(GetUserAddressModel.fromJson(response.data));
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }
}
