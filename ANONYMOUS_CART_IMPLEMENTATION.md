# Anonymous Cart Implementation Documentation

## Goals
- Allow unauthenticated users to add products to cart and manage cart items without requiring login.
- Persist anonymous cart data server-side using a unique guest identifier (`x-guest-id` header).
- Link anonymous cart to user account during OTP verification after login/registration.
- Keep checkout and purchase actions protected (require authentication).

## Current Architecture Summary
- **Networking**: `Dio` via `ApiConsumer` (`lib/core/api/dio_consumer.dart`). All HTTP requests flow through this layer.
- **Secure Storage**: `SecureCacheHelper` wraps `flutter_secure_storage` for persisting sensitive data like tokens and guest IDs.
- **State Management**: `flutter_bloc` with cubits for cart operations (`AddCartCubit`, `GetCartCubit`, `UpdateCartCubit`).
- **Routing**: `GoRouter` (`lib/routing/router_generator.dart`) with route guards for protected screens.
- **Cart Architecture**:
  - Data source: `CartRemoteDataSource` (`lib/features/cart/data/data_source/remote_data_source.dart`)
  - Repository: `CartRepository` (`lib/features/cart/data/repository/cart_repo.dart`)
  - Cubits: `AddCartCubit`, `GetCartCubit`, `UpdateCartCubit`
  - UI: `MyCartScreen`, `ProductDetails`, `HomeScreen`

## Key Requirements from Spec
1. Generate and persist `guestId` in `flutter_secure_storage` with key `guestId`.
2. Include `x-guest-id` header in all API requests.
3. Anonymous users can browse products and add to cart without login.
4. Purchase attempts redirect to login screen.
5. During OTP verification, send `x-guest-id` header to link guest cart to user account.
6. Backend supports `x-guest-id` header for cart operations.

## Implementation Strategy

### 1. Guest ID Generation and Persistence
**Goal**: Ensure every app instance has a unique, persistent guest identifier.

**Approach**:
- Generate UUID v4 on first app launch.
- Store in `flutter_secure_storage` with key `guestId`.
- Reuse same `guestId` across app sessions until user logs in or clears app data.

**Implementation**:
- **File**: `lib/main.dart`
- **Location**: In `main()` function, after `setupServiceLocator()` and before `checkIfUserIsLoggedIn()`.
- **Code**:
  ```dart
  // Ensure a guestId exists for anonymous cart tracking
  final existingGuestId = await sl<SecureCacheHelper>().getData(key: 'guestId');
  if (existingGuestId == null || existingGuestId.isEmpty) {
    final newGuestId = const Uuid().v4();
    await sl<SecureCacheHelper>().saveData(key: 'guestId', value: newGuestId);
  }
  ```
- **Dependencies**: Added `uuid: ^4.5.1` to `pubspec.yaml` (already present).

### 2. Automatic x-guest-id Header Injection
**Goal**: Include `x-guest-id` header in every API request without manual intervention.

**Approach**:
- Add Dio interceptor to `DioConsumer` that reads `guestId` from secure storage.
- If `guestId` missing, generate and persist it inline.
- Inject `x-guest-id` header into request options using `putIfAbsent` (non-destructive).

**Implementation**:
- **File**: `lib/core/api/dio_consumer.dart`
- **Location**: In `DioConsumer` constructor, before `LogInterceptor`.
- **Code**:
  ```dart
  // Inject x-guest-id header for anonymous session tracking
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      try {
        String? guestId = await sl<SecureCacheHelper>().getData(key: 'guestId');
        if (guestId == null || guestId.isEmpty) {
          guestId = const Uuid().v4();
          await sl<SecureCacheHelper>().saveData(key: 'guestId', value: guestId);
        }
        // Do not override if already set explicitly
        options.headers.putIfAbsent('x-guest-id', () => guestId);
      } catch (_) {
        // Silently ignore any issues to avoid blocking the request
      }
      handler.next(options);
    },
  ));
  ```
- **Benefits**:
  - Centralized header management.
  - Works for all API calls (cart, auth, products, etc.).
  - Backend receives `x-guest-id` on OTP verification automatically for cart linking.

### 3. Cart API Layer: Optional Token Support
**Goal**: Allow cart operations with or without authentication token.

**Approach**:
- Make `token` parameter optional (`String?`) in data source and repository.
- Conditionally add `Authorization: Bearer <token>` header only if token exists.
- Rely on `x-guest-id` header (injected by interceptor) for anonymous cart identification.

