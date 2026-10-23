# Camion Mobile App
## Backend API Requirements

### Shareable Review Document

This document is prepared for:

- backend team
- project lead
- product/design review

Purpose of this document:

- list the backend APIs needed for the new mobile UI
- make screen requirements clear before implementation
- help evaluate scope before development starts
- provide payload and expected response examples for each screen flow

The mobile app should behave as if it is talking to one backend source.
Internally that backend can use multiple services, but for the app team this should feel like one complete API contract.

Internal services behind the backend:

- API Gateway: user, cart, checkout, wishlist, notifications, affiliate, utility
- Buckydrop: products, categories, reviews, tracking
- Stories service: sliders, stories
- Chatbot service: chatbot sessions and messages

## Review Notes

- this document is written as a complete app contract for the new UI
- some payload/response fields may still gain small extra fields during implementation
- variation structures can have missing or changing variation types in some product cases, and those will be handled on the go during backend and app integration
- `lang` and `currencyCode` should be respected across the complete app
- if a screen is visually static in design, it is still listed where backend-controlled content is useful for long-term flexibility

## What Needs Review

The backend team and project lead should review:

- API coverage for every screen
- response shape consistency
- dynamic language support
- dynamic currency support
- review flow after completed orders
- static design content that should come from backend
- any missing business rules before implementation starts

## Basic Rules

### Common headers

```http
Authorization: Bearer <token>      // only for logged-in APIs
Content-Type: application/json
```

### Common query params

- `lang`: app language like `en`, `ar`
- `currencyCode`: currency like `QAR`, `USD`
- `page`: page number
- `per_page`: items per page

### Important rule for the whole app

- `lang` must be accepted by all content APIs in the app
- `currencyCode` must be accepted by all money-related APIs in the app
- backend should not assume fixed language or fixed currency anywhere
- all labels, titles, messages, policy content, help content, product content, affiliate content, and section names should be returned according to `lang`
- all prices, totals, wallet amounts, order amounts, coupon calculations, shipping totals, and product prices should be returned according to `currencyCode`
- for consistency, backend can accept both `lang` and `currencyCode` on all APIs, even if one of them is not used for a specific endpoint

### Common success response style

For a simple response:

```json
{
  "success": true,
  "message": "Done",
  "data": {}
}
```

For a list response:

```json
{
  "success": true,
  "message": "Done",
  "data": [],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 100,
    "has_next": true
  }
}
```

## Screen Wise API List

## 1. Login Screen

### API: login

`POST /users/auth/login`

Payload:

```json
{
  "email": "john@example.com"
}
```

or

```json
{
  "phone": "+97450000000"
}
```

Response:

```json
{
  "success": true,
  "message": "Verification code sent",
  "data": {
    "userId": "usr_123",
    "email": "john@example.com",
    "phone": "+97450000000",
    "requiresVerification": true
  }
}
```

## 2. Register Screen

### API: register

`POST /users/auth/register`

Payload:

```json
{
  "fullName": "John Doe",
  "email": "john@example.com",
  "phone": "+97450000000"
}
```

Response:

```json
{
  "success": true,
  "message": "Verification code sent",
  "data": {
    "userId": "usr_123",
    "email": "john@example.com",
    "phone": "+97450000000",
    "requiresVerification": true
  }
}
```

## 3. OTP Verification Screen

### API: verify code

`POST /users/verify`

Payload:

```json
{
  "email": "john@example.com",
  "code": "123456"
}
```

or

```json
{
  "phone": "+97450000000",
  "code": "123456"
}
```

Response:

```json
{
  "success": true,
  "message": "User verified",
  "data": {
    "token": "jwt-token",
    "user": {
      "id": "usr_123",
      "fullName": "John Doe",
      "email": "john@example.com",
      "phone": "+97450000000",
      "role": "customer",
      "isActive": true
    }
  }
}
```

## 4. Social Login

### API: Google login

`POST /auth/mobile/google`

Payload:

```json
{
  "idToken": "google-id-token"
}
```

### API: Facebook login

`POST /auth/mobile/facebook`

Payload:

```json
{
  "accessToken": "facebook-access-token"
}
```

### API: Apple login

`POST /auth/mobile/apple`

Payload:

```json
{
  "identityToken": "apple-identity-token",
  "authorizationCode": "optional-auth-code",
  "fullName": "John Doe"
}
```

Common response for social login:

```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "jwt-token",
    "user": {
      "id": "usr_123",
      "fullName": "John Doe",
      "email": "john@example.com",
      "phone": "+97450000000",
      "role": "customer",
      "isActive": true
    },
    "isNewUser": false
  }
}
```

## 5. Address Screen

### API: get my address

`GET /users/address/me?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Address fetched",
  "data": {
    "city": "Doha",
    "email": "john@example.com",
    "phone": "+97450000000",
    "state": "Doha",
    "country": "QA",
    "postcode": "00000",
    "address_1": "Street 1",
    "address_2": "Building 20",
    "last_name": "Doe",
    "first_name": "John",
    "shipping_option": {
      "method_id": "flat_rate",
      "title": "Standard Shipping",
      "cost": 25
    },
    "shipping_address": {
      "city": "Doha",
      "email": "john@example.com",
      "phone": "+97450000000",
      "state": "Doha",
      "country": "QA",
      "postcode": "00000",
      "address_1": "Street 1",
      "address_2": "Building 20",
      "last_name": "Doe",
      "first_name": "John"
    }
  }
}
```

