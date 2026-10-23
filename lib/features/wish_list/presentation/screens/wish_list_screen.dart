import 'dart:async';

import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/section_top_header.dart';
import 'package:camion/core/api/api_locale_mapper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/auth_session_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/connectivity_error_utils.dart';
import 'package:camion/core/utils/product_description_formatter.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/presentation/screens/home_screen.dart';
import 'package:camion/features/home/presentation/widgets/product_collection_card.dart';
import 'package:camion/features/wish_list/data/models/get_wish_list_model.dart';
import 'package:camion/features/wish_list/data/repository/wish_list_repo.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/add_to_wish_list/wish_list_cubit.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/get_wish_listcubit/get_wish_list_cubit.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class WishListScreen extends StatelessWidget {
  const WishListScreen({super.key});

  static GlobalKey<WishListScreenBodyState> wishListKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetWishListCubit(sl<WishListRepository>()),
        ),
        BlocProvider(
          create: (context) => AddToWishListCubit(sl<WishListRepository>()),
        ),
      ],
      child: WishListScreenBody(key: wishListKey),
    );
  }
}

class WishListScreenBody extends StatefulWidget {
  const WishListScreenBody({super.key});

  @override
  State<WishListScreenBody> createState() => WishListScreenBodyState();
}

class WishListScreenBodyState extends State<WishListScreenBody> {
  static const double _horizontalPadding = 16;

  List<GetWishListModel> wishList = [];
  List<HomeGraphqlProduct> popularProducts = [];
  Set<int> selectedItems = {};
  bool isSelectionMode = false;
  bool isLoggedIn = false;
  bool authResolved = false;
  bool _popularLoading = true;
  bool _popularGridView = true;
  final HomeRepository _homeRepository = sl<HomeRepository>();
  String? _lastLocaleCode;
  int _popularRequestGeneration = 0;

  void _handleAuthChanged() {
    refreshGetWishList();
  }

  @override
  void initState() {
    super.initState();
    sl<AuthSessionNotifier>().addListener(_handleAuthChanged);
    refreshGetWishList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    if (_lastLocaleCode == null) {
      _lastLocaleCode = localeCode;
      return;
    }
    if (_lastLocaleCode == localeCode) {
      return;
    }
    _lastLocaleCode = localeCode;
    setState(() {
      _popularLoading = true;
      _popularRequestGeneration++;
    });
    refreshGetWishList();
  }

  @override
  void dispose() {
    sl<AuthSessionNotifier>().removeListener(_handleAuthChanged);
    super.dispose();
  }

  Future<void> refreshGetWishList() async {
    if (!mounted) {
      return;
    }

    final authState = sl<AuthSessionNotifier>();
    final loggedIn = authState.isLoggedIn;
    setState(() {
      isLoggedIn = loggedIn;
      authResolved = true;
      _popularLoading = true;
      wishList = [];
      selectedItems.clear();
      isSelectionMode = false;
    });

    if (loggedIn) {
      unawaited(context.read<GetWishListCubit>().getWishList());
      unawaited(_loadPopularProducts());
    } else {
      wishList = [];
      unawaited(_loadPopularProducts());
    }
  }

  Future<void> _loadPopularProducts({int itemsPerPage = 4}) async {
    final requestGeneration = ++_popularRequestGeneration;
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final languageCode =
        (await sl<SecureCacheHelper>().getData(key: 'languageCode')) ?? '';
    final language = ApiLocaleMapper.toGraphqlLocale(languageCode);

    final result = await _homeRepository.getPopularGraphqlProducts(
      token: token,
      language: language,
      pageNumber: 1,
      itemsPerPage: itemsPerPage,
    );
    if (!mounted || requestGeneration != _popularRequestGeneration) return;

    result.fold(
      (_) => setState(() {
        popularProducts = const <HomeGraphqlProduct>[];
        _popularLoading = false;
      }),
      (products) => setState(() {
        popularProducts = products;
        _popularLoading = false;
      }),
    );
  }

