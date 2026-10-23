# Feature Implementation: Anonymous Browsing for Cart

## Current State

- Anonymous browsing already implemented for products and home screen
- Backend team has added `x-guest-id` header support

## Implementation Requirements

1. **Frontend Changes**

   - Generate guest ID in app (store in `flutter_secure_storage` with key `guestId`)
   - Include `x-guest-id` header in all requests

2. **User Flow**
   - Anonymous users can browse/add to cart
   - Purchase attempt redirects to login
   - During OTP verification:
     - Send `x-guest-id` header
     - Link cart to user account

## API References

- [Get Cart API](https://mohamedamin-8823854.postman.co/workspace/TAJ~703b00db-89aa-4199-b705-02a281b00e08/request/46629053-939d6477-5442-43a5-adef-c91a2e391b23?action=share&source=copy-link&creator=48723488&ctx=documentation)
- [Add to Cart API](https://mohamedamin-8823854.postman.co/workspace/TAJ~703b00db-89aa-4199-b705-02a281b00e08/request/46629053-92f0123a-4146-42d9-9b31-416f5108c965?action=share&source=copy-link&creator=48723488&ctx=documentation)
