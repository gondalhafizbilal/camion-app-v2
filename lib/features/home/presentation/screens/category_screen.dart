import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/section_top_header.dart';
import 'package:camion/core/api/api_locale_mapper.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/connectivity_error_utils.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/models/slider_items/slider_item_model.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/presentation/logic/cubit/category_feed_cubit/category_feed_cubit.dart';
import 'package:camion/features/searching/presentation/widgets/recent_search_sheet.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({
    super.key,
    this.showBackButton = true,
    this.initialCategorySlug,
  });

  final bool showBackButton;
  final String? initialCategorySlug;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CategoryFeedCubit(sl<HomeRepository>())..getCategoryFeed(
            locale: ApiLocaleMapper.toGraphqlLocale(
              context.read<LocalizationsCubit>().state.languageCode,
            ),
          ),
      child: _CategoryScreenView(
        showBackButton: showBackButton,
        initialCategorySlug: initialCategorySlug,
      ),
    );
  }
}

class CategoriesTabScreen extends StatelessWidget {
  const CategoriesTabScreen({super.key, this.initialCategorySlug});

  final String? initialCategorySlug;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CategoryFeedCubit(sl<HomeRepository>())..getCategoryFeed(
            locale: ApiLocaleMapper.toGraphqlLocale(
              context.read<LocalizationsCubit>().state.languageCode,
            ),
          ),
      child: _CategoriesTabView(initialCategorySlug: initialCategorySlug),
    );
  }
}

class _CategoryScreenView extends StatefulWidget {
  const _CategoryScreenView({
    required this.showBackButton,
    this.initialCategorySlug,
  });

  final bool showBackButton;
  final String? initialCategorySlug;

  @override
  State<_CategoryScreenView> createState() => _CategoryScreenViewState();
}

