import 'package:camion/core/utils/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<dynamic> customModalBottomSheetProfile({
  required String title,
  required String subTitle,
  required Widget Function(BuildContext bottomSheetContext) contentBuilder,
  required double screenWidth,
  required BuildContext context,
}) {
  return showModalBottomSheet(
    backgroundColor: Colors.white,
    constraints: BoxConstraints(maxWidth: screenWidth),
    context: context,
    useRootNavigator: true,
    builder: (bottomSheetContext) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                SizedBox(
                  height: 20.h,
                ),
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      style: AppStyle.styleSemiBold18(
                        bottomSheetContext,
                      ).copyWith(color: Colors.black),
                    ),
                  ),
                ),

                SizedBox(height: 15.h),

                Center(
                  child: Text(
                    textAlign: TextAlign.center,
                    subTitle,
                    style: AppStyle.styleRegular14(
                      bottomSheetContext,
                    ).copyWith(color: Colors.black),
                  ),
                ),

                SizedBox(height: 35.h),

                contentBuilder(bottomSheetContext),

                SizedBox(
                  height: 40.h,
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