### API: save address

`POST /users/address/update`

Payload:

```json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john@example.com",
  "phone": "+97450000000",
  "address_1": "Street 1",
  "address_2": "Building 20",
  "city": "Doha",
  "state": "Doha",
  "postcode": "00000",
  "country": "QA",
  "shipping_address": {
    "first_name": "John",
    "last_name": "Doe",
    "email": "john@example.com",
    "phone": "+97450000000",
    "address_1": "Street 1",
    "address_2": "Building 20",
    "city": "Doha",
    "state": "Doha",
    "postcode": "00000",
    "country": "QA"
  },
  "shipping_option": {
    "method_id": "flat_rate",
    "title": "Standard Shipping",
    "cost": "25"
  }
}
```

Response:

```json
{
  "success": true,
  "message": "Address updated successfully",
  "data": {
    "saved": true
  }
}
```

### API: countries list

`GET /utility/countries?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Countries fetched",
  "data": [
    {
      "code": "QA",
      "name": "Qatar",
      "phoneCode": "+974"
    }
  ]
}
```

### API: states list

`GET /utility/countries/{countryCode}/states?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "States fetched",
  "data": [
    {
      "code": "DOHA",
      "name": "Doha"
    }
  ]
}
```

### API: cities list

`GET /utility/countries/{countryCode}/states/{stateCode}/cities?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Cities fetched",
  "data": [
    {
      "code": "DOHA_CITY",
      "name": "Doha"
    }
  ]
}
```

## 6. Home Screen

The Home screen in the new UI has multiple required blocks, not just one product list.
Backend should provide all of these blocks:

- stories
- hero banners
- categories
- section tabs
- `Popular Products`
- `Top Sales`
- `Recommended`
- optional promo block like `Join Us`

### Preferred API: full home feed

`GET /home?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Home feed fetched",
  "data": {
    "stories": [
      {
        "id": "story_1",
        "title": "Spring Drop",
        "description": "Latest arrivals",
        "mediaUrl": "https://cdn.example.com/story-1.mp4",
        "mediaType": "video",
        "duration": 15,
        "expiresAt": "2026-03-26T00:00:00.000Z",
        "createdAt": "2026-03-25T08:00:00.000Z",
        "isActive": true
      }
    ],
    "banners": [
      {
        "id": 1,
        "imageUrl": "https://cdn.example.com/slider-1.jpg",
        "title": "Brands Week",
        "description": "Shop top brands",
        "discount": "Flat 50% Off",
        "action": {
          "type": "collection",
          "value": "top-sales"
        }
      }
    ],
    "categories": [
      {
        "id": 10,
        "name": "Shoes",
        "slug": "shoes",
        "description": "",
        "parent": 0,
        "count": 145,
        "review_count": 0,
        "permalink": "https://example.com/category/shoes",
        "image": {
          "id": 2,
          "src": "https://cdn.example.com/category-shoes.jpg",
          "thumbnail": "https://cdn.example.com/category-shoes-thumb.jpg"
        }
      }
    ],
    "sectionTabs": [
      {
        "id": "all",
        "label": "All"
      },
      {
        "id": "popular_products",
        "label": "Popular Products"
      },
      {
        "id": "top_sales",
        "label": "Top Sales"
      },
      {
        "id": "recommended",
        "label": "Recommended"
      }
    ],
    "sections": [
      {
        "id": "popular_products",
        "title": "Popular Products",
        "layout": "grid",
        "showMore": true,
        "items": [
          {
            "id": 101,
            "name": "Running Shoes",
            "slug": "running-shoes",
            "short_description": "Lightweight shoes",
            "description": "<p>Full description</p>",
            "on_sale": true,
            "price_html": "<span>QAR 199</span>",
            "average_rating": "4.6",
            "review_count": 12,
            "images": [
              {
                "id": 1,
                "src": "https://cdn.example.com/p1.jpg",
                "thumbnail": "https://cdn.example.com/p1-thumb.jpg",
                "name": "Running Shoes",
                "alt": "Running Shoes"
              }
            ],
            "categories": [
              {
                "id": 10,
                "name": "Shoes",
                "slug": "shoes"
              }
            ],
            "brands": [
              {
                "id": 4,
                "name": "Nike",
                "slug": "nike"
              }
            ],
            "attributes": [
              {
                "id": 1,
                "name": "Size",
                "terms": [
                  {
                    "id": 11,
                    "name": "UK 8",
                    "slug": "uk-8"
                  }
                ]
              }
            ],
            "variations": [
              {
                "attribute": "Size",
                "value": "UK 8"
              }
            ],
            "has_options": true,
            "is_purchasable": true,
            "is_in_stock": true,
            "cart": false,
            "wishlist": true,
            "prices": {
              "currency_code": "QAR",
              "currency_symbol": "QAR",
              "price": "199",
              "regular_price": "249",
              "sale_price": "199"
            }
          }
        ]
      },
      {
        "id": "top_sales",
        "title": "Top Sales",
        "layout": "grid",
        "showMore": true,
        "items": []
      },
      {
        "id": "recommended",
        "title": "Recommended",
        "layout": "grid",
        "showMore": true,
        "items": []
      }
    ],
    "promoCards": [
      {
        "id": "join_us",
        "title": "Join Our Team",
        "description": "Become part of Camion and start earning with us.",
        "imageUrl": "https://cdn.example.com/join-us-banner.jpg",
        "buttonText": "Join Us",
        "action": {
          "type": "route",
          "value": "affiliateCheckScreen"
        }
      }
    ]
  }
}
```

