import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/money_utils.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';

class GetWishListModel {
  String? id;
  String? userId;
  String? productId;
  String? productName;
  String? productImage;
  String? price;
  String? oldPrice;
  String? currencyCode;
  int reviewsCount;
  int likesCount;
  String averageRatingText;
  int variantsCount;
  String? defaultVariantUuid;
  String? productSlug;
  String? productBrief;
  String? productDescription;
  String? productDescriptionHtml;
  String? productStatus;
  HomeGraphqlProductCampaign? campaign;

  GetWishListModel({
    this.id,
    this.userId,
    this.productId,
    this.productName,
    this.productImage,
    this.price,
    this.oldPrice,
    this.currencyCode,
    this.reviewsCount = 0,
    this.likesCount = 0,
    this.averageRatingText = '0.0',
    this.variantsCount = 0,
    this.defaultVariantUuid,
    this.productSlug,
    this.productBrief,
    this.productDescription,
    this.productDescriptionHtml,
    this.productStatus,
    this.campaign,
  });

  factory GetWishListModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final productMap = product is Map<String, dynamic>
        ? product
        : const <String, dynamic>{};
    final campaignMap = productMap['campaign'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(productMap['campaign'] as Map)
        : json['campaign'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['campaign'] as Map)
        : null;
    final variantRaw = json['variant'];
    final topVariant = variantRaw is Map<String, dynamic>
        ? variantRaw
        : const <String, dynamic>{};
    final variants = (productMap['variants'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    num? parsePositiveAmount(dynamic value) {
      final parsed = parseMoneyValue(value);
      return parsed > 0 ? parsed : null;
    }

    String formatAmount(num value) => value.toStringAsFixed(2);

    num? variantPriceAmount(Map<String, dynamic> variant) {
      final priceMap = variant['price'];
      if (priceMap is! Map<String, dynamic>) {
        return null;
      }
      return parsePositiveAmount(priceMap);
    }

    num? variantDiscountedAmount(Map<String, dynamic> variant) {
      final discountedMap = variant['discountedPrice'];
      if (discountedMap is! Map<String, dynamic>) {
        return null;
      }
      return parsePositiveAmount(discountedMap);
    }

    Map<String, dynamic> selectPrimaryVariant() {
      if (topVariant.isNotEmpty) {
        return topVariant;
      }
      Map<String, dynamic>? fallback;
      for (final variant in variants) {
        final regular = variantPriceAmount(variant);
        final discounted = variantDiscountedAmount(variant);
        final hasRegular = regular != null;
        final hasDiscounted = discounted != null;
        if (hasRegular && hasDiscounted) {
          return variant;
        }
        if ((hasRegular || hasDiscounted) && fallback == null) {
          fallback = variant;
        }
      }
      if (fallback != null) {
        return fallback;
      }
      if (variants.isNotEmpty) {
        return variants.first;
      }
      return const <String, dynamic>{};
    }

    final primaryVariant = selectPrimaryVariant();
    final primaryRegularPrice = variantPriceAmount(primaryVariant);
    final primaryDiscountedPrice = variantDiscountedAmount(primaryVariant);

    String resolveImage() {
      final featuredThumbnail =
          productMap['featuredThumbnailUrl']?.toString().trim() ?? '';
      if (featuredThumbnail.isNotEmpty) {
        return featuredThumbnail;
      }

      final featuredImage =
          productMap['featuredImageUrl']?.toString().trim() ?? '';
      if (featuredImage.isNotEmpty) {
        return featuredImage;
      }

      final primaryImages =
          (primaryVariant['images'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>();
      for (final image in primaryImages) {
        final thumbnail = image['thumbnailUrl']?.toString().trim() ?? '';
        if (thumbnail.isNotEmpty) return thumbnail;
        final imageUrl = image['imageUrl']?.toString().trim() ?? '';
        if (imageUrl.isNotEmpty) return imageUrl;
      }

      for (final variant in variants) {
        final images = (variant['images'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>();
        for (final image in images) {
          final thumbnail = image['thumbnailUrl']?.toString().trim() ?? '';
          if (thumbnail.isNotEmpty) return thumbnail;
          final imageUrl = image['imageUrl']?.toString().trim() ?? '';
          if (imageUrl.isNotEmpty) return imageUrl;
        }
      }
      return productMap['productImage']?.toString() ??
          json['productImage']?.toString() ??
          '';
    }

    String resolvePrice() {
      if (primaryDiscountedPrice != null) {
        return formatAmount(primaryDiscountedPrice);
      }
      if (primaryRegularPrice != null) {
        return formatAmount(primaryRegularPrice);
      }
      final productPrice = productMap['price'];
      final parsedProductPrice = parseMoneyValue(productPrice);
      if (parsedProductPrice > 0) {
        return formatAmount(parsedProductPrice);
      }
      final fallbackPrice = parseMoneyValue(json['price']);
      return fallbackPrice > 0 ? formatAmount(fallbackPrice) : '';
    }

    String resolveOldPrice() {
      final hasBothRegularAndDiscounted =
          primaryRegularPrice != null && primaryDiscountedPrice != null;
      if (!hasBothRegularAndDiscounted) {
        return '';
      }
      return formatAmount(primaryRegularPrice);
    }

    String resolveCurrencyCode() {
      final discountedMap = primaryVariant['discountedPrice'];
      if (discountedMap is Map<String, dynamic>) {
        final code = parseMoneyCurrencyCode(discountedMap)?.trim() ?? '';
        if (code.isNotEmpty) {
          return code.toUpperCase();
        }
      }

      final priceMap = primaryVariant['price'];
      if (priceMap is Map<String, dynamic>) {
        final code = parseMoneyCurrencyCode(priceMap)?.trim() ?? '';
        if (code.isNotEmpty) {
          return code.toUpperCase();
        }
      }

      for (final variant in variants) {
        final variantPriceMap = variant['price'];
        if (variantPriceMap is Map<String, dynamic>) {
          final code =
              parseMoneyCurrencyCode(variantPriceMap)?.trim() ?? '';
          if (code.isNotEmpty) {
            return code.toUpperCase();
          }
        }
      }
      return savedCurrencyCode();
    }

    Map<String, dynamic> resolveReviews() {
      final countFromAggregate = productMap['reviewsCount'];
      final avgFromAggregate = productMap['ratingAvg'];
      final aggregateCount = countFromAggregate is num
          ? countFromAggregate.toInt()
          : int.tryParse(countFromAggregate?.toString() ?? '');
      final aggregateAvg = avgFromAggregate is num
          ? avgFromAggregate.toDouble()
          : double.tryParse(avgFromAggregate?.toString() ?? '');

      if (aggregateCount != null || aggregateAvg != null) {
        final count = aggregateCount ?? 0;
        final avg = aggregateAvg ?? 0;
        return {'count': count, 'average': avg.toStringAsFixed(1)};
      }

      final reviews = (productMap['reviews'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (reviews.isEmpty) {
        return {'count': 0, 'average': '0.0'};
      }
      final total = reviews.fold<double>(0, (sum, review) {
        final rating = review['rating'];
        if (rating is num) {
          return sum + rating.toDouble();
        }
        return sum + (double.tryParse(rating?.toString() ?? '') ?? 0);
      });
      final avg = total / reviews.length;
      return {'count': reviews.length, 'average': avg.toStringAsFixed(1)};
    }

    final productId =
        productMap['uuid']?.toString() ??
        json['productId']?.toString() ??
        json['productUuid']?.toString();

    final productName =
        productMap['title']?.toString() ?? json['productName']?.toString();
    final reviewData = resolveReviews();
    final likesRaw = productMap['likesCount'] ?? productMap['likes_count'];
    final likesCount = likesRaw is num
        ? likesRaw.toInt()
        : int.tryParse(likesRaw?.toString() ?? '') ?? 0;

    return GetWishListModel(
      id: json['uuid']?.toString() ?? json['id']?.toString(),
      userId: json['userId']?.toString(),
      productId: productId,
      productName: productName,
      productImage: resolveImage(),
      price: resolvePrice(),
      oldPrice: resolveOldPrice(),
      currencyCode: resolveCurrencyCode(),
      reviewsCount: reviewData['count'] as int? ?? 0,
      likesCount: likesCount,
      averageRatingText: reviewData['average']?.toString() ?? '0.0',
      variantsCount: topVariant.isNotEmpty ? 1 : variants.length,
      defaultVariantUuid: primaryVariant['uuid']?.toString().trim(),
      productSlug: productMap['slug']?.toString(),
      productBrief: productMap['brief']?.toString(),
      productDescription: productMap['description']?.toString(),
      productDescriptionHtml: productMap['descriptionHtml']?.toString(),
      productStatus: productMap['status']?.toString(),
      campaign: campaignMap == null
          ? null
          : HomeGraphqlProductCampaign.fromJson(campaignMap),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'productId': productId,
    'productName': productName,
    'productImage': productImage,
    'price': price,
    'oldPrice': oldPrice,
    'currencyCode': currencyCode,
    'reviewsCount': reviewsCount,
    'likesCount': likesCount,
    'averageRatingText': averageRatingText,
    'variantsCount': variantsCount,
    'defaultVariantUuid': defaultVariantUuid,
    'productSlug': productSlug,
    'productBrief': productBrief,
    'productDescription': productDescription,
    'productDescriptionHtml': productDescriptionHtml,
    'productStatus': productStatus,
  };
}
