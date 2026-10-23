# Affiliate Dashboard + Influencer Dashboard API Doc

This doc reflects the current app implementation in `camion-app-v2` and is intended to be shared with backend/API teammates.

Date: 2026-04-09

## Common Notes

- Base URL: `EndPoints.baseUrl`
- Auth header required on all dashboard endpoints:

```http
Authorization: Bearer <token>
```

- The app currently uses:
  - separate affiliate and influencer endpoints for `request`, `status`, and `stats`
  - shared affiliate endpoints for coupon creation, coupon listing, wallet balance, and wallet transactions

## Quick Endpoint List

| Area | Method | Endpoint |
|---|---|---|
| Affiliate join | `POST` | `/affiliates/request` |
| Affiliate status | `GET` | `/affiliates/me/status` |
| Affiliate stats | `GET` | `/affiliates/stats/me?lang=<lang>&currencyCode=<currencyCode>` |
| Influencer join | `POST` | `/influencers/request` |
| Influencer status | `GET` | `/influencers/me/status` |
| Influencer stats | `GET` | `/influencers/stats/me?lang=<lang>&currencyCode=<currencyCode>` |
| Shared coupon create | `POST` | `/affiliates/coupon` |
| Shared coupon list | `GET` | `/affiliates/coupon/me` |
| Shared wallet balance | `GET` | `/affiliates/wallet` |
| Shared wallet transactions | `GET` | `/affiliates/wallet/transactions` |

## 1. Affiliate Dashboard Endpoints

### 1.1 Submit Affiliate Request

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

Response currently expected by app:

```json
{
  "id": "aff_123",
  "userId": "usr_123",
  "fullName": "John Doe",
  "gender": "male",
  "nationality": "Qatari",
  "status": "pending",
  "totalEarnings": 0,
  "couponsCreated": 0,
  "bio": "Content creator focused on fashion",
  "referralLink": null,
  "createdAt": "2026-04-09T10:00:00.000Z",
  "updatedAt": "2026-04-09T10:00:00.000Z"
}
```

### 1.2 Get Affiliate Status

`GET /affiliates/me/status`

Response currently expected by app:

```json
{
  "affiliateId": "aff_123",
  "fullName": "John Doe",
  "status": "approved",
  "token": "affiliate_token_optional"
}
```

### 1.3 Get Affiliate Stats

`GET /affiliates/stats/me?lang=en&currencyCode=QAR`

Response currently expected by app:

```json
{
  "affiliateId": "aff_123",
  "type": "affiliate",
  "totalCommission": 245.5,
  "totalPaid": 120.0,
  "remainingBalance": 125.5,
  "couponsUsedCount": 18,
  "trendingCoupon": null,
  "topProduct": null,
  "message": "Affiliate stats fetched"
}
```

### 1.4 Create Coupon

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
  "message": "Coupon created"
}
```

Note: the repository currently accepts any JSON object here, so extra fields are fine.

### 1.5 Get My Coupons

`GET /affiliates/coupon/me`

Response currently expected by app:

```json
[
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
      "type": "affiliate",
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
```

### 1.6 Get Wallet Balance

`GET /affiliates/wallet`

Minimum response the wallet screen currently needs:

```json
{
  "walletBalance": 245.5
}
```

Recommended richer response:

```json
{
  "walletBalance": 245.5,
  "currencyCode": "QAR",
  "pending": 40,
  "available": 205.5
}
```

### 1.7 Get Wallet Transactions

`GET /affiliates/wallet/transactions`

Response currently expected by app:

```json
[
  {
    "id": "txn_1",
    "amount": 25.5,
    "description": "Commission for order #4501",
    "createdAt": "2026-03-25T10:00:00.000Z"
  }
]
```

## 2. Influencer Dashboard Endpoints

### 2.1 Submit Influencer Request

`POST /influencers/request`

Payload:

```json
{
  "fullName": "Jane Doe",
  "gender": "female",
  "nationality": "Qatari",
  "bio": "Lifestyle and beauty influencer"
}
```

Response currently expected by app:

```json
{
  "id": "inf_123",
  "userId": "usr_456",
  "fullName": "Jane Doe",
  "gender": "female",
  "nationality": "Qatari",
  "status": "pending",
  "totalEarnings": 0,
  "couponsCreated": 0,
  "bio": "Lifestyle and beauty influencer",
  "referralLink": null,
  "createdAt": "2026-04-09T10:00:00.000Z",
  "updatedAt": "2026-04-09T10:00:00.000Z"
}
```

### 2.2 Get Influencer Status

`GET /influencers/me/status`

Response currently expected by app:

```json
{
  "affiliateId": "inf_123",
  "fullName": "Jane Doe",
  "status": "approved",
  "token": "influencer_token_optional"
}
```

### 2.3 Get Influencer Stats

`GET /influencers/stats/me?lang=en&currencyCode=QAR`

Response currently expected by app:

```json
{
  "affiliateId": "inf_123",
  "type": "influencer",
  "totalCommission": 420.0,
  "totalPaid": 200.0,
  "remainingBalance": 220.0,
  "couponsUsedCount": 31,
  "trendingCoupon": null,
  "topProduct": null
}
```

### 2.4 Shared Coupon + Wallet APIs Used by Influencer Flow

The influencer flow currently calls the same shared endpoints as affiliate for:

- `POST /affiliates/coupon`
- `GET /affiliates/coupon/me`
- `GET /affiliates/wallet`
- `GET /affiliates/wallet/transactions`

For influencer users, the response shape is the same as affiliate, but the nested `affiliate.type` should ideally be:

```json
{
  "type": "influencer"
}
```

## 3. Important Implementation Note

There is an older backend requirements doc in the repo that uses wrapped responses like:

```json
{
  "success": true,
  "message": "OK",
  "data": {}
}
```

But the current app code for these dashboard endpoints mostly parses raw objects/lists directly.

So if this is being implemented right now, the safest contract for the current app is:

- raw object for `request`
- raw object for `status`
- raw object for `stats`
- raw array for `coupon/me`
- raw object for `wallet`
- raw array for `wallet/transactions`

