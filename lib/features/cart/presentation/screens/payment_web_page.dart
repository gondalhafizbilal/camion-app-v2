import 'dart:async';

import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/appsflyer_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/core/services/tiktok_business_service.dart';
import 'package:camion/routing/app_router.dart';
import 'package:camion/core/services/cart_refresh_notifier.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/features/order_status/data/models/order_response_model/order_response_model.dart';
import 'package:camion/features/order_status/data/repository/order_status_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String checkoutUrl;
  final OrderResponse? orderResponse;
  final double subTotal;
  final double shipping;
  final double discountTotal;
  final double total;
  // final String orderId;

  const PaymentWebViewPage({
    super.key,
    required this.checkoutUrl,
    this.orderResponse,
    this.subTotal = 0,
    this.shipping = 0,
    this.discountTotal = 0,
    this.total = 0,
    // required this.orderId,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  InAppWebViewController? webViewController;
  bool isLoading = true;
  bool _didHandleResult = false;
  bool _showContinueButton = false;
  bool _showRetryPayment = false;
  bool _isRetryingPayment = false;
  String _currentCheckoutUrl = '';
  String _retryErrorMessage = '';
  OrderResponse? _currentOrderResponse;

  @override
  void initState() {
    super.initState();
    _currentCheckoutUrl = widget.checkoutUrl;
    _currentOrderResponse = widget.orderResponse;
    unawaited(
      sl<AppsFlyerService>().logConversionEvent(
        'payment_attempt',
        eventParams: _paymentEventParams(),
      ),
    );
  }

  void _inspectNavigationForResult(WebUri? webUri) {
    if (_didHandleResult || webUri == null) {
      return;
    }

    final rawUrl = webUri.toString();
    if (rawUrl.trim().isEmpty) {
      return;
    }

    final lowerUrl = rawUrl.toLowerCase();
    final uri = Uri.tryParse(rawUrl);

    if (_isPaymentSuccessUrl(lowerUrl, uri)) {
      _handlePaymentSuccess();
      return;
    }

    if (_isPaymentFailureUrl(lowerUrl, uri)) {
      _handlePaymentFailure(rawUrl: rawUrl);
    }
  }

  Future<void> _detectSkipCashPaidState() async {
    if (_didHandleResult || webViewController == null || !mounted) {
      return;
    }

    try {
      final raw = await webViewController!.evaluateJavascript(
        source: '''
          (() => {
            const text = (document.body && document.body.innerText) ? document.body.innerText : '';
            return text.toLowerCase();
          })();
        ''',
      );

      final bodyText = (raw ?? '').toString().toLowerCase();
      final paidDetected =
          bodyText.contains('status') &&
          bodyText.contains('paid') &&
          bodyText.contains('transaction id');

      if (paidDetected && mounted) {
        setState(() {
          _showContinueButton = true;
        });
      }
    } catch (_) {
      // Ignore transient JS eval errors while page is changing.
    }
  }

  bool _isPaymentSuccessUrl(String lowerUrl, Uri? uri) {
    if (lowerUrl.contains('payment_successful') ||
        lowerUrl.contains('payment-status=paid') ||
        lowerUrl.contains('payment_status=paid') ||
        lowerUrl.contains('payment_status=success') ||
        lowerUrl.contains('payment_intent') ||
        lowerUrl.contains('status=paid') ||
        lowerUrl.contains('status=success') ||
        lowerUrl.contains('result=success') ||
        lowerUrl.contains('result=successful')) {
      return true;
    }

    if (uri == null) {
      return false;
    }

    final path = uri.path.toLowerCase();
    if (path.contains('payment-success') ||
        path.contains('/success') ||
        path.contains('/successful')) {
      return true;
    }

    for (final entry in uri.queryParameters.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value.toLowerCase();
      if (key == 'status' ||
          key == 'payment_status' ||
          key == 'result' ||
          key == 'paymentresult') {
        if (value == 'success' ||
            value == 'successful' ||
            value == 'paid' ||
            value == 'succeeded' ||
            value == 'payment_successful') {
          return true;
        }
      }
    }

    return false;
  }

  bool _isPaymentFailureUrl(String lowerUrl, Uri? uri) {
    if (lowerUrl.contains('payment_rejected') ||
        lowerUrl.contains('payment_failed') ||
        lowerUrl.contains('payment_status=failed') ||
        lowerUrl.contains('payment-status=failed') ||
        lowerUrl.contains('status=failed') ||
        lowerUrl.contains('status=cancel') ||
        lowerUrl.contains('status=cancelled') ||
        lowerUrl.contains('result=failed') ||
        lowerUrl.contains('result=cancelled') ||
        lowerUrl.contains('cancel') ||
        lowerUrl.contains('failed') ||
        lowerUrl.contains('declined') ||
        lowerUrl.contains('rejected')) {
      return true;
    }

    if (uri == null) {
      return false;
    }

    for (final entry in uri.queryParameters.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value.toLowerCase();
      if (key == 'status' ||
          key == 'payment_status' ||
          key == 'result' ||
          key == 'paymentresult') {
        if (value == 'failed' ||
            value == 'cancel' ||
            value == 'cancelled' ||
            value == 'rejected' ||
            value == 'declined' ||
            value == 'error') {
          return true;
        }
      }
    }

    return false;
  }

  String _resolveOrderUuid() {
    final orderResponse = _currentOrderResponse;
    if (orderResponse == null) {
      return '';
    }
    final orderId = orderResponse.data.order.id.trim();
    if (orderId.isNotEmpty) {
      return orderId;
    }
    return orderResponse.data.orderId.trim();
  }

  String _resolvePaymentCheckoutUrl(OrderResponse orderResponse) {
    final fromV1 = orderResponse.data.paymentPayUrl.trim();
    if (fromV1.isNotEmpty) {
      return fromV1;
    }
    final legacy = orderResponse.data.order.skipCashPaymentUrl.trim();
    if (legacy.isNotEmpty) {
      return legacy;
    }
    return '';
  }

  Future<void> _retryPayment() async {
    if (_isRetryingPayment) {
      return;
    }

    final orderUuid = _resolveOrderUuid();
    if (orderUuid.isEmpty) {
      setState(() {
        _retryErrorMessage = 'Unable to retry payment for this order.';
      });
      return;
    }

    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (!mounted) {
      return;
    }
    if (token == null || token.trim().isEmpty) {
      setState(() {
        _retryErrorMessage = 'Please login to retry payment.';
      });
      return;
    }

    setState(() {
      _isRetryingPayment = true;
      _retryErrorMessage = '';
    });

    final result = await sl<OrderStatusRepository>().retryPayment(
      token: token,
      orderUuid: orderUuid,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (error) {
        setState(() {
          _isRetryingPayment = false;
          _retryErrorMessage = error.message.trim().isNotEmpty
              ? error.message
              : 'Unable to retry payment. Please try again.';
        });
      },
      (orderResponse) async {
        final checkoutUrl = _resolvePaymentCheckoutUrl(orderResponse);
        if (checkoutUrl.isEmpty) {
          setState(() {
            _isRetryingPayment = false;
            _retryErrorMessage =
                'Unable to open payment page. Please try again.';
          });
          return;
        }

        setState(() {
          _currentOrderResponse = orderResponse;
          _currentCheckoutUrl = checkoutUrl;
          _didHandleResult = false;
          _showContinueButton = false;
          _showRetryPayment = false;
          _isRetryingPayment = false;
          _retryErrorMessage = '';
          isLoading = true;
        });

        await webViewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri(checkoutUrl)),
        );
      },
    );
  }

  void _showPaymentRetryState({String? message}) {
    if (!mounted) {
      return;
    }
    setState(() {
      isLoading = false;
      _didHandleResult = true;
      _showContinueButton = false;
      _showRetryPayment = true;
      _retryErrorMessage = message ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        return;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 70.h,
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(_currentCheckoutUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                domStorageEnabled: true,
              ),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  isLoading = true;
                });
                _inspectNavigationForResult(url);
              },
              onLoadStop: (controller, url) {
                setState(() {
                  isLoading = false;
                });
                _inspectNavigationForResult(url);
                _detectSkipCashPaidState();
              },
              onUpdateVisitedHistory: (controller, url, isReload) {
                _inspectNavigationForResult(url);
                _detectSkipCashPaidState();
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                _inspectNavigationForResult(navigationAction.request.url);
                return NavigationActionPolicy.ALLOW;
              },
              onReceivedError: (controller, request, error) {
                if (request.isForMainFrame ?? true) {
                  unawaited(
                    sl<AppsFlyerService>().logConversionEvent(
                      'payment_failed',
                      eventParams: _paymentEventParams(
                        errorCode: error.type.toString(),
                        errorStage: 'payment_page_load',
                      ),
                    ),
                  );
                  _showPaymentRetryState(
                    message: 'Payment page could not load. Please try again.',
                  );
                }
              },
            ),

            // Loading Indicator
            if (isLoading)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        S.of(context).payment_page_loading,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showContinueButton && !_didHandleResult)
              Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 20.h,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 52.h,
                    child: ElevatedButton(
                      onPressed: _handlePaymentSuccess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ),
              ),
            if (_showRetryPayment) _buildRetryPaymentOverlay(context),
          ],
        ),
      ),
    );
  }

  void _handlePaymentSuccess() {
    if (_didHandleResult) {
      return;
    }
    _didHandleResult = true;

    AppToast.show(msg: "Successful payment", backgroundColor: Colors.green);
    debugPrint('[TIKTOK][PURCHASE] payment success detected');
    CartRefreshNotifier.requestRefresh();
    unawaited(_trackAppsFlyerPurchase());
    unawaited(_trackTikTokPurchase());

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      final orderResponse = _currentOrderResponse;
      if (orderResponse != null) {
        GoRouter.of(context).pushReplacement(
          AppRouter.orderOverview,
          extra: {
            'orderResponse': orderResponse,
            'subTotal': widget.subTotal,
            'shipping': widget.shipping,
            'discountTotal': widget.discountTotal,
            'total': widget.total,
          },
        );
        return;
      }

      GoRouter.of(context).pushReplacement(AppRouter.selectingFromBottomNavBar);
    });
  }

  Future<void> _trackTikTokPurchase() async {
    try {
      debugPrint('[TIKTOK][PURCHASE] preparing purchase event');
      final orderResponse = _currentOrderResponse;
      final order = orderResponse?.data.order;
      final currency = (order?.currency ?? '').trim().isNotEmpty
          ? (order?.currency ?? '').trim().toUpperCase()
          : 'USD';
      final orderId = (order?.id ?? '').trim();
      final total = order != null
          ? double.tryParse(order.total.trim()) ?? widget.total
          : widget.total;
      final contents = order == null
          ? const <Map<String, dynamic>>[]
          : order.items
                .map((item) {
                  final productId = item.productId.trim();
                  if (productId.isEmpty) return null;
                  return <String, dynamic>{
                    'contentId': productId,
                    'contentName': item.title.trim(),
                    'price': double.tryParse(item.price.trim()) ?? 0.0,
                    'quantity': item.quantity,
                  };
                })
                .whereType<Map<String, dynamic>>()
                .toList();

      await TikTokBusinessService.purchase(
        eventId: orderId.isNotEmpty ? orderId : null,
        contentId: orderId.isNotEmpty ? orderId : null,
        description: 'Payment successful',
        contentType: 'product',
        value: total.toStringAsFixed(2),
        currency: currency,
        contents: contents,
      );
      debugPrint('[TIKTOK][PURCHASE] purchase event sent');
    } catch (error, stackTrace) {
      debugPrint('[TIKTOK][PURCHASE] tracking failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  Future<void> _trackAppsFlyerPurchase() async {
    try {
      final orderResponse = _currentOrderResponse;
      final order = orderResponse?.data.order;
      final currency = (order?.currency ?? '').trim().isNotEmpty
          ? (order?.currency ?? '').trim().toUpperCase()
          : 'USD';
      final orderId = (order?.id ?? '').trim();
      final total = order != null
          ? double.tryParse(order.total.trim()) ?? widget.total
          : widget.total;
      final items = order?.items ?? const [];
      final contentIds = items
          .map((item) => item.productId.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      final quantity = items.fold<int>(
        0,
        (sum, item) => sum + (item.quantity <= 0 ? 1 : item.quantity),
      );

      await sl<AppsFlyerService>().logPurchase(
        orderId: orderId.isNotEmpty ? orderId : 'payment_success',
        receiptId: orderId.isNotEmpty ? orderId : null,
        contentIds: contentIds.isNotEmpty
            ? contentIds
            : [orderId.isNotEmpty ? orderId : 'payment_success'],
        contentType: 'product',
        revenue: total.toStringAsFixed(2),
        price: total.toStringAsFixed(2),
        currency: currency,
        quantity: quantity <= 0 ? 1 : quantity,
      );
    } catch (error, stackTrace) {
      debugPrint('[APPSFLYER][PURCHASE] tracking failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  Map<String, dynamic> _paymentEventParams({
    String errorCode = '',
    String errorStage = '',
  }) {
    final order = _currentOrderResponse?.data.order;
    final orderId = (order?.id ?? _currentOrderResponse?.data.orderId ?? '')
        .trim();
    final currency = (order?.currency ?? '').trim().isNotEmpty
        ? (order?.currency ?? '').trim().toUpperCase()
        : 'USD';
    final total = order != null
        ? double.tryParse(order.total.trim()) ?? widget.total
        : widget.total;
    return <String, dynamic>{
      'order_id': orderId,
      'cart_value': total,
      'currency': currency,
      if (errorCode.trim().isNotEmpty) 'error_code': errorCode.trim(),
      if (errorStage.trim().isNotEmpty) 'error_stage': errorStage.trim(),
    };
  }

  void _handlePaymentFailure({String rawUrl = ''}) {
    if (_didHandleResult) {
      return;
    }

    final lowerUrl = rawUrl.toLowerCase();
    final isCancelled =
        lowerUrl.contains('cancel') || lowerUrl.contains('cancelled');
    unawaited(
      sl<AppsFlyerService>().logConversionEvent(
        isCancelled ? 'payment_cancelled' : 'payment_failed',
        eventParams: _paymentEventParams(
          errorCode: isCancelled ? 'cancelled' : 'failed',
          errorStage: 'payment_webview',
        ),
      ),
    );
    AppToast.show(msg: "Payment failed", backgroundColor: Colors.red);
    _showPaymentRetryState();
  }

  Widget _buildRetryPaymentOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.credit_card_off_outlined,
                color: Colors.red,
                size: 52.sp,
              ),
              SizedBox(height: 18.h),
              Text(
                'Payment could not be completed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                _retryErrorMessage.trim().isNotEmpty
                    ? _retryErrorMessage
                    : 'You can retry payment on the same order without placing a duplicate order.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 28.h),
              SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _isRetryingPayment ? null : _retryPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: _isRetryingPayment
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Retry Payment'),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: _isRetryingPayment
                    ? null
                    : () => AppNavigator.safePop(context),
                child: Text(
                  'Back to checkout',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // void _showExitDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text("تأكيد الخروج"),
  //         content: const Text("هل تريد إلغاء عملية الدفع والخروج؟"),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               GoRouter.of(context).pop(); // إغلاق الحوار
  //             },
  //             child: const Text("لا"),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               GoRouter.of(context).pop(); // إغلاق الحوار
  //               GoRouter.of(context).pop(); // العودة للصفحة السابقة
  //             },
  //             child: const Text("نعم", style: TextStyle(color: Colors.red)),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  void dispose() {
    super.dispose();
  }
}
