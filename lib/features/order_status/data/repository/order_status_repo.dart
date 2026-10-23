import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/core/api/api_error_handler.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/features/order_status/data/data_source/remote_data_source.dart';
import 'package:camion/features/order_status/data/models/order_model/order_model.dart';
import 'package:camion/features/order_status/data/models/order_preview_model/order_preview_model.dart';
import 'package:camion/features/order_status/data/models/return_request_model.dart';
import 'package:camion/features/order_status/data/models/order_response_model/order_response_model.dart';
import 'package:camion/features/order_status/data/models/tracking_order_model/tracking_order_model_response_model.dart'
    as tracking_model;
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class OrderStatusRepository {
  final OrderStatusRemoteDataSource orderStatusRemoteDataSource;
  OrderStatusRepository({required this.orderStatusRemoteDataSource});
  final Map<String, Map<String, dynamic>> _currentOrderCache = {};

  void _logOrderTimeDebug({
    required String flow,
    required Map<String, dynamic> source,
    required OrderModel order,
  }) {
    final serverTime =
        source['orderPlacementDate'] ??
        source['orderplacement'] ??
        source['orderPlacement'] ??
        source['createdAt'];
    final local = order.createdAt;
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hh = offset.inHours.abs().toString().padLeft(2, '0');
    final mm = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    appLog(
      '[OrderTime/$flow] server="$serverTime" local="${local.toIso8601String()}" timezone="${local.timeZoneName} (UTC$sign$hh:$mm)"',
    );
  }

  // Future<Either<ApiErrorModel, List<ShippingMethodModel>>>
  // calculateShippingAddress({
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
  //   try {
  //     final response = await orderStatusRemoteDataSource
  //         .calculateShippingAddress(
  //           items: items,
  //           firstName: shippingFirstName,
  //           lastName: shippingLastName,
  //           address1: shippingAddress1,
  //           city: shippingCity,
  //           postcode: shippingPostcode,
  //           country: shippingCountry,
  //         );

  //     final List<ShippingMethodModel> shippingMethods = (response.data as List)
  //         .map((e) => ShippingMethodModel.fromJson(e))
  //         .toList();
  //     return right(shippingMethods);
  //   } catch (e) {
  //     return left(ApiErrorHandler.handle(e));
  //   }
  // }

  Future<Either<ApiErrorModel, OrderResponse>> createOrder({
    required String token,
    required List<String> cartItemUuids,
    required String paymentMethod,
    required String currency,
    String? couponCode,
  }) async {
    try {
      final response = await orderStatusRemoteDataSource.createOrder(
        token: token,
        cartItemUuids: cartItemUuids,
        paymentMethod: paymentMethod,
        currency: currency,
        couponCode: couponCode,
      );

      return right(OrderResponse.fromJson(response.data));
    } catch (e) {
      appLog(e.toString());
      return left(_resolveCreateOrderError(e));
    }
  }

  Future<Either<ApiErrorModel, OrderResponse>> retryPayment({
    required String token,
    required String orderUuid,
  }) async {
    try {
      final response = await orderStatusRemoteDataSource.retryPayment(
        token: token,
        orderUuid: orderUuid,
      );

      return right(OrderResponse.fromJson(response.data));
    } catch (e) {
      appLog(e.toString());
      return left(_resolveCreateOrderError(e));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> deleteOrder({
    required String token,
    required String orderUuid,
  }) async {
    try {
      final response = await orderStatusRemoteDataSource.deleteOrder(
        token: token,
        uuid: orderUuid,
      );
      return right(response.data);
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  ApiErrorModel _resolveCreateOrderError(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final fallback = ApiErrorHandler.handle(error, showNoDataPopup: false);
      final parsed = ApiErrorModel.fromDynamic(
        error.response?.data,
        fallbackMessage: fallback.message,
      );
      return ApiErrorModel(
        message: parsed.message,
        statusCode: statusCode ?? fallback.statusCode,
        icon: fallback.icon,
      );
    }
    return ApiErrorHandler.handle(error);
  }

  Future<Either<ApiErrorModel, List<OrderModel>>> getOrders({
    required String token,
    required String userId,
    int pageNumber = 1,
    int itemsPerPage = 10,
  }) async {
    try {
      final response = await orderStatusRemoteDataSource.getOrders(
        token: token,
        userId: userId,
        pageNumber: pageNumber,
        itemsPerPage: itemsPerPage,
      );

      final data = response.data['data'] ?? const <String, dynamic>{};
      final rawOrders =
          (data['getCurrentCustomerOrders'] as List? ?? const <dynamic>[]);
      final orders = rawOrders.whereType<Map<String, dynamic>>().map((order) {
        final model = OrderModel.fromJson(order);
        _logOrderTimeDebug(flow: 'listing', source: order, order: model);
        return model;
      }).toList();
      return right(orders);
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, OrderPreviewModel>> getOrderPreview({
    required String token,
    String? couponCode,
    List<String>? cartItemUuids,
  }) async {
    try {
      final response = await orderStatusRemoteDataSource.getOrderPreview(
        token: token,
        couponCode: couponCode,
        cartItemUuids: cartItemUuids,
      );
      return right(OrderPreviewModel.fromJson(response.data));
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<OrderModel>>> getOrderStatus({
    required String token,
    required String status,
    int pageNumber = 1,
    int itemsPerPage = 10,
  }) async {
    try {
      final response = await orderStatusRemoteDataSource.getOrderStatus(
        token: token,
        status: status,
        pageNumber: pageNumber,
        itemsPerPage: itemsPerPage,
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final rawOrders =
          (data['getCurrentCustomerOrders'] as List? ?? const <dynamic>[]);
      final orders = rawOrders.whereType<Map<String, dynamic>>().map((order) {
        final model = OrderModel.fromJson(order);
        _logOrderTimeDebug(flow: 'listing-status', source: order, order: model);
        return model;
      }).toList();
      final normalizedStatus = status.trim().toLowerCase();
      final filteredOrders = orders.where((order) {
        final currentStatus = order.wcOrderStatus.trim().toLowerCase();
        if (normalizedStatus == 'delivered') {
          return currentStatus == 'delivered' ||
              currentStatus == 'payment_successful';
        }
        if (normalizedStatus == 'payment_successful') {
          return currentStatus == 'payment_successful';
        }
        return currentStatus == normalizedStatus;
      }).toList();

      return right(filteredOrders);
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, tracking_model.TrackingResponse>>
  getOrderTracking({required String token, required String orderId}) async {
    try {
      final response = await orderStatusRemoteDataSource.getOrderTracking(
        token: token,
        uuid: orderId,
      );
      final payload =
          (response.data as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final data =
          (payload['data'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final rawStages = data['getOrderTracking'] as List? ?? const <dynamic>[];
      final stages = rawStages
          .whereType<Map>()
          .map(
            (item) => tracking_model.TrackingStage.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);
      return right(
        tracking_model.TrackingResponse(
          statusCode: 200,
          message: 'Order tracking fetched successfully',
          data: tracking_model.OrderData.fromTrackingStages(stages),
        ),
      );
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, OrderModel>> getCurrentCustomerOrder({
    required String token,
    required String uuid,
  }) async {
    try {
      final orderMap = await _fetchCurrentCustomerOrderMap(
        token: token,
        uuid: uuid,
        forceRefresh: true,
      );
      final order = OrderModel.fromJson(orderMap);
      _logOrderTimeDebug(flow: 'detail', source: orderMap, order: order);
      return right(order);
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<ReturnRequestModel>>>
  getCurrentCustomerReturnRequests({required String token}) async {
    try {
      final response = await orderStatusRemoteDataSource
          .getCurrentCustomerReturnRequests(token: token);
      final data = response.data['data'] ?? const <String, dynamic>{};
      final rawRequests =
          (data['getCurrentCustomerReturnRequests'] as List? ??
          const <dynamic>[]);
      final requests = rawRequests
          .whereType<Map<String, dynamic>>()
          .map(ReturnRequestModel.fromJson)
          .toList();
      return right(requests);
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, ReturnRequestModel>>
  getCurrentCustomerReturnRequest({
    required String token,
    required String uuid,
  }) async {
    try {
      final response = await orderStatusRemoteDataSource
          .getCurrentCustomerReturnRequest(token: token, uuid: uuid);
      final data = response.data['data'] ?? const <String, dynamic>{};
      final raw = data['getCurrentCustomerReturnRequest'];
      final requestMap = raw is Map<String, dynamic>
          ? raw
          : const <String, dynamic>{};
      return right(ReturnRequestModel.fromJson(requestMap));
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, ReturnRequestModel>> createReturnRequest({
    required String token,
    required String orderUuid,
    String? orderItemUuid,
    required String reason,
    required String reasonDetail,
  }) async {
    try {
      final response = await orderStatusRemoteDataSource.createReturnRequest(
        token: token,
        orderUuid: orderUuid,
        orderItemUuid: orderItemUuid,
        reason: reason,
        reasonDetail: reasonDetail,
      );
      return right(ReturnRequestModel.fromJson(response.data));
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, ReturnRequestEvidence>>
  uploadReturnRequestEvidence({
    required String token,
    required String requestUuid,
    required FormData formData,
  }) async {
    try {
      final response = await orderStatusRemoteDataSource
          .uploadReturnRequestEvidence(
            token: token,
            requestUuid: requestUuid,
            formData: formData,
          );
      return right(ReturnRequestEvidence.fromJson(response.data));
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Map<String, dynamic>> _fetchCurrentCustomerOrderMap({
    required String token,
    required String uuid,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _currentOrderCache.containsKey(uuid)) {
      return _currentOrderCache[uuid]!;
    }

    final response = await orderStatusRemoteDataSource.getCurrentCustomerOrder(
      token: token,
      uuid: uuid,
    );
    final data = response.data['data'] ?? const <String, dynamic>{};
    final rawOrder =
        data['getCurrentCustomerOrder'] ?? data['getCurrentCustomerOrders'];
    final orderMap = rawOrder is Map<String, dynamic>
        ? rawOrder
        : const <String, dynamic>{};

    if (orderMap.isNotEmpty) {
      _currentOrderCache[uuid] = orderMap;
    }
    return orderMap;
  }
}
