import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/notification_bell_with_badge.dart';
import 'package:camion/config/widgets/custom_cached_network_image.dart';
import 'package:camion/core/api/local_status_codes.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/product_description_formatter.dart';
import 'package:camion/features/cart/data/repository/cart_repo.dart';
import 'package:camion/features/cart/presentation/logic/cubit/add_cart_cubit/add_cart_cubit.dart';
import 'package:camion/features/cart/presentation/logic/cubit/get_cart_cubit/get_cart_cubit.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/models/slider_items/slider_item_model.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/presentation/logic/cubit/get_sub_categories/get_sub_categories_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/product_by_category_banners/product_by_category_banners_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/product_by_category_cubit/product_by_category_cubit.dart';
import 'package:camion/features/home/presentation/widgets/list_view_item_skeletonizer.dart';
import 'package:camion/features/home/presentation/widgets/product_collection_card.dart';
import 'package:camion/features/searching/presentation/widgets/recent_search_sheet.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProductsByCategoryScreen extends StatelessWidget {
  const ProductsByCategoryScreen({
    super.key,
    required this.slug,
    this.id,
    this.parentName,
    this.parentSlug,
    this.childName,
    this.viewAllCategories = const [],
  });

  final String slug;
  final int? id;
  final String? parentName;
  final String? parentSlug;
  final String? childName;
  final List<HomeGraphqlCategory> viewAllCategories;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProductByCategoryCubit(sl<HomeRepository>()),
        ),
        BlocProvider(
          create: (context) =>
              ProductByCategoryBannersCubit(sl<HomeRepository>()),
        ),
        BlocProvider(create: (context) => AddCartCubit(sl<CartRepository>())),
        BlocProvider(create: (context) => GetCartCubit(sl<CartRepository>())),
        BlocProvider(
          create: (context) => GetSubCategoriesCubit(sl<HomeRepository>()),
        ),
      ],
      child: ProductsByCategoryScreenBody(
        slug: slug,
        id: id,
        parentName: parentName,
        parentSlug: parentSlug,
        childName: childName,
        viewAllCategories: viewAllCategories,
      ),
    );
  }
}

class ProductsByCategoryScreenBody extends StatefulWidget {
  const ProductsByCategoryScreenBody({
    super.key,
    required this.slug,
    this.id,
    this.parentName,
    this.parentSlug,
    this.childName,
    this.viewAllCategories = const [],
  });

  final String slug;
  final int? id;
  final String? parentName;
  final String? parentSlug;
  final String? childName;
  final List<HomeGraphqlCategory> viewAllCategories;

  @override
  State<ProductsByCategoryScreenBody> createState() =>
      _ProductsByCategoryScreenBodyState();
}

