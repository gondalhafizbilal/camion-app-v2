import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
import 'package:camion/core/api/local_status_codes.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/features/order_status/data/models/order_model/order_model.dart';
import 'package:camion/features/order_status/presentation/logic/cubit/get_orders_cubit/get_orders_cubit.dart';
import 'package:camion/features/order_status/presentation/logic/cubit/toggle_nav_bar/toggle_nav_bar_cubit.dart';
import 'package:camion/features/order_status/utils/order_status_utils.dart';
import 'package:camion/features/order_status/presentation/widgets/custom_order.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key, this.openedFromProfile = false});

  final bool openedFromProfile;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<OrderModel> _allOrders = const [];
  final Set<String> _deletingOrderIds = <String>{};

  Future<void> _refreshOrders() async {
    final selectedIndex = context.read<ToggleNavBarCubit>().state.index;
    if (selectedIndex == 1) {
      await context.read<GetOrdersCubit>().getOrderStatus(status: "delivered");
      return;
    }
    if (selectedIndex == 2) {
      await context.read<GetOrdersCubit>().getOrderStatus(
        status: "payment_successful",
      );
      return;
    }
    await context.read<GetOrdersCubit>().getOrders();
  }

  bool _isConnectivityErrorStatus(int? statusCode) {
    return statusCode == LocalStatusCodes.connectionError ||
        statusCode == LocalStatusCodes.connectionTimeout ||
        statusCode == LocalStatusCodes.sendTimeout ||
        statusCode == LocalStatusCodes.receiveTimeout;
  }

  String? _variantTitleFromOrder(OrderModel order) {
    if (order.items.isEmpty) return null;
    for (final variation in order.items.first.variation) {
      final attribute = variation.attribute.trim().toLowerCase();
      if (attribute != 'variant') continue;
      final value = variation.value.trim();
      return value.isEmpty ? null : value;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    context.read<GetOrdersCubit>().getOrders();
  }

  bool _isCompletedStatus(OrderModel order) {
    return isDeliveredLikeStatus(order.wcOrderStatus) ||
        isDeliveredLikeStatus(order.statusDisplay);
  }

  bool _isCancelableStatus(OrderModel order) {
    return isCancelableOrderStatus(order.wcOrderStatus) ||
        isCancelableOrderStatus(order.statusDisplay);
  }

  Future<void> _confirmCancelOrder(OrderModel order) async {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final orderLabel = isArabic ? 'الطلب' : 'this order';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isArabic ? 'إلغاء الطلب' : 'Cancel Order'),
          content: Text(
            isArabic
                ? 'هل تريد بالتأكيد حذف هذا الطلب؟'
                : 'Are you sure you want to delete $orderLabel?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(isArabic ? 'لا' : 'No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(isArabic ? 'نعم' : 'Yes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _deletingOrderIds.add(order.id);
    });

    final result = await context.read<GetOrdersCubit>().deleteOrder(
      orderId: order.id,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _deletingOrderIds.remove(order.id);
    });

    result.fold(
      (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      },
      (_) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم إلغاء الطلب بنجاح'
                  : 'Order cancelled successfully',
            ),
          ),
        );
        await _refreshOrders();
      },
    );
  }

  List<_OrderFilterOption> _buildFilters(BuildContext context) {
    return [
      _OrderFilterOption(
        title: S.of(context).all,
        onTap: () => context.read<GetOrdersCubit>().getOrders(),
      ),
      _OrderFilterOption(
        title: S.of(context).delivered,
        onTap: () =>
            context.read<GetOrdersCubit>().getOrderStatus(status: "delivered"),
      ),
      _OrderFilterOption(
        title: S.of(context).completed,
        onTap: () => context.read<GetOrdersCubit>().getOrderStatus(
          status: "payment_successful",
        ),
      ),
    ];
  }

  _OrderSummaryCounts _buildSummaryCounts(List<OrderModel> orders) {
    final toBeShipped = orders
        .where((order) => !order.isDelivered && !_isCompletedStatus(order))
        .length;
    final shipped = orders.where((order) => order.isDelivered).length;
    final toBeReviewed = orders.where(_isCompletedStatus).length;

    return _OrderSummaryCounts(
      toBeShipped: toBeShipped,
      shipped: shipped,
      toBeReviewed: toBeReviewed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final filters = _buildFilters(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CustomSliverAppBar(
              appBarHeight: 50.h,
              centerTitle: false,
              leading: GestureDetector(
                onTap: () {
                  AppNavigator.safePop(
                    context,
                    fallbackRoute:
                        '${AppRouter.selectingFromBottomNavBar}?tab=4',
                  );
                },
                child: Icon(
                  Icons.arrow_back,
                  color: AppColors.black,
                  size: 24.sp,
                ),
              ),
              title: Text(
                S.of(context).my_orders,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 20.sp,
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w500,
                  height: 2,
                ),
              ),
              actions: const [],
              isShoppingCartShown: false,
              isShownActions: false,
              isShownDivider: false,
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            BlocBuilder<GetOrdersCubit, GetOrdersState>(
              buildWhen: (previous, current) =>
                  current is GetOrdersSuccess ||
                  current is GetOrdersLoading ||
                  current is GetOrdersError,
              builder: (context, state) {
                final selectedIndex = context
                    .watch<ToggleNavBarCubit>()
                    .state
                    .index;
                if (state is GetOrdersSuccess && selectedIndex == 0) {
                  _allOrders = state.orders;
                }
                final summarySource = _allOrders.isNotEmpty
                    ? _allOrders
                    : state is GetOrdersSuccess
                    ? state.orders
                    : const <OrderModel>[];
                final summaryCounts = _buildSummaryCounts(summarySource);

                return SliverToBoxAdapter(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 82.h,
                        child: ListView(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          scrollDirection: Axis.horizontal,
                          children: [
                            _OrderSummaryTile(
                              count: summaryCounts.toBeShipped,
                              label: isArabic ? 'جاهز للشحن' : 'To Be Shipped',
                            ),
                            SizedBox(width: 8.w),
                            _OrderSummaryTile(
                              count: summaryCounts.shipped,
                              label: isArabic ? 'تم الشحن' : 'Shipped',
                            ),
                            SizedBox(width: 8.w),
                            _OrderSummaryTile(
                              count: summaryCounts.toBeReviewed,
                              label: isArabic
                                  ? 'بانتظار التقييم'
                                  : 'To Be Reviewed',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      SizedBox(
                        height: 30.h,
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          scrollDirection: Axis.horizontal,
                          itemCount: filters.length,
                          separatorBuilder: (_, __) => SizedBox(width: 10.w),
                          itemBuilder: (context, index) {
                            return BlocSelector<
                              ToggleNavBarCubit,
                              ToggleNavBarState,
                              bool
                            >(
                              selector: (state) => state.index == index,
                              builder: (context, isActive) {
                                return GestureDetector(
                                  onTap: () {
                                    context
                                        .read<ToggleNavBarCubit>()
                                        .toggle(index)
                                        .then((_) => filters[index].onTap());
                                  },
                                  child: _OrderFilterChip(
                                    label: filters[index].title,
                                    isActive: isActive,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 18.h),
                    ],
                  ),
                );
              },
            ),
            BlocBuilder<GetOrdersCubit, GetOrdersState>(
              buildWhen: (previous, current) =>
                  current is GetOrdersSuccess ||
                  current is GetOrdersLoading ||
                  current is GetOrdersError,
              builder: (context, state) {
                if (state is GetOrdersLoading) {
                  return const SliverToBoxAdapter(child: _OrdersShimmerList());
                }

                if (state is GetOrdersSuccess) {
                  if (context.read<ToggleNavBarCubit>().state.index == 0) {
                    _allOrders = state.orders;
                  }

                  if (state.orders.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80.h),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 52.sp,
                                color: Colors.grey.shade500,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                isArabic ? 'لا توجد طلبات' : 'No orders found',
                                style:
                                    AppStyle.styleSectionTitle16Medium(
                                      context,
                                    ).copyWith(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList.builder(
                      itemCount: state.orders.length,
                      itemBuilder: (context, index) {
                        final order = state.orders[index];
                        final subTotalPrice = order.subTotal.toStringAsFixed(2);
                        final totalPrice =
                            (order.total > 0 ? order.total : order.grandTotal)
                                .toStringAsFixed(2);
                        final currencyCode = resolveCurrencyCode([
                          order.currencyCode,
                        ]);

                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: GestureDetector(
                            onTap: () {
                              final extra = {
                                'currency': currencyCode,
                                'items': order.items,
                                'numberOfOrder': order.id,
                                'subTotalPrice': subTotalPrice,
                                'totalPrice': totalPrice,
                                'orderDate': order.createdAt,
                                'shippingCost': order.shippingCost.toString(),
                                'paymentMethod': order.paymentMethod,
                                'discount': order.discount.toString(),
                                'shippingAddress':
                                    "${order.customerData?.city ?? ''} ${order.customerData?.address1 ?? ''}",
                              };
                              GoRouter.of(context).push(
                                AppRouter.orderDetailsScreen,
                                extra: extra,
                              );
                            },
                            child: CustomOrder(
                              currencyCode: currencyCode,
                              orderId: order.worderId,
                              orderImage: order.items.isNotEmpty
                                  ? order.items.first.image
                                  : '',
                              orderTitle: order.items.isNotEmpty
                                  ? order.items.first.title
                                  : (isArabic ? 'عنصر طلب' : 'Order Item'),
                              variantTitle: _variantTitleFromOrder(order),
                              numberOfRequest: order.id,
                              productId: order.items.isNotEmpty
                                  ? order.items.first.productId
                                  : '',
                              canCancelOrder: _isCancelableStatus(order),
                              isCanceling: _deletingOrderIds.contains(order.id),
                              onCancelOrder: () => _confirmCancelOrder(order),
                              paymentMethod: order.paymentMethod,
                              deliveryEta: order.eta,
                              totalPrice: totalPrice,
                              numberOfProducts: order.items.length,
                              date: order.createdAt,
                              orderStatus: order.wcOrderStatus.trim().isNotEmpty
                                  ? order.wcOrderStatus
                                  : order.statusDisplay,
                              onTapOnOrderDetails: () {
                                final extra = {
                                  'currency': currencyCode,
                                  'items': order.items,
                                  'numberOfOrder': order.id,
                                  'subTotalPrice': subTotalPrice,
                                  'totalPrice': totalPrice,
                                  'orderDate': order.createdAt,
                                  'shippingCost': order.shippingCost.toString(),
                                  'paymentMethod': order.paymentMethod,
                                  'discount': order.discount.toString(),
                                  'shippingAddress':
                                      "${order.customerData?.city ?? ''} ${order.customerData?.address1 ?? ''}",
                                };
                                GoRouter.of(context).push(
                                  AppRouter.orderDetailsScreen,
                                  extra: extra,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                if (state is GetOrdersError) {
                  if (_isConnectivityErrorStatus(state.error.statusCode)) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40.h),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(state.error.icon, color: Colors.red, size: 50),
                            SizedBox(height: 20.h),
                            Text(
                              state.error.message,
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10.h),
                            ElevatedButton(
                              onPressed: () {
                                context.read<GetOrdersCubit>().getOrders();
                              },
                              child: Text(
                                S.of(context).retry,
                                style: TextStyle(fontSize: 16.sp),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
            SliverToBoxAdapter(child: SizedBox(height: 100.h)),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryCounts {
  const _OrderSummaryCounts({
    required this.toBeShipped,
    required this.shipped,
    required this.toBeReviewed,
  });

  final int toBeShipped;
  final int shipped;
  final int toBeReviewed;
}

class _OrderFilterOption {
  const _OrderFilterOption({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;
}

class _OrderSummaryTile extends StatelessWidget {
  const _OrderSummaryTile({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108.w,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              count.toString().padLeft(2, '0'),
              style: AppStyle.styleSectionTitle16Medium(context).copyWith(
                color: AppColors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                height: 24 / 16,
              ),
            ),
          ),
          const Spacer(),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppStyle.styleCategoryLabel10SemiBold(
              context,
            ).copyWith(color: AppColors.black, height: 18 / 10),
          ),
        ],
      ),
    );
  }
}

class _OrderFilterChip extends StatelessWidget {
  const _OrderFilterChip({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 68.w),
      height: 30.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryColor : AppColors.white,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(
          color: isActive ? AppColors.primaryColor : AppColors.borderGray,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppStyle.styleFilterChip12Medium(context).copyWith(
          color: isActive ? AppColors.white : AppColors.black,
          height: 1,
        ),
      ),
    );
  }
}

class _OrdersShimmerList extends StatelessWidget {
  const _OrdersShimmerList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE6E6E6),
      highlightColor: const Color(0xFFF6F6F6),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: List.generate(4, (index) {
            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.r),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 130.w,
                        height: 18.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 90.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  Container(
                    width: double.infinity,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: List.generate(2, (metricIndex) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: metricIndex == 0 ? 14.w : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 90.w,
                                height: 10.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Container(
                                width: 70.w,
                                height: 18.h,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Container(
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