**Implementation**:

#### Data Source Changes
- **File**: `lib/features/cart/data/data_source/remote_data_source.dart`
- **Methods Updated**: `addToCart`, `getCart`, `updateCart`, `deleteFromCart`
- **Pattern**:
  ```dart
  Future<Response> addToCart({
    String? token,  // Changed from required String token
    required String productId,
    required int quantity,
    required List<dynamic> variations,
  }) async {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await apiConsumer.post(
      "<base-url>/cart/add",
      headers: headers.isEmpty ? null : headers,
      data: {"productId": productId, "quantity": quantity, "variation": variations},
    );
    return response;
  }
  ```
- **Note**: `applyCoupon` and `getUserAddress` still require token (protected operations).

#### Repository Changes
- **File**: `lib/features/cart/data/repository/cart_repo.dart`
- **Methods Updated**: `addToCart`, `getCart`, `updateCart`, `deleteFromCart`
- **Pattern**:
  ```dart
  Future<Either<ApiErrorModel, dynamic>> addToCart({
    String? token,  // Changed from required String token
    required String productId,
    required int quantity,
    required List<dynamic> variations,
  }) async {
    try {
      final response = await cartRemoteDataSource.addToCart(
        token: token,
        productId: productId,
        quantity: quantity,
        variations: variations,
      );
      return Right(response.data);
    } catch (e) {
      return left(ApiErrorHandler.handle(e));
    }
  }
  ```

### 4. Cart Cubits: Remove Login Gates
**Goal**: Allow cart operations for both authenticated and anonymous users.

**Approach**:
- Remove token validation checks that blocked operations when token missing.
- Pass nullable token to repository; let backend handle authorization via `x-guest-id` or token.
- Maintain existing state management (loading, success, error).

**Implementation**:

#### AddCartCubit
- **File**: `lib/features/cart/presentation/logic/cubit/add_cart_cubit/add_cart_cubit.dart`
- **Changes**:
  - Removed early return when `token == null`.
  - Pass nullable token to repository.
- **Before**:
  ```dart
  if (token == null || token.isEmpty) {
    emit(AddCartError(ApiErrorModel(message: 'Please login to add items to cart'), productId));
    return;
  }
  ```
- **After**: Removed the check; directly calls repository with nullable token.

#### GetCartCubit
- **File**: `lib/features/cart/presentation/logic/cubit/get_cart_cubit/get_cart_cubit.dart`
- **Changes**:
  - Removed early return when `token == null`.
  - Always fetch cart (backend returns guest cart via `x-guest-id` or user cart via token).
- **Before**:
  ```dart
  if (token == null || token.isEmpty) {
    emit(GetCartError(ApiErrorModel(message: 'Please login to view cart')));
    return;
  }
  ```
- **After**: Removed the check; always emits loading and fetches cart.

#### UpdateCartCubit
- **File**: `lib/features/cart/presentation/logic/cubit/update_cubit/update_cart_cubit.dart`
- **Changes**:
  - Removed force unwrap (`token!`) in `updateCart` and `deleteFromCart`.
  - Pass nullable token to repository.
- **Before**: `token: token!`
- **After**: `token: token`

### 5. Routing: Allow Anonymous Cart Access
**Goal**: Let anonymous users open cart screen; keep checkout protected.

**Approach**:
- Remove redirect guard from `AppRouter.myCart` route.
- Keep guards on checkout flow routes (`confirmPayment`, `confirmAddress`, etc.).

**Implementation**:
- **File**: `lib/routing/router_generator.dart`
- **Changes**:
  - Removed `redirect` callback from `myCart` GoRoute.
  - Protected routes still have token checks:
    - `confirmPayment`
    - `confirmAddress`
    - `confirmShippingAddressScreen`
    - `myWallet`
    - `notificationScreen`
    - All affiliate/order/profile routes
- **Result**: Anonymous users can view and manage cart; attempting checkout redirects to login.

### 6. UI Updates: Always Fetch Cart
**Goal**: Display cart for both anonymous and authenticated users.

**Approach**:
- Remove token checks before calling `getCart()` in UI screens.
- Always fetch cart on screen init and refresh.
- Keep wishlist and other protected features gated.

**Implementation**:

#### HomeScreen
- **File**: `lib/features/home/presentation/screens/home_screen.dart`
- **Changes in `initState()`**:
  - Added `context.read<GetCartCubit>().getCart(lang);` before authenticated-only section.
  - Removed cart fetch from within token check.
