import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/api/api_locale_mapper.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'product_by_category_state.dart';

class ProductByCategoryCubit extends Cubit<ProductByCategoryState> {
  ProductByCategoryCubit(this.homeRepository)
    : super(ProductByCategoryInitial());

  final HomeRepository homeRepository;

  int currentPage = 1;
  final int perPage = 20;
  bool hasMore = true;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasLoadMoreError = false;
  String _activeSort = '';
  List<String> _activeCategorySlugs = const [];

  List<HomeGraphqlProduct> allProducts = [];

  Future<void> getProductsByCategory({
    required String slug,
    required String lang,
    String? sort,
    List<String>? categorySlugs,
    bool isLoadMore = false,
  }) async {
    final normalizedSlug = slug.trim();
    final normalizedCategorySlugs = (categorySlugs ?? const <String>[])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    if (normalizedSlug.isEmpty) {
      if (!isClosed && !isLoadMore) {
        emit(
          ProductByCategoryError(
            error: ApiErrorModel(message: 'No Category Found'),
          ),
        );
      }
      return;
    }
    if (!hasMore && isLoadMore) return;
    if (isLoading) return;
    if (isClosed) return;

    if (!isLoadMore) {
      _activeSort = sort?.trim() ?? '';
      _activeCategorySlugs = normalizedCategorySlugs;
      currentPage = 1;
      allProducts.clear();
      hasMore = true;
      isLoadingMore = false;
      hasLoadMoreError = false;
      isLoading = true;
      emit(ProductByCategoryLoading());
    } else {
      isLoadingMore = true;
      hasLoadMoreError = false;
      isLoading = true;
      emit(ProductByCategoryLoaded(products: allProducts));
    }

    final activeSort = _activeSort.trim().isNotEmpty
        ? _activeSort.trim()
        : sort?.trim();
    final response = _activeCategorySlugs.isNotEmpty
        ? await homeRepository.getProductsByCategoriesGraphql(
            slugs: _activeCategorySlugs,
            language: ApiLocaleMapper.toGraphqlLocale(lang),
            sort: activeSort,
            pageNumber: currentPage,
            itemsPerPage: perPage,
          )
        : await homeRepository.getProductsByCategoryGraphql(
            slug: normalizedSlug,
            language: ApiLocaleMapper.toGraphqlLocale(lang),
            sort: activeSort,
            pageNumber: currentPage,
            itemsPerPage: perPage,
          );

    if (isClosed) return;

    await response.fold<Future<void>>(
      (ApiErrorModel error) async {
        isLoading = false;

        if (isLoadMore) {
          isLoadingMore = false;
          hasLoadMoreError = true;
          emit(ProductByCategoryLoaded(products: allProducts));
        } else {
          isLoadingMore = false;
          hasLoadMoreError = false;
          emit(ProductByCategoryError(error: error));
        }
      },
      (List<HomeGraphqlProduct> products) async {
        hasMore = products.isNotEmpty;
        if (products.isNotEmpty) {
          allProducts.addAll(products);
          currentPage++;
        }

        if (!isClosed) {
          isLoading = false;
          isLoadingMore = false;
          hasLoadMoreError = false;
          emit(ProductByCategoryLoaded(products: allProducts));
        }
      },
    );
  }
}
