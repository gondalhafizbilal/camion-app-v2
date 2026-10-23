// import 'package:camion/config/widgets/selecting_from_bottom_navbar.dart';
// import 'package:camion/core/services/cached_services/product_id_cache_service.dart';
// import 'package:camion/core/services/service_locator.dart';
// import 'package:camion/features/auth/data/repository/auth_repository.dart';
// import 'package:camion/features/auth/presentation/logic/login_cubit/login_cubit.dart';
// import 'package:camion/features/auth/presentation/logic/google_login_cubit/google_login_cubit.dart';
// import 'package:camion/features/auth/presentation/logic/register_cubit/register_cubit.dart';
// import 'package:camion/features/auth/presentation/logic/send_user_shipping_cubit/send_user_shipping_address_cubit.dart';
// import 'package:camion/features/auth/presentation/logic/verify_cubit/verify_cubit.dart';
// import 'package:camion/features/auth/presentation/screens/confirm_phone_number_screen.dart';
// import 'package:camion/features/auth/presentation/screens/first_screen_if_first_time.dart';
// import 'package:camion/features/auth/presentation/screens/login_screen.dart';
// import 'package:camion/features/auth/presentation/screens/register_screen.dart';
// import 'package:camion/features/cart/data/models/get_cart_model.dart';
// import 'package:camion/features/cart/data/repository/cart_repo.dart';
// import 'package:camion/features/cart/presentation/logic/cubit/add_cart_cubit/add_cart_cubit.dart';
// import 'package:camion/features/cart/presentation/logic/cubit/apply_coupon_cubit/apply_coupon_cubit.dart';
// import 'package:camion/features/cart/presentation/logic/cubit/get_cart_cubit/get_cart_cubit.dart';
// import 'package:camion/features/cart/presentation/logic/cubit/get_user_address_cubit/get_user_address_cubit.dart';
// import 'package:camion/features/cart/presentation/logic/cubit/toggle_payment_cubit/payment_method_cubit.dart';
// import 'package:camion/features/auth/presentation/screens/confirm_address.dart';
// import 'package:camion/features/cart/presentation/screens/confirm_payment_screen.dart';
// import 'package:camion/features/cart/presentation/screens/confirm_shipping_address_screen.dart';
// import 'package:camion/features/cart/presentation/screens/my_cart_screen.dart';
// import 'package:camion/features/cart/presentation/screens/payment_web_page.dart';
// import 'package:camion/features/home/data/models/categories_model/get_categories_model.dart';
// import 'package:camion/features/home/data/models/stories_model.dart/stories_model.dart';
// import 'package:camion/features/home/data/repository/home_repo.dart';
// import 'package:camion/features/home/presentation/logic/cubit/create_review_cubit/create_review_cubit.dart';
// import 'package:camion/features/home/presentation/logic/cubit/get_review_cubit/get_review_cubit.dart';
// import 'package:camion/features/home/presentation/logic/cubit/product_id_detailscubit/product_id_details_cubit.dart';
// import 'package:camion/features/home/presentation/logic/cubit/products_cubit/products_cubit.dart';
// import 'package:camion/features/home/presentation/logic/cubit/toggle_add_cart_cubit/toggle_add_cart_cubit.dart';
// import 'package:camion/features/home/presentation/logic/cubit/toggle_product_id_images/toggle_product_id_images_cubit.dart';
// import 'package:camion/features/home/presentation/screens/all_categories_screen.dart';
// import 'package:camion/features/home/presentation/screens/category_screen.dart';
// import 'package:camion/features/home/presentation/screens/products_by_category_screen.dart';
// import 'package:camion/features/home/presentation/screens/product_details.dart';
// import 'package:camion/features/home/presentation/screens/products_on_sale.dart';
// import 'package:camion/features/currency/presentation/screens/change_currency_screen.dart';
// import 'package:camion/features/home/presentation/screens/stories_screen.dart';
// import 'package:camion/features/home/presentation/widgets/full_screen_image.dart';
// import 'package:camion/features/join_us/data/repository/supplier_repo.dart';
// import 'package:camion/features/join_us/presentation/logic/cubit/create_coupon_cubit/create_coupon_cubit.dart';
// import 'package:camion/features/join_us/presentation/logic/cubit/get_affiliate_status_cubit/get_affiliate_status_cubit.dart';
// import 'package:camion/features/join_us/presentation/logic/cubit/Affiliate_sign_cubit/affiliate_sign_cubit.dart';
// import 'package:camion/features/join_us/presentation/logic/cubit/get_coupons_cubit/get_coupons_cubit.dart';
// import 'package:camion/features/join_us/presentation/logic/cubit/toggle_join_us_gender/toggle_join_us_cubit.dart';
// import 'package:camion/features/join_us/presentation/logic/cubit/toggle_social_media_cubit/toggle_social_media_selecting_cubit.dart';
// import 'package:camion/features/join_us/presentation/screens/check_affiliate_or_not.dart';
// import 'package:camion/features/join_us/presentation/screens/create_code_screen.dart';
// import 'package:camion/features/join_us/presentation/screens/join_us_screen.dart';
// import 'package:camion/features/join_us/presentation/screens/my_coupons_screen.dart';
// import 'package:camion/features/join_us/presentation/screens/select_countries_of_supplier.dart';
// import 'package:camion/features/join_us/presentation/screens/select_social_media_screen.dart';
// import 'package:camion/features/join_us/presentation/screens/affiliate_account.dart';
// import 'package:camion/features/join_us/presentation/screens/welcome_screen.dart';
// import 'package:camion/features/notifications/data/repository/notification_repo.dart';
// import 'package:camion/features/notifications/presentation/logic/cubit/notifications_cubit.dart';
// import 'package:camion/features/notifications/presentation/screens/notifications_screen.dart';
// import 'package:camion/features/order_status/data/models/order_model/order_model.dart';
// import 'package:camion/features/order_status/data/repository/order_status_repo.dart';
// import 'package:camion/features/order_status/presentation/logic/cubit/create_order_cubit/create_order_cubit.dart';
// import 'package:camion/features/order_status/presentation/screens/order_details.dart';
// import 'package:camion/features/order_status/presentation/screens/order_tracking_web_view.dart';
// import 'package:camion/features/profile/data/repository/profie_repo.dart';
// import 'package:camion/features/profile/presentation/logic/cubit/get_all_transations_cubit/get_all_transations_cubit.dart';
// import 'package:camion/features/profile/presentation/logic/cubit/get_user_cubit/get_user_cubit.dart';
// import 'package:camion/features/profile/presentation/logic/cubit/get_wallet_cubit/get_wallet_balance_cubit.dart';
// import 'package:camion/features/profile/presentation/logic/cubit/log_out_cubit/log_out_cubit.dart';
// import 'package:camion/features/profile/presentation/logic/cubit/update_user_cubit/update_user_cubit.dart';
// import 'package:camion/features/profile/presentation/screens/account_settings_screen.dart';
// import 'package:camion/features/profile/presentation/screens/change_language_screen.dart';
// import 'package:camion/features/profile/presentation/screens/edit_profile_screen.dart';
// import 'package:camion/features/profile/presentation/screens/feed_back_screen.dart';
// import 'package:camion/features/profile/presentation/screens/help_screen.dart';
// import 'package:camion/features/profile/presentation/screens/my_info.dart';
// import 'package:camion/features/profile/presentation/screens/my_wallet_screen.dart';
// import 'package:camion/features/profile/presentation/screens/privacy_and_return_policy_scren.dart';
// import 'package:camion/features/profile/presentation/screens/settings_screen.dart';
// import 'package:camion/features/profile/presentation/screens/wallet_affiliate_check.dart';
// import 'package:camion/features/searching/presentation/screens/search_filter_screen.dart';
// import 'package:camion/features/searching/presentation/screens/search_screen_with_products.dart';
// import 'package:camion/features/wish_list/data/repository/wish_list_repo.dart';
// import 'package:camion/features/wish_list/presentation/logic/cubit/add_to_wish_list/wish_list_cubit.dart';
// import 'package:camion/features/wish_list/presentation/logic/cubit/get_wish_listcubit/get_wish_list_cubit.dart';
// import 'package:camion/core/cache/secure_cache_storage.dart';
// import 'package:camion/core/services/transient_extras_store.dart';
// import 'package:camion/routing/app_router.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
//
// class RouterGenerator {
//   static GoRouter mainRouting = GoRouter(
//     initialLocation: AppRouter.selectingFromBottomNavBar,
//     // initialLocation: AppRouter.login,
//     errorBuilder: (context, state) {
//       return Scaffold(body: Center(child: Text(state.error.toString())));
//     },
//     routes: [
//       GoRoute(
//         name: AppRouter.firstScreenIfFirstLaunch,
//         path: AppRouter.firstScreenIfFirstLaunch,
//         builder: (context, state) => const FirstScreenIfFirstTime(),
//       ),
//
//       GoRoute(
//         name: AppRouter.login,
//         path: AppRouter.login,
//         builder: (context, state) {
//           final next = state.uri.queryParameters['next'];
//           return MultiBlocProvider(
//             providers: [
//               BlocProvider(create: (context) => LoginCubit(sl<AuthRepository>())),
//               BlocProvider(create: (context) => GoogleLoginCubit(sl<AuthRepository>())),
//             ],
//             child: LoginScreen(nextPath: next),
//           );
//         },
//       ),
//
//       GoRoute(
//         name: AppRouter.register,
//         path: AppRouter.register,
//         builder: (context, state) =>
//             BlocProvider(create: (context) => RegisterCubit(sl<AuthRepository>()), child: const RegisterScreen()),
//       ),
//
//       GoRoute(
//         name: AppRouter.confirmPhoneNumberScreen,
//         path: AppRouter.confirmPhoneNumberScreen,
//         builder: (context, state) {
//           final next = state.extra as String?;
//           return BlocProvider(
//             create: (context) => VerifyCubit(sl<AuthRepository>()),
//             child: ConfirmPhoneNumberScreen(nextPath: next),
//           );
//         },
//       ),
//
//       // GoRoute(
//       //   name: AppRouter.profileScreen,
//       //   path: AppRouter.profileScreen,
//       //   builder: (context, state) => MultiBlocProvider(
//       //     providers: [
//       //       BlocProvider(create: (context) => LogOutCubit()),
//       //       BlocProvider(create: (context) => DeleteAccountCubit(sl<ProfileRepository>())),
//       //     ],
//       //     child: const ProfileScreenBody(),
//       //   ),
//       // ),
//       GoRoute(
//         name: AppRouter.selectingFromBottomNavBar,
//         path: AppRouter.selectingFromBottomNavBar,
//         builder: (context, state) {
//           final tabStr = state.uri.queryParameters['tab'];
//           final initialIndex = int.tryParse(tabStr ?? '');
//           return BlocProvider(
//             create: (context) => GetCartCubit(sl<CartRepository>()),
//             child: SelectingFromBottomNavBar(initialIndex: initialIndex),
//           );
//         },
//       ),
//
//       GoRoute(
//         name: AppRouter.category,
//         path: AppRouter.category,
//         builder: (context, state) {
//           final extra = state.extra as Map<String, dynamic>;
//           return CategoryScreen(title: extra['title'] as Widget, leading: extra['leading'] as Widget);
//         },
//       ),
//
//       GoRoute(
//         name: AppRouter.productDetails,
//         path: AppRouter.productDetails,
//         builder: (context, state) {
//           final productId = (state.extra as String?) ?? state.uri.queryParameters['id'] ?? '';
//           return MultiBlocProvider(
//             providers: [
//               BlocProvider(create: (context) => ProductIdDetailsCubit(sl<HomeRepository>(), ProductCacheService())),
//               BlocProvider(create: (context) => ToggleProductIdImagesCubit()),
//
//               BlocProvider(create: (context) => AddCartCubit(sl<CartRepository>())),
//
//               BlocProvider(create: (context) => GetCartCubit(sl<CartRepository>())),
//
//               BlocProvider(create: (context) => AddToWishListCubit(sl<WishListRepository>())),
//
//               BlocProvider(create: (context) => GetWishListCubit(sl<WishListRepository>())),
//
//               BlocProvider(create: (context) => GetReviewCubit(sl<HomeRepository>())),
//
//               BlocProvider(create: (context) => CreateReviewCubit(sl<HomeRepository>())),
//             ],
//             child: ProductDetails(productId: productId),
//           );
//         },
//       ),
//       GoRoute(name: AppRouter.myCart, path: AppRouter.myCart, builder: (context, state) => const MyCartScreen()),
//
//       GoRoute(
//         name: AppRouter.confirmPayment,
//         path: AppRouter.confirmPayment,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             // Persist extras temporarily and append a key to the 'next' URL so we can restore them after login
//             String? extraKey;
//             final extraPayload = state.extra;
//             if (extraPayload != null) {
//               extraKey = sl<TransientExtrasStore>().put(extraPayload);
//             }
//
//             final nextUri = state.uri.replace(
//               queryParameters: {...state.uri.queryParameters, if (extraKey != null) 'extraKey': extraKey},
//             );
//             final next = Uri.encodeComponent(nextUri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) {
//           // Restore extras passed originally, or retrieve them via a transient key if returning from login
//           final restoredExtraKey = state.uri.queryParameters['extraKey'];
//           final extra =
//               (state.extra as List<GetCartModel>?) ??
//               (restoredExtraKey != null
//                   ? sl<TransientExtrasStore>().take<List<GetCartModel>>(restoredExtraKey)
//                   : null) ??
//               <GetCartModel>[];
//           return MultiBlocProvider(
//             providers: [
//               BlocProvider(create: (context) => PaymentMethodCubit()),
//               BlocProvider(create: (context) => CreateOrderCubit(sl<OrderStatusRepository>())),
//               BlocProvider(create: (context) => CreateOrderCubit(sl<OrderStatusRepository>())),
//
//               BlocProvider(create: (context) => ApplyCouponCubit(sl<CartRepository>())),
//             ],
//             child: ConfirmPaymentScreen(cartList: extra),
//           );
//         },
//       ),
//
//       GoRoute(
//         name: AppRouter.confirmAddress,
//         path: AppRouter.confirmAddress,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) {
//           return MultiBlocProvider(
//             providers: [
//               // BlocProvider(create: (context) => PaymentMethodCubit()),
//               BlocProvider(create: (context) => SendUserShippingAddressCubit(sl<AuthRepository>())),
//             ],
//             child: const ConfirmAddress(),
//           );
//         },
//       ),
//
//       GoRoute(
//         name: AppRouter.myWallet,
//         path: AppRouter.myWallet,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) => MultiBlocProvider(
//           providers: [
//             BlocProvider(create: (context) => GetWalletBalanceCubit(sl<ProfileRepository>())),
//             BlocProvider(create: (context) => GetAllTransationsCubit(sl<ProfileRepository>())),
//           ],
//           child: const MyWalletScreen(),
//         ),
//       ),
//
//       GoRoute(
//         name: AppRouter.notificationScreen,
//         path: AppRouter.notificationScreen,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) => BlocProvider(
//           create: (context) => NotificationsCubit(sl<NotificationRepository>()),
//           child: const NotificationsScreen(),
//         ),
//       ),
//
//       GoRoute(
//         name: AppRouter.searchFilter,
//         path: AppRouter.searchFilter,
//         builder: (context, state) => const SearchFilterScreen(),
//       ),
//
//       GoRoute(
//         name: AppRouter.joinUs,
//         path: AppRouter.joinUs,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) => MultiBlocProvider(
//           providers: [
//             BlocProvider(create: (context) => ToggleJoinUsCubit()),
//             BlocProvider(create: (context) => AffiliateSignCubit(sl<AffiliateRepository>())),
//           ],
//           child: const JoinUsScreen(),
//         ),
//       ),
//
//       GoRoute(
//         name: AppRouter.selectSocialMediaOfSupplierScreen,
//         path: AppRouter.selectSocialMediaOfSupplierScreen,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) => BlocProvider(
//           create: (context) => ToggleSocialMediaSelectingCubit(),
//           child: const SelectSocialMediaScreen(),
//         ),
//       ),
//
//       GoRoute(
//         name: AppRouter.selectCoutriesOfSupplier,
//         path: AppRouter.selectCoutriesOfSupplier,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) => BlocProvider(
//           create: (context) => ToggleSocialMediaSelectingCubit(),
//           child: const SelectCountriesOfSupplier(),
//         ),
//       ),
//
//       GoRoute(
//         name: AppRouter.supplierWelcome,
//         path: AppRouter.supplierWelcome,
//         builder: (context, state) => const WelcomeScreen(),
//       ),
//
//       GoRoute(
//         name: AppRouter.supplierAccount,
//         path: AppRouter.supplierAccount,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) => const AffiliateAccountScreen(),
//       ),
//
//       GoRoute(
//         name: AppRouter.myCodings,
//         path: AppRouter.myCodings,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) => BlocProvider(
//           create: (context) => GetCouponsCubit(sl<AffiliateRepository>()),
//           child: const MyCouponsScreen(),
//         ),
//       ),
//
//       GoRoute(
//         name: AppRouter.createCode,
//         path: AppRouter.createCode,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) => BlocProvider(
//           create: (context) => CreateCouponCubit(sl<AffiliateRepository>()),
//           child: const CreateCodeScreen(),
//         ),
//       ),
//
//       GoRoute(
//         name: AppRouter.searchScreenWithProducts,
//         path: AppRouter.searchScreenWithProducts,
//         builder: (context, state) => MultiBlocProvider(
//           providers: [
//             BlocProvider(create: (context) => ProductsCubit(sl<HomeRepository>())),
//             BlocProvider(create: (context) => ToggleAddCartCubit()),
//           ],
//           child: const SearchScreenWithProducts(),
//         ),
//       ),
//
//       GoRoute(
//         name: AppRouter.storiesView,
//         path: AppRouter.storiesView,
//         builder: (context, state) {
//           final extra = state.extra as Map<String, dynamic>;
//           return StoryViewerScreen(
//             initialIndex: extra['index'] as int,
//             stories: extra['stories'] as List<StoriesModel>,
//             durationPeriod: extra['duration'] as int,
//             mediaType: extra['mediaType'] as String,
//           );
//         },
//       ),
//
//       GoRoute(
//         name: AppRouter.allCategoriesScreen,
//         path: AppRouter.allCategoriesScreen,
//         builder: (context, state) {
//           final extra = state.extra as List<GeTCategoriesModel>;
//           return BlocProvider(
//             create: (context) => GetCartCubit(sl<CartRepository>()),
//             child: AllCategoriesScreen(categories: extra),
//           );
//         },
//       ),
//
//       // GoRoute(
//       //   name: AppRouter.myOrders,
//       //   path: AppRouter.myOrders,
//       //   builder: (context, state) => BlocProvider(
//       //     create: (context) => ToggleNavBarCubit(),
//       //     child: const MyOrdersScreen(),
//       //   ),
//       // ),
//
//       // GoRoute(
//       //   name: AppRouter.orderDetails,
//       //   path: AppRouter.orderDetails,
//
//       //   builder: (context, state) {
//       //     final extra = state.extra as Map<String, Object>;
//       //     return OrderDetailsScreen(
//       //       items: extra['items'] as List<OrderItemModel>,
//       //       numberOfOrder: extra['numberOfOrder'] as String,
//       //       orderDate: extra['orderDate'] as DateTime,
//       //       totalPrice: extra['totalPrice'] as String,
//       //       deliveryCost: extra['deliveryCost'] as String,
//       //       paymentMethod: extra['paymentMethod'] as String,
//       //       shippingAddress: extra['shippingAddress'] as String,
//       //     );
//       //   },
//       // ),
//       GoRoute(
//         path: AppRouter.orderDetailsScreen,
//         name: AppRouter.orderDetailsScreen,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//
//         builder: (context, state) {
//           final extra = state.extra as Map<String, dynamic>;
//           return OrderDetailsScreen(
//             currency: extra['currency'] as String,
//             items: extra['items'] as List<OrderItemModel>,
//             numberOfOrder: extra['numberOfOrder'] as String,
//             orderDate: extra['orderDate'] as DateTime,
//             totalPrice: extra['totalPrice'] as String,
//             deliveryCost: extra['deliveryCost'] as String,
//             paymentMethod: extra['paymentMethod'] as String,
//             shippingAddress: extra['shippingAddress'] as String,
//           );
//         },
//       ),
//
//       GoRoute(
//         name: AppRouter.myInfo,
//         path: AppRouter.myInfo,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) =>
//             BlocProvider(create: (context) => GetUserCubit(sl<ProfileRepository>()), child: const MyInfoScreen()),
//       ),
//
//       GoRoute(
//         name: AppRouter.editInfo,
//         path: AppRouter.editInfo,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) {
//           final extra = state.extra as Map<String, dynamic>;
//           return MultiBlocProvider(
//             providers: [
//               BlocProvider(create: (context) => UpdateUserCubit(sl<ProfileRepository>())),
//               BlocProvider(create: (context) => GetUserCubit(sl<ProfileRepository>())),
//             ],
//             child: EditInfoScreen(fullName: extra['fullName'], phone: extra['phone'], email: extra['email']),
//           );
//         },
//       ),
//
//       GoRoute(name: AppRouter.settings, path: AppRouter.settings, builder: (context, state) => const SettingsScreen()),
//
//       GoRoute(
//         name: AppRouter.changeLanuage,
//         path: AppRouter.changeLanuage,
//         builder: (context, state) => const ChangeLanguageScreen(),
//       ),
//
//       GoRoute(
//         name: AppRouter.changeCurrency,
//         path: AppRouter.changeCurrency,
//         builder: (context, state) => const ChangeCurrencyScreen(),
//       ),
//
//       GoRoute(
//         name: AppRouter.accountSettings,
//         path: AppRouter.accountSettings,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) =>
//             BlocProvider(create: (context) => LogOutCubit(), child: const AccountSettingsScreen()),
//       ),
//
//       GoRoute(name: AppRouter.help, path: AppRouter.help, builder: (context, state) => const HelpScreen()),
//
//       GoRoute(
//         name: AppRouter.productByCategory,
//         path: AppRouter.productByCategory,
//         builder: (context, state) {
//           final extra = state.extra as Map<String, dynamic>;
//           return ProductsByCategoryScreen(slug: extra['slug'], id: extra['id']);
//         },
//       ),
//
//       // GoRoute(
//       //   name: AppRouter.affiliateStatus,
//       //   path: AppRouter.affiliateStatus,
//       //   builder: (context, state) => BlocProvider(
//       //     create: (context) =>
//       //         GetAffiliateStatusCubit(sl<SupplierRepository>()),
//       //     child: const AffiliatePending(),
//       //   ),
//       // ),
//       GoRoute(
//         name: AppRouter.affiliateCheckScreen,
//         path: AppRouter.affiliateCheckScreen,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) => BlocProvider(
//           create: (context) => GetAffiliateStatusCubit(sl<AffiliateRepository>()),
//           child: const AffiliateCheckScreen(),
//         ),
//       ),
//
//       GoRoute(
//         name: AppRouter.paymentWebPage,
//         path: AppRouter.paymentWebPage,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) {
//           final extra = state.extra as Map<String, dynamic>;
//           return PaymentWebViewPage(
//             checkoutUrl: extra['checkoutUrl'] as String,
//             // orderId: extra['orderId'] as String,
//           );
//         },
//       ),
//
//       GoRoute(
//         name: AppRouter.privacyScreen,
//         path: AppRouter.privacyScreen,
//         builder: (context, state) => const PrivacyAndReturnPolicyScren(),
//       ),
//
//       GoRoute(
//         name: AppRouter.feedBackScreen,
//         path: AppRouter.feedBackScreen,
//         builder: (context, state) => const FeedBackScreen(),
//       ),
//
//       GoRoute(
//         name: AppRouter.walletAffiliateCheckScreen,
//         path: AppRouter.walletAffiliateCheckScreen,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) => BlocProvider(
//           create: (context) => GetAffiliateStatusCubit(sl<AffiliateRepository>()),
//           child: const WalletAffiliateCheckScreen(),
//         ),
//       ),
//
//       GoRoute(
//         name: AppRouter.confirmShippingAddressScreen,
//         path: AppRouter.confirmShippingAddressScreen,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) => MultiBlocProvider(
//           providers: [
//             BlocProvider(create: (context) => GetUserAddressCubit(sl<CartRepository>())),
//             BlocProvider(create: (context) => SendUserShippingAddressCubit(sl<AuthRepository>())),
//           ],
//           child: const ConfirmShippingAddressScreen(),
//         ),
//       ),
//
//       GoRoute(
//         name: AppRouter.orderTrackingWebPage,
//         path: AppRouter.orderTrackingWebPage,
//         redirect: (context, state) async {
//           final token = await sl<SecureCacheHelper>().getData(key: 'token');
//           if (token == null || token.isEmpty) {
//             final next = Uri.encodeComponent(state.uri.toString());
//             return '${AppRouter.login}?next=$next';
//           }
//           return null;
//         },
//         builder: (context, state) {
//           final extra = state.extra as String;
//           return OrderTrackingWebView(orderTrackingUrl: extra);
//         },
//       ),
//
//       GoRoute(
//         name: AppRouter.getProductsOnsale,
//         path: AppRouter.getProductsOnsale,
//         builder: (context, state) {
//           return const ProductsOnSaleScreen();
//         },
//       ),
//
//       GoRoute(
//         name: AppRouter.fullScreenImage,
//         path: AppRouter.fullScreenImage,
//         builder: (context, state) {
//           final extra = state.extra as String;
//           return FullScreenImageViewer(imageUrl: extra);
//         },
//       ),
//     ],
//   );
// }
import 'package:camion/config/widgets/selecting_from_bottom_navbar.dart';
import 'package:camion/core/services/cached_services/product_id_cache_service.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/constants/app_defaults.dart';
import 'package:camion/features/auth/data/repository/auth_repository.dart';
import 'package:camion/features/auth/presentation/logic/guest_auth_cubit/guest_auth_cubit.dart';
import 'package:camion/features/auth/presentation/logic/login_cubit/login_cubit.dart';
import 'package:camion/features/auth/presentation/logic/register_cubit/register_cubit.dart';
// import 'package:camion/features/auth/presentation/logic/send_user_shipping_cubit/send_user_shipping_address_cubit.dart';
import 'package:camion/features/auth/presentation/logic/verify_cubit/verify_cubit.dart';
import 'package:camion/features/auth/presentation/screens/confirm_phone_number_screen.dart';
import 'package:camion/features/auth/presentation/screens/first_screen_if_first_time.dart';
import 'package:camion/features/auth/presentation/screens/login_screen.dart';
import 'package:camion/features/auth/presentation/screens/register_screen.dart';
// import 'package:camion/features/cart/data/models/get_cart_model.dart';
import 'package:camion/features/cart/data/repository/cart_repo.dart';
import 'package:camion/features/cart/presentation/logic/cubit/add_cart_cubit/add_cart_cubit.dart';
import 'package:camion/features/cart/presentation/logic/cubit/get_cart_cubit/get_cart_cubit.dart';
import 'package:camion/features/cart/presentation/logic/cubit/toggle_payment_cubit/payment_method_cubit.dart';
import 'package:camion/features/auth/presentation/screens/confirm_address.dart';
import 'package:camion/features/cart/presentation/screens/add_address_screen.dart';
import 'package:camion/features/cart/presentation/screens/checkout_payment_method_screen.dart';
import 'package:camion/features/cart/presentation/screens/confirm_payment_screen.dart';
import 'package:camion/features/cart/presentation/screens/confirm_shipping_address_screen.dart';
import 'package:camion/features/cart/presentation/screens/my_cart_screen.dart';
import 'package:camion/features/cart/presentation/screens/order_overview_screen.dart';
import 'package:camion/features/cart/presentation/screens/payment_web_page.dart';
import 'package:camion/features/home/data/models/categories_model/get_categories_model.dart';
import 'package:camion/features/home/data/models/home_graphql/home_graphql_models.dart';
import 'package:camion/features/home/data/models/stories_model.dart/stories_model.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/home/presentation/logic/cubit/create_review_cubit/create_review_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/get_review_cubit/get_review_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/product_id_detailscubit/product_id_details_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/products_cubit/products_cubit.dart';
import 'package:camion/features/home/presentation/logic/cubit/toggle_product_id_images/toggle_product_id_images_cubit.dart';
import 'package:camion/features/home/presentation/screens/home_screen.dart';
import 'package:camion/features/home/presentation/screens/all_categories_screen.dart';
import 'package:camion/features/home/presentation/screens/category_screen.dart';
import 'package:camion/features/home/presentation/screens/home_section_details_screen.dart';
import 'package:camion/features/home/presentation/screens/camion_commitments_screen.dart';
import 'package:camion/features/home/presentation/screens/products_by_category_screen.dart';
import 'package:camion/features/home/presentation/screens/product_details.dart';
import 'package:camion/features/home/presentation/screens/products_on_sale.dart';
import 'package:camion/features/currency/presentation/screens/change_currency_screen.dart';
import 'package:camion/features/home/presentation/screens/stories_screen.dart';
import 'package:camion/features/home/presentation/widgets/full_screen_image.dart';

