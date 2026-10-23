class TrackingResponse {
  final int statusCode;
  final bool success;
  final String message;
  final OrderData data;

  TrackingResponse({
    required this.statusCode,
    this.success = true,
    required this.message,
    required this.data,
  });

  factory TrackingResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawStages = rawData is List
        ? rawData
        : rawData is Map
        ? (rawData['getOrderTracking'] as List? ?? const <dynamic>[])
        : const <dynamic>[];
    final trackingStages = rawStages
        .map(
          (e) => TrackingStage.fromJson(
            (e as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
          ),
        )
        .toList();

    return TrackingResponse(
      statusCode: json['statusCode'] is num
          ? (json['statusCode'] as num).toInt()
          : int.tryParse(json['statusCode']?.toString() ?? '') ?? 0,
      success: json['success'] != false,
      message: json['message']?.toString() ?? '',
      data: trackingStages.isNotEmpty
          ? OrderData.fromTrackingStages(trackingStages)
          : OrderData.fromJson(
              (rawData as Map?)?.cast<String, dynamic>() ??
                  const <String, dynamic>{},
            ),
    );
  }
}

class OrderData {
  final int orderId;
  final String orderStatus;
  final bool hasFulfillmentTracking;
  final String trackingStage;
  final String trackingStatus;
  final String waybillNo;
  final List<dynamic> trackingItems;
  final List<TrackingStage> trackingStages;
  final int totalTracking;
  final Shipping shipping;
  final List<ShippingLine> shippingLines;