### Optional support APIs if backend keeps Home modular

If backend still wants to keep Home in smaller APIs, these APIs are still required:

- `GET /sliders`
- `GET /stories/active`
- `GET /categories?lang=en&currencyCode=QAR`
- `GET /products?page=1&per_page=20&lang=en&currencyCode=QAR`
- `GET /products/sections/home?lang=en&currencyCode=QAR`

### API: home product sections

`GET /products/sections/home?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Home sections fetched",
  "data": [
    {
      "id": "popular_products",
      "title": "Popular Products",
      "layout": "grid",
      "showMore": true,
      "items": []
    },
    {
      "id": "top_sales",
      "title": "Top Sales",
      "layout": "grid",
      "showMore": true,
      "items": []
    },
    {
      "id": "recommended",
      "title": "Recommended",
      "layout": "grid",
      "showMore": true,
      "items": []
    }
  ]
}
```

### API: save FCM token

`POST /users/notifications/token?lang=en&currencyCode=QAR`

Payload:

```json
{
  "token": "fcm_device_token"
}
```

Response:

```json
{
  "success": true,
  "message": "Notification token saved",
  "data": {
    "saved": true
  }
}
```

## 7. Search Screen

### API: search products

`GET /products?search=shoe&page=1&per_page=20&lang=en&currencyCode=QAR`

Response:

Use the same product list response as Home products.

## 8. Filter Screen

### API: filter options

`GET /products/filters?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Filter options fetched",
  "data": {
    "priceRange": {
      "min": 10,
      "max": 999
    },
    "brands": [
      { "id": "nike", "label": "Nike", "count": 44 },
      { "id": "adidas", "label": "Adidas", "count": 31 }
    ],
    "categories": [
      { "id": 11, "label": "Running", "count": 32 }
    ],
    "sizes": [
      { "id": "uk-8", "label": "UK 8", "count": 12 }
    ],
    "colors": [
      { "id": "#000000", "label": "Black", "count": 19 }
    ],
    "sortOptions": [
      { "id": "popular", "label": "Popular" },
      { "id": "price_asc", "label": "Price low to high" },
      { "id": "price_desc", "label": "Price high to low" }
    ]
  }
}
```

### API: filtered products

`GET /products?lang=en&currencyCode=QAR&category=shoes&brand=nike&size=uk-8&min_price=50&max_price=300&sort=popular&page=1&per_page=20`

Response:

Use the same product list response as Home products.

## 9. Category Screen

### API: sub categories

`GET /categories/{categoryId}?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Subcategories fetched",
  "data": {
    "id": 10,
    "name": "Shoes",
    "subcategories": [
      {
        "id": 11,
        "name": "Running",
        "slug": "running",
        "description": "",
        "parent": 10,
        "count": 32,
        "review_count": 0,
        "permalink": "https://example.com/category/running",
        "image": {
          "id": 3,
          "src": "https://cdn.example.com/running.jpg",
          "thumbnail": "https://cdn.example.com/running-thumb.jpg"
        }
      }
    ]
  }
}
```

## 10. Products By Category Screen

### API: products by category

`GET /products?category=shoes&page=1&per_page=20&lang=en&currencyCode=QAR`

Response:

Use the same product list response as Home products.

## 11. Product Details Screen

### API: product details

`GET /products/{productId}?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Product details fetched",
  "data": {
    "id": 101,
    "name": "Running Shoes",
    "slug": "running-shoes",
    "short_description": "Lightweight shoes",
    "description": "<p>Full description</p>",
    "on_sale": true,
    "price_html": "<span>QAR 199</span>",
    "average_rating": "4.6",
    "review_count": 12,
    "images": [
      {
        "id": 1,
        "src": "https://cdn.example.com/p1.jpg",
        "thumbnail": "https://cdn.example.com/p1-thumb.jpg",
        "name": "Running Shoes",
        "alt": "Running Shoes"
      }
    ],
    "categories": [
      {
        "id": 10,
        "name": "Shoes",
        "slug": "shoes"
      }
    ],
    "brands": [
      {
        "id": 4,
        "name": "Nike",
        "slug": "nike"
      }
    ],
    "attributes": [
      {
        "id": 1,
        "name": "Size",
        "terms": [
          {
            "id": 11,
            "name": "UK 8",
            "slug": "uk-8"
          }
        ]
      }
    ],
    "variations": [
      {
        "attribute": "Size",
        "value": "UK 8"
      }
    ],
    "product_variations": [
      {
        "id": 991,
        "attributes": [
          {
            "name": "Size",
            "value": "UK 8"
          }
        ],
        "price": "199",
        "regular_price": "249",
        "sale_price": "199",
        "stock_status": "instock"
      }
    ],
    "has_options": true,
    "is_purchasable": true,
    "is_in_stock": true,
    "cart": false,
    "wishlist": true,
    "prices": {
      "currency_code": "QAR",
      "currency_symbol": "QAR",
      "price": "199",
      "regular_price": "249",
      "sale_price": "199"
    }
  }
}
```

### API: product reviews