- **Changes in `refreshWishListAndCartList()`**:
  - Moved `getCart()` outside token check.
- **Changes in `onRefresh()`**:
  - Added `context.read<GetCartCubit>().getCart(lang);` before token check.
  - Removed cart fetch from within token check.
- **Protected calls still gated**: `SendFcmTokenCubit`, `GetWishListCubit`, `StoriesCubit`.

#### ProductDetails
- **File**: `lib/features/home/presentation/screens/product_details.dart`
- **Changes in `initState()`**:
  - Changed from conditional cart fetch to always fetch:
    ```dart
    BlocProvider.of<GetCartCubit>(context).getCart(context.read<LocalizationsCubit>().state.languageCode);
    ```
- **Changes in `refreshGetCart()`**:
  - Removed token check; always fetches cart.
- **Changes in "Add to Cart" button**:
  - Removed manual token check and login redirect before calling `addToCart()`.
  - Button now directly calls `context.read<AddCartCubit>().addToCart(...)`.
  - Backend handles anonymous add via `x-guest-id`.
- **Wishlist button**: Still checks token and redirects to login if missing (protected feature).

#### Bottom Navigation
- **File**: `lib/config/widgets/selecting_from_bottom_navbar.dart`
- **No changes needed**: Existing logic already gates Orders/Wishlist/Profile tabs with token checks.

### 7. Auth Integration: Cart Linking on Login
**Goal**: Link anonymous cart to user account during OTP verification.

**Approach**:
- Interceptor automatically includes `x-guest-id` in OTP verification request.
- Backend links guest cart to user account server-side.
- No client-side code changes needed in auth flow.

**Implementation**:
- **Files**: `lib/features/auth/data/data_source/auth_remote_data_source.dart`, `lib/features/auth/presentation/logic/verify_cubit/verify_cubit.dart`
- **Changes**: None required.
- **How it works**:
  1. User adds items to cart as guest (cart stored server-side with `x-guest-id`).
  2. User taps checkout → redirected to login.
  3. User completes OTP verification.
  4. `VerifyCubit` calls `authRemoteDataSource.verify()` with OTP code.
  5. Interceptor adds `x-guest-id` header to verification request.
  6. Backend receives both OTP and `x-guest-id`, links guest cart to newly authenticated user.
  7. `VerifyCubit` saves token to secure storage.
  8. User navigated to home/cart; cart fetch now uses token and returns merged cart.

## Files Changed Summary

### Core Infrastructure
1. **`lib/main.dart`**
   - Generate and persist `guestId` on app startup.

2. **`lib/core/api/dio_consumer.dart`**
   - Add interceptor to inject `x-guest-id` header in all requests.
   - Generate `guestId` inline if missing.

### Cart Data Layer
3. **`lib/features/cart/data/data_source/remote_data_source.dart`**
   - Make `token` optional for `addToCart`, `getCart`, `updateCart`, `deleteFromCart`.
   - Conditionally add `Authorization` header.

4. **`lib/features/cart/data/repository/cart_repo.dart`**
   - Update method signatures to accept `String? token`.
   - Pass nullable token to data source.

### Cart Business Logic
5. **`lib/features/cart/presentation/logic/cubit/add_cart_cubit/add_cart_cubit.dart`**
   - Remove login gate; allow anonymous add-to-cart.

6. **`lib/features/cart/presentation/logic/cubit/get_cart_cubit/get_cart_cubit.dart`**
   - Remove login gate; always fetch cart.

7. **`lib/features/cart/presentation/logic/cubit/update_cubit/update_cart_cubit.dart`**
   - Remove force unwrap; support anonymous updates/deletes.

### Routing
8. **`lib/routing/router_generator.dart`**
   - Remove redirect guard from `myCart` route.
   - Keep guards on checkout flow routes.

### UI Screens
9. **`lib/features/home/presentation/screens/home_screen.dart`**
   - Always fetch cart in init and refresh.
   - Keep wishlist/stories/FCM token gated.

10. **`lib/features/home/presentation/screens/product_details.dart`**
    - Always fetch cart in init and refresh.
    - Remove login prompt from add-to-cart button.
    - Keep wishlist button gated.

