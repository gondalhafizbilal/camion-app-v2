import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:dio/dio.dart';

class AffiliateRemoteDataSource {
  final ApiConsumer apiConsumer;
  AffiliateRemoteDataSource({required this.apiConsumer});

  Future<Response> signAffiliate({
    required String token,
    required String name,
    required String nationality,
    required String gender,
    required String bio,
  }) async {
    final response = await apiConsumer.post(
      "${EndPoints.baseUrl}/v1/referral/affiliates/affiliate",
      headers: {"Authorization": "Bearer $token"},
      data: {
        "fullName": name,
        "gender": gender,
        "nationality": nationality,
        "bio": bio,
      },
    );
    return response;
  }

  Future<Response> getAffiliateStatus({required String token}) async {
    final response = await _postGraphql(
      token: token,
      query: '''
query GetCurrentAffiliate {
  getCurrentAffiliate {
    uuid
    fullName
    gender
    nationality
    bio
    type
    status
    totalCommission {
      amount
      minorAmount
      currencyCode
    }
    totalPaid {
      amount
      minorAmount
      currencyCode
    }
    remainingBalance {
      amount
      minorAmount
      currencyCode
    }
    couponsCreated
    couponsUsed
    trendingCoupon {
      uuid
    }
    topProduct {
      uuid
    }
    wallet {
      uuid
      amount {
        amount
        minorAmount
        currencyCode
      }
      amountPending {
        amount
        minorAmount
        currencyCode
      }
      amountAvailable {
        amount
        minorAmount
        currencyCode
      }
    }
    createdAt
  }
}
''',
      variables: const <String, dynamic>{},
    );

    final data = _extractGraphqlField(response, 'getCurrentAffiliate');
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: _rebuildResponse(response, {
          'message': 'Affiliate not found',
        }),
        type: DioExceptionType.badResponse,
      );
    }
    return _rebuildResponse(response, data);
  }

  Future<Response> createCoupon({
    required String token,
    required String code,
    required String expiryDate,
    required num discountPercentage,
  }) async {
    final response = await apiConsumer.post(
      "${EndPoints.baseUrl}/v1/referral/coupons",
      headers: {"Authorization": "Bearer $token"},
      data: {
        "code": code,
        "discountPercentage": discountPercentage,
        "expiresAt": expiryDate,
      },
    );

    return response;
  }

  Future<Response> getCouponCodeByAffiliateId({required String token}) async {
    const variables = <String, dynamic>{'pageNumber': 1, 'itemsPerPage': 100};

    try {
      final response = await _postGraphql(
        token: token,
        query: _richCouponsQuery,
        variables: variables,
      );

      final data = _extractGraphqlField(response, 'getCurrentAffiliateCoupons');
      final coupons = data is List ? data : const [];
      return _rebuildResponse(response, coupons);
    } on DioException {
      final fallbackResponse = await _postGraphql(
        token: token,
        query: _fallbackCouponsQuery,
        variables: variables,
      );
      final fallbackData = _extractGraphqlField(
        fallbackResponse,
        'getCurrentAffiliateCoupons',
      );
      final coupons = fallbackData is List ? fallbackData : const [];
      return _rebuildResponse(fallbackResponse, coupons);
    }
  }

  Future<Response> getCouponOrders({
    required String token,
    required String uuid,
    int pageNumber = 1,
    int itemsPerPage = 24,
  }) async {
    final response = await _postGraphql(
      token: token,
      query: _couponOrdersQuery,
      variables: <String, dynamic>{
        'uuid': uuid,
        'pageNumber': pageNumber,
        'itemsPerPage': itemsPerPage,
      },
    );

    final data = _extractGraphqlField(response, 'getCouponOrders');
    final orders = data is List ? data : const [];
    return _rebuildResponse(response, orders);
  }

  static const String _richCouponsQuery = '''
query GetCurrentAffiliateCoupons(
  \$pageNumber: Int
  \$itemsPerPage: Int
) {
  getCurrentAffiliateCoupons(
    pageNumber: \$pageNumber
    itemsPerPage: \$itemsPerPage
  ) {
    uuid
    code
    discountPercentage
    ordersCount
    totalSales {
      amount
      minorAmount
      currencyCode
    }
    totalCommission {
      amount
      minorAmount
      currencyCode
    }
    expiresAt
    createdAt
  }
}
''';

  static const String _couponOrdersQuery = '''
query GetCouponOrders(\$uuid: String, \$pageNumber: Int, \$itemsPerPage: Int) {
  getCouponOrders(uuid: \$uuid, pageNumber: \$pageNumber, itemsPerPage: \$itemsPerPage) {
    uuid
    total {
      amount
      minorAmount
      currencyCode
    }
    commission {
      amount
      minorAmount
      currencyCode
    }
    status
    createdAt
  }
}
''';

  static const String _fallbackCouponsQuery = '''
query GetCurrentAffiliateCoupons(
  \$pageNumber: Int
  \$itemsPerPage: Int
) {
  getCurrentAffiliateCoupons(
    pageNumber: \$pageNumber
    itemsPerPage: \$itemsPerPage
  ) {
    uuid
    code
    discountPercentage
    ordersCount
    totalSales {
      amount
      minorAmount
      currencyCode
    }
    totalCommission {
      amount
      minorAmount
      currencyCode
    }
    expiresAt
    createdAt
  }
}
''';

  Future<Response> _postGraphql({
    required String token,
    required String query,
    required Map<String, dynamic> variables,
  }) {
    return apiConsumer.post(
      EndPoints.graphql,
      data: {'query': query, 'variables': variables},
      headers: {"Authorization": "Bearer $token"},
    );
  }

  dynamic _extractGraphqlField(Response response, String fieldName) {
    final root = response.data;
    if (root is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: _rebuildResponse(response, {
          'message': 'Invalid GraphQL response',
        }),
        type: DioExceptionType.badResponse,
      );
    }

    final errors = root['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      final message = first is Map<String, dynamic>
          ? (first['message']?.toString() ?? 'GraphQL request failed')
          : 'GraphQL request failed';
      throw DioException(
        requestOptions: response.requestOptions,
        response: _rebuildResponse(response, {'message': message}),
        type: DioExceptionType.badResponse,
      );
    }

    final data = root['data'];
    if (data is Map<String, dynamic>) {
      return data[fieldName];
    }
    return null;
  }

  Response _rebuildResponse(Response response, dynamic data) {
    return Response(
      requestOptions: response.requestOptions,
      data: data,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      headers: response.headers,
      isRedirect: response.isRedirect,
      redirects: response.redirects,
      extra: response.extra,
    );
  }
}
