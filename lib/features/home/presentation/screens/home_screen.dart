import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/config/widgets/notification_bell_with_badge.dart';
import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/core/api/api_locale_mapper.dart';
import 'package:camion/core/services/dashboard_badge_counts_notifier.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_logger.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/connectivity_error_utils.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/product_description_formatter.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/models/all_products_model/all_products_model.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/presentation/logic/cubit/home_categories_cubit/home_categories_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/home_product_sections_cubit/home_product_sections_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/products_cubit/products_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/sliders_cubit/sliders_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/stories_cubit/stories_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/toggle__list_or_grid_cubit/toggle_list_and_grid_cubit.dart';
import 'package:camion/features/home/presentation/widgets/list_view_item_skeletonizer.dart';
import 'package:camion/features/home/presentation/widgets/product_collection_card.dart';
import 'package:camion/features/searching/presentation/widgets/recent_search_sheet.dart';
import 'package:camion/features/wish_list/data/repository/wish_list_repo.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/add_to_wish_list/wish_list_cubit.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/get_wish_listcubit/get_wish_list_cubit.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final GlobalKey<HomeScreenBodyState> homeKey =
      GlobalKey<HomeScreenBodyState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HomeProductSectionsCubit(sl<HomeRepository>()),
        ),
        BlocProvider(create: (context) => StoriesCubit(sl<HomeRepository>())),
        BlocProvider(
          create: (context) => AddToWishListCubit(sl<WishListRepository>()),
        ),
        BlocProvider(
          create: (context) => GetWishListCubit(sl<WishListRepository>()),
        ),
        BlocProvider(
          create: (context) => HomeCategoriesCubit(sl<HomeRepository>()),
        ),
        BlocProvider(
          create: (context) => ProductsCubit(sl<HomeRepository>(), perPage: 20),
        ),
        BlocProvider(create: (context) => ToggleListAndGridCubit()),
        BlocProvider(create: (context) => SlidersCubit(sl<HomeRepository>())),
      ],
      child: HomeScreenBody(key: homeKey),
    );
  }
}

class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({super.key});

  @override
  State<HomeScreenBody> createState() => HomeScreenBodyState();
}