`GET /products/reviews?product=101&lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Reviews fetched",
  "data": [
    {
      "id": 1,
      "date_created": "2026-03-20T10:00:00",
      "formatted_date_created": "March 20, 2026",
      "date_created_gmt": "2026-03-20T07:00:00",
      "product_id": 101,
      "product_name": "Running Shoes",
      "product_permalink": "https://example.com/products/running-shoes",
      "product_image": {
        "id": 1,
        "src": "https://cdn.example.com/p1.jpg",
        "thumbnail": "https://cdn.example.com/p1-thumb.jpg",
        "srcset": "",
        "sizes": "",
        "name": "Running Shoes",
        "alt": "Running Shoes"
      },
      "reviewer": "John Doe",
      "review": "Very good quality",
      "rating": 5,
      "verified": true,
      "reviewer_avatar_urls": {
        "24": "https://cdn.example.com/avatar.jpg"
      }
    }
  ]
}
```

### API: create review

`POST /products/reviews`

Payload:

```json
{
  "product_id": 101,
  "review": "Very good quality",
  "rating": 5,
  "reviewer": "John Doe",
  "reviewer_email": "john@example.com"
}
```

Response:

```json
{
  "success": true,
  "message": "Review submitted",
  "data": {
    "id": 501
  }
}
```

### API: can review

`GET /reviews/can-review/{productId}?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Review permission checked",
  "data": {
    "canReview": true,
    "reason": null
  }
}
```

This API is required because review entry should only be enabled if the user has completed or delivered purchase history for that product.

### API: related products

`GET /products/{productId}/related?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Related products fetched",
  "data": [
    {
      "id": 102,
      "name": "Training Shoes",
      "slug": "training-shoes",
      "on_sale": false,
      "average_rating": "4.3",
      "review_count": 9,
      "images": [
        {
          "id": 2,
          "src": "https://cdn.example.com/p2.jpg",
          "thumbnail": "https://cdn.example.com/p2-thumb.jpg"
        }
      ],
      "prices": {
        "currency_code": "QAR",
        "price": "220",
        "regular_price": "220",
        "sale_price": "220"
      }
    }
  ]
}
```

### Review requirement in Product Details screen

Product Details screen must support:

- showing review summary
- showing review list
- checking whether user can review
- submitting a review if eligible

The backend should therefore support this full review flow:

- `GET /products/reviews`
- `GET /reviews/can-review/{productId}`
- `POST /products/reviews`

## 12. Wishlist Screen

### API: add wishlist

`POST /wishlist/add?lang=en&currencyCode=QAR`

Payload:

```json
{
  "productId": "101",
  "productName": "Running Shoes",
  "productImage": "https://cdn.example.com/p1.jpg",
  "price": "199"
}
```

Response:

```json
{
  "success": true,
  "message": "Added to wishlist",
  "data": {
    "saved": true
  }
}
```

### API: get wishlist

`GET /wishlist/get?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Wishlist fetched",
  "data": [
    {
      "id": "wish_1",
      "productId": "101",
      "productName": "Running Shoes",
      "productImage": "https://cdn.example.com/p1.jpg",
      "price": "199",
      "createdAt": "2026-03-25T08:00:00.000Z"
    }
  ]
}
```

### API: remove wishlist

`DELETE /wishlist/remove?lang=en&currencyCode=QAR`

Payload:

```json
{
  "productId": "101"
}
```

Response:

```json
{
  "success": true,
  "message": "Removed from wishlist",
  "data": {
    "removed": true
  }
}
```

## 13. Cart Screen

### API: add to cart

`POST /cart/add`

Payload:

```json
{
  "productId": "101",
  "quantity": 2,
  "variation": [
    {
      "attribute": "Size",
      "value": "UK 8"
    }
  ],
  "currencyCode": "QAR"
}
```

Response:

```json
{
  "success": true,
  "message": "Added to cart",
  "data": {
    "cartCount": 3
  }
}
```

### API: get cart

`GET /cart/get?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Cart fetched",
  "data": [
    {
      "id": "cart_1",
      "userId": "usr_123",
      "productId": "101",
      "quantity": 2,
      "variation": [
        {
          "attribute": "Size",
          "value": "UK 8"
        }
      ],
      "title": "Running Shoes",
      "image": "https://cdn.example.com/p1.jpg",
      "price": "199",
      "couponCode": null,
      "discountPercentage": 0,
      "totalPrice": 398,
      "createdAt": "2026-03-25T09:00:00.000Z",
      "updatedAt": "2026-03-25T09:05:00.000Z"
    }
  ]
}
```

### API: update cart item

`PATCH /cart/update`

Payload:

```json
{
  "productId": "101",
  "quantity": 3
}
```

Response:

```json
{
  "success": true,
  "message": "Cart updated",
  "data": {
    "id": "cart_1",
    "productId": "101",
    "quantity": 3,
    "totalPrice": 597
  }
}
```

### API: remove cart item

`DELETE /cart/remove`

Payload:

```json
{
  "productId": "101"
}
```

Response:

```json
{
  "success": true,
  "message": "Item removed",
  "data": {
    "removed": true
  }
}
```

### API: apply coupon

`POST /cart/apply-coupon`

Payload:

```json
{
  "couponCode": "RAMADAN10"
}
```

Response:

```json
{
  "success": true,
  "message": "Coupon applied",
  "data": {
    "couponCode": "RAMADAN10",
    "discountPercentage": 10
  }
}
```

### API: cart with shipping totals

`POST /cart/get-with-shipping?lang=en&currencyCode=QAR`