import 'package:camion/features/join_us/data/repository/supplier_repo.dart';
import 'package:camion/features/join_us/presentation/logic/cubit/create_coupon_cubit/create_coupon_cubit.dart';
import 'package:camion/features/join_us/presentation/logic/cubit/get_affiliate_status_cubit/get_affiliate_status_cubit.dart';
import 'package:camion/features/join_us/presentation/logic/cubit/Affiliate_sign_cubit/affiliate_sign_cubit.dart';
import 'package:camion/features/join_us/presentation/logic/cubit/get_coupons_cubit/get_coupons_cubit.dart';
import 'package:camion/features/join_us/presentation/logic/cubit/toggle_join_us_gender/toggle_join_us_cubit.dart';
import 'package:camion/features/join_us/presentation/logic/cubit/toggle_social_media_cubit/toggle_social_media_selecting_cubit.dart';
import 'package:camion/features/join_us/presentation/screens/check_affiliate_or_not.dart';
import 'package:camion/features/join_us/presentation/screens/create_code_screen.dart';
import 'package:camion/features/join_us/presentation/screens/join_us_screen.dart';
import 'package:camion/features/join_us/presentation/screens/my_coupons_screen.dart';
import 'package:camion/features/join_us/presentation/screens/select_countries_of_supplier.dart';
import 'package:camion/features/join_us/presentation/screens/select_social_media_screen.dart';
import 'package:camion/features/join_us/presentation/screens/affiliate_account.dart';
import 'package:camion/features/join_us/presentation/screens/welcome_screen.dart';
import 'package:camion/features/join_us/data/models/coupons_model/get_coupons_model.dart'
    as affiliate_coupon_model;
