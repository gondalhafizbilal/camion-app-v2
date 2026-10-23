import 'dart:async';

import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/notification_bell_with_badge.dart';
import 'package:camion/core/api/api_locale_mapper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/product_description_formatter.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/presentation/widgets/product_collection_card.dart';
import 'package:camion/features/searching/presentation/logic/search_graphql_cubit.dart';
import 'package:camion/features/searching/presentation/widgets/recent_search_sheet.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class HomeSectionDetailsScreen extends StatefulWidget {
  const HomeSectionDetailsScreen({
    super.key,
    required this.title,
    required this.section,
    this.slug,
    this.campaignEndsAt,
  });

  final String title;
  final String section;
  final String? slug;
  final DateTime? campaignEndsAt;

  @override
  State<HomeSectionDetailsScreen> createState() =>
      _HomeSectionDetailsScreenState();
}

class _HomeSectionDetailsScreenState extends State<HomeSectionDetailsScreen> {
  static const double _gridHorizontalPadding = 16;
  static const double _gridCrossAxisSpacing = 8;

  final HomeRepository _homeRepository = sl<HomeRepository>();
  final ScrollController _scrollController = ScrollController();

  bool _isGridView = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  String _selectedSortOption = '';

  List<HomeGraphqlProduct> _products = const [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  String _currentLanguage() {
    final appLanguage = context.read<LocalizationsCubit>().state.languageCode;
    return ApiLocaleMapper.toGraphqlLocale(appLanguage);
  }

  HomeProductSectionType _sectionType() {
    return switch (widget.section) {
      'featured' => HomeProductSectionType.featuredProducts,
      'popular' => HomeProductSectionType.popularProducts,
      'recentlyViewed' => HomeProductSectionType.recentlyViewed,
      _ => HomeProductSectionType.allProducts,
    };
  }

  HomeGraphqlSectionQuery _sectionQuery() {
    if (widget.section == 'all') {
      return const HomeGraphqlSectionQuery(itemsPerPage: 24);
    }
    if (widget.section == 'featuredCampaign') {
      return const HomeGraphqlSectionQuery(itemsPerPage: 10);
    }
    final sectionType = _sectionType();
    for (final definition in HomeRepository.defaultHomeGraphqlSections) {
      if (definition.type == sectionType) {
        return definition.query;
      }
    }
    return const HomeGraphqlSectionQuery(itemsPerPage: 10);
  }

  bool get _isPopularSection => widget.section == 'popular';
  bool get _showSortControls =>
      widget.section != 'related' && widget.section != 'recentlyViewed';
  bool get _showInlineResultsCount =>
      widget.section == 'related' || widget.section == 'recentlyViewed';

  String _titleWithCount(String title, int count) {
    return '$title ($count)';
  }

  List<String> _sortOptions() {
    return _isPopularSection
        ? PopularSortOption.values.map((e) => e.label).toList()
        : SearchSortOption.values.map((e) => e.label).toList();
  }

  String _localizedSortLabel(String label, bool isArabic) {
    if (!isArabic) return label;
    if (_isPopularSection) {
      switch (label) {
        case 'Most Viewed':
          return 'الأكثر مشاهدة';
        case 'Best Sellers':
          return 'الأكثر مبيعًا';
        case 'Most Favorited':
          return 'الأكثر تفضيلًا';
        case 'Most Rated':
          return 'الأعلى تقييمًا';
        default:
          return label;
      }
    }
    switch (label) {
      case 'Best Match':
        return 'الأفضل تطابقًا';
      case 'Price: Low to High':
        return 'السعر: من الأقل إلى الأعلى';
      case 'Price: High to Low':
        return 'السعر: من الأعلى إلى الأقل';
      case 'Best Sellers':
        return 'الأكثر مبيعًا';
      case 'Most Favorited':
        return 'الأكثر تفضيلًا';
      case 'New Arrivals':
        return 'وصل حديثًا';
      case 'Most Rated':
        return 'الأعلى تقييمًا';
      default:
        return label;
    }
  }

  String? _searchSortValue(String sortLabel) {
    final normalized = sortLabel.trim();
    if (normalized.isEmpty) return null;
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

  String? _popularSortValue(String sortLabel) {
    final normalized = sortLabel.trim();
    if (normalized.isEmpty) return null;
    switch (normalized) {
      case 'الأكثر مشاهدة':
        return PopularSortOption.mostViewed.apiValue;
      case 'Best Sellers':
      case 'الأكثر مبيعًا':
        return PopularSortOption.bestSellers.apiValue;
      case 'Most Favorited':
      case 'الأكثر تفضيلًا':
        return PopularSortOption.mostFavorited.apiValue;
      case 'Most Rated':
      case 'الأعلى تقييمًا':
        return PopularSortOption.mostRated.apiValue;
      case 'Most Viewed':
      default:
        return PopularSortOption.mostViewed.apiValue;
    }
  }

  Future<void> _openSortSheet() async {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final options = _sortOptions();
    String? tempSelection = _selectedSortOption.trim().isEmpty
        ? null
        : _selectedSortOption;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.r),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 14.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isArabic ? 'ترتيب حسب' : 'Sort By',
                              style: AppStyle.styleSemiBold25(
                                context,
                              ).copyWith(color: Colors.black),
                            ),
                          ),
                          AppTapFeedback(
                            onTap: () =>
                                setModalState(() => tempSelection = null),
                            borderRadius: BorderRadius.circular(4.r),
                            child: Text(
                              isArabic ? 'مسح' : 'Clear',
                              style: AppStyle.styleRegular15(context).copyWith(
                                color: const Color(0xFFCB262E),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFFCB262E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (
                            var index = 0;
                            index < options.length;
                            index++
                          ) ...[
                            _SelectionTile(
                              label: _localizedSortLabel(
                                options[index],
                                isArabic,
                              ),
                              selected: tempSelection == options[index],
                              onTap: () async {
                                final option = options[index];
                                if (tempSelection == option) {
                                  Navigator.of(sheetContext).pop();
                                  return;
                                }
                                setState(() {
                                  _selectedSortOption = option;
                                });
                                Navigator.of(sheetContext).pop();
                                await _loadInitial();
                              },
                            ),
                            if (index != options.length - 1)
                              SizedBox(height: 8.h),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadInitial() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _currentPage = 1;
      _errorMessage = null;
      _products = const [];
    });
    await _fetchPage(isLoadMore: false);
  }

  void _onScroll() {
    if (!_hasMore || _isLoading || _isLoadingMore) {
      return;
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 180) {
      _fetchPage(isLoadMore: true);
    }
  }

  Future<void> _fetchPage({required bool isLoadMore}) async {
    if (!mounted) return;
    if (isLoadMore && (!_hasMore || _isLoadingMore || _isLoading)) {
      return;
    }

    if (isLoadMore) {
      setState(() {
        _isLoadingMore = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final language = _currentLanguage();
    final sectionQuery = _sectionQuery();
    final itemsPerPage = sectionQuery.itemsPerPage;

    final result = await switch (widget.section) {
      'featured' => _homeRepository.getFeaturedGraphqlProducts(
        token: token,
        language: language,
        sort: _searchSortValue(_selectedSortOption),
        pageNumber: _currentPage,
        itemsPerPage: itemsPerPage,
      ),
      'featuredCampaign' =>
        (widget.slug ?? '').trim().isNotEmpty
            ? _homeRepository.getProductsByCategoryGraphql(
                token: token,
                language: language,
                slug: widget.slug!.trim(),
                pageNumber: _currentPage,
                itemsPerPage: itemsPerPage,
              )
            : _homeRepository.getProductsInFeaturedCampaignGraphql(
                token: token,
                language: language,
                sort: _searchSortValue(_selectedSortOption),
                pageNumber: _currentPage,
                itemsPerPage: itemsPerPage,
              ),
      'related' =>
        (widget.slug ?? '').trim().isNotEmpty
            ? _homeRepository.getRelatedGraphqlProducts(
                token: token,
                language: language,
                slug: (widget.slug ?? '').trim(),
                pageNumber: _currentPage,
                itemsPerPage: itemsPerPage,
              )
            : _homeRepository.getGraphqlProducts(
                token: token,
                language: language,
                pageNumber: _currentPage,
                itemsPerPage: itemsPerPage,
              ),
      'popular' => _homeRepository.getPopularGraphqlProducts(
        token: token,
        language: language,
        sort: _popularSortValue(_selectedSortOption),
        pageNumber: _currentPage,
        itemsPerPage: itemsPerPage,
      ),
      'recentlyViewed' => _homeRepository.getRecentlyViewedGraphqlProducts(
        token: token,
        language: language,
        pageNumber: _currentPage,
        itemsPerPage: itemsPerPage,
      ),
      _ => _homeRepository.getGraphqlProducts(
        token: token,
        language: language,
        sort: _searchSortValue(_selectedSortOption),
        pageNumber: _currentPage,
        itemsPerPage: itemsPerPage,
      ),
    };

    result.fold(
      (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error.message;
          _isLoading = false;
          _isLoadingMore = false;
        });
      },
      (newProducts) {
        if (!mounted) return;

        final merged = <HomeGraphqlProduct>[..._products];
        for (final item in newProducts) {
          if (!merged.any((existing) => existing.uuid == item.uuid)) {
            merged.add(item);
          }
        }

        setState(() {
          _products = merged;
          _currentPage += 1;
          _hasMore = newProducts.isNotEmpty;
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage = null;
        });

        if (!isLoadMore && merged.isNotEmpty) {
          unawaited(
            sl<AppsFlyerService>().logListView(
              contentType: widget.section,
              contentList: merged
                  .map((product) => product.uuid)
                  .where((value) => value.trim().isNotEmpty)
                  .toList(growable: false),
            ),
          );
        }
      },
    );
  }

  List<_SectionProductCardData> _buildItems(BuildContext context) {
    final localized = S.of(context);
    return _products
        .map(
          (product) => _SectionProductCardData(
            id: product.uuid,
            slug: product.slug,
            selectedVariantUuid: product.variantUuid ?? '',
            campaignLabel: product.campaign?.name.trim().isNotEmpty == true
                ? product.campaign!.name
                : '',
            campaignEndsAt: product.campaign?.finishesAt,
            name: product.title,
            subtitle: ProductDescriptionFormatter.resolveShort(
              brief: product.brief,
              descriptionHtml: product.descriptionHtml,
              description: product.description,
              fallback: localized.description,
            ),
            imageUrl: product.primaryVariantImageUrl,
            imageAssetPath: Assets.imagesShoes,
            price: product.formattedPrice,
            oldPrice: product.formattedOriginalPrice,
            currencyCode: product.formattedCurrencyCode,
            favoritesLabel:
                '${formatLocalizedNumber(context, product.likesCount)}  •  ${localized.favorites}',
            reviewsLabel:
                '${formatLocalizedNumber(context, product.averageRatingText, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product.reviewsCount)} ${localized.reviews}',
            canOpenDetails: true,
            wishlistEnabled: false,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final localized = S.of(context);
    final items = _buildItems(context);
    final resultCount = items.length;
    final showCampaignTimerPreview = widget.section == 'featuredCampaign';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 0),
              child: Directionality(
                textDirection:
                    Localizations.localeOf(context).languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Row(
                  children: [
                    AppTapFeedback(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: const Color(0xFF303030),
                        size: 30.sp,
                      ),
                    ),
                    SizedBox(width: 18.w),
                    Expanded(
                      child: Text(
                        _titleWithCount(widget.title, resultCount),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyle.styleSemiBold16(context).copyWith(
                          color: Colors.black,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    AppTapFeedback(
                      onTap: () => openRecentSearchSheet(context),
                      borderRadius: BorderRadius.circular(8.r),
                      child: SizedBox(
                        width: 40.w,
                        height: 40.h,
                        child: Image.asset(
                          'assets/images/searchicon.png',
                          width: 40.w,
                          height: 40.h,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    NotificationBellWithBadge(
                      onTap: () =>
                          AppNavigator.openNotificationsOrLogin(context),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection:
                        Localizations.localeOf(context).languageCode == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_showInlineResultsCount)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Spacer(),
                              SizedBox(width: 10.w),
                              Row(
                                children: [
                                  AppTapFeedback(
                                    onTap: () =>
                                        setState(() => _isGridView = false),
                                    borderRadius: BorderRadius.circular(5.r),
                                    child: Opacity(
                                      opacity: _isGridView ? 0.6 : 1,
                                      child: Image.asset(
                                        'assets/images/sorticon2.png',
                                        width: 24.w,
                                        height: 24.w,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  AppTapFeedback(
                                    onTap: () =>
                                        setState(() => _isGridView = true),
                                    borderRadius: BorderRadius.circular(5.r),
                                    child: Opacity(
                                      opacity: _isGridView ? 1 : 0.6,
                                      child: Image.asset(
                                        'assets/images/sorticon.png',
                                        width: 24.w,
                                        height: 24.w,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        if (!_showInlineResultsCount)
                          Row(
                            children: [
                              if (_showSortControls)
                                _SortByChip(
                                  label:
                                      Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'ar'
                                      ? 'ترتيب حسب'
                                      : 'Sort by',
                                  onTap: _openSortSheet,
                                ),
                              if (_showSortControls) SizedBox(width: 10.w),
                              const Spacer(),
                              Row(
                                children: [
                                  AppTapFeedback(
                                    onTap: () =>
                                        setState(() => _isGridView = false),
                                    borderRadius: BorderRadius.circular(5.r),
                                    child: Opacity(
                                      opacity: _isGridView ? 0.6 : 1,
                                      child: Image.asset(
                                        'assets/images/sorticon2.png',
                                        width: 24.w,
                                        height: 24.w,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  AppTapFeedback(
                                    onTap: () =>
                                        setState(() => _isGridView = true),
                                    borderRadius: BorderRadius.circular(5.r),
                                    child: Opacity(
                                      opacity: _isGridView ? 1 : 0.6,
                                      child: Image.asset(
                                        'assets/images/sorticon.png',
                                        width: 24.w,
                                        height: 24.w,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        if (_showInlineResultsCount) SizedBox(height: 12.h),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadInitial,
                child: (_isLoading && _products.isEmpty)
                    ? (_isGridView
                          ? GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                _gridHorizontalPadding.w,
                                8.h,
                                _gridHorizontalPadding.w,
                                28.h,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: _gridCrossAxisSpacing.w,
                                    mainAxisSpacing: 18.h,
                                    mainAxisExtent: ProductCollectionCard
                                        .compactCardHeight
                                        .h,
                                  ),
                              itemCount: 6,
                              itemBuilder: (_, __) => const _GridCardSkeleton(),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                15.5.w,
                                8.h,
                                15.5.w,
                                28.h,
                              ),
                              itemCount: 6,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 20.h),
                              itemBuilder: (_, __) => const _GridCardSkeleton(),
                            ))
                    : (_errorMessage != null && _products.isEmpty)
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          SizedBox(height: 160.h),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: AppStyle.styleRegular16(
                                  context,
                                ).copyWith(color: Colors.red),
                              ),
                              SizedBox(height: 10.h),
                              ElevatedButton(
                                onPressed: _loadInitial,
                                child: Text(localized.retry),
                              ),
                            ],
                          ),
                        ],
                      )
                    : (!_isLoading && _products.isEmpty)
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          SizedBox(height: 180.h),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: Text(
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'لا توجد منتجات'
                                    : 'No products found',
                                style: AppStyle.styleRegular16(
                                  context,
                                ).copyWith(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      )
                    : _isGridView
                    ? GridView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          _gridHorizontalPadding.w,
                          8.h,
                          _gridHorizontalPadding.w,
                          28.h,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: _gridCrossAxisSpacing.w,
                          mainAxisSpacing: 18.h,
                          mainAxisExtent:
                              ProductCollectionCard.compactCardHeight.h,
                        ),
                        itemCount: items.length + (_isLoadingMore ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index >= items.length) {
                            return const _GridCardSkeleton();
                          }
                          return _SectionGridCard(
                            item: items[index],
                            showCampaignTimerPreview: showCampaignTimerPreview,
                          );
                        },
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(15.5.w, 8.h, 15.5.w, 28.h),
                        itemCount: items.length + (_isLoadingMore ? 2 : 0),
                        separatorBuilder: (_, __) => SizedBox(height: 20.h),
                        itemBuilder: (context, index) {
                          if (index >= items.length) {
                            return const _GridCardSkeleton();
                          }
                          return _SectionListCard(
                            item: items[index],
                            showCampaignTimerPreview: showCampaignTimerPreview,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridCardSkeleton extends StatelessWidget {
  const _GridCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: ProductCollectionCard.compactCardHeight.h - 94.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5.r),
                topRight: Radius.circular(5.r),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 110.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  width: 82.w,
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 96.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionGridCard extends StatelessWidget {
  const _SectionGridCard({
    required this.item,
    required this.showCampaignTimerPreview,
  });

  final _SectionProductCardData item;
  final bool showCampaignTimerPreview;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ProductCollectionCard.compactCardWidth.w,
      child: ProductCollectionCard(
        productId: item.id,
        productSlug: item.slug,
        selectedVariantUuid: item.selectedVariantUuid,
        name: item.name,
        subtitle: item.subtitle,
        price: item.price,
        oldPrice: item.oldPrice,
        currencyCode: item.currencyCode,
        imageUrl: item.imageUrl,
        imageAssetPath: item.imageAssetPath,
        campaignLabel: item.campaignLabel,
        campaignEndsAt: item.campaignEndsAt,
        showCampaignTimerPreview: showCampaignTimerPreview,
        isInitiallyInWishList: false,
        wishlistEnabled: item.wishlistEnabled,
        favoritesLabel: item.favoritesLabel,
        reviewsLabel: item.reviewsLabel,
        onTap: () {
          if (item.id == '0' || !item.canOpenDetails) {
            return;
          }
          context.push(
            AppRouter.productDetails,
            extra: {
              'id': item.id,
              'slug': item.slug,
              'selectedVariantUuid': item.selectedVariantUuid,
            },
          );
        },
      ),
    );
  }
}

class _SectionListCard extends StatelessWidget {
  const _SectionListCard({
    required this.item,
    required this.showCampaignTimerPreview,
  });

  final _SectionProductCardData item;
  final bool showCampaignTimerPreview;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: ProductCollectionCard.expandedCardWidth.w,
        height: ProductCollectionCard.expandedCardHeight.h,
        child: ProductCollectionCard(
          productId: item.id,
          productSlug: item.slug,
          selectedVariantUuid: item.selectedVariantUuid,
          type: ProductCollectionCardType.expanded,
          name: item.name,
          subtitle: item.subtitle,
          price: item.price,
          oldPrice: item.oldPrice,
          currencyCode: item.currencyCode,
          imageUrl: item.imageUrl,
          imageAssetPath: item.imageAssetPath,
          campaignLabel: item.campaignLabel,
          campaignEndsAt: item.campaignEndsAt,
          showCampaignTimerPreview: showCampaignTimerPreview,
          isInitiallyInWishList: false,
          wishlistEnabled: item.wishlistEnabled,
          favoritesLabel: item.favoritesLabel,
          reviewsLabel: item.reviewsLabel,
          onTap: () {
            if (item.id == '0' || !item.canOpenDetails) {
              return;
            }
            context.push(
              AppRouter.productDetails,
              extra: {
                'id': item.id,
                'slug': item.slug,
                'selectedVariantUuid': item.selectedVariantUuid,
              },
            );
          },
        ),
      ),
    );
  }
}

class _SectionProductCardData {
  const _SectionProductCardData({
    required this.id,
    required this.slug,
    this.selectedVariantUuid = '',
    required this.name,
    required this.subtitle,
    required this.price,
    required this.oldPrice,
    required this.currencyCode,
    required this.favoritesLabel,
    required this.reviewsLabel,
    this.canOpenDetails = false,
    this.wishlistEnabled = false,
    this.imageUrl,
    this.imageAssetPath,
    this.campaignLabel = '',
    this.campaignEndsAt,
  });

  final String id;
  final String slug;
  final String selectedVariantUuid;
  final String name;
  final String subtitle;
  final String price;
  final String oldPrice;
  final String currencyCode;
  final String favoritesLabel;
  final String reviewsLabel;
  final bool canOpenDetails;
  final bool wishlistEnabled;
  final String? imageUrl;
  final String? imageAssetPath;
  final String campaignLabel;
  final DateTime? campaignEndsAt;
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppTapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 56.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF6F5) : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? const Color(0xFFCB262E) : const Color(0xFFE4E4E4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppStyle.styleRegular15(context).copyWith(
                  color: const Color(0xFF222222),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Container(
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFFCB262E)
                      : const Color(0xFFBDBDBD),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCB262E),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortByChip extends StatelessWidget {
  const _SortByChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppTapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999.r),
          border: Border.all(color: const Color(0xFFD9D9D9), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 18.sp,
              color: const Color(0xFFCB262E),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppStyle.styleRegular14(context).copyWith(
                color: const Color(0xFF2D2D2D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum PopularSortOption {
  mostViewed(label: 'Most Viewed', apiValue: 'most-viewed'),
  bestSellers(label: 'Best Sellers', apiValue: 'best-sellers'),
  mostFavorited(label: 'Most Favorited', apiValue: 'most-favorited'),
  mostRated(label: 'Most Rated', apiValue: 'most-rated');

  const PopularSortOption({required this.label, required this.apiValue});
  final String label;
  final String apiValue;
}