Payload:

```json
{
  "couponCode": "RAMADAN10",
  "email": "john@example.com",
  "currencyCode": "QAR",
  "user": {
    "id": "usr_123"
  }
}
```

Response:

```json
{
  "success": true,
  "message": "Cart totals fetched",
  "data": {
    "items": [
      {
        "id": "cart_1",
        "productId": "101",
        "title": "Running Shoes",
        "quantity": 2,
        "price": 199,
        "total": 398
      }
    ],
    "summary": {
      "subTotal": 398,
      "discount": 39.8,
      "shippingCost": 25,
      "grandTotal": 383.2,
      "currencyCode": "QAR"
    },
    "coupon": {
      "code": "RAMADAN10",
      "discountPercentage": 10
    },
    "shippingMethods": [
      {
        "method_id": "flat_rate",
        "title": "Standard Shipping",
        "cost": 25
      }
    ]
  }
}
```

## 14. Checkout Payment Screen

### API: complete checkout

`POST /checkout/complete`

Payload:

```json
{
  "payment_method": "skipcash",
  "payment_data": [],
  "currencyCode": "QAR"
}
```

Response:

```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "sessionId": "sess_123",
    "orderId": "ord_123",
    "order": {
      "id": "ord_123",
      "wcOrderId": 4501,
      "wcOrderKey": "wc_key_123",
      "wcOrderStatus": "pending",
      "wcPaymentStatus": "pending",
      "currency": "QAR",
      "total": "383.2",
      "userId": "usr_123",
      "items": [],
      "customerData": {},
      "paymentMethod": "skipcash",
      "paymentData": [],
      "trackingUrl": "https://tracking.example.com/4501",
      "isPaid": false,
      "paidAt": null,
      "isDelivered": false,
      "deliveredAt": null,
      "skipCashPaymentUrl": "https://payment.skipcash.app/session/abc",
      "createdAt": "2026-03-25T09:30:00.000Z",
      "updatedAt": "2026-03-25T09:30:00.000Z"
    }
  }
}
```

## 15. Order Overview Screen

### API: order details by order id

`GET /checkout/order/{orderId}?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Order details fetched",
  "data": {
    "id": "ord_123",
    "wcOrderId": "4501",
    "userId": "usr_123",
    "wcOrderStatus": "processing",
    "wcPaymentStatus": "paid",
    "wcOrderKey": "wc_key_123",
    "payment_method": "skipcash",
    "skipCashPaymentUrl": "",
    "skipCashTransactionId": "txn_001",
    "customerName": "John Doe",
    "customerEmail": "john@example.com",
    "customerPhone": "+97450000000",
    "itemsCount": 2,
    "trackingUrl": "https://tracking.example.com/4501",
    "statusDisplay": "Processing",
    "currency": "QAR",
    "netTotal": 398,
    "discount": 39.8,
    "shippingCost": 25,
    "grandTotal": 383.2,
    "total": 383.2,
    "couponCode": "RAMADAN10",
    "createdAt": "2026-03-25T09:30:00.000Z",
    "paidAt": "2026-03-25T09:35:00.000Z",
    "deliveredAt": null,
    "isPaid": true,
    "isDelivered": false,
    "items": [],
    "customer_data": {}
  }
}
```

## 16. My Orders Screen

### API: all my orders

`GET /checkout/user/{userId}?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Orders fetched",
  "data": [
    {
      "id": "ord_123",
      "wcOrderId": "4501",
      "userId": "usr_123",
      "wcOrderStatus": "processing",
      "wcPaymentStatus": "paid",
      "wcOrderKey": "wc_key_123",
      "payment_method": "skipcash",
      "skipCashPaymentUrl": "",
      "skipCashTransactionId": "txn_001",
      "customerName": "John Doe",
      "customerEmail": "john@example.com",
      "customerPhone": "+97450000000",
      "itemsCount": 2,
      "trackingUrl": "https://tracking.example.com/4501",
      "statusDisplay": "Processing",
      "currency": "QAR",
      "netTotal": 398,
      "discount": 39.8,
      "shippingCost": 25,
      "grandTotal": 383.2,
      "total": 383.2,
      "couponCode": "RAMADAN10",
      "createdAt": "2026-03-25T09:30:00.000Z",
      "paidAt": "2026-03-25T09:35:00.000Z",
      "deliveredAt": null,
      "isPaid": true,
      "isDelivered": false,
      "items": [],
      "customer_data": {}
    }
  ]
}
```

### API: orders by status

`GET /checkout/status/{status}?lang=en&currencyCode=QAR`

Response:

Use the same response shape as My Orders.

## 17. Order Tracking Screen

### API: tracking

`GET /tracking/order/{orderId}?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Tracking fetched",
  "data": {
    "orderId": 4501,
    "orderStatus": "processing",
    "trackingItems": [
      {
        "status": "Package received",
        "location": "Doha Hub",
        "timestamp": "2026-03-25T10:00:00.000Z"
      }
    ],
    "totalTracking": 1,
    "shipping": {
      "first_name": "John",
      "last_name": "Doe",
      "company": "",
      "address_1": "Street 1",
      "address_2": "Building 20",
      "city": "Doha",
      "state": "Doha",
      "postcode": "00000",
      "country": "QA",
      "phone": "+97450000000"
    },
    "shippingLines": [
      {
        "id": 1,
        "method_title": "Standard Shipping",
        "method_id": "flat_rate",
        "instance_id": "1",
        "total": "25",
        "total_tax": "0",
        "taxes": [],
        "tax_status": "taxable",
        "meta_data": []
      }
    ]
  }
}
```

