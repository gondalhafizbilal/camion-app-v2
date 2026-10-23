// import 'package:camion/config/widgets/custom_box_decoration.dart';
// import 'package:camion/core/utils/app_images.dart';
// import 'package:camion/core/utils/app_style.dart';
// import 'package:camion/features/join_us_influencers/presentation/widgets/custom__join_us_sliver_app_bar.dart';
// import 'package:camion/generated/l10n.dart';
// import 'package:camion/routing/app_router.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:go_router/go_router.dart';
//
// class InfluencereAccountScreen extends StatelessWidget {
//   const InfluencereAccountScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       resizeToAvoidBottomInset: false,
//       body: CustomScrollView(
//         slivers: [
//           SliverToBoxAdapter(child: SizedBox(height: 15.h)),
//             CustomJoinUsSliverAppBar(title:  S.of(context).influencer_account),
//           SliverToBoxAdapter(child: SizedBox(height: 20.h)),
//           SliverToBoxAdapter(
//             child: GestureDetector(
//               onTap: () {
//                 GoRouter.of(context).push(AppRouter.myinfluencerCodings);
//               },
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
//                 margin: EdgeInsets.symmetric(horizontal: 16.w),
//                 decoration: getContainerBoxDecoration(),
//                 child: Row(
//                   children: [
//                     SvgPicture.asset(
//                       Assets.imagesPlay,
//                       width: 25.w,
//                       height: 25.h,
//                     ),
//
//                     SizedBox(width: 15.w),
//
//                     Text(
//                        S.of(context).my_coupuns,
//                       style: AppStyle.styleRegular18(context).copyWith(
//                         color: Colors.black,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           SliverToBoxAdapter(
//             child: GestureDetector(
//               onTap: () {
//                 GoRouter.of(context).push(AppRouter.createInfluencerCode);
//               },
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
//                 margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
//                 decoration: getContainerBoxDecoration(),
//                 child: Row(
//                   children: [
//                     Image.asset(Assets.imagesSave, width: 25.w, height: 25.h),
//
//                     SizedBox(width: 15.w),
//
//                     Text(
//                        S.of(context).create_coupon,
//                       style: AppStyle.styleRegular18(context).copyWith(
//                         color: Colors.black,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';

import 'package:camion/config/widgets/custom_box_decoration.dart';
import 'package:camion/core/api/backend_unavailable_detector.dart';
import 'package:camion/core/api/end_points.dart';
import 'package:camion/core/services/backend_unavailable_notifier.dart';
import 'package:camion/core/utils/app_images.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/currency_display_utils.dart';
import 'package:camion/core/utils/number_format_utils.dart';
import 'package:camion/core/utils/money_utils.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/features/join_us_influencers/presentation/widgets/custom__join_us_sliver_app_bar.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/cache/secure_cache_storage.dart';
import '../../../../core/services/service_locator.dart';

class InfluencereAccountScreen extends StatefulWidget {
  const InfluencereAccountScreen({super.key});

  @override
  State<InfluencereAccountScreen> createState() =>
      _InfluencereAccountScreenState();
}

class _InfluencereAccountScreenState extends State<InfluencereAccountScreen> {
  late Future<_InfluencerStatsModel> _statsFuture;
  String _t(String en, String ar) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  String _influencerAccountTitle(BuildContext context) {
    if (Localizations.localeOf(context).languageCode.toLowerCase() == 'ar') {
      return 'لوحة تحكم المؤثر';
    }
    return 'Influencer Dashboard';
  }

  String _moneyWithCurrency(num? amount, String? currencyCode) {
    return '${formatTwoDecimalsOrDash(amount)}${resolveCurrencyCode([currencyCode])}';
  }

  @override
  void initState() {
    super.initState();
    _statsFuture = _getInfluencerStatsMe();
  }

