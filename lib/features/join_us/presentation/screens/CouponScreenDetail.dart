import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/features/join_us/data/models/coupons_model/get_coupons_model.dart';
import 'package:camion/features/join_us/data/repository/supplier_repo.dart';
import 'package:camion/features/join_us/presentation/widgets/custom__join_us_sliver_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class CouponStatsScreen extends StatefulWidget {
  const CouponStatsScreen({super.key, required this.coupon});

  final GetCouponsModel coupon;

  @override
  State<CouponStatsScreen> createState() => _CouponStatsScreenState();
}

class _CouponStatsScreenState extends State<CouponStatsScreen> {
  late Future<List<CouponOrderStat>> _ordersFuture;
  late final String _savedCurrencyCode;

  @override
  void initState() {
    super.initState();
    _savedCurrencyCode =
        (sl<CacheHelper>().getDataString(key: 'currencyCode') ?? '').trim();
    _ordersFuture = _loadOrders();
  }

  Future<List<CouponOrderStat>> _loadOrders() async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (token == null || token.trim().isEmpty) {
      return const [];
    }

    final result = await sl<AffiliateRepository>().getCouponOrders(
      token: token,
      uuid: widget.coupon.id,
      pageNumber: 1,
      itemsPerPage: 24,
    );
    return result.fold((_) => <CouponOrderStat>[], (orders) => orders);
  }

  String _formatDate(DateTime dateTime, String languageCode) {
    return DateFormat(
      'MMM dd, yyyy hh:mm a',
      languageCode,
    ).format(dateTime.toLocal());
  }

  String _displayCurrencyCode([String? apiCurrencyCode]) {
    return resolveCurrencyCode([
      apiCurrencyCode,
      _savedCurrencyCode,
    ]).toUpperCase();
  }

  String _formatMoneyWithCurrency(double amount, [String? apiCurrencyCode]) {
    return formatMoneyForDisplay(
      context,
      amount,
      _displayCurrencyCode(apiCurrencyCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          CustomJoinUsSliverAppBar(
            title: isArabic ? 'إحصائيات الكوبون' : 'Coupon Statistics',
          ),
          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _CouponSummaryCard(
                coupon: widget.coupon,
                formatMoneyWithCurrency: _formatMoneyWithCurrency,
                createdAtText: widget.coupon.createdAt != null
                    ? _formatDate(widget.coupon.createdAt!, languageCode)
                    : '',
                expiresAtText: widget.coupon.expiresAt != null
                    ? _formatDate(widget.coupon.expiresAt!, languageCode)
                    : '',
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: FutureBuilder<List<CouponOrderStat>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? const <CouponOrderStat>[];
                  final totals = _CouponTotals.fromOrders(
                    orders,
                    widget.coupon,
                  );

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.borderGray),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DashboardStatItem(
                            label: isArabic ? 'الطلبات' : 'Orders',
                            value: totals.totalOrders.toString().padLeft(
                              2,
                              '0',
                            ),
                          ),
                        ),
                        Expanded(
                          child: _DashboardStatItem(
                            label: isArabic ? 'المبيعات' : 'Sales',
                            value: _formatMoneyWithCurrency(
                              totals.totalSales,
                              totals.currencyCode,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _DashboardStatItem(
                            label: isArabic ? 'العمولة' : 'Commission',
                            value: _formatMoneyWithCurrency(
                              totals.totalCommission,
                              totals.currencyCode,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                isArabic ? 'الطلبات' : 'Orders',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 20.sp,
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: FutureBuilder<List<CouponOrderStat>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final orders = snapshot.data ?? const <CouponOrderStat>[];
                if (orders.isEmpty) {
                  return const SliverToBoxAdapter(child: _EmptyOrdersCard());
                }

                return SliverList.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: _OrderCard(
                        order: orders[index],
                        formatMoneyWithCurrency: _formatMoneyWithCurrency,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 30.h)),
        ],
      ),
    );
  }
}

class _CouponSummaryCard extends StatelessWidget {
  const _CouponSummaryCard({
    required this.coupon,
    required this.createdAtText,
    required this.expiresAtText,
    required this.formatMoneyWithCurrency,
  });

  final GetCouponsModel coupon;
  final String createdAtText;
  final String expiresAtText;
  final String Function(double, [String?]) formatMoneyWithCurrency;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            coupon.code,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 16.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w500,
              height: 24 / 16,
            ),
          ),
          if (createdAtText.trim().isNotEmpty ||
              expiresAtText.trim().isNotEmpty) ...[
            SizedBox(height: 12.h),
            if (createdAtText.trim().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isArabic ? 'تاريخ الإنشاء: ' : 'Created: ',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 12.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w600,
                        height: 18 / 12,
                      ),
                    ),
                    TextSpan(
                      text: createdAtText,
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 12.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            if (createdAtText.trim().isNotEmpty &&
                expiresAtText.trim().isNotEmpty)
              SizedBox(height: 4.h),
            if (expiresAtText.trim().isNotEmpty)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: isArabic ? 'تاريخ الانتهاء: ' : 'Expires: ',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 12.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w600,
                        height: 18 / 12,
                      ),
                    ),
                    TextSpan(
                      text: expiresAtText,
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 12.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 16.h),
          ] else
            SizedBox(height: 8.h),
          Row(
            children: [
              Flexible(
                flex: 2,
                child: _CouponTag(
                  label: coupon.isActive
                      ? (isArabic ? 'نشط' : 'Active')
                      : (isArabic ? 'منتهي' : 'Expired'),
                  backgroundColor: coupon.isActive
                      ? const Color(0xFFE3FFD5)
                      : const Color(0xFFFFE1E1),
                  textColor: coupon.isActive
                      ? const Color(0xFF467E2E)
                      : const Color(0xFFB92123),
                ),
              ),
              SizedBox(width: 12.w),
              Flexible(
                flex: 3,
                child: _CouponTag(
                  label:
                      '${isArabic ? 'الخصم' : 'Discount'} ${formatLocalizedPercent(context, coupon.discountPercentage, fractionDigits: 2)}',
                  backgroundColor: const Color(0xFFE3FFD5),
                  textColor: const Color(0xFF467E2E),
                ),
              ),
              SizedBox(width: 12.w),
              Flexible(
                flex: 4,
                child: _CouponTag(
                  label:
                      '${isArabic ? 'العمولة' : 'Commission'} ${formatMoneyWithCurrency(coupon.totalCommissionAmount, coupon.totalCommissionCurrencyCode)}',
                  backgroundColor: const Color(0xFFE3FFD5),
                  textColor: const Color(0xFF467E2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.formatMoneyWithCurrency,
  });

  final CouponOrderStat order;
  final String Function(double, [String?]) formatMoneyWithCurrency;

  Color _statusColor(String status) {
    if (status.contains('pending')) return const Color(0xFFCC8A00);
    if (status.contains('cancel')) return const Color(0xFFB92123);
    if (status.contains('complete') || status.contains('paid')) {
      return const Color(0xFF467E2E);
    }
    return AppColors.black;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final status = order.status.replaceAll('_', ' ');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${isArabic ? 'طلب رقم' : 'Order #'}${order.uuid.length > 8 ? order.uuid.substring(0, 8) : order.uuid}',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 16.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w600,
                    height: 24 / 16,
                  ),
                ),
              ),
              Text(
                toBeginningOfSentenceCase(status) ?? status,
                style: TextStyle(
                  color: _statusColor(status),
                  fontSize: 12.sp,
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DashboardStatItem(
                  label: isArabic ? 'الإجمالي' : 'Total',
                  value: formatMoneyWithCurrency(
                    order.totalAmount,
                    order.totalCurrencyCode,
                  ),
                ),
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: _DashboardStatItem(
                  label: isArabic ? 'العمولة' : 'Commission',
                  value: formatMoneyWithCurrency(
                    order.commissionAmount,
                    order.commissionCurrencyCode,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            DateFormat(
              'MMM dd, yyyy hh:mm a',
            ).format(order.createdAt.toLocal()),
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 12.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrdersCard extends StatelessWidget {
  const _EmptyOrdersCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 122.h),
      padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 18.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Center(
        child: Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'لا توجد طلبات لهذا الكوبون حتى الآن.'
              : 'No orders for this coupon yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.black,
            fontSize: 16.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            height: 24 / 16,
          ),
        ),
      ),
    );
  }
}