## 17A. Order Details Screen

Order Details screen should support:

- list of purchased items
- order summary
- delivery address
- payment method
- order status
- review action for each product once order is completed or delivered

### API: order details

`GET /checkout/order/{orderId}?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Order details fetched",
  "data": {
    "id": "ord_123",
    "wcOrderId": "4501",
    "userId": "usr_123",
    "wcOrderStatus": "completed",
    "wcPaymentStatus": "paid",
    "wcOrderKey": "wc_key_123",
    "payment_method": "skipcash",
    "skipCashPaymentUrl": "",
    "skipCashTransactionId": "txn_001",
    "customerName": "John Doe",
    "customerEmail": "john@example.com",
    "customerPhone": "+97450000000",
    "itemsCount": 2,
    "trackingUrl": "https://tracking.example.com/4501",
    "statusDisplay": "Completed",
    "currency": "QAR",
    "netTotal": 398,
    "discount": 39.8,
    "shippingCost": 25,
    "grandTotal": 383.2,
    "total": 383.2,
    "couponCode": "RAMADAN10",
    "createdAt": "2026-03-25T09:30:00.000Z",
    "paidAt": "2026-03-25T09:35:00.000Z",
    "deliveredAt": "2026-03-28T12:00:00.000Z",
    "isPaid": true,
    "isDelivered": true,
    "items": [
      {
        "id": "item_1",
        "image": "https://cdn.example.com/p1.jpg",
        "price": 199,
        "title": "Running Shoes",
        "userId": "usr_123",
        "quantity": 1,
        "productId": "101",
        "variation": [
          {
            "attribute": "Size",
            "value": "UK 8"
          }
        ],
        "couponCode": "RAMADAN10",
        "discountPercentage": 10,
        "createdAt": "2026-03-25T09:30:00.000Z",
        "updatedAt": "2026-03-25T09:30:00.000Z",
        "reviewEligibility": {
          "canReview": true,
          "reason": null,
          "alreadyReviewed": false
        }
      }
    ],
    "customer_data": {
      "shipping_address": {
        "first_name": "John",
        "last_name": "Doe",
        "address_1": "Street 1",
        "address_2": "Building 20",
        "city": "Doha",
        "state": "Doha",
        "postcode": "00000",
        "country": "QA",
        "phone": "+97450000000"
      }
    }
  }
}
```

### Review requirement in Order Details screen

Once the order is completed or delivered, each product in the order details screen should be able to:

- show whether it can be reviewed
- open add review flow
- submit review for that product

Required APIs for this flow:

- `GET /checkout/order/{orderId}?lang=en&currencyCode=QAR`
- `GET /reviews/can-review/{productId}?lang=en&currencyCode=QAR`
- `POST /products/reviews`

Suggested backend behavior:

- if possible, include `reviewEligibility` per order item inside order details response
- this reduces extra API calls from the app

## 18. Notifications Screen

### API: get notifications

`GET /users/notifications/me?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Notifications fetched",
  "data": [
    {
      "id": "noti_1",
      "userId": "usr_123",
      "title": "Order shipped",
      "body": "Your order #4501 has been shipped",
      "data": {
        "type": "order",
        "orderId": "ord_123"
      },
      "isRead": false,
      "createdAt": "2026-03-25T10:00:00.000Z"
    }
  ]
}
```

### API: mark notification read

`PATCH /users/notifications/{id}/read?lang=en&currencyCode=QAR`

Payload:

```json
{}
```

Response:

```json
{
  "success": true,
  "message": "Notification updated",
  "data": {
    "id": "noti_1",
    "isRead": true
  }
}
```

### API: mark all read

`PATCH /users/notifications/read-all?lang=en&currencyCode=QAR`

Payload:

```json
{}
```

Response:

```json
{
  "success": true,
  "message": "All notifications marked as read",
  "data": {
    "done": true
  }
}
```

## 19. Profile Screen

### API: get profile

`GET /users/{userId}?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Profile fetched",
  "data": {
    "id": "usr_123",
    "email": "john@example.com",
    "phone": "+97450000000",
    "fullName": "John Doe",
    "isActive": true,
    "role": "customer",
    "notificationToken": "fcm_xxx",
    "createdAt": "2026-03-25T08:00:00.000Z",
    "updatedAt": "2026-03-25T08:00:00.000Z"
  }
}
```

## 20. My Info / Edit Profile Screen

### API: update profile

`PATCH /users/{userId}`

Payload:

```json
{
  "fullName": "John A. Doe",
  "email": "john@example.com",
  "phone": "+97450000000"
}
```

Response:

```json
{
  "success": true,
  "message": "Profile updated",
  "data": {
    "id": "usr_123",
    "email": "john@example.com",
    "phone": "+97450000000",
    "fullName": "John A. Doe",
    "isActive": true,
    "role": "customer",
    "notificationToken": "fcm_xxx",
    "createdAt": "2026-03-25T08:00:00.000Z",
    "updatedAt": "2026-03-25T10:15:00.000Z"
  }
}
```

## 21. Account Settings Screen

### API: delete account

`DELETE /users/{userId}`

Response:

```json
{
  "success": true,
  "message": "Account deleted",
  "data": {
    "deleted": true
  }
}
```

