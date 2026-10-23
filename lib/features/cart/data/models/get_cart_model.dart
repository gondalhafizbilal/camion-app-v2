import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/money_utils.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/variation.dart';

String _resolveImageUrl(dynamic value) {
  if (value is String) return value.trim();
  if (value is List && value.isNotEmpty) {
    for (final entry in value) {
      if (entry is String) {
        final resolved = entry.trim();
        if (resolved.isNotEmpty) return resolved;
      } else if (entry is Map) {
        final map = Map<String, dynamic>.from(entry);
        final resolved =
            map['thumbnailUrl']?.toString().trim() ??
            map['imageUrl']?.toString().trim() ??
            '';
        if (resolved.isNotEmpty) return resolved;
      }
    }
  } else if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    final resolved =
        map['thumbnailUrl']?.toString().trim() ??
        map['imageUrl']?.toString().trim() ??
        '';
    if (resolved.isNotEmpty) return resolved;
  }
  return '';
}

String _parseString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

String _currentLanguageCode() {
  final saved = sl<CacheHelper>().getDataString(key: 'languageCode');
  final normalized = saved?.trim().toLowerCase() ?? '';
  if (normalized.isNotEmpty) {
    return normalized;
  }
  return AppDefaults.defaultLanguageCode.toLowerCase();
}

