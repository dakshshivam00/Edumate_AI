import 'package:ailearning/src/common/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomElevatedButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final double? height;
  final double? width;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;

  const CustomElevatedButton({
    super.key,
    required this.title,
    this.onPressed,
    this.height,
    this.width,
    this.fontSize,
    this.fontWeight,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  String _getLoadingText() {
    // Automatically generate loading text from title
    if (title.toLowerCase().contains('login')) {
      return 'Logging in...';
    } else if (title.toLowerCase().contains('sign up') ||
        title.toLowerCase().contains('signup')) {
      return 'Signing up...';
    } else if (title.toLowerCase().contains('google')) {
      if (title.toLowerCase().contains('sign in')) {
        return 'Signing in...';
      } else {
        return 'Signing up...';
      }
    }
    return title; // Default to original title if no pattern matches
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isLoading = onPressed == null;

    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? colorScheme.secondary,
        foregroundColor: foregroundColor ?? AppTheme.buttonForeground,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: colorScheme.onSurface.withOpacity(AppTheme.borderOpacity),
          ),
          borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: (fontSize ?? 16.sp) * 1.2,
                  height: (fontSize ?? 16.sp) * 1.2,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      foregroundColor ?? AppTheme.buttonForeground,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  _getLoadingText(),
                  style: TextStyle(
                    fontSize: fontSize ?? 16.sp,
                    fontWeight: fontWeight ?? FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            )
          : Text(
              title,
              style: TextStyle(
                fontSize: fontSize ?? 16.sp,
                fontWeight: fontWeight ?? FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
    );

    if (height != null || width != null) {
      return SizedBox(
        height: height ?? 48.h,
        width: width ?? double.infinity,
        child: button,
      );
    }

    return button;
  }
}