## 22. Change Language Screen

### API: language list

`GET /utility/languages?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Languages fetched",
  "data": [
    {
      "code": "en",
      "name": "English",
      "isDefault": true
    },
    {
      "code": "ar",
      "name": "Arabic",
      "isDefault": false
    }
  ]
}
```

## 23. Change Currency Screen

### API: currency list

`GET /currency/list?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Currencies fetched",
  "data": [
    {
      "code": "QAR",
      "symbol": "QAR",
      "name": "Qatari Riyal",
      "minorUnit": 2,
      "decimalSeparator": ".",
      "thousandSeparator": ",",
      "prefix": "QAR ",
      "suffix": null
    }
  ]
}
```

### API: update selected currency

`PATCH /users/{userId}/currency`

Payload:

```json
{
  "currency": "USD"
}
```

Response:

```json
{
  "success": true,
  "message": "Currency updated",
  "data": {
    "currency": "USD"
  }
}
```

### API: currency rates

`GET /utility/currency-rates?base=QAR`

Response:

```json
{
  "success": true,
  "message": "Rates fetched",
  "data": {
    "base": "QAR",
    "rates": {
      "USD": 0.27,
      "EUR": 0.25,
      "SAR": 1.03
    },
    "updatedAt": "2026-03-25T10:00:00.000Z"
  }
}
```

## 24. Help Screen

### API: help content

`GET /cms/help?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Help content fetched",
  "data": {
    "sections": [
      {
        "title": "Shipping and Delivery",
        "questions": [
          {
            "question": "How long does shipping take?",
            "answer": "Shipping usually takes 3 to 5 business days."
          }
        ]
      }
    ],
    "contact": {
      "whatsapp": "+97477223333",
      "email": "info@camiontrading.com"
    }
  }
}
```

## 24A. App Static Design Content

Some screens are visually static in the UI, but their content should still be available from backend so the design can be changed without app release.

This includes:

- Home section labels
- Home promo cards
- Settings menu items
- Join affiliate / join influencer welcome text
- Pending / rejected copy
- Empty states
- Support contact values

### API: app UI content

`GET /cms/app-ui?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "App UI content fetched",
  "data": {
    "home": {
      "tabs": [
        { "id": "all", "label": "All" },
        { "id": "popular_products", "label": "Popular Products" },
        { "id": "top_sales", "label": "Top Sales" },
        { "id": "recommended", "label": "Recommended" }
      ],
      "promoCards": [
        {
          "id": "join_us",
          "title": "Join Our Team",
          "description": "Become part of Camion and start earning with us.",
          "buttonText": "Join Us"
        }
      ]
    },
    "settings": {
      "items": [
        {
          "id": "change_language",
          "title": "Change Language"
        },
        {
          "id": "help",
          "title": "Help"
        },
        {
          "id": "chat_support",
          "title": "Chat Support"
        }
      ]
    },
    "affiliate": {
      "welcome": {
        "title": "Welcome",
        "subtitle": "Start your affiliate journey with Camion."
      },
      "pending": {
        "title": "Application Under Review",
        "subtitle": "We are currently reviewing your request."
      },
      "rejected": {
        "title": "Application Rejected",
        "subtitle": "You can apply again later."
      }
    },
    "influencer": {
      "welcome": {
        "title": "Welcome",
        "subtitle": "Start your influencer journey with Camion."
      },
      "pending": {
        "title": "Application Under Review",
        "subtitle": "We are currently reviewing your request."
      },
      "rejected": {
        "title": "Application Rejected",
        "subtitle": "You can apply again later."
      }
    },
    "emptyStates": {
      "wishlist": {
        "title": "No wishlist items yet",
        "subtitle": "Start saving products you like."
      },
      "notifications": {
        "title": "No notifications yet",
        "subtitle": "We will show updates here."
      },
      "coupons": {
        "title": "No coupons found",
        "subtitle": "Your coupon list will appear here."
      }
    },
    "support": {
      "email": "info@camiontrading.com",
      "whatsapp": "+97477223333"
    }
  }
}
```

## 25. Privacy / Return Policy Screen

### API: policies

`GET /cms/policies?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Policies fetched",
  "data": {
    "title": "Privacy Policy",
    "sections": [
      {
        "title": "Terms of Use",
        "points": [
          "Point one",
          "Point two"
        ]
      },
      {
        "title": "Return Policy",
        "points": [
          "Point one",
          "Point two"
        ]
      }
    ]
  }
}
```

## 26. Feedback Screen

### API: submit feedback

`POST /feedback`

Payload:

```json
{
  "subject": "App feedback",
  "message": "Checkout experience is good but needs clearer steps",
  "rating": 4,
  "channel": "mobile-app"
}
```

Response:

```json
{
  "success": true,
  "message": "Feedback submitted",
  "data": {
    "saved": true
  }
}
```

## 27. Affiliate / Influencer Join Screen

### API: submit affiliate request

`POST /affiliates/request`

Payload:

```json
{
  "fullName": "John Doe",
  "gender": "male",
  "nationality": "Qatari",
  "bio": "Content creator focused on fashion"
}
```

Response:

```json
{
  "success": true,
  "message": "Request submitted",
  "data": {
    "affiliateId": "aff_123",
    "status": "pending"
  }
}
```

## 28. Affiliate / Influencer Status Screen

### API: my affiliate status

