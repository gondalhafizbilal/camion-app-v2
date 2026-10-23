import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/notification_bell_with_badge.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/connectivity_error_utils.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/product_description_formatter.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/presentation/widgets/grid_item_skeletonizer.dart';
import 'package:camion/features/home/presentation/widgets/product_collection_card.dart';
import 'package:camion/features/searching/presentation/logic/search_graphql_cubit.dart';
import 'package:camion/features/searching/presentation/widgets/recent_search_sheet.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SearchScreenWithProducts extends StatefulWidget {
  const SearchScreenWithProducts({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreenWithProducts> createState() =>
      _SearchScreenWithProductsState();
}

class _SearchScreenWithProductsState extends State<SearchScreenWithProducts> {
  static const double _gridHorizontalPadding = 16;
  static const double _gridCrossAxisSpacing = 8;
  static const double _listHorizontalPadding = 15.5;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;
  String _queryLabel = 'All products';
  String _selectedSortOption = '';

  static final List<String> _sortOptions = SearchSortOption.values
      .map((option) => option.label)
      .toList();

  String _localizedSortLabel(String label, bool isArabic) {
    if (!isArabic) return label;
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

  @override
  void initState() {
    super.initState();
    final lang = context.read<LocalizationsCubit>().state.languageCode;
    final isArabic = lang.toLowerCase().startsWith('ar');
    _queryLabel = isArabic ? 'كل المنتجات' : 'All products';
    final initialQuery = widget.initialQuery.trim();
    if (initialQuery.isNotEmpty) {
      _queryLabel = initialQuery;
      _searchController.text = initialQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleSearchSelected(initialQuery);
      });
    } else {
      context.read<SearchGraphqlCubit>().loadInitial(
        appLanguageCode: lang,
        filter: _currentFilter(),
      );
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 180) {
      context.read<SearchGraphqlCubit>().loadMore();
    }
  }

  void _handleSearchSelected(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    _searchController.text = query;
    setState(() {
      _queryLabel = query;
    });
    _runSearch();
  }

  SearchApiFilter _currentFilter() {
    return SearchApiFilter(
      sortLabel: _selectedSortOption,
      pageNumber: 1,
      itemsPerPage: 100,
    );
  }

  void _runSearch() {
    context.read<SearchGraphqlCubit>().search(
      query: _searchController.text,
      appLanguageCode: context.read<LocalizationsCubit>().state.languageCode,
      filter: _currentFilter(),
    );
  }

  Future<void> _refreshResults() async {
    await context.read<SearchGraphqlCubit>().refresh();
  }

  Future<void> _openSelectionSheet({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onApply,
  }) async {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    String? tempSelection = selectedValue;

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
                              title,
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
                                onApply(option);
                                if (context.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
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

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final horizontalPadding = _gridHorizontalPadding.w;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<SearchGraphqlCubit, SearchGraphqlState>(
          builder: (context, state) {
            final resultsCount = _resultsCount(state);
            return RefreshIndicator(
              onRefresh: _refreshResults,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12.h,
                        horizontalPadding,
                        0,
                      ),
                      child: Column(
                        children: [
                          Directionality(
                            textDirection: isArabic
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
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Text(
                                    isArabic
                                        ? 'نتائج البحث ($resultsCount)'
                                        : 'Search Results ($resultsCount)',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                AppTapFeedback(
                                  onTap: () => openRecentSearchSheet(
                                    context,
                                    onSearchSelected: _handleSearchSelected,
                                  ),
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
                                SizedBox(width: 14.w),
                                NotificationBellWithBadge(
                                  onTap: () =>
                                      AppNavigator.openNotificationsOrLogin(
                                        context,
                                      ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 28.h),
                          Directionality(
                            textDirection: isArabic
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            child: Row(
                              children: [
                                _SortByChip(
                                  label: isArabic ? 'ترتيب حسب' : 'Sort by',
                                  onTap: () => _openSelectionSheet(
                                    title: isArabic ? 'ترتيب حسب' : 'Sort By',
                                    options: _sortOptions,
                                    selectedValue: _selectedSortOption.isEmpty
                                        ? null
                                        : _selectedSortOption,
                                    onApply: (value) => setState(() {
                                      _selectedSortOption = value ?? '';
                                      _runSearch();
                                    }),
                                  ),
                                ),
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
                          ),
                          SizedBox(height: 12.h),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isArabic
                                  ? 'عرض نتائج البحث عن "$_queryLabel"'
                                  : 'Showing results for "$_queryLabel"',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w400,
                                height: 1.35,
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                  ),
                  if (state is SearchGraphqlLoading)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: _gridCrossAxisSpacing.w,
                          mainAxisSpacing: 22.h,
                          mainAxisExtent:
                              ProductCollectionCard.compactCardHeight.h,
                        ),
                        itemBuilder: (_, __) => const Skeletonizer(
                          enabled: true,
                          child: GridItemBuildingSkeleton(),
                        ),
                        itemCount: 8,
                      ),
                    )
                  else if (state is SearchGraphqlLoaded)
                    _isGridView
                        ? SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                            ),
                            sliver: SliverGrid.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: _gridCrossAxisSpacing.w,
                                    mainAxisSpacing: 22.h,
                                    mainAxisExtent: ProductCollectionCard
                                        .compactCardHeight
                                        .h,
                                  ),
                              itemCount:
                                  state.products.length +
                                  (state.isLoadingMore ? 2 : 0),
                              itemBuilder: (context, index) {
                                if (index >= state.products.length) {
                                  return const Skeletonizer(
                                    enabled: true,
                                    child: GridItemBuildingSkeleton(),
                                  );
                                }
                                return _SearchProductCard(
                                  product: state.products[index],
                                  expanded: false,
                                );
                              },
                            ),
                          )
                        : SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: _listHorizontalPadding.w,
                            ),
                            sliver: SliverList.separated(
                              itemCount:
                                  state.products.length +
                                  (state.isLoadingMore ? 2 : 0),
                              itemBuilder: (context, index) {
                                if (index >= state.products.length) {
                                  return const Skeletonizer(
                                    enabled: true,
                                    child: GridItemBuildingSkeleton(),
                                  );
                                }
                                return _SearchProductCard(
                                  product: state.products[index],
                                  expanded: true,
                                );
                              },
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 20.h),
                            ),
                          )
                  else if (state is SearchGraphqlError)
                    SliverToBoxAdapter(
                      child: isConnectivityErrorStatus(state.error.statusCode)
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: EdgeInsets.only(top: 40.h),
                              child: Center(
                                child: Text(
                                  state.error.message,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ),
                            ),
                    )
                  else
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  int _resultsCount(SearchGraphqlState state) {
    if (state is SearchGraphqlLoaded) {
      return state.products.length;
    }
    return 0;
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

class _SearchProductCard extends StatelessWidget {
  const _SearchProductCard({required this.product, required this.expanded});

  final HomeGraphqlProduct product;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final localized = S.of(context);

    final card = ProductCollectionCard(
      productId: product.uuid,
      productSlug: product.slug,
      campaignLabel: product.campaign?.name.trim().isNotEmpty == true
          ? product.campaign!.name
          : 'Special ...',
      campaignEndsAt: product.campaign?.finishesAt,
      type: expanded
          ? ProductCollectionCardType.expanded
          : ProductCollectionCardType.compact,
      name: product.title,
      subtitle: ProductDescriptionFormatter.resolveShort(
        brief: product.brief,
        descriptionHtml: product.descriptionHtml,
        description: product.description,
        fallback: localized.description,
      ),
      price: product.formattedPrice,
      oldPrice: product.formattedOriginalPrice,
      currencyCode: product.formattedCurrencyCode,
      imageUrl: product.primaryVariantImageUrl,
      imageAssetPath: Assets.imagesShoes,
      isInitiallyInWishList: false,
      wishlistEnabled: false,
      favoritesLabel:
          '${formatLocalizedNumber(context, product.likesCount)}  •  ${localized.favorites}',
      reviewsLabel:
          '${formatLocalizedNumber(context, product.averageRatingText, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product.reviewsCount)} ${localized.reviews}',
      onTap: () {
        if (product.uuid.trim().isEmpty) {
          return;
        }
        context.push(
          AppRouter.productDetails,
          extra: {
            'id': product.uuid,
            'slug': product.slug,
            'selectedVariantUuid': product.variantUuid ?? '',
          },
        );
      },
    );

    if (expanded) {
      return Center(
        child: SizedBox(
          width: ProductCollectionCard.expandedCardWidth.w,
          height: ProductCollectionCard.expandedCardHeight.h,
          child: card,
        ),
      );
    }

    return SizedBox(
      width: ProductCollectionCard.compactCardWidth.w,
      child: card,
    );
  }
}
