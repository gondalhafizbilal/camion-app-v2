import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/image_url_transformer.dart';
import 'package:camion/features/home/data/models/slider_items/slider_item_model.dart';
import 'package:camion/features/home/data/models/stories_model.dart/stories_model.dart';

enum HomeProductSectionType {
  allProducts,
  featuredProducts,
  popularProducts,
  recentlyViewed,
}

class HomeGraphqlCustomer {
  const HomeGraphqlCustomer({
    required this.uuid,
    required this.fullName,
    required this.emailAddress,
    required this.phoneNumber,
    required this.unreadNotificationCount,
  });

  final String uuid;
  final String fullName;
  final String emailAddress;
  final String phoneNumber;
  final int unreadNotificationCount;

  factory HomeGraphqlCustomer.fromJson(Map<String, dynamic> json) {
    return HomeGraphqlCustomer(
      uuid: json['uuid']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      emailAddress: json['emailAddress']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      unreadNotificationCount:
          (json['unreadNotificationCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeGraphqlCustomerAddress {
  const HomeGraphqlCustomerAddress({
    required this.uuid,
    required this.fullName,
    required this.countryCode,
    required this.phoneNumber,
    required this.streetAddress,
    required this.apartment,
    required this.zipCode,
    required this.city,
    required this.state,
    required this.country,
    required this.isDefault,
  });

  final String uuid;
  final String fullName;
  final String countryCode;
  final String phoneNumber;
  final String streetAddress;
  final String apartment;
  final String zipCode;
  final String city;
  final String state;
  final String country;
  final bool isDefault;

  factory HomeGraphqlCustomerAddress.fromJson(Map<String, dynamic> json) {
    return HomeGraphqlCustomerAddress(
      uuid: json['uuid']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      countryCode: json['countryCode']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      streetAddress: json['streetAddress']?.toString() ?? '',
      apartment: json['apartment']?.toString() ?? '',
      zipCode: json['zipCode']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      isDefault: _toBool(json['isDefault']),
    );
  }
}

class HomeGraphqlProductReview {
  const HomeGraphqlProductReview({
    required this.uuid,
    required this.rating,
    required this.comment,
    required this.customer,
    required this.images,
  });

  final String uuid;
  final num rating;
  final String comment;
  final HomeGraphqlCustomer? customer;
  final List<HomeGraphqlProductReviewImage> images;

  factory HomeGraphqlProductReview.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'];
    final images = (json['images'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HomeGraphqlProductReviewImage.fromJson)
        .toList();
    return HomeGraphqlProductReview(
      uuid: json['uuid']?.toString() ?? '',
      rating: json['rating'] is num ? json['rating'] as num : 0,
      comment: json['comment']?.toString() ?? '',
      customer: customerJson is Map<String, dynamic>
          ? HomeGraphqlCustomer.fromJson(customerJson)
          : null,
      images: images,
    );
  }
}

class HomeGraphqlProductReviewImage {
  const HomeGraphqlProductReviewImage({
    required this.uuid,
    required this.thumbnailUrl,
    required this.imageUrl,
  });

  final String uuid;
  final String thumbnailUrl;
  final String imageUrl;

  String get bestUrl {
    final thumb = thumbnailUrl.trim();
    if (thumb.isNotEmpty) return thumb;
    return imageUrl.trim();
  }

  factory HomeGraphqlProductReviewImage.fromJson(Map<String, dynamic> json) {
    return HomeGraphqlProductReviewImage(
      uuid: json['uuid']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}

class HomeGraphqlProductAttachment {
  const HomeGraphqlProductAttachment({
    required this.uuid,
    required this.mediaUrl,
    required this.mediaType,
  });

  final String uuid;
  final String mediaUrl;
  final String mediaType;

  bool get hasMedia => mediaUrl.trim().isNotEmpty;

  bool get isVideo {
    final type = mediaType.trim().toLowerCase();
    final url = mediaUrl.trim().toLowerCase();
    return type == 'video' ||
        type.startsWith('video/') ||
        url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.m4v') ||
        url.endsWith('.webm');
  }

  factory HomeGraphqlProductAttachment.fromJson(Map<String, dynamic> json) {
    return HomeGraphqlProductAttachment(
      uuid: json['uuid']?.toString() ?? '',
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? '',
    );
  }
}

class HomeGraphqlProductCampaign {
  const HomeGraphqlProductCampaign({
    required this.uuid,
    required this.name,
    required this.brief,
    required this.slug,
    required this.discountPercentage,
    required this.startsAt,
    required this.finishesAt,
  });

  final String uuid;
  final String name;
  final String brief;
  final String slug;
  final num discountPercentage;
  final DateTime? startsAt;
  final DateTime? finishesAt;

  factory HomeGraphqlProductCampaign.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      final value = raw?.toString().trim() ?? '';
      if (value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return HomeGraphqlProductCampaign(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brief: json['brief']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      discountPercentage: _toNum(json['discountPercentage']),
      startsAt: parseDate(json['startsAt']),
      finishesAt: parseDate(json['finishesAt']),
    );
  }
}

class HomeGraphqlLanguage {
  const HomeGraphqlLanguage({
    required this.uuid,
    required this.name,
    required this.shortCode,
  });

  final String uuid;
  final String name;
  final String shortCode;

  factory HomeGraphqlLanguage.fromJson(Map<String, dynamic> json) {
    return HomeGraphqlLanguage(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortCode: json['shortCode']?.toString().toLowerCase().trim() ?? '',
    );
  }
}

class HomeGraphqlCurrency {
  const HomeGraphqlCurrency({
    required this.uuid,
    required this.name,
    required this.alphaCode,
  });

  final String uuid;
  final String name;
  final String alphaCode;

  factory HomeGraphqlCurrency.fromJson(Map<String, dynamic> json) {
    return HomeGraphqlCurrency(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      alphaCode: json['alphaCode']?.toString().toUpperCase().trim() ?? '',
    );
  }
}

class HomeGraphqlProductOptionValue {
  const HomeGraphqlProductOptionValue({
    required this.uuid,
    required this.value,
    required this.position,
  });

  final String uuid;
  final String value;
  final int position;

  factory HomeGraphqlProductOptionValue.fromJson(Map<String, dynamic> json) {
    return HomeGraphqlProductOptionValue(
      uuid: json['uuid']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      position: _toInt(json['position']),
    );
  }
}

class HomeGraphqlProductOption {
  const HomeGraphqlProductOption({
    required this.uuid,
    required this.name,
    required this.position,
    required this.values,
  });

  final String uuid;
  final String name;
  final int position;
  final List<HomeGraphqlProductOptionValue> values;

  factory HomeGraphqlProductOption.fromJson(Map<String, dynamic> json) {
    final values = (json['values'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HomeGraphqlProductOptionValue.fromJson)
        .toList();

    return HomeGraphqlProductOption(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      position: _toInt(json['position']),
      values: values,
    );
  }
}

class HomeGraphqlMoney {
  const HomeGraphqlMoney({
    required this.amount,
    required this.minorAmount,
    required this.currencyCode,
  });

  final num amount;
  final num minorAmount;
  final String currencyCode;

  double get decimalAmount => amount.toDouble() + (minorAmount.toDouble() / 100);

  factory HomeGraphqlMoney.fromJson(Map<String, dynamic> json) {
    return HomeGraphqlMoney(
      amount: _toNum(json['amount']),
      minorAmount: _toNum(json['minorAmount']),
      currencyCode: json['currencyCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'minorAmount': minorAmount,
      'currencyCode': currencyCode,
    };
  }
}

class HomeGraphqlMeasure {
  const HomeGraphqlMeasure({required this.amount, required this.unit});

  final num amount;
  final String unit;

  factory HomeGraphqlMeasure.fromJson(Map<String, dynamic> json) {
    return HomeGraphqlMeasure(
      amount: json['amount'] is num ? json['amount'] as num : 0,
      unit: json['unit']?.toString() ?? '',
    );
  }
}

class HomeGraphqlDimensions {
  const HomeGraphqlDimensions({
    required this.width,
    required this.height,
    required this.length,
    required this.unit,
  });

  final num width;
  final num height;
  final num length;
  final String unit;

  factory HomeGraphqlDimensions.fromJson(Map<String, dynamic> json) {
    return HomeGraphqlDimensions(
      width: json['width'] is num ? json['width'] as num : 0,
      height: json['height'] is num ? json['height'] as num : 0,
      length: json['length'] is num ? json['length'] as num : 0,
      unit: json['unit']?.toString() ?? '',
    );
  }
}

class HomeGraphqlVariantOptionValueRef {
  const HomeGraphqlVariantOptionValueRef({required this.optionValueUuid});

  final String optionValueUuid;

  factory HomeGraphqlVariantOptionValueRef.fromJson(Map<String, dynamic> json) {
    final optionValue = json['optionValue'];
    return HomeGraphqlVariantOptionValueRef(
      optionValueUuid: optionValue is Map<String, dynamic>
          ? optionValue['uuid']?.toString() ?? ''
          : '',
    );
  }
}

class HomeGraphqlVariantImage {
  const HomeGraphqlVariantImage({
    required this.uuid,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.alt,
    required this.isFeatured,
    required this.position,
  });

  final String uuid;
  final String imageUrl;
  final String thumbnailUrl;
  final String alt;
  final bool isFeatured;
  final int position;

  String get bestUrl {
    final thumb = thumbnailUrl.trim();
    if (thumb.isNotEmpty) return thumb;
    return imageUrl.trim();
  }

  factory HomeGraphqlVariantImage.fromJson(Map<String, dynamic> json) {
    return HomeGraphqlVariantImage(
      uuid: json['uuid']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      alt: json['alt']?.toString() ?? '',
      isFeatured: _toBool(json['isFeatured']),
      position: _toInt(json['position']),
    );
  }
}

class HomeGraphqlProductVariant {
  const HomeGraphqlProductVariant({
    required this.uuid,
    required this.title,
    required this.sku,
    required this.barcode,
    required this.price,
    required this.discountedPrice,
    required this.weight,
    required this.dimensions,
    required this.optionValues,
    required this.images,
  });

  final String uuid;
  final String title;
  final String sku;
  final String barcode;
  final HomeGraphqlMoney? price;
  final HomeGraphqlMoney? discountedPrice;
  final HomeGraphqlMeasure? weight;
  final HomeGraphqlDimensions? dimensions;
  final List<HomeGraphqlVariantOptionValueRef> optionValues;
  final List<HomeGraphqlVariantImage> images;

  num get regularAmount => price?.decimalAmount ?? 0;
  num get discountedAmount => discountedPrice?.decimalAmount ?? 0;

  bool get hasValidRegularPrice => regularAmount > 0;
  bool get hasValidDiscountedPrice =>
      discountedPrice != null && discountedAmount > 0;

  bool get hasDisplayablePrice =>
      hasValidRegularPrice || hasValidDiscountedPrice;

  bool get hasDisplayDiscount =>
      hasValidRegularPrice &&
      hasValidDiscountedPrice &&
      discountedAmount != regularAmount;

  num get displayPriceAmount {
    if (hasDisplayDiscount) return discountedAmount;
    if (hasValidRegularPrice) return regularAmount;
    if (hasValidDiscountedPrice) return discountedAmount;
    return 0;
  }

  String get bestImageUrl {
    if (images.isEmpty) return '';

    final featured =
        images
            .where((image) => image.isFeatured && image.bestUrl.isNotEmpty)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    if (featured.isNotEmpty) {
      return featured.first.bestUrl;
    }

    final sorted = images.where((image) => image.bestUrl.isNotEmpty).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    if (sorted.isEmpty) return '';
    return sorted.first.bestUrl;
  }

  factory HomeGraphqlProductVariant.fromJson(Map<String, dynamic> json) {
    final priceJson = json['price'];
    final discountedPriceJson = json['discountedPrice'];
    final weightJson = json['weight'];
    final dimensionsJson = json['dimensions'];
    final optionValues = (json['optionValues'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HomeGraphqlVariantOptionValueRef.fromJson)
        .toList();
    final images = (json['images'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HomeGraphqlVariantImage.fromJson)
        .toList();

    return HomeGraphqlProductVariant(
      uuid: json['uuid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
      price: priceJson is Map<String, dynamic>
          ? HomeGraphqlMoney.fromJson(priceJson)
          : null,
      discountedPrice: discountedPriceJson is Map<String, dynamic>
          ? HomeGraphqlMoney.fromJson(discountedPriceJson)
          : null,
      weight: weightJson is Map<String, dynamic>
          ? HomeGraphqlMeasure.fromJson(weightJson)
          : null,
      dimensions: dimensionsJson is Map<String, dynamic>
          ? HomeGraphqlDimensions.fromJson(dimensionsJson)
          : null,
      optionValues: optionValues,
      images: images,
    );
  }
}

class HomeGraphqlProduct {
  HomeGraphqlProduct({
    required this.uuid,
    required this.slug,
    required this.title,
    required this.brief,
    required this.description,
    this.descriptionHtml = '',
    this.sizechartUrl = '',
    required this.status,
    this.salesCount = 0,
    this.likesCount = 0,
    this.reviewsCountValue = 0,
    this.ratingAvgValue = 0,
    this.ratingOneStarCount = 0,
    this.ratingTwoStarCount = 0,
    this.ratingThreeStarCount = 0,
    this.ratingFourStarCount = 0,
    this.ratingFiveStarCount = 0,
    this.categoryNames = const [],
    this.options = const [],
    this.variants = const [],
    this.reviews = const [],
    this.attachments = const [],
    this.priceAmount = 0,
    this.originalPriceAmount = 0,
    this.currencyCode = '',
    this.variantUuid,
    this.featuredThumbnailUrl = '',
    this.featuredImageUrl = '',
    this.campaign,
  });

  final String uuid;
  final String slug;
  final String title;
  final String brief;
  final String description;
  final String descriptionHtml;
  final String sizechartUrl;
  final String status;
  final int salesCount;
  final int likesCount;
  final int reviewsCountValue;
  final double ratingAvgValue;
  final int ratingOneStarCount;
  final int ratingTwoStarCount;
  final int ratingThreeStarCount;
  final int ratingFourStarCount;
  final int ratingFiveStarCount;
  final List<String> categoryNames;
  final List<HomeGraphqlProductOption> options;
  final List<HomeGraphqlProductVariant> variants;
  final List<HomeGraphqlProductReview> reviews;
  final List<HomeGraphqlProductAttachment> attachments;

  // Keep these computed fields for existing UI/widgets.
  final num priceAmount;
  final num originalPriceAmount;
  final String currencyCode;
  final String? variantUuid;
  final String featuredThumbnailUrl;
  final String featuredImageUrl;
  final HomeGraphqlProductCampaign? campaign;

  HomeGraphqlProductVariant? get preferredPricingVariant {
    return _resolvePreferredPricingVariant(variants);
  }

  String get primaryVariantImageUrl {
    final featuredThumb = featuredThumbnailUrl.trim();
    if (featuredThumb.isNotEmpty) {
      return featuredThumb;
    }
    final featuredImage = featuredImageUrl.trim();
    if (featuredImage.isNotEmpty) {
      return featuredImage;
    }

    final preferred = preferredPricingVariant;
    final sourceVariants = <HomeGraphqlProductVariant>[
      if (preferred != null) preferred,
      ...variants.where(
        (variant) => preferred == null || variant.uuid != preferred.uuid,
      ),
    ];
    for (final variant in sourceVariants) {
      final url = variant.bestImageUrl;
      if (url.isNotEmpty) {
        return url;
      }
    }
    return '';
  }

  String get formattedPrice =>
      priceAmount > 0 ? priceAmount.toStringAsFixed(2) : '';

  String get formattedOriginalPrice {
    if (!hasDiscount) {
      return '';
    }
    return originalPriceAmount.toStringAsFixed(2);
  }

  bool get hasDiscount =>
      originalPriceAmount > 0 &&
      priceAmount > 0 &&
      priceAmount != originalPriceAmount;

  List<HomeGraphqlProductVariant> get displayableVariants =>
      variants.where((variant) => variant.hasDisplayablePrice).toList();

  String get formattedCurrencyCode {
    return resolveCurrencyCode([currencyCode]);
  }

  int get reviewsCount => reviewsCountValue < 0 ? 0 : reviewsCountValue;

  double get averageRatingValue => ratingAvgValue < 0 ? 0 : ratingAvgValue;

  String get averageRatingText => averageRatingValue.toStringAsFixed(1);

  static HomeGraphqlProductVariant? _resolvePreferredPricingVariant(
    List<HomeGraphqlProductVariant> variants,
  ) {
    final firstDiscountedVariant = variants
        .where((variant) => variant.hasDisplayDiscount)
        .cast<HomeGraphqlProductVariant?>()
        .firstWhere((variant) => variant != null, orElse: () => null);
    if (firstDiscountedVariant != null) {
      return firstDiscountedVariant;
    }

    return variants
        .where((variant) => variant.hasDisplayablePrice)
        .cast<HomeGraphqlProductVariant?>()
        .firstWhere((variant) => variant != null, orElse: () => null);
  }

  factory HomeGraphqlProduct.fromJson(Map<String, dynamic> json) {
    final variants = (json['variants'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HomeGraphqlProductVariant.fromJson)
        .toList();
    final options = (json['options'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HomeGraphqlProductOption.fromJson)
        .toList();
    final categoryNames =
        (json['productCategories'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((entry) => entry['category'])
            .whereType<Map<String, dynamic>>()
            .map((category) => category['name']?.toString().trim() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
    categoryNames.addAll(
      (json['categories'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((category) => category['name']?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .where((name) => !categoryNames.contains(name)),
    );
    final categoryMap = json['category'];
    if (categoryMap is Map<String, dynamic>) {
      final categoryName = categoryMap['name']?.toString().trim() ?? '';
      if (categoryName.isNotEmpty && !categoryNames.contains(categoryName)) {
        categoryNames.insert(0, categoryName);
      }
    } else if (categoryMap is Map) {
      final categoryName = categoryMap['name']?.toString().trim() ?? '';
      if (categoryName.isNotEmpty && !categoryNames.contains(categoryName)) {
        categoryNames.insert(0, categoryName);
      }
    }
    final categoryName = json['categoryName']?.toString().trim() ?? '';
    if (categoryName.isNotEmpty && !categoryNames.contains(categoryName)) {
      categoryNames.insert(0, categoryName);
    }
    final reviews = (json['reviews'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HomeGraphqlProductReview.fromJson)
        .toList();
    final attachments = (json['attachments'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HomeGraphqlProductAttachment.fromJson)
        .where((attachment) => attachment.hasMedia)
        .toList();
    final hasReviewsCount = json.containsKey('reviewsCount');
    final hasRatingAvg = json.containsKey('ratingAvg');
    double averageFromReviews() {
      if (reviews.isEmpty) return 0;
      final total = reviews.fold<double>(
        0,
        (sum, review) => sum + review.rating.toDouble(),
      );
      return total / reviews.length;
    }

    final resolvedVariant = _resolvePreferredPricingVariant(variants);
    final effectivePrice = resolvedVariant?.displayPriceAmount ?? 0;
    final hasDiscount = resolvedVariant?.hasDisplayDiscount == true;
    final regularAmount = resolvedVariant?.regularAmount ?? 0;

    return HomeGraphqlProduct(
      uuid: json['uuid']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      brief: json['brief']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      descriptionHtml: json['descriptionHtml']?.toString() ?? '',
      sizechartUrl: json['sizechartUrl']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      salesCount: _toInt(json['salesCount']),
      likesCount: _toInt(json['likesCount']),
      reviewsCountValue: hasReviewsCount
          ? _toInt(json['reviewsCount'])
          : reviews.length,
      ratingAvgValue: hasRatingAvg
          ? _toNum(json['ratingAvg']).toDouble()
          : averageFromReviews(),
      ratingOneStarCount: _toInt(json['ratingOneStarCount']),
      ratingTwoStarCount: _toInt(json['ratingTwoStarCount']),
      ratingThreeStarCount: _toInt(json['ratingThreeStarCount']),
      ratingFourStarCount: _toInt(json['ratingFourStarCount']),
      ratingFiveStarCount: _toInt(json['ratingFiveStarCount']),
      categoryNames: categoryNames,
      options: options,
      variants: variants,
      reviews: reviews,
      attachments: attachments,
      priceAmount: effectivePrice,
      originalPriceAmount: hasDiscount ? regularAmount : 0,
      currencyCode:
          (resolvedVariant?.discountedPrice?.currencyCode.trim().isNotEmpty ==
              true)
          ? resolvedVariant!.discountedPrice!.currencyCode
          : (resolvedVariant?.price?.currencyCode ?? ''),
      variantUuid: resolvedVariant?.uuid,
      featuredThumbnailUrl: json['featuredThumbnailUrl']?.toString() ?? '',
      featuredImageUrl: json['featuredImageUrl']?.toString() ?? '',
      campaign: json['campaign'] is Map<String, dynamic>
          ? HomeGraphqlProductCampaign.fromJson(
              json['campaign'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class HomeGraphqlCategory {
  HomeGraphqlCategory({
    required this.uuid,
    required this.slug,
    required this.name,
    required this.thumbnailUrl,
    this.children = const [],
  });

  final String uuid;
  final String slug;
  final String name;
  final String thumbnailUrl;
  final List<HomeGraphqlCategory> children;

  factory HomeGraphqlCategory.fromJson(Map<String, dynamic> json) {
    final children = (json['children'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HomeGraphqlCategory.fromJson)
        .toList();

    return HomeGraphqlCategory(
      uuid: json['uuid']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      children: children,
    );
  }
}

class HomeGraphqlFeaturedCampaign {
  const HomeGraphqlFeaturedCampaign({
    required this.uuid,
    required this.name,
    required this.brief,
    required this.slug,
    required this.discountPercentage,
    required this.startsAt,
    required this.finishesAt,
    required this.campaignCategories,
  });

  final String uuid;
  final String name;
  final String brief;
  final String slug;
  final num discountPercentage;
  final DateTime? startsAt;
  final DateTime? finishesAt;
  final List<HomeGraphqlFeaturedCampaignCategory> campaignCategories;

  factory HomeGraphqlFeaturedCampaign.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      final value = raw?.toString().trim() ?? '';
      if (value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return HomeGraphqlFeaturedCampaign(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brief: json['brief']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      discountPercentage: _toNum(json['discountPercentage']),
      startsAt: parseDate(json['startsAt']),
      finishesAt: parseDate(json['finishesAt']),
      campaignCategories:
          (json['campaignCategories'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(HomeGraphqlFeaturedCampaignCategory.fromJson)
              .toList(),
    );
  }
}

class HomeGraphqlFeaturedCampaignCategory {
  const HomeGraphqlFeaturedCampaignCategory({required this.category});

  final HomeGraphqlCategory category;

  factory HomeGraphqlFeaturedCampaignCategory.fromJson(
    Map<String, dynamic> json,
  ) {
    final categoryJson = json['category'];
    return HomeGraphqlFeaturedCampaignCategory(
      category: categoryJson is Map<String, dynamic>
          ? HomeGraphqlCategory.fromJson(categoryJson)
          : HomeGraphqlCategory(uuid: '', slug: '', name: '', thumbnailUrl: ''),
    );
  }
}

class HomeGraphqlCampaignSection {
  const HomeGraphqlCampaignSection({
    required this.campaignUuid,
    required this.campaignName,
    required this.campaignFinishesAt,
    required this.categoryUuid,
    required this.categorySlug,
    required this.categoryName,
    required this.categoryThumbnailUrl,
    required this.products,
  });

  final String campaignUuid;
  final String campaignName;
  final DateTime? campaignFinishesAt;
  final String categoryUuid;
  final String categorySlug;
  final String categoryName;
  final String categoryThumbnailUrl;
  final List<HomeGraphqlProduct> products;
}

class HomeProductSections {
  HomeProductSections({
    required this.allProducts,
    required this.featuredProducts,
    required this.popularProducts,
    required this.recentlyViewed,
    this.featuredCampaignTitle = '',
    this.featuredCampaignEndsAt,
    this.featuredCampaignProducts = const [],
    this.featuredCampaignSections = const [],
  });

  final List<HomeGraphqlProduct> allProducts;
  final List<HomeGraphqlProduct> featuredProducts;
  final List<HomeGraphqlProduct> popularProducts;
  final List<HomeGraphqlProduct> recentlyViewed;
  final String featuredCampaignTitle;
  final DateTime? featuredCampaignEndsAt;
  final List<HomeGraphqlProduct> featuredCampaignProducts;
  final List<HomeGraphqlCampaignSection> featuredCampaignSections;
}

class HomeGraphqlBootstrapData {
  const HomeGraphqlBootstrapData({
    required this.banners,
    required this.stories,
    required this.categories,
    required this.sections,
  });

  final List<SliderItemModel> banners;
  final List<StoriesModel> stories;
  final List<HomeGraphqlCategory> categories;
  final HomeProductSections sections;
}

class HomeGraphqlCategoryFeedData {
  const HomeGraphqlCategoryFeedData({
    required this.banners,
    required this.categories,
  });

  final List<SliderItemModel> banners;
  final List<HomeGraphqlCategory> categories;
}

class HomeDashboardCounts {
  const HomeDashboardCounts({
    required this.cartCount,
    required this.wishlistCount,
  });

  final int cartCount;
  final int wishlistCount;
}

class HomeGraphqlSectionQuery {
  const HomeGraphqlSectionQuery({
    this.filters,
    this.sort,
    this.pageNumber = 1,
    this.itemsPerPage = 10,
  });

  final String? filters;
  final String? sort;
  final int pageNumber;
  final int itemsPerPage;
}

class HomeGraphqlPagination {
  const HomeGraphqlPagination({this.pageNumber = 1, this.itemsPerPage = 100});

  final int pageNumber;
  final int itemsPerPage;

  Map<String, dynamic> toVariables() {
    return {'pageNumber': pageNumber, 'itemsPerPage': itemsPerPage};
  }
}

class HomeGraphqlSectionDefinition {
  const HomeGraphqlSectionDefinition({required this.type, required this.query});

  final HomeProductSectionType type;
  final HomeGraphqlSectionQuery query;
}

extension HomeGraphqlBannerMapper on SliderItemModel {
  static SliderItemModel fromGraphqlJson(
    Map<String, dynamic> json, {
    String language = 'en',
  }) {
    String normalizeImageUrl(String rawValue) {
      final trimmed = rawValue.trim();
      if (trimmed.isEmpty) return '';
      final transformed = ImageUrlTransformer.getTransformedImageUrl(
        trimmed,
        AppConfig.instance.assetsHost,
      );
      return transformed.isNotEmpty ? transformed : trimmed;
    }

    final normalizedLanguage = language.trim().toLowerCase();
    final imageUrlDefault = normalizeImageUrl(
      json['imageUrl']?.toString() ?? '',
    );
    final imageUrlAr = normalizeImageUrl(json['imageUrlAr']?.toString() ?? '');
    final imageUrlEn = normalizeImageUrl(json['imageUrlEn']?.toString() ?? '');
    final localizedImageUrl = normalizedLanguage == 'ar'
        ? (imageUrlAr.isNotEmpty
              ? imageUrlAr
              : (imageUrlDefault.isNotEmpty ? imageUrlDefault : imageUrlEn))
        : (imageUrlEn.isNotEmpty
              ? imageUrlEn
              : (imageUrlDefault.isNotEmpty ? imageUrlDefault : imageUrlAr));

    return SliderItemModel(
      id: json['uuid']?.toString().hashCode ?? 0,
      imageUrl: localizedImageUrl,
      imageUrlAr: imageUrlAr,
      imageUrlEn: imageUrlEn,
      title: json['title']?.toString().trim() ?? '',
      description: json['linkUrl']?.toString().trim() ?? '',
      discount: json['placement']?.toString().trim() ?? '',
      bannerColor: json['color']?.toString().trim() ?? '',
    );
  }
}

extension HomeGraphqlStoryMapper on StoriesModel {
  static StoriesModel fromGraphqlJson(Map<String, dynamic> json) {
    final frames =
        (json['frames'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList()
          ..sort((a, b) {
            final left = a['order'] is int ? a['order'] as int : 0;
            final right = b['order'] is int ? b['order'] as int : 0;
            return left.compareTo(right);
          });
    final mappedFrames = frames.map(StoryFrameModel.fromJson).where((frame) {
      final mediaUrl = frame.mediaUrl.trim();
      final thumbnailUrl = frame.thumbnailUrl.trim();
      if (frame.mediaType.trim().toLowerCase() == 'video') {
        return mediaUrl.isNotEmpty;
      }
      return mediaUrl.isNotEmpty || thumbnailUrl.isNotEmpty;
    }).toList();
    final firstFrame = mappedFrames.isNotEmpty
        ? mappedFrames.first
        : const StoryFrameModel(
            id: '',
            mediaUrl: '',
            mediaType: 'image',
            thumbnailUrl: '',
            duration: 5,
            order: 0,
          );
    final now = DateTime.now();
    return StoriesModel(
      id: json['uuid']?.toString() ?? '',
      title: json['caption']?.toString() ?? '',
      description: json['caption']?.toString() ?? '',
      mediaUrl: firstFrame.mediaUrl.isNotEmpty
          ? firstFrame.mediaUrl
          : firstFrame.thumbnailUrl,
      mediaType: firstFrame.mediaType,
      thumbnailUrl: firstFrame.thumbnailUrl.isNotEmpty
          ? firstFrame.thumbnailUrl
          : firstFrame.mediaUrl,
      duration: firstFrame.duration,
      expiresAt: now.add(const Duration(days: 7)),
      createdAt: now,
      isActive: true,
      frames: mappedFrames,
    );
  }
}

int _toInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

num _toNum(dynamic raw) {
  if (raw is num) return raw;
  return num.tryParse(raw?.toString() ?? '') ?? 0;
}

bool _toBool(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final value = raw?.toString().trim().toLowerCase();
  return value == 'true' || value == '1' || value == 'yes';
}
