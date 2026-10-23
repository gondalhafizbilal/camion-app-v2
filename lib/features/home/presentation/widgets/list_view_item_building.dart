import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/config/widgets/discount_percentage_badge.dart';
import 'package:camion/config/widgets/formatted_price_text.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/presentation/widgets/listing_quick_add_flow.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ListViewItemBuilding extends StatefulWidget {
  const ListViewItemBuilding({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.originalPrice,
    required this.productId,
    required this.onAddToCartTap,
    required this.onAddToWishListTap,
    required this.onBasketTap,
    required this.outPrice,
    required this.averageRating,
    required this.reviewCount,
    required this.currencyCode,
    required this.currencySymbol,
  });

  final String imageUrl;
  final String productName;
  final String originalPrice;
  final String outPrice;
  final String productId;
  final VoidCallback onAddToCartTap;
  final VoidCallback onAddToWishListTap;
  final FutureOr<void> Function(BuildContext context) onBasketTap;
  final String averageRating;
  final String reviewCount;
  final String currencyCode;
  final String currencySymbol;

  @override
  State<ListViewItemBuilding> createState() => _ListViewItemBuildingState();
}

class _ListViewItemBuildingState extends State<ListViewItemBuilding> {
  int currentIndex = 0;

  int get _discountPercentage {
    final current = double.tryParse(
      widget.originalPrice.trim().replaceAll(',', ''),
    );
    final old = double.tryParse(widget.outPrice.trim().replaceAll(',', ''));
    if (current == null || old == null) return 0;
    if (current <= 0 || old <= current) return 0;
    return (((old - current) / old) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final resolvedImageUrl = widget.imageUrl.trim();
    final hasImage = resolvedImageUrl.isNotEmpty;
    final hasReviews = (int.tryParse(widget.reviewCount.trim()) ?? 0) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),

          height: screenWidth > 800 ? 500.h : 400.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              hasImage
                  ? CachedNetworkImage(
                      fit: BoxFit.cover,
                      imageUrl: resolvedImageUrl,
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: const Color(0xFFF5F5F5),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      placeholder: (context, url) => Skeletonizer(
                        enabled: true,
                        child: SizedBox(
                          height: 400,
                          width: double.infinity,
                          child: Image.asset(
                            Assets.imagesShoes,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => SizedBox(
                        height: 400,
                        width: double.infinity,
                        child: Image.asset(
                          Assets.imagesShoes,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 400,
                      width: double.infinity,
                      child: Image.asset(Assets.imagesShoes, fit: BoxFit.cover),
                    ),
              PositionedDirectional(
                end: 10.w,
                bottom: 10.h,
                child: ListingBasketButton(onTap: widget.onBasketTap, size: 32),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.productName,
                      style: AppStyle.styleBold18(context),
                      // textDirection: TextDirection.ltr,
                    ),
                  ),

                  // SizedBox(width: 20.w),
                ],
              ),

              SizedBox(height: 8.h),

              Row(
                children: [
                  if (_discountPercentage > 0) ...[
                    DiscountPercentageBadge(percentage: _discountPercentage),
                    SizedBox(width: 4.w),
                  ],
                  Flexible(
                    fit: FlexFit.loose,
                    child: Builder(
                      builder: (context) {
                        final display = resolveCurrencyCode([
                          widget.currencyCode,
                          widget.currencySymbol,
                        ]);
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: FormattedPriceText(
                            amountText: widget.originalPrice,
                            currencyText: display,
                            mainStyle: AppStyle.styleBold20(context).copyWith(
                              color: AppColors.primaryColor,
                              fontSize: 12.sp,
                            ),
                            minorStyle: TextStyle(
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w600,
                              fontSize: 10.sp,
                              height: 1,
                              color: AppColors.primaryColor,
                            ),
                            spaceBeforeCurrency: true,
                          ),
                        );
                      },
                    ),
                  ),
                  widget.originalPrice == widget.outPrice
                      ? const SizedBox()
                      : Flexible(
                          fit: FlexFit.loose,
                          child: Builder(
                            builder: (context) {
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: FormattedPriceText(
                                  amountText: widget.outPrice,
                                  currencyText: '',
                                  mainStyle: AppStyle.styleRegular15(context)
                                      .copyWith(
                                        color: AppColors.gray,
                                        fontSize: 12.sp,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                  minorStyle: TextStyle(
                                    fontFamily: 'Montes',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.sp,
                                    height: 1,
                                    color: AppColors.gray,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  spaceBeforeCurrency: false,
                                ),
                              );
                            },
                          ),
                        ),

                  SizedBox(width: 4.w),
                ],
              ),

              if (hasReviews) ...[
                SizedBox(height: 5.h),
                Row(
                  children: [
                    Text(
                      widget.averageRating,
                      style: AppStyle.styleRegular14(
                        context,
                      ).copyWith(color: AppColors.gray),
                    ),

                    SizedBox(width: 5.w),
                    ...List.generate(5, (index) {
                      int rating = 0;
                      try {
                        rating = double.parse(widget.averageRating).toInt();
                      } catch (e) {
                        rating = 0;
                      }
                      return Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20.r,
                      );
                    }),
                  ],
                ),
                SizedBox(height: 5.h),
                Row(
                  children: [
                    Text(
                      widget.reviewCount,
                      style: AppStyle.styleRegular14(
                        context,
                      ).copyWith(color: AppColors.gray),
                    ),

                    SizedBox(width: 5.w),

                    Icon(Icons.visibility, color: AppColors.gray, size: 15.r),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: CustomElevatedButton(
                  onPressed: () {
                    unawaited(
                      sl<AppsFlyerService>().logConversionEvent(
                        'select_item',
                        eventParams: {
                          'product_id': widget.productId.trim(),
                          'category': 'product',
                          'item_value':
                              double.tryParse(
                                widget.originalPrice.trim().replaceAll(',', ''),
                              ) ??
                              0,
                          if (widget.currencyCode.trim().isNotEmpty)
                            'currency': widget.currencyCode
                                .trim()
                                .toUpperCase(),
                        },
                      ),
                    );
                    GoRouter.of(
                      context,
                    ).push(AppRouter.productDetails, extra: widget.productId);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        S.of(context).choose_prduct,
                        style: AppStyle.styleRegular15(
                          context,
                        ).copyWith(color: Colors.white),
                      ),

                      // SizedBox(width: 6.w),

                      // SvgPicture.asset(
                      //   Assets.imagesShoppingCartWhite,
                      //   width: 22.w,
                      //   height: 22.h,
                      // ),
                    ],
                  ),
                ),
                // child: BlocBuilder<AddCartCubit, AddCartState>(
                //   builder: (context, state) {
                //     final cubit = context.read<AddCartCubit>();
                //     final isInCart = cubit.isProductInCart(widget.productId);
                //     final isLoading =
                //         state is AddCartLoading &&
                //         state.productId == widget.productId;
                //     return isInCart
                //         ? ElevatedButton(
                //             onPressed: () {
                //               GoRouter.of(context).push(AppRouter.myCart);
                //             },
                //             style: ElevatedButton.styleFrom(
                //               padding: EdgeInsets.symmetric(vertical: 16.h),
                //               backgroundColor: AppColors.blueC3,
                //               shape: RoundedRectangleBorder(
                //                 borderRadius: BorderRadius.circular(16.r),
                //               ),
                //             ),
                //             child: Row(
                //               mainAxisAlignment: MainAxisAlignment.center,
                //               children: isLoading
                //                   ? [
                //                       const CircularProgressIndicator(
                //                         color: Colors.white,
                //                       ),
                //                     ]
                //                   : [
                //                       Text(
                //                         'أذهب الي العربة',
                //                         style: AppStyle.styleRegular15(
                //                           context,
                //                         ).copyWith(color: Colors.white),
                //                       ),

                //                       SizedBox(width: 6.w),

                //                       SvgPicture.asset(
                //                         Assets.imagesShoppingCartWhite,
                //                         width: 22.w,
                //                         height: 22.h,
                //                       ),
                //                     ],
                //             ),
                //           )
                //         : ElevatedButton(
                //             onPressed: state is! AddCartLoading
                //                 ? () {}
                //                 : widget.onAddToCartTap,
                //             style: ElevatedButton.styleFrom(
                //               padding: EdgeInsets.symmetric(vertical: 16.h),
                //               backgroundColor: AppColors.primaryColor,
                //               shape: RoundedRectangleBorder(
                //                 borderRadius: BorderRadius.circular(16.r),
                //               ),
                //             ),
                //             child: Row(
                //               mainAxisAlignment: MainAxisAlignment.center,
                //               children: state is AddCartLoading
                //                   ? [
                //                       const CircularProgressIndicator(
                //                         color: Colors.white,
                //                       ),
                //                     ]
                //                   : [
                //                       Text(
                //                         'أضف للعربة',
                //                         style: AppStyle.styleRegular15(
                //                           context,
                //                         ).copyWith(color: Colors.white),
                //                       ),

                //                       SizedBox(width: 6.w),

                //                       SvgPicture.asset(
                //                         Assets.imagesShoppingCartWhite,
                //                         width: 22.w,
                //                         height: 22.h,
                //                       ),
                //                     ],
                //             ),
                //           );
                //   },
                // ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
