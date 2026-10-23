import 'package:camion/core/api/api_error_handler.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/features/currency/data/data_source/remote_data_source.dart';
import 'package:camion/features/currency/data/models/currency_model.dart';
import 'package:dartz/dartz.dart';

class CurrencyRepository {
  final CurrencyRemoteDataSource remoteDataSource;
  CurrencyRepository({required this.remoteDataSource});

  Future<Either<ApiErrorModel, List<Currency>>> getCurrenciesGraphql({
    String? token,
  }) async {
    try {
      final response = await remoteDataSource.getCurrenciesGraphql(
        token: token,
      );
      final data = response.data['data'] ?? const <String, dynamic>{};
      final raw = data['getCurrencies'];
      final list = raw is List ? raw : const [];
      final currencies = list
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => Currency(
              code: (item['alphaCode'] ?? '').toString().trim().toUpperCase(),
              symbol: (item['alphaCode'] ?? '').toString().trim().toUpperCase(),
              name: (item['name'] ?? '').toString().trim(),
              minorUnit: 2,
            ),
          )
          .where((item) => item.code.isNotEmpty)
          .toList();
      return Right(currencies);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<Currency>>> getCurrencies({
    String? token,
  }) async {
    try {
      final response = await remoteDataSource.getCurrencies(token: token);
      final data = response.data;
      // Support: array of objects OR array of strings OR { currencies: [...] }
      final List rawList = data is List
          ? data
          : (data['currencies'] as List? ?? []);
      final currencies = rawList.map((e) {
        if (e is Map<String, dynamic>) {
          return Currency.fromJson(e);
        } else {
          final code = e.toString();
          // Fallback: symbol defaults to code if not provided by backend
          return Currency(code: code, symbol: code);
        }
      }).toList();
      return Right(currencies);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> updateUserCurrency({
    required String token,
    required String userId,
    required String currencyCode,
  }) async {
    try {
      final response = await remoteDataSource.updateUserCurrency(
        token: token,
        userId: userId,
        currencyCode: currencyCode,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> convertProducts({
    required String token,
    required String fromCurrency,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final response = await remoteDataSource.convertProducts(
        token: token,
        fromCurrency: fromCurrency,
        products: products,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }
}
