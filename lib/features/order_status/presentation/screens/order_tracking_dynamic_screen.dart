import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
import 'package:camion/core/api/local_status_codes.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/features/order_status/data/models/tracking_order_model/tracking_order_model_response_model.dart';
import 'package:camion/features/order_status/presentation/logic/cubit/get_orders_cubit/get_orders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class OrderTrackingDynamicScreen extends StatelessWidget {
  const OrderTrackingDynamicScreen({
    super.key,
    required this.orderId,
    this.orderNumber,
    this.productTitle,
    this.productImage,
    this.productId,
  });

  final String orderId;
  final String? orderNumber;
  final String? productTitle;
  final String? productImage;
  final String? productId;

  bool _isConnectivityErrorStatus(int? statusCode) {
    return statusCode == LocalStatusCodes.connectionError ||
        statusCode == LocalStatusCodes.connectionTimeout ||
        statusCode == LocalStatusCodes.sendTimeout ||
        statusCode == LocalStatusCodes.receiveTimeout;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            appBarHeight: 50.h,
            centerTitle: false,
            isShownDivider: false,
            isShownActions: false,
            title: Text(
              isArabic ? 'تتبع الطلب' : 'Track Order',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 20.sp,
                fontFamily: 'Montes',
                fontWeight: FontWeight.w500,
                height: 2,
              ),
            ),
          ),
          BlocBuilder<GetOrdersCubit, GetOrdersState>(
            builder: (context, state) {
              if (state is GetOrdersInitial || state is OrderTrackingLoading) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                );
              }

              if (state is OrderTrackingError) {
                final connectivityIssue = _isConnectivityErrorStatus(
                  state.error.statusCode,
                );
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _TrackingErrorView(
                    title: connectivityIssue
                        ? (isArabic ? 'مشكلة في الاتصال' : 'Connection issue')
                        : (isArabic
                              ? 'تعذر تحميل التتبع'
                              : 'Unable to load tracking'),
                    message: connectivityIssue
                        ? (isArabic
                              ? 'يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.'
                              : 'Please check your internet connection and try again.')
                        : state.error.message,
                    onRetry: () => context
                        .read<GetOrdersCubit>()
                        .getOrderTracking(orderId: orderId),
                  ),
                );
              }

              if (state is! OrderTrackingSuccess) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              final trackingData = state.trackingResponse.data;
              final stages = trackingData.trackingStages;
              final completedCount = stages
                  .where((stage) => stage.checked)
                  .length;
              final trackingId = _extractTrackingId(stages);

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HeaderCard(
                      isArabic: isArabic,
                      orderId: orderId,
                      orderNumber: orderNumber,
                      completedCount: completedCount,
                      totalCount: stages.length,
                    ),
                    SizedBox(height: 16.h),
                    if (trackingId != null) ...[
                      _TrackingIdCard(
                        trackingId: trackingId,
                        isArabic: isArabic,
                      ),
                      SizedBox(height: 16.h),
                    ],
                    ...List.generate(stages.length, (index) {
                      final stage = stages[index];
                      return _TimelineStageTile(
                        stage: stage,
                        isLast: index == stages.length - 1,
                        isArabic: isArabic,
                        icon: _iconForStage(stage.id),
                      );
                    }),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String? _extractTrackingId(List<TrackingStage> stages) {
    for (final stage in stages) {
      final trackingId = stage.metadata.trackingId?.trim() ?? '';
      if (trackingId.isNotEmpty) return trackingId;
    }
    return null;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isArabic,
    required this.orderId,
    required this.orderNumber,
    required this.completedCount,
    required this.totalCount,
  });

  final bool isArabic;
  final String orderId;
  final String? orderNumber;
  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFFD1D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'رحلة الطلب' : 'Order journey',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 18.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            isArabic
                ? 'تم إكمال $completedCount من $totalCount مراحل التتبع.'
                : '$completedCount of $totalCount tracking stages completed.',
            style: TextStyle(
              color: AppColors.softGray,
              fontSize: 13.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            isArabic ? 'رقم الطلب' : 'Order ID',
            style: TextStyle(
              color: AppColors.softGray,
              fontSize: 12.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            orderNumber?.trim().isNotEmpty == true ? orderNumber! : orderId,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 14.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingIdCard extends StatelessWidget {
  const _TrackingIdCard({required this.trackingId, required this.isArabic});

  final String trackingId;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFDFDFDF)),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: const BoxDecoration(
              color: Color(0xFFCB262E),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'رقم التتبع' : 'Tracking ID',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 13.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                SelectableText(
                  trackingId,
                  style: TextStyle(
                    color: const Color(0xFFCB262E),
                    fontSize: 14.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: trackingId));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isArabic ? 'تم نسخ رقم التتبع' : 'Tracking ID copied',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 18),
            label: Text(isArabic ? 'نسخ' : 'Copy'),
          ),
        ],
      ),
    );
  }
}

