import 'dart:async';

import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
import 'package:camion/core/api/local_status_codes.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/features/home/presentation/logic/cubit/create_review_cubit/create_review_cubit.dart';
import 'package:camion/features/order_status/data/models/tracking_order_model/tracking_order_model_response_model.dart';
import 'package:camion/features/order_status/presentation/logic/cubit/get_orders_cubit/get_orders_cubit.dart';
import 'package:camion/features/order_status/utils/order_status_utils.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class OrderTrackingWebView extends StatelessWidget {
  const OrderTrackingWebView({
    super.key,
    required this.orderId,
    this.orderNumber,
    this.productTitle,
    this.variantTitle,
    this.productImage,
    this.productId,
  });

  final String orderId;
  final String? orderNumber;
  final String? productTitle;
  final String? variantTitle;
  final String? productImage;
  final String? productId;

  static final Set<String> _trackedOrderStatusEvents = <String>{};

  bool _isConnectivityErrorStatus(int? statusCode) {
    return statusCode == LocalStatusCodes.connectionError ||
        statusCode == LocalStatusCodes.connectionTimeout ||
        statusCode == LocalStatusCodes.sendTimeout ||
        statusCode == LocalStatusCodes.receiveTimeout;
  }

  void _trackOrderStatusEvent(OrderData trackingData) {
    final normalized = trackingData.orderStatus
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    final eventName = switch (normalized) {
      'confirmed' || 'order_confirmed' => 'order_confirmed',
      'cancelled' || 'canceled' || 'order_cancelled' => 'order_cancelled',
      'return_requested' || 'refund_requested' => 'refund_requested',
      _ => '',
    };
    if (eventName.isEmpty) return;
    final key = '${trackingData.orderId}:$eventName';
    if (!_trackedOrderStatusEvents.add(key)) return;
    unawaited(
      sl<AppsFlyerService>().logConversionEvent(
        eventName,
        eventParams: {
          'order_id': trackingData.orderId == 0
              ? orderId.trim()
              : trackingData.orderId.toString(),
          'shipping_method': trackingData.shippingLines.isEmpty
              ? ''
              : trackingData.shippingLines.first.methodId,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            appBarHeight: 50.h,
            centerTitle: false,
            isShownDivider: false,
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
            isShownActions: false,
          ),
          BlocBuilder<GetOrdersCubit, GetOrdersState>(
            builder: (context, state) {
              if (state is OrderTrackingLoading || state is GetOrdersInitial) {
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
                if (_isConnectivityErrorStatus(state.error.statusCode)) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _TrackingErrorView(
                      title: isArabic ? 'مشكلة في الاتصال' : 'Connection issue',
                      message: isArabic
                          ? 'يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.'
                          : 'Please check your internet connection and try again.',
                      onRetry: () => context
                          .read<GetOrdersCubit>()
                          .getOrderTracking(orderId: orderId),
                    ),
                  );
                }
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _TrackingErrorView(
                    title: isArabic
                        ? 'تعذر تحميل التتبع'
                        : 'Unable to load tracking',
                    message: state.error.message,
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
              _trackOrderStatusEvent(trackingData);
              final timeline = _TrackingTimelineBuilder(
                trackingData,
                isArabic: isArabic,
              ).build();
              final currentIndex = timeline.indexWhere((step) => step.isActive);
              final activeIndex = currentIndex == -1 ? 0 : currentIndex;
              final activeStep = timeline.isEmpty
                  ? null
                  : timeline[activeIndex.clamp(0, timeline.length - 1)];

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 40.h),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      _headlineForStatus(
                        trackingData.orderStatus,
                        trackingData: trackingData,
                        isArabic: isArabic,
                      ),
                      style: TextStyle(
                        color: AppColors.deepDark,
                        fontSize: 16.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      _subtitleForStatus(
                        trackingData.orderStatus,
                        activeStep,
                        trackingData: trackingData,
                        isArabic: isArabic,
                      ),
                      style: TextStyle(
                        color: AppColors.softGray,
                        fontSize: 12.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    const Divider(color: Color(0xFFDDF2F4), height: 1),
                    SizedBox(height: 18.h),
                    _TrackingInfoRow(trackingData: trackingData),
                    SizedBox(height: 14.h),
                    _TrackingOrderDateRow(trackingData: trackingData),
                    _WaybillTrackingCard(trackingData: trackingData),
                    SizedBox(height: 22.h),
                    const Divider(color: Color(0xFFDDF2F4), height: 1),
                    SizedBox(height: 22.h),
                    if (timeline.isEmpty)
                      const _EmptyTrackingView()
                    else
                      ...List.generate(timeline.length, (index) {
                        final step = timeline[index];
                        final nextStep = index < timeline.length - 1
                            ? timeline[index + 1]
                            : null;
                        return _TrackingStepTile(
                          step: step,
                          isLast: index == timeline.length - 1,
                          lineColor:
                              step.isCompleted &&
                                  (nextStep?.isCompleted ?? false)
                              ? const Color(0xFFCB262E)
                              : const Color(0xFFFFD1D3),
                        );
                      }),
                    // Add spacing before buttons
                    SizedBox(height: 32.h),
                    // Bottom Action Buttons
                    _buildActionButtons(context, trackingData.orderStatus),
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Bottom Action Buttons Widget
  Widget _buildActionButtons(BuildContext context, String orderStatus) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final normalizedStatus = orderStatusFromRaw(orderStatus);
    final canRequestReturn = normalizedStatus == OrderStatus.delivered;
    final canTrackReturn =
        normalizedStatus == OrderStatus.returnRequested ||
        normalizedStatus == OrderStatus.returned;
    if (!canRequestReturn && !canTrackReturn) {
      return const SizedBox.shrink();
    }
    final actionLabel = canTrackReturn
        ? (isArabic ? 'تتبع الإرجاع' : 'Track Return')
        : (isArabic ? 'طلب إرجاع' : 'Request Return');
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: () {
          context.push(
            AppRouter.trackReturnOrderScreen,
            extra: {
              'orderId': orderId,
              'orderNumber': orderNumber ?? orderId,
              'productTitle':
                  productTitle ?? (isArabic ? 'عنصر الإرجاع' : 'Return item'),
              'productImage': productImage ?? '',
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFCB262E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          elevation: 0,
        ),
        child: Text(
          actionLabel,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _headlineForStatus(
    String orderStatus, {
    required OrderData trackingData,
    required bool isArabic,
  }) {
    final trackingStatus = trackingData.trackingStatus.trim();
    final stage = trackingData.trackingStage.trim().toLowerCase();
    if (_shouldShowTrackingStatus(trackingData) && trackingStatus.isNotEmpty) {
      if (stage == 'outbound') {
        return isArabic ? 'شحنتك في الطريق' : 'Your shipment is on the way';
      }
      if (stage == 'inbound') {
        return isArabic
            ? 'طلبك قيد التجهيز في المستودع'
            : 'Your order is being prepared';
      }
    }
    switch (orderStatusFromRaw(orderStatus)) {
      case OrderStatus.delivered:
        return isArabic ? 'تم تسليم شحنتك' : 'Your parcel has been delivered';
      case OrderStatus.returnRequested:
        return isArabic
            ? 'طلب الإرجاع قيد المراجعة'
            : 'Your return request is under review';
      case OrderStatus.returned:
        return isArabic
            ? 'تمت معالجة طلب الإرجاع'
            : 'Your returned order has been processed';
      case OrderStatus.cancelled:
        return isArabic ? 'تم إلغاء طلبك' : 'Your order has been cancelled';
      case OrderStatus.paymentRejected:
        return isArabic ? 'تم رفض عملية الدفع' : 'Your payment was rejected';
      case OrderStatus.confirmed:
      case OrderStatus.paymentSuccessful:
      case OrderStatus.dispatched:
        return isArabic ? 'تم تأكيد طلبك' : 'Your order has been confirmed';
      case OrderStatus.pending:
      case OrderStatus.paymentPending:
      case OrderStatus.unknown:
        return isArabic ? 'جارٍ معالجة طلبك' : 'Your order is being processed';
    }
  }

  String _subtitleForStatus(
    String orderStatus,
    _TrackingStepData? activeStep, {
    required OrderData trackingData,
    required bool isArabic,
  }) {
    final trackingStatus = trackingData.trackingStatus.trim();
    if (_shouldShowTrackingStatus(trackingData) && trackingStatus.isNotEmpty) {
      final statusLabel = _trackingStatusLabel(
        trackingStatus,
        isArabic: isArabic,
      );
      final waybill = trackingData.waybillNo.trim();
      if (waybill.isNotEmpty) {
        return isArabic
            ? '$statusLabel • رقم التتبع $waybill'
            : '$statusLabel • Tracking number $waybill';
      }
      return statusLabel;
    }
    if (activeStep != null && activeStep.metaLine.isNotEmpty) {
      return activeStep.metaLine;
    }
    switch (orderStatusFromRaw(orderStatus)) {
      case OrderStatus.delivered:
        return isArabic
            ? 'وصل طلبك إلى الوجهة بنجاح.'
            : 'Your order has reached the destination successfully.';
      case OrderStatus.returnRequested:
        return isArabic
            ? 'استلمنا طلب الإرجاع وهو بانتظار المراجعة.'
            : 'We received your return request and it is awaiting review.';
      case OrderStatus.returned:
        return isArabic
            ? 'تمت الموافقة على الإرجاع وجارٍ معالجة الاسترداد.'
            : 'The return has been approved and the refund is being processed.';
      case OrderStatus.cancelled:
        return isArabic
            ? 'تم إلغاء هذا الطلب ولن يتم شحنه.'
            : 'This order was cancelled and will not be shipped.';
      case OrderStatus.paymentRejected:
        return isArabic
            ? 'فشلت عملية الدفع. يرجى إعادة الطلب.'
            : 'Payment failed. Please place the order again.';
      case OrderStatus.confirmed:
      case OrderStatus.paymentSuccessful:
      case OrderStatus.dispatched:
        return isArabic
            ? 'تم تأكيد طلبك وهو جاهز للشحن.'
            : 'Your order is confirmed and ready for dispatch.';
      case OrderStatus.pending:
      case OrderStatus.paymentPending:
      case OrderStatus.unknown:
        return isArabic
            ? 'نحن نحضّر طلبك للشحن.'
            : 'We are preparing your order for dispatch.';
    }
  }
}

String _trackingStatusLabel(String raw, {required bool isArabic}) {
  final normalized = raw.trim();
  if (normalized.isEmpty || !isArabic) return normalized;

  switch (normalized.toLowerCase()) {
    case 'order confirmed':
      return 'تم تأكيد الطلب';
    case 'procurement in progress':
      return 'جاري تجهيز المنتجات';
    case 'goods being sourced':
      return 'جاري توفير المنتجات';
    case 'goods arrived at warehouse':
      return 'وصلت المنتجات إلى المستودع';
    case 'goods being processed':
      return 'جاري معالجة المنتجات';
    case 'ready to ship':
      return 'جاهز للشحن';
    case 'processing complete':
      return 'اكتملت المعالجة';
    case 'order issue — contact support':
    case 'order issue - contact support':
      return 'مشكلة في الطلب - يرجى التواصل مع الدعم';
    case 'preparing your shipment':
      return 'جاري تجهيز الشحنة';
    case 'shipment in progress':
      return 'الشحنة قيد النقل';
    case 'shipment delayed':
      return 'تأخر الشحنة';
    case 'shipment ready':
      return 'الشحنة جاهزة';
    case 'shipped':
      return 'تم الشحن';
    case 'shipment cancelled':
      return 'تم إلغاء الشحنة';
    default:
      return normalized;
  }
}

bool _canUseFulfillmentTracking(OrderData data) {
  if (!data.hasFulfillmentTracking) return false;
  switch (orderStatusFromRaw(data.orderStatus)) {
    case OrderStatus.confirmed:
    case OrderStatus.dispatched:
    case OrderStatus.delivered:
    case OrderStatus.returnRequested:
    case OrderStatus.returned:
      return true;
    case OrderStatus.pending:
    case OrderStatus.paymentPending:
    case OrderStatus.paymentSuccessful:
    case OrderStatus.paymentRejected:
    case OrderStatus.cancelled:
    case OrderStatus.unknown:
      return false;
  }
}

bool _shouldShowTrackingStatus(OrderData data) {
  if (!_canUseFulfillmentTracking(data)) return false;
  final stage = data.trackingStage.trim().toLowerCase();
  return stage == 'inbound' || stage == 'outbound';
}

// ==================== REFUND REQUEST POPUP ====================

class RefundRequestPopup {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const RefundRequestDialog(),
    );
  }
}

class RefundRequestDialog extends StatelessWidget {
  const RefundRequestDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: 343.w,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shopping Bag Icon
            Container(
              width: 64.w,
              height: 64.w,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFCB262E),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/cart.png',
                color: Colors.white,
                width: 32.w,
                height: 32.h,
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(height: 16.h),

            // Title
            Text(
              isArabic
                  ? 'تفاصيل طلب الإرجاع والاسترداد'
                  : 'Return/Refund Request Details',
              style: TextStyle(
                fontFamily: 'Montes',
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
                height: 1.5,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 8.h),

            // Subtitle
            Text(
              isArabic
                  ? 'يرجى إخبارنا بسبب الإرجاع!'
                  : 'Please let us know the reason for return!',
              style: TextStyle(
                fontFamily: 'Montes',
                fontWeight: FontWeight.w400,
                fontSize: 10.sp,
                height: 1.8,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 12.h),

            // Policy Link
            GestureDetector(
              onTap: () {
                // Navigate to refund policy
              },
              child: Text(
                isArabic
                    ? 'عرض سياسة الاسترداد والإرجاع'
                    : 'View refund and return policy',
                style: TextStyle(
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                  height: 1.5,
                  color: const Color(0xFFCB262E),
                  decoration: TextDecoration.underline,
                  decorationColor: const Color(0xFFCB262E),
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 16.h),

            // Text Field
            Container(
              width: 295.w,
              height: 168.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: TextField(
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(fontFamily: 'Montes', fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: isArabic
                      ? 'أضف سبب الإرجاع هنا.'
                      : 'Add reason for return here.',
                  hintStyle: TextStyle(
                    fontFamily: 'Montes',
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none, // No border when unfocused
                  focusedBorder:
                      InputBorder.none, // No border when focused ← ADD THIS
                  enabledBorder:
                      InputBorder.none, // No border when enabled ← ADD THIS
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Select Photo / Media Button
            SizedBox(
              width: 295.w,
              height: 50.h,
              child: OutlinedButton(
                onPressed: () {
                  // Handle photo/video upload
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCB262E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),
                child: Text(
                  isArabic ? 'إضافة صور/فيديو' : 'Add Photos/Video',
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: const Color(0xFFCB262E),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Submit Request Button
            SizedBox(
              width: 295.w,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  // Handle submit
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCB262E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),
                child: Text(
                  isArabic ? 'إرسال الطلب' : 'Submit Request',
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
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

// ==================== RATING & REVIEW POPUP ====================

class RatingReviewPopup {
  static void show(
    BuildContext context, {
    String? productId,
    String? orderUuid,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          RatingReviewDialog(productId: productId, orderUuid: orderUuid),
    );
  }
}

class RatingReviewDialog extends StatefulWidget {
  const RatingReviewDialog({super.key, this.productId, this.orderUuid});

  final String? productId;
  final String? orderUuid;

  @override
  State<RatingReviewDialog> createState() => _RatingReviewDialogState();
}

class _RatingReviewDialogState extends State<RatingReviewDialog> {
  double _rating = 3.5;
  late final TextEditingController _reviewController;
  final ImagePicker _picker = ImagePicker();
  final List<String> _imagePaths = <String>[];
  String _inlineMessage = '';
  bool _inlineMessageIsError = false;
  bool _isPickingMedia = false;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _showInlineFeedback({required String message, required bool isError}) {
    if (!mounted) return;
    setState(() {
      _inlineMessage = message;
      _inlineMessageIsError = isError;
    });
  }

  Future<ImageSource?> _pickSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'التقاط صورة'
                      : 'Take Photo',
                ),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'اختيار من المعرض'
                      : 'Choose from Gallery',
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                title: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'إلغاء'
                      : 'Cancel',
                  textAlign: TextAlign.center,
                ),
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onAddMediaTap() async {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    if (_isPickingMedia) return;
    if (_imagePaths.length >= 5) {
      _showInlineFeedback(
        message: Localizations.localeOf(context).languageCode == 'ar'
            ? 'يمكنك إضافة 5 صور كحد أقصى.'
            : 'You can add up to 5 images only.',
        isError: true,
      );
      return;
    }

    try {
      setState(() {
        _isPickingMedia = true;
      });
      final source = await _pickSource();
      if (!mounted || source == null) return;
      final remainingSlots = 5 - _imagePaths.length;
      if (remainingSlots <= 0) return;

      if (source == ImageSource.gallery) {
        final picked = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (!mounted || picked.isEmpty) return;
        setState(() {
          for (final file in picked.take(remainingSlots)) {
            final path = file.path.trim();
            if (path.isNotEmpty) {
              _imagePaths.add(path);
            }
          }
        });
      } else {
        final captured = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (!mounted) return;
        final path = captured?.path.trim();
        if (path == null || path.isEmpty) return;
        setState(() {
          _imagePaths.add(path);
        });
      }
    } on PlatformException catch (_) {
      _showInlineFeedback(
        message: isArabic
            ? 'يرجى السماح بالوصول للكاميرا/الصور من إعدادات iOS.'
            : 'Please allow camera/photos access in iOS Settings.',
        isError: true,
      );
    } catch (_) {
      _showInlineFeedback(
        message: isArabic
            ? 'تعذر فتح اختيار الوسائط حالياً. يرجى المحاولة مرة أخرى.'
            : 'Unable to open media picker right now. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingMedia = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        width: 343.w,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shopping Bag Icon
            Container(
              width: 64.w,
              height: 64.w,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFCB262E),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/cart.png',
                color: Colors.white,
                width: 32.w,
                height: 32.h,
                fit: BoxFit.contain,
              ),
            ),

            SizedBox(height: 16.h),

            Text(
              isArabic ? 'كيف كانت تجربتك؟' : 'How was your experience?',
              style: TextStyle(
                fontFamily: 'Montes',
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
                height: 1.5,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 8.h),

            // Subtitle
            Text(
              isArabic
                  ? 'يرجى إخبارنا كيف يمكننا التحسين عبر إضافة ملاحظاتك القيّمة.'
                  : 'Please let us know how we can improve this by adding your valuable feedback.',
              style: TextStyle(
                fontFamily: 'Montes',
                fontWeight: FontWeight.w400,
                fontSize: 10.sp,
                height: 1.8,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 16.h),

            // Rating Display with Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w600,
                    fontSize: 20.sp,
                    color: Colors.black,
                  ),
                ),
                SizedBox(width: 12.w),
                // Star Rating
                Row(
                  children: List.generate(5, (index) {
                    final starValue = index + 1;
                    final isFilled = starValue <= _rating;
                    final isHalf = (starValue - 0.5) == _rating;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = starValue.toDouble();
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Icon(
                          isHalf
                              ? Icons.star_half
                              : isFilled
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFFFFB800),
                          size: 24.sp,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Text Field
            Container(
              width: 295.w,
              height: 84.h,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: TextField(
                controller: _reviewController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(fontFamily: 'Montes', fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: isArabic
                      ? 'أضف مراجعة المنتج هنا.'
                      : 'Add your product review here.',
                  hintStyle: TextStyle(
                    fontFamily: 'Montes',
                    fontSize: 14.sp,
                    color: Colors.grey,
                  ),
                  border: InputBorder.none, // No border when unfocused
                  focusedBorder:
                      InputBorder.none, // No border when focused ← ADD THIS
                  enabledBorder:
                      InputBorder.none, // No border when enabled ← ADD THIS
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            if (_imagePaths.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isArabic
                      ? 'تم اختيار ${_imagePaths.length} صورة'
                      : '${_imagePaths.length} image(s) selected',
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],

            if (_inlineMessage.trim().isNotEmpty) ...[
              SizedBox(height: 10.h),
              Container(
                width: 295.w,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: _inlineMessageIsError
                      ? const Color(0xFFFFEBEB)
                      : const Color(0xFFEAFBF0),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _inlineMessageIsError
                        ? const Color(0xFFE65A5A)
                        : const Color(0xFF4CAF7D),
                  ),
                ),
                child: Text(
                  _inlineMessage,
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontSize: 12.sp,
                    color: _inlineMessageIsError
                        ? const Color(0xFF9C2E2E)
                        : const Color(0xFF1E6D47),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            SizedBox(height: 12.h),

            // Select Photo Button
            SizedBox(
              width: 295.w,
              height: 50.h,
              child: OutlinedButton(
                onPressed: _isPickingMedia ? null : _onAddMediaTap,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCB262E)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ),
                child: Text(
                  _isPickingMedia
                      ? (isArabic ? 'جارٍ الاختيار...' : 'Selecting...')
                      : (_imagePaths.isEmpty
                            ? (isArabic ? 'اختيار صورة' : 'Select Photo')
                            : (isArabic
                                  ? 'إدارة الصور (${_imagePaths.length})'
                                  : 'Manage Photos (${_imagePaths.length})')),
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                    color: const Color(0xFFCB262E),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // Submit Feedback Button
            BlocConsumer<CreateReviewCubit, CreateReviewState>(
              listener: (context, state) {
                if (state is CreateReviewSuccess) {
                  unawaited(
                    sl<AppsFlyerService>().logConversionEvent(
                      'review_submitted',
                      eventParams: {
                        'product_id': (widget.productId ?? '').trim(),
                        'order_id': (widget.orderUuid ?? '').trim(),
                      },
                    ),
                  );
                  final review = state.review;
                  if (review != null) {
                    Navigator.of(context).pop(review);
                    return;
                  }
                  _showInlineFeedback(
                    message: isArabic
                        ? 'تم إرسال المراجعة بنجاح.'
                        : 'Review submitted successfully.',
                    isError: false,
                  );
                }
                if (state is CreateReviewError) {
                  _showInlineFeedback(
                    message: state.error.message,
                    isError: true,
                  );
                }
              },
              builder: (context, state) {
                return SizedBox(
                  width: 295.w,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: state is CreateReviewLoading
                        ? null
                        : () {
                            final productId = (widget.productId ?? '').trim();
                            final comment = _reviewController.text.trim();
                            if (productId.isEmpty) {
                              _showInlineFeedback(
                                message: isArabic
                                    ? 'المنتج غير متوفر لهذا الطلب. يرجى إضافة المراجعة من تفاصيل المنتج.'
                                    : 'Product is missing for this order. Please review from product details.',
                                isError: true,
                              );
                              return;
                            }
                            if (comment.isEmpty) {
                              _showInlineFeedback(
                                message: isArabic
                                    ? 'يرجى إضافة تعليق المراجعة'
                                    : 'Please add your review comment',
                                isError: true,
                              );
                              return;
                            }
                            context.read<CreateReviewCubit>().submitReview(
                              productId: productId,
                              comment: comment,
                              rating: _rating,
                              imagePaths: List<String>.from(_imagePaths),
                              orderUuid: widget.orderUuid?.trim(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCB262E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                    ),
                    child: state is CreateReviewLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isArabic ? 'إرسال الملاحظات' : 'Submit Feedback',
                            style: TextStyle(
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                            ),
                          ),
                  ),
                );
              },
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: 295.w,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'إغلاق'
                      : 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingInfoRow extends StatelessWidget {
  const _TrackingInfoRow({required this.trackingData});

  final OrderData trackingData;

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final helper = _TrackingMetaReader(trackingData, isArabic: isArabic);
    return Row(
      children: [
        Expanded(
          child: _TrackingInfoItem(
            iconPath: 'assets/images/delivery_type.png',
            title: isArabic ? 'نوع التوصيل' : 'Delivery Type',
            value: helper.deliveryType,
          ),
        ),
        Expanded(
          child: _TrackingInfoItem(
            iconPath: 'assets/images/estimate.png',
            title: isArabic ? 'الوقت المتوقع' : 'Estimate',
            value: helper.estimate,
          ),
        ),
        Expanded(
          child: _TrackingInfoItem(
            iconPath: 'assets/images/weight.png',
            title: isArabic ? 'الوزن' : 'Weight',
            value: helper.weight,
          ),
        ),
      ],
    );
  }
}

class _TrackingInfoItem extends StatelessWidget {
  const _TrackingInfoItem({
    required this.iconPath,
    required this.title,
    required this.value,
  });

  final String iconPath;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(iconPath, width: 72.w, height: 72.w, fit: BoxFit.contain),
        SizedBox(height: 10.h),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.deepDark,
            fontSize: 14.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.softGray,
            fontSize: 13.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _TrackingOrderDateRow extends StatelessWidget {
  const _TrackingOrderDateRow({required this.trackingData});

  final OrderData trackingData;

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final helper = _TrackingMetaReader(trackingData, isArabic: isArabic);
    final orderDate = helper.orderDate;
    if (orderDate == null) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context).languageCode;
    final formatted = DateFormat('MMMM dd, yyyy hh:mm a', locale)
        .format(orderDate.toLocal())
        .replaceAll('ص', 'صباحاً')
        .replaceAll('م', 'مساءً');

    return RichText(
      text: TextSpan(
        text: isArabic ? 'تاريخ الطلب: ' : 'Order Date: ',
        style: TextStyle(
          color: AppColors.deepDark,
          fontSize: 13.sp,
          fontFamily: 'Montes',
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: formatted,
            style: TextStyle(
              color: AppColors.softGray,
              fontSize: 13.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaybillTrackingCard extends StatelessWidget {
  const _WaybillTrackingCard({required this.trackingData});

  final OrderData trackingData;

  bool get _canShow {
    return _canUseFulfillmentTracking(trackingData) &&
        trackingData.waybillNo.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (!_canShow) return const SizedBox.shrink();

    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final waybill = trackingData.waybillNo.trim();
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6F6),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFFFFD1D3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38.w,
              height: 38.w,
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
                    isArabic ? 'تتبع الشحنة' : 'Shipment Tracking',
                    style: TextStyle(
                      color: AppColors.deepDark,
                      fontSize: 14.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    isArabic
                        ? 'تم إنشاء رقم التتبع الخاص بالناقل.'
                        : 'Carrier tracking is now available.',
                    style: TextStyle(
                      color: AppColors.softGray,
                      fontSize: 12.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SelectableText(
                    waybill,
                    style: TextStyle(
                      color: const Color(0xFFCB262E),
                      fontSize: 13.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: waybill));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isArabic ? 'تم نسخ رقم التتبع' : 'Tracking number copied',
                    ),
                  ),
                );
              },
              child: Text(
                isArabic ? 'نسخ' : 'Copy',
                style: TextStyle(
                  color: const Color(0xFFCB262E),
                  fontSize: 12.sp,
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingStepTile extends StatelessWidget {
  const _TrackingStepTile({
    required this.step,
    required this.isLast,
    required this.lineColor,
  });

  final _TrackingStepData step;
  final bool isLast;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    final titleColor = step.isCompleted || step.isActive
        ? const Color(0xFFCB262E)
        : AppColors.softGray;
    final metaColor = step.isCompleted || step.isActive
        ? const Color(0xFFCB262E)
        : AppColors.softGray;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48.w,
            child: Column(
              children: [
                Image.asset(
                  step.iconPath,
                  width: 36.w,
                  height: 36.w,
                  fit: BoxFit.contain,
                ),
                if (!isLast)
                  Container(width: 2.w, height: 58.h, color: lineColor),
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
                    step.title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14.sp,
                      fontFamily: 'Montes',
                      fontWeight: step.isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    step.metaLine,
                    style: TextStyle(
                      color: metaColor,
                      fontSize: 12.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w400,
                      height: 1.9,
                    ),
                  ),
                ],
              ),
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
              color: AppColors.deepDark,
              fontSize: 16.sp,
              fontFamily: 'Montes',
              fontWeight: FontWeight.w600,
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
          SizedBox(height: 20.h),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.white,
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

class _EmptyTrackingView extends StatelessWidget {
  const _EmptyTrackingView();

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return Padding(
      padding: EdgeInsets.only(top: 60.h),
      child: Center(
        child: Text(
          isArabic
              ? 'ستظهر تحديثات التتبع هنا قريباً.'
              : 'Tracking updates will appear here soon.',
          style: TextStyle(
            color: AppColors.softGray,
            fontSize: 12.sp,
            fontFamily: 'Montes',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _TrackingMetaReader {
  const _TrackingMetaReader(this.data, {required this.isArabic});

  final OrderData data;
  final bool isArabic;

  String get deliveryType => _localizedMetaValue(
    _findString(['delivery_type', 'deliveryType', 'service', 'method_title']) ??
        (data.shippingLines.isNotEmpty
            ? data.shippingLines.first.methodTitle
            : 'Express'),
  );

  String get estimate => _localizedMetaValue(
    _shouldShowTrackingStatus(data) && data.trackingStatus.trim().isNotEmpty
        ? _trackingStatusLabel(data.trackingStatus, isArabic: isArabic)
        : _findString([
                'estimate',
                'estimated_delivery',
                'estimatedDelivery',
                'eta',
              ]) ??
              _estimateFromStatus(),
  );

  String get weight =>
      _findString([
        'weight',
        'parcel_weight',
        'parcelWeight',
        'total_weight',
      ]) ??
      '--';

  DateTime? get orderDate {
    final raw = _findString([
      'orderPlacementDate',
      'orderplacement',
      'orderPlacement',
      'createdAt',
      'orderDate',
      'date',
    ]);
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return null;
    if (parsed.isUtc) return parsed.toLocal();
    final hasExplicitTimezone = RegExp(
      r'(z|Z|[+-]\d{2}:\d{2})$',
    ).hasMatch(raw.trim());
    if (hasExplicitTimezone) return parsed.toLocal();
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    ).toLocal();
  }

  String _estimateFromStatus() {
    switch (orderStatusFromRaw(data.orderStatus)) {
      case OrderStatus.delivered:
      case OrderStatus.returned:
        return isArabic ? 'تم التسليم' : 'Delivered';
      case OrderStatus.returnRequested:
        return isArabic ? 'قيد المراجعة' : 'Under Review';
      case OrderStatus.cancelled:
      case OrderStatus.paymentRejected:
        return isArabic ? 'متوقف' : 'Stopped';
      case OrderStatus.confirmed:
      case OrderStatus.paymentSuccessful:
      case OrderStatus.dispatched:
        return isArabic ? 'قيد المعالجة' : 'Processing';
      case OrderStatus.pending:
      case OrderStatus.paymentPending:
      case OrderStatus.unknown:
        return isArabic ? 'قيد الانتظار' : 'Pending';
    }
  }

  String _localizedMetaValue(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return raw;
    if (!isArabic) return raw;

    final lower = raw.toLowerCase();
    if (lower == 'unknown') return 'غير معروف';
    if (lower == 'status') return 'الحالة';
    if (lower == 'express') return 'سريع';
    if (lower == 'we will email you when delivery is scheduled.' ||
        lower == 'we will email you when delivery is scheduled') {
      return 'سنرسل لك بريداً إلكترونياً عند تحديد موعد التوصيل.';
    }
    return raw;
  }

  String? _findString(List<String> keys) {
    final candidates = <dynamic>[
      ...data.trackingItems,
      for (final line in data.shippingLines) ...line.metaData,
    ];
    for (final candidate in candidates) {
      final value = _readValue(candidate, keys);
      if (value != null && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String? _readValue(dynamic input, List<String> keys) {
    if (input is! Map) return null;
    for (final entry in input.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (keys.any(
        (candidate) => candidate.toLowerCase() == key.toLowerCase(),
      )) {
        return value?.toString();
      }
      if (value is Map || value is List) {
        final nested = value is List
            ? value
                  .map((item) => _readValue(item, keys))
                  .firstWhere((item) => item != null, orElse: () => null)
            : _readValue(value, keys);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }
}

class _TrackingTimelineBuilder {
  const _TrackingTimelineBuilder(this.data, {required this.isArabic});

  final OrderData data;
  final bool isArabic;
  static const Set<String> _hiddenMobileStatusKeys = <String>{
    'procurement_in_progress',
    'goods_being_sourced',
    'goods_arrived_at_warehouse',
    'goods_being_processed',
    'ready_to_ship',
    'processing_complete',
    'order_issue_contact_support',
    'preparing_your_shipment',
    'shipment_in_progress',
    'shipment_delayed',
    'shipment_ready',
  };

  static const List<_FulfillmentStepDefinition> _fulfillmentSteps = [
    _FulfillmentStepDefinition(
      stage: 'order',
      statusKey: 'order_confirmed',
      englishTitle: 'Order Confirmed',
      arabicTitle: 'تم تأكيد الطلب',
    ),
    _FulfillmentStepDefinition(
      stage: 'inbound',
      statusKey: 'procurement_in_progress',
      englishTitle: 'Procurement in Progress',
      arabicTitle: 'جاري تجهيز المنتجات',
    ),
    _FulfillmentStepDefinition(
      stage: 'inbound',
      statusKey: 'goods_being_sourced',
      englishTitle: 'Goods Being Sourced',
      arabicTitle: 'جاري توفير المنتجات',
    ),
    _FulfillmentStepDefinition(
      stage: 'inbound',
      statusKey: 'goods_arrived_at_warehouse',
      englishTitle: 'Goods Arrived at Warehouse',
      arabicTitle: 'وصلت المنتجات إلى المستودع',
    ),
    _FulfillmentStepDefinition(
      stage: 'inbound',
      statusKey: 'goods_being_processed',
      englishTitle: 'Goods Being Processed',
      arabicTitle: 'جاري معالجة المنتجات',
    ),
    _FulfillmentStepDefinition(
      stage: 'inbound',
      statusKey: 'ready_to_ship',
      englishTitle: 'Ready to Ship',
      arabicTitle: 'جاهز للشحن',
    ),
    _FulfillmentStepDefinition(
      stage: 'inbound',
      statusKey: 'processing_complete',
      englishTitle: 'Processing Complete',
      arabicTitle: 'اكتملت المعالجة',
    ),
    _FulfillmentStepDefinition(
      stage: 'inbound',
      statusKey: 'order_issue_contact_support',
      englishTitle: 'Order Issue - Contact Support',
      arabicTitle: 'مشكلة في الطلب - يرجى التواصل مع الدعم',
    ),
    _FulfillmentStepDefinition(
      stage: 'outbound',
      statusKey: 'preparing_your_shipment',
      englishTitle: 'Preparing Your Shipment',
      arabicTitle: 'جاري تجهيز الشحنة',
    ),
    _FulfillmentStepDefinition(
      stage: 'outbound',
      statusKey: 'shipment_in_progress',
      englishTitle: 'Shipment in Progress',
      arabicTitle: 'الشحنة قيد النقل',
    ),
    _FulfillmentStepDefinition(
      stage: 'outbound',
      statusKey: 'shipment_delayed',
      englishTitle: 'Shipment Delayed',
      arabicTitle: 'تأخر الشحنة',
    ),
    _FulfillmentStepDefinition(
      stage: 'outbound',
      statusKey: 'shipment_ready',
      englishTitle: 'Shipment Ready',
      arabicTitle: 'الشحنة جاهزة',
    ),
    _FulfillmentStepDefinition(
      stage: 'outbound',
      statusKey: 'shipped',
      englishTitle: 'Shipped',
      arabicTitle: 'تم الشحن',
    ),
    _FulfillmentStepDefinition(
      stage: 'outbound',
      statusKey: 'shipment_cancelled',
      englishTitle: 'Shipment Cancelled',
      arabicTitle: 'تم إلغاء الشحنة',
    ),
  ];

  List<_TrackingStepData> build() {
    if (data.trackingStages.isNotEmpty) {
      return _buildFixedStageTimeline();
    }
    return _buildCombinedTimeline();
  }

  List<_TrackingStepData> _buildFixedStageTimeline() {
    final stages = data.trackingStages;
    final activeIndex = stages.lastIndexWhere((stage) => stage.checked);

    return List<_TrackingStepData>.generate(stages.length, (index) {
      final stage = stages[index];
      return _TrackingStepData(
        statusKey: 'tracking_stage_${stage.id}',
        title: stage.name,
        metaLine: _fixedStageMetaLine(stage),
        isCompleted: stage.checked,
        isActive: index == activeIndex,
        iconPath: _iconForStage(stage.id, stage.checked),
      );
    });
  }

  String _fixedStageMetaLine(TrackingStage stage) {
    if (!stage.checked) {
      return isArabic ? 'بانتظار التحديث' : 'Awaiting update';
    }

    final parts = <String>[];
    if (stage.date != null) {
      parts.add(_formatTimelineDate(stage.date!));
    } else {
      parts.add(isArabic ? 'مكتمل' : 'Completed');
    }

    final metadata = stage.metadata;
    if (stage.id == 6 && metadata.trackingId != null) {
      parts.add(
        isArabic
            ? 'رقم التتبع ${metadata.trackingId}'
            : 'Tracking ID ${metadata.trackingId}',
      );
    }
    if (stage.id == 8 && metadata.reviewRating != null) {
      parts.add(
        isArabic
            ? 'التقييم ${metadata.reviewRating}'
            : 'Rating ${metadata.reviewRating}',
      );
    }
    if (stage.id == 9 && metadata.cancellationReason != null) {
      parts.add(metadata.cancellationReason!);
    }

    return parts.join(' • ');
  }

  List<_TrackingStepData> _buildCombinedTimeline() {
    final normalizedStage = _normalizeTrackingStage(data.trackingStage);
    final normalizedStatus = _normalizeTrackingStatus(data.trackingStatus);
    final statusIndex = _fulfillmentSteps.indexWhere(
      (step) => step.statusKey == normalizedStatus,
    );
    final fallbackIndex = _fallbackFulfillmentIndexForStage(normalizedStage);
    final activeFulfillmentIndex = statusIndex == -1
        ? fallbackIndex
        : statusIndex;
    final nowText = _formatTimelineDate(
      _resolveTrackingTimestamp() ?? DateTime.now(),
    );
    final oldStatuses = _oldStatusesBeforeFulfillment();
    final oldActiveIndex = _activeOldStatusIndex(oldStatuses);
    final shouldShowTrackingStatus = _shouldShowTrackingStatus(data);
    final hasTrackingProgress =
        shouldShowTrackingStatus && data.trackingStatus.trim().isNotEmpty ||
        shouldShowTrackingStatus && data.trackingStage.trim().isNotEmpty;
    final fulfillmentOffset = oldStatuses.length;
    final postFulfillmentStatuses = _postFulfillmentStatuses();
    final postFulfillmentOffset = oldStatuses.length + _fulfillmentSteps.length;
    final postActiveIndex = _activePostFulfillmentStatusIndex(
      postFulfillmentStatuses,
    );
    final activeIndex = postActiveIndex != -1
        ? postFulfillmentOffset + postActiveIndex
        : hasTrackingProgress
        ? fulfillmentOffset + activeFulfillmentIndex
        : oldActiveIndex;
    final backendStatus =
        shouldShowTrackingStatus && data.trackingStatus.trim().isNotEmpty
        ? data.trackingStatus.trim()
        : _fulfillmentSteps[activeFulfillmentIndex].englishTitle;
    final waybill = data.waybillNo.trim();
    final totalLength =
        oldStatuses.length +
        _fulfillmentSteps.length +
        postFulfillmentStatuses.length;

    final allSteps = List.generate(totalLength, (index) {
      final isTerminalProblem =
          normalizedStatus == 'order_issue_contact_support' ||
          normalizedStatus == 'shipment_cancelled';
      final isActive = index == activeIndex;
      final isCompleted =
          index < activeIndex ||
          (isActive &&
              (hasTrackingProgress || postActiveIndex != -1) &&
              !isTerminalProblem);

      if (index < fulfillmentOffset) {
        final rawStatus = oldStatuses[index];
        return _TrackingStepData(
          statusKey: rawStatus,
          title: _labelFor(rawStatus),
          metaLine: isActive
              ? (isArabic
                    ? 'الحالة الحالية • $nowText'
                    : 'Current status • $nowText')
              : index < activeIndex
              ? (isArabic ? 'مكتمل' : 'Completed')
              : (isArabic ? 'بانتظار التحديث' : 'Awaiting update'),
          isCompleted: isCompleted,
          isActive: isActive,
          iconPath: _iconFor(index, isCompleted),
        );
      }

      if (index >= postFulfillmentOffset) {
        final postIndex = index - postFulfillmentOffset;
        final rawStatus = postFulfillmentStatuses[postIndex];
        return _TrackingStepData(
          statusKey: rawStatus,
          title: _labelFor(rawStatus),
          metaLine: isActive
              ? (isArabic
                    ? 'الحالة الحالية • $nowText'
                    : 'Current status • $nowText')
              : index < activeIndex
              ? (isArabic ? 'مكتمل' : 'Completed')
              : (isArabic ? 'بانتظار التحديث' : 'Awaiting update'),
          isCompleted: isCompleted,
          isActive: isActive,
          iconPath: _iconFor(index, isCompleted),
        );
      }

      final fulfillmentIndex = index - fulfillmentOffset;
      final step = _fulfillmentSteps[fulfillmentIndex];
      final line = isActive && hasTrackingProgress
          ? _activeFulfillmentMetaLine(
              stage: step.stage,
              backendStatus: backendStatus,
              waybill: waybill,
              timestamp: nowText,
            )
          : index < activeIndex
          ? (isArabic ? 'مكتمل' : 'Completed')
          : _waitingFulfillmentText(step.stage);

      return _TrackingStepData(
        statusKey: step.statusKey,
        title: isArabic ? step.arabicTitle : step.englishTitle,
        metaLine: line,
        isCompleted: isCompleted,
        isActive: isActive,
        iconPath: _iconFor(index, isCompleted),
      );
    });

    final lastConfirmedIndex = allSteps.lastIndexWhere(
      (step) => step.statusKey == 'order_confirmed',
    );
    final dedupedSteps = lastConfirmedIndex == -1
        ? allSteps
        : List<_TrackingStepData>.generate(allSteps.length, (index) {
            final step = allSteps[index];
            if (step.statusKey == 'order_confirmed' &&
                index != lastConfirmedIndex) {
              return step.copyWith(statusKey: '__hidden_duplicate__');
            }
            return step;
          }).where((step) => step.statusKey != '__hidden_duplicate__').toList();

    final visibleSteps = dedupedSteps
        .where((step) => !_hiddenMobileStatusKeys.contains(step.statusKey))
        .toList(growable: false);
    if (visibleSteps.isEmpty) {
      return dedupedSteps;
    }

    var activeVisibleIndex = visibleSteps.indexWhere((step) => step.isActive);
    if (activeVisibleIndex == -1) {
      final lastCompletedVisible = visibleSteps.lastIndexWhere(
        (step) => step.isCompleted,
      );
      activeVisibleIndex = lastCompletedVisible >= 0 ? lastCompletedVisible : 0;
    }

    return List<_TrackingStepData>.generate(visibleSteps.length, (index) {
      final step = visibleSteps[index];
      return step.copyWith(isActive: index == activeVisibleIndex);
    });
  }

  List<String> _oldStatusesBeforeFulfillment() {
    final activeRawStatus = _normalizeStatus(data.orderStatus);
    if (activeRawStatus == 'failed' || activeRawStatus == 'cancelled') {
      return const [
        'pending',
        'order_placed',
        'payment_rejected',
        'order_cancelled',
      ];
    }
    if (activeRawStatus == 'payment_pending') {
      return const [
        'pending',
        'order_placed',
        'payment_pending',
        'payment_successful',
        'order_confirmed',
      ];
    }
    return const [
      'pending',
      'order_placed',
      'payment_successful',
      'order_confirmed',
    ];
  }

  int _activeOldStatusIndex(List<String> oldStatuses) {
    final activeRawStatus = _normalizeStatus(data.orderStatus);
    final mappedStatus = switch (activeRawStatus) {
      'confirmed' => 'order_confirmed',
      'payment_rejected' || 'failed' => 'payment_rejected',
      'cancelled' => 'order_cancelled',
      _ => activeRawStatus,
    };
    final exactIndex = oldStatuses.indexOf(mappedStatus);
    if (exactIndex != -1) return exactIndex;
    if (activeRawStatus == 'dispatched' ||
        activeRawStatus == 'delivered' ||
        activeRawStatus == 'return_requested' ||
        activeRawStatus == 'returned') {
      return oldStatuses.length - 1;
    }
    return 0;
  }

  List<String> _postFulfillmentStatuses() {
    return const ['delivered', 'return_requested', 'returned'];
  }

  int _activePostFulfillmentStatusIndex(List<String> statuses) {
    final activeRawStatus = _normalizeStatus(data.orderStatus);
    return statuses.indexOf(activeRawStatus);
  }

  String _activeFulfillmentMetaLine({
    required String stage,
    required String backendStatus,
    required String waybill,
    required String timestamp,
  }) {
    final status = backendStatus.isNotEmpty
        ? _trackingStatusLabel(backendStatus, isArabic: isArabic)
        : _defaultTrackingStatus(stage);
    if (stage == 'outbound' && waybill.isNotEmpty) {
      return isArabic
          ? '$status • رقم التتبع $waybill'
          : '$status • Waybill $waybill';
    }
    return isArabic ? '$status • $timestamp' : '$status • $timestamp';
  }

  String _defaultTrackingStatus(String stage) {
    return switch (stage) {
      'inbound' => isArabic ? 'جاري تجهيز المنتجات' : 'Procurement in Progress',
      'outbound' => isArabic ? 'جاري تجهيز الشحنة' : 'Preparing Your Shipment',
      _ => isArabic ? 'تم تأكيد الطلب' : 'Order Confirmed',
    };
  }

  int _fallbackFulfillmentIndexForStage(String stage) {
    return switch (stage) {
      'outbound' => _fulfillmentSteps.indexWhere(
        (step) => step.statusKey == 'preparing_your_shipment',
      ),
      'inbound' => _fulfillmentSteps.indexWhere(
        (step) => step.statusKey == 'procurement_in_progress',
      ),
      _ => 0,
    };
  }

  String _waitingFulfillmentText(String stage) {
    return switch (stage) {
      'outbound' =>
        isArabic ? 'بانتظار تحديث الشحنة' : 'Awaiting shipment update',
      'inbound' =>
        isArabic ? 'بانتظار تحديث المستودع' : 'Awaiting warehouse update',
      _ => isArabic ? 'بانتظار تجهيز الطلب' : 'Awaiting order processing',
    };
  }

  String _normalizeTrackingStage(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'inbound' || normalized == 'outbound') {
      return normalized;
    }
    return 'order';
  }

  String _normalizeTrackingStatus(String raw) {
    final normalized = raw
        .trim()
        .toLowerCase()
        .replaceAll('—', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (normalized == 'order_issue_contact_support') {
      return 'order_issue_contact_support';
    }
    if (normalized == 'confirmed' || normalized == 'order_confirmed') {
      return 'order_confirmed';
    }
    if (normalized == 'outbound_shipped_fetched' ||
        normalized == 'outbound_shipped' ||
        normalized == 'shipment_shipped' ||
        normalized == 'order_shipped') {
      return 'shipped';
    }
    return normalized;
  }

  String _normalizeStatus(String raw) {
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'payment success':
      case 'paymentsuccess':
        return 'payment_successful';
      case 'payment_rejected':
      case 'payment failed':
      case 'payment_failed':
        return 'failed';
      case 'cancelled':
        return 'cancelled';
      case 'completed':
        return 'delivered';
      case 'return requested':
      case 'return-requested':
        return 'return_requested';
      case 'shipped':
      case 'order_shipped':
      case 'outbound_shipped':
      case 'outbound_shipped_fetched':
        return 'dispatched';
      default:
        return normalized;
    }
  }

  String _labelFor(String rawStatus) {
    if (rawStatus == 'order_placed') {
      return isArabic ? 'تم تقديم الطلب' : 'Order Placed';
    }
    if (rawStatus == 'order_confirmed') {
      return isArabic ? 'تم تأكيد الطلب' : 'Order Confirmed';
    }
    if (rawStatus == 'order_cancelled') {
      return isArabic ? 'تم إلغاء الطلب' : 'Order Cancelled';
    }
    if (rawStatus == 'dispatched') {
      return isArabic ? 'تم الشحن' : 'Dispatched';
    }
    if (rawStatus == 'payment_pending') {
      return isArabic ? 'الدفع قيد الانتظار' : 'Payment Pending';
    }
    if (rawStatus == 'failed' || rawStatus == 'payment_rejected') {
      return isArabic ? 'فشل الدفع' : 'Payment Unsuccessful';
    }
    return orderStatusLabelByLocale(rawStatus, isArabic: isArabic);
  }

  static String _iconFor(int index, bool isCompleted) {
    if (!isCompleted) {
      return 'assets/images/incomplete.png';
    }
    // Use the dedicated active-step artwork for each completed stage.
    // `track4.png` is not present in assets right now, so step 4 falls back to
    // the nearest available completed icon until that file is added.
    const completedIcons = <String>[
      'assets/images/track1.png',
      'assets/images/track2.png',
      'assets/images/track3.png',
      'assets/images/track5.png',
      'assets/images/track5.png',
    ];
    final safeIndex = index.clamp(0, completedIcons.length - 1);
    return completedIcons[safeIndex];
  }

  static String _iconForStage(int stageId, bool isCompleted) {
    if (!isCompleted) {
      return 'assets/images/incomplete.png';
    }

    const completedIcons = <int, String>{
      1: 'assets/images/track1.png',
      2: 'assets/images/track2.png',
      3: 'assets/images/track3.png',
      4: 'assets/images/track5.png',
      5: 'assets/images/track5.png',
      6: 'assets/images/track5.png',
      7: 'assets/images/track5.png',
      8: 'assets/images/track3.png',
      9: 'assets/images/track2.png',
    };
    return completedIcons[stageId] ?? 'assets/images/track1.png';
  }

  static String _formatTimelineDate(DateTime date) {
    return DateFormat('MMM dd | hh:mm a').format(date);
  }

  DateTime? _resolveTrackingTimestamp() {
    final candidates = <dynamic>[
      ...data.trackingItems,
      for (final line in data.shippingLines) ...line.metaData,
    ];
    const keys = <String>[
      'updatedAt',
      'orderUpdatedAt',
      'orderPlacementDate',
      'orderplacement',
      'orderPlacement',
      'createdAt',
      'orderDate',
      'date',
      'eta',
    ];

    for (final candidate in candidates) {
      final raw = _readValue(candidate, keys)?.trim() ?? '';
      if (raw.isEmpty) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) continue;

      if (parsed.isUtc) return parsed.toLocal();
      final hasExplicitTimezone = RegExp(
        r'(z|Z|[+-]\d{2}:\d{2})$',
      ).hasMatch(raw);
      if (hasExplicitTimezone) return parsed.toLocal();

      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      ).toLocal();
    }
    return null;
  }

  String? _readValue(dynamic input, List<String> keys) {
    if (input is! Map) return null;
    for (final entry in input.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (keys.any(
        (candidate) => candidate.toLowerCase() == key.toLowerCase(),
      )) {
        return value?.toString();
      }
      if (value is Map || value is List) {
        final nested = value is List
            ? value
                  .map((item) => _readValue(item, keys))
                  .firstWhere((item) => item != null, orElse: () => null)
            : _readValue(value, keys);
        if (nested != null) {
          return nested;
        }
      }
    }
    return null;
  }
}

class _FulfillmentStepDefinition {
  const _FulfillmentStepDefinition({
    required this.stage,
    required this.statusKey,
    required this.englishTitle,
    required this.arabicTitle,
  });

  final String stage;
  final String statusKey;
  final String englishTitle;
  final String arabicTitle;
}

class _TrackingStepData {
  const _TrackingStepData({
    required this.statusKey,
    required this.title,
    required this.metaLine,
    required this.isCompleted,
    required this.isActive,
    required this.iconPath,
  });

  final String statusKey;
  final String title;
  final String metaLine;
  final bool isCompleted;
  final bool isActive;
  final String iconPath;

  _TrackingStepData copyWith({
    String? statusKey,
    String? title,
    String? metaLine,
    bool? isCompleted,
    bool? isActive,
    String? iconPath,
  }) {
    return _TrackingStepData(
      statusKey: statusKey ?? this.statusKey,
      title: title ?? this.title,
      metaLine: metaLine ?? this.metaLine,
      isCompleted: isCompleted ?? this.isCompleted,
      isActive: isActive ?? this.isActive,
      iconPath: iconPath ?? this.iconPath,
    );
  }
}