  void toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        selectedItems.clear();
      }
    });
  }

  Future<void> handleTrashTap() async {
    if (!isSelectionMode) {
      setState(() {
        isSelectionMode = true;
        selectedItems.clear();
      });
      return;
    }

    if (selectedItems.isEmpty) {
      return;
    }

    await deleteSelectedItems();
  }

  void toggleSelection(int index) {
    setState(() {
      if (selectedItems.contains(index)) {
        selectedItems.remove(index);
      } else {
        selectedItems.add(index);
      }
    });
  }

  Future<void> deleteSelectedItems() async {
    final indexes = selectedItems.toList()..sort((a, b) => b.compareTo(a));
    for (final index in indexes) {
      await _deleteItem(index);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      selectedItems.clear();
      isSelectionMode = false;
    });
  }

  Future<void> _deleteItem(int index) async {
    if (index < 0 || index >= wishList.length) {
      return;
    }

    final removedItem = wishList[index];
    final originalIndex = index;

    setState(() {
      wishList.removeAt(index);
      selectedItems.remove(index);
      final updatedSelections = <int>{};
      for (final selectedIndex in selectedItems) {
        if (selectedIndex > index) {
          updatedSelections.add(selectedIndex - 1);
        } else {
          updatedSelections.add(selectedIndex);
        }
      }
      selectedItems = updatedSelections;
    });

    try {
      final removeTargetId = (removedItem.id ?? '').trim().isNotEmpty
          ? removedItem.id!.trim()
          : (removedItem.productId ?? '').trim();
      await context.read<GetWishListCubit>().removeFromWishList(
        productId: removeTargetId,
      );
      HomeScreen.homeKey.currentState?.refreshWishListAndCartList();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        wishList.insert(originalIndex, removedItem);
      });
    }
  }

  Future<void> _openLogin() async {
    final next = Uri.encodeComponent(
      '${AppRouter.selectingFromBottomNavBar}?tab=2',
    );
    await GoRouter.of(context).push('${AppRouter.login}?next=$next');
    await refreshGetWishList();
  }

  Future<void> _refreshWishlistScreen() async {
    await refreshGetWishList();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GetWishListCubit, GetWishListState>(
          listener: (context, state) {
            if (state is GetWishListWithPopularSuccess) {
              setState(() {
                wishList = state.wishLists;
                selectedItems.clear();
                isSelectionMode = false;
              });
              return;
            }
            if (state is GetWishListSuccess) {
              setState(() {
                wishList = state.wishLists;
                selectedItems.clear();
                isSelectionMode = false;
              });
              return;
            }
          },
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _refreshWishlistScreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox.shrink()),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _horizontalPadding.w,
                  50.h,
                  _horizontalPadding.w,
                  0,
                ),
                child: const _WishlistHeader(),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 22.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: _horizontalPadding.w),
                child: _SavedProductsHeader(
                  isLoggedIn: isLoggedIn,
                  isSelectionMode: isSelectionMode,
                  hasSavedProducts: wishList.isNotEmpty,
                  onBagTap: isLoggedIn && wishList.isNotEmpty
                      ? toggleSelectionMode
                      : null,
                  onTrashTap: isLoggedIn && wishList.isNotEmpty
                      ? handleTrashTap
                      : null,
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 22.h)),
            ..._buildSavedProductsSection(),
            SliverToBoxAdapter(child: SizedBox(height: 30.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: _horizontalPadding.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        S.of(context).popular_products,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Montes',
                          height: 24 / 20,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(
                        AppRouter.homeSectionDetails,
                        extra: {
                          'title': S.of(context).popular_products,
                          'section': 'popular',
                        },
                      ),
                      child: Text(
                        S.of(context).more,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.sp,
                          decoration: TextDecoration.underline,
                          fontFamily: 'Montes',
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    GestureDetector(
                      onTap: () => setState(() => _popularGridView = false),
                      child: Opacity(
                        opacity: _popularGridView ? 0.6 : 1,
                        child: Image.asset(
                          'assets/images/sorticon2.png',
                          width: 20.w,
                          height: 20.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: () => setState(() => _popularGridView = true),
                      child: Opacity(
                        opacity: _popularGridView ? 1 : 0.6,
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
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 18.h)),
            ..._buildPopularProductsSection(),
            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSavedProductsSection() {
    final localized = S.of(context);
    final state = context.watch<GetWishListCubit>().state;

    if (!authResolved) {
      return const [SliverToBoxAdapter(child: _WishlistGuestCardShimmer())];
    }

    if (!isLoggedIn) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _horizontalPadding.w),
            child: _WishlistGuestCard(onLoginTap: _openLogin),
          ),
        ),
      ];
    }

    if (state is GetWishListLoading && wishList.isEmpty) {
      return const [
        _ProductGridShimmerSliver(mainAxisSpacing: 18, itemCount: 6),
      ];
    }

    if (state is GetWishListError) {
      if (isConnectivityErrorStatus(state.error.statusCode)) {
        return const [SliverToBoxAdapter(child: SizedBox.shrink())];
      }
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _horizontalPadding.w),
            child: _StateMessageCard(
              icon: Icon(state.error.icon, color: Colors.red, size: 36.sp),
              title: state.error.message,
              subtitle: localized.retry,
              buttonLabel: localized.retry,
              onTap: () => refreshGetWishList(),
            ),
          ),
        ),
      ];
    }

    if (wishList.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _horizontalPadding.w),
            child: _StateMessageCard(
              icon: Icon(
                Icons.favorite_border_rounded,
                color: const Color(0xFFD72631),
                size: 52.sp,
              ),
              title: localized.Your_wishlist_is_empty,
              subtitle: localized.add_some_products_to_your_favorites,
            ),
          ),
        ),
      ];
    }

    return [
      if (isSelectionMode && selectedItems.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _horizontalPadding.w,
              0,
              _horizontalPadding.w,
              16.h,
            ),
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withAlpha(12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primaryColor.withAlpha(40)),
              ),
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'تم تحديد ${selectedItems.length} ${selectedItems.length == 1 ? 'عنصر' : 'عناصر'}.'
                    : '${selectedItems.length} item${selectedItems.length == 1 ? '' : 's'} selected.',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montes',
                ),
              ),
            ),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: _horizontalPadding.w),
        sliver: SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 18.h,
            mainAxisExtent: ProductCollectionCard.compactCardHeight.h,
          ),
          itemCount: wishList.length,
          itemBuilder: (context, index) {
            final item = wishList[index];
            final isSelected = selectedItems.contains(index);
            final navigationProductId = (item.productId ?? '').trim();
            final navigationProductSlug = (item.productSlug ?? '').trim();
            final canNavigate =
                navigationProductId.isNotEmpty ||
                navigationProductSlug.isNotEmpty;

            return Stack(
              children: [
                ProductCollectionCard(
                  productId: item.productId ?? '',
                  productSlug: item.productSlug ?? '',
                  name: item.productName ?? '',
                  subtitle: ProductDescriptionFormatter.resolveShort(
                    brief: item.productBrief,
                    descriptionHtml: item.productDescriptionHtml,
                    description: item.productDescription,
                    fallback: localized.description,
                  ),
                  price: item.price?.toString() ?? '',
                  oldPrice: item.oldPrice?.toString() ?? '',
                  showOldPriceWhenSame: true,
                  currencyCode: item.currencyCode?.trim().isNotEmpty == true
                      ? item.currencyCode!.trim().toUpperCase()
                      : savedCurrencyCode(),
                  favoritesLabel:
                      '${formatLocalizedNumber(context, item.likesCount)}  •  ${localized.favorites}',
                  reviewsLabel:
                      '${formatLocalizedNumber(context, item.averageRatingText, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, item.reviewsCount)} ${localized.reviews}',
                  imageUrl: item.productImage ?? '',
                  imageAssetPath: Assets.imagesShoes,
                  campaignLabel: item.campaign?.name.trim().isNotEmpty == true
                      ? item.campaign!.name
                      : (item.campaign?.finishesAt != null
                            ? (item.productName ?? '')
                            : ''),
                  campaignEndsAt: item.campaign?.finishesAt,
                  isInitiallyInWishList: true,
                  wishlistEnabled: false,
                  forceIsInWishList: true,
                  onTap: isSelectionMode
                      ? () => toggleSelection(index)
                      : !canNavigate
                      ? () {}
                      : () => GoRouter.of(context).push(
                          AppRouter.productDetails,
                          extra: {
                            'id': navigationProductId,
                            'slug': navigationProductSlug,
                            'selectedVariantUuid':
                                item.defaultVariantUuid ?? '',
                          },
                        ),
                ),
                if (isSelectionMode)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryColor
                                : const Color(0xFFD0D5DD),
                            width: isSelected ? 2.w : 1.w,
                          ),
                          color: isSelected
                              ? AppColors.primaryColor.withAlpha(22)
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                if (isSelectionMode)
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: IgnorePointer(
                      child: Container(
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryColor
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryColor
                                : const Color(0xFFD0D5DD),
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14.sp,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildPopularProductsSection() {
    if (_popularLoading && popularProducts.isEmpty) {
      return const [
        _ProductGridShimmerSliver(mainAxisSpacing: 12, itemCount: 4),
      ];
    }

    if (popularProducts.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: _horizontalPadding.w),
            child: _StateMessageCard(
              icon: Icon(
                Icons.inventory_2_outlined,
                color: const Color(0xFFD72631),
                size: 42.sp,
              ),
              title: 'Popular products will appear here soon.',
              subtitle: 'This area will stay dynamic as product data loads.',
            ),
          ),
        ),
      ];
    }

    return [
      if (_popularGridView)
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding.w),
          sliver: SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 8.w,
              mainAxisExtent: ProductCollectionCard.compactCardHeight.h,
            ),
            itemCount: popularProducts.length,
            itemBuilder: (context, index) {
              final product = popularProducts[index];
              return ProductCollectionCard(
                productId: product.uuid,
                productSlug: product.slug,
                name: product.title,
                subtitle: ProductDescriptionFormatter.resolveShort(
                  brief: product.brief,
                  descriptionHtml: product.descriptionHtml,
                  description: product.description,
                  fallback: S.of(context).description,
                ),
                price: product.formattedPrice,
                oldPrice: product.formattedOriginalPrice,
                currencyCode: product.formattedCurrencyCode,
                favoritesLabel:
                    '${formatLocalizedNumber(context, product.likesCount)}  •  ${S.of(context).favorites}',
                reviewsLabel:
                    '${formatLocalizedNumber(context, product.averageRatingText, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product.reviewsCount)} ${S.of(context).reviews}',
                imageUrl: product.primaryVariantImageUrl,
                imageAssetPath: Assets.imagesShoes,
                campaignLabel: product.campaign?.name.trim().isNotEmpty == true
                    ? product.campaign!.name
                    : (product.campaign?.finishesAt != null
                          ? product.title
                          : ''),
                campaignEndsAt: product.campaign?.finishesAt,
                isInitiallyInWishList: false,
                wishlistEnabled: false,
                onTap: () => context.push(
                  AppRouter.productDetails,
                  extra: {
                    'id': product.uuid,
                    'slug': product.slug,
                    'selectedVariantUuid': product.variantUuid ?? '',
                  },
                ),
              );
            },
          ),
        )
      else
        SliverToBoxAdapter(
          child: SizedBox(
            height: 580.h,
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                _horizontalPadding.w,
                8.h,
                (_horizontalPadding + 12).w,
                20.h,
              ),
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: popularProducts.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, index) {
                final product = popularProducts[index];
                return SizedBox(
                  width: ProductCollectionCard.expandedCardWidth.w,
                  child: ProductCollectionCard(
                    productId: product.uuid,
                    productSlug: product.slug,
                    type: ProductCollectionCardType.expanded,
                    width: ProductCollectionCard.expandedCardWidth.w,
                    name: product.title,
                    subtitle: ProductDescriptionFormatter.resolveShort(
                      brief: product.brief,
                      descriptionHtml: product.descriptionHtml,
                      description: product.description,
                      fallback: S.of(context).description,
                    ),
                    price: product.formattedPrice,
                    oldPrice: product.formattedOriginalPrice,
                    currencyCode: product.formattedCurrencyCode,
                    favoritesLabel:
                        '${formatLocalizedNumber(context, product.likesCount)}  •  ${S.of(context).favorites}',
                    reviewsLabel:
                        '${formatLocalizedNumber(context, product.averageRatingText, fractionDigits: 1)} ★★★★★  •  ${formatLocalizedNumber(context, product.reviewsCount)} ${S.of(context).reviews}',
                    imageUrl: product.primaryVariantImageUrl,
                    imageAssetPath: Assets.imagesShoes,
                    campaignLabel:
                        product.campaign?.name.trim().isNotEmpty == true
                        ? product.campaign!.name
                        : (product.campaign?.finishesAt != null
                              ? product.title
                              : ''),
                    campaignEndsAt: product.campaign?.finishesAt,
                    isInitiallyInWishList: false,
                    wishlistEnabled: false,
                    onTap: () => context.push(
                      AppRouter.productDetails,
                      extra: {
                        'id': product.uuid,
                        'slug': product.slug,
                        'selectedVariantUuid': product.variantUuid ?? '',
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
    ];
  }
}

class _WishlistHeader extends StatelessWidget {
  const _WishlistHeader();

  @override
  Widget build(BuildContext context) {
    return SectionTopHeader(
      title: Localizations.localeOf(context).languageCode == 'ar'
          ? 'قائمة الرغبات'
          : 'Wishlist',
    );
  }
}

class _SavedProductsHeader extends StatelessWidget {
  const _SavedProductsHeader({
    required this.isLoggedIn,
    required this.isSelectionMode,
    required this.hasSavedProducts,
    this.onBagTap,
    this.onTrashTap,
  });

  final bool isLoggedIn;
  final bool isSelectionMode;
  final bool hasSavedProducts;
  final VoidCallback? onBagTap;
  final VoidCallback? onTrashTap;

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return Text(
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'المنتجات المحفوظة'
            : 'Saved Products',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Montes',
          height: 24 / 20,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            Localizations.localeOf(context).languageCode == 'ar'
                ? 'المنتجات المحفوظة'
                : 'Saved Products',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Montes',
              height: 24 / 20,
            ),
          ),
        ),
        _ActionIcon(
          assetPath: Assets.imagesWishlistSaved,
          enabled: isLoggedIn && hasSavedProducts,
          onTap: onBagTap,
        ),
        SizedBox(width: 18.w),
        _ActionIcon(
          assetPath: Assets.imagesWishlistDelete,
          enabled: isLoggedIn && hasSavedProducts,
          onTap: onTrashTap,
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.assetPath,
    required this.enabled,
    this.onTap,
  });

  final String assetPath;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppTapFeedback(
      onTap: enabled ? onTap : null,
      customBorder: const CircleBorder(),
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: SizedBox(
          width: 40.w,
          height: 40.w,
          child: Center(
            child: Image.asset(
              assetPath,
              width: 40.w,
              height: 40.h,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _WishlistGuestCard extends StatelessWidget {
  const _WishlistGuestCard({required this.onLoginTap});

  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 343.w,
        constraints: BoxConstraints(minHeight: 252.h),
        padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 18.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFD9D9D9)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Container(
                  width: 50.w,
                  height: 50.h,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD72631),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'سجّل الدخول لتجربة أفضل!'
                      : 'Login for a better experience!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montes',
                    height: 24 / 16,
                  ),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'سجّل الدخول لحفظ المنتجات والوصول إلى قائمة رغباتك في أي وقت.'
                        : 'Sign in to save products and access your wishlist anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF333333),
                      fontSize: 14.sp,
                      height: 24 / 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Montes',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 295.w,
              height: 50.h,
              child: ElevatedButton(
                onPressed: onLoginTap,
                style:
                    ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD72631),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      elevation: 0,
                      shadowColor: const Color(0x33D72631),
                      animationDuration: const Duration(milliseconds: 160),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith<Color?>((
                        states,
                      ) {
                        if (states.contains(WidgetState.pressed)) {
                          return Colors.white.withAlpha(46);
                        }
                        if (states.contains(WidgetState.hovered) ||
                            states.contains(WidgetState.focused)) {
                          return Colors.white.withAlpha(20);
                        }
                        return null;
                      }),
                      splashFactory: InkRipple.splashFactory,
                      elevation: WidgetStateProperty.resolveWith<double>(
                        (states) =>
                            states.contains(WidgetState.pressed) ? 2 : 0,
                      ),
                    ),
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'تسجيل الدخول'
                      : 'Log In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montes',
                    height: 24 / 16,
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

class _WishlistGuestCardShimmer extends StatelessWidget {
  const _WishlistGuestCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE6E6E6),
      highlightColor: const Color(0xFFF5F5F5),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: WishListScreenBodyState._horizontalPadding.w,
        ),
        child: Container(
          height: 252.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: const Color(0xFFD9D9D9)),
          ),
        ),
      ),
    );
  }
}