String _firstNonEmpty(Iterable<dynamic> values) {
  for (final value in values) {
    final text = _parseString(value).trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

String _resolveLocalizedTitle(Map<String, dynamic> data) {
  final languageCode = _currentLanguageCode();
  final preferredKeys = languageCode == 'ar'
      ? <String>[
          'titleAr',
          'arabicTitle',
          'nameAr',
          'localizedTitleAr',
          'title',
          'name',
          'titleEn',
          'englishTitle',
          'nameEn',
        ]
      : <String>[
          'titleEn',
          'englishTitle',
          'nameEn',
          'localizedTitleEn',
          'title',
          'name',
          'titleAr',
          'arabicTitle',
          'nameAr',
        ];
  return _firstNonEmpty(preferredKeys.map((key) => data[key]));
}

class GetCartModel {
  String? id;
  String? userId;
  String? productId;
  String? productSlug;
  String? variantUuid;
  int? quantity;
  List<Variation>? variation;
  String? title;
  String? image;
  String? variantImageUrl;
  String? price;
  String? currencyCode;
  HomeGraphqlProductCampaign? campaign;
  dynamic couponCode;
  int? discountPercentage;
  DateTime? createdAt;
  DateTime? updatedAt;
  double? totalPrice;

  GetCartModel({
    this.id,
    this.userId,
    this.productId,
    this.productSlug,
    this.variantUuid,
    this.quantity,
    this.variation,
    this.title,
    this.image,
    this.variantImageUrl,
    this.price,
    this.currencyCode,
    this.campaign,
    this.couponCode,
    this.discountPercentage,
    this.createdAt,
    this.updatedAt,
    this.totalPrice,
  });

  factory GetCartModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : const <String, dynamic>{};
    final campaign = product['campaign'] is Map
        ? Map<String, dynamic>.from(product['campaign'] as Map)
        : json['campaign'] is Map
        ? Map<String, dynamic>.from(json['campaign'] as Map)
        : null;
    final variantRaw = json['variation'] ?? json['variant'];
    final variant = variantRaw is Map
        ? Map<String, dynamic>.from(variantRaw)
        : const <String, dynamic>{};
    final variantImages = (variant['images'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((image) => Map<String, dynamic>.from(image))
        .toList();
    final productVariants = (product['variants'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();

    final rawQuantity = json['quantity'];
    final parsedQuantity = rawQuantity is int
        ? rawQuantity
        : int.tryParse(rawQuantity?.toString() ?? '');

    String? variantImageUrl;
    String? image;
    final directVariantImage = _resolveImageUrl(variant['image']);
    if (directVariantImage.isNotEmpty) {
      variantImageUrl = directVariantImage;
      image = directVariantImage;
    }

    final variantUuid = variant['uuid']?.toString().trim() ?? '';
    List<Map<String, dynamic>> candidateImages = variantImages;

    if (candidateImages.isEmpty && productVariants.isNotEmpty) {
      final matchedVariant = productVariants.firstWhere(
        (entry) =>
            (entry['uuid']?.toString().trim() ?? '').isNotEmpty &&
            (entry['uuid']?.toString().trim() ?? '') == variantUuid,
        orElse: () => const <String, dynamic>{},
      );
      final matchedImages = (matchedVariant['images'] as List? ?? const [])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
      if (matchedImages.isNotEmpty) {
        candidateImages = matchedImages;
      } else {
        for (final productVariant in productVariants) {
          final fallbackImages =
              (productVariant['images'] as List? ?? const <dynamic>[])
                  .whereType<Map>()
                  .map((entry) => Map<String, dynamic>.from(entry))
                  .toList();
          if (fallbackImages.isNotEmpty) {
            candidateImages = fallbackImages;
            break;
          }
        }
      }
    }

    if ((image ?? '').trim().isEmpty) {
      final featuredImages = candidateImages.where((entry) {
        final featured = entry['isFeatured'];
        if (featured is bool) return featured;
        return featured?.toString().toLowerCase() == 'true';
      }).toList();
      final prioritizedImages = [
        ...featuredImages,
        ...candidateImages.where((entry) => !featuredImages.contains(entry)),
      ];
      for (final entry in prioritizedImages) {
        final thumbnail = entry['thumbnailUrl']?.toString().trim() ?? '';
        if (thumbnail.isNotEmpty) {
          image = thumbnail;
          variantImageUrl ??= thumbnail;
          break;
        }
        final imageUrl = entry['imageUrl']?.toString().trim() ?? '';
        if (imageUrl.isNotEmpty) {
          image = imageUrl;
          variantImageUrl ??= imageUrl;
          break;
        }
      }
    }

    if ((image ?? '').trim().isEmpty) {
      final productFeaturedThumbnail =
          product['featuredThumbnailUrl']?.toString().trim() ?? '';
      final productFeaturedImage =
          product['featuredImageUrl']?.toString().trim() ?? '';
      if (productFeaturedThumbnail.isNotEmpty) {
        image = productFeaturedThumbnail;
      } else if (productFeaturedImage.isNotEmpty) {
        image = productFeaturedImage;
      }
    }

    final variantTitle = variant['title']?.toString() ?? '';
    final variationList = <Variation>[
      if (variantTitle.trim().isNotEmpty)
        Variation(attribute: 'Variant', value: variantTitle),
      if ((variant['uuid']?.toString().trim() ?? '').isNotEmpty)
        Variation(attribute: 'variantUuid', value: variant['uuid'].toString()),
    ];

    final variantPrice = variant['price'] is Map
        ? parseMoneyValue(variant['price']).toString()
        : null;
    final variantPriceCurrency = variant['price'] is Map
        ? parseMoneyCurrencyCode(variant['price'])
        : null;
    final variantDiscountedPrice = variant['discountedPrice'] is Map
        ? parseMoneyValue(variant['discountedPrice']).toString()
        : null;
    final variantDiscountedPriceCurrency = variant['discountedPrice'] is Map
        ? parseMoneyCurrencyCode(variant['discountedPrice'])
        : null;
    final subTotalMap = json['subTotal'] is Map
        ? Map<String, dynamic>.from(json['subTotal'] as Map)
        : const <String, dynamic>{};
    final subTotalValue = parseMoneyValue(subTotalMap);
    final subTotalCurrency = parseMoneyCurrencyCode(subTotalMap);

    return GetCartModel(
      id: (json['uuid'] ?? json['id'])?.toString(),
      userId: (json['customerUuid'] ?? json['userId'])?.toString(),
      productId: (json['productUuid'] ?? product['uuid'] ?? json['productId'])
          ?.toString(),
      productSlug: product['slug']?.toString(),
      variantUuid: variant['uuid']?.toString(),
      quantity: parsedQuantity ?? 1,
      variation: variationList,
      title: _firstNonEmpty([
        _resolveLocalizedTitle(json),
        _resolveLocalizedTitle(product),
        _resolveLocalizedTitle(variant),
      ]),
      image: image,
      variantImageUrl: variantImageUrl,
      price: (() {
        final apiPrice = parseMoneyValue(json['price']);
        if (apiPrice > 0) return apiPrice.toString();
        if (variantDiscountedPrice != null) return variantDiscountedPrice;
        if (variantPrice != null) return variantPrice;
        if (subTotalValue > 0) return subTotalValue.toString();
        final totalPriceValue = parseMoneyValue(json['totalPrice']);
        return totalPriceValue > 0 ? totalPriceValue.toString() : null;
      })(),
      currencyCode:
          json['currencyCode']?.toString() ??
          variantDiscountedPriceCurrency ??
          variantPriceCurrency ??
          subTotalCurrency,
      campaign: campaign == null
          ? null
          : HomeGraphqlProductCampaign.fromJson(campaign),
      couponCode: json['couponCode'],
      discountPercentage: json['discountPercentage'] is int
          ? json['discountPercentage'] as int
          : int.tryParse(json['discountPercentage']?.toString() ?? ''),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
      totalPrice:
          (json['totalPrice'] as num?)?.toDouble() ??
          double.tryParse(json['totalPrice']?.toString() ?? '') ??
          subTotalValue,
    );
  }
}