class _CategoryScreenViewState extends State<_CategoryScreenView> {
  int _selectedCategoryIndex = 0;
  bool _didChangeSelection = false;

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go('${AppRouter.selectingFromBottomNavBar}?tab=1');
  }

  Future<void> _refreshCategoryData() async {
    final locale = ApiLocaleMapper.toGraphqlLocale(
      context.read<LocalizationsCubit>().state.languageCode,
    );
    await context.read<CategoryFeedCubit>().getCategoryFeed(
      locale: locale,
      forceRefresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshCategoryData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 15.h, 20.w, 10.h),
                  child: _CategoryHeader(
                    showBackButton: widget.showBackButton,
                    onBackTap: _handleBackNavigation,
                  ),
                ),
              ),
              BlocBuilder<CategoryFeedCubit, CategoryFeedState>(
                builder: (context, state) {
                  if (state is CategoryFeedInitial ||
                      state is CategoryFeedLoading) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _CategorySplitSkeleton(),
                    );
                  }

                  if (state is CategoryFeedError) {
                    if (isBackendUnavailableStatus(state.error.statusCode)) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.error.message,
                                textAlign: TextAlign.center,
                                style: AppStyle.styleRegular15(
                                  context,
                                ).copyWith(color: Colors.red),
                              ),
                              SizedBox(height: 16.h),
                              SizedBox(
                                width: 140.w,
                                child: ElevatedButton(
                                  onPressed: () => context
                                      .read<CategoryFeedCubit>()
                                      .getCategoryFeed(
                                        locale: ApiLocaleMapper.toGraphqlLocale(
                                          context
                                              .read<LocalizationsCubit>()
                                              .state
                                              .languageCode,
                                        ),
                                      ),
                                  child: Text(
                                    'Retry',
                                    style: AppStyle.styleRegular15(
                                      context,
                                    ).copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is! CategoryFeedLoaded) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  final categories = state.feed.categories
                      .where(
                        (category) =>
                            category.name.trim().isNotEmpty &&
                            category.slug.trim().isNotEmpty,
                      )
                      .toList();

                  if (categories.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No Category Found',
                          style: AppStyle.styleRegular15(
                            context,
                          ).copyWith(color: Colors.black54),
                        ),
                      ),
                    );
                  }

                  final initialIndex = widget.initialCategorySlug == null
                      ? -1
                      : categories.indexWhere(
                          (category) =>
                              category.slug == widget.initialCategorySlug,
                        );
                  final fallbackIndex = initialIndex >= 0 ? initialIndex : 0;
                  final selectedIndex = _didChangeSelection
                      ? (_selectedCategoryIndex >= categories.length
                            ? fallbackIndex
                            : _selectedCategoryIndex)
                      : fallbackIndex;
                  return SliverFillRemaining(
                    hasScrollBody: true,
                    child: _CategorySplitLayout(
                      categories: categories,
                      selectedTopCategoryIndex: selectedIndex,
                      onCategoryTap: (index) {
                        if (selectedIndex == index) {
                          return;
                        }
                        setState(() {
                          _selectedCategoryIndex = index;
                          _didChangeSelection = true;
                        });
                      },
                      onSubCategoryTap: (subcategory) {
                        final parentName = categories[selectedIndex].name;
                        context.push(
                          AppRouter.productByCategory,
                          extra: {
                            'slug': subcategory.slug,
                            'id': subcategory.uuid,
                            'parentName': parentName,
                            'parentSlug': categories[selectedIndex].slug,
                            'childName': subcategory.name,
                          },
                        );
                      },
                      onViewAllTap: (topCategory) {
                        context.push(
                          AppRouter.productByCategory,
                          extra: {
                            'slug': topCategory.slug,
                            'id': topCategory.uuid,
                            'parentName': topCategory.name,
                            'parentSlug': topCategory.slug,
                            'childName': S.of(context).view_all,
                            'viewAllCategories': topCategory.children,
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoriesTabView extends StatefulWidget {
  const _CategoriesTabView({this.initialCategorySlug});

  final String? initialCategorySlug;

  @override
  State<_CategoriesTabView> createState() => _CategoriesTabViewState();
}

class _CategoriesTabViewState extends State<_CategoriesTabView> {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  String? _selectedCategorySlug;
  int _selectedCategoryIndex = 0;
  bool _didChangeSelectedCategory = false;

  @override
  void initState() {
    super.initState();
    final incomingSlug = widget.initialCategorySlug?.trim() ?? '';
    if (incomingSlug.isNotEmpty) {
      _selectedCategorySlug = incomingSlug;
    }
  }

  Future<void> _refreshCategoryData() async {
    final locale = ApiLocaleMapper.toGraphqlLocale(
      context.read<LocalizationsCubit>().state.languageCode,
    );
    await context.read<CategoryFeedCubit>().getCategoryFeed(
      locale: locale,
      forceRefresh: true,
    );
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshCategoryData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _selectedCategorySlug == null
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(10.w, 15.h, 10.w, 16.h),
                        child: _CategoryOverviewHeader(
                          onSearchTap: () => openRecentSearchSheet(context),
                        ),
                      )
                    : _CategoryInlineHeader(
                        onBackTap: () {
                          setState(() {
                            _selectedCategorySlug = null;
                            _selectedCategoryIndex = 0;
                            _didChangeSelectedCategory = false;
                          });
                        },
                        onSearchTap: () => openRecentSearchSheet(context),
                      ),
              ),
              BlocBuilder<CategoryFeedCubit, CategoryFeedState>(
                builder: (context, state) {
                  if (state is CategoryFeedInitial ||
                      state is CategoryFeedLoading) {
                    return SliverList(
                      delegate: SliverChildListDelegate([
                        _CategoryOverviewBannerSkeleton(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(10.w, 16.h, 10.w, 120.h),
                          child: _CategoryOverviewGridSkeleton(),
                        ),
                      ]),
                    );
                  }

                  if (state is CategoryFeedError) {
                    if (isBackendUnavailableStatus(state.error.statusCode)) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                state.error.message,
                                textAlign: TextAlign.center,
                                style: AppStyle.styleRegular15(
                                  context,
                                ).copyWith(color: Colors.red),
                              ),
                              SizedBox(height: 16.h),
                              SizedBox(
                                width: 140.w,
                                child: ElevatedButton(
                                  onPressed: _refreshCategoryData,
                                  child: Text(
                                    'Retry',
                                    style: AppStyle.styleRegular15(
                                      context,
                                    ).copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is! CategoryFeedLoaded) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  final banners = state.feed.banners;
                  final categories = state.feed.categories
                      .where(
                        (category) =>
                            category.name.trim().isNotEmpty &&
                            category.slug.trim().isNotEmpty,
                      )
                      .toList();

                  if (_selectedCategorySlug != null) {
                    final initialIndex = categories.indexWhere(
                      (category) => category.slug == _selectedCategorySlug,
                    );
                    final fallbackIndex = initialIndex >= 0 ? initialIndex : 0;
                    final selectedIndex = _didChangeSelectedCategory
                        ? (_selectedCategoryIndex >= categories.length
                              ? fallbackIndex
                              : _selectedCategoryIndex)
                        : fallbackIndex;
                    return SliverFillRemaining(
                      hasScrollBody: true,
                      child: _CategorySplitLayout(
                        categories: categories,
                        selectedTopCategoryIndex: selectedIndex,
                        onCategoryTap: (index) {
                          if (selectedIndex == index) {
                            return;
                          }
                          setState(() {
                            _selectedCategoryIndex = index;
                            _didChangeSelectedCategory = true;
                            _selectedCategorySlug = categories[index].slug;
                          });
                        },
                        onSubCategoryTap: (subcategory) {
                          final parentName = categories[selectedIndex].name;
                          context.push(
                            AppRouter.productByCategory,
                            extra: {
                              'slug': subcategory.slug,
                              'id': subcategory.uuid,
                              'parentName': parentName,
                              'parentSlug': categories[selectedIndex].slug,
                              'childName': subcategory.name,
                            },
                          );
                        },
                        onViewAllTap: (topCategory) {
                          context.push(
                            AppRouter.productByCategory,
                            extra: {
                              'slug': topCategory.slug,
                              'id': topCategory.uuid,
                              'parentName': topCategory.name,
                              'parentSlug': topCategory.slug,
                              'childName': S.of(context).view_all,
                              'viewAllCategories': topCategory.children,
                            },
                          );
                        },
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      if (banners.isNotEmpty) ...[
                        _CategoryOverviewBanner(
                          controller: _bannerController,
                          banners: banners,
                          currentIndex: _bannerIndex,
                          onPageChanged: (index) {
                            if (!mounted) return;
                            setState(() => _bannerIndex = index);
                          },
                        ),
                        SizedBox(height: 16.h),
                      ],
                      Padding(
                        padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 120.h),
                        child: categories.isEmpty
                            ? SizedBox(
                                height: 240.h,
                                child: Center(
                                  child: Text(
                                    'No Category Found',
                                    style: AppStyle.styleRegular15(
                                      context,
                                    ).copyWith(color: Colors.black54),
                                  ),
                                ),
                              )
                            : GridView.builder(
                                itemCount: categories.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisExtent: 80.h,
                                      crossAxisSpacing: 14.w,
                                      mainAxisSpacing: 18.h,
                                    ),
                                itemBuilder: (_, index) {
                                  final category = categories[index];
                                  return _CategoryOverviewCard(
                                    title: category.name,
                                    imageUrl: category.thumbnailUrl,
                                    onTap: () {
                                      setState(() {
                                        _selectedCategorySlug = category.slug;
                                        _selectedCategoryIndex = index;
                                        _didChangeSelectedCategory = false;
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.showBackButton,
    this.onBackTap,
    this.onSearchTap,
  });

  final bool showBackButton;
  final VoidCallback? onBackTap;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    if (!showBackButton) {
      return SectionTopHeader(title: S.of(context).all_categories);
    }

    return Row(
      children: [
        AppTapFeedback(
          onTap: onBackTap ?? () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(8.r),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            S.of(context).all_categories,
            style: TextStyle(
              fontFamily: 'Montes',
              fontWeight: FontWeight.w500,
              fontSize: 20.sp,
              height: 2,
              letterSpacing: 0,
              color: Colors.black,
            ),
          ),
        ),
        AppTapFeedback(
          onTap: onSearchTap ?? () => openRecentSearchSheet(context),
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(8.r),
            child: Image.asset(
              'assets/images/searchicon.png',
              width: 40.w,
              height: 40.h,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryOverviewHeader extends StatelessWidget {
  const _CategoryOverviewHeader({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            S.of(context).all_categories,
            style: TextStyle(
              fontFamily: 'Montes',
              fontWeight: FontWeight.w500,
              fontSize: 20.sp,
              height: 2,
              letterSpacing: 0,
              color: Colors.black,
            ),
          ),
        ),
        AppTapFeedback(
          onTap: onSearchTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(8.r),
            child: Image.asset(
              'assets/images/searchicon.png',
              width: 40.w,
              height: 40.h,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryInlineHeader extends StatelessWidget {
  const _CategoryInlineHeader({
    required this.onBackTap,
    required this.onSearchTap,
  });

  final VoidCallback onBackTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(10.w, 15.h, 10.w, 10.h),
          child: _CategoryHeader(
            showBackButton: true,
            onBackTap: onBackTap,
            onSearchTap: onSearchTap,
          ),
        ),
        Container(
          width: double.infinity,
          height: 1,
          color: const Color(0xFFD9D9D9),
        ),
      ],
    );
  }
}

class _CategoryOverviewBanner extends StatelessWidget {
  const _CategoryOverviewBanner({
    required this.controller,
    required this.banners,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<SliderItemModel> banners;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 118.h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: controller,
            itemCount: banners.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, index) {
              final banner = banners[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  banner.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: banner.imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: const Color(0xFFCB262E)),
                        )
                      : Image.asset(
                          Assets.imagesBlackFriday,
                          fit: BoxFit.cover,
                        ),
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
              children: List.generate(banners.length, (dotIndex) {
                final distance = (currentIndex.toDouble() - dotIndex).abs();
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

class _CategoryOverviewCard extends StatelessWidget {
  const _CategoryOverviewCard({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final imageWidget = imageUrl.trim().isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorWidget: (_, __, ___) => Image.asset(
              Assets.imagesCategoryPlaceholder,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          )
        : Image.asset(
            Assets.imagesCategoryPlaceholder,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          );

    return AppTapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5.r),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFCED4D4),
          borderRadius: BorderRadius.circular(5.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              offset: Offset(4, 4),
              blurRadius: 40,
              spreadRadius: -15,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(10.w, 8.h, 8.w, 8.h),
          child: Row(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Expanded(
                child: Align(
                  alignment: isRtl
                      ? AlignmentDirectional.topStart
                      : AlignmentDirectional.topStart,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    textDirection: isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: 'Montes',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              SizedBox(width: 72.w, height: 64.h, child: imageWidget),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryOverviewBannerSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 118.h, color: const Color(0xFFE9E9E9));
  }
}

class _CategoryOverviewGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 80.h,
        crossAxisSpacing: 14.w,
        mainAxisSpacing: 18.h,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE9E9E9),
          borderRadius: BorderRadius.circular(5.r),
        ),
      ),
    );
  }
}

class _CategorySplitLayout extends StatelessWidget {
  const _CategorySplitLayout({
    required this.categories,
    required this.selectedTopCategoryIndex,
    required this.onCategoryTap,
    required this.onSubCategoryTap,
    required this.onViewAllTap,
  });

  final List<HomeGraphqlCategory> categories;
  final int selectedTopCategoryIndex;
  final ValueChanged<int> onCategoryTap;
  final ValueChanged<HomeGraphqlCategory> onSubCategoryTap;
  final ValueChanged<HomeGraphqlCategory> onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return _CategoryThreeLevelLayout(
      categories: categories,
      selectedTopCategoryIndex: selectedTopCategoryIndex,
      onTopCategoryTap: onCategoryTap,
      onLeafCategoryTap: onSubCategoryTap,
      onViewAllTap: onViewAllTap,
    );
  }
}

class _CategoryThreeLevelLayout extends StatefulWidget {
  const _CategoryThreeLevelLayout({
    required this.categories,
    required this.selectedTopCategoryIndex,
    required this.onTopCategoryTap,
    required this.onLeafCategoryTap,
    required this.onViewAllTap,
  });

  final List<HomeGraphqlCategory> categories;
  final int selectedTopCategoryIndex;
  final ValueChanged<int> onTopCategoryTap;
  final ValueChanged<HomeGraphqlCategory> onLeafCategoryTap;
  final ValueChanged<HomeGraphqlCategory> onViewAllTap;

  @override
  State<_CategoryThreeLevelLayout> createState() =>
      _CategoryThreeLevelLayoutState();
}

class _CategoryThreeLevelLayoutState extends State<_CategoryThreeLevelLayout> {
  int _selectedSecondLevelIndex = 0;

  @override
  void didUpdateWidget(covariant _CategoryThreeLevelLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTopCategoryIndex != widget.selectedTopCategoryIndex) {
      _selectedSecondLevelIndex = 0;
      return;
    }

    final secondLevelItems = _secondLevelCategories();
    if (_selectedSecondLevelIndex >= secondLevelItems.length) {
      _selectedSecondLevelIndex = secondLevelItems.isEmpty
          ? 0
          : secondLevelItems.length - 1;
    }
  }

  List<HomeGraphqlCategory> _secondLevelCategories() {
    final selectedTop = widget.categories[widget.selectedTopCategoryIndex];
    return selectedTop.children
        .where(
          (category) =>
              category.name.trim().isNotEmpty &&
              category.slug.trim().isNotEmpty,
        )
        .toList();
  }

  List<HomeGraphqlCategory> _thirdLevelCategories(
    List<HomeGraphqlCategory> secondLevelItems,
  ) {
    if (secondLevelItems.isEmpty) return const [];
    final selectedSecond = secondLevelItems[_selectedSecondLevelIndex];
    return selectedSecond.children
        .where(
          (category) =>
              category.name.trim().isNotEmpty &&
              category.slug.trim().isNotEmpty,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final secondLevelItems = _secondLevelCategories();
    final hasSecondLevelItems = secondLevelItems.isNotEmpty;
    final thirdLevelItems = _thirdLevelCategories(secondLevelItems);

    return Column(
      children: [
        Container(
          height: 56.h,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          color: Colors.white,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.categories.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, index) {
              final item = widget.categories[index];
              return _TopCategoryChip(
                label: item.name,
                isSelected: index == widget.selectedTopCategoryIndex,
                onTap: () => widget.onTopCategoryTap(index),
              );
            },
          ),
        ),
        Container(
          height: 1,
          width: double.infinity,
          color: const Color(0xFFE8E8E8),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 128.w,
                color: const Color(0xFFF7F7F7),
                child: hasSecondLevelItems
                    ? ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: secondLevelItems.length,
                        itemBuilder: (context, index) {
                          final secondItem = secondLevelItems[index];
                          return _LeftCategoryTile(
                            title: secondItem.name,
                            isSelected: index == _selectedSecondLevelIndex,
                            onTap: () {
                              setState(() {
                                _selectedSecondLevelIndex = index;
                              });
                              if (secondItem.children.isEmpty) {
                                widget.onLeafCategoryTap(secondItem);
                              }
                            },
                          );
                        },
                      )
                    : Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: Text(
                            'No subcategories',
                            textAlign: TextAlign.center,
                            style: AppStyle.styleRegular12(
                              context,
                            ).copyWith(color: Colors.black54),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: !hasSecondLevelItems
                      ? Center(
                          child: Text(
                            'No category found',
                            style: AppStyle.styleRegular14(
                              context,
                            ).copyWith(color: Colors.black54),
                          ),
                        )
                      : thirdLevelItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'No third-level categories',
                                  style: AppStyle.styleRegular14(
                                    context,
                                  ).copyWith(color: Colors.black54),
                                ),
                                SizedBox(height: 10.h),
                                OutlinedButton(
                                  onPressed: () => widget.onLeafCategoryTap(
                                    secondLevelItems[_selectedSecondLevelIndex],
                                  ),
                                  child: Text(
                                    'View ${secondLevelItems[_selectedSecondLevelIndex].name}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final computedCount = (constraints.maxWidth / 96.w)
                                .floor()
                                .clamp(2, 4);
                            final selectedSecondCategory =
                                secondLevelItems[_selectedSecondLevelIndex];
                            return GridView.builder(
                              padding: EdgeInsets.fromLTRB(
                                10.r,
                                10.r,
                                10.r,
                                10.r +
                                    MediaQuery.of(context).padding.bottom +
                                    kBottomNavigationBarHeight +
                                    36.h,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemCount: thirdLevelItems.length + 1,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: computedCount,
                                    mainAxisExtent: 98.h,
                                    crossAxisSpacing: 10.w,
                                    mainAxisSpacing: 18.h,
                                  ),
                              itemBuilder: (_, index) {
                                if (index == 0) {
                                  return _ViewAllSubCategoryCard(
                                    onTap: () => widget.onViewAllTap(
                                      selectedSecondCategory,
                                    ),
                                  );
                                }
                                final item = thirdLevelItems[index - 1];
                                return _HomeStyleSubCategoryCard(
                                  title: item.name,
                                  imageUrl: item.thumbnailUrl,
                                  onTap: () => widget.onLeafCategoryTap(item),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopCategoryChip extends StatelessWidget {
  const _TopCategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppTapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999.r),
          color: isSelected ? const Color(0xFFCB262E) : const Color(0xFFF1F1F1),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFCB262E)
                : const Color(0xFFE2E2E2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Montes',
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF3E3E3E),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeftCategoryTile extends StatelessWidget {
  const _LeftCategoryTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100.w,
      height: 40.h,
      child: Material(
        color: isSelected ? Colors.white : const Color(0xFFF5F5F5),
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 4.w,
                height: 40.h,
                color: isSelected
                    ? const Color(0xFFCB262E)
                    : Colors.transparent,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Montes',
                      fontSize: 10.sp,
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                      height: 1.8,
                      letterSpacing: 0,
                      color: isSelected
                          ? const Color(0xFFCB262E)
                          : const Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeStyleSubCategoryCard extends StatelessWidget {
  const _HomeStyleSubCategoryCard({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const cardBackgroundColor = Color(0xFFCED4D4);

    return SizedBox(
      width: 75.w,
      height: 93.h,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 75.w,
              height: 75.h,
              decoration: BoxDecoration(
                color: cardBackgroundColor,
                borderRadius: BorderRadius.circular(5.r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    offset: Offset(4, 4),
                    blurRadius: 40,
                    spreadRadius: -15,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5.r),
                child: imageUrl.trim().isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Image.asset(
                          Assets.imagesCategoryPlaceholder,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        Assets.imagesCategoryPlaceholder,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            SizedBox(height: 4.h),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montes',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      letterSpacing: 0,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewAllSubCategoryCard extends StatelessWidget {
  const _ViewAllSubCategoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = S.of(context).view_all;

    return SizedBox(
      width: 75.w,
      height: 93.h,
      child: AppTapFeedback(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5.r),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              width: 75.w,
              height: 75.h,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(5.r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    offset: Offset(4, 4),
                    blurRadius: 40,
                    spreadRadius: -15,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _CategorySplitSkeleton extends StatelessWidget {
  const _CategorySplitSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 100,
          color: const Color(0xFFF5F5F5),
          child: ListView.separated(
            itemCount: 12,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (_, index) => Container(
              height: 40,
              color: index == 0 ? Colors.white : const Color(0xFFF5F5F5),
            ),
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFFF7F7F7),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 98),
            child: GridView.builder(
              itemCount: 15,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 93,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (_, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 58,
                    height: 8,
                    color: const Color(0xFFD8D8D8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
