import 'package:camion/config/widgets/notification_bell_with_badge.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/core/utils/navigation_utils.dart';
import 'package:camion/features/searching/presentation/logic/search_graphql_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({
    super.key,
    this.initialFilter = const SearchApiFilter(),
  });

  final SearchApiFilter initialFilter;

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  late String _selectedSortLabel;

  String _localizedSortLabel(String label, bool isArabic) {
    if (!isArabic) return label;
    switch (label) {
      case 'Best Match':
        return 'الأفضل تطابقًا';
      case 'Price: Low to High':
        return 'السعر: من الأقل إلى الأعلى';
      case 'Price: High to Low':
        return 'السعر: من الأعلى إلى الأقل';
      case 'Best Sellers':
        return 'الأكثر مبيعًا';
      case 'Most Favorited':
        return 'الأكثر تفضيلًا';
      case 'New Arrivals':
        return 'وصل حديثًا';
      case 'Most Rated':
        return 'الأعلى تقييمًا';
      default:
        return label;
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedSortLabel = widget.initialFilter.sortLabel;
  }

  void _resetToDefault() {
    setState(() {
      _selectedSortLabel = SearchSortOption.bestMatch.label;
    });
  }

  void _applyFilters() {
    final filter = SearchApiFilter(
      sortLabel: _selectedSortLabel,
      pageNumber: 1,
      itemsPerPage: 100,
    );

    context.pop(filter.toMap());
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 15.h, 16.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterHeader(
                      onBackTap: () => context.pop(),
                      onResetTap: _resetToDefault,
                      isArabic: isArabic,
                    ),
                    SizedBox(height: 32.h),
                    _FieldLabel(text: isArabic ? 'الترتيب' : 'Sort'),
                    SizedBox(height: 10.h),
                    _RoundedContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedSortLabel,
                          items: SearchSortOption.values
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option.label,
                                  child: Text(
                                    _localizedSortLabel(option.label, isArabic),
                                    style: AppStyle.styleRegular15(
                                      context,
                                    ).copyWith(color: Colors.black),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedSortLabel = value);
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
              child: SizedBox(
                width: double.infinity,
                height: 60.h,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD6222B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    isArabic ? 'تطبيق' : 'Apply',
                    style: AppStyle.styleRegular18(
                      context,
                    ).copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({
    required this.onBackTap,
    required this.onResetTap,
    required this.isArabic,
  });

  final VoidCallback onBackTap;
  final VoidCallback onResetTap;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBackTap,
          child: Icon(
            Icons.arrow_back_rounded,
            color: const Color(0xFF303030),
            size: 30.sp,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            isArabic ? 'الفلاتر' : 'Filter',
            style: AppStyle.styleSemiBold20(
              context,
            ).copyWith(color: Colors.black),
          ),
        ),
        GestureDetector(
          onTap: onResetTap,
          child: Text(
            isArabic ? 'إعادة ضبط الكل' : 'Reset All',
            style: AppStyle.styleRegular15(context).copyWith(
              color: Colors.black,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        SizedBox(width: 14.w),
        NotificationBellWithBadge(
          onTap: () => AppNavigator.openNotificationsOrLogin(context),
          borderRadius: BorderRadius.circular(8.r),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppStyle.styleSemiBold16(context).copyWith(color: Colors.black),
    );
  }
}

class _RoundedContainer extends StatelessWidget {
  const _RoundedContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFD0D0D0)),
      ),
      child: child,
    );
  }
}
