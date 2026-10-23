# Anonymous Browsing Implementation Plan

## Goals
- Allow unauthenticated users to browse and search products without requiring login.
- Keep authentication required for protected actions: add to cart, wishlist, orders, checkout, profile, notifications, wallet, affiliate.

## Current Architecture Summary
- Routing: `GoRouter` (`lib/routing/router_generator.dart`). Initial route gated by `isLoggedInUser` from `lib/main_production.dart`.
- Auth state: token stored in `SecureCacheHelper` (`flutter_secure_storage`).
- Data: `Dio` via `ApiConsumer` and feature repositories.
- State: `flutter_bloc`.
- Home browsing: public endpoints for list/search/categories/on sale/reviews.
- Product details: currently requires token (must be made public).
- Protected endpoints: cart and wishlist repos/data sources require `Authorization: Bearer <token>`.

## Key Findings
- `initialLocation` forces login for anonymous users:
  - `lib/routing/router_generator.dart` sets `initialLocation` to `AppRouter.selectingFromBottomNavBar` if logged in, otherwise `AppRouter.login`.
- Product details requires token:
  - `lib/features/home/data/data_source/remote_data_source.dart#getProductById` requires token header.
  - `lib/features/home/data/repository/home_repo.dart#getProductById` requires token.
  - `lib/features/home/presentation/logic/cubit/product_id_detailscubit/product_id_details_cubit.dart#getProductDetails` force-unwraps token.
- Home screen triggers tokened calls on init (will crash for anonymous):
  - `SendFcmTokenCubit.sendFcmToken()` (force-unwraps token inside cubit)
  - `GetWishListCubit.getWishList()` (force-unwraps token)
  - `GetCartCubit.getCart()` (force-unwraps token)
- Bottom nav does not gate protected tabs (OrderStatus, Wishlist, Profile) and PageView lazily builds them.
- Cart/Wishlist cubits force-unwrap token; must prevent calling them when anonymous.

## Public vs Protected
- Public routes/screens:
  - `SelectingFromBottomNavBar` (default to Home tab)
  - `HomeScreen`
  - `SearchScreenWithProducts`
  - `ProductsByCategoryScreen`, `AllCategoriesScreen`, `ProductsOnSaleScreen`
  - `ProductDetails` (after changes)
  - `FullScreenImage`, `HelpScreen`, `ChangeLanguageScreen`, `ChangeCurrencyScreen`, `PrivacyAndReturnPolicyScren`
- Protected routes/screens:
  - Cart/Checkout: `MyCartScreen`, `ConfirmPaymentScreen`, `ConfirmAddress`, `ConfirmShippingAddressScreen`, `PaymentWebViewPage`
  - Wishlist: `WishListScreen`, add/remove wishlist actions
  - Orders: `OrderStatusScreen`, `OrderDetailsScreen`, `OrderTrackingWebView`
  - Profile: `ProfileScreen`, `MyInfoScreen`, `EditInfoScreen`, `AccountSettingsScreen`, `MyWalletScreen`
  - Notifications: `NotificationsScreen`
  - Affiliate: `JoinUsScreen`, `AffiliateCheckScreen`, `MyCouponsScreen`, `CreateCodeScreen`, `SelectSocialMediaScreen`, `SelectCountriesOfSupplier`, `AffiliateAccountScreen`, `WelcomeScreen`

## Implementation Steps

1) Routing: allow anonymous entry and guard protected routes
- Change `initialLocation` to always `AppRouter.selectingFromBottomNavBar`.
- Add `redirect` guards to protected routes to require token; if unauthenticated, redirect to `AppRouter.login` (optionally pass intended destination via `extra`).
- Protected routes to guard: cart/checkout flow, wishlist screen, orders, profile pages, notifications, wallet/affiliate, order tracking, etc.

2) Bottom Nav gating
- In `lib/config/widgets/selecting_from_bottom_navbar.dart`, gate taps for indices 1 (Orders), 2 (Wishlist), 3 (Profile):
  - If no token: push `AppRouter.login` and do not change page.
  - Else: jump to the selected page.

3) Product details public access
- In `HomeRemoteDataSource.getProductById`, make `token` optional and only add Authorization header if present.
- In `HomeRepository.getProductById`, accept `String? token` and pass through.
- In `ProductIdDetailsCubit.getProductDetails`, fetch token optionally and pass nullable token (remove force-unwrap).

4) Home screen: avoid tokened calls when anonymous
- In `HomeScreen.initState()` and refresh methods, only call:
  - Public endpoints: `ProductsCubit.getProducts`, `GetCategoriesCubit.getCategories`, `SlidersCubit.getSliders`, `StoriesCubit.getStories` (if backend allows; otherwise ignore 401).
  - Tokened endpoints (`SendFcmTokenCubit.sendFcmToken`, `GetWishListCubit.getWishList`, `GetCartCubit.getCart`) only when token is present.

5) Guard protected actions in UI
- In `product_details.dart` and product list/grid item widgets, before calling:
  - `AddCartCubit.addToCart` or `AddToWishListCubit.addtoWishList`:
    - If no token: navigate to `AppRouter.login` and abort the action.
    - Else: proceed with the cubit call.

6) Optional defensive coding
- Cubits that rely on token (`AddCartCubit`, `GetCartCubit`, `AddToWishListCubit`, `GetWishListCubit`, `SendFcmTokenCubit`) should early-return or emit a friendly error if token is null to avoid crashes when invoked by mistake.

## Files To Change (exact locations)
- `lib/routing/router_generator.dart`
  - Set `initialLocation: AppRouter.selectingFromBottomNavBar`.
  - Add `redirect` guards for protected routes.
- `lib/config/widgets/selecting_from_bottom_navbar.dart`
  - Gate `onTap` for indices 1,2,3 with token check.
- `lib/features/home/data/data_source/remote_data_source.dart`
  - `getProductById`: make `token` optional and add header conditionally.
- `lib/features/home/data/repository/home_repo.dart`
  - `getProductById`: accept `String? token` and pass through.
- `lib/features/home/presentation/logic/cubit/product_id_detailscubit/product_id_details_cubit.dart`
  - Read token optionally; remove force-unwrap; call repo with nullable token.
- `lib/features/home/presentation/screens/home_screen.dart`
  - Wrap tokened calls with token check in `initState`, refresh, and helper methods.
- `lib/features/home/presentation/screens/product_details.dart`
  - Before calling wishlist/add-to-cart cubits, check token; redirect to login if missing.
- Optionally: add defensive checks inside cart/wishlist cubits to avoid null token usage.

## Security Considerations
- All state-mutating endpoints continue to require token; anonymous users cannot perform them.
- Token checks at route and UI levels prevent invoking tokened cubits while unauthenticated.
- Product read endpoints remain public; details endpoint becomes public for read-only access.

## Post-Login Return UX (optional)
- When redirecting to login from a protected action, pass the intended destination (via `extra`) and return after successful verification. Minimal viable is to return to the Home tab.

## Rollout Order
1. Router initial route + per-route guards.
2. Bottom nav gating.
3. Product details public access (data + cubit).
4. Home screen token-guarded fetches.
5. UI gating for protected actions.
6. Defensive checks in cubits (optional).

## Testing Checklist
- Launch app signed-out: should land on Home and list products.
- Search and open product details without login.
- Tap Wishlist or Orders or Profile tabs → should open Login.
- Add to cart or wishlist from lists/details while anonymous → should open Login.
- After login, retry actions should work; tokened lists (wishlist/cart) load without error.
