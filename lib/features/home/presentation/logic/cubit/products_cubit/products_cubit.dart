// import 'dart:async';
// import 'package:camion/core/api/api_error_model.dart';
// import 'package:camion/features/home/data/models/all_products_model/all_products_model.dart';
// import 'package:camion/features/home/data/repository/home_repo.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:camion/features/home/data/services/image_prefetcher.dart';
//
// part 'products_state.dart';
//
// class ProductsCubit extends Cubit<ProductsState> {
//   ProductsCubit(this.homeRepository) : super(ProductsInitial());
//
//   final HomeRepository homeRepository;
//
//   int currentPage = 1;
//   final int perPage = 28;
//   bool hasMore = true;
//   bool isLoading = false;
//   bool isLoadingMore = false;
//   bool hasLoadMoreError = false;
//
//   List<AllProductModel> allProducts = [];
//
//   bool isSearching = false;
//
//   Timer? _debounce;
//
//   Future<void> getProducts({bool isLoadMore = false, required String lang, String? search}) async {
//     if (!hasMore && isLoadMore) return;
//     if (isLoading) return;
//     if (isClosed) return;
//
//     if (!isLoadMore) {
//       currentPage = 1;
//       allProducts.clear();
//       hasMore = true;
//       isLoadingMore = false;
//       hasLoadMoreError = false;
//       isLoading = true;
//       emit(ProductsLoading());
//     } else {
//       isLoadingMore = true;
//       hasLoadMoreError = false;
//       isLoading = true;
//       emit(ProductsLoaded(products: allProducts, isSearching: false));
//     }
//
//     // emit(ProductsLoading());
//
//     final result = await homeRepository.getProducts(page: currentPage, perPage: perPage, lang: lang, search: search);
//     await result.fold<Future<void>>(
//       (error) async {
//         isLoading = false;
//
//         if (!isClosed) {
//           if (isLoadMore) {
//             isLoadingMore = false;
//             hasLoadMoreError = true;
//             emit(ProductsLoaded(products: allProducts, isSearching: false));
//           } else {
//             isLoadingMore = false;
//             hasLoadMoreError = false;
//             emit(ProductsError(error: error));
//           }
//         }
//       },
//       (products) async {
//         if (products.isEmpty) {
//           hasMore = false;
//         } else {
//           if (!isLoadMore) {
//             // Ensure images are cached before first paint of initial page.
//             await ImagePrefetcher.prefetchProductThumbnails(products, maxConcurrent: 8);
//           } else {
//             // Best-effort prefetch for subsequent pages without blocking UI.
//             // ignore: unawaited_futures
//             ImagePrefetcher.prefetchProductThumbnails(products, maxConcurrent: 6);
//           }
//           allProducts.addAll(products);
//           currentPage++;
//         }
//         if (!isClosed) {
//           isLoading = false;
//           isLoadingMore = false;
//           hasLoadMoreError = false;
//           emit(ProductsLoaded(products: allProducts, isSearching: false));
//         }
//       },
//     );
//   }
//
//   Future<void> searchProducts({required String query}) async {
//     if (isClosed) {
//       return;
//     }
//     if (_debounce?.isActive ?? false) _debounce?.cancel();
//
//     _debounce = Timer(const Duration(milliseconds: 500), () async {
//       if (query.isEmpty) {
//         isSearching = false;
//         if (!isClosed) {
//           emit(ProductsLoaded(products: allProducts, isSearching: false));
//           return;
//         }
//       }
//
//       isSearching = true;
//       emit(ProductsLoading());
//       final result = await homeRepository.searchProducts(query: query);
//       result.fold(
//         (error) {
//           if (!isClosed) {
//             emit(ProductsError(error: error));
//           }
//         },
//         (products) {
//           if (!isClosed) {
//             emit(ProductsLoaded(products: products, isSearching: true));
//           }
//         },
//       );
//     });
//   }
//
//   // void retryLoadMore() {
//   //   // hasLoadMoreError = false;
//   //   getProducts();
//   // }
// }

