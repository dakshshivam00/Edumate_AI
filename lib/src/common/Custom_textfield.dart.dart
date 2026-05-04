import 'package:ailearning/src/common/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthField extends StatefulWidget {
  final String hintText;
  final String header;
  final TextEditingController controller;
  final bool isObscureText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  const AuthField({
    super.key,
    required this.hintText,
    required this.controller,
    this.isObscureText = false,
    required this.header,
    this.validator,
    this.focusNode,
    // required this.validator,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool isConfidentialField;
  late bool hideData;

  @override
  void initState() {
    super.initState();
    isConfidentialField = widget.isObscureText;
    hideData = widget.isObscureText;
  }

  @override
  void didUpdateWidget(AuthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure state is correctly updated when widget rebuilds
    if (oldWidget.isObscureText != widget.isObscureText) {
      isConfidentialField = widget.isObscureText;
      hideData = widget.isObscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            widget.header,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12.sp,
              fontFamily: 'Poppins',
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48.h,
          child: TextFormField(
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14.sp,
              fontFamily: 'Poppins',
            ),
            controller: widget.controller,
            focusNode: widget.focusNode,
            validator: widget.validator,
            cursorColor: theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.transparent,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: colorScheme.onSurface.withOpacity(
                    AppTheme.borderOpacity,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: colorScheme.onSurface),
              ),
              hintText: widget.hintText,
              contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
              hintStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins',
                color: colorScheme.onSurface.withOpacity(
                  AppTheme.textTertiaryOpacity,
                ),
              ),
              suffixIcon: isConfidentialField
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          hideData = !hideData;
                        });
                      },
                      icon: Icon(
                        hideData
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: colorScheme.onSurface.withOpacity(
                          AppTheme.textTertiaryOpacity,
                        ),
                      ),
                    )
                  : null,
            ),
            obscureText: hideData,
          ),
        ),
      ],
    );
  }
}