class HomeScreenBodyState extends State<HomeScreenBody>
    with AutomaticKeepAliveClientMixin {
  static const bool _debugHomeLogs = false;
  @override
  bool get wantKeepAlive => true;

  final ScrollController _scrollController = ScrollController();
  final PageController _bannerController = PageController(viewportFraction: 1);
  final GlobalKey _allSectionKey = GlobalKey();
  final GlobalKey _popularSectionKey = GlobalKey();
  final GlobalKey _featuredSectionKey = GlobalKey();
  final GlobalKey _featuredCampaignSectionKey = GlobalKey();
  final GlobalKey _recentlyViewedSectionKey = GlobalKey();
  int _bannerIndex = 0;
  double _bannerPage = 0;
  String? _lastGraphqlLocale;
  Timer? _bannerAutoScrollTimer;
  StreamSubscription<Locale>? _localeSubscription;
  int _autoScrollBannerCount = 0;
  bool _sectionHighlightSyncScheduled = false;
  _HomeSectionTab _selectedSectionTab = _HomeSectionTab.all;
  final Map<_HomeProductSection, bool> _sectionGridView = {
    _HomeProductSection.all: true,
    _HomeProductSection.featured: true,
    _HomeProductSection.featuredCampaign: true,
    _HomeProductSection.popular: true,
    _HomeProductSection.recentlyViewed: true,
  };

  @override
  void initState() {
    super.initState();
    _bannerController.addListener(_handleBannerScroll);
    _scrollController.addListener(_handleHomeScroll);
    final locale = _currentGraphqlLocale();
    _lastGraphqlLocale = locale;
    _localeSubscription = context.read<LocalizationsCubit>().stream.listen((
      localeState,
    ) {
      if (!mounted) return;
      final nextLocale = ApiLocaleMapper.toGraphqlLocale(
        localeState.languageCode,
      );
      if (_lastGraphqlLocale == nextLocale) return;
      _lastGraphqlLocale = nextLocale;
      _clearHomeCachesAndRefresh(nextLocale);
    });
    context.read<HomeProductSectionsCubit>().getSections(locale: locale);
    context.read<ProductsCubit>().loadInitial(lang: locale);
    context.read<HomeCategoriesCubit>().getCategories(locale: locale);
    context.read<SlidersCubit>().getSliders(locale: locale);
    context.read<StoriesCubit>().getStories(locale: locale);
    unawaited(sl<AppsFlyerService>().logConversionEvent('view_home'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      sl<DashboardBadgeCountsNotifier>().refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = _currentGraphqlLocale();
    if (_lastGraphqlLocale == null) {
      _lastGraphqlLocale = locale;
      return;
    }
    if (_lastGraphqlLocale == locale) {
      return;
    }
    _lastGraphqlLocale = locale;
    _clearHomeCachesAndRefresh(locale);
  }

  void _clearHomeCachesAndRefresh(String locale) {
    _homeDebug(
      'clearHomeCachesAndRefresh locale=$locale '
      'productsBeforeClear=${context.read<ProductsCubit>().allProducts.length}',
    );
    context.read<HomeProductSectionsCubit>().clearCache();
    context.read<HomeCategoriesCubit>().clearCache();
    context.read<SlidersCubit>().clearCache();
    context.read<StoriesCubit>().clearCache();
    context.read<ProductsCubit>().clearCache();

    unawaited(
      Future.wait([
        context.read<ProductsCubit>().loadInitial(
          lang: locale,
          forceRefresh: true,
        ),
        context.read<HomeProductSectionsCubit>().getSections(
          locale: locale,
          forceRefresh: true,
        ),
        context.read<HomeCategoriesCubit>().getCategories(
          locale: locale,
          forceRefresh: true,
        ),
        context.read<SlidersCubit>().getSliders(
          locale: locale,
          forceRefresh: true,
        ),
        context.read<StoriesCubit>().getStories(
          locale: locale,
          forceRefresh: true,
        ),
      ]),
    );
  }

  void _handleHomeScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final cubit = context.read<ProductsCubit>();
    if (cubit.isLoading || cubit.isLoadingMore || !cubit.hasMore) {
      return;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= (maxScroll - 420)) {
      cubit.loadMore(lang: _currentGraphqlLocale());
    }
    _syncSelectedSectionWithViewport();
  }

  void _handleBannerScroll() {
    if (!_bannerController.hasClients) {
      return;
    }
    final page = _bannerController.page ?? _bannerIndex.toDouble();
    if ((page - _bannerPage).abs() < 0.001) {
      return;
    }
    setState(() {
      _bannerPage = page;
    });
  }

  void _configureBannerAutoScroll(int itemCount) {
    if (_autoScrollBannerCount == itemCount &&
        (_bannerAutoScrollTimer?.isActive ?? false)) {
      return;
    }
    _autoScrollBannerCount = itemCount;
    _bannerAutoScrollTimer?.cancel();
    if (itemCount <= 1) {
      return;
    }
    _bannerAutoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_bannerController.hasClients) {
        return;
      }
      if (_bannerIndex >= itemCount - 1) {
        _bannerController.jumpToPage(0);
        setState(() {
          _bannerIndex = 0;
          _bannerPage = 0;
        });
        return;
      }
      final nextPage = _bannerIndex + 1;
      _bannerController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void refreshWishListAndCartList() {
    final locale = _currentGraphqlLocale();
    _clearHomeCachesAndRefresh(locale);
    sl<DashboardBadgeCountsNotifier>().refresh();
  }

  void refreshProducts() {
    final locale = _currentGraphqlLocale();
    _clearHomeCachesAndRefresh(locale);
    sl<DashboardBadgeCountsNotifier>().refresh();
  }

  Future<void> _refreshHomeSections() async {
    final locale = _currentGraphqlLocale();
    final sectionsCubit = context.read<HomeProductSectionsCubit>();
    final productsCubit = context.read<ProductsCubit>();
    final categoriesCubit = context.read<HomeCategoriesCubit>();
    final slidersCubit = context.read<SlidersCubit>();
    final storiesCubit = context.read<StoriesCubit>();
    _homeDebug(
      'pullToRefresh locale=$locale '
      'productsBeforeRefresh=${productsCubit.allProducts.length}',
    );
    await Future.wait([
      sectionsCubit.getSections(locale: locale, forceRefresh: true),
      productsCubit.loadInitial(lang: locale, forceRefresh: true),
      categoriesCubit.getCategories(locale: locale, forceRefresh: true),
      slidersCubit.getSliders(locale: locale, forceRefresh: true),
      storiesCubit.getStories(locale: locale, forceRefresh: true),
    ]);
    _homeDebug(
      'pullToRefresh complete locale=$locale '
      'productsAfterRefresh=${productsCubit.allProducts.length}',
    );
    sl<DashboardBadgeCountsNotifier>().refresh();
  }

  void _homeDebug(String message) {
    if (!_debugHomeLogs) return;
    appLog(message, name: 'HOME_SCREEN_DEBUG');
  }

  bool _isHomeBackendIssueState(Object? state) {
    if (state is HomeProductSectionsError) {
      return isBackendUnavailableStatus(state.error.statusCode);
    }
    if (state is HomeCategoriesError) {
      return isBackendUnavailableStatus(state.error.statusCode);
    }
    if (state is GetAllSlidersError) {
      return isBackendUnavailableStatus(state.error.statusCode);
    }
    return false;
  }

  List<_CategoryViewItem> _effectiveCategories(HomeCategoriesState state) {
    if (state is HomeCategoriesInitial || state is HomeCategoriesLoading) {
      return const <_CategoryViewItem>[];
    }

    if (state is HomeCategoriesLoaded) {
      return state.categories
          .map(
            (category) => _CategoryViewItem(
              id: category.uuid,
              slug: category.slug,
              title: category.name,
              imageUrl: category.thumbnailUrl,
              imageAssetPath: Assets.imagesCategoryPlaceholder,
              children: category.children
                  .where(
                    (child) =>
                        child.slug.trim().isNotEmpty &&
                        child.name.trim().isNotEmpty,
                  )
                  .map(
                    (child) => _CategoryChildViewItem(
                      slug: child.slug,
                      title: child.name,
                    ),
                  )
                  .toList(),
              canOpen: true,
            ),
          )
          .toList();
    }
    return const <_CategoryViewItem>[];
  }

  List<_StoryViewItem> _effectiveStories(StoriesState state) {
    if (state is StoriesLoaded && state.storiesList.isNotEmpty) {
      final items = <_StoryViewItem>[];
      for (final entry in state.storiesList.asMap().entries) {
        final story = entry.value;
        final validFrames = story.frames.where((frame) {
          final mediaUrl = frame.mediaUrl.trim();
          final thumbnailUrl = frame.thumbnailUrl.trim();
          if (frame.mediaType.trim().toLowerCase() == 'video') {
            return mediaUrl.isNotEmpty;
          }
          return mediaUrl.isNotEmpty || thumbnailUrl.isNotEmpty;
        }).toList();
        if (validFrames.isEmpty) {
          continue;
        }

        final firstFrame = validFrames.first;
        final mediaType = firstFrame.mediaType.trim().toLowerCase();
        final mediaUrl = firstFrame.mediaUrl.trim();
        final thumbnailUrl = firstFrame.thumbnailUrl.trim();
        final previewUrl = mediaType == 'video'
            ? (thumbnailUrl.isNotEmpty ? thumbnailUrl : mediaUrl)
            : (mediaUrl.isNotEmpty ? mediaUrl : thumbnailUrl);
        if (previewUrl.isEmpty) {
          continue;
        }

        items.add(
          _StoryViewItem(
            imageUrl: previewUrl,
            mediaType: firstFrame.mediaType,
            remoteIndex: entry.key,
            remoteStories: state.storiesList,
          ),
        );
      }
      return items;
    }
    return const <_StoryViewItem>[];
  }

  List<_BannerViewItem> _effectiveBanners(SlidersState state) {
    if (state is SlidersInitial || state is GetAllSlidersLoading) {
      return const <_BannerViewItem>[];
    }

    if (state is GetAllSlidersLoaded && state.slidersList.isNotEmpty) {
      return state.slidersList
          .map(
            (slider) => _BannerViewItem(
              imageUrl: slider.imageUrl,
              title: slider.title,
              subtitle: slider.discount,
              caption: slider.description,
              backgroundColorHex: slider.bannerColor,
            ),
          )
          .toList();
    }
    return const <_BannerViewItem>[];
  }

  String _currentGraphqlLocale() {
    final languageCode = context.read<LocalizationsCubit>().state.languageCode;
    return ApiLocaleMapper.toGraphqlLocale(languageCode);
  }

  String _recentlyViewedLabel(BuildContext context) {
    final languageCode = context.read<LocalizationsCubit>().state.languageCode;
    if (languageCode == 'ar') {
      return 'شوهدت مؤخراً';
    }
    return 'Recently Viewed';
  }

  String _featuredCampaignLabel(BuildContext context) {
    final state = context.read<HomeProductSectionsCubit>().state;
    if (state is HomeProductSectionsLoaded) {
      final title = state.sections.featuredCampaignTitle.trim();
      if (title.isNotEmpty) {
        return title;
      }
    }
    return Localizations.localeOf(context).languageCode == 'ar'
        ? 'مميز'
        : 'Featured';
  }

  void _scheduleSelectedSectionSync() {
    if (_sectionHighlightSyncScheduled || !mounted) {
      return;
    }
    _sectionHighlightSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sectionHighlightSyncScheduled = false;
      if (!mounted) {
        return;
      }
      _syncSelectedSectionWithViewport();
    });
  }

  void _syncSelectedSectionWithViewport() {
    if (!_scrollController.hasClients) {
      return;
    }

    final candidates = <_HomeSectionTab>[
      _HomeSectionTab.featuredCampaign,
      _HomeSectionTab.featured,
      _HomeSectionTab.popular,
      _HomeSectionTab.recentlyViewed,
      _HomeSectionTab.all,
    ];
    final viewportTop = _scrollController.position.pixels;
    final anchor = viewportTop + 160;

    _HomeSectionTab? bestLower;
    double bestLowerOffset = double.negativeInfinity;
    _HomeSectionTab? bestUpper;
    double bestUpperOffset = double.infinity;

    for (final tab in candidates) {
      final key = switch (tab) {
        _HomeSectionTab.featuredCampaign => _featuredCampaignSectionKey,
        _HomeSectionTab.featured => _featuredSectionKey,
        _HomeSectionTab.popular => _popularSectionKey,
        _HomeSectionTab.recentlyViewed => _recentlyViewedSectionKey,
        _HomeSectionTab.all => _allSectionKey,
      };
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject == null) {
        continue;
      }
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        continue;
      }
      final viewport = RenderAbstractViewport.of(renderObject);
      final offset = viewport.getOffsetToReveal(renderObject, 0).offset;
      if (offset <= anchor && offset > bestLowerOffset) {
        bestLower = tab;
        bestLowerOffset = offset;
      } else if (offset > anchor && offset < bestUpperOffset) {
        bestUpper = tab;
        bestUpperOffset = offset;
      }
    }

    final nextTab = bestLower ?? bestUpper;
    if (nextTab != null && nextTab != _selectedSectionTab && mounted) {
      setState(() => _selectedSectionTab = nextTab);
    }
  }

  List<HomeGraphqlProduct> _productsForSection(
    HomeProductSectionsState state,
    _HomeProductSection section,
  ) {
    if (state is! HomeProductSectionsLoaded) {
      return const <HomeGraphqlProduct>[];
    }
    switch (section) {
      case _HomeProductSection.popular:
        return state.sections.popularProducts;
      case _HomeProductSection.featured:
        return state.sections.featuredProducts;
      case _HomeProductSection.featuredCampaign:
        return state.sections.featuredCampaignProducts;
      case _HomeProductSection.all:
        return state.sections.allProducts;
      case _HomeProductSection.recentlyViewed:
        return state.sections.recentlyViewed;
    }
  }

  List<HomeGraphqlProduct> _effectiveProductsForSection(
    HomeProductSectionsState state,
    _HomeProductSection section,
  ) {
    if (state is HomeProductSectionsInitial ||
        state is HomeProductSectionsLoading) {
      return const <HomeGraphqlProduct>[];
    }

    return _productsForSection(state, section);
  }

  void scrollToTopAndRefresh() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    final locale = _currentGraphqlLocale();
    context.read<HomeProductSectionsCubit>().getSections(locale: locale);
    context.read<HomeCategoriesCubit>().getCategories(locale: locale);
    context.read<SlidersCubit>().getSliders(locale: locale);
    context.read<StoriesCubit>().getStories(locale: locale);
    sl<DashboardBadgeCountsNotifier>().refresh();
  }

  Future<void> _scrollToSection(_HomeSectionTab tab) async {
    setState(() => _selectedSectionTab = tab);
    final targetKey = switch (tab) {
      _HomeSectionTab.all => _allSectionKey,
      _HomeSectionTab.featured => _featuredSectionKey,
      _HomeSectionTab.featuredCampaign => _featuredCampaignSectionKey,
      _HomeSectionTab.popular => _popularSectionKey,
      _HomeSectionTab.recentlyViewed => _recentlyViewedSectionKey,
    };
    final targetContext = targetKey.currentContext;
    if (targetContext == null) {
      return;
    }
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.04,
    );
  }

  void _toggleSectionView(_HomeProductSection section, bool showGrid) {
    setState(() {
      _sectionGridView[section] = showGrid;
    });
  }

  void _openSectionDetails(
    BuildContext context, {
    required String title,
    required _HomeProductSection section,
    String? slug,
    DateTime? campaignEndsAt,
  }) {
    final extra = <String, dynamic>{
      'title': title,
      'section': section.name,
      if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
      if (campaignEndsAt != null) 'campaignEndsAt': campaignEndsAt,
    };
    context.push(AppRouter.homeSectionDetails, extra: extra);
  }

  @override
  void dispose() {
    _bannerAutoScrollTimer?.cancel();
    _localeSubscription?.cancel();
    _bannerController.removeListener(_handleBannerScroll);
    _scrollController.removeListener(_handleHomeScroll);
    _scrollController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Color _parseBannerHexColor(String? hex) {
    const fallback = Color(0xFFCB262E);
    final raw = (hex ?? '').trim();
    if (raw.isEmpty) return fallback;
    var normalized = raw.startsWith('#') ? raw.substring(1) : raw;
    if (normalized.length == 6) {
      normalized = 'FF$normalized';
    }
    if (normalized.length != 8) {
      return fallback;
    }
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return fallback;
    return Color(value);
  }

  Gradient _headerGradientForBannerScroll(List<_BannerViewItem> banners) {
    if (banners.isEmpty) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFCB262E), Color(0xFFCB262E)],
        stops: [0.0, 1.0],
      );
    }

    final maxIndex = banners.length > 1 ? banners.length - 1 : 0;
    final page = _bannerPage.clamp(0.0, maxIndex.toDouble());
    final fromIndex = page.floor().clamp(0, maxIndex);
    final toIndex = (fromIndex + 1).clamp(0, maxIndex);
    final progress = (page - fromIndex).clamp(0.0, 1.0);

    final fromBase = _parseBannerHexColor(
      banners[fromIndex].backgroundColorHex,
    );
    final toBase = _parseBannerHexColor(banners[toIndex].backgroundColorHex);
    final base = Color.lerp(fromBase, toBase, progress) ?? fromBase;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [base, base],
      stops: const [0.0, 1.0],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final hasBackendIssue =
        _isHomeBackendIssueState(
          context.watch<HomeProductSectionsCubit>().state,
        ) ||
        _isHomeBackendIssueState(context.watch<HomeCategoriesCubit>().state) ||
        _isHomeBackendIssueState(context.watch<SlidersCubit>().state);

    final categoriesState = context.watch<HomeCategoriesCubit>().state;
    final slidersState = context.watch<SlidersCubit>().state;
    final categories = _effectiveCategories(categoriesState);
    final stories = _effectiveStories(context.watch<StoriesCubit>().state);
    final hasStories = stories.isNotEmpty;
    final banners = _effectiveBanners(slidersState);
    final productSectionsState = context
        .watch<HomeProductSectionsCubit>()
        .state;
    final productsState = context.watch<ProductsCubit>().state;
    final popularProducts = _effectiveProductsForSection(
      productSectionsState,
      _HomeProductSection.popular,
    );
    final featuredProducts = _effectiveProductsForSection(
      productSectionsState,
      _HomeProductSection.featured,
    );
    final featuredCampaignProducts = _effectiveProductsForSection(
      productSectionsState,
      _HomeProductSection.featuredCampaign,
    );
    final featuredCampaignEndsAt =
        productSectionsState is HomeProductSectionsLoaded
        ? productSectionsState.sections.featuredCampaignEndsAt
        : null;
    final allProducts = switch (productsState) {
      ProductsLoaded(:final products) => products,
      _ => const <AllProductModel>[],
    };
    final recentlyViewedProducts = _effectiveProductsForSection(
      productSectionsState,
      _HomeProductSection.recentlyViewed,
    );
    final isCategoriesLoading =
        categoriesState is HomeCategoriesInitial ||
        categoriesState is HomeCategoriesLoading;
    final isBannersLoading =
        slidersState is SlidersInitial || slidersState is GetAllSlidersLoading;
    final isSectionsLoading =
        productSectionsState is HomeProductSectionsInitial ||
        productSectionsState is HomeProductSectionsLoading;
    final isAllProductsLoading =
        productsState is ProductsInitial || productsState is ProductsLoading;
    final isAllProductsLoadingMore = context
        .read<ProductsCubit>()
        .isLoadingMore;
    final hasAllProducts = allProducts.isNotEmpty;
    final hasFeaturedProducts = featuredProducts.isNotEmpty;
    final hasFeaturedCampaignProducts = featuredCampaignProducts.isNotEmpty;
    final hasPopularProducts = popularProducts.isNotEmpty;
    final hasRecentlyViewedProducts = recentlyViewedProducts.isNotEmpty;
    final hasAnyProductSections =
        hasAllProducts ||
        hasFeaturedProducts ||
        hasFeaturedCampaignProducts ||
        hasPopularProducts ||
        hasRecentlyViewedProducts;
    final hasAnyContent =
        hasStories ||
        categories.isNotEmpty ||
        banners.isNotEmpty ||
        hasAnyProductSections;
    final hasAnyLoading =
        isCategoriesLoading ||
        isBannersLoading ||
        isSectionsLoading ||
        isAllProductsLoading;
    final localized = S.of(context);
    final featuredLabel = Localizations.localeOf(context).languageCode == 'ar'
        ? 'مميز'
        : 'Featured';
    final featuredCampaignLabel = _featuredCampaignLabel(context);
    final campaignGridView =
        _sectionGridView[_HomeProductSection.featuredCampaign] ?? false;
    final sectionTabs = <_SectionTabItem>[
      if (hasFeaturedCampaignProducts)
        _SectionTabItem(
          label: featuredCampaignLabel,
          tab: _HomeSectionTab.featuredCampaign,
        ),
      if (isSectionsLoading || hasFeaturedProducts)
        _SectionTabItem(label: featuredLabel, tab: _HomeSectionTab.featured),
      if (isSectionsLoading || hasPopularProducts)
        _SectionTabItem(
          label: localized.popular_products,
          tab: _HomeSectionTab.popular,
        ),
      if (isSectionsLoading || hasRecentlyViewedProducts)
        _SectionTabItem(
          label: _recentlyViewedLabel(context),
          tab: _HomeSectionTab.recentlyViewed,
        ),
      if (isAllProductsLoading || hasAllProducts)
        _SectionTabItem(label: localized.all, tab: _HomeSectionTab.all),
    ];
    final selectedTab =
        sectionTabs.any((item) => item.tab == _selectedSectionTab)
        ? _selectedSectionTab
        : _HomeSectionTab.all;
    final headerGradient = _headerGradientForBannerScroll(banners);
    _configureBannerAutoScroll(banners.length);
    _scheduleSelectedSectionSync();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RefreshIndicator(
            onRefresh: _refreshHomeSections,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeTopSection(
                    gradient: headerGradient,
                    stories: stories,
                    onSearchTap: () => openRecentSearchSheet(context),
                    onLanguageTap: () => context.push(AppRouter.changeLanuage),
                    onNotificationTap: () =>
                        AppNavigator.openNotificationsOrLogin(context),
                    onStoryTap: (story) {
                      if (story.remoteStories == null ||
                          story.remoteIndex == null) {
                        return;
                      }
                      final list = story.remoteStories!;
                      final index = story.remoteIndex!;
                      final extra = {
                        'index': index,
                        'stories': list,
                        'duration': list[index].duration == 0
                            ? 5
                            : list[index].duration,
                        'mediaType': list[index].mediaType,
                      };
                      context.push(AppRouter.storiesView, extra: extra);
                    },
                  ),
                ),
                if (isBannersLoading || banners.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _HomeBanner(
                      controller: _bannerController,
                      items: banners,
                      currentPage: _bannerPage,
                      showSkeleton: isBannersLoading,
                      onPageChanged: (index) => setState(() {
                        _bannerIndex = index;
                        _bannerPage = index.toDouble();
                      }),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                ],
                if (isCategoriesLoading || categories.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _CategoriesGrid(
                      categories: categories,
                      showSkeleton: isCategoriesLoading,
                      onCategoryTap: (category) {
                        if (!category.canOpen) {
                          return;
                        }
                        final defaultChild = category.children.isNotEmpty
                            ? category.children.first
                            : null;
                        final categoryId = int.tryParse(category.id);
                        context.push(
                          AppRouter.productByCategory,
                          extra: {
                            'slug': category.slug,
                            'id': categoryId,
                            'parentName': defaultChild != null
                                ? category.title
                                : null,
                            'parentSlug': category.slug,
                            'childName': defaultChild?.title ?? category.title,
                          },
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 10.h)),
                ],
                if (sectionTabs.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Directionality(
                      textDirection:
                          Localizations.localeOf(
                                context,
                              ).languageCode.toLowerCase() ==
                              'ar'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: SizedBox(
                        height: 30.h,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          clipBehavior: Clip.none,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final item = sectionTabs[index];
                            final selected = item.tab == selectedTab;
                            return _FilterTile(
                              label: item.label,
                              selected: selected,
                              onTap: () => _scrollToSection(item.tab),
                            );
                          },
                          separatorBuilder: (_, __) => SizedBox(width: 8.w),
                          itemCount: sectionTabs.length,
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                if (isSectionsLoading || hasFeaturedCampaignProducts) ...[
                  SliverToBoxAdapter(
                    child: _ProductSection(
                      sectionKey: _featuredCampaignSectionKey,
                      title: featuredCampaignLabel,
                      products: featuredCampaignProducts,
                      fallbackImage: Assets.imagesShoes,
                      showSkeleton: isSectionsLoading,
                      isGridView: campaignGridView,
                      campaignEndsAt: featuredCampaignEndsAt,
                      showCampaignTimerPreview: true,
                      isCampaignHighlight: true,
                      onToggleGridView: (showGrid) => _toggleSectionView(
                        _HomeProductSection.featuredCampaign,
                        showGrid,
                      ),
                      onMoreTap: () => _openSectionDetails(
                        context,
                        title: featuredCampaignLabel,
                        section: _HomeProductSection.featuredCampaign,
                        campaignEndsAt: featuredCampaignEndsAt,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 18.h)),
                ],
                if (isSectionsLoading || hasFeaturedProducts) ...[
                  SliverToBoxAdapter(
                    child: _ProductSection(
                      sectionKey: _featuredSectionKey,
                      title: featuredLabel,
                      products: featuredProducts,
                      fallbackImage: Assets.imagesShoes,
                      showSkeleton: isSectionsLoading,
                      isGridView:
                          _sectionGridView[_HomeProductSection.featured] ??
                          false,
                      onToggleGridView: (showGrid) => _toggleSectionView(
                        _HomeProductSection.featured,
                        showGrid,
                      ),
                      onMoreTap: () => _openSectionDetails(
                        context,
                        title: featuredLabel,
                        section: _HomeProductSection.featured,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 18.h)),
                ],
                if (isSectionsLoading || hasPopularProducts) ...[
                  SliverToBoxAdapter(
                    child: _ProductSection(
                      sectionKey: _popularSectionKey,
                      title: localized.popular_products,
                      products: popularProducts,
                      fallbackImage: Assets.imagesShoes,
                      showSkeleton: isSectionsLoading,
                      isGridView:
                          _sectionGridView[_HomeProductSection.popular] ??
                          false,
                      onToggleGridView: (showGrid) => _toggleSectionView(
                        _HomeProductSection.popular,
                        showGrid,
                      ),
                      onMoreTap: () => _openSectionDetails(
                        context,
                        title: localized.popular_products,
                        section: _HomeProductSection.popular,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 18.h)),
                ],
                if (isSectionsLoading || hasRecentlyViewedProducts) ...[
                  SliverToBoxAdapter(
                    child: _ProductSection(
                      sectionKey: _recentlyViewedSectionKey,
                      title: _recentlyViewedLabel(context),
                      products: recentlyViewedProducts,
                      fallbackImage: Assets.imagesShoes,
                      showSkeleton: isSectionsLoading,
                      isGridView:
                          _sectionGridView[_HomeProductSection
                              .recentlyViewed] ??
                          false,
                      onToggleGridView: (showGrid) => _toggleSectionView(
                        _HomeProductSection.recentlyViewed,
                        showGrid,
                      ),
                      onMoreTap: () => _openSectionDetails(
                        context,
                        title: _recentlyViewedLabel(context),
                        section: _HomeProductSection.recentlyViewed,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 18.h)),
                ],
                if (isAllProductsLoading || hasAllProducts) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      key: _allSectionKey,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  localized.all,
                                  style: AppStyle.styleSemiBold16(context)
                                      .copyWith(
                                        fontSize: 18.sp,
                                        color: Colors.black,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          AppTapFeedback(
                            onTap: () => _openSectionDetails(
                              context,
                              title: localized.all,
                              section: _HomeProductSection.all,
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                            child: Text(
                              localized.more,
                              style: AppStyle.styleRegular14(context).copyWith(
                                color: Colors.black,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Row(
                            children: [
                              AppTapFeedback(
                                onTap: () => _toggleSectionView(
                                  _HomeProductSection.all,
                                  false,
                                ),
                                borderRadius: BorderRadius.circular(5.r),
                                child: Opacity(
                                  opacity:
                                      (_sectionGridView[_HomeProductSection
                                              .all] ??
                                          false)
                                      ? 0.6
                                      : 1,
                                  child: Image.asset(
                                    'assets/images/sorticon2.png',
                                    width: 20.w,
                                    height: 20.w,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              AppTapFeedback(
                                onTap: () => _toggleSectionView(
                                  _HomeProductSection.all,
                                  true,
                                ),
                                borderRadius: BorderRadius.circular(5.r),
                                child: Opacity(
                                  opacity:
                                      (_sectionGridView[_HomeProductSection
                                              .all] ??
                                          false)
                                      ? 1
                                      : 0.6,
                                  child: Image.asset(
                                    'assets/images/sorticon.png',
                                    width: 20.w,
                                    height: 20.w,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                  if (_sectionGridView[_HomeProductSection.all] ?? false)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10.w,
                          mainAxisSpacing: 10.h,
                          mainAxisExtent:
                              ProductCollectionCard.compactCardHeight.h,
                        ),
                        itemCount:
                            (isAllProductsLoading ? 6 : allProducts.length) +
                            (isAllProductsLoadingMore ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (isAllProductsLoading ||
                              index >= allProducts.length) {
                            return const Skeletonizer(
                              enabled: true,
                              child: _HomeGridCardSkeleton(),
                            );
                          }
                          return _InfiniteAllProductCard(
                            product: allProducts[index],
                          );
                        },
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverList.builder(
                        itemCount:
                            ((isAllProductsLoading ? 6 : allProducts.length) +
                                    (isAllProductsLoadingMore ? 2 : 0)) *
                                2 -
                            1,
                        itemBuilder: (context, index) {
                          if (index.isOdd) {
                            return SizedBox(height: 10.h);
                          }
                          final itemIndex = index ~/ 2;
                          if (isAllProductsLoading ||
                              itemIndex >= allProducts.length) {
                            return const Skeletonizer(
                              enabled: true,
                              child: ListViewItemBuildingSkeleton(),
                            );
                          }
                          return _InfiniteAllProductExpandedCard(
                            product: allProducts[itemIndex],
                          );
                        },
                      ),
                    ),
                  SliverToBoxAdapter(child: SizedBox(height: 18.h)),
                ],
                if (!hasAnyLoading && !hasAnyContent)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        Localizations.localeOf(
                                  context,
                                ).languageCode.toLowerCase() ==
                                'ar'
                            ? 'لا توجد بيانات'
                            : 'No data found',
                        style: AppStyle.styleRegular16(
                          context,
                        ).copyWith(color: AppColors.midGray),
                      ),
                    ),
                  ),
                if (hasAnyLoading || hasAnyContent)
                  SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom,
                  ),
                ),
              ],
            ),
          ),
          if (hasBackendIssue) ...[
            Positioned.fill(child: Container(color: AppColors.black20)),
            Center(
              child: SafeArea(
                minimum: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: 340,
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.softPink,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.cloud_off_rounded,
                            size: 40,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Backend Not Responding',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.deepDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Backend is not responding. Please try again later.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.midGray,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _refreshHomeSections,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              S.of(context).retry,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeTopSection extends StatelessWidget {
  const _HomeTopSection({
    required this.gradient,
    required this.stories,
    required this.onSearchTap,
    required this.onLanguageTap,
    required this.onNotificationTap,
    required this.onStoryTap,
  });

  final Gradient gradient;
  final List<_StoryViewItem> stories;
  final VoidCallback onSearchTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onNotificationTap;
  final ValueChanged<_StoryViewItem> onStoryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Column(
        children: [
          _HomeGradientHeader(
            onSearchTap: onSearchTap,
            onLanguageTap: onLanguageTap,
            onNotificationTap: onNotificationTap,
          ),
          if (stories.isNotEmpty)
            _HomeStoriesStrip(stories: stories, onStoryTap: onStoryTap),
        ],
      ),
    );
  }
}

class _HomeGradientHeader extends StatelessWidget {
  const _HomeGradientHeader({
    required this.onSearchTap,
    required this.onLanguageTap,
    required this.onNotificationTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 28.h, 16.w, 16.h),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTapFeedback(
                    onTap: onSearchTap,
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      height: 46.h,
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/searchicon.png',
                            width: 40.w,
                            height: 40.h,
                            fit: BoxFit.contain,
                            color: const Color(0xFF8A8A8A),
                            colorBlendMode: BlendMode.srcIn,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            S.of(context).search,
                            style: AppStyle.styleMedium16(
                              context,
                            ).copyWith(color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                AppTapFeedback(
                  onTap: onLanguageTap,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    width: 45.w,
                    height: 45.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        Assets.imagesGlobal,
                        width: 20.w,
                        height: 20.h,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF8A8A8A),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 45.w,
                  height: 45.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1.0,
                    ),
                  ),
                  child: NotificationBellWithBadge(
                    onTap: onNotificationTap,
                    width: 45.w,
                    height: 45.h,
                    borderRadius: BorderRadius.circular(8.r),
                    iconColor: const Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeStoriesStrip extends StatelessWidget {
  const _HomeStoriesStrip({required this.stories, required this.onStoryTap});

  final List<_StoryViewItem> stories;
  final ValueChanged<_StoryViewItem> onStoryTap;

  @override
  Widget build(BuildContext context) {
    final double avatarSize = 50.r;
    final double avatarPadding = 2.r;
    final double stripHeight = avatarSize + (avatarPadding * 2);

    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0.h, 0, 8.h),
      child: SizedBox(
        height: stripHeight,
        child: ListView.separated(
          clipBehavior: Clip.hardEdge,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final story = stories[index];
            return AppTapFeedback(
              onTap: () => onStoryTap(story),
              borderRadius: BorderRadius.circular(999.r),
              child: SizedBox.square(
                dimension: stripHeight,
                child: Container(
                  padding: EdgeInsets.all(avatarPadding),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFCB262E),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: story.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: story.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Image.asset(
                                Assets.imagesIconsStoriesWatch,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              Assets.imagesIconsStoriesWatch,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => SizedBox(width: 10.w),
          itemCount: stories.length,
        ),
      ),
    );
  }
}

class _HomeBanner extends StatelessWidget {
  const _HomeBanner({
    required this.controller,
    required this.items,
    required this.currentPage,
    required this.showSkeleton,
    required this.onPageChanged,
  });

  final PageController controller;
  final List<_BannerViewItem> items;
  final double currentPage;
  final bool showSkeleton;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final renderItems = items.isNotEmpty
        ? items
        : const [
            _BannerViewItem(
              imageAssetPath: Assets.imagesBlackFriday,
              title: 'Loading',
              subtitle: 'Loading',
              caption: 'Loading',
              backgroundColorHex: '#CB262E',
            ),
          ];

    return Skeletonizer(
      enabled: showSkeleton,
      child: SizedBox(
        height: 118.h,
        child: PageView.builder(
          controller: controller,
          itemCount: renderItems.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            final banner = renderItems[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                if (banner.imageUrl != null)
                  CachedNetworkImage(
                    imageUrl: banner.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Container(color: const Color(0xFFCB262E)),
                  )
                else if (banner.imageAssetPath != null)
                  Image.asset(banner.imageAssetPath!, fit: BoxFit.cover)
                else
                  Container(color: const Color(0xFFCB262E)),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(renderItems.length, (dotIndex) {
                      final distance = (currentPage - dotIndex).abs();
                      final strength = (1 - distance.clamp(0.0, 1.0))
                          .toDouble();
                      final width = 8.w + (14.w * strength);
                      final height = 8.h;
                      final fillAlpha = (0.1 + (0.9 * strength)).clamp(
                        0.0,
                        1.0,
                      );
                      final borderAlpha = (0.6 + (0.4 * strength)).clamp(
                        0.0,
                        1.0,
                      );
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
            );
          },
        ),
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({
    required this.categories,
    required this.showSkeleton,
    required this.onCategoryTap,
  });

  final List<_CategoryViewItem> categories;
  final bool showSkeleton;
  final ValueChanged<_CategoryViewItem> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final visible = categories.take(24).toList();
    final renderItems = visible.isNotEmpty
        ? visible
        : List<_CategoryViewItem>.generate(
            8,
            (index) => _CategoryViewItem(
              id: 'skeleton-$index',
              slug: 'skeleton-$index',
              title: S.of(context).category_label,
              imageAssetPath: Assets.imagesCategoryPlaceholder,
              children: List<_CategoryChildViewItem>.generate(
                2 + index,
                (childIndex) => _CategoryChildViewItem(
                  slug: 'skeleton-$index-$childIndex',
                  title: 'Sub category',
                ),
              ),
              canOpen: false,
            ),
          );
    final visibleRowCount = renderItems.length > 4 ? 2 : 1;
    final sectionHeight =
        (93.h * visibleRowCount) + (14.h * (visibleRowCount - 1));
    return Skeletonizer(
      enabled: showSkeleton,
      child: Container(
        color: const Color(0xFFF4F4F4),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 0, 18.h),
        child: SizedBox(
          height: sectionHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(right: 16.w),
            child: Wrap(
              direction: Axis.vertical,
              spacing: 14.h,
              runSpacing: 12.w,
              children: List.generate(renderItems.length, (index) {
                final category = renderItems[index];
                return _HomeCategoryCard(
                  category: category,
                  onCategoryTap: () => onCategoryTap(category),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeCategoryCard extends StatelessWidget {
  const _HomeCategoryCard({
    required this.category,
    required this.onCategoryTap,
  });

  final _CategoryViewItem category;
  final VoidCallback onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 75.w,
      height: 93.h,
      child: AppTapFeedback(
        onTap: onCategoryTap,
        borderRadius: BorderRadius.circular(5.r),
        child: Column(
          children: [
            Container(
              width: 75.w,
              height: 75.h,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEEEF),
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
                child:
                    category.imageUrl != null && category.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: category.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Image.asset(
                          category.imageAssetPath ??
                              Assets.imagesCategoryPlaceholder,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        category.imageAssetPath ??
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
                    category.title,
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

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color _selectedColor = Color(0x99000000);

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppTapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5.r),
      child: Container(
        constraints: BoxConstraints(minWidth: selected ? 68.w : 67.w),
        height: 30.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _selectedColor : Colors.white,
          borderRadius: BorderRadius.circular(5.r),
          border: selected
              ? null
              : Border.all(color: const Color(0x26000000), width: 1),
        ),
        child: Text(
          label,
          style: AppStyle.styleFilterChip12Medium(context).copyWith(
            color: selected ? Colors.white : Colors.black,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            height: 24 / 12,
          ),
        ),
      ),
    );
  }
}

class _InfiniteAllProductCard extends StatelessWidget {
  const _InfiniteAllProductCard({required this.product});

  final AllProductModel? product;

  @override
  Widget build(BuildContext context) {
    final itemId = (product?.id ?? 0) <= 0 ? '0' : (product!.id).toString();
    final itemSlug = product?.slug ?? '';
    final imageUrl = product?.primaryImageUrl ?? '';
    final name = product?.name.trim().isNotEmpty == true
        ? product!.name
        : 'Loading Product';
    final subtitle = product?.shortDescription.trim().isNotEmpty == true
        ? product!.shortDescription
        : ProductDescriptionFormatter.resolveShort(
            brief: '',
            descriptionHtml: product?.description ?? '',
            description: product?.description ?? '',
            fallback: S.of(context).description,
          );
    final rawPrice = product?.prices.price.trim() ?? '';
    final oldPrice = product?.prices.regularPrice.trim() ?? '';
    final currency = product?.prices.currencyCode.trim() ?? '';

    return ProductCollectionCard(
      productId: itemId,
      productSlug: itemSlug,
      selectedVariantUuid: '',
      name: name,
      subtitle: subtitle,
      price: rawPrice,
      oldPrice: oldPrice,
      currencyCode: currency,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      imageAssetPath: imageUrl.isEmpty ? Assets.imagesShoes : null,
      campaignLabel: product?.campaign?.name.trim().isNotEmpty == true
          ? product!.campaign!.name
          : '',
      campaignEndsAt: product?.campaign?.finishesAt,
      favoritesLabel:
          '${formatLocalizedNumber(context, product?.likesCount ?? 0)}  •  ${S.of(context).favorites}',
      reviewsLabel:
          '${formatLocalizedNumber(context, product?.averageRating ?? '0', fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product?.reviewCount ?? 0)} ${S.of(context).reviews}',
      isInitiallyInWishList: false,
      wishlistEnabled: false,
      onTap: () {
        if (itemId == '0') {
          return;
        }
        context.push(
          AppRouter.productDetails,
          extra: {'id': itemId, 'slug': itemSlug},
        );
      },
    );
  }
}

class _InfiniteAllProductExpandedCard extends StatelessWidget {
  const _InfiniteAllProductExpandedCard({required this.product});

  final AllProductModel? product;

  @override
  Widget build(BuildContext context) {
    final itemId = (product?.id ?? 0) <= 0 ? '0' : (product!.id).toString();
    final itemSlug = product?.slug ?? '';
    final imageUrl = product?.primaryImageUrl ?? '';
    final name = product?.name.trim().isNotEmpty == true
        ? product!.name
        : 'Loading Product';
    final subtitle = product?.shortDescription.trim().isNotEmpty == true
        ? product!.shortDescription
        : ProductDescriptionFormatter.resolveShort(
            brief: '',
            descriptionHtml: product?.description ?? '',
            description: product?.description ?? '',
            fallback: S.of(context).description,
          );
    final rawPrice = product?.prices.price.trim() ?? '';
    final oldPrice = product?.prices.regularPrice.trim() ?? '';
    final currency = product?.prices.currencyCode.trim() ?? '';

    return SizedBox(
      height: 580.h,
      child: ProductCollectionCard(
        productId: itemId,
        productSlug: itemSlug,
        selectedVariantUuid: '',
        width: double.infinity,
        type: ProductCollectionCardType.expanded,
        name: name,
        subtitle: subtitle,
        price: rawPrice,
        oldPrice: oldPrice,
        currencyCode: currency,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        imageAssetPath: imageUrl.isEmpty ? Assets.imagesShoes : null,
        campaignLabel: product?.campaign?.name.trim().isNotEmpty == true
            ? product!.campaign!.name
            : '',
        campaignEndsAt: product?.campaign?.finishesAt,
        favoritesLabel:
            '${formatLocalizedNumber(context, product?.likesCount ?? 0)}  •  ${S.of(context).favorites}',
        reviewsLabel:
            '${formatLocalizedNumber(context, product?.averageRating ?? '0', fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product?.reviewCount ?? 0)} ${S.of(context).reviews}',
        isInitiallyInWishList: false,
        wishlistEnabled: false,
        onTap: () {
          if (itemId == '0') {
            return;
          }
          context.push(
            AppRouter.productDetails,
            extra: {'id': itemId, 'slug': itemSlug},
          );
        },
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.sectionKey,
    required this.title,
    required this.products,
    required this.fallbackImage,
    required this.showSkeleton,
    required this.isGridView,
    required this.onToggleGridView,
    required this.onMoreTap,
    this.campaignEndsAt,
    this.showCampaignTimerPreview = false,
    this.isCampaignHighlight = false,
  });

  final GlobalKey sectionKey;
  final String title;
  final List<HomeGraphqlProduct> products;
  final String fallbackImage;
  final bool showSkeleton;
  final bool isGridView;
  final ValueChanged<bool> onToggleGridView;
  final VoidCallback onMoreTap;
  final DateTime? campaignEndsAt;
  final bool showCampaignTimerPreview;
  final bool isCampaignHighlight;

  @override
  Widget build(BuildContext context) {
    final localized = S.of(context);
    final items = products
        .take(8)
        .map(
          (product) => _ProductCardData(
            id: product.uuid,
            slug: product.slug,
            selectedVariantUuid: product.variantUuid ?? '',
            campaignLabel: product.campaign?.name.trim().isNotEmpty == true
                ? product.campaign!.name
                : (campaignEndsAt != null ? title : ''),
            name: product.title,
            subtitle: ProductDescriptionFormatter.resolveShort(
              brief: product.brief,
              descriptionHtml: product.descriptionHtml,
              description: product.description,
              fallback: localized.description,
            ),
            imageUrl: product.primaryVariantImageUrl,
            imageAssetPath: fallbackImage,
            price: product.formattedPrice,
            oldPrice: product.formattedOriginalPrice,
            currencyCode: product.formattedCurrencyCode,
            favoritesLabel:
                '${formatLocalizedNumber(context, product.likesCount)}  •  ${localized.favorites}',
            reviewsLabel:
                '${formatLocalizedNumber(context, product.averageRatingText, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product.reviewsCount)} ${localized.reviews}',
            canOpenDetails: true,
            wishlistEnabled: false,
            campaignEndsAt: product.campaign?.finishesAt ?? campaignEndsAt,
          ),
        )
        .toList();
    final visibleItems = items.take(8).toList();
    final isCampaignHighlight = this.isCampaignHighlight;
    final containerDecoration = isCampaignHighlight
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFF8F5),
                Colors.white,
                const Color(0xFFFFF2EE).withValues(alpha: 0.92),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: const Color(0xFFF0D8D2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          )
        : const BoxDecoration();

    return Skeletonizer(
      enabled: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isCampaignHighlight ? 12.w : 0,
        ),
        child: Container(
          key: sectionKey,
          decoration: containerDecoration,
          padding: EdgeInsets.only(
            top: isCampaignHighlight ? 14.h : 0,
            bottom: isCampaignHighlight ? 6.h : 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Directionality(
                  textDirection:
                      Localizations.localeOf(context).languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  (isCampaignHighlight
                                          ? AppStyle.styleSectionTitle16Medium(
                                              context,
                                            )
                                          : AppStyle.styleSectionTitle16Medium(
                                              context,
                                            ))
                                      .copyWith(
                                        color: const Color(0xFF111827),
                                        fontSize: isCampaignHighlight
                                            ? 16.sp
                                            : 14.sp,
                                        fontWeight: isCampaignHighlight
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                            ),
                          ),
                          Row(
                            children: [
                              AppTapFeedback(
                                onTap: onMoreTap,
                                borderRadius: BorderRadius.circular(10.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCampaignHighlight ? 12.w : 0,
                                    vertical: isCampaignHighlight ? 6.h : 0,
                                  ),
                                  decoration: isCampaignHighlight
                                      ? BoxDecoration(
                                          color: const Color(0xFFFFEAE3),
                                          borderRadius: BorderRadius.circular(
                                            999.r,
                                          ),
                                        )
                                      : null,
                                  child: Text(
                                    localized.more,
                                    style: AppStyle.styleRegular14(context)
                                        .copyWith(
                                          color: isCampaignHighlight
                                              ? const Color(0xFFB4232A)
                                              : Colors.black,
                                          decoration: isCampaignHighlight
                                              ? TextDecoration.none
                                              : TextDecoration.underline,
                                          fontWeight: isCampaignHighlight
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              AppTapFeedback(
                                onTap: () => onToggleGridView(false),
                                borderRadius: BorderRadius.circular(5.r),
                                child: Opacity(
                                  opacity: isGridView ? 0.6 : 1,
                                  child: Image.asset(
                                    'assets/images/sorticon2.png',
                                    width: 20.w,
                                    height: 20.w,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              AppTapFeedback(
                                onTap: () => onToggleGridView(true),
                                borderRadius: BorderRadius.circular(5.r),
                                child: Opacity(
                                  opacity: isGridView ? 1 : 0.6,
                                  child: Image.asset(
                                    'assets/images/sorticon.png',
                                    width: 20.w,
                                    height: 20.w,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isCampaignHighlight) ...[
                        SizedBox(height: 8.h),
                        Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'العرض المميز للحملة الحالية.'
                              : 'Highlighted picks from the active campaign.',
                          style: TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: 12.sp,
                            fontFamily: 'Montes',
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: isCampaignHighlight ? 14.h : 10.h),
              SizedBox(
                height: isGridView
                    ? ProductCollectionCard.compactCardHeight.h + 24.h
                    : 580.h,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16.w,
                    8.h,
                    28.w,
                    isCampaignHighlight ? 24.h : 20.h,
                  ),
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    if (showSkeleton) {
                      return isGridView
                          ? const Skeletonizer(
                              enabled: true,
                              child: _HomeGridCardSkeleton(),
                            )
                          : const Skeletonizer(
                              enabled: true,
                              child: ListViewItemBuildingSkeleton(),
                            );
                    }
                    if (index == visibleItems.length) {
                      return _SectionSeeAllCard(
                        isGridView: isGridView,
                        onTap: onMoreTap,
                      );
                    }
                    if (isGridView) {
                      return SizedBox(
                        width: ProductCollectionCard.compactCardWidth.w,
                        child: _ProductGridCard(
                          item: visibleItems[index],
                          showCampaignTimerPreview: showCampaignTimerPreview,
                        ),
                      );
                    }
                    return _ProductCard(
                      item: visibleItems[index],
                      showCampaignTimerPreview: showCampaignTimerPreview,
                    );
                  },
                  separatorBuilder: (_, __) => SizedBox(width: 10.w),
                  itemCount: showSkeleton ? 8 : visibleItems.length + 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeGridCardSkeleton extends StatelessWidget {
  const _HomeGridCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ProductCollectionCard.compactCardWidth.w,
      child: Container(
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
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.showCampaignTimerPreview,
  });

  final _ProductCardData item;
  final bool showCampaignTimerPreview;

  @override
  Widget build(BuildContext context) {
    return ProductCollectionCard(
      productId: item.id,
      productSlug: item.slug,
      selectedVariantUuid: item.selectedVariantUuid,
      width: ProductCollectionCard.expandedCardWidth.w,
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
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({
    required this.item,
    required this.showCampaignTimerPreview,
  });

  final _ProductCardData item;
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

class _SectionSeeAllCard extends StatelessWidget {
  const _SectionSeeAllCard({required this.isGridView, required this.onTap});

  final bool isGridView;
  final VoidCallback onTap;

  String _seeAllLabel(BuildContext context) {
    return Localizations.localeOf(context).languageCode.toLowerCase() == 'ar'
        ? 'عرض الكل'
        : 'See all';
  }

  @override
  Widget build(BuildContext context) {
    final width = isGridView ? 138.w : 176.w;
    final height = isGridView
        ? ProductCollectionCard.compactCardHeight.h
        : ProductCollectionCard.expandedCardHeight.h;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return AppTapFeedback(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFABABAB),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _seeAllLabel(context),
                  style: AppStyle.styleSemiBold16(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 16.h),
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 1.8,
                    ),
                  ),
                  child: Icon(
                    isRtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _HomeSectionTab {
  all,
  recentlyViewed,
  featured,
  featuredCampaign,
  popular,
}

enum _HomeProductSection {
  all,
  featured,
  featuredCampaign,
  popular,
  recentlyViewed,
}

class _SectionTabItem {
  const _SectionTabItem({required this.label, required this.tab});

  final String label;
  final _HomeSectionTab tab;
}

class _StoryViewItem {
  const _StoryViewItem({
    this.imageUrl,
    this.mediaType,
    this.remoteIndex,
    this.remoteStories,
  });

  final String? imageUrl;
  final String? mediaType;
  final int? remoteIndex;
  final List<dynamic>? remoteStories;
}

class _BannerViewItem {
  const _BannerViewItem({
    required this.title,
    required this.subtitle,
    required this.caption,
    this.backgroundColorHex = '',
    this.imageUrl,
    this.imageAssetPath,
  });

  final String title;
  final String subtitle;
  final String caption;
  final String backgroundColorHex;
  final String? imageUrl;
  final String? imageAssetPath;
}

class _CategoryViewItem {
  const _CategoryViewItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.canOpen,
    this.children = const [],
    this.imageUrl,
    this.imageAssetPath,
  });

  final String id;
  final String slug;
  final String title;
  final bool canOpen;
  final List<_CategoryChildViewItem> children;
  final String? imageUrl;
  final String? imageAssetPath;
}

class _CategoryChildViewItem {
  const _CategoryChildViewItem({required this.slug, required this.title});

  final String slug;
  final String title;
}

class _ProductCardData {
  const _ProductCardData({
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