class _StateMessageCard extends StatelessWidget {
  const _StateMessageCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onTap,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          icon,
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Montes',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF667085),
              fontSize: 14.sp,
              height: 1.5,
              fontFamily: 'Montes',
            ),
          ),
          if (buttonLabel != null && onTap != null) ...[
            SizedBox(height: 18.h),
            ElevatedButton(onPressed: onTap, child: Text(buttonLabel!)),
          ],
        ],
      ),
    );
  }
}

class _ProductGridShimmerSliver extends StatelessWidget {
  const _ProductGridShimmerSliver({
    required this.mainAxisSpacing,
    required this.itemCount,
  });

  final double mainAxisSpacing;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: WishListScreenBodyState._horizontalPadding.w,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: mainAxisSpacing.h,
          mainAxisExtent: ProductCollectionCard.compactCardHeight.h,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const _ProductCardShimmer(),
      ),
    );
  }
}

class _ProductCardShimmer extends StatelessWidget {
  const _ProductCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE6E6E6),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        margin: EdgeInsets.fromLTRB(2.w, 2.h, 2.w, 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 16,
              spreadRadius: 1,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: ProductCollectionCard.compactImageHeight.h,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: const Color(0xFFE7E7E7), width: 1.w),
                  left: BorderSide(color: const Color(0xFFE7E7E7), width: 1.w),
                  right: BorderSide(color: const Color(0xFFE7E7E7), width: 1.w),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5.r),
                  topRight: Radius.circular(5.r),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 92.w,
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: 74.w,
                      height: 9.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 110.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 120.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 96.w,
                      height: 11.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
