import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/services/dashboard_badge_counts_notifier.dart';
import 'package:camion/core/services/auth_session_notifier.dart';
import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:camion/features/auth/data/repository/auth_repository.dart';
import 'package:camion/features/cart/data/data_source/remote_data_source.dart';
import 'package:camion/features/cart/data/repository/cart_repo.dart';
import 'package:camion/features/home/data/data_source/remote_data_source.dart';
import 'package:camion/features/home/data/repository/home_repo.dart';
import 'package:camion/features/join_us/data/data_source/remote_data_source.dart';
import 'package:camion/features/join_us/data/repository/supplier_repo.dart';
import 'package:camion/features/notifications/data/data_source/remote_data_source.dart';
import 'package:camion/features/notifications/data/repository/notification_repo.dart';
import 'package:camion/features/order_status/data/data_source/remote_data_source.dart';
import 'package:camion/features/order_status/data/repository/order_status_repo.dart';
import 'package:camion/features/profile/data/data_source/remote_data_source.dart';
import 'package:camion/features/profile/data/repository/profie_repo.dart';
import 'package:camion/features/wish_list/data/data_source/remote_data_source.dart';
import 'package:camion/features/wish_list/data/repository/wish_list_repo.dart';
import 'package:camion/features/currency/data/data_source/remote_data_source.dart';
import 'package:camion/features/currency/data/repository/currency_repo.dart';
import 'package:camion/features/join_us_influencers/data/data_source/remote_data_source.dart';
import 'package:camion/features/join_us_influencers/data/repository/supplier_repo.dart';
Future<void> initRepositories() async {
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSource(apiConsumer: sl()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepository(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<DashboardBadgeCountsNotifier>(
    () => DashboardBadgeCountsNotifier(
      homeRepository: sl<HomeRepository>(),
      secureCacheHelper: sl<SecureCacheHelper>(),
      authSessionNotifier: sl<AuthSessionNotifier>(),
    ),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(apiConsumer: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(authRemoteDataSource: sl()),
  );

  sl.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSource(apiConsumer: sl()),
  );

  sl.registerLazySingleton<CartRepository>(
    () => CartRepository(cartRemoteDataSource: sl()),
  );

  sl.registerLazySingleton<WishListRemoteDataSource>(
    () => WishListRemoteDataSource(apiConsumer: sl()),
  );

  sl.registerLazySingleton<WishListRepository>(
    () => WishListRepository(wishListRemoteDataSource: sl()),
  );

  sl.registerLazySingleton<OrderStatusRemoteDataSource>(
    () => OrderStatusRemoteDataSource(apiConsumer: sl()),
  );

  sl.registerLazySingleton<OrderStatusRepository>(
    () => OrderStatusRepository(orderStatusRemoteDataSource: sl()),
  );

  sl.registerLazySingleton<AffiliateRemoteDataSource>(
    () => AffiliateRemoteDataSource(apiConsumer: sl()),
  );

  sl.registerLazySingleton<InfluencerRemoteDataSource>(
        () => InfluencerRemoteDataSource(apiConsumer: sl()),
  );
  sl.registerLazySingleton<AffiliateRepository>(
    () => AffiliateRepository(supplierRemoteDataSource: sl()),
  );
  sl.registerLazySingleton<InfluencerRepository>(
        () => InfluencerRepository(supplierRemoteDataSource: sl()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSource(apiConsumer: sl()),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(profileRemoteDataSource: sl()),
  );

  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSource(apiConsumer: sl()),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(notificationRemoteDataSource: sl()),
  );

  // Currency
  sl.registerLazySingleton<CurrencyRemoteDataSource>(
    () => CurrencyRemoteDataSource(apiConsumer: sl()),
  );

  sl.registerLazySingleton<CurrencyRepository>(
    () => CurrencyRepository(remoteDataSource: sl()),
  );
}
