import 'package:camion/core/api/api_consumer.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/config/app_config.dart';
import 'package:camion/core/config/app_flavor.dart';
import 'package:camion/features/join_us/data/data_source/remote_data_source.dart'
    as aff_ds;
import 'package:camion/features/join_us/data/models/affiliate_status/affiliate_status_model.dart'
    as aff_status;
import 'package:camion/features/join_us/data/models/coupons_model/get_coupons_model.dart'
    as aff_coupons;
import 'package:camion/features/join_us_influencers/data/data_source/remote_data_source.dart'
    as inf_ds;
import 'package:camion/features/notifications/data/data_source/remote_data_source.dart'
    as notif_ds;
import 'package:camion/features/notifications/data/models/notification_model.dart'
    as notif_model;
import 'package:camion/features/profile/data/data_source/remote_data_source.dart'
    as profile_ds;
import 'package:camion/features/profile/data/models/transaction_model/transactions.dart'
    as tx_model;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeApiConsumer implements ApiConsumer {
  String? lastPath;
  Object? lastData;

  Response<dynamic> _response(String path, dynamic data) {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: data,
      statusCode: 200,
    );
  }

  @override
  Future<Response<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPath = path;
    lastData = data;
    return _response(path, {'ok': true});
  }

  @override
  Future<Response<dynamic>> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPath = path;
    lastData = data;
    return _response(path, {'ok': true});
  }

  @override
  Future<Response<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPath = path;
    lastData = data;
    return _response(path, {'ok': true});
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPath = path;
    lastData = data;

    if (path.endsWith('/v1/referral/affiliates/affiliate') ||
        path.endsWith('/v1/referral/affiliates/influencer')) {
      return _response(path, {
        'uuid': 'aff-1',
        'fullName': 'James',
        'gender': 'Male',
        'nationality': 'Qatari',
        'bio': 'Bio',
        'type': 'affiliate',
        'status': 'accepted',
        'totalCommission': {'amount': 0, 'currencyCode': 'QAR'},
        'couponsCreated': 2,
      });
    }

    if (path.endsWith('/v1/referral/coupons')) {
      return _response(path, {
        'uuid': 'coupon-1',
        'code': 'JAMES10',
        'discountPercentage': '10',
        'expiresAt': '2026-12-31T00:00:00.000Z',
      });
    }

    if (path == EndPoints.graphql) {
      final payload = (data as Map<String, dynamic>);
      final query = (payload['query'] ?? '').toString();

      if (query.contains('getCurrentAffiliateWalletTransactions')) {
        return _response(path, {
          'data': {
            'getCurrentAffiliateWalletTransactions': [
              {
                'uuid': 'tx-1',
                'amount': {'amount': 100, 'currencyCode': 'QAR'},
                'type': 'credit',
                'description': 'Commission payout',
                'createdAt': '2026-04-15T10:24:10.783Z',
              },
            ],
          },
        });
      }

      if (query.contains('getCurrentAffiliateCoupons')) {
        return _response(path, {
          'data': {
            'getCurrentAffiliateCoupons': [
              {
                'uuid': 'coupon-1',
                'code': 'JAMES10',
                'discountPercentage': '10.4',
                'ordersCount': 2,
                'expiresAt': '2026-12-31T00:00:00.000Z',
                'createdAt': '2026-04-15T10:07:07.504Z',
              },
            ],
          },
        });
      }

      if (query.contains('getCurrentAffiliate')) {
        return _response(path, {
          'data': {
            'getCurrentAffiliate': {
              'uuid': 'aff-1',
              'fullName': 'James',
              'gender': 'Male',
              'nationality': 'Qatari',
              'bio': 'I am James',
              'type': 'influencer',
              'status': 'accepted',
              'totalCommission': {'amount': 120, 'currencyCode': 'QAR'},
              'totalPaid': {'amount': 40, 'currencyCode': 'QAR'},
              'remainingBalance': {'amount': 80, 'currencyCode': 'QAR'},
              'couponsCreated': 2,
              'couponsUsed': 1,
              'trendingCoupon': {'uuid': 'coupon-1'},
              'topProduct': {'uuid': 'product-1'},
              'wallet': {
                'uuid': 'wallet-1',
                'amount': {'amount': 200, 'currencyCode': 'QAR'},
                'amountPending': {'amount': 0, 'currencyCode': 'QAR'},
                'amountAvailable': {'amount': 0, 'currencyCode': 'QAR'},
              },
              'createdAt': '2026-04-14T06:44:14.229Z',
            },
          },
        });
      }

      if (query.contains('getNotifications')) {
        return _response(path, {
          'data': {
            'getNotifications': [
              {
                'uuid': 'n-1',
                'type': 'ORDER_SHIPPED',
                'title': 'Your order has been shipped',
                'brief': 'Order #1042 is on its way',
                'message': 'Great news! Your order is on the way.',
                'payload': {'orderId': '1042'},
                'priority': 'HIGH',
                'isRead': false,
                'createdAt': '2026-04-15T10:30:00.000Z',
                'updatedAt': '2026-04-15T10:30:00.000Z',
                'customer': {
                  'uuid': 'c-1',
                  'fullName': 'Your Name',
                  'emailAddress': 'your-name@your-domain.com',
                  'phoneNumber': '+974 12345678',
                },
              },
            ],
          },
        });
      }
    }

    return _response(path, {'data': {}});
  }

  @override
  Future<Response<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    lastPath = path;
    lastData = data;
    return _response(path, {'ok': true});
  }
}

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env.development');
    AppConfig.initialize(
      flavor: AppFlavor.development,
      envFile: '.env.development',
    );
  });

  test(
    'Referral API dry-run aligns with updated endpoints and mappings',
    () async {
      final api = FakeApiConsumer();

      final affRemote = aff_ds.AffiliateRemoteDataSource(apiConsumer: api);
      final infRemote = inf_ds.InfluencerRemoteDataSource(apiConsumer: api);
      final notifRemote = notif_ds.NotificationRemoteDataSource(
        apiConsumer: api,
      );
      final profileRemote = profile_ds.ProfileRemoteDataSource(
        apiConsumer: api,
      );

      await affRemote.signAffiliate(
        token: 't',
        name: 'James',
        nationality: 'Qatari',
        gender: 'Male',
        bio: 'Bio',
      );
      expect(api.lastPath, endsWith('/v1/referral/affiliates/affiliate'));

      await infRemote.signAffiliate(
        token: 't',
        name: 'James',
        nationality: 'Qatari',
        gender: 'Male',
        bio: 'Bio',
      );
      expect(api.lastPath, endsWith('/v1/referral/affiliates/influencer'));

      await affRemote.createCoupon(
        token: 't',
        code: 'JAMES10',
        expiryDate: '2026-12-31',
        discountPercentage: 10,
      );
      expect(api.lastPath, endsWith('/v1/referral/coupons'));
      final couponBody = api.lastData as Map<String, dynamic>;
      expect(couponBody.containsKey('expiresAt'), isTrue);

      final statusResponse = await affRemote.getAffiliateStatus(token: 't');
      final status = aff_status.AffiliateStatus.fromJson(
        statusResponse.data as Map<String, dynamic>,
      );
      expect(status.affiliateId, 'aff-1');
      expect(status.status, 'accepted');
      expect(status.walletBalance, 200);
      expect(status.totalCommission, 120);
      expect(status.totalPaid, 40);
      expect(status.remainingBalance, 80);
      expect(status.couponsCreated, 2);
      expect(status.couponsUsed, 1);
      expect(status.trendingCouponId, 'coupon-1');
      expect(status.topProductId, 'product-1');

      final couponsResponse = await affRemote.getCouponCodeByAffiliateId(
        token: 't',
      );
      final coupons = (couponsResponse.data as List)
          .map(
            (e) =>
                aff_coupons.GetCouponsModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
      expect(coupons, isNotEmpty);
      expect(coupons.first.id, 'coupon-1');
      expect(coupons.first.discountPercentage, greaterThan(0));
      expect(coupons.first.ordersCount, 2);

      final notificationsResponse = await notifRemote.getNotifications(
        token: 't',
      );
      final notifications = (notificationsResponse.data as List)
          .map(
            (e) => notif_model.NotificationModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
      expect(notifications, isNotEmpty);
      expect(notifications.first.id, 'n-1');
      expect(notifications.first.body, isNotEmpty);

      final walletResponse = await profileRemote.getWalletBalance(token: 't');
      final wallet = walletResponse.data as Map<String, dynamic>;
      expect(wallet['wallet'], isNotNull);

      final txResponse = await profileRemote.getAllTransactions(token: 't');
      final tx = (txResponse.data as List)
          .map((e) => tx_model.Transactions.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(tx, isNotEmpty);
      expect(tx.first.id, 'tx-1');
      expect(tx.first.amount, 100);
      expect(tx.first.createdAt.year, 2026);
    },
  );
}
