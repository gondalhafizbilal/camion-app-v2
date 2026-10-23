import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/features/home/presentation/logic/cubit/products_cubit/products_cubit.dart';
import 'package:camion/features/home/presentation/widgets/custom_product.dart';
import 'package:camion/features/home/presentation/widgets/grid_item_skeletonizer.dart';
import 'package:camion/features/home/presentation/widgets/listing_quick_add_flow.dart';
import 'package:camion/features/home/presentation/widgets/product_collection_card.dart';
import 'package:camion/core/utils/connectivity_error_utils.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SliverGridViewBuilding extends StatelessWidget {
  const SliverGridViewBuilding({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  final double screenWidth;
  final double screenHeight;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        if (state is ProductsLoading) {
          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth > 800 ? 3 : 2,
              mainAxisExtent: ProductCollectionCard.compactCardHeight.h,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 10.h,
            ),
            itemBuilder: (context, index) {
              return const Skeletonizer(
                enabled: true,
                child: GridItemBuildingSkeleton(),
              );
            },
            itemCount: 20,
          );
        }

        if (state is ProductsLoaded) {
          final bool isLoadingMore = context
              .watch<ProductsCubit>()
              .isLoadingMore;

          final products = state.products;
          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth > 800 ? 3 : 2,
              mainAxisExtent: ProductCollectionCard.compactCardHeight.h,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 10.h,
            ),
            itemBuilder: (context, index) {
              if (index < products.length) {
                final product = products[index];
                return AppTapFeedback(
                  onTap: () {
                    GoRouter.of(context).push(
                      AppRouter.productDetails,
                      extra: {
                        'id': product.id.toString(),
                        'slug': product.slug,
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(14.r),
                  child: ProductCarouselWidget(
                    reviewCount: product.reviewCount.toString(),
                    averageRating: product.averageRating,
                    productId: product.id.toString(),
                    currencyCode: product.prices.currencyCode,
                    currencySymbol: product.prices.currencySymbol,
                    imageUrl: product.images.isEmpty
                        ? ''
                        : product.images[0].thumbnail,
                    productName: product.name,
                    originalPrice: product.prices.price.toString(),
                    outPrice: product.prices.regularPrice,
                    isGridView: true,
                    onAddToCartTap: () {
                      // context.read<AddCartCubit>().addToCart(
                      //   productId: product.id.toString(),
                      //   title: product.name,
                      //   price: product.prices.price,
                      //   image: product.images[0].thumbnail,
                      //   quantity: 1,
                      // );
                    },
                    onBasketTap: (buttonContext) => handleListingQuickAddTap(
                      buttonContext,
                      productSlug: product.slug,
                      showAddedToCartPreview: false,
                    ),
                    onAddToWishListTap: () {},
                  ),
                );
              } else if (isLoadingMore) {
                return const Skeletonizer(
                  enabled: true,
                  child: GridItemBuildingSkeleton(),
                );
              }
              return const SizedBox();
            },
            itemCount: state.products.length + (isLoadingMore ? 2 : 0),
          );
        }

        if (state is ProductsError) {
          if (isBackendUnavailableStatus(state.error.statusCode)) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }
          return SliverToBoxAdapter(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(state.error.icon, color: Colors.red, size: 50),

                  SizedBox(height: 20.h),
                  Text(
                    state.error.message,
                    style: TextStyle(fontSize: 16.sp, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 10.h),

                  ElevatedButton(
                    onPressed: () {
                      context.read<ProductsCubit>().getProducts(
                        lang: context
                            .read<LocalizationsCubit>()
                            .state
                            .languageCode,
                      );
                    },
                    child: Text(
                      S.of(context).retry,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Container();
      },
    );
  }
}