class _TimelineStageTile extends StatelessWidget {
  const _TimelineStageTile({
    required this.stage,
    required this.isLast,
    required this.isArabic,
    required this.icon,
  });

  final TrackingStage stage;
  final bool isLast;
  final bool isArabic;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final done = stage.checked;
    final activeColor = const Color(0xFFCB262E);
    final disabledColor = const Color(0xFFA9A9A9);
    final textColor = done ? AppColors.black : disabledColor;
    final lineColor = done ? activeColor : const Color(0xFFE5E5E5);
    final dateLabel = _formatDate(
      stage.date,
      Localizations.localeOf(context).languageCode,
    );
    final hasTrackingId = stage.metadata.trackingId?.trim().isNotEmpty == true;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52.w,
            child: Column(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: done ? activeColor : const Color(0xFFF3F3F3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: done ? activeColor : const Color(0xFFDFDFDF),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20.sp,
                    color: done ? Colors.white : disabledColor,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2.w,
                    height: hasTrackingId ? 78.h : 64.h,
                    color: lineColor,
                  ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.name.isNotEmpty ? stage.name : 'Stage ${stage.id}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15.sp,
                      fontFamily: 'Montes',
                      fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    done
                        ? (isArabic ? 'مكتمل' : 'Completed')
                        : (isArabic ? 'غير متاح بعد' : 'Disabled'),
                    style: TextStyle(
                      color: done ? activeColor : disabledColor,
                      fontSize: 12.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (dateLabel != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        color: done ? activeColor : disabledColor,
                        fontSize: 11.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                  if (hasTrackingId) ...[
                    SizedBox(height: 8.h),
                    _InlineTrackingId(
                      trackingId: stage.metadata.trackingId!.trim(),
                      isArabic: isArabic,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineTrackingId extends StatelessWidget {
  const _InlineTrackingId({required this.trackingId, required this.isArabic});

  final String trackingId;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F6),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFFFD1D3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${isArabic ? 'رقم التتبع' : 'Tracking ID'}: $trackingId',
              style: TextStyle(
                color: const Color(0xFFCB262E),
                fontSize: 12.sp,
                fontFamily: 'Montes',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: trackingId));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isArabic ? 'تم نسخ رقم التتبع' : 'Tracking ID copied',
                  ),
                ),
              );
            },
            child: Icon(
              Icons.copy_rounded,
              size: 16.sp,
              color: const Color(0xFFCB262E),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingErrorView extends StatelessWidget {
  const _TrackingErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.black,
              fontSize: 16.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.softGray,
              fontSize: 12.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          SizedBox(height: 18.h),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'إعادة المحاولة'
                  : 'Retry',
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForStage(int stageId) {
  switch (stageId) {
    case 1:
      return Icons.receipt_long_outlined;
    case 2:
      return Icons.payments_outlined;
    case 3:
      return Icons.verified_outlined;
    case 4:
      return Icons.settings_outlined;
    case 5:
      return Icons.inventory_2_outlined;
    case 6:
      return Icons.local_shipping_outlined;
    case 7:
      return Icons.done_all_outlined;
    case 8:
      return Icons.rate_review_outlined;
    case 9:
      return Icons.cancel_outlined;
    default:
      return Icons.timelapse_outlined;
  }
}

String? _formatDate(DateTime? date, String localeCode) {
  if (date == null) return null;
  return DateFormat('MMM d, yyyy • hh:mm a', localeCode).format(date);
}
