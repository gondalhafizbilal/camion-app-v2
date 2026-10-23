import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/config/widgets/notification_bell_with_badge.dart';
import 'package:camion/config/localization/cubit/localizations_cubit.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/features/cart/presentation/logic/cubit/get_cart_cubit/get_cart_cubit.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class CustomSliverAppBar extends StatelessWidget {
  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.leading,
    this.leadingWidth,
    this.centerTitle,
    this.cartImage,
    this.isShoppingCartShown,
    this.isShownDivider,
    this.isShownActions,
    this.readOnly,
    this.onSearchTap,
    this.flexibleSpace,
    this.appBarHeight,
    this.actions,
    this.topContentPadding,
  });

  final Widget title;
  final Widget? leading;
  final double? leadingWidth;
  final bool? centerTitle;
  final String? cartImage;
  final bool? isShoppingCartShown;
  final bool? isShownDivider;
  final bool? isShownActions;
  final bool? readOnly;
  final VoidCallback? onSearchTap;
  final Widget? flexibleSpace;
  final double? appBarHeight;
  final List<Widget>? actions;
  final double? topContentPadding;

  @override
  Widget build(BuildContext context) {
    GetCartCubit? getCartCubit;
    try {
      getCartCubit = BlocProvider.of<GetCartCubit>(context);
    } catch (_) {
      getCartCubit = null;
    }
    final hasFlexibleSpace = flexibleSpace != null;
    final resolvedTopContentPadding = topContentPadding ?? 0;
    final baseToolbarHeight = 50.h;
    final resolvedToolbarHeight = baseToolbarHeight;
    final resolvedExpandedHeight = hasFlexibleSpace
        ? (appBarHeight ?? 150.h)
        : resolvedToolbarHeight;
    final resolvedActions = isShownActions == false
        ? <Widget>[]
        : (actions ??
              [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isShoppingCartShown ?? true
                        ? SizedBox(
                            width: 40.r,
                            height: 40.r,
                            child: Center(
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned.fill(
                                    child: AppTapFeedback(
                                      onTap: () async {
                                        final router = GoRouter.of(context);
                                        final currentRoute = GoRouterState.of(
                                          context,
                                        ).uri.toString();
                                        String? langCode;
                                        try {
                                          langCode = context
                                              .read<LocalizationsCubit>()
                                              .state
                                              .languageCode;
                                        } catch (_) {}

                                        if (currentRoute !=
                                                AppRouter
                                                    .selectingFromBottomNavBarCartTab &&
                                            currentRoute != AppRouter.myCart) {
                                          AppNavigator.rememberCartBackTarget(
                                            context,
                                          );
                                          router.go(
                                            AppRouter
                                                .selectingFromBottomNavBarCartTab,
                                          );
                                          final lang = langCode;
                                          if (lang != null &&
                                              lang.isNotEmpty &&
                                              getCartCubit != null) {
                                            getCartCubit.getCart(lang);
                                          }
                                        }
                                      },
                                      customBorder: const CircleBorder(),
                                      child: Center(
                                        child: SvgPicture.asset(
                                          cartImage ??
                                              Assets.imagesShoppingCart,
                                          width: 25,
                                          height: 25,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (getCartCubit != null)
                                    BlocBuilder<GetCartCubit, GetCartState>(
                                      bloc: getCartCubit,
                                      builder: (context, state) {
                                        if (state is GetCartSuccess) {
                                          return state.cartList.isEmpty
                                              ? Container()
                                              : Positioned(
                                                  top: -11.h,
                                                  right: -6.w,
                                                  child: Container(
                                                    padding: EdgeInsets.all(
                                                      6.r,
                                                    ),
                                                    decoration:
                                                        const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: AppColors
                                                              .primaryColor,
                                                        ),
                                                    child: Text(
                                                      state.cartList.length
                                                          .toString(),
                                                      style:
                                                          AppStyle.styleRegular12(
                                                            context,
                                                          ).copyWith(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                        }
                                        return Container();
                                      },
                                    ),
                                ],
                              ),
                            ),
                          )
                        : Container(),
                    SizedBox(width: 8.w),
                    SizedBox(
                      width: 40.r,
                      height: 40.r,
                      child: NotificationBellWithBadge(
                        onTap: () =>
                            AppNavigator.openNotificationsOrLogin(context),
                      ),
                    ),
                    SizedBox(
                      width:
                          context
                                  .watch<LocalizationsCubit>()
                                  .state
                                  .languageCode ==
                              'ar'
                          ? 0
                          : 8.w,
                    ),
                  ],
                ),
              ]);

    final canPop =
        Navigator.of(context).canPop() || GoRouter.of(context).canPop();
    final resolvedLeading =
        leading ??
        (canPop
            ? IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(width: 40.r, height: 40.r),
                onPressed: () => AppNavigator.safePop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.black,
                  size: 24.sp,
                ),
              )
            : null);

    return SliverAppBar(
      toolbarHeight: resolvedToolbarHeight,
      collapsedHeight: resolvedToolbarHeight,
      expandedHeight: resolvedExpandedHeight,
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      scrolledUnderElevation: 0,
      actionsPadding: EdgeInsets.symmetric(horizontal: 16.w),

      leadingWidth: leadingWidth ?? 56.w,
      leading: resolvedLeading == null
          ? null
          : Padding(
              padding: EdgeInsets.only(top: resolvedTopContentPadding),
              child: Center(child: resolvedLeading),
            ),
      title: Padding(
        padding: EdgeInsets.only(top: resolvedTopContentPadding),
        child: title,
      ),
      centerTitle: centerTitle ?? true,
      titleSpacing: (centerTitle ?? true) ? null : 0,

      actions: resolvedActions
          .map(
            (action) => Padding(
              padding: EdgeInsets.only(top: resolvedTopContentPadding),
              child: action,
            ),
          )
          .toList(),

      flexibleSpace: flexibleSpace,

      bottom: isShownDivider == true
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade300,
              ),
            )
          : null,
    );
  }
}