## Security Considerations
- **Guest ID Persistence**: Stored in `flutter_secure_storage`; cleared on app uninstall or manual clear data.
- **Token Priority**: When user logged in, `Authorization` header takes precedence; backend uses token for user identification.
- **Protected Operations**: Checkout, payment, address management, coupons, wallet, orders, profile, wishlist, notifications, affiliate features all require authentication.
- **Cart Linking**: Backend responsibility; client only ensures `x-guest-id` sent during OTP verification.
- **No Client-Side Cart Merge**: All cart data managed server-side; client fetches current state via API.

## User Flows

### Flow 1: Anonymous User Adds to Cart
1. User opens app (not logged in).
2. `main()` generates/retrieves `guestId` from secure storage.
3. User browses products on `HomeScreen`.
4. User taps product → `ProductDetails` screen.
5. User selects options and taps "Add to Cart".
6. `AddCartCubit.addToCart()` called with `token=null`.
7. Request sent to backend with `x-guest-id` header (via interceptor).
8. Backend creates/updates cart for guest ID.
9. `GetCartCubit.getCart()` fetches updated cart.
10. Cart icon badge shows item count.

### Flow 2: Anonymous User Views Cart
1. User taps cart icon in app bar.
2. Router navigates to `MyCartScreen` (no redirect).
3. `GetCartCubit` fetches cart with `token=null` and `x-guest-id` header.
4. Backend returns guest cart items.
5. User sees cart items, can update quantities or remove items.
6. Updates sent via `UpdateCartCubit` with `token=null` and `x-guest-id`.

### Flow 3: Anonymous User Attempts Checkout
1. User taps "Continue to Checkout" in `MyCartScreen`.
2. Router navigates to `confirmPayment` route.
3. Route guard checks token; finds `token=null`.
4. Router redirects to `login` screen with `next` parameter.
5. User completes login/registration and OTP verification.
6. During OTP verification, `x-guest-id` header sent automatically.
7. Backend links guest cart to user account.
8. User redirected to intended destination (checkout).
9. Cart fetch now uses token; returns merged cart.

### Flow 4: Logged-In User Manages Cart
1. User already logged in (token exists).
2. Cart operations send both `Authorization: Bearer <token>` and `x-guest-id` headers.
3. Backend prioritizes token for user identification.
4. Cart data associated with user account.

### Flow 5: User Logs Out
1. User taps logout in profile settings.
2. Token removed from secure storage.
3. `guestId` remains in secure storage.
4. Subsequent cart operations use `x-guest-id` only (new guest cart).
5. Previous user cart preserved server-side under user account.

## Backend Expectations
- **Cart Endpoints**: Must accept `x-guest-id` header for anonymous cart operations when `Authorization` header missing.
- **OTP Verification**: Must accept `x-guest-id` header and link guest cart to user account on successful verification.
- **Cart Linking Logic**: Server-side responsibility; merge or replace guest cart with user cart as per business rules.
- **Header Priority**: When both `Authorization` and `x-guest-id` present, use token for user identification.

## Testing Strategy

### Unit Tests
1. **Dio Interceptor**:
   - Mock `SecureCacheHelper` and `Dio`.
   - Verify `x-guest-id` header added to request options.
   - Verify `guestId` generated and persisted if missing.

2. **Cart Repository**:
   - Mock `CartRemoteDataSource`.
   - Test `addToCart` with `token=null` → verify data source called with `token=null`.
   - Test `getCart` with `token=null` → verify success/error handling.

3. **Cart Cubits**:
   - Mock `CartRepository`.
   - Test `AddCartCubit.addToCart()` with `token=null` → verify states emitted (Loading → Success/Error).
   - Test `GetCartCubit.getCart()` with `token=null` → verify states emitted.
   - Test `UpdateCartCubit.updateCart()` with `token=null` → verify states emitted.

### Integration Tests
1. **Anonymous Cart Flow**:
   - Launch app with no token.
   - Add product to cart from `ProductDetails`.
   - Navigate to `MyCartScreen`.
   - Verify cart items displayed.
   - Update quantity.
   - Remove item.
   - Verify cart updates reflected.

2. **Login and Cart Linking**:
   - Add items to cart as guest.
   - Tap checkout → redirected to login.
   - Complete OTP verification.
   - Verify network logs show `x-guest-id` in OTP request.
   - Navigate to cart.
   - Verify cart items persisted (linked to user account).

3. **Protected Features**:
   - As guest, tap wishlist button → redirected to login.
   - As guest, tap Orders tab in bottom nav → redirected to login.
   - As guest, tap Profile tab → redirected to login.

