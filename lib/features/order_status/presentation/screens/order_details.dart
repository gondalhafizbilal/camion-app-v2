import 'dart:io';

import 'package:camion/config/widgets/custom_sliver_app_bar.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/features/home/data/models/reviews_model/review_model.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/presentation/logic/cubit/create_review_cubit/create_review_cubit.dart';
import 'package:camion/features/order_status/data/models/order_model/order_model.dart';
import 'package:camion/features/order_status/data/models/return_request_model.dart';
import 'package:camion/features/order_status/data/repository/order_status_repo.dart';
import 'package:camion/features/order_status/utils/order_status_utils.dart';
import 'package:camion/features/order_status/presentation/widgets/custom_order_details.dart';
import 'package:camion/routing/app_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    super.key,
    required this.items,
    required this.numberOfOrder,
    required this.orderDate,
    required this.subTotalPrice,
    required this.totalPrice,
    required this.shippingCost,
    required this.paymentMethod,
    required this.discount,
    required this.shippingAddress,
    required this.currency,
  });

  final List<OrderItemModel> items;
  final String numberOfOrder;
  final DateTime orderDate;
  final String subTotalPrice;
  final String totalPrice;
  final String currency;
  final String shippingCost;
  final String paymentMethod;
  final String discount;
  final String shippingAddress;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isLoading = true;
  OrderModel? _order;
  String? _errorMessage;
  Map<String, ReviewModel> _myReviewsByProduct = const <String, ReviewModel>{};
  ReturnRequestModel? _returnRequest;
  String? _lastLocaleCode;
  int _fetchSequence = 0;

  bool _isDisplayableVariation(String attribute, String value) {
    final normalized = attribute.trim().toLowerCase();
    if (normalized.isEmpty || value.trim().isEmpty) return false;
    return normalized != 'variantuuid' &&
        normalized != 'variant_uuid' &&
        normalized != 'sku' &&
        normalized != 'barcode';
  }

  int _variationPriority(String attribute) {
    final key = attribute.trim().toLowerCase();
    if (key == 'size' || key == 'applicable model' || key == 'model') return 0;
    if (key == 'color' || key == 'colour') return 1;
    if (key == 'variant') return 99;
    return 50;
  }

  List<String> _sharedVariationOrder(List<OrderItemModel> items) {
    final counts = <String, int>{};
    final labelByKey = <String, String>{};

    for (final item in items) {
      final seenInItem = <String>{};
      for (final variation in item.variation) {
        final label = variation.attribute.trim();
        final value = variation.value.trim();
        if (!_isDisplayableVariation(label, value)) continue;
        final key = label.toLowerCase();
        if (!seenInItem.add(key)) continue;
        counts[key] = (counts[key] ?? 0) + 1;
        labelByKey[key] = labelByKey[key] ?? label;
      }
    }

    final sharedKeys = counts.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toList();

    sharedKeys.sort((a, b) {
      final aLabel = labelByKey[a] ?? a;
      final bLabel = labelByKey[b] ?? b;
      final pA = _variationPriority(aLabel);
      final pB = _variationPriority(bLabel);
      if (pA != pB) return pA.compareTo(pB);
      return aLabel.compareTo(bLabel);
    });

    return sharedKeys
        .map((key) => labelByKey[key] ?? key)
        .where((label) => label.trim().isNotEmpty)
        .toList();
  }

  Color _statusBackgroundColor(String rawStatus) {
    switch (orderStatusFromRaw(rawStatus)) {
      case OrderStatus.delivered:
      case OrderStatus.paymentSuccessful:
      case OrderStatus.returned:
        return const Color(0xFFE3FFD5);
      case OrderStatus.confirmed:
      case OrderStatus.dispatched:
        return const Color(0xFFEAF1FF);
      case OrderStatus.returnRequested:
      case OrderStatus.pending:
      case OrderStatus.paymentPending:
      case OrderStatus.unknown:
        return const Color(0xFFFFF2D9);
      case OrderStatus.cancelled:
      case OrderStatus.paymentRejected:
        return const Color(0xFFFFE8E8);
    }
  }

  Color _statusTextColor(String rawStatus) {
    switch (orderStatusFromRaw(rawStatus)) {
      case OrderStatus.delivered:
      case OrderStatus.paymentSuccessful:
      case OrderStatus.returned:
        return const Color(0xFF3D743A);
      case OrderStatus.confirmed:
      case OrderStatus.dispatched:
        return const Color(0xFF24419B);
      case OrderStatus.returnRequested:
      case OrderStatus.pending:
      case OrderStatus.paymentPending:
      case OrderStatus.unknown:
        return const Color(0xFF9A6700);
      case OrderStatus.cancelled:
      case OrderStatus.paymentRejected:
        return const Color(0xFFB42318);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchOrder();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final localeCode = Localizations.localeOf(
      context,
    ).languageCode.toLowerCase();
    if (_lastLocaleCode == null) {
      _lastLocaleCode = localeCode;
      return;
    }
    if (_lastLocaleCode == localeCode) {
      return;
    }
    _lastLocaleCode = localeCode;
    setState(() {
      _isLoading = true;
      _order = null;
      _errorMessage = null;
      _returnRequest = null;
      _myReviewsByProduct = const <String, ReviewModel>{};
    });
    _fetchOrder();
  }

  Future<void> _fetchOrder() async {
    final fetchVersion = ++_fetchSequence;
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final orderUuid = widget.numberOfOrder.trim();
    if (!mounted || fetchVersion != _fetchSequence) return;

    if (token == null || token.isEmpty || orderUuid.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final result = await sl<OrderStatusRepository>().getCurrentCustomerOrder(
      token: token,
      uuid: orderUuid,
    );
    if (!mounted || fetchVersion != _fetchSequence) return;
    result.fold(
      (error) {
        if (!mounted || fetchVersion != _fetchSequence) return;
        setState(() {
          _errorMessage = error.message;
          _isLoading = false;
        });
      },
      (order) async {
        if (!mounted || fetchVersion != _fetchSequence) return;
        setState(() {
          _order = order;
          _isLoading = false;
          _errorMessage = null;
        });
        await _loadReturnRequestForOrder(order.id);
        await _loadMyReviewsByProduct(order.items);
      },
    );
  }

  Future<void> _loadReturnRequestForOrder(String orderUuid) async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    if (token == null || token.trim().isEmpty || orderUuid.trim().isEmpty) {
      return;
    }
    final result = await sl<OrderStatusRepository>()
        .getCurrentCustomerReturnRequests(token: token);
    if (!mounted) return;
    result.fold((_) {}, (requests) {
      final matches = requests.where(
        (request) => request.order?.uuid.trim() == orderUuid.trim(),
      );
      setState(() {
        _returnRequest = matches.isEmpty ? null : matches.first;
      });
    });
  }

  bool _isReviewEligibleStatus(String rawStatus) {
    final normalized = rawStatus.trim().toLowerCase();
    final status = orderStatusFromRaw(rawStatus);
    return status == OrderStatus.delivered ||
        status == OrderStatus.paymentSuccessful ||
        status == OrderStatus.returned ||
        normalized == 'completed';
  }

  String _formatOrderDate(DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    final localDate = date.toLocal();
    return DateFormat(
      'MMMM dd, yyyy hh:mm a',
      locale,
    ).format(localDate).replaceAll('ص', 'صباحاً').replaceAll('م', 'مساءً');
  }

  List<String> _deliveryAddressLines(OrderModel? order, String fallback) {
    final customer = order?.customerData;
    final shipping = customer?.shippingAddress;

    final line1 = [
      shipping?.firstName ?? customer?.firstName ?? '',
      shipping?.lastName ?? customer?.lastName ?? '',
    ].where((part) => part.trim().isNotEmpty).join(' ').trim();

    final line2 = [
      shipping?.address1 ?? customer?.address1 ?? '',
      shipping?.address2 ?? customer?.address2 ?? '',
    ].where((part) => part.trim().isNotEmpty).join(', ').trim();

    final line3 = [
      shipping?.city ?? customer?.city ?? '',
      shipping?.state ?? customer?.state ?? '',
      shipping?.postcode ?? customer?.postcode ?? '',
      shipping?.country ?? customer?.country ?? '',
    ].where((part) => part.trim().isNotEmpty).join(', ').trim();

    final lines = [
      line1,
      line2,
      line3,
    ].where((line) => line.trim().isNotEmpty).toList();

    if (lines.isNotEmpty) {
      return lines;
    }
    final fallbackLine = fallback.trim();
    return fallbackLine.isEmpty ? const <String>[] : <String>[fallbackLine];
  }

  String _shippingDetailsText(
    OrderModel? order,
    double shippingValue,
    String currencyCode,
  ) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final option = order?.customerData?.shippingOption;
    final title = option?.title.trim() ?? '';
    final methodId = option?.methodId.trim() ?? '';
    final effectiveCost = (option?.cost ?? 0) > 0
        ? option!.cost
        : shippingValue;
    final costText = formatMoneyForDisplay(
      context,
      effectiveCost,
      currencyCode,
    );

    final firstLine = [
      if (title.isNotEmpty) title,
      if (methodId.isNotEmpty && methodId != title) methodId,
    ].join(' • ');

    if (firstLine.isNotEmpty) {
      return isArabic
          ? '$firstLine\nالتكلفة: $costText'
          : '$firstLine\nCost: $costText';
    }
    return isArabic ? 'التكلفة: $costText' : 'Cost: $costText';
  }

  Future<void> _loadMyReviewsByProduct(List<OrderItemModel> items) async {
    final userId = (await sl<SecureCacheHelper>().getData(key: 'id'))?.trim();
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        setState(() {
          _myReviewsByProduct = const <String, ReviewModel>{};
        });
      }
      return;
    }
    final productIds = items
        .map((item) => item.productId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (productIds.isEmpty) return;

    final map = <String, ReviewModel>{};
    for (final productId in productIds) {
      final result = await sl<HomeRepository>().getReviews(
        productId: productId,
        lang: '',
      );
      result.fold((_) {}, (reviews) {
        for (final review in reviews) {
          if (review.customerId.trim() == userId) {
            map[productId] = review;
            break;
          }
        }
      });
    }
    if (!mounted) return;
    setState(() {
      _myReviewsByProduct = map;
    });
  }

  String _indexLabelForItem(OrderItemModel item) {
    String category = '';
    try {
      final dynamic unsafeItem = item;
      category = (unsafeItem.categoryName ?? '').toString().trim();
    } catch (_) {
      category = '';
    }
    if (category.isNotEmpty) {
      return category;
    }

    for (final variation in item.variation) {
      final key = variation.attribute.trim().toLowerCase();
      final value = variation.value.trim();
      if (value.isEmpty) continue;
      if (key == 'category' || key.contains('category')) {
        return value;
      }
    }

    return 'Product';
  }

  bool _shouldShowReturnAction(String rawStatus) {
    final status = orderStatusFromRaw(rawStatus);
    return status == OrderStatus.delivered ||
        status == OrderStatus.returnRequested ||
        status == OrderStatus.returned ||
        _returnRequest != null;
  }

  String _returnActionLabel(String rawStatus) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final status = orderStatusFromRaw(rawStatus);
    if (_returnRequest != null ||
        status == OrderStatus.returnRequested ||
        status == OrderStatus.returned) {
      return isArabic ? 'تتبع الإرجاع' : 'Track Return';
    }
    return isArabic ? 'طلبات الإرجاع' : 'Return Requests';
  }

  void _openReturnFlow() {
    final order = _order;
    final firstItem = order?.items.isNotEmpty == true
        ? order!.items.first
        : null;
    GoRouter.of(context).push(
      AppRouter.trackReturnOrderScreen,
      extra: {
        'orderId': (order?.id ?? widget.numberOfOrder).trim(),
        'orderNumber': widget.numberOfOrder,
        'productTitle':
            firstItem?.title ??
            (Localizations.localeOf(context).languageCode == 'ar'
                ? 'عنصر الإرجاع'
                : 'Return item'),
        'productImage': firstItem?.image ?? '',
        'requestUuid': _returnRequest?.uuid,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _OrderDetailsShimmerBody();
    }

    final order = _order;
    final items = order?.items ?? widget.items;
    if (items.isEmpty) {
      return const _OrderDetailsShimmerBody();
    }

    final currencyCode = resolveCurrencyCode([
      order?.currencyCode,
      widget.currency,
    ]);
    final subtotalValue =
        order?.subTotal ?? (double.tryParse(widget.subTotalPrice) ?? 0);
    final totalValue =
        order?.total ?? (double.tryParse(widget.totalPrice) ?? 0);
    final shippingValue =
        order?.shippingCost ?? (double.tryParse(widget.shippingCost) ?? 0);
    final discountValue =
        order?.discount ?? (double.tryParse(widget.discount) ?? 0);
    final grandTotalValue = totalValue > 0
        ? totalValue
        : (subtotalValue + shippingValue - discountValue);
    final sharedVariationOrder = _sharedVariationOrder(items);
    final addressLines = _deliveryAddressLines(order, widget.shippingAddress);
    final shippingDetailsText = _shippingDetailsText(
      order,
      shippingValue,
      currencyCode,
    );
    final paymentMethod = (order?.paymentMethod ?? '').trim().isNotEmpty
        ? order!.paymentMethod.trim()
        : widget.paymentMethod.trim();
    final orderId = (order?.id ?? '').trim().isNotEmpty
        ? order!.id
        : widget.numberOfOrder;
    final orderStatusRaw = (order?.wcOrderStatus ?? order?.statusDisplay ?? '')
        .trim();
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    final orderStatusText = orderStatusLabelByLocale(
      orderStatusRaw,
      isArabic: isArabic,
    );
    final canReviewItems = _isReviewEligibleStatus(orderStatusRaw);
    final showReturnAction = _shouldShowReturnAction(orderStatusRaw);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            appBarHeight: 50.h,
            centerTitle: false,
            isShownDivider: false,
            isShoppingCartShown: false,
            isShownActions: false,
            title: Text(
              isArabic ? 'تفاصيل الطلب' : 'Order Details',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 20.sp,
                fontFamily: 'Montes',
                fontWeight: FontWeight.w500,
                height: 2,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 18.h)),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: _statusBackgroundColor(orderStatusRaw),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    orderStatusText,
                    style: TextStyle(
                      color: _statusTextColor(orderStatusRaw),
                      fontSize: 12.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 12.h)),
          if (showReturnAction)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              sliver: SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 14.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: ElevatedButton(
                      onPressed: _openReturnFlow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCB262E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        _returnActionLabel(orderStatusRaw),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'Montes',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFD8D8D8)),
                ),
                child: Column(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    final normalizedProductId = item.productId.trim();
                    final existingReview = normalizedProductId.isEmpty
                        ? null
                        : _myReviewsByProduct[normalizedProductId];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == items.length - 1 ? 0 : 16.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            onTap: () {
                              final slug = item.productSlug.trim();
                              GoRouter.of(context).push(
                                AppRouter.productDetails,
                                extra: {'id': item.productId, 'slug': slug},
                              );
                            },
                            child: CustomOrderDetails(
                              currency: currencyCode,
                              image: item.image,
                              title: item.title,
                              variations: item.variation,
                              alignedOptionOrder: sharedVariationOrder,
                              total: item.price.toString(),
                              quantity: item.quantity.toString(),
                              indexLabel: _indexLabelForItem(item),
                            ),
                          ),
                          if (canReviewItems &&
                              normalizedProductId.isNotEmpty) ...[
                            SizedBox(height: 10.h),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (dialogContext) =>
                                        BlocProvider.value(
                                          value: context
                                              .read<CreateReviewCubit>(),
                                          child: _OrderItemReviewDialog(
                                            productId: normalizedProductId,
                                            existingReview: existingReview,
                                            orderUuid: widget.numberOfOrder,
                                            onSaved: (saved) {
                                              if (!mounted) return;
                                              setState(() {
                                                _myReviewsByProduct = {
                                                  ..._myReviewsByProduct,
                                                  normalizedProductId: saved,
                                                };
                                              });
                                            },
                                          ),
                                        ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFCB262E),
                                  ),
                                  minimumSize: Size(0, 30.h),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 0,
                                  ),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: Text(
                                  existingReview == null
                                      ? (Localizations.localeOf(
                                                  context,
                                                ).languageCode ==
                                                'ar'
                                            ? 'إضافة تقييم'
                                            : 'Add Review')
                                      : (Localizations.localeOf(
                                                  context,
                                                ).languageCode ==
                                                'ar'
                                            ? 'تعديل التقييم'
                                            : 'Edit Review'),
                                  style: TextStyle(
                                    color: const Color(0xFFCB262E),
                                    fontSize: 11.sp,
                                    fontFamily: 'Montes',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 28.h)),
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24.w, 26.h, 24.w, 28.h),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: const Color(0xFFD8D8D8), width: 1.w),
                  bottom: BorderSide(
                    color: const Color(0xFFD8D8D8),
                    width: 1.w,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'ملخص الطلب'
                        : 'Order Summary',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  _OrderSummaryRow(
                    label: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'المجموع الفرعي'
                        : 'Subtotal',
                    value: formatMoneyForDisplay(
                      context,
                      subtotalValue,
                      currencyCode,
                    ),
                  ),
                  SizedBox(height: 26.h),
                  _OrderSummaryRow(
                    label: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'الخصم'
                        : 'Discount',
                    value: discountValue == 0
                        ? '-'
                        : formatMoneyForDisplay(
                            context,
                            discountValue,
                            currencyCode,
                          ),
                  ),
                  SizedBox(height: 26.h),
                  _OrderSummaryRow(
                    label: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'رسوم الشحن'
                        : 'Shipping Fee',
                    value: formatMoneyForDisplay(
                      context,
                      shippingValue,
                      currencyCode,
                    ),
                  ),
                  SizedBox(height: 34.h),
                  _OrderSummaryRow(
                    label: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'الإجمالي'
                        : 'Total',
                    value: formatMoneyForDisplay(
                      context,
                      grandTotalValue,
                      currencyCode,
                    ),
                    isEmphasized: true,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'عنوان التوصيل'
                        : 'Delivery Address',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 14.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    addressLines.isEmpty ? '-' : addressLines.join('\n'),
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 12.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'تفاصيل الشحن'
                        : 'Shipping Details',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 14.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    shippingDetailsText,
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 12.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  if (paymentMethod.isNotEmpty) ...[
                    Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'طريقة الدفع'
                          : 'Payment Method',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 14.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      paymentMethod,
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 18.h),
                  ],
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'تاريخ الطلب'
                        : 'Order Date',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 14.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _formatOrderDate(order?.createdAt ?? widget.orderDate),
                    style: TextStyle(
                      color: const Color(0xFF666666),
                      fontSize: 12.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  if ((order?.eta ?? '').trim().isNotEmpty) ...[
                    Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'التوصيل المتوقع'
                          : 'Estimated Delivery',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 14.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      order!.eta.trim(),
                      style: TextStyle(
                        color: const Color(0xFF666666),
                        fontSize: 12.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 18.h),
                  ],
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'رقم الطلب'
                        : 'Order ID',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 14.sp,
                      fontFamily: 'Montes',
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: const Color(0xFFE2E2E2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            orderId,
                            style: TextStyle(
                              color: AppColors.black,
                              fontSize: 13.sp,
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final id = orderId.trim();
                            if (id.isEmpty) return;
                            final isArabic =
                                Localizations.localeOf(
                                  context,
                                ).languageCode.toLowerCase() ==
                                'ar';
                            await Clipboard.setData(ClipboardData(text: id));
                            if (!mounted) return;
                            AppToast.show(
                              msg: isArabic
                                  ? 'تم نسخ رقم الطلب'
                                  : 'Order ID copied',
                              gravity: ToastGravity.TOP,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_rounded,
                                  size: 14.sp,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  Localizations.localeOf(
                                            context,
                                          ).languageCode ==
                                          'ar'
                                      ? 'نسخ'
                                      : 'Copy',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontFamily: 'Montes',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_errorMessage != null && _errorMessage!.trim().isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 16.h),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: const Color(0xFFB42318),
                    fontSize: 12.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderItemReviewDialog extends StatefulWidget {
  const _OrderItemReviewDialog({
    required this.productId,
    required this.onSaved,
    this.existingReview,
    this.orderUuid,
  });

  final String productId;
  final ReviewModel? existingReview;
  final String? orderUuid;
  final ValueChanged<ReviewModel> onSaved;

  @override
  State<_OrderItemReviewDialog> createState() => _OrderItemReviewDialogState();
}

class _OrderItemReviewDialogState extends State<_OrderItemReviewDialog> {
  double _rating = 5;
  late final TextEditingController _reviewController;
  final ImagePicker _picker = ImagePicker();
  final List<String> _imagePaths = <String>[];
  bool _isPickingMedia = false;
  String _inlineMessage = '';
  bool _inlineMessageIsError = false;

  @override
  void initState() {
    super.initState();
    _rating = (widget.existingReview?.rating ?? 5).toDouble();
    _reviewController = TextEditingController(
      text: widget.existingReview?.review ?? '',
    );
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
          source: source,
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
      if (!mounted) return;
      _showInlineFeedback(
        message: Localizations.localeOf(context).languageCode == 'ar'
            ? 'يرجى السماح بالوصول للكاميرا/الصور من إعدادات iOS.'
            : 'Please allow camera/photos access in iOS Settings.',
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;
      _showInlineFeedback(
        message: Localizations.localeOf(context).languageCode == 'ar'
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.86,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16.sp,
                        color: const Color(0xFF4A4A4A),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 82.w,
                      height: 82.w,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFCC1F2E),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 40.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'كيف كانت تجربتك؟'
                          : 'How was your experience?',
                      style: TextStyle(
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w500,
                        fontSize: 19.sp,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'يرجى إخبارنا كيف يمكننا التحسين عبر\nإضافة ملاحظاتك القيّمة.'
                          : 'Please let us know how we can improve this by\nadding your valuable feedback.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp,
                        color: const Color(0xFF2D2D2D),
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontFamily: 'Montes',
                            fontWeight: FontWeight.w500,
                            fontSize: 22.sp,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        ...List.generate(5, (index) {
                          final starValue = index + 1;
                          final isFilled = starValue <= _rating;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _rating = starValue.toDouble();
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 3.w),
                              child: Icon(
                                Icons.star_rounded,
                                color: isFilled
                                    ? const Color(0xFFF4C449)
                                    : const Color(0xFFE0E0E0),
                                size: 34.sp,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    SizedBox(height: 14.h),
                    Container(
                      width: 295.w,
                      height: 100.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      child: TextField(
                        controller: _reviewController,
                        minLines: 4,
                        maxLines: 7,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(fontFamily: 'Montes', fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText:
                              Localizations.localeOf(context).languageCode ==
                                  'ar'
                              ? 'أضف تقييمك للمنتج هنا.'
                              : 'Add your product review here.',
                          hintStyle: TextStyle(
                            fontFamily: 'Montes',
                            fontSize: 14.sp,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_imagePaths.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
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
                    SizedBox(
                      width: 295.w,
                      height: 52.h,
                      child: OutlinedButton(
                        onPressed: _isPickingMedia ? null : _onAddMediaTap,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCB262E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9.r),
                          ),
                        ),
                        child: Text(
                          _isPickingMedia
                              ? (Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? 'جارٍ الاختيار...'
                                    : 'Selecting...')
                              : (_imagePaths.isEmpty
                                    ? (Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ar'
                                          ? 'اختيار صورة'
                                          : 'Select Photo')
                                    : (Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ar'
                                          ? 'إدارة الصور'
                                          : 'Manage Photos')),
                          style: TextStyle(
                            color: const Color(0xFFCB262E),
                            fontFamily: 'Montes',
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    BlocConsumer<CreateReviewCubit, CreateReviewState>(
                      listener: (context, state) {
                        if (state is CreateReviewSuccess) {
                          final review = state.review;
                          if (review != null) {
                            widget.onSaved(review);
                            AppToast.show(
                              gravity: ToastGravity.TOP,
                              backgroundColor: Colors.green,
                              msg: state.isEdited
                                  ? (Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'ar'
                                        ? 'تم تحديث التقييم بنجاح'
                                        : 'Review updated successfully')
                                  : (Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'ar'
                                        ? 'تم إرسال التقييم بنجاح'
                                        : 'Review submitted successfully'),
                            );
                            Navigator.of(context).pop(review);
                            return;
                          }
                        }
                        if (state is CreateReviewError) {
                          AppToast.show(
                            gravity: ToastGravity.TOP,
                            backgroundColor: Colors.red,
                            msg: state.error.message,
                          );
                        }
                      },
                      builder: (context, state) {
                        return SizedBox(
                          width: 295.w,
                          height: 52.h,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFDF2130), Color(0xFFCB262E)],
                              ),
                              borderRadius: BorderRadius.circular(9.r),
                            ),
                            child: TextButton(
                              onPressed: state is CreateReviewLoading
                                  ? null
                                  : () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      final comment = _reviewController.text
                                          .trim();
                                      if (comment.isEmpty) {
                                        _showInlineFeedback(
                                          message:
                                              Localizations.localeOf(
                                                    context,
                                                  ).languageCode ==
                                                  'ar'
                                              ? 'يرجى إضافة تعليق التقييم'
                                              : 'Please add your review comment',
                                          isError: true,
                                        );
                                        return;
                                      }
                                      context
                                          .read<CreateReviewCubit>()
                                          .submitReview(
                                            productId: widget.productId.trim(),
                                            comment: comment,
                                            rating: _rating,
                                            existingReviewId:
                                                widget.existingReview?.id,
                                            imagePaths: List<String>.from(
                                              _imagePaths,
                                            ),
                                            orderUuid: widget.orderUuid?.trim(),
                                          );
                                    },
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9.r),
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
                                      widget.existingReview == null
                                          ? (Localizations.localeOf(
                                                      context,
                                                    ).languageCode ==
                                                    'ar'
                                                ? 'إرسال التقييم'
                                                : 'Submit Feedback')
                                          : (Localizations.localeOf(
                                                      context,
                                                    ).languageCode ==
                                                    'ar'
                                                ? 'تحديث التقييم'
                                                : 'Update Feedback'),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Montes',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewMediaSelectionDialog extends StatefulWidget {
  const _ReviewMediaSelectionDialog({required this.initialPaths});

  final List<String> initialPaths;

  @override
  State<_ReviewMediaSelectionDialog> createState() =>
      _ReviewMediaSelectionDialogState();
}

class _ReviewMediaSelectionDialogState
    extends State<_ReviewMediaSelectionDialog> {
  late List<String> _paths;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _paths = List<String>.from(widget.initialPaths);
  }

  Future<ImageSource?> _pickSource() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..removeCurrentSnackBar();
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

  Future<void> _addNewPath() async {
    try {
      if (_paths.length >= 5) {
        AppToast.show(
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          msg: Localizations.localeOf(context).languageCode == 'ar'
              ? 'يمكنك إضافة 5 صور كحد أقصى.'
              : 'You can add up to 5 images only.',
        );
        return;
      }
      final source = await _pickSource();
      if (!mounted || source == null) return;
      if (source == ImageSource.gallery) {
        final remainingSlots = 5 - _paths.length;
        final picked = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
        if (!mounted) return;
        if (picked.isEmpty) return;
        setState(() {
          for (final file in picked.take(remainingSlots)) {
            final path = file.path.trim();
            if (path.isNotEmpty) {
              _paths.add(path);
            }
          }
        });
        return;
      }

      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (!mounted) return;
      final path = file?.path.trim();
      if (path == null || path.isEmpty) return;
      setState(() {
        _paths.add(path);
      });
    } on PlatformException catch (_) {
      if (!mounted) return;
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: Localizations.localeOf(context).languageCode == 'ar'
            ? 'يرجى السماح بالوصول للكاميرا/الصور من إعدادات iOS.'
            : 'Please allow camera/photos access in iOS Settings.',
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: Localizations.localeOf(context).languageCode == 'ar'
            ? 'تعذر فتح اختيار الوسائط حالياً. يرجى المحاولة مرة أخرى.'
            : 'Unable to open media picker right now. Please try again.',
      );
    }
  }

  Future<void> _replaceAt(int index) async {
    try {
      final source = await _pickSource();
      if (!mounted || source == null) return;
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (!mounted) return;
      final path = file?.path.trim();
      if (path == null || path.isEmpty) return;
      setState(() {
        _paths[index] = path;
      });
    } on PlatformException catch (_) {
      if (!mounted) return;
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: Localizations.localeOf(context).languageCode == 'ar'
            ? 'يرجى السماح بالوصول للكاميرا/الصور من إعدادات iOS.'
            : 'Please allow camera/photos access in iOS Settings.',
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.show(
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        msg: Localizations.localeOf(context).languageCode == 'ar'
            ? 'تعذر فتح اختيار الوسائط حالياً. يرجى المحاولة مرة أخرى.'
            : 'Unable to open media picker right now. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 18.w),
      child: Container(
        width: 340.w,
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selected Photos',
              style: TextStyle(
                fontFamily: 'Montes',
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 10.h),
            if (_paths.isEmpty)
              Text(
                'No files selected yet.',
                style: TextStyle(
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w400,
                  fontSize: 12.sp,
                  color: Colors.grey.shade700,
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 180.h),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _paths.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (_, index) {
                    final path = _paths[index];
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44.w,
                            height: 44.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6.r),
                              color: Colors.white,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) {
                                return const Icon(
                                  Icons.image_not_supported_outlined,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              path,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Montes',
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          TextButton(
                            onPressed: () => _replaceAt(index),
                            child: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'تغيير'
                                  : 'Change',
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _paths.removeAt(index);
                              });
                            },
                            child: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'إزالة'
                                  : 'Remove',
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 12.h),
            OutlinedButton(
              onPressed: _addNewPath,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCB262E)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'اختيار صورة'
                    : 'Select Photo',
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'إلغاء'
                          : 'Cancel',
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_paths),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCB262E),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'تم'
                          : 'Done',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSummaryRow extends StatelessWidget {
  const _OrderSummaryRow({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final fontSize = isEmphasized ? 20.sp : 16.sp;
    final fontWeight = isEmphasized ? FontWeight.w700 : FontWeight.w400;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.black,
              fontSize: fontSize,
              fontFamily: 'Montes',
              fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w400,
              height: isEmphasized ? 1.2 : 1.3,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: AppColors.black,
            fontSize: fontSize,
            fontFamily: 'Montes',
            fontWeight: fontWeight,
            height: isEmphasized ? 1.2 : 1.3,
          ),
        ),
      ],
    );
  }
}

class _OrderDetailsShimmerBody extends StatelessWidget {
  const _OrderDetailsShimmerBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Shimmer.fromColors(
        baseColor: const Color(0xFFE6E6E6),
        highlightColor: const Color(0xFFF6F6F6),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  height: 24.h,
                  color: Colors.white,
                ),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: List.generate(3, (index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: index == 2 ? 0 : 16.h),
                        height: 126.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 28.h),
                Container(
                  width: double.infinity,
                  height: 240.h,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
