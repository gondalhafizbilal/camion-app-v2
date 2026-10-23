import 'package:camion/core/utils/app_colors.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class CamionCommitmentsScreen extends StatelessWidget {
  const CamionCommitmentsScreen({super.key});

  static final Uri _termsOfUseUri = Uri.parse(
    'https://camion-app.com/en/myaccount/terms-conditions#terms-of-use',
  );

  static const Color _green = Color(0xFF2E9A58);
  static const Color _darkText = Color(0xFF3D3D3D);
  static const Color _bodyText = Color(0xFF666666);
  static const Color _softDivider = Color(0xFFEDEDED);
  static const Color _iconRed = AppColors.primaryColor;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;
    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18.w, 6.h, 18.w, 32.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CommitmentsTopBar(onBack: () => AppNavigator.safePop(context)),
                SizedBox(height: 20.h),
                _CommitmentsIntro(
                  title: isArabic
                      ? 'ملتزمون برضا العملاء'
                      : 'Committed to customer satisfaction',
                  description: isArabic
                      ? 'تقدم كميون تجربة تجارة إلكترونية سلسة عبر جميع منصاتها. دعنا نشرح لك كيف نضمن أفضل تجربة ممكنة.'
                      : 'Camion offers a seamless e-commerce experience across all its platforms. Let us explain how we ensure the best possible experience.',
                ),
                SizedBox(height: 22.h),
                _CommitmentInfoSection(
                  icon: Icons.credit_card_rounded,
                  title: isArabic ? 'طرق الدفع' : 'Payment methods',
                  description: isArabic
                      ? 'نوفر لك مجموعة واسعة وآمنة من خيارات الدفع.'
                      : 'We provide a wide and safe range of payment options for you.',
                  bullets: isArabic
                      ? ['الدفع الآمن', 'حماية الخصوصية', 'شركاء دفع عالميون']
                      : [
                          'Secure payment',
                          'Privacy protection',
                          'Global payment partners',
                        ],
                  footer: const _PaymentMethodsContent(),
                ),
                const _SectionDivider(),
                _CommitmentInfoSection(
                  icon: Icons.verified_user_rounded,
                  title: isArabic ? 'إجراءات السلامة' : 'Safety measures',
                  description: isArabic
                      ? 'إليك ما نقوم به للحفاظ على تجربة تسوق آمنة في كميون:'
                      : 'Here is what we do to keep your shopping experience safe at Camion:',
                  bullets: isArabic
                      ? [
                          'تشفير البيانات لأقصى درجات الأمان',
                          'مراقبة المعاملات على مدار الساعة لمنع الاحتيال',
                          'لا نقوم بحفظ أي من بيانات بطاقاتك لمزيد من الأمان.',
                          'عمليات تدقيق منتظمة من الجهات المختصة',
                          'الالتزام بجميع لوائح خصوصية البيانات العالمية لضمان حماية المعلومات',
                          'عمليات وخيارات دفع آمنة',
                          'حماية الخصوصية',
                        ]
                      : [
                          'Data encryption for maximum security',
                          '24/7 transaction monitoring to prevent fraud',
                          'We are not saving any of your cards data for added security.',
                          'Regular audits by authorities',
                          'Compliance with all global data privacy regulations to ensure information protection',
                          'Secure payment processes and options',
                          'Privacy protection',
                        ],
                ),
                const _SectionDivider(),
                _CommitmentInfoSection(
                  icon: Icons.local_shipping_rounded,
                  title: isArabic ? 'الشحن والتوصيل' : 'Shipping & Delivery',
                  description: isArabic
                      ? 'نوفر عمليات شحن وتوصيل سريعة ودقيقة.'
                      : 'We offer fast yet diligent shipping and delivery processes.',
                  bullets: isArabic
                      ? [
                          'استرداد قيمة الطرود المفقودة أو التالفة',
                          'شركاء توصيل عالميون ومحليون',
                        ]
                      : [
                          'Refund for lost and damaged packages',
                          'Global and local delivery partners',
                        ],
                  footer: _DeliveryPartnersContent(
                    label: isArabic ? 'شركاء التوصيل' : 'Delivery partners',
                  ),
                ),
                const _SectionDivider(),
                _CommitmentInfoSection(
                  icon: Icons.assignment_return_rounded,
                  title: isArabic ? 'الإرجاع والاسترداد' : 'Returns & Refunds',
                  description: isArabic
                      ? 'لست راضيًا عن طلبك؟ يمكنك إرجاعه بسهولة واسترداد أموالك.'
                      : 'Not satisfied with your order? Easily return and get your refund.',
                  bullets: isArabic
                      ? [
                          'إرجاع سهل ومجاني في الحالات المقبولة.',
                          'معالجة سريعة لطلبات الاسترداد',
                        ]
                      : [
                          'Easy and free return in case of acceptable situations.',
                          'Quick refund processing',
                        ],
                  footer: _LearnMoreContent(
                    text: isArabic ? 'اعرف المزيد' : 'Learn more',
                    url: _termsOfUseUri,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommitmentsTopBar extends StatelessWidget {
  const _CommitmentsTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: 52.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(22.r),
              child: Padding(
                padding: EdgeInsets.all(8.r),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Icon(
                    isRtl ? Icons.arrow_forward : Icons.arrow_back,
                    color: const Color(0xFF222222),
                    size: 25.sp,
                  ),
                ),
              ),
            ),
          ),
          Text(
            'camion',
            style: TextStyle(
              fontFamily: 'Montes',
              fontSize: 31.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommitmentsIntro extends StatelessWidget {
  const _CommitmentsIntro({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _RoundIcon(
              icon: Icons.handshake_rounded,
              color: CamionCommitmentsScreen._iconRed,
            ),
            SizedBox(width: 7.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Montes',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: CamionCommitmentsScreen._darkText,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 29.w),
          child: Text(
            description,
            style: TextStyle(
              fontFamily: 'Montes',
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: CamionCommitmentsScreen._bodyText,
              height: 1.12,
            ),
          ),
        ),
      ],
    );
  }
}

class _CommitmentInfoSection extends StatelessWidget {
  const _CommitmentInfoSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.bullets,
    this.footer,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> bullets;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RoundIcon(icon: icon, color: CamionCommitmentsScreen._iconRed),
              SizedBox(width: 7.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Montes',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: CamionCommitmentsScreen._darkText,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            description,
            style: TextStyle(
              fontFamily: 'Montes',
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: CamionCommitmentsScreen._bodyText,
              height: 1.15,
            ),
          ),
          SizedBox(height: 5.h),
          ...bullets.map((bullet) => _CheckBullet(text: bullet)),
          if (footer != null) ...[SizedBox(height: 9.h), footer!],
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21.w,
      height: 21.w,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: 13.sp),
    );
  }
}

