import 'package:camion/config/widgets/custom_elevated_button.dart';
import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/app_toast.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedBackScreen extends StatefulWidget {
  const FeedBackScreen({super.key});

  @override
  State<FeedBackScreen> createState() => _FeedBackScreenState();
}

class _FeedBackScreenState extends State<FeedBackScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(15.w, 8.h, 15.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CmsHeader(
                title: S.of(context).give_us_feedback,
                onBack: () => AppNavigator.safePop(context),
              ),
              SizedBox(height: 28.h),
              Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: 176.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5.r),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  minLines: 8,
                  style: AppStyle.styleCmsBody10Regular(
                    context,
                  ).copyWith(color: AppColors.deepDark),
                  decoration: InputDecoration(
                    hintText: S.of(context).feed_back_description,
                    hintStyle: AppStyle.styleCmsBody10Regular(context),
                    border: _feedbackInputBorder(),
                    enabledBorder: _feedbackInputBorder(),
                    focusedBorder: _feedbackInputBorder(),
                    disabledBorder: _feedbackInputBorder(),
                    contentPadding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
                  ),
                ),
              ),
              SizedBox(height: 22.h),
              CustomElevatedButton(
                onPressed: _submitFeedback,
                height: 48.h,
                elevation: 0,
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'إرسال'
                      : 'Submit',
                  style: AppStyle.styleMedium16(
                    context,
                  ).copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _feedbackInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(5.r),
      borderSide: BorderSide(color: AppColors.borderGray, width: 1.w),
    );
  }

  Future<void> _submitFeedback() async {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      AppToast.show(
        backgroundColor: Colors.red,
        gravity: ToastGravity.TOP,
        msg: Localizations.localeOf(context).languageCode == 'ar'
            ? 'يرجى كتابة ملاحظاتك'
            : 'Please enter your feedback',
      );
      return;
    }

    final emailUri = Uri(
      scheme: 'mailto',
      path: 'info@camiontrading.com',
      queryParameters: {'subject': 'App feedback', 'body': message},
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    AppToast.show(
      backgroundColor: Colors.red,
      gravity: ToastGravity.TOP,
      msg: Localizations.localeOf(context).languageCode == 'ar'
          ? 'تعذر إرسال الملاحظات'
          : 'Unable to submit feedback',
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
