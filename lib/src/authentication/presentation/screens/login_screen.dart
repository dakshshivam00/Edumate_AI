import 'package:ailearning/src/authentication/application/auth_provider.dart';
import 'package:ailearning/src/authentication/presentation/screens/forgotten_password_screen.dart';
import 'package:ailearning/src/common/Custom_textfield.dart.dart'
    show AuthField;
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/common/global_snackbar.dart';
import 'package:ailearning/src/common/custom_elevated_button.dart';
import 'package:ailearning/src/common/gradient_container.dart';
import 'package:ailearning/src/common/user_role_service.dart';
import 'package:ailearning/src/services/fcm_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLogin = true;
  bool _isStudent = true;
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  final AuthProvider _authProvider = AuthProvider();
  final UserRoleService _userRoleService = UserRoleService();
  final FCMService _fcmService = FCMService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _toggleUserType() {
    setState(() {
      _isStudent = !_isStudent;
    });
  }

  String? _validateFields() {
    if (_isLogin) {
      if (_emailController.text.trim().isEmpty) {
        return 'Email cannot be empty';
      }
      if (_passwordController.text.isEmpty) {
        return 'Password cannot be empty';
      }
    } else {
      // Signup validation with specific error messages
      if (_nameController.text.trim().isEmpty) {
        return 'Name cannot be empty';
      }
      if (_emailController.text.trim().isEmpty) {
        return 'Email cannot be empty';
      }
      if (!_emailController.text.trim().contains('@')) {
        return 'Please enter a valid email address';
      }
      if (_passwordController.text.isEmpty) {
        return 'Password cannot be empty';
      }
      if (_passwordController.text.length < 6) {
        return 'Password must be at least 6 characters';
      }
      if (_confirmPasswordController.text.isEmpty) {
        return 'Confirm password cannot be empty';
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        return 'Passwords do not match';
      }
    }
    return null;
  }

  String _getAuthErrorMessage(dynamic error) {
    final errorMsg = _authProvider.getErrorMessage(error);

    // Map Firebase errors to user-friendly messages
    if (errorMsg.contains('user-not-found') ||
        errorMsg.contains('wrong-password') ||
        errorMsg.contains('invalid-credential')) {
      return 'Wrong email or password';
    }

    return errorMsg;
  }

  Future<void> _handleSubmit() async {
    // Validate fields manually
    final validationError = _validateFields();
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
      _isEmailLoading = true;
    });

    try {
      if (_isLogin) {
        await _authProvider.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authProvider.signUpWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
      }
      // Save user role - ensure it's saved before navigation
      final isStudentValue = _isStudent;
      final roleSaved = await _userRoleService.saveUserRole(isStudentValue);
      if (!roleSaved && mounted) {
        GlobalScaffoldManager().showSnackbar(
          'Warning: Failed to save user role. Please try again.',
          type: SnackbarType.error,
          duration: const Duration(seconds: 3),
        );
      }

      // Request FCM token and send to backend
      await _fcmService.requestNotificationPermissions();
      await _fcmService.sendFCMTokenToBackend(isStudentValue);

      // Navigation will be handled automatically by AuthWrapper
    } catch (e) {
      // Show error snackbar
      GlobalScaffoldManager().showSnackbar(
        _getAuthErrorMessage(e),
        type: SnackbarType.error,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // Ensure loading state is always reset
      if (mounted) {
        setState(() {
          _isEmailLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!mounted) return;

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final result = await _authProvider.signInWithGoogle();
      if (result == null) {
        // User canceled sign-in
        if (mounted) {
          setState(() {
            _isGoogleLoading = false;
          });
          GlobalScaffoldManager().showSnackbar(
            'Sign-in was cancelled',
            type: SnackbarType.info,
            duration: const Duration(seconds: 2),
          );
        }
        return;
      }
      // Save user role - ensure it's saved before navigation
      // Capture the current state to ensure we save the correct role
      final isStudentValue = _isStudent;
      final roleSaved = await _userRoleService.saveUserRole(isStudentValue);
      if (!roleSaved && mounted) {
        GlobalScaffoldManager().showSnackbar(
          'Warning: Failed to save user role. Please try again.',
          type: SnackbarType.error,
          duration: const Duration(seconds: 3),
        );
      }

      // Request FCM token and send to backend
      await _fcmService.requestNotificationPermissions();
      await _fcmService.sendFCMTokenToBackend(isStudentValue);

      // Navigation will be handled automatically by AuthWrapper
    } catch (e) {
      // Ensure loading state is reset before showing error
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
        GlobalScaffoldManager().showSnackbar(
          _authProvider.getErrorMessage(e),
          type: SnackbarType.error,
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      // Ensure loading state is always reset
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),

                // Title
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  _isLogin ? 'Sign in to continue' : 'Sign up to get started',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: colorScheme.onSurface.withOpacity(
                      AppTheme.textSecondaryOpacity,
                    ),
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40.h),

                // User Type Toggle (Student/Teacher)
                Container(
                  padding: EdgeInsets.all(4.sp),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(
                      AppTheme.containerOpacity,
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: colorScheme.onSurface.withOpacity(
                        AppTheme.borderOpacity,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isStudent) _toggleUserType();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: _isStudent
                                  ? colorScheme.onSurface.withOpacity(
                                      AppTheme.selectedContainerOpacity,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Text(
                              'Student',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isStudent) _toggleUserType();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: !_isStudent
                                  ? colorScheme.onSurface.withOpacity(
                                      AppTheme.selectedContainerOpacity,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Text(
                              'Teacher',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),

                // Form Fields
                if (!_isLogin)
                  AuthField(
                    header: 'Full Name',
                    hintText: 'Enter your name',
                    controller: _nameController,
                  ),
                SizedBox(height: _isLogin ? 0 : 20.h),

                AuthField(
                  header: 'Email',
                  hintText: 'Enter your email',
                  controller: _emailController,
                ),
                SizedBox(height: 20.h),

                AuthField(
                  header: 'Password',
                  hintText: 'Enter your password',
                  controller: _passwordController,
                  isObscureText: true,
                ),
                SizedBox(height: _isLogin ? 0 : 20.h),

                if (!_isLogin)
                  AuthField(
                    header: 'Confirm Password',
                    hintText: 'Confirm your password',
                    controller: _confirmPasswordController,
                    isObscureText: true,
                  ),

                // Forgot Password (Login only)
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ForgottenPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: colorScheme.onSurface.withOpacity(0.8),
                          fontFamily: 'Poppins',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                if (!_isLogin) SizedBox(height: 24.h),

                // Submit Button
                CustomElevatedButton(
                  title: _isLogin ? 'Login' : 'Sign Up',
                  onPressed: _isEmailLoading ? null : _handleSubmit,
                  height: 48.h,
                ),
                SizedBox(height: 24.h),
                CustomElevatedButton(
                  title: _isLogin
                      ? 'Sign in with Google'
                      : 'Sign up with Google',
                  onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                  height: 48.h,
                ),
                SizedBox(height: 24.h),

                // Toggle between Login and Signup
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: colorScheme.onSurface.withOpacity(
                          AppTheme.textSecondaryOpacity,
                        ),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    GestureDetector(
                      onTap: _toggleAuthMode,
                      child: Text(
                        _isLogin ? 'Sign Up' : 'Login',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          fontFamily: 'Poppins',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_isLogin) SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