class _DashboardStatItem extends StatelessWidget {
  const _DashboardStatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.black,
            fontSize: 12.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            height: 18 / 12,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.black,
            fontSize: 16.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w600,
            height: 24 / 16,
          ),
        ),
      ],
    );
  }
}

class _CouponTag extends StatelessWidget {
  const _CouponTag({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppStyle.styleFilterChip12Medium(
          context,
        ).copyWith(color: textColor, height: 1, letterSpacing: -0.19),
      ),
    );
  }
}

class _CouponTotals {
  const _CouponTotals({
    required this.totalOrders,
    required this.totalSales,
    required this.totalCommission,
    required this.currencyCode,
  });

  final int totalOrders;
  final double totalSales;
  final double totalCommission;
  final String? currencyCode;

  factory _CouponTotals.fromOrders(
    List<CouponOrderStat> orders,
    GetCouponsModel coupon,
  ) {
    double totalSales = 0;
    double totalCommission = 0;
    String? firstCurrency;

    for (final order in orders) {
      totalSales += order.totalAmount;
      totalCommission += order.commissionAmount;
      firstCurrency ??= order.totalCurrencyCode ?? order.commissionCurrencyCode;
    }

    return _CouponTotals(
      totalOrders: orders.isNotEmpty ? orders.length : coupon.ordersCount,
      totalSales: totalSales > 0 ? totalSales : coupon.totalSalesAmount,
      totalCommission: totalCommission > 0
          ? totalCommission
          : coupon.totalCommissionAmount,
      currencyCode:
          firstCurrency ??
          coupon.totalSalesCurrencyCode ??
          coupon.totalCommissionCurrencyCode,
    );
  }
}