class _ProductsByCategoryScreenBodyState
    extends State<ProductsByCategoryScreenBody> {
  static const double _gridHorizontalPadding = 16;
  static const double _gridCrossAxisSpacing = 8;

  final ScrollController _scrollController = ScrollController();
  bool _isGridView = true;
  _SortByOption? _selectedSortOption;
  final Set<String> _selectedViewAllCategorySlugs = <String>{};

  String? _sortApiValue(_SortByOption? option) {
    if (option == null) {
      return null;
    }
    return switch (option) {
      _SortByOption.mostRelevant => 'best-match',
      _SortByOption.bestsellers => 'best-sellers',
      _SortByOption.mostFavorited => 'most-favorited',
      _SortByOption.newArrivals => 'new-arrivals',
      _SortByOption.mostRated => 'most-rated',
      _SortByOption.lowToHighPrice => 'price:low-to-high',
      _SortByOption.highToLowPrice => 'price:high-to-low',
    };
  }

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    final slug = widget.parentSlug?.trim() ?? '';
    if (slug.isNotEmpty) {
      context.go(
        '${AppRouter.selectingFromBottomNavBar}?tab=1&categorySlug=${Uri.encodeQueryComponent(slug)}',
      );
      return;
    }
    context.go('${AppRouter.selectingFromBottomNavBar}?tab=1');
  }

  String _sortByLabel(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? 'ترتيب حسب' : 'Sort by';
  }

  String _categoryLabel(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? 'التصنيف' : 'Category';
  }

  bool get _showCategoryShareButton => false;

  Future<void> _shareCategory(BuildContext context) async {
    final shareLink = sl<AppsFlyerService>().buildCategoryShareLink(
      categorySlug: widget.slug.trim().isNotEmpty ? widget.slug.trim() : null,
      categoryId: widget.id,
      parentName: widget.parentName,
      parentSlug: widget.parentSlug,
      childName: widget.childName,
    );
    if (shareLink == null || shareLink.trim().isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    final shareOrigin = renderBox != null
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null;

    await SharePlus.instance.share(
      ShareParams(
        text: shareLink,
        subject: _categoryLabel(context),
        sharePositionOrigin: shareOrigin,
      ),
    );
  }

  bool get _showCategoryFilter => _isViewAllChildName(widget.childName);

  bool _isViewAllChildName(String? value) {
    final child = value?.trim() ?? '';
    if (child.isEmpty) return false;

    final normalized = child.toLowerCase();
    final localized = S.of(context).view_all.trim().toLowerCase();
    return normalized == 'view all' || normalized == localized;
  }

  List<HomeGraphqlCategory> get _availableViewAllCategories {
    return widget.viewAllCategories
        .where(
          (category) =>
              category.name.trim().isNotEmpty &&
              category.slug.trim().isNotEmpty,
        )
        .toList();
  }

  List<String> _activeViewAllCategorySlugs() {
    final categories = _availableViewAllCategories;
    final selected = categories
        .map((category) => category.slug.trim())
        .where(_selectedViewAllCategorySlugs.contains)
        .toSet()
        .toList();
    final baseSlug = widget.slug.trim();

    // When a third-level category is selected, query only by those slugs.
    // When nothing is selected (including Clear), fall back to the default
    // second-level category slug.
    if (selected.isNotEmpty) {
      return selected.where((slug) => slug.isNotEmpty).toSet().toList();
    }

    return baseSlug.isEmpty ? const <String>[] : <String>[baseSlug];
  }

  Future<void> _loadProducts({bool isLoadMore = false}) async {
    await context.read<ProductByCategoryCubit>().getProductsByCategory(
      slug: widget.slug,
      lang: context.read<LocalizationsCubit>().state.languageCode,
      sort: _sortApiValue(_selectedSortOption),
      categorySlugs: _showCategoryFilter ? _activeViewAllCategorySlugs() : null,
      isLoadMore: isLoadMore,
    );
  }

  Future<void> _openSortSheet() async {
    final initialSelection = _selectedSortOption;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _SortByBottomSheet(
          selectedOption: _selectedSortOption,
          onApply: (option) async {
            if (option == initialSelection) {
              return;
            }

            setState(() {
              _selectedSortOption = option;
            });

            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
            await _loadProducts();
          },
        );
      },
    );
  }

  Future<void> _openCategorySheet() async {
    final categories = _availableViewAllCategories;
    if (categories.isEmpty) return;

    final initialSelection = Set<String>.from(_selectedViewAllCategorySlugs);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _CategoryFilterBottomSheet(
          categories: categories,
          selectedSlugs: initialSelection,
          onApply: (selectedSlugs) async {
            final normalizedSelection = selectedSlugs
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toSet();
            if (normalizedSelection.length ==
                    _selectedViewAllCategorySlugs.length &&
                normalizedSelection.containsAll(
                  _selectedViewAllCategorySlugs,
                )) {
              return;
            }

            setState(() {
              _selectedViewAllCategorySlugs
                ..clear()
                ..addAll(normalizedSelection);
            });
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
            await _loadProducts();
          },
        );
      },
    );
  }

  String _displayTitle() {
    final parent = widget.parentName?.trim() ?? '';
    final child = widget.childName?.trim() ?? '';

    if (parent.isNotEmpty && child.isNotEmpty) {
      if (_isViewAllChildName(child)) {
        return parent;
      }
      return '$parent / $child';
    }
    if (child.isNotEmpty) return child;
    if (parent.isNotEmpty) return parent;
    return widget.slug;
  }

  String _displayTitleWithCount(int count) {
    return '${_displayTitle()} ($count)';
  }

  bool _isConnectivityErrorStatus(int? statusCode) {
    return statusCode == LocalStatusCodes.connectionError ||
        statusCode == LocalStatusCodes.connectionTimeout ||
        statusCode == LocalStatusCodes.sendTimeout ||
        statusCode == LocalStatusCodes.receiveTimeout;
  }

  void _onScroll() {
    final cubit = context.read<ProductByCategoryCubit>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      if (cubit.hasMore && !cubit.isLoadingMore && !cubit.hasLoadMoreError) {
        _loadProducts(isLoadMore: true);
      }
    }
  }

  Future<void> _refreshProducts() async {
    final languageCode = context.read<LocalizationsCubit>().state.languageCode;
    final bannerCubit = context.read<ProductByCategoryBannersCubit>();
    await _loadProducts();
    await bannerCubit.getBanners(
      language: languageCode,
      slug: widget.slug,
      parentSlug: widget.parentSlug,
      forceRefresh: true,
    );
    if (!mounted) return;
    if (widget.id != null) {
      await context.read<GetSubCategoriesCubit>().getSubCategories(
        lang: languageCode,
        id: widget.id!,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<GetCartCubit>().getCart(
      context.read<LocalizationsCubit>().state.languageCode,
    );
    if (widget.slug.trim().isNotEmpty) {
      unawaited(
        sl<AppsFlyerService>().logCategoryView(
          categorySlug: widget.slug.trim(),
          categoryId: widget.id,
          parentName: widget.parentName,
          childName: widget.childName,
        ),
      );
    }
    _loadProducts();
    context.read<ProductByCategoryBannersCubit>().getBanners(
      language: context.read<LocalizationsCubit>().state.languageCode,
      slug: widget.slug,
      parentSlug: widget.parentSlug,
    );
    if (widget.id != null) {
      context.read<GetSubCategoriesCubit>().getSubCategories(
        lang: context.read<LocalizationsCubit>().state.languageCode,
        id: widget.id!,
      );
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: BlocBuilder<ProductByCategoryCubit, ProductByCategoryState>(
            builder: (context, state) {
              final products = state is ProductByCategoryLoaded
                  ? state.products
                  : <HomeGraphqlProduct>[];
              final bannersState = context
                  .watch<ProductByCategoryBannersCubit>()
                  .state;

              final items = _buildItems(context, products);
              final scrollSlivers = <Widget>[
                _buildBannerSection(context, bannersState),
                if (widget.id != null)
                  SliverToBoxAdapter(
                    child: _SubCategoriesStrip(
                      categoryId: widget.id!,
                      currentParentTitle: _displayTitle(),
                      currentParentSlug:
                          widget.parentSlug?.trim().isNotEmpty == true
                          ? widget.parentSlug!.trim()
                          : widget.slug,
                      isConnectivityErrorStatus: _isConnectivityErrorStatus,
                    ),
                  ),
                ..._buildProductSlivers(context, state, items),
              ];

              return Column(
                children: [
                  _buildPinnedHeader(context, products.length),
                  _buildPinnedSortRow(context),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshProducts,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: scrollSlivers,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedHeader(BuildContext context, int resultCount) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 0),
      child: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          children: [
            AppTapFeedback(
              onTap: _handleBackNavigation,
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
                _displayTitleWithCount(resultCount),
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
            if (_showCategoryShareButton)
              AppTapFeedback(
                onTap: () => _shareCategory(context),
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 40.w,
                  height: 40.h,
                  child: SvgPicture.asset(
                    Assets.imagesShareProduct,
                    width: 40.w,
                    height: 40.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            SizedBox(width: 12.w),
            NotificationBellWithBadge(
              onTap: () => AppNavigator.openNotificationsOrLogin(context),
              borderRadius: BorderRadius.circular(8.r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedSortRow(BuildContext context) {
    final showCategoryFilter = _showCategoryFilter;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: Localizations.localeOf(context).languageCode == 'ar'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Row(
              children: [
                if (showCategoryFilter)
                  _FilterChip(
                    label: _categoryLabel(context),
                    onTap: _availableViewAllCategories.isEmpty
                        ? () {}
                        : _openCategorySheet,
                  ),
                if (showCategoryFilter) SizedBox(width: 10.w),
                _FilterChip(
                  label: _sortByLabel(context),
                  icon: Icons.swap_vert_rounded,
                  iconColor: const Color(0xFFCB262E),
                  onTap: _openSortSheet,
                ),
                const Spacer(),
                Row(
                  children: [
                    AppTapFeedback(
                      onTap: () => setState(() => _isGridView = false),
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
                      onTap: () => setState(() => _isGridView = true),
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
        ],
      ),
    );
  }

  Widget _buildBannerSection(
    BuildContext context,
    ProductByCategoryBannersState state,
  ) {
    if (state is ProductByCategoryBannersLoading ||
        state is ProductByCategoryBannersInitial) {
      return const SliverToBoxAdapter(
        child: _ProductByCategoryBannerSkeleton(),
      );
    }

    if (state is ProductByCategoryBannersError) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (state is! ProductByCategoryBannersLoaded || state.banners.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: _ProductByCategoryBannerCarousel(banners: state.banners),
      ),
    );
  }

  List<Widget> _buildProductSlivers(
    BuildContext context,
    ProductByCategoryState state,
    List<_SectionProductCardData> items,
  ) {
    if (state is ProductByCategoryInitial ||
        state is ProductByCategoryLoading) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            _gridHorizontalPadding.w,
            8.h,
            _gridHorizontalPadding.w,
            28.h,
          ),
          sliver: _isGridView
              ? SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: _gridCrossAxisSpacing.w,
                    mainAxisSpacing: 18.h,
                    mainAxisExtent: ProductCollectionCard.compactCardHeight.h,
                  ),
                  itemCount: 6,
                  itemBuilder: (_, __) => const Skeletonizer(
                    enabled: true,
                    child: _GridCardSkeleton(),
                  ),
                )
              : SliverList.builder(
                  itemCount: 6,
                  itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Skeletonizer(
                      enabled: true,
                      child: ListViewItemBuildingSkeleton(),
                    ),
                  ),
                ),
        ),
      ];
    }

    if (state is ProductByCategoryError) {
      if (_isConnectivityErrorStatus(state.error.statusCode) ||
          state.error.statusCode == LocalStatusCodes.badResponse ||
          state.error.statusCode == LocalStatusCodes.unknown ||
          state.error.statusCode == LocalStatusCodes.defaultError ||
          (state.error.statusCode != null && state.error.statusCode! >= 500)) {
        return _buildFallbackProductSlivers(items);
      }
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(state.error.icon, color: Colors.red, size: 50.sp),
                SizedBox(height: 20.h),
                Text(
                  state.error.message,
                  style: TextStyle(fontSize: 16.sp, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                ElevatedButton(
                  onPressed: () => _loadProducts(),
                  child: Text(S.of(context).retry),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (state is ProductByCategoryLoaded && state.products.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'لا توجد منتجات'
                    : 'No products found',
                style: AppStyle.styleRegular16(
                  context,
                ).copyWith(color: Colors.grey),
              ),
            ),
          ),
        ),
      ];
    }

    final isLoadingMore = context.watch<ProductByCategoryCubit>().isLoadingMore;
    final totalCount = items.length + (isLoadingMore ? 2 : 0);

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          _gridHorizontalPadding.w,
          8.h,
          _gridHorizontalPadding.w,
          28.h,
        ),
        sliver: _isGridView
            ? SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: _gridCrossAxisSpacing.w,
                  mainAxisSpacing: 18.h,
                  mainAxisExtent: ProductCollectionCard.compactCardHeight.h,
                ),
                itemCount: totalCount,
                itemBuilder: (context, index) {
                  if (index >= items.length) {
                    return const Skeletonizer(
                      enabled: true,
                      child: _GridCardSkeleton(),
                    );
                  }
                  return _SectionGridCard(item: items[index]);
                },
              )
            : SliverList.separated(
                itemCount: totalCount,
                itemBuilder: (context, index) {
                  if (index >= items.length) {
                    return const Skeletonizer(
                      enabled: true,
                      child: ListViewItemBuildingSkeleton(),
                    );
                  }
                  return _SectionListCard(item: items[index]);
                },
                separatorBuilder: (_, __) => SizedBox(height: 20.h),
              ),
      ),
    ];
  }

  List<Widget> _buildFallbackProductSlivers(
    List<_SectionProductCardData> items,
  ) {
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          _gridHorizontalPadding.w,
          8.h,
          _gridHorizontalPadding.w,
          28.h,
        ),
        sliver: _isGridView
            ? SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: _gridCrossAxisSpacing.w,
                  mainAxisSpacing: 18.h,
                  mainAxisExtent: ProductCollectionCard.compactCardHeight.h,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _SectionGridCard(item: items[index]),
              )
            : SliverList.separated(
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _SectionListCard(item: items[index]),
                separatorBuilder: (_, __) => SizedBox(height: 20.h),
              ),
      ),
    ];
  }

  List<_SectionProductCardData> _buildItems(
    BuildContext context,
    List<HomeGraphqlProduct> products,
  ) {
    final localized = S.of(context);
    return products
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
            averageRating: product.averageRatingText,
            reviewCount: product.reviewsCount,
            currencyCode: product.formattedCurrencyCode,
            currencySymbol: product.formattedCurrencyCode,
            favoritesCount: product.likesCount,
            isInitiallyInWishList: false,
          ),
        )
        .toList();
  }
}