class _CheckBullet extends StatelessWidget {
  const _CheckBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Icon(
              Icons.check_rounded,
              color: CamionCommitmentsScreen._green,
              size: 17.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Montes',
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: CamionCommitmentsScreen._bodyText,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodsContent extends StatelessWidget {
  const _PaymentMethodsContent();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7.w,
      runSpacing: 7.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: const [
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PaymentBadge(label: 'Apple Pay', strong: true),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PaymentBadge(label: 'Mastercard', leading: _MastercardMark()),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PaymentBadge(label: 'VISA', textColor: Color(0xFF1D3C8F)),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PaymentBadge(label: 'G Pay', textColor: Color(0xFF4A4A4A)),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PaymentBadge(
            label: 'NAPS',
            leading: _NapsMark(),
            textColor: Color(0xFF1D3C8F),
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: _PaymentBadge(
            label: 'QPAY',
            leading: _QPayMark(),
            textColor: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _DeliveryPartnersContent extends StatelessWidget {
  const _DeliveryPartnersContent({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Montes',
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            color: CamionCommitmentsScreen._bodyText,
          ),
        ),
        SizedBox(width: 12.w),
        const _PartnerLogoText(text: '4PX', color: Color(0xFFE5482F)),
        SizedBox(width: 5.w),
        Text(
          '4PX',
          style: TextStyle(
            fontFamily: 'Montes',
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: CamionCommitmentsScreen._darkText,
          ),
        ),
        SizedBox(width: 10.w),
        const _PartnerLogoText(text: 'GFS', color: Color(0xFF202020)),
        SizedBox(width: 5.w),
        Text(
          'GFS',
          style: TextStyle(
            fontFamily: 'Montes',
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: CamionCommitmentsScreen._darkText,
          ),
        ),
      ],
    );
  }
}

class _LearnMoreContent extends StatelessWidget {
  const _LearnMoreContent({required this.text, required this.url});

  final String text;
  final Uri url;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return InkWell(
      onTap: () async {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(6.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Montes',
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: CamionCommitmentsScreen._bodyText,
              ),
            ),
            SizedBox(width: 4.w),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(
                isRtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 18.sp,
                color: CamionCommitmentsScreen._bodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({
    required this.label,
    this.leading,
    this.textColor = const Color(0xFF111111),
    this.strong = false,
  });

  final String label;
  final Widget? leading;
  final Color textColor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 31.h,
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: const Color(0xFFDCDCDC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, SizedBox(width: 5.w)],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Montes',
              fontSize: strong ? 12.sp : 11.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NapsMark extends StatelessWidget {
  const _NapsMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18.w,
      height: 16.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 8.w,
              height: 13.h,
              decoration: BoxDecoration(
                color: const Color(0xFF1D3C8F),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          Container(
            width: 8.w,
            height: 13.h,
            decoration: BoxDecoration(
              color: const Color(0xFF2E9A58),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 8.w,
              height: 13.h,
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QPayMark extends StatelessWidget {
  const _QPayMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16.w,
      height: 16.w,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        'Q',
        style: TextStyle(
          fontFamily: 'Montes',
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

class _MastercardMark extends StatelessWidget {
  const _MastercardMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 21.w,
      height: 14.h,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 14.w,
              height: 14.w,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5F00),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(
                color: const Color(0xFFF79E1B).withValues(alpha: 0.88),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerLogoText extends StatelessWidget {
  const _PartnerLogoText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Montes',
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Container(
        height: 1,
        width: double.infinity,
        color: CamionCommitmentsScreen._softDivider,
      ),
    );
  }
}
