import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

enum SnackbarType { error, success, info, progress }

class GlobalScaffoldManager {
  static final GlobalScaffoldManager _instance =
      GlobalScaffoldManager._internal();

  factory GlobalScaffoldManager() => _instance;

  GlobalScaffoldManager._internal();

  // ScaffoldMessenger key for fallback SnackBar
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Navigator key for overlay (top snackbar)
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Show a top snackbar anywhere
  void showSnackbar(
    String message, {
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 1),
    String? actionLabel,
    VoidCallback? onActionPressed,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool persistent = false,
  }) {
    try {
      final overlayState = navigatorKey.currentState?.overlay;

      if (overlayState != null) {
        showTopSnackBar(
          overlayState,
          persistent: persistent,
          _buildTopSnackbar(
            type,
            message,
            actionLabel: actionLabel,
            onActionPressed: onActionPressed,
            margin: margin,
            padding: padding,
            persistent: persistent,
          ),
          displayDuration: persistent ? Duration.zero : duration,
          snackBarPosition: SnackBarPosition.top,
        );
        return;
      }

      // fallback: normal SnackBar
      scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: persistent ? Duration.zero : duration,
          backgroundColor: _getSnackbarColor(type),
          behavior: SnackBarBehavior.floating,
          action: persistent
              ? SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                  },
                )
              : null,
        ),
      );
    } catch (e) {
      debugPrint("Error showing snackbar: $e");
    }
  }

  Widget _buildTopSnackbar(
    SnackbarType type,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool persistent = false,
  }) {
    return _buildSnackbarContainer(
      type,
      message,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      margin: margin,
      padding: padding,
      persistent: persistent,
    );
  }

  Widget _buildSnackbarContainer(
    SnackbarType type,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
    EdgeInsets? margin,
    EdgeInsets? padding,
    bool persistent = false,
  }) {
    final backgroundColor = _getSnackbarColor(type);

    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
          child: Dismissible(
            key: Key('snackbar_${DateTime.now().millisecondsSinceEpoch}'),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              // Snackbar will be automatically dismissed by the Dismissible widget
            },
            child: Container(
              padding:
                  padding ??
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: AlignmentGeometry.bottomCenter,
                  colors: [
                    backgroundColor.withOpacity(0.2),
                    backgroundColor.withOpacity(0.3),
                  ],
                  stops: [0, 1],
                ),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Color.fromRGBO(153, 153, 153, 1),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    _getSnackbarIcon(type),
                    color: Colors.white,
                    size: 24.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'poppins',
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getSnackbarColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.error:
        return const Color.fromRGBO(255, 93, 109, 0.5);
      case SnackbarType.success:
        return const Color.fromRGBO(77, 213, 83, 0.5);
      case SnackbarType.info:
        return const Color.fromRGBO(33, 150, 243, 0.5);
      case SnackbarType.progress:
        return const Color.fromRGBO(255, 152, 0, 0.5);
    }
  }

  IconData _getSnackbarIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.error:
        return Icons.error_outline;
      case SnackbarType.success:
        return Icons.check_circle_outline_rounded;
      case SnackbarType.info:
        return Icons.info_outline;
      case SnackbarType.progress:
        return Icons.hourglass_empty;
    }
  }
}