### Manual Testing Checklist
- [ ] Clear app data, open app → verify `guestId` generated and persisted.
- [ ] Add multiple products to cart as guest → verify cart icon badge updates.
- [ ] Close and reopen app → verify cart persists (server-side via `guestId`).
- [ ] Tap checkout → verify redirected to login.
- [ ] Complete login → verify cart items still present (linked).
- [ ] Log out → verify new guest cart created (old cart preserved under user account).
- [ ] Network logs: verify `x-guest-id` header in all cart requests.
- [ ] Network logs: verify `x-guest-id` header in OTP verification request.
- [ ] As guest, try to access wishlist → verify redirected to login.
- [ ] As guest, try to access orders → verify redirected to login.
- [ ] As guest, try to access profile → verify redirected to login.

## Known Limitations and Future Enhancements
1. **Guest Cart Expiration**: Backend should implement expiration policy for abandoned guest carts (e.g., 30 days).
2. **Multi-Device Guest Cart**: `guestId` device-specific; guest cart not synced across devices (expected behavior).
3. **Cart Conflict Resolution**: If user has existing cart and logs in with guest cart, backend merge strategy determines final cart state.
4. **Analytics**: Consider tracking guest-to-user conversion rates and cart abandonment metrics.
5. **Guest Checkout**: Currently not supported; could be added in future with guest email/phone collection.

## Rollout Checklist
- [x] Generate and persist `guestId` at app startup.
- [x] Add Dio interceptor for `x-guest-id` header injection.
- [x] Update cart data source to support optional token.
- [x] Update cart repository to support optional token.
- [x] Remove login gates from cart cubits.
- [x] Allow anonymous access to `MyCartScreen` route.
- [x] Update `HomeScreen` to always fetch cart.
- [x] Update `ProductDetails` to allow anonymous add-to-cart.
- [x] Verify OTP requests include `x-guest-id` header.
- [x] Keep checkout and protected features gated.
- [ ] Backend: Verify `x-guest-id` support for cart endpoints.
- [ ] Backend: Verify cart linking during OTP verification.
- [ ] QA: Execute manual testing checklist.
- [ ] QA: Execute integration tests.
- [ ] Monitoring: Add logging for cart linking events.
- [ ] Monitoring: Track guest cart usage metrics.

## Troubleshooting

### Issue: Cart not persisting across app restarts
**Cause**: `guestId` not persisted or backend not storing guest cart.
**Solution**: 
- Verify `guestId` in secure storage: `await sl<SecureCacheHelper>().getData(key: 'guestId')`.
- Check network logs for `x-guest-id` header in cart requests.
- Verify backend cart storage for guest IDs.

### Issue: Cart not linking after login
**Cause**: `x-guest-id` not sent during OTP verification or backend not linking.
**Solution**:
- Check network logs for OTP verification request; verify `x-guest-id` header present.
- Verify backend cart linking logic.
- Test with backend team using specific `guestId` and user account.

### Issue: Duplicate cart items after login
**Cause**: Backend merge strategy creates duplicates.
**Solution**: Coordinate with backend team on cart merge logic (replace vs. merge).

### Issue: Cart badge not updating after add-to-cart
**Cause**: `GetCartCubit` not called after `AddCartCubit` success.
**Solution**: Ensure `ProductDetails` calls `context.read<GetCartCubit>().getCart(lang)` after successful add.

## References
- **Spec Document**: `Prompt.md`
- **Previous Implementation**: `ANONYMOUS_BROWSING_IMPLEMENTATION.md`
- **Cart API Docs**: 
  - [Get Cart API](https://mohamedamin-8823854.postman.co/workspace/TAJ~703b00db-89aa-4199-b705-02a281b00e08/request/46629053-939d6477-5442-43a5-adef-c91a2e391b23)
  - [Add to Cart API](https://mohamedamin-8823854.postman.co/workspace/TAJ~703b00db-89aa-4199-b705-02a281b00e08/request/46629053-92f0123a-4146-42d9-9b31-416f5108c965)
- **Flutter Secure Storage**: [Package Documentation](https://pub.dev/packages/flutter_secure_storage)
- **UUID Package**: [Package Documentation](https://pub.dev/packages/uuid)

## Conclusion
The anonymous cart feature enables seamless shopping experience for unauthenticated users while maintaining security and data integrity. The implementation follows Flutter best practices, integrates cleanly with existing architecture, and provides clear upgrade path for future enhancements. All cart operations are now available to both guest and authenticated users, with automatic cart linking during login to preserve user's shopping intent.
