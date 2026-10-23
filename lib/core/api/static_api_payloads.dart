class StaticApiPayloads {
  static final DateTime _now = DateTime.now();

  static String get demoToken => 'static-demo-token';
  static String get demoUserId => 'static-demo-user';

  static Map<String, dynamic> authUser() => {
    'id': demoUserId,
    'email': 'demo@camion.app',
    'phone': '+97400000000',
    'fullName': 'Static Demo User',
    'isActive': true,
    'code': '1234',
    'role': 'user',
    'createdAt': _now.toIso8601String(),
    'updatedAt': _now.toIso8601String(),
  };

  static Map<String, dynamic> registerResponse() => {...authUser()};

  static Map<String, dynamic> verifyResponse() => {
    'accessToken': demoToken,
    'user': authUser(),
    'isFirstLogin': false,
  };

  static Map<String, dynamic> demoProduct({
    int id = 101,
    String? name,
    String? slug,
    String? image,
    bool onSale = true,
    String currentPrice = '149.00',
    String regularPrice = '199.00',
    String currencyCode = 'QAR',
    String currencySymbol = 'ر.ق',
  }) {
    final productName = name ?? 'Static Product $id';
    final productSlug = slug ?? 'static-product-$id';
    final imageUrl =
        image ??
        'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=900&q=80';
    return {
      'id': id,
      'name': productName,
      'slug': productSlug,
      'parent': 0,
      'type': 'simple',
      'variation': '',
      'permalink': 'https://camion-app.com/products/$productSlug',
      'sku': 'SKU-$id',
      'short_description': 'Static preview content for screen rendering.',
      'description':
          '<p>This product is served from static preview data so the UI stays accessible without backend dependencies.</p>',
      'on_sale': onSale,
      'prices': {
        'price': currentPrice,
        'regular_price': regularPrice,
        'sale_price': currentPrice,
        'currency_code': currencyCode,
        'currency_symbol': currencySymbol,
        'currency_minor_unit': 2,
        'currency_decimal_separator': '.',
        'currency_thousand_separator': ',',
        'currency_prefix': currencySymbol,
        'currency_suffix': '',
      },
      'price_html': '$currencySymbol$currentPrice',
      'average_rating': '4.7',
      'review_count': 12,
      'images': [
        {
          'id': id * 10,
          'src': imageUrl,
          'thumbnail': imageUrl,
          'srcset': '',
          'sizes': '',
          'name': productName,
          'alt': productName,
        },
      ],
      'categories': [
        {
          'id': 1,
          'name': 'Featured',
          'slug': 'featured',
          'description': 'Static featured category',
          'parent': 0,
          'count': 3,
          'image': {
            'id': 1,
            'src': imageUrl,
            'thumbnail': imageUrl,
            'srcset': '',
            'sizes': '',
            'name': 'Featured',
            'alt': 'Featured',
          },
          'review_count': 0,
          'permalink': 'https://camion-app.com/categories/featured',
        },
      ],
      'tags': [],
      'brands': [],
      'attributes': [],
      'variations': [],
      'has_options': false,
      'is_purchasable': true,
      'is_in_stock': true,
      'is_on_backorder': false,
      'stock_availability': {'text': 'In stock', 'class': 'in-stock'},
      'sold_individually': false,
      'add_to_cart': {
        'text': 'Add to cart',
        'description': 'Add to cart',
        'url': '',
        'single_text': 'Add to cart',
        'minimum': 1,
        'maximum': 99,
        'multiple_of': 1,
      },
      'cart': false,
      'wishlist': false,
    };
  }

  static List<Map<String, dynamic>> products() => [
    demoProduct(
      id: 101,
      name: 'Everyday Essentials Bag',
      slug: 'everyday-essentials-bag',
      image:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=80',
    ),
    demoProduct(
      id: 102,
      name: 'Minimal Travel Watch',
      slug: 'minimal-travel-watch',
      image:
          'https://images.unsplash.com/photo-1524805444758-089113d48a6d?auto=format&fit=crop&w=900&q=80',
      currentPrice: '249.00',
      regularPrice: '299.00',
    ),
    demoProduct(
      id: 103,
      name: 'Modern Street Sneakers',
      slug: 'modern-street-sneakers',
      image:
          'https://images.unsplash.com/photo-1549298916-b41d501d3772?auto=format&fit=crop&w=900&q=80',
      currentPrice: '189.00',
      regularPrice: '229.00',
    ),
  ];

  static List<Map<String, dynamic>> categories() => [
    {
      'id': 1,
      'name': 'Featured',
      'slug': 'featured',
      'description': 'Static preview category',
      'parent': 0,
      'count': 3,
      'image': {
        'id': 1,
        'src':
            'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=80',
        'thumbnail':
            'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=80',
        'srcset': '',
        'sizes': '',
        'name': 'Featured',
        'alt': 'Featured',
      },
      'review_count': 0,
      'permalink': 'https://camion-app.com/categories/featured',
    },
    {
      'id': 2,
      'name': 'New Arrivals',
      'slug': 'new-arrivals',
      'description': 'Static preview category',
      'parent': 0,
      'count': 3,
      'image': {
        'id': 2,
        'src':
            'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=900&q=80',
        'thumbnail':
            'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=900&q=80',
        'srcset': '',
        'sizes': '',
        'name': 'New Arrivals',
        'alt': 'New Arrivals',
      },
      'review_count': 0,
      'permalink': 'https://camion-app.com/categories/new-arrivals',
    },
  ];

  static List<Map<String, dynamic>> sliders() => [
    {
      'id': 1,
      'imageUrl':
          'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?auto=format&fit=crop&w=1200&q=80',
      'title': 'Static Preview',
      'description': 'Browse every screen without live storefront APIs.',
      'discount': '25%',
    },
  ];

  static List<Map<String, dynamic>> stories() => [
    {
      'id': 'story-1',
      'title': 'Preview Story',
      'description': 'Static story for UI rendering',
      'mediaUrl':
          'https://images.unsplash.com/photo-1491553895911-0055eca6402d?auto=format&fit=crop&w=1200&q=80',
      'mediaType': 'image',
      'duration': 5,
      'expiresAt': _now.add(const Duration(days: 7)).toIso8601String(),
      'createdAt': _now.toIso8601String(),
      'isActive': true,
    },
  ];

  static List<Map<String, dynamic>> reviews() => [
    {
      'id': 1,
      'date_created': _now.toIso8601String(),
      'formatted_date_created': 'Today',
      'date_created_gmt': _now.toUtc().toIso8601String(),
      'product_id': 101,
      'product_name': 'Everyday Essentials Bag',
      'product_permalink':
          'https://camion-app.com/products/everyday-essentials-bag',
      'product_image': {
        'id': 1,
        'src':
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=80',
        'thumbnail':
            'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=80',
        'srcset': '',
        'sizes': '',
        'name': 'Everyday Essentials Bag',
        'alt': 'Everyday Essentials Bag',
      },
      'reviewer': 'Preview User',
      'review': 'Static review content for layout validation.',
      'rating': 5,
      'verified': true,
      'reviewer_avatar_urls': {'24': '', '48': '', '96': ''},
    },
  ];

  static List<Map<String, dynamic>> cartItems() => [
    {
      'id': 'cart-1',
      'userId': demoUserId,
      'productId': '101',
      'quantity': 1,
      'variation': [],
      'title': 'Everyday Essentials Bag',
      'image':
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=80',
      'price': '149.00',
      'couponCode': null,
      'discountPercentage': 0,
      'createdAt': _now.toIso8601String(),
      'updatedAt': _now.toIso8601String(),
      'totalPrice': 149.00,
    },
  ];

  static Map<String, dynamic> shippingAddress() => {
    'first_name': 'Static',
    'last_name': 'User',
    'email': 'demo@camion.app',
    'phone': '+97400000000',
    'address_1': 'Preview Street 1',
    'address_2': 'Apartment 2',
    'city': 'Doha',
    'state': 'Doha',
    'postcode': '00000',
    'country': 'QA',
    'shipping_address': {
      'first_name': 'Static',
      'last_name': 'User',
      'email': 'demo@camion.app',
      'phone': '+97400000000',
      'address_1': 'Preview Street 1',
      'address_2': 'Apartment 2',
      'city': 'Doha',
      'state': 'Doha',
      'postcode': '00000',
      'country': 'QA',
    },
    'shipping_option': {
      'method_id': 'flat_rate',
      'title': 'Shipping',
      'cost': '20.00',
    },
  };

  static List<Map<String, dynamic>> orders() => [
    {
      'id': 'order-1',
      'wcOrderId': '5001',
      'userId': demoUserId,
      'wcOrderStatus': 'processing',
      'wcPaymentStatus': 'pending',
      'wcOrderKey': 'wc_order_static',
      'payment_method': 'cod',
      'skipCashPaymentUrl': '',
      'skipCashTransactionId': '',
      'customerName': 'Static Demo User',
      'customerEmail': 'demo@camion.app',
      'customerPhone': '+97400000000',
      'itemsCount': 1,
      'trackingUrl': 'https://example.com/tracking/static',
      'statusDisplay': 'Processing',
      'currency': 'QAR',
      'netTotal': 149.0,
      'discount': 0.0,
      'shippingCost': 20.0,
      'grandTotal': 169.0,
      'total': 169.0,
      'couponCode': null,
      'items': cartItems(),
      'customer_data': shippingAddress(),
      'createdAt': _now.toIso8601String(),
      'paidAt': null,
      'deliveredAt': null,
      'isPaid': false,
      'isDelivered': false,
    },
  ];

  static Map<String, dynamic> createOrderResponse() => {
    'status': 200,
    'message': 'Static order preview created',
    'data': {
      'sessionId': 'static-session',
      'orderId': 'order-1',
      'order': {
        'id': 'order-1',
        'wcOrderId': 5001,
        'wcOrderKey': 'wc_order_static',
        'wcOrderStatus': 'processing',
        'wcPaymentStatus': 'pending',
        'currency': 'QAR',
        'total': '169.00',
        'userId': demoUserId,
        'items': cartItems(),
        'customerData': shippingAddress(),
        'paymentMethod': 'cod',
        'paymentData': [],
        'trackingUrl': 'https://example.com/tracking/static',
        'isPaid': false,
        'paidAt': null,
        'isDelivered': false,
        'deliveredAt': null,
        'skipCashPaymentUrl': '',
        'createdAt': _now.toIso8601String(),
        'updatedAt': _now.toIso8601String(),
      },
    },
  };

  static Map<String, dynamic> trackingResponse() => {
    'success': true,
    'message': 'Order statuses fetched successfully',
    'data': [
      _trackingStage(1, 'Order Placed', true, _now),
      _trackingStage(2, 'Payment Confirmed', true, _now.add(_minutes(1))),
      _trackingStage(3, 'Order Confirmed', true, _now.add(_minutes(5))),
      _trackingStage(4, 'Processing', true, _now.add(_minutes(60))),
      _trackingStage(5, 'Packing', false, null),
      _trackingStage(6, 'Dispatching', false, null),
      _trackingStage(7, 'Order Delivered', false, null),
      _trackingStage(8, 'Order Review', false, null),
      _trackingStage(9, 'Order Cancelled', false, null),
    ],
  };

  static Duration _minutes(int value) => Duration(minutes: value);

  static Map<String, dynamic> _trackingStage(
    int id,
    String name,
    bool checked,
    DateTime? date, {
    String? trackingId,
    String? cancellationReason,
    String? reviewText,
    num? reviewRating,
  }) => {
    'id': id,
    'name': name,
    'checked': checked,
    'date': date?.toUtc().toIso8601String(),
    'metadata': {
      'trackingId': trackingId,
      'cancellationReason': cancellationReason,
      'reviewText': reviewText,
      'reviewRating': reviewRating,
    },
  };

  static List<Map<String, dynamic>> wishlist() => [
    {
      'id': 'wish-1',
      'userId': demoUserId,
      'productId': '102',
      'productName': 'Minimal Travel Watch',
      'productImage':
          'https://images.unsplash.com/photo-1524805444758-089113d48a6d?auto=format&fit=crop&w=900&q=80',
      'price': '249.00',
    },
  ];

  static List<Map<String, dynamic>> notifications() => [
    {
      'id': 'notification-1',
      'userId': demoUserId,
      'title': 'Static preview mode',
      'body': 'This screen is rendering from mock data.',
      'data': null,
      'isRead': false,
      'createdAt': _now.toIso8601String(),
    },
  ];

  static List<Map<String, dynamic>> currencies() => [
    {'code': 'QAR', 'symbol': 'ر.ق', 'name': 'Qatari Riyal'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'SAR', 'symbol': 'ر.س', 'name': 'Saudi Riyal'},
  ];

  static Map<String, dynamic> userProfile() => {
    'id': demoUserId,
    'email': 'demo@camion.app',
    'phone': '+97400000000',
    'password': null,
    'fullName': 'Static Demo User',
    'isActive': true,
    'code': '1234',
    'role': 'user',
    'notificationToken': '',
    'createdAt': _now.toIso8601String(),
    'updatedAt': _now.toIso8601String(),
  };

  static List<Map<String, dynamic>> transactions() => [
    {
      'id': 'txn-1',
      'amount': 120.0,
      'description': 'Static wallet preview entry',
      'createdAt': _now.toIso8601String(),
    },
  ];

  static Map<String, dynamic> wallet() => {'balance': 120.0, 'currency': 'QAR'};

  static Map<String, dynamic> affiliateProfile({
    String id = 'affiliate-1',
    String type = 'affiliate',
    String status = 'approved',
  }) => {
    'id': id,
    'userId': demoUserId,
    'fullName': 'Static Demo User',
    'gender': 'male',
    'nationality': 'Qatar',
    'status': status,
    'totalEarnings': 120,
    'couponsCreated': 2,
    'bio': 'Static preview profile for dashboard rendering.',
    'referralLink': 'https://camion-app.com/ref/static-demo',
    'createdAt': _now.toIso8601String(),
    'updatedAt': _now.toIso8601String(),
    'type': type,
    'walletBalance': 120.0,
  };

  static Map<String, dynamic> affiliateStatus({
    String affiliateId = 'affiliate-1',
    String status = 'approved',
  }) => {
    'affiliateId': affiliateId,
    'fullName': 'Static Demo User',
    'status': status,
    'token': demoToken,
  };

  static List<Map<String, dynamic>> affiliateCoupons({
    String type = 'affiliate',
  }) => [
    {
      'id': 'coupon-1',
      'code': type == 'influencer' ? 'INFLUENCE10' : 'AFFILIATE10',
      'isActive': true,
      'affiliate': affiliateProfile(
        id: type == 'influencer' ? 'influencer-1' : 'affiliate-1',
        type: type,
      ),
      'discountPercentage': 10.0,
      'commissionPercentage': 5.0,
      'createdAt': _now.toIso8601String(),
      'orders': [
        {
          'orderId': 'order-1',
          'wcOrderId': '5001',
          'userId': demoUserId,
          'buyerName': 'Preview Buyer',
          'buyerEmail': 'buyer@example.com',
          'products': [
            {
              'productId': '101',
              'productName': 'Everyday Essentials Bag',
              'quantity': 1,
              'price': 149.0,
              'image':
                  'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=80',
            },
          ],
          'commission': 7.45,
          'total': 149.0,
          'createdAt': _now.toIso8601String(),
        },
      ],
    },
  ];

  static Map<String, dynamic> chatbotSession() => {
    'sessionUUID': 'static-chat-session',
  };

  static Map<String, dynamic> chatbotHistory() => {
    'sessionUUID': 'static-chat-session',
    'messages': [
      {
        'id': 'm1',
        'role': 'assistant',
        'content': 'This is a static chatbot preview.',
        'createdAt': _now.toIso8601String(),
      },
    ],
  };

  static Map<String, dynamic> chatbotAnswer() => {
    'answer': 'Static preview mode is active, so this response is mocked.',
    'sources': [],
    'products': [],
    'sessionUUID': 'static-chat-session',
  };

  static Map<String, dynamic> genericSuccess([
    String message = 'Static action completed',
  ]) => {'success': true, 'message': message};
}
