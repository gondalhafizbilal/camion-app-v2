import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/api/api_locale_mapper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/dashboard_badge_counts_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/wish_list/data/models/get_wish_list_model.dart';
import 'package:camion/features/wish_list/data/repository/wish_list_repo.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'get_wish_list_state.dart';

class GetWishListCubit extends Cubit<GetWishListState> {
  GetWishListCubit(this.wishListRepository, {HomeRepository? homeRepository})
    : _homeRepository = homeRepository ?? sl<HomeRepository>(),
      super(GetWishListInitial());
  final WishListRepository wishListRepository;
  final HomeRepository _homeRepository;

  Future<String> _activeGraphqlLanguage() async {
    final deviceLanguage = await sl<SecureCacheHelper>().getData(
      key: 'languageCode',
    );
    final languageCode = deviceLanguage?.toString() ?? '';
    return ApiLocaleMapper.toGraphqlLocale(languageCode);
  }

  Future<void> getWishList() async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (token == null || token.isEmpty) {
      if (isClosed) return;
      emit(
        GetWishListError(
          ApiErrorModel(message: 'Please login to access your wishlist'),
        ),
      );
      return;
    }
    if (isClosed) return;
    emit(GetWishListLoading());
    final result = await wishListRepository.getWishList(token: token);
    if (isClosed) return;
    result.fold(
      (l) => emit(GetWishListError(l)),
      (r) => emit(GetWishListSuccess(r)),
    );
  }

  Future<void> getWishListAndPopular({int popularItemsPerPage = 4}) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (token == null || token.isEmpty) {
      if (isClosed) return;
      emit(
        GetWishListError(
          ApiErrorModel(message: 'Please login to access your wishlist'),
        ),
      );
      return;
    }
    if (isClosed) return;
    emit(GetWishListLoading());
    final language = await _activeGraphqlLanguage();
    final results = await Future.wait<dynamic>([
      wishListRepository.getWishList(token: token),
      _homeRepository.getPopularGraphqlProducts(
        token: token,
        language: language,
        pageNumber: 1,
        itemsPerPage: popularItemsPerPage,
      ),
    ]);
    if (isClosed) return;

    final wishListResult =
        results[0] as Either<ApiErrorModel, List<GetWishListModel>>;
    final popularResult =
        results[1] as Either<ApiErrorModel, List<HomeGraphqlProduct>>;

    final wishLists = <GetWishListModel>[];
    final popularProducts = <HomeGraphqlProduct>[];
    ApiErrorModel? firstError;

    wishListResult.fold(
      (error) => firstError ??= error,
      (items) => wishLists.addAll(items),
    );
    popularResult.fold(
      (error) => firstError ??= error,
      (items) => popularProducts.addAll(items),
    );

    final hasData = wishLists.isNotEmpty || popularProducts.isNotEmpty;
    if (hasData || firstError == null) {
      emit(
        GetWishListWithPopularSuccess(
          wishLists: wishLists,
          popularProducts: popularProducts,
        ),
      );
      return;
    }

    emit(GetWishListError(firstError!));
  }

  Future<void> getPopularProductsOnly({int popularItemsPerPage = 4}) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (isClosed) return;
    emit(GetWishListLoading());
    final language = await _activeGraphqlLanguage();

    final popularResult = await _homeRepository.getPopularGraphqlProducts(
      token: token,
      language: language,
      pageNumber: 1,
      itemsPerPage: popularItemsPerPage,
    );
    if (isClosed) return;

    popularResult.fold(
      (error) => emit(GetWishListError(error)),
      (products) => emit(
        GetWishListWithPopularSuccess(
          wishLists: const <GetWishListModel>[],
          popularProducts: products,
        ),
      ),
    );
  }

  Future<void> removeFromWishList({required String productId}) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (token == null || token.isEmpty) {
      if (isClosed) return;
      emit(
        RemoveWishListError(
          ApiErrorModel(message: 'Please login to manage your wishlist'),
        ),
      );
      return;
    }
    final removeTargetId = _resolveRemoveTargetId(productId);
    emit(RemoveWishListLoading());
    final result = await wishListRepository.removeFromWishList(
      token: token,
      productId: removeTargetId,
    );
    result.fold((l) => emit(RemoveWishListError(l)), (r) {
      sl<DashboardBadgeCountsNotifier>().refresh();
      emit(RemoveWishListSuccess());
    });
  }

  String _resolveRemoveTargetId(String value) {
    final candidate = value.trim();
    if (candidate.isEmpty) {
      return candidate;
    }

    Iterable<GetWishListModel> items = const <GetWishListModel>[];
    final currentState = state;
    if (currentState is GetWishListSuccess) {
      items = currentState.wishLists;
    } else if (currentState is GetWishListWithPopularSuccess) {
      items = currentState.wishLists;
    }

    for (final item in items) {
      final itemProductId = (item.productId ?? '').trim();
      final itemWishlistId = (item.id ?? '').trim();
      if (itemProductId == candidate && itemWishlistId.isNotEmpty) {
        return itemWishlistId;
      }
    }

    return candidate;
  }
}
