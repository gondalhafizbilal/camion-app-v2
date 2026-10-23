import 'package:camion/core/api/api_error_handler.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/features/profile/data/data_source/remote_data_source.dart';
import 'package:camion/features/profile/data/models/cms_post_model.dart';
import 'package:camion/features/profile/data/models/get_user_model/user_model.dart';
import 'package:camion/features/profile/data/models/transaction_model/transactions.dart';
import 'package:dartz/dartz.dart';

class ProfileRepository {
  final ProfileRemoteDataSource profileRemoteDataSource;
  ProfileRepository({required this.profileRemoteDataSource});

  Map<String, dynamic> _normalizeUserPayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) {
        return data.map((k, v) => MapEntry(k.toString(), v));
      }
      return raw;
    }
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  Future<Either<ApiErrorModel, GetUserModel>> getUserById({
    required String token,
    required String userId,
  }) async {
    try {
      final response = await profileRemoteDataSource.getUserById(
        token: token,
        userId: userId,
      );
      return Right(GetUserModel.fromJson(_normalizeUserPayload(response.data)));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, GetUserModel>> updateUser({
    required String token,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await profileRemoteDataSource.updateUser(
        token: token,
        userId: userId,
        data: data,
      );
      return Right(GetUserModel.fromJson(_normalizeUserPayload(response.data)));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> getWalletBalance({
    required String token,
  }) async {
    try {
      final response = await profileRemoteDataSource.getWalletBalance(
        token: token,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<Transactions>>> getAllTransactions({
    required String token,
  }) async {
    try {
      final response = await profileRemoteDataSource.getAllTransactions(
        token: token,
      );
      final transations = (response.data as List)
          .map((transaction) => Transactions.fromJson(transaction))
          .toList();
      return Right(transations);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> deleteAccount({
    required String token,
  }) async {
    try {
      final response = await profileRemoteDataSource.deleteAccount(
        token: token,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> cancelAccountDeletion({
    required String token,
  }) async {
    try {
      final response = await profileRemoteDataSource.cancelAccountDeletion(
        token: token,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<CmsPostModel>>> getCmsPages({
    String? token,
  }) async {
    try {
      final response = await profileRemoteDataSource.getCmsPages(token: token);
      final list = response.data is List ? response.data as List : const [];
      final pages = list
          .whereType<Map<String, dynamic>>()
          .map(CmsPostModel.fromJson)
          .toList();
      return Right(pages);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, CmsPostModel>> getCmsPageByUuid({
    required String uuid,
    String? token,
  }) async {
    try {
      final response = await profileRemoteDataSource.getCmsPageByUuid(
        uuid: uuid,
        token: token,
      );
      final map = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      return Right(CmsPostModel.fromJson(map));
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }
}
