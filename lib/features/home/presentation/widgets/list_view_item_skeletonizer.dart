import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ListViewItemBuildingSkeleton extends StatelessWidget {
  const ListViewItemBuildingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 344.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 398.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 120.w,
                  height: 11.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  width: 150.w,
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  width: 210.w,
                  height: 10.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(height: 18.h),
                Container(
                  width: double.infinity,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
