import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/discount_percentage_badge.dart';
import 'package:camion/config/widgets/formatted_price_text.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/features/home/presentation/widgets/listing_quick_add_flow.dart';
import 'package:camion/features/home/presentation/screens/home_screen.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/add_to_wish_list/wish_list_cubit.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/get_wish_listcubit/get_wish_list_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:skeletonizer/skeletonizer.dart';

class GridItemBuilding extends StatelessWidget {
  static const double cardWidth = 165;
  static const double cardHeight = 336;
  static const double imageHeight = 230;

  const GridItemBuilding({
    super.key,
    required this.imageUrl,
    required this.productName,
    required this.originalPrice,
    required this.onTap,
    required this.averageRating,
    required this.reviewCount,
    required this.outPrice,
    required this.productId,
    required this.currencyCode,
    required this.currencySymbol,
    required this.onBasketTap,
    this.showWishlistButton = false,
    this.wishlistEnabled = false,
    this.forceIsInWishList,
  });

  final String imageUrl;
  final String productName;
  final String originalPrice;
  final String averageRating;
  final String reviewCount;
  final String outPrice;
  final String productId;
  final VoidCallback onTap;
  final FutureOr<void> Function(BuildContext context) onBasketTap;
  final String currencyCode;
  final String currencySymbol;
  final bool showWishlistButton;
  final bool wishlistEnabled;
  final bool? forceIsInWishList;