import 'package:camion/features/join_us/presentation/screens/CouponScreenDetail.dart'
    as affiliate_coupon_detail;

import 'package:camion/features/join_us_influencers/data/repository/supplier_repo.dart';
import 'package:camion/features/join_us_influencers/presentation/logic/cubit/create_coupon_cubit/create_coupon_cubit.dart';
import 'package:camion/features/join_us_influencers/presentation/logic/cubit/get_affiliate_status_cubit/get_affiliate_status_cubit.dart';
import 'package:camion/features/join_us_influencers/presentation/logic/cubit/Affiliate_sign_cubit/affiliate_sign_cubit.dart';
import 'package:camion/features/join_us_influencers/presentation/logic/cubit/get_coupons_cubit/get_coupons_cubit.dart';
import 'package:camion/features/join_us_influencers/presentation/logic/cubit/toggle_join_us_gender/toggle_join_us_cubit.dart';
import 'package:camion/features/join_us_influencers/presentation/logic/cubit/toggle_social_media_cubit/toggle_social_media_selecting_cubit.dart';
import 'package:camion/features/join_us_influencers/presentation/screens/check_affiliate_or_not.dart';
import 'package:camion/features/join_us_influencers/presentation/screens/create_code_screen.dart';
import 'package:camion/features/join_us_influencers/presentation/screens/join_us_screen.dart';
import 'package:camion/features/join_us_influencers/presentation/screens/my_coupons_screen.dart';
import 'package:camion/features/join_us_influencers/presentation/screens/select_countries_of_supplier.dart';
import 'package:camion/features/join_us_influencers/presentation/screens/select_social_media_screen.dart';
import 'package:camion/features/join_us_influencers/presentation/screens/affiliate_account.dart';
import 'package:camion/features/join_us_influencers/presentation/screens/welcome_screen.dart';
import 'package:camion/features/join_us_influencers/data/models/coupons_model/get_coupons_model.dart'
    as influencer_coupon_model;
