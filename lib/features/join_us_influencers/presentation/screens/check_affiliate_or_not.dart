import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/core/utils/connectivity_error_utils.dart';
import 'package:camion/features/join_us_influencers/presentation/logic/cubit/get_affiliate_status_cubit/get_affiliate_status_cubit.dart';
import 'package:camion/features/join_us_influencers/presentation/screens/pending_screen.dart';
import 'package:camion/features/join_us_influencers/presentation/screens/rejected_screen.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class InfluencerCheckScreen extends StatefulWidget {
  const InfluencerCheckScreen({super.key});

  @override
  State<InfluencerCheckScreen> createState() => _AffiliateCheckScreenState();
}

class _AffiliateCheckScreenState extends State<InfluencerCheckScreen> {
  String _conflictMessage(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic
        ? 'أنت مسجل بالفعل كمسوّق، ولا يمكنك عرض قسم المؤثرين.'
        : 'You are already an affiliate, you cannot view this influencer section.';
  }

  @override
  void initState() {
    super.initState();
    context.read<GetInfluencerStatusCubit>().getAffiliateStatus();
  }

  bool _isCurrentRouteAffiliateCheck() {
    final currentRoute = GoRouterState.of(context).uri.path;
    return currentRoute == AppRouter.influencerCheckScreen;
  }

  void _navigateIfCurrentRoute(String route) {
    if (_isCurrentRouteAffiliateCheck()) {
      final fromProfile =
          GoRouterState.of(context).uri.queryParameters['fromProfile'] == '1';
      final target = fromProfile ? '$route?fromProfile=1' : route;
      GoRouter.of(context).pushReplacement(target);
    }
  }

  bool _isConflictWithAffiliate(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('already registered as an affiliate') ||
        normalized.contains('already registered') ||
        normalized.contains('already an affiliate');
  }

  bool _isAffiliateType(String? type) {
    final normalized = (type ?? '').trim().toLowerCase();
    return normalized.contains('affiliate');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: BlocConsumer<GetInfluencerStatusCubit, GetAffiliateStatusState>(
          listener: (context, state) {
            if (state is GetAffiliateStatusSuccess) {
              final status = state.data.status;
              final isAffiliate = _isAffiliateType(state.data.type);

              if (isAffiliate) {
                return;
              }

              if (status == 'accepted' || status == 'approved') {
                _navigateIfCurrentRoute(AppRouter.influencerAccount);
              }
            }

            if (state is GetAffiliateStatusError) {
              if (isConnectivityErrorStatus(state.error.statusCode)) {
                return;
              }
              final message = state.error.message;

              if (!_isConflictWithAffiliate(message)) {
                _navigateIfCurrentRoute(AppRouter.influencerWelcome);
              }
            }
          },
          builder: (context, state) {
            if (state is GetAffiliateStatusSuccess) {
              if (_isAffiliateType(state.data.type)) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _ConflictStatusCard(
                    icon: Icons.block_rounded,
                    message: _conflictMessage(context),
                    onRetry: () {
                      context
                          .read<GetInfluencerStatusCubit>()
                          .getAffiliateStatus();
                    },
                  ),
                );
              }

              final status = state.data.status;
              if (status == "pending") {
                return const PendingScreen();
              }

              if (status == "rejected") {
                return const RejectedScreen();
              }
            }

            if (state is GetAffiliateStatusError) {
              final message = state.error.message;

              if (_isConflictWithAffiliate(message)) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _ConflictStatusCard(
                    icon: Icons.block_rounded,
                    message: _conflictMessage(context),
                    onRetry: () {
                      context
                          .read<GetInfluencerStatusCubit>()
                          .getAffiliateStatus();
                    },
                  ),
                );
              }
            }
            return const CircularProgressIndicator(
              color: AppColors.primaryColor,
            );
          },
        ),
      ),
    );
  }
}

class _ConflictStatusCard extends StatelessWidget {
  const _ConflictStatusCard({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.white, size: 34.sp),
            ),
            SizedBox(height: 20.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyle.styleSectionTitle16Medium(
                context,
              ).copyWith(color: AppColors.black, height: 24 / 16),
            ),
            SizedBox(height: 20.h),
            CustomElevatedButton(
              onPressed: onRetry,
              backgroundColor: AppColors.primaryColor,
              child: Text(
                S.of(context).retry,
                style: AppStyle.styleButtonLabel14Regular(
                  context,
                ).copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
