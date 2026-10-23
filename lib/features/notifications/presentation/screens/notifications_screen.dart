import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'package:camion/core/services/auth_session_notifier.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/connectivity_error_utils.dart';
import 'package:camion/features/notifications/data/models/notification_model.dart';
import 'package:camion/features/notifications/presentation/logic/cubit/notifications_cubit.dart';
import 'package:camion/features/searching/presentation/widgets/recent_search_sheet.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _refreshNotifications() async {
    await context.read<NotificationsCubit>().getNotifications();
  }

  void _handleAuthChanged() {
    if (!mounted || !sl<AuthSessionNotifier>().isLoggedIn) return;
    context.read<NotificationsCubit>().getNotifications();
  }

  @override
  void initState() {
    super.initState();
    sl<AuthSessionNotifier>().addListener(_handleAuthChanged);
    context.read<NotificationsCubit>().getNotifications();
  }

  @override
  void dispose() {
    sl<AuthSessionNotifier>().removeListener(_handleAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              AppTapFeedback(
                                onTap: () => context.pop(),
                                customBorder: const CircleBorder(),
                                child: SizedBox(
                                  width: 40.w,
                                  height: 40.h,
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.black,
                                    size: 30.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  S.of(context).notifications,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Montes',
                                    height: 40 / 20,
                                  ),
                                ),
                              ),
                              _HeaderIconButton(
                                onTap: () => openRecentSearchSheet(context),
                                child: Image.asset(
                                  'assets/images/searchicon.png',
                                  width: 40.w,
                                  height: 40.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(width: 18.w),
                              _HeaderIconButton(
                                onTap: () {},
                                child: Image.asset(
                                  Assets.imagesNotificationNew,
                                  width: 40.w,
                                  height: 40.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 28.h),
                        ],
                      ),
                    ),
                  ),
                  ..._buildBody(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, NotificationsState state) {
    if (state is NotificationsLoadingState) {
      return [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList.separated(
            itemCount: 4,
            itemBuilder: (context, index) =>
                _NotificationCardSkeleton(isHighlighted: index == 0),
            separatorBuilder: (_, __) => SizedBox(height: 16.h),
          ),
        ),
      ];
    }

    if (state is NotificationsLoadedState) {
      if (state.notifications.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                Localizations.localeOf(context).languageCode.toLowerCase() ==
                        'ar'
                    ? 'لا توجد بيانات'
                    : 'No data found',
                style: TextStyle(
                  color: const Color(0xFF888888),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Montes',
                ),
              ),
            ),
          ),
        ];
      }

      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
          sliver: SliverList.separated(
            itemCount: state.notifications.length,
            itemBuilder: (context, index) => _NotificationCard(
              notification: state.notifications[index],
              isHighlighted: index == 0,
            ),
            separatorBuilder: (_, __) => SizedBox(height: 16.h),
          ),
        ),
      ];
    }

    if (state is NotificationsErrorState) {
      if (isConnectivityErrorStatus(state.error.statusCode)) {
        return const [SliverToBoxAdapter(child: SizedBox.shrink())];
      }

      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(state.error.icon, color: Colors.red, size: 50.sp),
                  SizedBox(height: 16.h),
                  Text(
                    state.error.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.red,
                      fontFamily: 'Montes',
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<NotificationsCubit>().getNotifications(),
                    child: Text(S.of(context).retry),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return const [SliverToBoxAdapter(child: SizedBox.shrink())];
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.8,
      child: SizedBox(
        width: 40.w,
        height: 40.h,
        child: AppTapFeedback(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: child,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isHighlighted,
  });

  final NotificationModel notification;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final cardColor = isHighlighted
        ? const Color(0xFFFCE0E2)
        : const Color(0xFFF6F7FB);

    return AppTapFeedback(
      onTap: () => _handleNotificationTap(context),
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: 343.w,
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 14.w, 14.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Image.asset(
                Assets.imagesNotificationCard,
                width: 30.w,
                height: 30.h,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NotificationRichTitle(title: notification.title),
                  SizedBox(height: 10.h),
                  Text(
                    notification.body,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: const Color(0xFF212121),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Montes',
                      height: 1.5,
                      letterSpacing: -0.1,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    _relativeTime(context, notification.createdAt),
                    style: TextStyle(
                      color: const Color(0xFFC4C4C4),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Montes',
                      height: 1.5,
                      letterSpacing: -0.1,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(BuildContext context) {
    final payload = notification.data;
    if (payload is! Map) return;

    final type = notification.type?.trim().toUpperCase();

    if (type == 'ORDER_SHIPPED' || type == 'ORDER_DISPATCHED') {
      final orderId = payload['orderId']?.toString().trim() ?? '';
      if (orderId.isEmpty) return;

      context.push(
        AppRouter.orderTrackingWebPage,
        extra: {
          'orderId': orderId,
          if ((payload['orderNumber']?.toString().trim() ?? '').isNotEmpty)
            'orderNumber': payload['orderNumber']?.toString().trim(),
        },
      );
      return;
    }

    if (type == 'PRICE_DROP') {
      final productSlug = payload['productSlug']?.toString().trim() ?? '';
      if (productSlug.isEmpty) return;

      context.push(AppRouter.productDetails, extra: {'slug': productSlug});
    }
  }

  String _relativeTime(BuildContext context, DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt.toLocal());
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isArabic = locale.toLowerCase().startsWith('ar');

    if (difference.inMinutes < 1) {
      return isArabic ? 'الآن' : 'Just now';
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      if (isArabic) {
        if (minutes == 1) return 'منذ دقيقة واحدة';
        if (minutes == 2) return 'منذ دقيقتين';
        return 'منذ ${_formatArabicNumber(minutes)} ${_arabicMinuteUnit(minutes)}';
      }
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      if (isArabic) {
        if (hours == 1) return 'منذ ساعة واحدة';
        if (hours == 2) return 'منذ ساعتين';
        return 'منذ ${_formatArabicNumber(hours)} ${_arabicHourUnit(hours)}';
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
    final languageCode = Localizations.localeOf(context).languageCode;
    final pattern = isArabic ? 'd MMMM y، h:mm a' : 'MMMM dd, yyyy hh:mm a';
    return DateFormat(pattern, languageCode).format(createdAt.toLocal());
  }

  String _formatArabicNumber(int value) {
    return NumberFormat.decimalPattern('ar').format(value);
  }

  String _arabicMinuteUnit(int value) {
    if (value >= 3 && value <= 10) return 'دقائق';
    return 'دقيقة';
  }

  String _arabicHourUnit(int value) {
    if (value >= 3 && value <= 10) return 'ساعات';
    return 'ساعة';
  }
}

class _NotificationRichTitle extends StatelessWidget {
  const _NotificationRichTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final quotedMatch = RegExp(r'\"([^\"]+)\"').firstMatch(title);
    if (quotedMatch == null) {
      return Text(
        title,
        textAlign: TextAlign.justify,
        style: TextStyle(
          color: const Color(0xFF212121),
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          fontFamily: 'Montes',
          height: 1.5,
          letterSpacing: -0.1,
        ),
      );
    }

    final start = quotedMatch.start;
    final end = quotedMatch.end;

    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: const Color(0xFF212121),
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          fontFamily: 'Montes',
          height: 1.5,
          letterSpacing: -0.1,
        ),
        children: [
          if (start > 0) TextSpan(text: title.substring(0, start)),
          TextSpan(
            text: title.substring(start, end),
            style: const TextStyle(color: Color(0xFFD9252A)),
          ),
          if (end < title.length) TextSpan(text: title.substring(end)),
        ],
      ),
      textAlign: TextAlign.justify,
    );
  }
}

class _NotificationCardSkeleton extends StatelessWidget {
  const _NotificationCardSkeleton({required this.isHighlighted});

  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final cardColor = isHighlighted
        ? const Color(0xFFFCE0E2)
        : const Color(0xFFF6F7FB);

    return Container(
      width: 343.w,
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30.w,
            height: 30.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 210.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 220.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  width: 110.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
