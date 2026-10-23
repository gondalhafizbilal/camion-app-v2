import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:dio/dio.dart';

class ProfileRemoteDataSource {
  final ApiConsumer apiConsumer;
  ProfileRemoteDataSource({required this.apiConsumer});

  Future<Response> getUserById({
    required String token,
    required String userId,
  }) async {
    final response = await _postGraphql(
      token: token,
      query: '''
query GetCurrentCustomer {
  getCurrentCustomer {
    uuid
    fullName
    emailAddress
    phoneNumber
  }
}
''',
      variables: const <String, dynamic>{},
    );
    final data = _extractGraphqlField(response, 'getCurrentCustomer');
    return _rebuildResponse(response, data ?? const <String, dynamic>{});
  }

  Future<Response> updateUser({
    required String token,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final normalized = _asMap(data);
    final profilePayload = _buildCustomerSelfPayload(normalized);

    if (profilePayload.isNotEmpty) {
      await apiConsumer.put(
        EndPoints.customerSelf,
        headers: {"Authorization": "Bearer $token"},
        data: profilePayload,
      );
    }

    if (profilePayload.isEmpty) {
      return getUserById(token: token, userId: userId);
    }

    // Return latest profile snapshot so UI gets normalized dynamic data.
    final latest = await getUserById(token: token, userId: userId);
    return _rebuildResponse(latest, latest.data);
  }

  Map<String, dynamic> _buildCustomerSelfPayload(Map<String, dynamic> data) {
    final payload = <String, dynamic>{};

    final fullName = _readAsString(data, const ['fullName']);
    if (fullName.isNotEmpty) {
      payload['fullName'] = fullName;
    }

    final emailAddress = _readAsString(data, const ['emailAddress']);
    if (emailAddress.isNotEmpty) {
      payload['emailAddress'] = emailAddress;
    }

    final countryCode = _readAsString(data, const ['countryCode']);
    var phoneNumber = _readAsString(data, const ['phoneNumber', 'phone']);

    String normalizedCountryCode = countryCode;
    if (phoneNumber.startsWith('+')) {
      final split = _splitPhoneWithDialCode(phoneNumber);
      if (normalizedCountryCode.isEmpty) {
        normalizedCountryCode = split.$1;
      }
      phoneNumber = split.$2;
    }
    if (normalizedCountryCode.isNotEmpty && phoneNumber.isNotEmpty) {
      payload['countryCode'] = normalizedCountryCode;
      payload['phoneNumber'] = phoneNumber;
    }

    return payload;
  }

  (String, String) _splitPhoneWithDialCode(String phone) {
    final raw = phone.trim().replaceAll(RegExp(r'\s+'), ' ');
    final match = RegExp(r'^\+\d{1,4}').firstMatch(raw);
    if (match == null) return ('', raw);
    final code = match.group(0) ?? '';
    final number = raw.substring(code.length).trim();
    return (code, number);
  }

  String _readAsString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  Future<Response> getWalletBalance({required String token}) async {
    final response = await _postGraphql(
      token: token,
      query: '''
query GetCurrentAffiliate {
  getCurrentAffiliate {
    uuid
    fullName
    status
    type
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
  }
}
''',
      variables: const <String, dynamic>{},
    );

    final data = _extractGraphqlField(response, 'getCurrentAffiliate');
    return _rebuildResponse(response, data ?? const <String, dynamic>{});
  }

  Future<Response> getAllTransactions({required String token}) async {
    final response = await _postGraphql(
      token: token,
      query: '''
query GetCurrentAffiliateWalletTransactions(
  \$pageNumber: Int
  \$itemsPerPage: Int
) {
  getCurrentAffiliateWalletTransactions(
    pageNumber: \$pageNumber
    itemsPerPage: \$itemsPerPage
  ) {
    uuid
    amount {
      amount
      minorAmount
      currencyCode
    }
    type
    description
    createdAt
  }
}
''',
      variables: const <String, dynamic>{'pageNumber': 1, 'itemsPerPage': 100},
    );

    final data = _extractGraphqlField(
      response,
      'getCurrentAffiliateWalletTransactions',
    );
    final transactions = data is List ? data : const [];
    return _rebuildResponse(response, transactions);
  }

  Future<Response> deleteAccount({required String token}) async {
    final response = await apiConsumer.delete(
      EndPoints.customerDeleteMe,
      headers: {"Authorization": "Bearer $token"},
    );
    return response;
  }

  Future<Response> cancelAccountDeletion({required String token}) async {
    final response = await apiConsumer.patch(
      EndPoints.customerCancelDeletion,
      headers: {"Authorization": "Bearer $token"},
    );
    return response;
  }

  Future<Response> _postGraphql({
    String? token,
    required String query,
    required Map<String, dynamic> variables,
  }) {
    final normalizedToken = token?.trim() ?? '';
    return apiConsumer.post(
      EndPoints.graphql,
      data: {'query': query, 'variables': variables},
      headers: {
        if (normalizedToken.isNotEmpty)
          "Authorization": "Bearer $normalizedToken",
      },
    );
  }

  Future<Response> getCmsPages({String? token}) async {
    final response = await _postGraphql(
      token: token,
      query: '''
query {
  getPosts {
    # uuid
    slug
    title
    brief
    content
    enabled
    images
    createdBy {
      # uuid
      fullName
    }
  }
}
''',
      variables: const <String, dynamic>{},
    );

    final data = _extractGraphqlField(response, 'getPosts');
    final posts = data is List ? data : const [];
    return _rebuildResponse(response, posts);
  }

  Future<Response> getCmsPageByUuid({
    required String uuid,
    String? token,
  }) async {
    final response = await _postGraphql(
      token: token,
      query: '''
query GetPost(\$uuid: String!) {
  getPost(uuid: \$uuid) {
    # uuid
    slug
    title
    brief
    content
    enabled
    images
    createdBy {
      # uuid
      fullName
    }
  }
}
''',
      variables: <String, dynamic>{'uuid': uuid},
    );

    final data = _extractGraphqlField(response, 'getPost');
    return _rebuildResponse(response, data ?? const <String, dynamic>{});
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
