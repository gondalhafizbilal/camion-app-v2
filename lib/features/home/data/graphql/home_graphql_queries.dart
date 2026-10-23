class HomeGraphqlQueries {
  const HomeGraphqlQueries._();

  static const String productFields = r'''
    uuid
    slug
    title(language: $language)
    brief(language: $language)
    description(language: $language)
    descriptionHtml(language: $language)
    sizechartUrl
    salesCount
    likesCount
    reviewsCount
    ratingAvg
    featuredThumbnailUrl
    featuredImageUrl
    campaign {
      uuid
      name(language: $language)
      brief(language: $language)
      slug
      discountPercentage
      startsAt
      finishesAt
    }
    variants {
      uuid
      title(language: $language)
      sku
      price(currency: $currency) {
        amount
        minorAmount
        currencyCode
      }
      discountedPrice(currency: $currency) {
        amount
        minorAmount
        currencyCode
      }
      images {
        uuid
        imageUrl
        thumbnailUrl
        alt
        isFeatured
        position
      }
    }
  ''';

  // Lightweight fields for list/search/home cards to reduce payload size.
  static const String productListFields = r'''
    uuid
    slug
    title(language: $language)
    brief(language: $language)
    description(language: $language)
    salesCount
    likesCount
    reviewsCount
    ratingAvg
    featuredThumbnailUrl
    featuredImageUrl
    campaign {
      uuid
      name(language: $language)
      brief(language: $language)
      slug
      discountPercentage
      startsAt
      finishesAt
    }
    variants {
      uuid
      price(currency: $currency) {
        amount
        minorAmount
        currencyCode
      }
      discountedPrice(currency: $currency) {
        amount
        minorAmount
        currencyCode
      }
      images {
        uuid
        imageUrl
        thumbnailUrl
        isFeatured
        position
      }
    }
  ''';

  static const String bannersByPlacement = r'''
    query GetBannersByPlacement(
      $placement: String,
      $language: String,
      $pageNumber: Int,
      $itemsPerPage: Int
    ) {
      getBannersByPlacement(
        placement: $placement,
        pageNumber: $pageNumber,
        itemsPerPage: $itemsPerPage
      ) {
        uuid
        title(language: $language)
        imageUrl
        imageUrlAr
        imageUrlEn
        color
        linkUrl
        placement
        isActive
      }
    }
  ''';

  static const String bannersByCategory = r'''
    query GetBannersByCategory(
      $slug: String,
      $language: String,
      $pageNumber: Int,
      $itemsPerPage: Int
    ) {
      getBannersByCategory(
        slug: $slug,
        pageNumber: $pageNumber,
        itemsPerPage: $itemsPerPage
      ) {
        uuid
        title(language: $language)
        imageUrl(language: $language)
        linkUrl(language: $language)
        placement
        color
        isActive
      }
    }
  ''';

  static const String bannersFallback = r'''
    query GetBanners($language: String, $pageNumber: Int, $itemsPerPage: Int) {
      getBanners(pageNumber: $pageNumber, itemsPerPage: $itemsPerPage) {
        uuid
        title(language: $language)
        imageUrl
        imageUrlAr
        imageUrlEn
        color
        linkUrl
        placement
        isActive
      }
    }
  ''';

  static const String categories = r'''
    query GetCategories($language: String, $pageNumber: Int, $itemsPerPage: Int) {
      getCategories(pageNumber: $pageNumber, itemsPerPage: $itemsPerPage) {
        uuid
        slug
        name(language: $language)
        thumbnailUrl
        children {
          uuid
          slug
          name(language: $language)
          thumbnailUrl
          children {
            uuid
            slug
            name(language: $language)
            thumbnailUrl
          }
        }
      }
    }
  ''';

  static const String featuredCategories = r'''
    query GetFeaturedCategories($language: String, $pageNumber: Int, $itemsPerPage: Int) {
      getFeaturedCategories(pageNumber: $pageNumber, itemsPerPage: $itemsPerPage) {
        uuid
        slug
        name(language: $language)
        thumbnailUrl
      }
    }
  ''';

  static const String categoryFeed = r'''
    query GetCategoryFeed(
      $language: String,
      $placement: String,
      $categoriesPageNumber: Int,
      $categoriesItemsPerPage: Int,
      $bannersPageNumber: Int,
      $bannersItemsPerPage: Int
    ) {
      categoriesSection: getCategories(
        pageNumber: $categoriesPageNumber,
        itemsPerPage: $categoriesItemsPerPage
      ) {
        uuid
        slug
        name(language: $language)
        thumbnailUrl
        children {
          uuid
          slug
          name(language: $language)
          thumbnailUrl
          children {
            uuid
            slug
            name(language: $language)
            thumbnailUrl
          }
        }
      }

      bannersSection: getBannersByPlacement(
        placement: $placement,
        pageNumber: $bannersPageNumber,
        itemsPerPage: $bannersItemsPerPage
      ) {
        uuid
        title(language: $language)
        imageUrl
        imageUrlAr
        imageUrlEn
        color
        linkUrl
        placement
        isActive
      }
    }
  ''';

  static const String stories = r'''
    query GetStories($language: String, $pageNumber: Int, $itemsPerPage: Int) {
      getStories(pageNumber: $pageNumber, itemsPerPage: $itemsPerPage) {
        uuid
        caption(language: $language)
        isHighlighted
        frames {
          uuid
          mediaType
          mediaUrl
          thumbnailUrl
          duration
          order
        }
      }
    }
  ''';

  static const String products =
      '''
    query GetProducts(\$language: String, \$currency: String, \$sort: String, \$pageNumber: Int, \$itemsPerPage: Int) {
      getProducts(language: \$language, currency: \$currency, sort: \$sort, pageNumber: \$pageNumber, itemsPerPage: \$itemsPerPage) {
        ...ProductListFields
      }
    }
    fragment ProductListFields on Product {
$productListFields
    }
  ''';

  static const String productsByCategories =
      '''
    query GetProductsByCategories(\$slugs: [String!]!, \$language: String, \$currency: String, \$sort: String, \$pageNumber: Int, \$itemsPerPage: Int) {
      getProductsByCategories(slugs: \$slugs, language: \$language, currency: \$currency, sort: \$sort, pageNumber: \$pageNumber, itemsPerPage: \$itemsPerPage) {
        ...ProductFields
      }
    }
    fragment ProductFields on Product {
$productFields
    }
  ''';

  static const String featuredProducts =
      '''
    query GetFeaturedProducts(\$language: String, \$sort: String, \$currency: String!, \$pageNumber: Int, \$itemsPerPage: Int) {
      getFeaturedProducts(language: \$language, sort: \$sort, currency: \$currency, pageNumber: \$pageNumber, itemsPerPage: \$itemsPerPage) {
        ...ProductListFields
      }
    }
    fragment ProductListFields on Product {
$productListFields
    }
  ''';

  static const String featuredCampaign = r'''
    query GetFeaturedCampaign($language: String) {
      getFeaturedCampaign(language: $language) {
        uuid
        name(language: $language)
        brief(language: $language)
        slug
        discountPercentage
        startsAt
        finishesAt
        campaignCategories {
          category {
            uuid
            slug
            name(language: $language)
            thumbnailUrl
          }
        }
      }
    }
  ''';

  static const String productsInFeaturedCampaign =
      '''
    query GetProductsInFeaturedCampaign(\$language: String, \$currency: String, \$sort: String, \$pageNumber: Int, \$itemsPerPage: Int) {
      getProductsInFeaturedCampaign(language: \$language, currency: \$currency, sort: \$sort, pageNumber: \$pageNumber, itemsPerPage: \$itemsPerPage) {
        ...ProductListFields
      }
    }
    fragment ProductListFields on Product {
$productListFields
    }
  ''';

  static const String popularProducts =
      '''
    query GetPopularProducts(\$language: String, \$currency: String!, \$sort: String, \$pageNumber: Int, \$itemsPerPage: Int) {
      getPopularProducts(language: \$language, currency: \$currency, sort: \$sort, pageNumber: \$pageNumber, itemsPerPage: \$itemsPerPage) {
        ...ProductListFields
      }
    }
    fragment ProductListFields on Product {
$productListFields
    }
  ''';

  static const String recentlyViewedProducts =
      '''
    query GetRecentlyViewedProducts(\$language: String, \$currency: String!, \$pageNumber: Int, \$itemsPerPage: Int) {
      getRecentlyViewedProducts(language: \$language, currency: \$currency, pageNumber: \$pageNumber, itemsPerPage: \$itemsPerPage) {
        ...ProductListFields
      }
    }
    fragment ProductListFields on Product {
$productListFields
    }
  ''';

  static const String homeProductSections =
      '''
    query GetHomeProductSections(
      \$language: String,
      \$currency: String!,
      \$allPageNumber: Int,
      \$allItemsPerPage: Int,
      \$featuredPageNumber: Int,
      \$featuredItemsPerPage: Int,
      \$popularPageNumber: Int,
      \$popularItemsPerPage: Int,
      \$recentlyViewedPageNumber: Int,
      \$recentlyViewedItemsPerPage: Int
    ) {
      allProductsSection: getProducts(
        language: \$language,
        currency: \$currency,
        pageNumber: \$allPageNumber,
        itemsPerPage: \$allItemsPerPage
      ) {
        ...ProductListFields
      }
      featuredProductsSection: getFeaturedProducts(
        language: \$language,
        currency: \$currency,
        pageNumber: \$featuredPageNumber,
        itemsPerPage: \$featuredItemsPerPage
      ) {
        ...ProductListFields
      }
      popularProductsSection: getPopularProducts(
        language: \$language,
        currency: \$currency,
        pageNumber: \$popularPageNumber,
        itemsPerPage: \$popularItemsPerPage
      ) {
        ...ProductListFields
      }
      recentlyViewedProductsSection: getRecentlyViewedProducts(
        language: \$language,
        currency: \$currency,
        pageNumber: \$recentlyViewedPageNumber,
        itemsPerPage: \$recentlyViewedItemsPerPage
      ) {
        ...ProductListFields
      }
    }

    fragment ProductListFields on Product {
$productListFields
    }
  ''';

  static const String homeBootstrap =
      '''
    query GetHomeBootstrap(
      \$language: String,
      \$currency: String!,
      \$allPageNumber: Int,
      \$allItemsPerPage: Int,
      \$featuredPageNumber: Int,
      \$featuredItemsPerPage: Int,
      \$popularPageNumber: Int,
      \$popularItemsPerPage: Int,
      \$recentlyViewedPageNumber: Int,
      \$recentlyViewedItemsPerPage: Int,
      \$categoriesPageNumber: Int,
      \$categoriesItemsPerPage: Int,
      \$storiesPageNumber: Int,
      \$storiesItemsPerPage: Int,
      \$bannersPageNumber: Int,
      \$bannersItemsPerPage: Int
    ) {
      bannersSection: getBanners(
        pageNumber: \$bannersPageNumber,
        itemsPerPage: \$bannersItemsPerPage
      ) {
        uuid
        title(language: \$language)
        imageUrl
        imageUrlAr
        imageUrlEn
        color
        linkUrl
        placement
        isActive
      }

      storiesSection: getStories(
        pageNumber: \$storiesPageNumber,
        itemsPerPage: \$storiesItemsPerPage
      ) {
        uuid
        caption(language: \$language)
        isHighlighted
        frames {
          uuid
          mediaType
          mediaUrl
          thumbnailUrl
          duration
          order
        }
      }

      categoriesSection: getCategories(
        pageNumber: \$categoriesPageNumber,
        itemsPerPage: \$categoriesItemsPerPage
      ) {
        uuid
        slug
        name(language: \$language)
        thumbnailUrl
        children {
          uuid
          slug
          name(language: \$language)
          thumbnailUrl
          children {
            uuid
            slug
            name(language: \$language)
            thumbnailUrl
          }
        }
      }

      allProductsSection: getProducts(
        language: \$language,
        currency: \$currency,
        pageNumber: \$allPageNumber,
        itemsPerPage: \$allItemsPerPage
      ) {
        ...ProductListFields
      }
      featuredProductsSection: getFeaturedProducts(
        language: \$language,
        currency: \$currency,
        pageNumber: \$featuredPageNumber,
        itemsPerPage: \$featuredItemsPerPage
      ) {
        ...ProductListFields
      }
      popularProductsSection: getPopularProducts(
        language: \$language,
        currency: \$currency,
        pageNumber: \$popularPageNumber,
        itemsPerPage: \$popularItemsPerPage
      ) {
        ...ProductListFields
      }
      recentlyViewedProductsSection: getRecentlyViewedProducts(
        language: \$language,
        currency: \$currency,
        pageNumber: \$recentlyViewedPageNumber,
        itemsPerPage: \$recentlyViewedItemsPerPage
      ) {
        ...ProductListFields
      }
    }

    fragment ProductListFields on Product {
$productListFields
    }
  ''';

  static const String recommendedProducts =
      '''
    query GetRecommendedProducts(\$slug: String!, \$language: String, \$currency: String!, \$pageNumber: Int, \$itemsPerPage: Int) {
      getRecommendedProducts(slug: \$slug, language: \$language, currency: \$currency, pageNumber: \$pageNumber, itemsPerPage: \$itemsPerPage) {
        ...ProductListFields
      }
    }
    fragment ProductListFields on Product {
$productListFields
    }
  ''';

  static const String relatedProducts =
      '''
    query GetRelatedProducts(\$slug: String!, \$language: String, \$currency: String!, \$pageNumber: Int, \$itemsPerPage: Int) {
      getRelatedProducts(slug: \$slug, language: \$language, currency: \$currency, pageNumber: \$pageNumber, itemsPerPage: \$itemsPerPage) {
        ...ProductListFields
      }
    }
    fragment ProductListFields on Product {
$productListFields
    }
  ''';

  static const String searchProducts =
      '''
    query SearchProducts(\$query: String!, \$language: String, \$currency: String!, \$sort: String, \$pageNumber: Int, \$itemsPerPage: Int) {
      searchProducts(query: \$query, language: \$language, currency: \$currency, sort: \$sort, pageNumber: \$pageNumber, itemsPerPage: \$itemsPerPage) {
        ...ProductListFields
      }
    }
    fragment ProductListFields on Product {
$productListFields
    }
  ''';

  static const String productsByCategory =
      '''
    query GetProductsByCategory(\$slug: String!, \$language: String, \$currency: String, \$sort: String, \$pageNumber: Int, \$itemsPerPage: Int) {
      getProductsByCategory(slug: \$slug, language: \$language, currency: \$currency, sort: \$sort, pageNumber: \$pageNumber, itemsPerPage: \$itemsPerPage) {
        ...ProductListFields
      }
    }
    fragment ProductListFields on Product {
$productListFields
    }
  ''';

  static const String product = r'''
    query GetProduct($slug: String, $language: String, $currency: String) {
      getProduct(slug: $slug, language: $language, currency: $currency) {
        uuid
        slug
        title(language: $language)
        featuredThumbnailUrl
        featuredImageUrl
        campaign {
          uuid
          name(language: $language)
          brief(language: $language)
          slug
          discountPercentage
          startsAt
          finishesAt
        }
        brief(language: $language)
        description(language: $language)
        descriptionHtml(language: $language)
        attachments {
          uuid
          mediaUrl
          mediaType
        }
        sizechartUrl
        status
        salesCount
        likesCount
        reviewsCount
        ratingAvg
        ratingOneStarCount
        ratingTwoStarCount
        ratingThreeStarCount
        ratingFourStarCount
        ratingFiveStarCount
        productCategories {
          category {
            uuid
            slug
            name(language: $language)
          }
        }
        options {
          uuid
          name(language: $language)
          position
          values {
            uuid
            value(language: $language)
            position
          }
        }
        variants {
          uuid
          title(language: $language)
          sku
          barcode
            price(currency: $currency) {
              amount
              minorAmount
              currencyCode
            }
            discountedPrice(currency: $currency) {
              amount
              minorAmount
              currencyCode
            }
            weight {
            amount
            unit
          }
          dimensions {
            width
            height
            length
            unit
          }
          optionValues {
            optionValue {
              uuid
            }
          }
          images {
            uuid
            imageUrl
            thumbnailUrl
            alt
            isFeatured
            position
          }
        }
        reviews {
          uuid
          rating
          comment
          customer {
            uuid
            fullName
          }
          images {
            uuid
            thumbnailUrl
            imageUrl
          }
        }
      }
    }
  ''';

  static const String currentCustomer = r'''
    query GetCurrentCustomer {
      getCurrentCustomer {
        uuid
        fullName
        emailAddress
        phoneNumber
        unreadNotificationCount
      }
    }
  ''';

  static const String customerAddresses = r'''
    query GetCustomerAddresses($pageNumber: Int, $itemsPerPage: Int) {
      getCustomerAddresses(pageNumber: $pageNumber, itemsPerPage: $itemsPerPage) {
        uuid
        fullName
        countryCode
        phoneNumber
        streetAddress
        apartment
        zipCode
        city
        state
        country
        isDefault
      }
    }
  ''';

  static const String languages = r'''
    query GetLanguages {
      getLanguages {
        uuid
        name
        shortCode
      }
    }
  ''';

  static const String currencies = r'''
    query GetCurrencies {
      getCurrencies {
        uuid
        name
        alphaCode
      }
    }
  ''';

  static const String customerDashboardCounts = r'''
    query GetCustomerDashboardCounts {
      getCustomerCartCount
      getCustomerWishlistCount
    }
  ''';
}
