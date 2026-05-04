import 'package:ailearning/src/common/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomDialogBox {
  static Future<bool?> showDialogBox({
    required String title,
    required String content,
    required String buttonTitle,
    required BuildContext context,
    VoidCallback? onConfirm,
    bool requiresTextConfirmation = false,
    IconData? icon,
    String? image,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return _CustomDialogWidget(
          title: title,
          content: content,
          buttonTitle: buttonTitle,
          onConfirm: onConfirm,
          requiresTextConfirmation: requiresTextConfirmation,
          icon: icon,
          image: image,
        );
      },
    );
  }
}

class _CustomDialogWidget extends StatefulWidget {
  final String title;
  final String content;
  final String buttonTitle;
  final VoidCallback? onConfirm; // optional and not required
  final bool requiresTextConfirmation;
  final IconData? icon;
  final String? image;

  const _CustomDialogWidget({
    required this.title,
    required this.content,
    required this.buttonTitle,
    this.onConfirm,
    this.requiresTextConfirmation = false,
    this.icon,
    this.image,
  });

  @override
  State<_CustomDialogWidget> createState() => _CustomDialogWidgetState();
}

class _CustomDialogWidgetState extends State<_CustomDialogWidget> {
  final TextEditingController _textController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (widget.requiresTextConfirmation) {
      final enteredText = _textController.text.trim().toLowerCase();
      if (enteredText != 'delete') {
        setState(() {
          _errorMessage = 'Incorrect confirmation text';
        });
        return;
      }
    }
    // Intentionally not calling onConfirm; dialog just returns true
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      backgroundColor: const Color.fromARGB(255, 1, 1, 1),
      title: Row(
        children: [
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.content,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontFamily: 'Poppins',
            ),
          ),
          if (widget.requiresTextConfirmation) ...[
            SizedBox(height: 16.h),
            TextField(
              controller: _textController,
              onChanged: (value) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontFamily: 'Poppins',
              ),
              decoration: InputDecoration(
                hintText: 'Type "delete" to confirm',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13.sp,
                  fontFamily: 'Poppins',
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                errorText: _errorMessage,
                errorStyle: TextStyle(
                  color: Colors.red,
                  fontSize: 12.sp,
                  fontFamily: 'Poppins',
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SizedBox(
                height: 40.h,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: SizedBox(
                height: 40.h,
                child: CustomElevatedButton(
                  onPressed: _handleConfirm,
                  title: widget.buttonTitle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