import 'package:camion/features/join_us_influencers/presentation/screens/CouponScreenDetail.dart'
    as influencer_coupon_detail;

import 'package:camion/features/notifications/data/repository/notification_repo.dart';
import 'package:camion/features/notifications/presentation/logic/cubit/notifications_cubit.dart';
import 'package:camion/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:camion/features/order_status/data/models/order_model/order_model.dart';
import 'package:camion/features/order_status/data/models/order_response_model/order_response_model.dart';
import 'package:camion/features/order_status/data/repository/order_status_repo.dart';
import 'package:camion/features/order_status/presentation/logic/cubit/create_order_cubit/create_order_cubit.dart';
import 'package:camion/features/order_status/presentation/logic/cubit/get_orders_cubit/get_orders_cubit.dart';
import 'package:camion/features/order_status/presentation/logic/cubit/toggle_nav_bar/toggle_nav_bar_cubit.dart';
import 'package:camion/features/order_status/presentation/screens/order_details.dart';
import 'package:camion/features/order_status/presentation/screens/my_orders.dart';
import 'package:camion/features/order_status/presentation/screens/order_tracking_web_view.dart';
import 'package:camion/features/order_status/presentation/screens/track_return_order_screen.dart';
import 'package:camion/features/profile/data/repository/profie_repo.dart';
import 'package:camion/features/profile/presentation/logic/cubit/get_all_transations_cubit/get_all_transations_cubit.dart';
import 'package:camion/features/profile/presentation/logic/cubit/get_user_cubit/get_user_cubit.dart';
import 'package:camion/features/profile/presentation/logic/cubit/get_wallet_cubit/get_wallet_balance_cubit.dart';
import 'package:camion/features/profile/presentation/logic/cubit/delete_account_cubit/delete_account_cubit.dart';
import 'package:camion/features/profile/presentation/logic/cubit/log_out_cubit/log_out_cubit.dart';
import 'package:camion/features/profile/presentation/logic/cubit/update_user_cubit/update_user_cubit.dart';
import 'package:camion/features/profile/presentation/screens/account_settings_screen.dart';
import 'package:camion/features/profile/presentation/screens/change_language_screen.dart';
import 'package:camion/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:camion/features/profile/presentation/screens/feed_back_screen.dart';
import 'package:camion/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:camion/features/profile/presentation/screens/help_screen.dart';
import 'package:camion/features/profile/presentation/screens/my_addresses_screen.dart';
import 'package:camion/features/profile/presentation/screens/my_info.dart';
import 'package:camion/features/profile/presentation/screens/my_wallet_screen.dart';
import 'package:camion/features/profile/presentation/screens/privacy_and_return_policy_scren.dart';
import 'package:camion/features/profile/presentation/screens/settings_screen.dart';
import 'package:camion/features/profile/presentation/screens/wallet_affiliate_check.dart';
import 'package:camion/features/searching/presentation/screens/search_filter_screen.dart';
import 'package:camion/features/searching/presentation/logic/search_graphql_cubit.dart';
import 'package:camion/features/searching/presentation/screens/search_screen_with_products.dart';
import 'package:camion/features/wish_list/data/repository/wish_list_repo.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/add_to_wish_list/wish_list_cubit.dart';
import 'package:camion/features/wish_list/presentation/logic/cubit/get_wish_listcubit/get_wish_list_cubit.dart';
import 'package:camion/features/wish_list/presentation/screens/wish_list_screen.dart';
import 'package:camion/features/profile/presentation/screens/profile_screen.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/transient_extras_store.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RouterGenerator {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');
  static final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'homeNavigator');
  static final GlobalKey<NavigatorState> _categoriesNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'categoriesNavigator');
  static final GlobalKey<NavigatorState> _wishListNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'wishListNavigator');
  static final GlobalKey<NavigatorState> _cartNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'cartNavigator');
  static final GlobalKey<NavigatorState> _profileNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'profileNavigator');

  static String _encodeLocation(String path, [Map<String, String>? params]) {
    final uri = Uri(
      path: path,
      queryParameters: params == null || params.isEmpty ? null : params,
    );
    return uri.toString();
  }

  static String _bottomNavLocationForTab(GoRouterState state) {
    final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
    final preservedQuery = Map<String, String>.from(state.uri.queryParameters)
      ..remove('tab');
    switch (tab) {
      case 1:
        return _encodeLocation(AppRouter.categoriesTab, preservedQuery);
      case 2:
        return _encodeLocation(AppRouter.wishListTab, preservedQuery);
      case 3:
        return _encodeLocation(AppRouter.myCart, preservedQuery);
      case 4:
        return _encodeLocation(AppRouter.profileScreen, preservedQuery);
      case 0:
      default:
        return _encodeLocation(AppRouter.homeTab, preservedQuery);
    }
  }

  static GoRouter mainRouting = GoRouter(
    initialLocation: AppRouter.firstScreenIfFirstLaunch,
    navigatorKey: _rootNavigatorKey,
    errorBuilder: (context, state) {
      return Scaffold(body: Center(child: Text(state.error.toString())));
    },
    routes: [
      GoRoute(
        name: AppRouter.firstScreenIfFirstLaunch,
        path: AppRouter.firstScreenIfFirstLaunch,
        builder: (context, state) => const FirstScreenIfFirstTime(),
      ),

      GoRoute(
        name: AppRouter.login,
        path: AppRouter.login,
        builder: (context, state) {
          final next = state.uri.queryParameters['next'];
          final logout = state.uri.queryParameters['logout'] == '1';
          final expired = state.uri.queryParameters['expired'] == '1';
          final unauthorized = state.uri.queryParameters['unauthorized'] == '1';
          final requiresGuestBootstrapOnLogin =
              logout || expired || unauthorized;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => LoginCubit(sl<AuthRepository>()),
              ),
              BlocProvider(
                create: (context) => GuestAuthCubit(sl<AuthRepository>()),
              ),
            ],
            child: LoginScreen(
              nextPath: next,
              requiresGuestBootstrapOnLogin: requiresGuestBootstrapOnLogin,
              exitAppOnBack: logout,
            ),
          );
        },
      ),

      GoRoute(
        name: AppRouter.register,
        path: AppRouter.register,
        builder: (context, state) {
          final next = state.uri.queryParameters['next'];
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => RegisterCubit(sl<AuthRepository>()),
              ),
            ],
            child: RegisterScreen(nextPath: next),
          );
        },
      ),

      GoRoute(
        name: AppRouter.confirmPhoneNumberScreen,
        path: AppRouter.confirmPhoneNumberScreen,
        builder: (context, state) {
          final next = state.extra as String?;
          return BlocProvider(
            create: (context) => VerifyCubit(sl<AuthRepository>()),
            child: ConfirmPhoneNumberScreen(nextPath: next),
          );
        },
      ),

      GoRoute(
        name: AppRouter.selectingFromBottomNavBar,
        path: AppRouter.selectingFromBottomNavBar,
        redirect: (context, state) => _bottomNavLocationForTab(state),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BlocProvider(
            create: (context) => GetCartCubit(sl<CartRepository>()),
            child: SelectingFromBottomNavBar(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                name: AppRouter.homeTab,
                path: AppRouter.homeTab,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _categoriesNavigatorKey,
            routes: [
              GoRoute(
                name: AppRouter.categoriesTab,
                path: AppRouter.categoriesTab,
                builder: (context, state) {
                  final categorySlug =
                      state.uri.queryParameters['categorySlug'];
                  return CategoriesTabScreen(initialCategorySlug: categorySlug);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _wishListNavigatorKey,
            routes: [
              GoRoute(
                name: AppRouter.wishListTab,
                path: AppRouter.wishListTab,
                builder: (context, state) => const WishListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _cartNavigatorKey,
            routes: [
              GoRoute(
                name: AppRouter.myCart,
                path: AppRouter.myCart,
                builder: (context, state) => const MyCartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                name: AppRouter.profileScreen,
                path: AppRouter.profileScreen,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        name: AppRouter.category,
        path: AppRouter.category,
        builder: (context, state) {
          final extra = state.extra;
          String? initialCategorySlug;
          if (extra is Map) {
            final dynamic slug = extra['slug'];
            initialCategorySlug = slug?.toString();
          }
          if ((initialCategorySlug ?? '').trim().isEmpty) {
            initialCategorySlug = state.uri.queryParameters['slug'];
          }
          return CategoryScreen(
            showBackButton: true,
            initialCategorySlug: initialCategorySlug,
          );
        },
      ),

      GoRoute(
        name: AppRouter.productDetails,
        path: AppRouter.productDetails,
        builder: (context, state) {
          final rawExtra = state.extra;
          String productId = '';
          String productSlug = '';
          String selectedVariantUuid = '';
          if (rawExtra is Map) {
            final dynamic id = rawExtra['id'];
            final dynamic slug = rawExtra['slug'];
            final dynamic variantUuid = rawExtra['selectedVariantUuid'];
            productId = (id ?? '').toString();
            productSlug = (slug ?? '').toString();
            selectedVariantUuid = (variantUuid ?? '').toString();
          } else {
            productId =
                (rawExtra as String?) ?? state.uri.queryParameters['id'] ?? '';
            productSlug = state.uri.queryParameters['slug'] ?? '';
            selectedVariantUuid =
                state.uri.queryParameters['selectedVariantUuid'] ?? '';
          }
          final languageCode =
              sl<CacheHelper>()
                      .getDataString(key: 'languageCode')
                      ?.trim()
                      .isNotEmpty ==
                  true
              ? sl<CacheHelper>().getDataString(key: 'languageCode')!.trim()
              : AppDefaults.defaultLanguageCode;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => ProductIdDetailsCubit(
                  sl<HomeRepository>(),
                  ProductCacheService(),
                ),
              ),
              BlocProvider(
                create: (context) =>
                    ProductsCubit(sl<HomeRepository>())
                      ..loadInitial(lang: languageCode),
              ),
              BlocProvider(create: (context) => ToggleProductIdImagesCubit()),
              BlocProvider(
                create: (context) => AddCartCubit(sl<CartRepository>()),
              ),
              BlocProvider(
                create: (context) =>
                    AddToWishListCubit(sl<WishListRepository>()),
              ),
              BlocProvider(
                create: (context) => GetWishListCubit(sl<WishListRepository>()),
              ),
              BlocProvider(
                create: (context) => GetReviewCubit(sl<HomeRepository>()),
              ),
            ],
            child: ProductDetails(
              productId: productId,
              productSlug: productSlug,
              initialVariantUuid: selectedVariantUuid,
            ),
          );
        },
      ),

      GoRoute(
        name: AppRouter.camionCommitments,
        path: AppRouter.camionCommitments,
        builder: (context, state) => const CamionCommitmentsScreen(),
      ),

      // ✅✅✅ UPDATED CONFIRM PAYMENT ROUTE (A–Z FIXED)
      GoRoute(
        name: AppRouter.confirmPayment,
        path: AppRouter.confirmPayment,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            String? extraKey;
            final extraPayload = state.extra;
            if (extraPayload != null) {
              extraKey = sl<TransientExtrasStore>().put(extraPayload);
            }

            final nextUri = state.uri.replace(
              queryParameters: {
                ...state.uri.queryParameters,
                if (extraKey != null) 'extraKey': extraKey,
              },
            );
            final next = Uri.encodeComponent(nextUri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) {
          final restoredExtraKey = state.uri.queryParameters['extraKey'];

          final dynamic restored =
              state.extra ??
              (restoredExtraKey != null
                  ? sl<TransientExtrasStore>().take(restoredExtraKey)
                  : null);

          // Support BOTH new Map extras and old List extras
          List<GetCartModel> cartList = <GetCartModel>[];
          double subTotal = 0.0;
          double shipping = 0.0;
          double itemsDiscount = 0.0;
          double couponDiscount = 0.0;
          double discountTotal = 0.0;
          double total = 0.0;

          double toD(dynamic v) {
            if (v == null) return 0.0;
            if (v is num) return v.toDouble();
            return double.tryParse(v.toString()) ?? 0.0;
          }

          if (restored is Map<String, dynamic>) {
            cartList = List<GetCartModel>.from(
              (restored["cartList"] as List?) ?? <GetCartModel>[],
            );

            subTotal = toD(restored["subTotal"]);
            shipping = toD(restored["shipping"]);
            itemsDiscount = toD(restored["itemsDiscount"]);
            couponDiscount = toD(restored["couponDiscount"]);
            discountTotal = toD(restored["discountTotal"]);
            total = toD(restored["total"]);
          } else if (restored is List<GetCartModel>) {
            cartList = restored;
          } else {
            cartList = <GetCartModel>[];
          }

          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => PaymentMethodCubit()),
              BlocProvider(
                create: (context) =>
                    CreateOrderCubit(sl<OrderStatusRepository>()),
              ),
            ],
            child: ConfirmPaymentScreen(
              cartList: cartList,
              subTotal: subTotal,
              shipping: shipping,
              itemsDiscount: itemsDiscount,
              couponDiscount: couponDiscount,
              discountTotal: discountTotal,
              total: total,
              checkoutPayload: restored is Map<String, dynamic>
                  ? restored
                  : null,
            ),
          );
        },
      ),
      // ✅✅✅ END UPDATED CONFIRM PAYMENT ROUTE

      // GoRoute(
      //   name: AppRouter.confirmAddress,
      //   path: AppRouter.confirmAddress,
      //   redirect: (context, state) async {
      //     final token = await sl<SecureCacheHelper>().getData(key: 'token');
      //     if (token == null || token.isEmpty) {
      //       final next = Uri.encodeComponent(state.uri.toString());
      //       return '${AppRouter.login}?next=$next';
      //     }
      //     return null;
      //   },
      //   builder: (context, state) {
      //     return MultiBlocProvider(
      //       providers: [
      //         BlocProvider(create: (context) => SendUserShippingAddressCubit(sl<AuthRepository>())),
      //       ],
      //       child: const ConfirmAddress(),
      //     );
      //   },
      // ),
      // ✅ ROUTER UPDATE (no args passed through route, only BlocProviders)
      // Put this where your routes are defined
      GoRoute(
        name: AppRouter.confirmShippingAddressScreen,
        path: AppRouter.confirmShippingAddressScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            String? extraKey;
            final extraPayload = state.extra;
            if (extraPayload != null) {
              extraKey = sl<TransientExtrasStore>().put(extraPayload);
            }
            final nextUri = state.uri.replace(
              queryParameters: {
                ...state.uri.queryParameters,
                if (extraKey != null) 'extraKey': extraKey,
              },
            );
            final next = Uri.encodeComponent(nextUri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => MultiBlocProvider(
          providers: [
            // ✅ Use INLINE repo (GetUserAddressRepo) NOT CartRepository
            BlocProvider<GetUserAddressCubit>(
              create: (_) =>
                  GetUserAddressCubit(GetUserAddressRepo())..getUserAddress(),
            ),
            BlocProvider<GetUserCubit>(
              create: (_) => GetUserCubit(sl<ProfileRepository>()),
            ),

            // ✅ Inline SendUserShippingAddressCubit already correct
            BlocProvider<SendUserShippingAddressCubit>(
              create: (_) =>
                  SendUserShippingAddressCubit(SendUserShippingAddressRepo()),
            ),
          ],
          child: ConfirmShippingAddressScreen(
            checkoutPayload: state.extra is Map<String, dynamic>
                ? state.extra as Map<String, dynamic>
                : (() {
                    final restoredExtraKey =
                        state.uri.queryParameters['extraKey'];
                    if (restoredExtraKey == null) return null;
                    final restored = sl<TransientExtrasStore>().take(
                      restoredExtraKey,
                    );
                    return restored is Map<String, dynamic> ? restored : null;
                  })(),
          ),
        ),
      ),

      GoRoute(
        name: AppRouter.checkoutPaymentMethod,
        path: AppRouter.checkoutPaymentMethod,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => CheckoutPaymentMethodScreen(
          checkoutPayload: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),

      GoRoute(
        name: AppRouter.addAddress,
        path: AppRouter.addAddress,
        builder: (context, state) => AddAddressScreen(
          initialAddress: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),

      // GoRoute(
      //   name: AppRouter.confirmAddress,
      //   path: AppRouter.confirmAddress,
      //   redirect: (context, state) async {
      //     final token = await sl<SecureCacheHelper>().getData(key: 'token');
      //     if (token == null || token.isEmpty) {
      //       final next = Uri.encodeComponent(state.uri.toString());
      //       return '${AppRouter.login}?next=$next';
      //     }
      //     return null;
      //   },
      //   builder: (context, state) {
      //     return MultiBlocProvider(
      //       providers: [
      //         // ✅ Needed for GET /users/address/me (prefill)
      //         BlocProvider(
      //           create: (context) => GetUserAddressCubit(sl<AuthRepository>()),
      //         ),
      //
      //         // ✅ Uses your inline Cubit + inline Repo (no external injection needed)
      //         BlocProvider(
      //           create: (context) => SendUserShippingAddressCubit(
      //             SendUserShippingAddressRepo(),
      //           ),
      //         ),
      //       ],
      //       child: const ConfirmShippingAddressScreen(),
      //     );
      //   },
      // ),
      GoRoute(
        name: AppRouter.confirmAddress,
        path: AppRouter.confirmAddress,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) {
          return BlocProvider<UserAddressCubit>(
            create: (_) => UserAddressCubit(UserAddressRepo()),
            child: const ConfirmAddress(),
          );
        },
      ),

      GoRoute(
        name: AppRouter.myWallet,
        path: AppRouter.myWallet,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) =>
                  GetWalletBalanceCubit(sl<ProfileRepository>()),
            ),
            BlocProvider(
              create: (context) =>
                  GetAllTransationsCubit(sl<ProfileRepository>()),
            ),
          ],
          child: const MyWalletScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.notificationScreen,
        path: AppRouter.notificationScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) => NotificationsCubit(sl<NotificationRepository>()),
          child: const NotificationsScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.searchFilter,
        path: AppRouter.searchFilter,
        builder: (context, state) {
          final map = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : const <String, dynamic>{};
          return SearchFilterScreen(
            initialFilter: SearchApiFilter.fromMap(map),
          );
        },
      ),

      /////////////////////// AFFILIATOR SCREENS //////////////////////
      GoRoute(
        name: AppRouter.joinUs,
        path: AppRouter.joinUs,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => ToggleJoinUsCubit()),
            BlocProvider(
              create: (context) =>
                  AffiliateSignCubit(sl<AffiliateRepository>()),
            ),
          ],
          child: const JoinUsScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.selectSocialMediaOfSupplierScreen,
        path: AppRouter.selectSocialMediaOfSupplierScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) => ToggleSocialMediaSelectingCubit(),
          child: const SelectSocialMediaScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.selectCoutriesOfSupplier,
        path: AppRouter.selectCoutriesOfSupplier,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) => ToggleSocialMediaSelectingCubit(),
          child: const SelectCountriesOfSupplier(),
        ),
      ),

      GoRoute(
        name: AppRouter.supplierWelcome,
        path: AppRouter.supplierWelcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      GoRoute(
        name: AppRouter.supplierAccount,
        path: AppRouter.supplierAccount,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => const AffiliateAccountScreen(),
      ),

      GoRoute(
        name: AppRouter.myCodings,
        path: AppRouter.myCodings,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) => GetCouponsCubit(sl<AffiliateRepository>()),
          child: const MyCouponsScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.createCode,
        path: AppRouter.createCode,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) => CreateCouponCubit(sl<AffiliateRepository>()),
          child: const CreateCodeScreen(),
        ),
      ),
      GoRoute(
        name: AppRouter.affiliateCheckScreen,
        path: AppRouter.affiliateCheckScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) =>
              GetAffiliateStatusCubit(sl<AffiliateRepository>()),
          child: const AffiliateCheckScreen(),
        ),
      ),
      GoRoute(
        name: AppRouter.walletAffiliateCheckScreen,
        path: AppRouter.walletAffiliateCheckScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) =>
              GetAffiliateStatusCubit(sl<AffiliateRepository>()),
          child: const WalletAffiliateCheckScreen(),
        ),
      ),

      /////////////////////// INFLUENCERS SCREENS //////////////////////
      GoRoute(
        name: AppRouter.joinUsInfluencer,
        path: AppRouter.joinUsInfluencer,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => ToggleJoinUsInfluencerCubit()),
            BlocProvider(
              create: (context) =>
                  InfluencerSignCubit(sl<InfluencerRepository>()),
            ),
          ],
          child: const JoinUsInfluencerScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.selectSocialMediaOfInfluencerScreen,
        path: AppRouter.selectSocialMediaOfInfluencerScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) => ToggleInfluencerSocialMediaSelectingCubit(),
          child: const SelectInfluencerSocialMediaScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.selectCoutriesOfInfluencer,
        path: AppRouter.selectCoutriesOfInfluencer,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) => ToggleInfluencerSocialMediaSelectingCubit(),
          child: const SelectCountriesOfInfluencer(),
        ),
      ),

      GoRoute(
        name: AppRouter.influencerWelcome,
        path: AppRouter.influencerWelcome,
        builder: (context, state) => const WelcomeInfluencerScreen(),
      ),

      GoRoute(
        name: AppRouter.influencerAccount,
        path: AppRouter.influencerAccount,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => const InfluencereAccountScreen(),
      ),

      GoRoute(
        name: AppRouter.myinfluencerCodings,
        path: AppRouter.myinfluencerCodings,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) =>
              GetCouponsInfluencerCubit(sl<InfluencerRepository>()),
          child: const MyInfluencerCouponsScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.createInfluencerCode,
        path: AppRouter.createInfluencerCode,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) =>
              CreateInfluencerCouponCubit(sl<InfluencerRepository>()),
          child: const CreateInfluencerCodeScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.influencerCheckScreen,
        path: AppRouter.influencerCheckScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) =>
              GetInfluencerStatusCubit(sl<InfluencerRepository>()),
          child: const InfluencerCheckScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.walletInfluencerCheckScreen,
        path: AppRouter.walletInfluencerCheckScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) =>
              GetInfluencerStatusCubit(sl<InfluencerRepository>()),
          child: const WalletAffiliateCheckScreen(),
        ),
      ),

      /////////////////////// NORMAL SCREENS //////////////////////
      GoRoute(
        name: AppRouter.searchScreenWithProducts,
        path: AppRouter.searchScreenWithProducts,
        builder: (context, state) {
          final initialQuery = state.uri.queryParameters['q'] ?? '';
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => SearchGraphqlCubit(sl<HomeRepository>()),
              ),
            ],
            child: SearchScreenWithProducts(initialQuery: initialQuery),
          );
        },
      ),

      GoRoute(
        name: AppRouter.storiesView,
        path: AppRouter.storiesView,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return StoryViewerScreen(
            initialIndex: extra['index'] as int,
            stories: extra['stories'] as List<StoriesModel>,
            durationPeriod: extra['duration'] as int,
            mediaType: extra['mediaType'] as String,
          );
        },
      ),

      GoRoute(
        name: AppRouter.allCategoriesScreen,
        path: AppRouter.allCategoriesScreen,
        builder: (context, state) {
          final extra = state.extra as List<GeTCategoriesModel>;
          return BlocProvider(
            create: (context) => GetCartCubit(sl<CartRepository>()),
            child: AllCategoriesScreen(categories: extra),
          );
        },
      ),

      GoRoute(
        name: AppRouter.myOrders,
        path: AppRouter.myOrders,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => GetOrdersCubit(sl<OrderStatusRepository>()),
            ),
            BlocProvider(create: (context) => ToggleNavBarCubit()),
          ],
          child: const MyOrdersScreen(openedFromProfile: true),
        ),
      ),

      GoRoute(
        name: AppRouter.homeSectionDetails,
        path: AppRouter.homeSectionDetails,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return HomeSectionDetailsScreen(
            title: extra['title'] as String,
            section: (extra['section'] as String?) ?? 'all',
            slug: extra['slug'] as String?,
            campaignEndsAt: extra['campaignEndsAt'] as DateTime?,
          );
        },
      ),

      GoRoute(
        path: AppRouter.orderDetailsScreen,
        name: AppRouter.orderDetailsScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BlocProvider(
            create: (context) => CreateReviewCubit(sl<HomeRepository>()),
            child: OrderDetailsScreen(
              currency: extra['currency'] as String,
              items: extra['items'] as List<OrderItemModel>,
              numberOfOrder: extra['numberOfOrder'] as String,
              orderDate: extra['orderDate'] as DateTime,
              subTotalPrice: (extra['subTotalPrice'] ?? extra['totalPrice'])
                  .toString(),
              totalPrice: extra['totalPrice'] as String,
              shippingCost: extra['shippingCost'] as String,
              discount: extra['discount'] as String,
              paymentMethod: extra['paymentMethod'] as String,
              shippingAddress: extra['shippingAddress'] as String,
            ),
          );
        },
      ),

      GoRoute(
        name: AppRouter.couponStats,
        path: AppRouter.couponStats,
        builder: (context, state) {
          final coupon = state.extra;
          if (coupon is affiliate_coupon_model.GetCouponsModel) {
            return affiliate_coupon_detail.CouponStatsScreen(coupon: coupon);
          }
          if (coupon is influencer_coupon_model.GetCouponsModel) {
            return influencer_coupon_detail.CouponStatsScreen(coupon: coupon);
          }
          return const Scaffold(
            body: Center(child: Text('Missing coupon data')),
          );
        },
      ),

      GoRoute(
        name: AppRouter.myAddresses,
        path: AppRouter.myAddresses,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => const MyAddressesScreen(),
      ),

      GoRoute(
        name: AppRouter.myInfo,
        path: AppRouter.myInfo,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => BlocProvider(
          create: (context) => GetUserCubit(sl<ProfileRepository>()),
          child: const MyInfoScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.editInfo,
        path: AppRouter.editInfo,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => UpdateUserCubit(sl<ProfileRepository>()),
              ),
              BlocProvider(
                create: (context) => GetUserCubit(sl<ProfileRepository>()),
              ),
            ],
            child: EditInfoScreen(
              fullName: extra['fullName'],
              phone: extra['phone'],
              email: extra['email'],
            ),
          );
        },
      ),

      GoRoute(
        name: AppRouter.settings,
        path: AppRouter.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        name: AppRouter.changeLanuage,
        path: AppRouter.changeLanuage,
        builder: (context, state) => const ChangeLanguageScreen(),
      ),

      GoRoute(
        name: AppRouter.changeCurrency,
        path: AppRouter.changeCurrency,
        builder: (context, state) => const ChangeCurrencyScreen(),
      ),

      GoRoute(
        name: AppRouter.accountSettings,
        path: AppRouter.accountSettings,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => LogOutCubit()),
            BlocProvider(
              create: (context) => DeleteAccountCubit(sl<ProfileRepository>()),
            ),
            BlocProvider(
              create: (context) =>
                  GetUserCubit(sl<ProfileRepository>())..getUserById(),
            ),
          ],
          child: const AccountSettingsScreen(),
        ),
      ),

      GoRoute(
        name: AppRouter.help,
        path: AppRouter.help,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => const HelpScreen(),
      ),

      GoRoute(
        name: AppRouter.chatbot,
        path: AppRouter.chatbot,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => const ChatbotScreen(),
      ),

      GoRoute(
        name: AppRouter.productByCategory,
        path: AppRouter.productByCategory,
        builder: (context, state) {
          final extra = state.extra;
          String slug = state.uri.queryParameters['slug'] ?? '';
          int? id;
          String? parentName;
          String? parentSlug;
          String? childName;
          List<HomeGraphqlCategory> viewAllCategories = const [];

          if (extra is Map) {
            final rawSlug = extra['slug'];
            if ((rawSlug?.toString().trim() ?? '').isNotEmpty) {
              slug = rawSlug.toString();
            }
            final rawId = extra['id'];
            if (rawId is int) {
              id = rawId;
            } else if (rawId is String) {
              id = int.tryParse(rawId);
            } else if (rawId is num) {
              id = rawId.toInt();
            }

            final rawParentName = extra['parentName'];
            if ((rawParentName?.toString().trim() ?? '').isNotEmpty) {
              parentName = rawParentName.toString();
            }

            final rawParentSlug = extra['parentSlug'];
            if ((rawParentSlug?.toString().trim() ?? '').isNotEmpty) {
              parentSlug = rawParentSlug.toString();
            }

            final rawChildName = extra['childName'];
            if ((rawChildName?.toString().trim() ?? '').isNotEmpty) {
              childName = rawChildName.toString();
            }

            final rawViewAllCategories = extra['viewAllCategories'];
            if (rawViewAllCategories is List) {
              viewAllCategories = rawViewAllCategories
                  .whereType<HomeGraphqlCategory>()
                  .toList();
            }
          }
          id ??= int.tryParse(state.uri.queryParameters['id'] ?? '');

          return ProductsByCategoryScreen(
            slug: slug,
            id: id,
            parentName: parentName,
            parentSlug: parentSlug,
            childName: childName,
            viewAllCategories: viewAllCategories,
          );
        },
      ),

      GoRoute(
        name: AppRouter.paymentWebPage,
        path: AppRouter.paymentWebPage,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PaymentWebViewPage(
            checkoutUrl: extra['checkoutUrl'] as String,
            orderResponse: extra['orderResponse'] as OrderResponse?,
            subTotal: (extra['subTotal'] as num?)?.toDouble() ?? 0,
            shipping: (extra['shipping'] as num?)?.toDouble() ?? 0,
            discountTotal: (extra['discountTotal'] as num?)?.toDouble() ?? 0,
            total: (extra['total'] as num?)?.toDouble() ?? 0,
          );
        },
      ),

      GoRoute(
        name: AppRouter.orderOverview,
        path: AppRouter.orderOverview,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OrderOverviewScreen(
            orderResponse: extra['orderResponse'] as OrderResponse,
            subTotal: (extra['subTotal'] as num?)?.toDouble() ?? 0,
            shipping: (extra['shipping'] as num?)?.toDouble() ?? 0,
            discountTotal: (extra['discountTotal'] as num?)?.toDouble() ?? 0,
            total: (extra['total'] as num?)?.toDouble() ?? 0,
          );
        },
      ),

      GoRoute(
        name: AppRouter.privacyScreen,
        path: AppRouter.privacyScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => const PrivacyAndReturnPolicyScren(),
      ),

      GoRoute(
        name: AppRouter.feedBackScreen,
        path: AppRouter.feedBackScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) => const FeedBackScreen(),
      ),

      GoRoute(
        name: AppRouter.orderTrackingWebPage,
        path: AppRouter.orderTrackingWebPage,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) {
          final extra = state.extra;
          final payload = extra is Map<String, dynamic> ? extra : null;
          final orderId =
              payload?['orderId'] as String? ?? (extra as String? ?? '');
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    GetOrdersCubit(sl<OrderStatusRepository>())
                      ..getOrderTracking(orderId: orderId),
              ),
            ],
            child: OrderTrackingWebView(
              orderId: orderId,
              orderNumber: payload?['orderNumber'] as String?,
              productTitle: payload?['productTitle'] as String?,
              variantTitle: payload?['variantTitle'] as String?,
              productImage: payload?['productImage'] as String?,
              productId: payload?['productId'] as String?,
            ),
          );
        },
      ),

      GoRoute(
        name: AppRouter.trackReturnOrderScreen,
        path: AppRouter.trackReturnOrderScreen,
        redirect: (context, state) async {
          final token = await sl<SecureCacheHelper>().getData(key: 'token');
          if (token == null || token.isEmpty) {
            final next = Uri.encodeComponent(state.uri.toString());
            return '${AppRouter.login}?next=$next';
          }
          return null;
        },
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TrackReturnOrderScreen(
            orderId: extra['orderId'] as String? ?? '',
            orderNumber: extra['orderNumber'] as String? ?? '',
            productTitle: extra['productTitle'] as String? ?? 'Return item',
            productImage: extra['productImage'] as String? ?? '',
            requestUuid: extra['requestUuid'] as String?,
          );
        },
      ),

      GoRoute(
        name: AppRouter.getProductsOnsale,
        path: AppRouter.getProductsOnsale,
        builder: (context, state) => const ProductsOnSaleScreen(),
      ),

      GoRoute(
        name: AppRouter.fullScreenImage,
        path: AppRouter.fullScreenImage,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            final urls =
                (extra['imageUrls'] as List?)
                    ?.whereType<String>()
                    .map((url) => url.trim())
                    .where((url) => url.isNotEmpty)
                    .toList(growable: false) ??
                const <String>[];
            final initialIndex = (extra['initialIndex'] as num?)?.toInt() ?? 0;
            return FullScreenImageViewer(
              imageUrls: urls,
              initialIndex: initialIndex,
            );
          }
          if (extra is List<String>) {
            return FullScreenImageViewer(imageUrls: extra);
          }
          return FullScreenImageViewer(imageUrls: <String>[extra.toString()]);
        },
      ),
    ],
  );
}
