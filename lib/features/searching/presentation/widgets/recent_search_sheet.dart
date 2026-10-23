import 'package:camion/config/widgets/app_tap_feedback.dart';
import 'dart:convert';

import 'package:camion/core/cache/cache_helper.dart';
import 'package:camion/core/services/service_locator.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

const String _recentSearchesCacheKey = 'recent_searches_v1';

Future<void> openRecentSearchSheet(
  BuildContext context, {
  ValueChanged<String>? onSearchSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
    ),
    builder: (_) => _RecentSearchSheet(
      hostContext: context,
      onSearchSelected: onSearchSelected,
    ),
  );
}

class _RecentSearchSheet extends StatefulWidget {
  const _RecentSearchSheet({required this.hostContext, this.onSearchSelected});

  final BuildContext hostContext;
  final ValueChanged<String>? onSearchSelected;

  @override
  State<_RecentSearchSheet> createState() => _RecentSearchSheetState();
}

class _RecentSearchSheetState extends State<_RecentSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  List<String> _recentSearches = const [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final saved = _readRecentSearches();
    if (!mounted) return;
    setState(() {
      _recentSearches = saved;
    });
  }

  List<String> _readRecentSearches() {
    final raw = sl<CacheHelper>().getDataString(key: _recentSearchesCacheKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<void> _persistRecentSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final existing = List<String>.from(_readRecentSearches());
    existing.removeWhere(
      (item) => item.toLowerCase() == normalized.toLowerCase(),
    );
    existing.insert(0, normalized);
    final trimmed = existing.take(8).toList();

    await sl<CacheHelper>().saveData(
      key: _recentSearchesCacheKey,
      value: jsonEncode(trimmed),
    );
  }

  Future<void> _submitSearch(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final callback = widget.onSearchSelected;
    final router = callback == null ? GoRouter.of(widget.hostContext) : null;
    await _persistRecentSearch(normalized);
    if (!mounted) return;
    Navigator.of(context).pop();
    if (callback != null) {
      callback(normalized);
      return;
    }

    final encodedQuery = Uri.encodeComponent(normalized);
    router?.push('${AppRouter.searchScreenWithProducts}?q=$encodedQuery');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isArabic =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'ar';

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 28.h, 16.w, bottomInset + 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    height: 48.h,
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 10.w, right: 8.w),
                          child: Image.asset(
                            'assets/images/searchicon.png',
                            width: 28.w,
                            height: 28.h,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: _submitSearch,
                            cursorColor: Colors.black,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18.sp,
                              fontFamily: 'Montes',
                              fontWeight: FontWeight.w400,
                              height: 1,
                            ),
                            decoration: InputDecoration(
                              hintText: isArabic ? 'بحث' : 'Search',
                              hintStyle: TextStyle(
                                color: const Color(0xFF8A8A8A),
                                fontSize: 16.sp,
                                fontFamily: 'Montes',
                                fontWeight: FontWeight.w400,
                              ),
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                AppTapFeedback(
                  onTap: () => Navigator.of(context).pop(),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: Text(
                      '×',
                      style: TextStyle(
                        color: const Color(0xFFEB5757),
                        fontSize: 30.sp,
                        fontFamily: 'Montes',
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 22.h),
            Text(
              isArabic ? 'عمليات البحث الأخيرة' : 'Recent search',
              style: TextStyle(
                color: const Color(0xFF4A4A4A),
                fontSize: 14.sp,
                fontFamily: 'Montes',
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
            ),
            SizedBox(height: 18.h),
            if (_recentSearches.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
                child: Text(
                  isArabic ? 'لا توجد عمليات بحث' : 'No recent searches',
                  style: TextStyle(
                    color: const Color(0xFF8A8A8A),
                    fontSize: 14.sp,
                    fontFamily: 'Montes',
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
              )
            else
              ..._recentSearches
                  .take(4)
                  .map(
                    (item) => _RecentSearchTile(
                      label: item,
                      onTap: () => _submitSearch(item),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  const _RecentSearchTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFF1F1F1F),
                  fontSize: 16.sp,
                  fontFamily: 'Montes',
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFFEB5757),
              size: 26.sp,
            ),
          ],
        ),
      ),
    );
  }
}