  int get _discountPercentage {
    final current = double.tryParse(originalPrice.trim().replaceAll(',', ''));
    final old = double.tryParse(outPrice.trim().replaceAll(',', ''));
    if (current == null || old == null) return 0;
    if (current <= 0 || old <= current) return 0;
    return (((old - current) / old) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final hasReviews = (int.tryParse(reviewCount.trim()) ?? 0) > 0;
    return AppTapFeedback(
      onTap: () {
        unawaited(
          sl<AppsFlyerService>().logConversionEvent(
            'select_item',
            eventParams: {
              'product_id': productId.trim(),
              'category': 'product',
              'item_value':
                  double.tryParse(originalPrice.trim().replaceAll(',', '')) ??
                  0,
              if (currencyCode.trim().isNotEmpty)
                'currency': currencyCode.trim().toUpperCase(),
            },
          ),
        );
        onTap();
      },
      borderRadius: BorderRadius.circular(5.r),
      child: Container(
        width: cardWidth.w,
        height: cardHeight.h,
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
            SizedBox(
              width: double.infinity,
              height: imageHeight.h,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFFE7E7E7),
                          width: 1.w,
                        ),
                        left: BorderSide(
                          color: const Color(0xFFE7E7E7),
                          width: 1.w,
                        ),
                        right: BorderSide(
                          color: const Color(0xFFE7E7E7),
                          width: 1.w,
                        ),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5.r),
                        topRight: Radius.circular(5.r),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5.r),
                        topRight: Radius.circular(5.r),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Skeletonizer(
                          enabled: true,
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Image.asset(
                              Assets.imagesShoes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            Image.asset(Assets.imagesShoes, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  if (showWishlistButton && wishlistEnabled)
                    Positioned(
                      top: 12.h,
                      right: 12.w,
                      child: _GridWishlistButton(
                        productId: productId,
                        productName: productName,
                        price: originalPrice,
                        imageUrl: imageUrl,
                        wishlistEnabled: wishlistEnabled,
                        forceIsInWishList: forceIsInWishList,
                      ),
                    ),
                  PositionedDirectional(
                    end: 10.w,
                    bottom: 10.h,
                    child: ListingBasketButton(onTap: onBasketTap, size: 32),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTight = constraints.maxHeight <= 80.h;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      10.w,
                      isTight ? 6.h : 8.h,
                      10.w,
                      isTight ? 6.h : 8.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            productName,
                            maxLines: isTight ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyle.styleBold14(context).copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: isTight ? 12.sp : 14.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: isTight ? 4.h : 6.h),
                        Row(
                          children: [
                            if (_discountPercentage > 0) ...[
                              DiscountPercentageBadge(
                                percentage: _discountPercentage,
                                compact: true,
                              ),
                              SizedBox(width: 3.w),
                            ],
                            Flexible(
                              fit: FlexFit.loose,
                              child: Builder(
                                builder: (context) {
                                  final display = resolveCurrencyCode([
                                    currencyCode,
                                    currencySymbol,
                                  ]);
                                  return FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: FormattedPriceText(
                                      amountText: originalPrice,
                                      currencyText: display,
                                      mainStyle: AppStyle.styleBold16(context)
                                          .copyWith(
                                            color: AppColors.primaryColor,
                                            fontSize: 10.sp,
                                          ),
                                      minorStyle: TextStyle(
                                        fontFamily: 'Montes',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 8.sp,
                                        height: 1,
                                        color: AppColors.primaryColor,
                                      ),
                                      spaceBeforeCurrency: true,
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (outPrice != originalPrice) ...[
                              SizedBox(width: 3.w),
                              Flexible(
                                fit: FlexFit.loose,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: FormattedPriceText(
                                    amountText: outPrice,
                                    currencyText: '',
                                    mainStyle: AppStyle.styleRegular12(context)
                                        .copyWith(
                                          color: AppColors.gray,
                                          fontSize: 10.sp,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                    minorStyle: TextStyle(
                                      fontFamily: 'Montes',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8.sp,
                                      height: 1,
                                      color: AppColors.gray,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                    spaceBeforeCurrency: false,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (hasReviews) ...[
                          SizedBox(height: isTight ? 4.h : 6.h),
                          Row(
                            children: [
                              Text(
                                averageRating,
                                style: AppStyle.styleRegular12(context)
                                    .copyWith(
                                      color: Colors.black,
                                      fontSize: isTight ? 10.sp : 12.sp,
                                    ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: isTight ? 12.sp : 14.sp,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  reviewCount,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppStyle.styleRegular12(context)
                                      .copyWith(
                                        color: AppColors.gray,
                                        fontSize: isTight ? 10.sp : 12.sp,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridWishlistButton extends StatelessWidget {
  const _GridWishlistButton({
    required this.productId,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.wishlistEnabled,
    this.forceIsInWishList,
  });

  final String productId;
  final String productName;
  final String price;
  final String imageUrl;
  final bool wishlistEnabled;
  final bool? forceIsInWishList;

  Future<void> _handleTap(BuildContext context, bool isInWishList) async {
    if (!wishlistEnabled) {
      return;
    }

    final canProceed = await AppNavigator.ensureAuthenticatedCustomer(context);
    if (!canProceed) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    final wishListCubit = context.read<GetWishListCubit>();
    if (isInWishList) {
      await wishListCubit.removeFromWishList(productId: productId);
    } else {
      await context.read<AddToWishListCubit>().addtoWishList(
        productId: productId,
        title: productName,
        price: price,
        image: imageUrl,
      );
    }

    if (!context.mounted) {
      return;
    }

    await wishListCubit.getWishList();
    HomeScreen.homeKey.currentState?.refreshWishListAndCartList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetWishListCubit, GetWishListState>(
      builder: (context, state) {
        final isInWishList =
            forceIsInWishList ??
            (state is GetWishListSuccess
                ? state.wishLists.any((item) => item.productId == productId)
                : false);

        return AppTapFeedback(
          onTap: () => _handleTap(context, isInWishList),
          customBorder: const CircleBorder(),
          child: Container(
            width: 35.w,
            height: 35.w,
            decoration: BoxDecoration(
              color: isInWishList ? const Color(0x1A000000) : null,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x1A000000), width: 1),
            ),
            child: Opacity(
              opacity: wishlistEnabled ? 1 : 0.9,
              child: Center(
                child: isInWishList
                    ? SvgPicture.asset(
                        Assets.imagesIconsNewwwActiveHeart,
                        width: 26.w,
                        height: 26.h,
                      )
                    : Image.asset(
                        Assets.imagesIconsWishlistOutlineHeart,
                        width: 32.w,
                        height: 32.h,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
