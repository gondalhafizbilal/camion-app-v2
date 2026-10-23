import 'dart:async';

import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchGraphqlCubit extends Cubit<SearchGraphqlState> {
  SearchGraphqlCubit(this._homeRepository) : super(SearchGraphqlInitial());

  final HomeRepository _homeRepository;

  String _lastAppLanguageCode = 'en';
  String _lastQuery = '';
  SearchApiFilter _lastFilter = const SearchApiFilter();
  bool _isFetchingMore = false;

  Future<void> loadInitial({
    required String appLanguageCode,
    SearchApiFilter filter = const SearchApiFilter(),
  }) async {
    _lastAppLanguageCode = appLanguageCode;
    _lastQuery = '';
    _lastFilter = filter;

    emit(SearchGraphqlLoading());
    await _fetchFirstPage(
      query: '',
      appLanguageCode: appLanguageCode,
      filter: filter,
    );
  }

  Future<void> search({
    required String query,
    required String appLanguageCode,
    SearchApiFilter? filter,
  }) async {
    final normalizedQuery = query.trim();
    final selectedFilter = filter ?? _lastFilter;

    _lastAppLanguageCode = appLanguageCode;
    _lastQuery = normalizedQuery;
    _lastFilter = selectedFilter;

    if (normalizedQuery.isEmpty) {
      await loadInitial(
        appLanguageCode: appLanguageCode,
        filter: selectedFilter,
      );
      return;
    }

    emit(SearchGraphqlLoading());
    await _fetchFirstPage(
      query: normalizedQuery,
      appLanguageCode: appLanguageCode,
      filter: selectedFilter,
    );
  }

  Future<void> refresh() async {
    await search(
      query: _lastQuery,
      appLanguageCode: _lastAppLanguageCode,
      filter: _lastFilter,
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! SearchGraphqlLoaded) return;
    if (!current.hasMore || current.isLoadingMore || _isFetchingMore) return;

    _isFetchingMore = true;
    emit(current.copyWith(isLoadingMore: true));

    final nextPage = current.currentPage + 1;
    final language = _normalizedLanguage(_lastAppLanguageCode);
    final result = current.query.isEmpty
        ? await _homeRepository.getGraphqlProducts(
            language: language,
            sort: _searchSortValue(current.filter.sortLabel),
            pageNumber: nextPage,
            itemsPerPage: current.filter.itemsPerPage,
          )
        : await _homeRepository.searchGraphqlProducts(
            language: language,
            queryText: current.query,
            sort: _searchSortValue(current.filter.sortLabel),
            pageNumber: nextPage,
            itemsPerPage: current.filter.itemsPerPage,
          );

    result.fold(
      (error) {
        _isFetchingMore = false;
        emit(current.copyWith(isLoadingMore: false));
      },
      (products) {
        final incoming = products;
        final merged = <HomeGraphqlProduct>[...current.products];
        for (final item in incoming) {
          if (!merged.any((existing) => existing.uuid == item.uuid)) {
            merged.add(item);
          }
        }

        _isFetchingMore = false;
        emit(
          current.copyWith(
            products: merged,
            currentPage: nextPage,
            hasMore: incoming.isNotEmpty,
            isLoadingMore: false,
          ),
        );
      },
    );
  }

  Future<void> _fetchFirstPage({
    required String query,
    required String appLanguageCode,
    required SearchApiFilter filter,
  }) async {
    final language = _normalizedLanguage(appLanguageCode);
    final result = query.isEmpty
        ? await _homeRepository.getGraphqlProducts(
            language: language,
            sort: _searchSortValue(filter.sortLabel),
            pageNumber: 1,
            itemsPerPage: filter.itemsPerPage,
          )
        : await _homeRepository.searchGraphqlProducts(
            language: language,
            queryText: query,
            sort: _searchSortValue(filter.sortLabel),
            pageNumber: 1,
            itemsPerPage: filter.itemsPerPage,
          );

    result.fold(
      (error) => emit(SearchGraphqlError(error)),
      (products) {
        emit(
          SearchGraphqlLoaded(
            products: products,
            query: query,
            sortLabel: filter.sortLabel,
            filter: filter.copyWith(pageNumber: 1),
            currentPage: 1,
            hasMore: products.isNotEmpty,
          ),
        );

        if (query.isNotEmpty) {
          unawaited(
            sl<AppsFlyerService>().logSearch(
              searchString: query,
              contentList: products
                  .map((product) => product.uuid)
                  .where((value) => value.trim().isNotEmpty)
                  .toList(growable: false),
            ),
          );
        }
      },
    );
  }

  String _normalizedLanguage(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'en';
    return value.split('-').first.toLowerCase();
  }

  String? _searchSortValue(String sortLabel) {
    final normalized = sortLabel.trim();
    if (normalized.isEmpty) {
      return null;
    }
    switch (normalized) {
      case 'Price: Low to High':
      case 'السعر: من الأقل إلى الأعلى':
        return SearchSortOption.priceLowToHigh.apiValue;
      case 'Price: High to Low':
      case 'السعر: من الأعلى إلى الأقل':
        return SearchSortOption.priceHighToLow.apiValue;
      case 'Best Sellers':
      case 'الأكثر مبيعًا':
        return SearchSortOption.bestSellers.apiValue;
      case 'Most Favorited':
      case 'الأكثر تفضيلًا':
        return SearchSortOption.mostFavorited.apiValue;
      case 'New Arrivals':
      case 'وصل حديثًا':
        return SearchSortOption.newArrivals.apiValue;
      case 'Most Rated':
      case 'الأعلى تقييمًا':
        return SearchSortOption.mostRated.apiValue;
      case 'Best Match':
      case 'الأفضل تطابقًا':
      default:
        return SearchSortOption.bestMatch.apiValue;
    }
  }
}

