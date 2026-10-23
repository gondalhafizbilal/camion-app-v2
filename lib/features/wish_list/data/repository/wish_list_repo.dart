import 'package:camion/core/api/api_error_handler.dart';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/wish_list/data/data_source/remote_data_source.dart';
import 'package:camion/features/wish_list/data/models/get_wish_list_model.dart';
import 'package:camion/features/wish_list/data/models/wish_list_graphql_bundle.dart';
import 'package:dartz/dartz.dart';

class WishListRepository {
  final WishListRemoteDataSource wishListRemoteDataSource;

  WishListRepository({required this.wishListRemoteDataSource});

  Future<Either<ApiErrorModel, dynamic>> addToWishList({
    required String token,
    required String productId,
    String? variantUuid,
    required String title,
    required String price,
    required String image,
  }) async {
    try {
      final response = await wishListRemoteDataSource.addToWishList(
        token: token,
        productId: productId,
        variantUuid: variantUuid,
        title: title,
        price: price,
        image: image,
      );

      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<GetWishListModel>>> getWishList({
    required String token,
    int pageNumber = 1,
    int itemsPerPage = 100,
  }) async {
    try {
      final response = await wishListRemoteDataSource.getWishList(
        token: token,
        pageNumber: pageNumber,
        itemsPerPage: itemsPerPage,
      );

      final data = response.data['data'] ?? const <String, dynamic>{};
      final rawWishList = data['getCustomerWishlist'] as List? ?? const [];
      final List<GetWishListModel> wishList = rawWishList
          .whereType<Map<String, dynamic>>()
          .map(GetWishListModel.fromJson)
          .toList();

      return Right(wishList);
    } catch (e) {
      appLog(e.toString());
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, dynamic>> removeFromWishList({
    required String token,
    required String productId,
  }) async {
    try {
      final response = await wishListRemoteDataSource.removeFromWishList(
        token: token,
        productId: productId,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, WishListGraphqlBundle>>
  getWishListAndPopularGraphql({
    required String token,
    int popularPageNumber = 1,
    int popularItemsPerPage = 4,
  }) async {
    try {
      final response = await wishListRemoteDataSource
          .getWishListAndPopularGraphql(
            token: token,
            popularPageNumber: popularPageNumber,
            popularItemsPerPage: popularItemsPerPage,
          );

      final data = response.data['data'] ?? const <String, dynamic>{};
      final rawWishList = data['getCustomerWishlist'] as List? ?? const [];
      final rawPopular = data['popularProductsSection'] as List? ?? const [];

      final wishList = rawWishList
          .whereType<Map<String, dynamic>>()
          .map(GetWishListModel.fromJson)
          .toList();
      final popularProducts = rawPopular
          .whereType<Map<String, dynamic>>()
          .map(HomeGraphqlProduct.fromJson)
          .toList();

      return Right(
        WishListGraphqlBundle(
          wishLists: wishList,
          popularProducts: popularProducts,
        ),
      );
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }

  Future<Either<ApiErrorModel, List<HomeGraphqlProduct>>>
  getPopularProductsGraphql({
    String? token,
    int pageNumber = 1,
    int itemsPerPage = 4,
  }) async {
    try {
      final response = await wishListRemoteDataSource.getPopularProductsGraphql(
        token: token,
        pageNumber: pageNumber,
        itemsPerPage: itemsPerPage,
      );

      final data = response.data['data'] ?? const <String, dynamic>{};
      final rawPopular =
          (data['getPopularProducts'] as List? ??
          data['popularProductsSection'] as List? ??
          const []);

      final popularProducts = rawPopular
          .whereType<Map<String, dynamic>>()
          .map(HomeGraphqlProduct.fromJson)
          .toList();

      return Right(popularProducts);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }
}
