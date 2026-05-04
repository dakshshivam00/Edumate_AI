import 'package:ailearning/src/authentication/application/auth_provider.dart';
import 'package:ailearning/src/common/Custom_textfield.dart.dart'
    show AuthField;
import 'package:ailearning/src/common/global_snackbar.dart';
import 'package:ailearning/src/common/custom_elevated_button.dart';
import 'package:ailearning/src/common/gradient_container.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ForgottenPasswordScreen extends StatefulWidget {
  const ForgottenPasswordScreen({super.key});

  @override
  State<ForgottenPasswordScreen> createState() =>
      _ForgottenPasswordScreenState();
}

class _ForgottenPasswordScreenState extends State<ForgottenPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _wasEmailSentSuccessfully = false;
  bool _isLoading = false;
  final AuthProvider _authProvider = AuthProvider();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email cannot be empty';
    }
    if (!email.trim().contains('@')) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  Future<void> _handleSendPasswordReset() async {
    final validationError = _validateEmail(_emailController.text.trim());
    if (validationError != null) {
      GlobalScaffoldManager().showSnackbar(
        validationError,
        type: SnackbarType.error,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Send password reset email directly
      // The checkUserExists function already handles validation
      // and Firebase will throw user-not-found error if user doesn't exist
      final email = _emailController.text.trim();

      // Try to send password reset email
      // Firebase will throw error if user doesn't exist
      await _authProvider.sendPasswordResetEmail(email);

      if (mounted) {
        setState(() {
          _wasEmailSentSuccessfully = true;
        });
        GlobalScaffoldManager().showSnackbar(
          'Password reset email sent successfully',
          type: SnackbarType.success,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Handle errors from sending password reset email
      final errorMessage = _authProvider.getErrorMessage(e);

      // Check if it's a user-not-found error
      if (e is FirebaseAuthException && e.code == 'user-not-found') {
        if (mounted) {
          GlobalScaffoldManager().showSnackbar(
            'User not found',
            type: SnackbarType.error,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        // Show other error messages
        if (mounted) {
          GlobalScaffoldManager().showSnackbar(
            errorMessage,
            type: SnackbarType.error,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleBack() {
    Navigator.pop(context);
    if (_wasEmailSentSuccessfully) {
      setState(() {
        _wasEmailSentSuccessfully = false;
        _emailController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: GradientContainer(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: _wasEmailSentSuccessfully ? 330.h : 260.h),
                Text(
                  _wasEmailSentSuccessfully
                      ? 'Email has been sent, \ncheck your mail'
                      : 'Can\'t remember your password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: colorScheme.onSurface,
                  ),
                ),
                if (!_wasEmailSentSuccessfully) ...[
                  SizedBox(height: 25.h),
                  AuthField(
                    hintText: 'Enter your email',
                    controller: _emailController,
                    header: 'Email',
                  ),
                ],
                SizedBox(height: 25.h),
                CustomElevatedButton(
                  title: _wasEmailSentSuccessfully
                      ? 'Back to login'
                      : 'Reset Password',
                  onPressed: _isLoading
                      ? null
                      : (_wasEmailSentSuccessfully
                            ? _handleBack
                            : _handleSendPasswordReset),
                  height: 48.h,
                ),
                SizedBox(height: 190.h),
                if (!_wasEmailSentSuccessfully)
                  InkWell(
                    onTap: _handleBack,
                    splashColor: colorScheme.onSurface.withOpacity(0.2),
                    hoverColor: colorScheme.onSurface.withOpacity(0.2),
                    highlightColor: colorScheme.onSurface.withOpacity(0.2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_arrow_left,
                          size: 35.sp,
                          color: colorScheme.onSurface,
                        ),
                        Text(
                          'Back to login',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
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