enum SearchSortOption {
  bestMatch(label: 'Best Match', apiValue: 'best-match'),
  bestSellers(label: 'Best Sellers', apiValue: 'best-sellers'),
  mostFavorited(label: 'Most Favorited', apiValue: 'most-favorited'),
  newArrivals(label: 'New Arrivals', apiValue: 'new-arrivals'),
  mostRated(label: 'Most Rated', apiValue: 'most-rated'),
  priceHighToLow(label: 'Price: High to Low', apiValue: 'price:high-to-low'),
  priceLowToHigh(label: 'Price: Low to High', apiValue: 'price:low-to-high');

  const SearchSortOption({required this.label, required this.apiValue});
  final String label;
  final String apiValue;
}

class SearchApiFilter {
  const SearchApiFilter({
    this.sortLabel = '',
    this.pageNumber = 1,
    this.itemsPerPage = 100,
  });

  final String sortLabel;
  final int pageNumber;
  final int itemsPerPage;

  SearchApiFilter copyWith({
    String? sortLabel,
    int? pageNumber,
    int? itemsPerPage,
  }) {
    return SearchApiFilter(
      sortLabel: sortLabel ?? this.sortLabel,
      pageNumber: pageNumber ?? this.pageNumber,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sortLabel': sortLabel,
      'pageNumber': pageNumber,
      'itemsPerPage': itemsPerPage,
    };
  }

  factory SearchApiFilter.fromMap(Map<String, dynamic> map) {
    return SearchApiFilter(
      sortLabel: map['sortLabel']?.toString() ?? '',
      pageNumber: (map['pageNumber'] as num?)?.toInt() ?? 1,
      itemsPerPage: (map['itemsPerPage'] as num?)?.toInt() ?? 100,
    );
  }
}

sealed class SearchGraphqlState {}

final class SearchGraphqlInitial extends SearchGraphqlState {}

final class SearchGraphqlLoading extends SearchGraphqlState {}

final class SearchGraphqlLoaded extends SearchGraphqlState {
  SearchGraphqlLoaded({
    required this.products,
    required this.query,
    required this.sortLabel,
    required this.filter,
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<HomeGraphqlProduct> products;
  final String query;
  final String sortLabel;
  final SearchApiFilter filter;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  SearchGraphqlLoaded copyWith({
    List<HomeGraphqlProduct>? products,
    String? query,
    String? sortLabel,
    SearchApiFilter? filter,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SearchGraphqlLoaded(
      products: products ?? this.products,
      query: query ?? this.query,
      sortLabel: sortLabel ?? this.sortLabel,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final class SearchGraphqlError extends SearchGraphqlState {
  SearchGraphqlError(this.error);
  final ApiErrorModel error;
}