  void _log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }

  Future<_InfluencerStatsModel> _getInfluencerStatsMe() async {
    final String? token = await sl<SecureCacheHelper>().getData(key: 'token');

    if (token == null || token.trim().isEmpty) {
      throw Exception("Token not found in SecureCacheHelper (key: 'token').");
    }

    final String url = EndPoints.graphql;

    final headers = <String, dynamic>{"Authorization": "Bearer $token"};

    _log("══════════════════════════════════════════════════════");
    _log("📡 [Influencer Stats] START REQUEST");
    _log("➡️  METHOD: POST");
    _log("➡️  URL: $url");
    _log("➡️  HEADERS: ${const JsonEncoder.withIndent('  ').convert(headers)}");
    _log("══════════════════════════════════════════════════════");

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        headers: headers,
      ),
    );

    // ✅ Interceptors for professional logging (request/response/errors)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _log("🟦 [DIO][REQUEST]");
          _log("• ${options.method} ${options.uri}");
          _log(
            "• headers: ${const JsonEncoder.withIndent('  ').convert(options.headers)}",
          );
          if (options.queryParameters.isNotEmpty) {
            _log(
              "• query: ${const JsonEncoder.withIndent('  ').convert(options.queryParameters)}",
            );
          }
          if (options.data != null) {
            _log("• body: ${_safePretty(options.data)}");
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _log("🟩 [DIO][RESPONSE]");
          _log("• status: ${response.statusCode}");
          _log("• url: ${response.realUri}");
          _log("• data: ${_safePretty(response.data)}");
          _log("══════════════════════════════════════════════════════");
          return handler.next(response);
        },
        onError: (e, handler) {
          _log("🟥 [DIO][ERROR]");
          _log("• type: ${e.type}");
          _log("• message: ${e.message}");
          _log("• url: ${e.requestOptions.uri}");
          if (e.response != null) {
            _log("• status: ${e.response?.statusCode}");
            _log("• data: ${_safePretty(e.response?.data)}");
          }
          _log("══════════════════════════════════════════════════════");
          return handler.next(e);
        },
      ),
    );

    Response response;
    try {
      response = await dio.post(
        url,
        data: {
          "query": '''
query GetCurrentAffiliate {
  getCurrentAffiliate {
    uuid
    type
    status
    totalCommission {
      amount
      currencyCode
    }
    totalPaid {
      amount
      currencyCode
    }
    remainingBalance {
      amount
      currencyCode
    }
    couponsCreated
    couponsUsed
    trendingCoupon {
      uuid
    }
    topProduct {
      uuid
    }
    wallet {
      uuid
      amount {
        amount
        currencyCode
      }
    }
    createdAt
  }
}
''',
          "variables": const <String, dynamic>{},
        },
      );
    } on DioException catch (error) {
      if (BackendUnavailableDetector.isBackendUnavailableDioException(error)) {
        BackendUnavailableNotifier.show();
      }
      rethrow;
    }

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        "Unexpected response format. Expected JSON object, got: ${response.data.runtimeType}",
      );
    }

    final root = response.data as Map<String, dynamic>;
    final errors = root['errors'];
    if (errors is List && errors.isNotEmpty) {
      if (BackendUnavailableDetector.isBackendUnavailablePayload(root)) {
        BackendUnavailableNotifier.show();
      }
      final first = errors.first;
      final message = first is Map<String, dynamic>
          ? (first['message']?.toString() ?? 'GraphQL request failed')
          : 'GraphQL request failed';
      if (BackendUnavailableDetector.isBackendUnavailableMessage(message)) {
        BackendUnavailableNotifier.show();
      }
      throw Exception(message);
    }

    final data = root['data'];
    final currentAffiliate = data is Map<String, dynamic>
        ? data['getCurrentAffiliate']
        : null;
    if (currentAffiliate is! Map<String, dynamic>) {
      throw Exception('Affiliate data not found');
    }

    return _InfluencerStatsModel.fromCurrentAffiliate(currentAffiliate);
  }

  String _safePretty(dynamic data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(
        _redactSensitiveData(data),
      );
    } catch (_) {
      return _redactSensitiveData(data).toString();
    }
  }

  dynamic _redactSensitiveData(dynamic value) {
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      value.forEach((key, item) {
        final keyText = key.toString();
        final normalized = keyText.toLowerCase();
        final isSensitive =
            normalized.contains('authorization') ||
            normalized.contains('token') ||
            normalized.contains('password') ||
            normalized.contains('secret') ||
            normalized.contains('apikey') ||
            normalized.contains('api_key');
        sanitized[keyText] = isSensitive ? '***REDACTED***' : _redactSensitiveData(item);
      });
      return sanitized;
    }
    if (value is List) {
      return value.map(_redactSensitiveData).toList();
    }
    return value;
  }

  void _retry() {
    setState(() {
      _statsFuture = _getInfluencerStatsMe();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: SizedBox(height: 15.h)),
          CustomJoinUsSliverAppBar(title: _influencerAccountTitle(context)),
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: FutureBuilder<_InfluencerStatsModel>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _statsLoadingCard(context);
                  }

                  if (snapshot.hasError) {
                    return _statsErrorCard(
                      context,
                      message: _t(
                        "Unable to fetch statistics. Please try again.",
                        "تعذر جلب الإحصائيات. يرجى إعادة المحاولة.",
                      ),
                      onRetry: _retry,
                    );
                  }

                  final stats = snapshot.data;
                  if (stats == null) {
                    return _statsErrorCard(
                      context,
                      message: _t(
                        "Stats response is empty.",
                        "لا توجد بيانات إحصائيات.",
                      ),
                      onRetry: _retry,
                    );
                  }

                  return _influencerStatsCard(context, stats);
                },
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 20.h)),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
              child: Row(
                children: [
                  Expanded(
                    child: _DashboardActionCard(
                      label: S.of(context).create_coupon,
                      icon: Image.asset(
                        Assets.imagesCreateCoupon,
                        width: 46.w,
                        height: 46.h,
                      ),
                      onTap: () => GoRouter.of(
                        context,
                      ).push(AppRouter.createInfluencerCode),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _DashboardActionCard(
                      label: S.of(context).my_coupuns,
                      icon: Image.asset(
                        Assets.imagesMyCoupons,
                        width: 46.w,
                        height: 46.h,
                      ),
                      onTap: () => GoRouter.of(
                        context,
                      ).push(AppRouter.myinfluencerCodings),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// UI HELPERS (INLINE)
  /// =======================

  Widget _influencerStatsCard(
    BuildContext context,
    _InfluencerStatsModel stats,
  ) {
    String pretty(dynamic v) {
      if (v == null) return "-";
      if (v is String && v.trim().isEmpty) return "-";
      if (v is Map || v is List) {
        return const JsonEncoder.withIndent("  ").convert(v);
      }
      return v.toString();
    }

    return Container(
      width: 343.w,
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 18.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t("Influencer Statistics", "إحصائيات المؤثر"),
            style: TextStyle(
              fontFamily: 'Montes',
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              height: 24 / 16,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: _DashboardStatItem(
                  label: _t("Affiliate ID", "معرّف المؤثر"),
                  value: pretty(stats.affiliateId),
                ),
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: _DashboardStatItem(
                  label: _t("Type", "النوع"),
                  value: pretty(stats.type),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _DashboardStatItem(
                  label: _t("Total Commision", "إجمالي العمولة"),
                  value: _moneyWithCurrency(
                    stats.totalCommission,
                    stats.totalCommissionCurrencyCode,
                  ),
                ),
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: _DashboardStatItem(
                  label: _t("Total Paid", "إجمالي المدفوع"),
                  value: _moneyWithCurrency(
                    stats.totalPaid,
                    stats.totalPaidCurrencyCode,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _DashboardStatItem(
                  label: _t("Remaining Balance", "الرصيد المتبقي"),
                  value: _moneyWithCurrency(
                    stats.remainingBalance,
                    stats.remainingBalanceCurrencyCode,
                  ),
                ),
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: _DashboardStatItem(
                  label: _t("Coupons Usage", "استخدام القسائم"),
                  value: pretty(stats.couponsUsedCount),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              Expanded(
                child: _DashboardStatItem(
                  label: _t("Trending Coupon", "القسيمة الرائجة"),
                  value: pretty(stats.trendingCoupon),
                ),
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: _DashboardStatItem(
                  label: _t("Top Product", "المنتج الأعلى"),
                  value: pretty(stats.topProduct),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsLoadingCard(BuildContext context) {
    return Container(
      decoration: getContainerBoxDecoration(),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14.h,
            width: 140.w,
            color: Colors.black.withValues(alpha: 0.06),
          ),
          SizedBox(height: 12.h),
          Container(
            height: 10.h,
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.05),
          ),
          SizedBox(height: 8.h),
          Container(
            height: 10.h,
            width: 240.w,
            color: Colors.black.withValues(alpha: 0.05),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 62.h,
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  height: 62.h,
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 62.h,
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  height: 62.h,
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            height: 10.h,
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.05),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 10.h,
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
    );
  }

  Widget _statsErrorCard(
    BuildContext context, {
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      decoration: getContainerBoxDecoration(),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18.sp,
                  color: Colors.black.withValues(alpha: 0.75),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  _t("Couldn’t load statistics", "تعذر تحميل الإحصائيات"),
                  style: AppStyle.styleRegular18(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Text(
              message,
              style: AppStyle.styleRegular18(context).copyWith(
                fontSize: 12.sp,
                color: Colors.black.withValues(alpha: 0.70),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: CustomElevatedButton(
              onPressed: onRetry,
              backgroundColor: AppColors.primaryColor,
              child: Text(
                S.of(context).retry,
                style: AppStyle.styleRegular16(
                  context,
                ).copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatItem extends StatelessWidget {
  const _DashboardStatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Montes',
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            height: 18 / 12,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Montes',
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            height: 24 / 16,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 165.38.w,
        height: 120.h,
        decoration: BoxDecoration(
          color: const Color(0xFFD72631),
          borderRadius: BorderRadius.circular(10.r),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Montes',
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// INLINE MODEL (NO FILES)
/// =======================
class _InfluencerStatsModel {
  final String? affiliateId;
  final String? type;
  final num? totalCommission;
  final String? totalCommissionCurrencyCode;
  final num? totalPaid;
  final String? totalPaidCurrencyCode;
  final num? remainingBalance;
  final String? remainingBalanceCurrencyCode;
  final int? couponsUsedCount;

  /// In your screenshot these are `null`, but they might become objects later
  final dynamic trendingCoupon;
  final dynamic topProduct;

  const _InfluencerStatsModel({
    required this.affiliateId,
    required this.type,
    required this.totalCommission,
    required this.totalCommissionCurrencyCode,
    required this.totalPaid,
    required this.totalPaidCurrencyCode,
    required this.remainingBalance,
    required this.remainingBalanceCurrencyCode,
    required this.couponsUsedCount,
    required this.trendingCoupon,
    required this.topProduct,
  });

  factory _InfluencerStatsModel.fromCurrentAffiliate(
    Map<String, dynamic> json,
  ) {
    num money(dynamic value) {
      return parseMoneyValue(value);
    }

    final trendingCoupon = json['trendingCoupon'];
    final topProduct = json['topProduct'];

    return _InfluencerStatsModel(
      affiliateId: json["uuid"]?.toString(),
      type: json["type"]?.toString(),
      totalCommission: money(json['totalCommission']),
      totalCommissionCurrencyCode:
          parseMoneyCurrencyCode(json['totalCommission']),
      totalPaid: money(json['totalPaid']),
      totalPaidCurrencyCode: parseMoneyCurrencyCode(json['totalPaid']),
      remainingBalance: money(json['remainingBalance']),
      remainingBalanceCurrencyCode:
          parseMoneyCurrencyCode(json['remainingBalance']),
      couponsUsedCount: (json['couponsUsed'] as num? ?? 0).toInt(),
      trendingCoupon: trendingCoupon is Map<String, dynamic>
          ? trendingCoupon['uuid']
          : trendingCoupon,
      topProduct: topProduct is Map<String, dynamic>
          ? topProduct['uuid']
          : topProduct,
    );
  }
}
