import 'package:intl/intl.dart';

enum OrderStatus {
  pending,
  confirmed,
  dispatched,
  cancelled,
  delivered,
  returnRequested,
  returned,
  paymentPending,
  paymentSuccessful,
  paymentRejected,
  unknown,
}

OrderStatus orderStatusFromRaw(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'pending':
      return OrderStatus.pending;
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'dispatched':
    case 'shipped':
    case 'order_shipped':
      return OrderStatus.dispatched;
    case 'cancelled':
      return OrderStatus.cancelled;
    case 'delivered':
    case 'completed':
      return OrderStatus.delivered;
    case 'return_requested':
    case 'return requested':
    case 'return-requested':
      return OrderStatus.returnRequested;
    case 'returned':
      return OrderStatus.returned;
    case 'payment_pending':
      return OrderStatus.paymentPending;
    case 'payment_successful':
    case 'payment success':
    case 'paymentsuccess':
      return OrderStatus.paymentSuccessful;
    case 'payment_rejected':
    case 'failed':
    case 'payment failed':
    case 'payment_failed':
      return OrderStatus.paymentRejected;
    default:
      return OrderStatus.unknown;
  }
}

String orderStatusLabel(String raw) {
  final isArabic = Intl.getCurrentLocale().toLowerCase().startsWith('ar');
  return orderStatusLabelByLocale(raw, isArabic: isArabic);
}

String orderStatusLabelByLocale(String raw, {required bool isArabic}) {
  switch (orderStatusFromRaw(raw)) {
    case OrderStatus.pending:
      return isArabic ? 'قيد الانتظار' : 'Pending';
    case OrderStatus.confirmed:
      return isArabic ? 'مؤكد' : 'Confirmed';
    case OrderStatus.dispatched:
      return isArabic ? 'تم الشحن' : 'Dispatched';
    case OrderStatus.cancelled:
      return isArabic ? 'ملغي' : 'Cancelled';
    case OrderStatus.delivered:
      return isArabic ? 'تم التسليم' : 'Delivered';
    case OrderStatus.returnRequested:
      return isArabic ? 'تم طلب الإرجاع' : 'Return Requested';
    case OrderStatus.returned:
      return isArabic ? 'تم الإرجاع' : 'Returned';
    case OrderStatus.paymentPending:
      return isArabic ? 'الدفع قيد الانتظار' : 'Payment Pending';
    case OrderStatus.paymentSuccessful:
      return isArabic ? 'تم الدفع بنجاح' : 'Payment Successful';
    case OrderStatus.paymentRejected:
      return isArabic ? 'تم رفض الدفع' : 'Payment Rejected';
    case OrderStatus.unknown:
      return _humanizeRawStatus(raw, isArabic: isArabic);
  }
}

String _humanizeRawStatus(String raw, {required bool isArabic}) {
  final normalized = raw.trim();
  if (normalized.isEmpty) {
    return isArabic ? 'قيد المعالجة' : 'In Progress';
  }
  if (isArabic) {
    final lowered = normalized.toLowerCase();
    if (lowered == 'unknown') return 'غير معروف';
    if (lowered == 'in progress') return 'قيد المعالجة';
  }
  final words = normalized
      .replaceAll(RegExp(r'[_\-\s]+'), ' ')
      .split(' ')
      .where((word) => word.trim().isNotEmpty)
      .map((word) {
        final lower = word.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .toList();
  if (words.isEmpty) {
    return isArabic ? 'قيد المعالجة' : 'In Progress';
  }
  return words.join(' ');
}

bool isDeliveredLikeStatus(String raw) {
  final status = orderStatusFromRaw(raw);
  return status == OrderStatus.delivered ||
      status == OrderStatus.returnRequested ||
      status == OrderStatus.returned ||
      status == OrderStatus.paymentSuccessful;
}

bool isCancelableOrderStatus(String raw) {
  final status = orderStatusFromRaw(raw);
  return status == OrderStatus.pending || status == OrderStatus.paymentPending;
}