  OrderData({
    required this.orderId,
    required this.orderStatus,
    this.hasFulfillmentTracking = false,
    this.trackingStage = '',
    this.trackingStatus = '',
    this.waybillNo = '',
    required this.trackingItems,
    this.trackingStages = const [],
    required this.totalTracking,
    required this.shipping,
    required this.shippingLines,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      orderId: json['orderId'] is num
          ? (json['orderId'] as num).toInt()
          : int.tryParse(json['orderId']?.toString() ?? '') ?? 0,
      orderStatus: json['orderStatus']?.toString() ?? '',
      hasFulfillmentTracking: json['hasFulfillmentTracking'] == true,
      trackingStage: json['trackingStage']?.toString() ?? '',
      trackingStatus: json['trackingStatus']?.toString() ?? '',
      waybillNo: json['waybillNo']?.toString() ?? '',
      trackingItems: json['trackingItems'] ?? [],
      trackingStages: const [],
      totalTracking: json['totalTracking'] is num
          ? (json['totalTracking'] as num).toInt()
          : int.tryParse(json['totalTracking']?.toString() ?? '') ?? 0,
      shipping: Shipping.fromJson(
        (json['shipping'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      shippingLines: (json['shippingLines'] as List? ?? const [])
          .map(
            (e) => ShippingLine.fromJson(
              (e as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{},
            ),
          )
          .toList(),
    );
  }

  factory OrderData.fromTrackingStages(List<TrackingStage> stages) {
    final lastChecked = stages.lastWhere(
      (stage) => stage.checked,
      orElse: () => stages.isNotEmpty
          ? stages.first
          : const TrackingStage(
              id: 0,
              name: '',
              checked: false,
              metadata: TrackingStageMetadata(),
            ),
    );
    TrackingStage? dispatchingStage;
    for (final stage in stages) {
      if (stage.id == 6) {
        dispatchingStage = stage;
        break;
      }
    }

    return OrderData(
      orderId: 0,
      orderStatus: _statusForStage(lastChecked),
      hasFulfillmentTracking: stages.any(
        (stage) =>
            stage.metadata.trackingId != null &&
            stage.metadata.trackingId!.trim().isNotEmpty,
      ),
      trackingStage: '',
      trackingStatus: lastChecked.name,
      waybillNo: dispatchingStage?.metadata.trackingId ?? '',
      trackingItems: stages.map((stage) => stage.toJson()).toList(),
      trackingStages: stages,
      totalTracking: stages.length,
      shipping: Shipping.empty(),
      shippingLines: const [],
    );
  }

  static String _statusForStage(TrackingStage stage) {
    return switch (stage.id) {
      2 => 'payment_successful',
      3 => 'confirmed',
      4 || 5 => 'processing',
      6 => 'dispatched',
      7 || 8 => 'delivered',
      9 => 'cancelled',
      _ => 'pending',
    };
  }
}

class TrackingStage {
  final int id;
  final String name;
  final bool checked;
  final DateTime? date;
  final TrackingStageMetadata metadata;

  const TrackingStage({
    required this.id,
    required this.name,
    required this.checked,
    this.date,
    required this.metadata,
  });

  factory TrackingStage.fromJson(Map<String, dynamic> json) {
    return TrackingStage(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      checked: json['checked'] == true,
      date: _parseDate(json['date']?.toString()),
      metadata: TrackingStageMetadata.fromJson(
        (json['metadata'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'checked': checked,
    'date': date?.toIso8601String(),
    'metadata': metadata.toJson(),
  };

  static DateTime? _parseDate(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    if (parsed.isUtc) return parsed.toLocal();
    final hasExplicitTimezone = RegExp(
      r'(z|Z|[+-]\d{2}:\d{2})$',
    ).hasMatch(value);
    return hasExplicitTimezone ? parsed.toLocal() : parsed;
  }
}

class TrackingStageMetadata {
  final String? trackingId;
  final String? cancellationReason;
  final String? reviewText;
  final num? reviewRating;
  final Map<String, dynamic> raw;

  const TrackingStageMetadata({
    this.trackingId,
    this.cancellationReason,
    this.reviewText,
    this.reviewRating,
    this.raw = const <String, dynamic>{},
  });

  factory TrackingStageMetadata.fromJson(Map<String, dynamic> json) {
    return TrackingStageMetadata(
      trackingId: _nullableString(json['trackingId']),
      cancellationReason: _nullableString(json['cancellationReason']),
      reviewText: _nullableString(json['reviewText']),
      reviewRating: json['reviewRating'] is num
          ? json['reviewRating'] as num
          : num.tryParse(json['reviewRating']?.toString() ?? ''),
      raw: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => {
    ...raw,
    'trackingId': trackingId,
    'cancellationReason': cancellationReason,
    'reviewText': reviewText,
    'reviewRating': reviewRating,
  };

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty || text.toLowerCase() == 'null'
        ? null
        : text;
  }
}

class Shipping {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String phone;

  Shipping({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.phone,
  });

  factory Shipping.empty() {
    return Shipping(
      firstName: '',
      lastName: '',
      company: '',
      address1: '',
      address2: '',
      city: '',
      state: '',
      postcode: '',
      country: '',
      phone: '',
    );
  }

  factory Shipping.fromJson(Map<String, dynamic> json) {
    return Shipping(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      address1: json['address_1']?.toString() ?? '',
      address2: json['address_2']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postcode: json['postcode']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class ShippingLine {
  final int id;
  final String methodTitle;
  final String methodId;
  final String instanceId;
  final String total;
  final String totalTax;
  final List<dynamic> taxes;
  final String taxStatus;
  final List<dynamic> metaData;

  ShippingLine({
    required this.id,
    required this.methodTitle,
    required this.methodId,
    required this.instanceId,
    required this.total,
    required this.totalTax,
    required this.taxes,
    required this.taxStatus,
    required this.metaData,
  });

  factory ShippingLine.fromJson(Map<String, dynamic> json) {
    return ShippingLine(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      methodTitle: json['method_title']?.toString() ?? '',
      methodId: json['method_id']?.toString() ?? '',
      instanceId: json['instance_id']?.toString() ?? '',
      total: json['total']?.toString() ?? '',
      totalTax: json['total_tax']?.toString() ?? '',
      taxes: json['taxes'] ?? [],
      taxStatus: json['tax_status']?.toString() ?? '',
      metaData: json['meta_data'] ?? [],
    );
  }
}
