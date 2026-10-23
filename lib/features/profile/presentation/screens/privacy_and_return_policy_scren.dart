import 'package:camion/core/cache/secure_cache_storage.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/features/profile/data/models/cms_post_model.dart';
import 'package:camion/features/profile/data/repository/profie_repo.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrivacyAndReturnPolicyScren extends StatefulWidget {
  const PrivacyAndReturnPolicyScren({super.key});

  @override
  State<PrivacyAndReturnPolicyScren> createState() =>
      _PrivacyAndReturnPolicyScrenState();
}

class _PrivacyAndReturnPolicyScrenState
    extends State<PrivacyAndReturnPolicyScren> {
  late final Future<List<CmsPostModel>> _cmsPagesFuture;

  @override
  void initState() {
    super.initState();
    _cmsPagesFuture = _loadCmsPages();
  }

  Future<List<CmsPostModel>> _loadCmsPages() async {
    final token = await sl<SecureCacheHelper>().getData(key: 'token');
    final repository = sl<ProfileRepository>();

    final listResult = await repository.getCmsPages(token: token);
    final posts = listResult.fold<List<CmsPostModel>>((error) {
      throw Exception(error.message);
    }, (data) => data.where((post) => post.enabled).toList());

    if (posts.isEmpty) {
      return const <CmsPostModel>[];
    }
    return posts;
  }

  List<String> _contentPoints(CmsPostModel post) {
    final source = post.content.trim().isNotEmpty ? post.content : post.brief;
    final normalized = source
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
    final points = normalized
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (points.isNotEmpty) {
      return points;
    }
    return normalized.isNotEmpty ? <String>[normalized] : const <String>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<CmsPostModel>>(
          future: _cmsPagesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: AppStyle.styleCmsBody10Regular(context),
                  ),
                ),
              );
            }

            final sections = snapshot.data ?? const <CmsPostModel>[];

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CmsHeader(
                    title: S.of(context).privacy_poilicy_camion_app,
                    onBack: () => AppNavigator.safePop(context),
                  ),
                  SizedBox(height: 18.h),
                  if (sections.isEmpty)
                    Text(
                      'No policy pages found.',
                      style: AppStyle.styleCmsBody10Regular(context),
                    ),
                  ...sections.map((section) {
                    final points = _contentPoints(section);
                    return Padding(
                      padding: EdgeInsets.only(bottom: 22.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: AppStyle.styleCmsSectionTitle20Regular(
                              context,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          if (section.brief.trim().isNotEmpty &&
                              section.content.trim().isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: Text(
                                section.brief,
                                style: AppStyle.styleCmsBody10Regular(context),
                              ),
                            ),
                          ...points.map(
                            (point) => Padding(
                              padding: EdgeInsets.only(bottom: 2.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 6.h,
                                      right: 6.w,
                                      left: 2.w,
                                    ),
                                    child: Container(
                                      width: 3.w,
                                      height: 3.w,
                                      decoration: const BoxDecoration(
                                        color: AppColors.softBlack,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      point,
                                      style: AppStyle.styleCmsBody10Regular(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CmsHeader extends StatelessWidget {
  const _CmsHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: onBack,
            child: Padding(
              padding: EdgeInsets.all(4.r),
              child: Icon(
                Icons.arrow_back,
                size: 22.sp,
                color: AppColors.black,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(title, style: AppStyle.styleAppBarTitle20Medium(context)),
        ],
      ),
    );
  }
}