import 'dart:async';
import 'dart:collection';
import 'package:camion/core/api/api_error_model.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/features/home/data/models/all_products_model/all_products_model.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/data/services/image_prefetcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  ProductsCubit(this.homeRepository, {int perPage = 28})
    : perPage = perPage < 1 ? 1 : perPage,
      super(ProductsInitial());

  final HomeRepository homeRepository;
  static const bool _debugHomeProductsLogs = false;
  static final Map<String, List<AllProductModel>> _firstPageCacheByLanguage =
      <String, List<AllProductModel>>{};

  // ======================
  // Existing paging (USED BY HOME + OTHER SCREENS)
  // ======================
  int currentPage = 1;
  final int perPage;

  bool hasMore = true;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasLoadMoreError = false;

  List<AllProductModel> allProducts = [];
  final LinkedHashMap<String, AllProductModel> _productsByKey =
      LinkedHashMap<String, AllProductModel>();
  int _requestGeneration = 0;

  // ======================
  // Search handling (used in both modes)
  // ======================
  static const int _minSearchLength = 3;
  Timer? _debounce;
  int _token = 0;

  String _activeSearch = ''; // only used by old remote-search flow
  String _activeLang = '';
  bool get isSearching => _activeSearch.isNotEmpty;

  // ======================
  // NEW: Search Screen Session Mode (does NOT break home)
  // ======================
  bool _isSearchSession = false;

  // Cache used ONLY during Search screen
  final List<AllProductModel> _searchAllCache = [];
  List<AllProductModel> _searchVisible = [];

  // Snapshot to restore home when search closes
  List<AllProductModel> _snapshotProducts = [];
  int _snapshotCurrentPage = 1;
  bool _snapshotHasMore = true;
  bool _snapshotIsLoadingMore = false;
  bool _snapshotHasLoadMoreError = false;
  String _snapshotActiveSearch = '';
  String _snapshotActiveLang = '';

  // ======================
  // Existing API methods (KEEP AS-IS)
  // ======================

  /// Call on screen init (no search)
  Future<void> loadInitial({
    required String lang,
    bool forceRefresh = false,
  }) async {
    _debugLog(
      'loadInitial lang=$lang forceRefresh=$forceRefresh '
      'listSize=${allProducts.length} activeLang=$_activeLang '
      'isLoading=$isLoading currentPage=$currentPage',
    );
    if (!forceRefresh) {
      final normalizedLang = lang.trim().toLowerCase();
      final cachedFirstPage = _firstPageCacheByLanguage[normalizedLang];
      if (cachedFirstPage != null && cachedFirstPage.isNotEmpty) {
        _activeLang = lang;
        _activeSearch = '';
        currentPage = 2;
        hasMore = true;
        isLoading = false;
        isLoadingMore = false;
        hasLoadMoreError = false;
        _productsByKey
          ..clear()
          ..addEntries(cachedFirstPage.map((p) => MapEntry(_productKey(p), p)));
        allProducts = List<AllProductModel>.unmodifiable(_productsByKey.values);
        if (!isClosed) {
          emit(ProductsLoaded(products: allProducts, isSearching: false));
        }
        _debugLog(
          'loadInitial served from cache lang=$normalizedLang '
          'size=${allProducts.length} nextPage=$currentPage',
        );
        return;
      }
    }
    if (forceRefresh) {
      _activeSearch = '';
      await getProducts(
        isLoadMore: false,
        lang: lang,
        search: null,
        forceRefresh: true,
      );
      return;
    }
    await _applySearch(lang: lang, newSearch: '', forceRefresh: forceRefresh);
  }

  /// Call from TextField.onChanged
  void onSearchChanged({required String query, required String lang}) {
    final q = query.trim();

    _debounce?.cancel();
    final myToken = ++_token;

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (isClosed) return;
      if (myToken != _token) return;

      // ✅ If Search Screen session is active -> LOCAL FILTER ONLY
      if (_isSearchSession) {
        _applyLocalSearch(q);
        return;
      }

      // ✅ Default behavior for other screens (remote paging / remote search)
      if (q.isEmpty) {
        await _applySearch(lang: lang, newSearch: '');
        return;
      }

      if (q.length < _minSearchLength) return;

      await _applySearch(lang: lang, newSearch: q);
    });
  }

  /// Call from scroll listener (HOME pagination)
  Future<void> loadMore({required String lang}) async {
    // In search session we never load more; we already fetched all pages.
    if (_isSearchSession) return;
    // Avoid accidental load-more calls while list is being reset/reloaded.
    if (allProducts.isEmpty) return;

    _debugLog(
      'loadMore lang=$lang listSize=${allProducts.length} '
      'hasMore=$hasMore isLoading=$isLoading isLoadingMore=$isLoadingMore '
      'currentPage=$currentPage',
    );
    await getProducts(isLoadMore: true, lang: lang, search: _activeSearch);
  }

  Future<void> _applySearch({
    required String lang,
    required String newSearch,
    bool forceRefresh = false,
  }) async {
    if (_isSearchSession) return; // safeguard

    final normalizedLang = lang.trim().toLowerCase();
    final normalizedActiveLang = _activeLang.trim().toLowerCase();
    final languageChanged =
        normalizedLang.isNotEmpty && normalizedLang != normalizedActiveLang;
    final shouldForceRefresh = forceRefresh || languageChanged;

    // If same query and already have results, don't refetch
    if (!shouldForceRefresh &&
        !languageChanged &&
        newSearch == _activeSearch &&
        allProducts.isNotEmpty) {
      return;
    }

    _activeLang = lang;
    _activeSearch = newSearch;

    await getProducts(
      isLoadMore: false,
      lang: lang,
      search: _activeSearch.isEmpty ? null : _activeSearch,
      forceRefresh: shouldForceRefresh,
    );
  }

  // ======================
  // Main fetch method (USED BY HOME + OTHER SCREENS)
  // ======================
  Future<void> getProducts({
    bool isLoadMore = false,
    required String lang,
    String? search,
    bool forceRefresh = false,
  }) async {
    // Block this method while Search session is active, so home doesn’t fight the state.
    if (_isSearchSession) return;

    if (isClosed) return;
    if (!hasMore && isLoadMore) return;
    if (isLoading && !forceRefresh) return;

    _debugLog(
      'getProducts start isLoadMore=$isLoadMore forceRefresh=$forceRefresh '
      'lang=$lang search=${search ?? ''} listBefore=${allProducts.length} '
      'activeLang=$_activeLang currentPage=$currentPage hasMore=$hasMore '
      'isLoading=$isLoading gen=$_requestGeneration',
    );

    if (!isLoadMore && forceRefresh) {
      _requestGeneration++;
      _activeLang = lang;
      currentPage = 1;
      allProducts = <AllProductModel>[];
      _productsByKey.clear();
      hasMore = true;
      isLoadingMore = false;
      hasLoadMoreError = false;
      _debugLog(
        'reset(forceRefresh) done size=${allProducts.length} '
        'currentPage=$currentPage gen=$_requestGeneration',
      );

      isLoading = true;
      emit(ProductsLoading());
    } else if (!isLoadMore) {
      _requestGeneration++;
      _activeLang = lang;
      currentPage = 1;
      allProducts = <AllProductModel>[];
      _productsByKey.clear();
      hasMore = true;
      isLoadingMore = false;
      hasLoadMoreError = false;
      _debugLog(
        'reset(initial) done size=${allProducts.length} '
        'currentPage=$currentPage gen=$_requestGeneration',
      );

      isLoading = true;
      emit(ProductsLoading());
    } else {
      isLoadingMore = true;
      hasLoadMoreError = false;
      isLoading = true;

      emit(ProductsLoaded(products: allProducts, isSearching: isSearching));
    }
    final int requestGeneration = _requestGeneration;
    _debugLog(
      'request prepared gen=$requestGeneration isLoadMore=$isLoadMore '
      'page=$currentPage lang=$lang listNow=${allProducts.length}',
    );

    final result = await homeRepository.getProducts(
      page: currentPage,
      perPage: perPage,
      lang: lang,
      search: search,
    );

    await result.fold<Future<void>>(
      (ApiErrorModel error) async {
        if (requestGeneration != _requestGeneration) return;
        _debugLog(
          'response error gen=$requestGeneration isLoadMore=$isLoadMore '
          'page=$currentPage lang=$lang status=${error.statusCode} '
          'message=${error.message}',
        );
        isLoading = false;
        if (isClosed) return;

        if (isLoadMore) {
          isLoadingMore = false;
          hasLoadMoreError = true;
          emit(ProductsLoaded(products: allProducts, isSearching: isSearching));
        } else {
          isLoadingMore = false;
          hasLoadMoreError = false;
          emit(ProductsError(error: error));
        }
      },
      (List<AllProductModel> products) async {
        if (requestGeneration != _requestGeneration) return;
        _debugLog(
          'response success gen=$requestGeneration isLoadMore=$isLoadMore '
          'page=$currentPage lang=$lang responseSize=${products.length} '
          'listBeforeMerge=${allProducts.length}',
        );
        if (products.isEmpty) {
          hasMore = false;
          _debugLog('response empty -> hasMore=false');
        } else {
          if (!isLoadMore) {
            await ImagePrefetcher.prefetchProductThumbnails(
              products,
              maxConcurrent: 8,
            );
          } else {
            // ignore: unawaited_futures
            ImagePrefetcher.prefetchProductThumbnails(
              products,
              maxConcurrent: 6,
            );
          }

          final addedCount = _appendUniqueProducts(products);
          if (!isLoadMore &&
              (search == null || search.trim().isEmpty) &&
              lang.trim().isNotEmpty) {
            final cacheKey = lang.trim().toLowerCase();
            _firstPageCacheByLanguage[cacheKey] = List<AllProductModel>.from(
              allProducts,
            );
            _debugLog(
              'first page cached lang=$cacheKey size=${allProducts.length}',
            );
          }
          // Advance page regardless so overlapping backend pages
          // never stop pagination early; dedupe still prevents duplicates.
          currentPage++;
          if (addedCount == 0) {
            // Keep loading next pages; backend can have overlap.
          }
          _debugLog(
            'merge done added=$addedCount listAfterMerge=${allProducts.length} '
            'nextPage=$currentPage hasMore=$hasMore',
          );
        }

        if (isClosed) return;

        isLoading = false;
        isLoadingMore = false;
        hasLoadMoreError = false;

        emit(ProductsLoaded(products: allProducts, isSearching: isSearching));
        _debugLog(
          'emit ProductsLoaded size=${allProducts.length} '
          'activeLang=$_activeLang isSearching=$isSearching',
        );
      },
    );
  }

  // ======================
  // ✅ NEW: Search Screen Session API
  // ======================

  /// Call ONLY from SearchScreen initState.
  /// - Takes snapshot of current home products/paging
  /// - Fetches ALL products (all pages) fresh
  /// - Caches them and enables LOCAL search
  Future<void> startSearchSession({required String lang}) async {
    if (isClosed) return;
    if (_isSearchSession) return;

    // Snapshot current state to restore later
    _snapshotProducts = List<AllProductModel>.from(allProducts);
    _snapshotCurrentPage = currentPage;
    _snapshotHasMore = hasMore;
    _snapshotIsLoadingMore = isLoadingMore;
    _snapshotHasLoadMoreError = hasLoadMoreError;
    _snapshotActiveSearch = _activeSearch;
    _snapshotActiveLang = _activeLang;

    // Enter search session
    _isSearchSession = true;

    // reset session data
    _searchAllCache.clear();
    _searchVisible = [];
    _activeSearch = ''; // not used in session but keep clean
    _activeLang = lang;

    // show loading in search screen
    isLoading = true;
    isLoadingMore = false;
    hasLoadMoreError = false;
    emit(ProductsLoading());

    // Fetch ALL pages
    int page = 1;
    while (true) {
      final result = await homeRepository.getProducts(
        page: page,
        perPage: perPage,
        lang: lang,
        search: null,
      );

      bool stop = false;

      await result.fold<Future<void>>(
        (ApiErrorModel error) async {
          stop = true;
          isLoading = false;
          if (isClosed) return;
          emit(ProductsError(error: error));
        },
        (List<AllProductModel> products) async {
          if (products.isEmpty) {
            stop = true;
            return;
          }

          // Prefetch thumbnails: await on first page only for faster initial UX
          if (page == 1) {
            await ImagePrefetcher.prefetchProductThumbnails(
              products,
              maxConcurrent: 8,
            );
          } else {
            // ignore: unawaited_futures
            ImagePrefetcher.prefetchProductThumbnails(
              products,
              maxConcurrent: 6,
            );
          }

          _searchAllCache.addAll(products);
          _searchVisible = List<AllProductModel>.from(_searchAllCache);

          if (!isClosed) {
            emit(ProductsLoaded(products: _searchVisible, isSearching: false));
          }

          // Keep paging until server returns an empty list.
          page++;
        },
      );

      if (stop) break;
      if (isClosed) return;
    }

    if (isClosed) return;

    isLoading = false;
    _searchVisible = List<AllProductModel>.from(_searchAllCache);

    emit(ProductsLoaded(products: _searchVisible, isSearching: false));
  }

  /// Call ONLY from SearchScreen dispose.
  /// Restores home list/paging exactly as it was.
  void endSearchSession() {
    if (!_isSearchSession) return;

    _debounce?.cancel();
    _token++;

    // exit session
    _isSearchSession = false;

    // clear session cache
    _searchAllCache.clear();
    _searchVisible = [];

    // restore snapshots
    allProducts = List<AllProductModel>.from(_snapshotProducts);
    _productsByKey
      ..clear()
      ..addEntries(allProducts.map((p) => MapEntry(_productKey(p), p)));
    currentPage = _snapshotCurrentPage;
    hasMore = _snapshotHasMore;
    isLoadingMore = _snapshotIsLoadingMore;
    hasLoadMoreError = _snapshotHasLoadMoreError;
    _activeSearch = _snapshotActiveSearch;
    _activeLang = _snapshotActiveLang;

    // emit restored state so Home doesn't break visually
    if (!isClosed) {
      emit(
        ProductsLoaded(
          products: allProducts,
          isSearching: _activeSearch.isNotEmpty,
        ),
      );
    }
  }

  void _applyLocalSearch(String q) {
    if (!_isSearchSession) return;

    // If not loaded yet, ignore
    if (_searchAllCache.isEmpty) return;

    // cleared -> show all
    if (q.isEmpty) {
      _searchVisible = List<AllProductModel>.from(_searchAllCache);
      emit(ProductsLoaded(products: _searchVisible, isSearching: false));
      return;
    }

    if (q.length < _minSearchLength) return;

    final query = q.toLowerCase();

    // Only filtering by name because that is guaranteed by your shared usage.
    _searchVisible = _searchAllCache
        .where((p) {
          final name = p.name.toString().toLowerCase();
          return name.contains(query);
        })
        .toList(growable: false);

    emit(ProductsLoaded(products: _searchVisible, isSearching: true));
  }

  void clearCache() {
    _debugLog(
      'clearCache before size=${allProducts.length} currentPage=$currentPage '
      'activeLang=$_activeLang gen=$_requestGeneration',
    );
    _debounce?.cancel();
    _token++;
    _activeSearch = '';
    _activeLang = '';
    _requestGeneration++;

    if (_isSearchSession) {
      _isSearchSession = false;
      _searchAllCache.clear();
      _searchVisible = [];
    }

    currentPage = 1;
    hasMore = true;
    isLoading = false;
    isLoadingMore = false;
    hasLoadMoreError = false;
    allProducts = <AllProductModel>[];
    _productsByKey.clear();

    if (!isClosed) {
      emit(ProductsInitial());
    }
    _debugLog(
      'clearCache after size=${allProducts.length} currentPage=$currentPage '
      'activeLang=$_activeLang gen=$_requestGeneration',
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  String _productKey(AllProductModel product) {
    if (product.id > 0) return 'id:${product.id}';
    final slug = product.slug.trim().toLowerCase();
    if (slug.isNotEmpty) return 'slug:$slug';
    final permalink = product.permalink.trim().toLowerCase();
    if (permalink.isNotEmpty) return 'link:$permalink';
    return 'fallback:${product.name.trim().toLowerCase()}';
  }

  int _appendUniqueProducts(List<AllProductModel> incoming) {
    var added = 0;
    for (final product in incoming) {
      final key = _productKey(product);
      final existed = _productsByKey.containsKey(key);
      _productsByKey[key] = product;
      if (!existed) added++;
    }
    allProducts = List<AllProductModel>.unmodifiable(_productsByKey.values);
    return added;
  }

  void _debugLog(String message) {
    if (!_debugHomeProductsLogs) return;
    appLog(message, name: 'HOME_PRODUCTS_DEBUG');
  }
}