class _ProductByCategoryBannerCarousel extends StatefulWidget {
  const _ProductByCategoryBannerCarousel({required this.banners});

  final List<SliderItemModel> banners;

  @override
  State<_ProductByCategoryBannerCarousel> createState() =>
      _ProductByCategoryBannerCarouselState();
}

class _ProductByCategoryBannerCarouselState
    extends State<_ProductByCategoryBannerCarousel> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118.h,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() => _currentIndex = index);
            },
            itemBuilder: (_, index) {
              final banner = widget.banners[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (banner.imageUrl.trim().isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: banner.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Image.asset(
                        Assets.imagesBlackFriday,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Image.asset(Assets.imagesBlackFriday, fit: BoxFit.cover),
                ],
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.banners.length, (dotIndex) {
                final distance = (_currentIndex.toDouble() - dotIndex).abs();
                final strength = (1 - distance.clamp(0.0, 1.0)).toDouble();
                final width = 8.w + (14.w * strength);
                final height = 8.h;
                final fillAlpha = (0.1 + (0.9 * strength)).clamp(0.0, 1.0);
                final borderAlpha = (0.6 + (0.4 * strength)).clamp(0.0, 1.0);
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: fillAlpha),
                    borderRadius: BorderRadius.circular(999.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: borderAlpha),
                      width: 1.1,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductByCategoryBannerSkeleton extends StatelessWidget {
  const _ProductByCategoryBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Skeletonizer(
        enabled: true,
        child: SizedBox(
          height: 118.h,
          width: double.infinity,
          child: Container(color: const Color(0xFFE8E8E8)),
        ),
      ),
    );
  }
}

class _SubCategoriesStrip extends StatelessWidget {
  const _SubCategoriesStrip({
    required this.categoryId,
    required this.currentParentTitle,
    required this.currentParentSlug,
    required this.isConnectivityErrorStatus,
  });

  final int categoryId;
  final String currentParentTitle;
  final String currentParentSlug;
  final bool Function(int? statusCode) isConnectivityErrorStatus;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return BlocBuilder<GetSubCategoriesCubit, GetSubCategoriesState>(
      builder: (context, state) {
        if (state is GetSubCategoriesLoading) {
          return SizedBox(
            height: 108.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, __) => const Skeletonizer(
                enabled: true,
                child: _SubCategoryChipSkeleton(),
              ),
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemCount: 5,
            ),
          );
        }

        if (state is GetSubCategoriesSuccess) {
          final categoriesWithImages = state.subCategories;

          if (categoriesWithImages.isEmpty) {
            return const SizedBox.shrink();
          }

          return SizedBox(
            height: 108.h,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final category = categoriesWithImages[index];
                return AppTapFeedback(
                  onTap: () => context.push(
                    AppRouter.productByCategory,
                    extra: {
                      'slug': category.slug,
                      'id': category.id,
                      'parentName': currentParentTitle,
                      'parentSlug': currentParentSlug,
                      'childName': category.name,
                    },
                  ),
                  borderRadius: BorderRadius.circular(46.r),
                  child: Container(
                    width: screenWidth > 800 ? 140.w : 92.w,
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(46.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipOval(
                            child: CustomCachedNetworkImage(
                              imageUrl: category.image?.thumbnail ?? '',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyle.styleRegular12(context).copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemCount: categoriesWithImages.length,
            ),
          );
        }

        if (state is GetSubCategoriesError) {
          if (isConnectivityErrorStatus(state.error.statusCode)) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              state.error.message,
              style: AppStyle.styleRegular14(
                context,
              ).copyWith(color: Colors.red),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.onTap,
    this.icon = Icons.keyboard_arrow_down_rounded,
    this.iconColor = const Color(0xFF2D2D2D),
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;

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
            Icon(icon, size: 18.sp, color: iconColor),
            SizedBox(width: 8.w),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

class _SubCategoryChipSkeleton extends StatelessWidget {
  const _SubCategoryChipSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(46.r),
      ),
    );
  }
}

class _SectionGridCard extends StatelessWidget {
  const _SectionGridCard({required this.item});

  final _SectionProductCardData item;

  @override
  Widget build(BuildContext context) {
    final localized = S.of(context);
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
        isInitiallyInWishList: item.isInitiallyInWishList,
        favoritesLabel: '${item.favoritesCount}  •  ${localized.favorites}',
        reviewsLabel: item.reviewCount > 0
            ? '${formatLocalizedNumber(context, item.averageRating, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, item.reviewCount)} ${localized.reviews}'
            : '',
        onTap: () {
          if (item.id == '0') {
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
  const _SectionListCard({required this.item});

  final _SectionProductCardData item;

  @override
  Widget build(BuildContext context) {
    final localized = S.of(context);
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
          isInitiallyInWishList: item.isInitiallyInWishList,
          favoritesLabel: '${item.favoritesCount}  •  ${localized.favorites}',
          reviewsLabel: item.reviewCount > 0
              ? '${formatLocalizedNumber(context, item.averageRating, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, item.reviewCount)} ${localized.reviews}'
              : '',
          onTap: () {
            if (item.id == '0') {
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

class _CategoryFilterBottomSheet extends StatelessWidget {
  const _CategoryFilterBottomSheet({
    required this.categories,
    required this.selectedSlugs,
    required this.onApply,
  });

  final List<HomeGraphqlCategory> categories;
  final Set<String> selectedSlugs;
  final Future<void> Function(Set<String> selectedSlugs) onApply;

  String _title(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? 'التصنيف' : 'Category';
  }

  String _clearAllLabel(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? 'مسح' : 'Clear';
  }

  String _applyLabel(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? 'تطبيق' : 'Apply';
  }

  @override
  Widget build(BuildContext context) {
    final categories = this.categories;
    final initialSelection = selectedSlugs;
    final tempSelection = <String>{...initialSelection};

    return SafeArea(
      top: false,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.56,
            minChildSize: 0.45,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, controller) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24.r),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 12.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _title(context),
                              style: AppStyle.styleSemiBold25(
                                context,
                              ).copyWith(color: const Color(0xFF222222)),
                            ),
                          ),
                          AppTapFeedback(
                            onTap: () =>
                                setModalState(() => tempSelection.clear()),
                            borderRadius: BorderRadius.circular(4.r),
                            child: Text(
                              _clearAllLabel(context),
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
                    SizedBox(height: 12.h),
                    Expanded(
                      child: ListView.separated(
                        controller: controller,
                        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final item = categories[index];
                          final isSelected = tempSelection.contains(item.slug);
                          return AppTapFeedback(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  tempSelection.remove(item.slug);
                                } else {
                                  tempSelection.add(item.slug);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(14.r),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 14.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFF6F5)
                                    : const Color(0xFFF9F9F9),
                                borderRadius: BorderRadius.circular(14.r),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFCB262E)
                                      : const Color(0xFFE4E4E4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: AppStyle.styleRegular15(context)
                                          .copyWith(
                                            color: const Color(0xFF222222),
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) {
                                      setModalState(() {
                                        if (isSelected) {
                                          tempSelection.remove(item.slug);
                                        } else {
                                          tempSelection.add(item.slug);
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xFFCB262E),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          height: 56.h,
                          child: ElevatedButton(
                            onPressed: () async {
                              await onApply({...tempSelection});
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD9252A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _applyLabel(context),
                              style: AppStyle.styleRegular18(
                                context,
                              ).copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

enum _SortByOption {
  mostRelevant,
  bestsellers,
  mostFavorited,
  newArrivals,
  mostRated,
  highToLowPrice,
  lowToHighPrice,
}

class _SortByBottomSheet extends StatelessWidget {
  const _SortByBottomSheet({
    required this.selectedOption,
    required this.onApply,
  });

  final _SortByOption? selectedOption;
  final Future<void> Function(_SortByOption?) onApply;

  String _title(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? 'ترتيب حسب' : 'Sort by';
  }

  String _label(BuildContext context, _SortByOption option) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return switch (option) {
      _SortByOption.mostRelevant => isArabic ? 'الأفضل تطابقًا' : 'Best match',
      _SortByOption.bestsellers => isArabic ? 'الأكثر مبيعًا' : 'Best sellers',
      _SortByOption.mostFavorited =>
        isArabic ? 'الأكثر تفضيلًا' : 'Most favorited',
      _SortByOption.newArrivals => isArabic ? 'وصل حديثًا' : 'New arrivals',
      _SortByOption.mostRated => isArabic ? 'الأعلى تقييمًا' : 'Most rated',
      _SortByOption.lowToHighPrice =>
        isArabic ? 'السعر: من الأقل إلى الأعلى' : 'Price: Low to high',
      _SortByOption.highToLowPrice =>
        isArabic ? 'السعر: من الأعلى إلى الأقل' : 'Price: High to low',
    };
  }

  @override
  Widget build(BuildContext context) {
    final options = _SortByOption.values;
    _SortByOption? tempSelection = selectedOption;

    return SafeArea(
      top: false,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                          _title(context),
                          style: AppStyle.styleSemiBold25(
                            context,
                          ).copyWith(color: const Color(0xFF222222)),
                        ),
                      ),
                      AppTapFeedback(
                        onTap: () => setModalState(() => tempSelection = null),
                        borderRadius: BorderRadius.circular(4.r),
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'مسح'
                              : 'Clear',
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
                      for (var index = 0; index < options.length; index++) ...[
                        AppTapFeedback(
                          onTap: () async {
                            final option = options[index];
                            if (tempSelection == option) {
                              Navigator.of(context).pop();
                              return;
                            }
                            await onApply(option);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          borderRadius: BorderRadius.circular(14.r),
                          child: Container(
                            width: double.infinity,
                            constraints: BoxConstraints(minHeight: 52.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: options[index] == tempSelection
                                  ? const Color(0xFFFFF6F5)
                                  : const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: options[index] == tempSelection
                                    ? const Color(0xFFCB262E)
                                    : const Color(0xFFE4E4E4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _label(context, options[index]),
                                    style: AppStyle.styleRegular15(context)
                                        .copyWith(
                                          color: const Color(0xFF222222),
                                          fontWeight:
                                              options[index] == tempSelection
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                  ),
                                ),
                                Container(
                                  width: 18.w,
                                  height: 18.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: options[index] == tempSelection
                                          ? const Color(0xFFCB262E)
                                          : const Color(0xFFBDBDBD),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: options[index] == tempSelection
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
                        ),
                        if (index != options.length - 1) SizedBox(height: 8.h),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
    required this.averageRating,
    required this.reviewCount,
    required this.currencyCode,
    required this.currencySymbol,
    required this.favoritesCount,
    this.isInitiallyInWishList = false,
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
  final String averageRating;
  final int reviewCount;
  final String currencyCode;
  final String currencySymbol;
  final int favoritesCount;
  final bool isInitiallyInWishList;
  final String? imageUrl;
  final String? imageAssetPath;
  final String campaignLabel;
  final DateTime? campaignEndsAt;
}
