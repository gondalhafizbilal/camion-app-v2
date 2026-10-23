import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final Set<String> _expandedItems = <String>{'shipping_1'};

  @override
  Widget build(BuildContext context) {
    final faqSections = <_FaqSection>[
      _FaqSection(
        title: S.of(context).Shipping_and_Delivery,
        items: [
          _FaqItem(
            id: 'shipping_0',
            question: S.of(context).question_1,
            answer: S.of(context).answer_1,
          ),
          _FaqItem(
            id: 'shipping_1',
            question: S.of(context).question_2,
            answer: S.of(context).answer_2,
          ),
        ],
      ),
      _FaqSection(
        title: S.of(context).Payments,
        items: [
          _FaqItem(
            id: 'payments_0',
            question: S.of(context).question_3,
            answer: S.of(context).answer_3,
          ),
        ],
      ),
      _FaqSection(
        title: S.of(context).Return_and_Exchange,
        items: [
          _FaqItem(
            id: 'returns_0',
            question: S.of(context).question_4,
            answer: S.of(context).answer_4,
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CmsHeader(
                title: S.of(context).help,
                onBack: () => AppNavigator.safePop(context),
              ),
              SizedBox(height: 18.h),
              ...faqSections.map(
                (section) => Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: AppStyle.styleCmsSectionTitle20Regular(context),
                      ),
                      SizedBox(height: 8.h),
                      ...section.items.map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: _buildFaqCard(context, item),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                S.of(context).Direct_communication,
                style: AppStyle.styleCmsSectionTitle20Regular(context),
              ),
              SizedBox(height: 14.h),
              _WhatsAppButton(onTap: _openWhatsApp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context, _FaqItem item) {
    final isExpanded = _expandedItems.contains(item.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(5.r),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedItems.remove(item.id);
              } else {
                _expandedItems.add(item.id);
              }
            });
          },
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 40.h),
            padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5.r),
              border: Border.all(color: AppColors.borderGray, width: 1.w),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.question,
                    style: AppStyle.styleInputField14Regular(
                      context,
                    ).copyWith(color: AppColors.deepDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  isExpanded ? '−' : '+',
                  style: AppStyle.styleCmsSectionTitle20Regular(
                    context,
                  ).copyWith(color: AppColors.primaryColor, height: 1),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text(
              item.answer,
              style: AppStyle.styleCmsBody10Regular(context),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openWhatsApp() async {
    final url = Uri.parse('https://wa.me/97477223333');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    AppToast.show(
      backgroundColor: Colors.red,
      gravity: ToastGravity.TOP,
      msg: Localizations.localeOf(context).languageCode == 'ar'
          ? 'تعذر فتح واتساب'
          : 'Unable to open WhatsApp',
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

class _WhatsAppButton extends StatelessWidget {
  const _WhatsAppButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(5.r),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 44.h),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(color: AppColors.borderGray, width: 1.w),
        ),
        child: Row(
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: const BoxDecoration(
                color: Color(0xFF25D366),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.call, color: Colors.white, size: 18.sp),
            ),
            SizedBox(width: 14.w),
            Text(
              S.of(context).Contact_us_via_WhatsApp,
              style: AppStyle.styleCmsSectionTitle20Regular(
                context,
              ).copyWith(fontSize: 13.sp, height: 24 / 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqSection {
  const _FaqSection({required this.title, required this.items});

  final String title;
  final List<_FaqItem> items;
}

class _FaqItem {
  const _FaqItem({
    required this.id,
    required this.question,
    required this.answer,
  });

  final String id;
  final String question;
  final String answer;
}
