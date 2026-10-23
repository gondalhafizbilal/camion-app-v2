import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/number_format_utils.dart';
import 'package:camion/features/join_us/data/models/coupons_model/get_coupons_model.dart';
import 'package:camion/features/join_us/presentation/logic/cubit/get_coupons_cubit/get_coupons_cubit.dart';
import 'package:camion/features/join_us/presentation/widgets/coupons_list_view_skeltonizer.dart';
import 'package:camion/features/join_us/presentation/widgets/custom__join_us_sliver_app_bar.dart';
import 'package:camion/features/join_us/presentation/widgets/custom_coupon.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import 'package:camion/routing/app_router.dart';

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    context.read<GetCouponsCubit>().getCouponCodeByAffiliateId();
    super.initState();
  }

  bool _isCouponActiveByDate(GetCouponsModel coupon) {
    final expiresAt = coupon.expiresAt;
    if (expiresAt == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
    return !expiryDate.isBefore(today);
  }

  List<GetCouponsModel> _filterCoupons(List<GetCouponsModel> coupons) {
    switch (_selectedFilterIndex) {
      case 1:
        return coupons.where(_isCouponActiveByDate).toList();
      case 2:
        return coupons
            .where((coupon) => !_isCouponActiveByDate(coupon))
            .toList();
      default:
        return coupons;
    }
  }

  String _formatCouponDate(DateTime dateTime) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return DateFormat('MMMM dd, yyyy hh:mm a', languageCode).format(dateTime);
  }

  String _formatCommissionText(GetCouponsModel coupon) {
    return formatMoneyForDisplay(
      context,
      coupon.totalCommissionAmount,
      resolveCurrencyCode([coupon.totalCommissionCurrencyCode]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          CustomJoinUsSliverAppBar(title: S.of(context).my_coupuns),
          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          BlocBuilder<GetCouponsCubit, GetCouponsState>(
            builder: (context, state) {
              if (state is GetCouponsLoading) {
                return SliverList.builder(
                  itemCount: 6,
                  itemBuilder: (context, index) => const Skeletonizer(
                    enabled: true,
                    child: CouponsListViewSkeletonizer(),
                  ),
                );
              }

              if (state is GetCouponsSuccess) {
                final activeCoupons = state.coupons
                    .where(_isCouponActiveByDate)
                    .length;
                final expiredCoupons = state.coupons.length - activeCoupons;
                final filteredCoupons = _filterCoupons(state.coupons);

                return SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: _CouponSummaryTile(
                              count: activeCoupons,
                              label:
                                  Localizations.localeOf(
                                        context,
                                      ).languageCode ==
                                      'ar'
                                  ? 'نشط'
                                  : 'Active',
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: _CouponSummaryTile(
                              count: expiredCoupons,
                              label:
                                  Localizations.localeOf(
                                        context,
                                      ).languageCode ==
                                      'ar'
                                  ? 'منتهي'
                                  : 'Expired',
                            ),
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
                        itemCount: _couponFilters(context).length,
                        separatorBuilder: (_, __) => SizedBox(width: 10.w),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilterIndex = index;
                              });
                            },
                            child: _CouponFilterChip(
                              label: _couponFilters(context)[index],
                              isActive: _selectedFilterIndex == index,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 18.h),
                    if (filteredCoupons.isEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 80.h),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                size: 52.sp,
                                color: Colors.grey.shade500,
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'لا توجد كوبونات'
                                    : 'No coupons found',
                                style: AppStyle.styleRegular18(context)
                                    .copyWith(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(filteredCoupons.length, (index) {
                        final coupon = filteredCoupons[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          // Show date only when both createdAt and expiresAt exist.
                          // Filter status always follows expiresAt date.
                          child: CustomCoupon(
                            couponCode: coupon.code,
                            discountPercentage: formatTwoDecimals(
                              coupon.discountPercentage,
                            ),
                            commissionText: _formatCommissionText(coupon),
                            createdAtText: coupon.createdAt != null
                                ? _formatCouponDate(coupon.createdAt!)
                                : null,
                            expiresAtText: coupon.expiresAt != null
                                ? _formatCouponDate(coupon.expiresAt!)
                                : null,
                            isActive: _isCouponActiveByDate(coupon),
                            onTap: () => context.push(
                              AppRouter.couponStats,
                              extra: coupon,
                            ),
                          ),
                        );
                      }),
                    SizedBox(height: 30.h),
                  ]),
                );
              }

              if (state is GetCouponsError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 80.h),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 48.sp,
                            color: Colors.grey.shade700,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            state.error.message,
                            textAlign: TextAlign.center,
                            style: AppStyle.styleRegular14(
                              context,
                            ).copyWith(color: Colors.grey.shade700),
                          ),
                          SizedBox(height: 14.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: CustomElevatedButton(
                              onPressed: () {
                                context
                                    .read<GetCouponsCubit>()
                                    .getCouponCodeByAffiliateId();
                              },
                              backgroundColor: AppColors.primaryColor,
                              child: Text(
                                S.of(context).retry,
                                style: AppStyle.styleRegular16(
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

              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
    );
  }
}

List<String> _couponFilters(BuildContext context) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return [
    isArabic ? 'كل الكوبونات' : 'All Coupons',
    isArabic ? 'الكوبونات النشطة' : 'Active Coupons',
    isArabic ? 'الكوبونات المنتهية' : 'Expired Coupons',
  ];
}

class _CouponSummaryTile extends StatelessWidget {
  const _CouponSummaryTile({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              count.toString(),
              style: AppStyle.styleSectionTitle16Medium(context).copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppStyle.styleSectionTitle16Medium(context).copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponFilterChip extends StatelessWidget {
  const _CouponFilterChip({required this.label, required this.isActive});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 116.w),
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
