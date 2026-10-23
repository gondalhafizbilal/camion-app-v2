// all_product_model.dart
import 'package:camion/features/home/data/models/all_products_model/sub_models/add_to_cart.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/attribute.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/product_variations.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/variation.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/prices_model.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/product_image.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/stock_availability.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/category.dart';
import 'package:camion/features/home/data/models/all_products_model/sub_models/brand.dart';

class AllProductCampaign {
  const AllProductCampaign({
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

  factory AllProductCampaign.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic raw) {
      final value = raw?.toString().trim() ?? '';
      if (value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return AllProductCampaign(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brief: json['brief']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      discountPercentage:
          num.tryParse(json['discountPercentage']?.toString() ?? '') ?? 0,
      startsAt: parseDate(json['startsAt']),
      finishesAt: parseDate(json['finishesAt']),
    );
  }
}

class AllProductModel {
  final int id;
  final String name;
  final String slug;
  final int parent;
  final String type;
  final String variation;
  final String permalink;
  final String sku;
  final String shortDescription;
  final String description;
  final bool onSale;
  final Prices prices;
  final String priceHtml;
  final String averageRating;
  final int reviewCount;
  final int likesCount;
  final List<ProductImage> images;
  final List<Category> categories;
  final List<Category> tags;
  final List<Brand> brands;
  final List<Attribute> attributes;
  final List<Variation> variations;
  final List<ProductVariations> productVariations;
  final bool hasOptions;
  final bool isPurchasable;
  final bool isInStock;
  final bool isOnBackorder;
  final StockAvailability stockAvailability;
  final bool soldIndividually;
  final AddToCart addToCart;
  final bool? isInCart;
  final bool? isInwishList;
  final String featuredThumbnailUrl;
  final String featuredImageUrl;
  final AllProductCampaign? campaign;

  AllProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.parent,
    required this.type,
    required this.variation,
    required this.permalink,
    required this.sku,
    required this.shortDescription,
    required this.description,
    required this.onSale,
    required this.prices,
    required this.priceHtml,
    required this.averageRating,
    required this.reviewCount,
    this.likesCount = 0,
    required this.images,
    required this.categories,
    required this.tags,
    required this.brands,
    required this.attributes,
    required this.variations,
    required this.productVariations,
    required this.hasOptions,
    required this.isPurchasable,
    required this.isInStock,
    required this.isOnBackorder,
    required this.stockAvailability,
    required this.soldIndividually,
    required this.addToCart,
    this.isInCart,
    this.isInwishList,
    this.featuredThumbnailUrl = '',
    this.featuredImageUrl = '',
    this.campaign,
  });

  String get primaryImageUrl {
    final featuredThumb = featuredThumbnailUrl.trim();
    if (featuredThumb.isNotEmpty) return featuredThumb;

    final featuredImage = featuredImageUrl.trim();
    if (featuredImage.isNotEmpty) return featuredImage;

    if (images.isNotEmpty) {
      final thumb = images.first.thumbnail.trim();
      if (thumb.isNotEmpty) return thumb;
      final src = images.first.src.trim();
      if (src.isNotEmpty) return src;
    }

    for (final variant in productVariations) {
      final variantImage = (variant.image ?? '').trim();
      if (variantImage.isNotEmpty) return variantImage;
    }
    return '';
  }

  factory AllProductModel.fromJson(Map<String, dynamic> json) {
    return AllProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      parent: json['parent'] ?? 0,
      type: json['type'] ?? '',
      variation: json['variation'] ?? '',
      permalink: json['permalink'] ?? '',
      sku: json['sku'] ?? '',
      shortDescription: json['short_description'] ?? '',
      description: json['description'] ?? '',
      onSale: json['on_sale'] ?? false,
      prices: Prices.fromJson(json['prices'] ?? {}),
      priceHtml: json['price_html'] ?? '',
      averageRating: json['average_rating'] ?? '0',
      reviewCount: json['review_count'] ?? 0,
      likesCount: json['likesCount'] ?? json['likes_count'] ?? 0,
      images: (json['images'] as List? ?? [])
          .map((img) => ProductImage.fromJson(img))
          .toList(),
      categories: (json['categories'] as List? ?? [])
          .map((c) => Category.fromJson(c))
          .toList(),
      tags: (json['tags'] as List? ?? [])
          .map((t) => Category.fromJson(t))
          .toList(),
      brands: (json['brands'] as List? ?? [])
          .map((b) => Brand.fromJson(b))
          .toList(),
      attributes: (json['attributes'] as List? ?? [])
          .map((a) => Attribute.fromJson(a))
          .toList(),
      variations: (json['variations'] as List? ?? [])
          .map((v) => Variation.fromJson(v))
          .toList(),

      productVariations: (json['variations'] as List? ?? [])
          .map((v) => ProductVariations.fromJson(v))
          .toList(),
      hasOptions: json['has_options'] ?? false,
      isPurchasable: json['is_purchasable'] ?? false,
      isInStock: json['is_in_stock'] ?? false,
      isOnBackorder: json['is_on_backorder'] ?? false,
      stockAvailability: StockAvailability.fromJson(
        json['stock_availability'] ?? {},
      ),
      soldIndividually: json['sold_individually'] ?? false,
      addToCart: AddToCart.fromJson(json['add_to_cart'] ?? {}),
      isInCart: json['cart'],
      isInwishList: json['wishlist'],
      featuredThumbnailUrl: (json['featuredThumbnailUrl'] ?? '').toString(),
      featuredImageUrl: (json['featuredImageUrl'] ?? '').toString(),
      campaign: json['campaign'] is Map<String, dynamic>
          ? AllProductCampaign.fromJson(
              json['campaign'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