`GET /affiliates/me/status?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Affiliate status fetched",
  "data": {
    "affiliateId": "aff_123",
    "fullName": "John Doe",
    "status": "approved",
    "token": "affiliate_token_optional"
  }
}
```

## 29. Affiliate / Influencer Account Screen

### API: affiliate stats

`GET /affiliates/stats/me?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Affiliate stats fetched",
  "data": {
    "affiliate": {
      "id": "aff_123",
      "fullName": "John Doe",
      "status": "approved",
      "type": "influencer"
    },
    "walletBalance": 245.5,
    "totalEarnings": 1220.75,
    "couponsCreated": 4,
    "ordersCount": 18,
    "totalCommission": 245.5,
    "currencyCode": "QAR"
  }
}
```

## 30. Create Coupon Screen

### API: create coupon

`POST /affiliates/coupon`

Payload:

```json
{
  "code": "JOHN10",
  "discountPercentage": 10,
  "expiryDate": "2026-12-31"
}
```

Response:

```json
{
  "success": true,
  "message": "Coupon created",
  "data": {
    "id": "coupon_1",
    "code": "JOHN10",
    "discountPercentage": 10,
    "commissionPercentage": 5,
    "isActive": true
  }
}
```

## 31. My Coupons Screen

### API: my coupons

`GET /affiliates/coupon/me?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Coupons fetched",
  "data": [
    {
      "id": "coupon_1",
      "code": "JOHN10",
      "isActive": true,
      "discountPercentage": 10,
      "commissionPercentage": 5,
      "createdAt": "2026-03-25T10:00:00.000Z",
      "affiliate": {
        "id": "aff_123",
        "userId": "usr_123",
        "fullName": "John Doe",
        "gender": "male",
        "nationality": "Qatari",
        "status": "approved",
        "type": "influencer",
        "totalEarnings": 1220.75,
        "couponsCreated": 4,
        "bio": "Content creator focused on fashion",
        "referralLink": "https://camion.app/ref/aff_123",
        "walletBalance": 245.5,
        "createdAt": "2026-03-01T00:00:00.000Z",
        "updatedAt": "2026-03-25T10:00:00.000Z"
      },
      "orders": [
        {
          "orderId": "ord_123",
          "wcOrderId": "4501",
          "userId": "usr_999",
          "buyerName": "Customer A",
          "buyerEmail": "customer@example.com",
          "commission": 5.25,
          "total": 105,
          "createdAt": "2026-03-25T10:00:00.000Z",
          "products": []
        }
      ]
    }
  ]
}
```

## 32. Wallet Screen

### API: wallet balance

`GET /affiliates/wallet?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Wallet fetched",
  "data": {
    "balance": 245.5,
    "currencyCode": "QAR",
    "pending": 40,
    "available": 205.5
  }
}
```

### API: wallet transactions

`GET /affiliates/wallet/transactions?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Transactions fetched",
  "data": [
    {
      "id": "txn_1",
      "amount": 25.5,
      "description": "Commission for order #4501",
      "createdAt": "2026-03-25T10:00:00.000Z"
    }
  ]
}
```

## 33. Chatbot Screen

### API: create chat session

`POST /api/chatbot/sessions`

Payload:

```json
{
  "userId": "usr_123"
}
```

Response:

```json
{
  "success": true,
  "message": "Chat session created",
  "data": {
    "sessionId": "chat_123"
  }
}
```

### API: chat history

`GET /api/chatbot/sessions/{sessionId}/history?lang=en&currencyCode=QAR`

Response:

```json
{
  "success": true,
  "message": "Chat history fetched",
  "data": {
    "sessionId": "chat_123",
    "messages": [
      {
        "role": "user",
        "content": "What is your return policy?",
        "timestamp": "2026-03-25T10:00:00.000Z",
        "sources": []
      },
      {
        "role": "assistant",
        "content": "You can return items within 14 days.",
        "timestamp": "2026-03-25T10:00:02.000Z",
        "sources": [
          {
            "title": "Return Policy",
            "content": "Returns accepted within 14 days",
            "category": "policy",
            "relevanceScore": 0.94
          }
        ]
      }
    ]
  }
}
```

### API: ask chatbot

`POST /api/chatbot/sessions/{sessionId}/ask`

Payload:

```json
{
  "question": "What is your return policy?",
  "limit": 5,
  "category": "policy"
}
```

Response:

```json
{
  "success": true,
  "message": "Chat answer fetched",
  "data": {
    "sessionId": "chat_123",
    "answer": "You can return items within 14 days.",
    "sources": [
      {
        "title": "Return Policy",
        "content": "Returns accepted within 14 days",
        "category": "policy",
        "relevanceScore": 0.94
      }
    ]
  }
}
```

## 34. Suggested Single Ownership View For Backend Team

Even if backend is split internally, the mobile app should receive this as one full contract:

- Auth and profile
- Address and utility data
- Home and catalog
- Product details and reviews
- Wishlist
- Cart and checkout
- Orders and tracking
- Notifications
- CMS content like help and policies
- Affiliate and wallet
- Chatbot

That way the mobile team can build every screen using one clear API document.

## Final Note

This document is intended to be shared directly with:

- backend team for implementation
- project lead for evaluation and prioritization

If any field is missing during implementation, especially around product variations or section metadata, those can be finalized on the go as part of backend and app integration, while keeping the screen-level API coverage defined in this document intact.
