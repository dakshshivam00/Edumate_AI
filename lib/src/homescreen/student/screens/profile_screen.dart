import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/common/confirmation_dialog.dart';
import 'package:ailearning/src/common/user_role_service.dart';
import 'package:ailearning/src/common/global_snackbar.dart';
import 'package:ailearning/src/authentication/application/auth_provider.dart'
    as auth;
import 'package:ailearning/src/homescreen/services/course_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _profileNameKey = 'zoomate_profile_name';
  final CourseService _courseService = CourseService();
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _courseService.addListener(_onCoursesChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    _courseService.removeListener(_onCoursesChanged);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    await _courseService.ensureLoaded();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _displayName = prefs.getString(_profileNameKey);
    });
  }

  void _onCoursesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _editProfile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final controller = TextEditingController(
      text: _displayName ?? user?.displayName ?? '',
    );

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display name',
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name == null || name.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileNameKey, name);
    if (!mounted) return;
    setState(() => _displayName = name);
    GlobalScaffoldManager().showSnackbar(
      'Profile updated locally',
      type: SnackbarType.success,
    );
  }

  void _showInfo(String message) {
    GlobalScaffoldManager().showSnackbar(
      message,
      type: SnackbarType.info,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final enrolledCourses = _courseService.enrolledCount;
    final averageProgress = (_courseService.averageProgress * 100).round();
    final certificates = _courseService.completedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),

              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.secondaryColor.withOpacity(0.3),
                          AppTheme.secondaryColor.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 56.r,
                      backgroundColor: AppTheme.textPrimary.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 56.sp,
                        color: AppTheme.secondaryColor.withOpacity(0.9),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    _displayName ?? user?.displayName ?? 'User Name',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 16.sp,
                        color: AppTheme.textPrimary.withOpacity(
                          AppTheme.textSecondaryOpacity,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        user?.email ?? 'user@example.com',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppTheme.textPrimary.withOpacity(
                            AppTheme.textSecondaryOpacity,
                          ),
                          overflow: TextOverflow.ellipsis,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Stats
            Row(
              children: [
                Expanded(
	                  child: StatCard(
	                    title: 'Courses',
	                    value: enrolledCourses.toString(),
	                    icon: Icons.school,
	                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
	                  child: StatCard(
	                    title: 'Progress',
	                    value: '$averageProgress%',
	                    icon: Icons.trending_up,
	                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
	                  child: StatCard(
	                    title: 'Certificates',
	                    value: certificates.toString(),
	                    icon: Icons.workspace_premium,
	                  ),
                ),
              ],
            ),

            SizedBox(height: 32.h),

            // Menu Items
	            ProfileMenuItem(
	              icon: Icons.edit_outlined,
	              title: 'Edit Profile',
	              onTap: () => _editProfile(context),
	            ),
            SizedBox(height: 14.h),
	            ProfileMenuItem(
	              icon: Icons.notifications_outlined,
	              title: 'Notifications',
	              onTap: () => _showInfo('Notifications are local-only for now'),
	            ),
            SizedBox(height: 14.h),
	            ProfileMenuItem(
	              icon: Icons.settings_outlined,
	              title: 'Settings',
	              onTap: () => _showInfo('Settings will be stored on device'),
	            ),
            SizedBox(height: 14.h),
	            ProfileMenuItem(
	              icon: Icons.help_outline,
	              title: 'Help & Support',
	              onTap: () => _showInfo('Use global chat for app help'),
	            ),
            SizedBox(height: 14.h),
	            ProfileMenuItem(
	              icon: Icons.info_outline,
	              title: 'About',
	              onTap: () => _showInfo('Zoomate AI local frontend prototype'),
	            ),
            SizedBox(height: 32.h),

            // Logout Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final confirmed = await CustomDialogBox.showDialogBox(
                    context: context,
                    title: 'Logout',
                    content: 'Are you sure you want to logout?',
                    buttonTitle: 'Logout',
                    icon: Icons.logout,
                  );

                  if (confirmed == true) {
                    try {
                      // Sign out from Firebase first (most critical step)
                      final authProvider = auth.AuthProvider();
                      await authProvider.signOut();

                      // Clear user role (non-blocking - if it fails, logout still succeeds)
                      final userRoleService = UserRoleService();
                      await userRoleService.clearUserRole();

                      // Navigation will be handled automatically by AuthWrapper
                    } catch (e) {
                      if (context.mounted) {
                        GlobalScaffoldManager().showSnackbar(
                          'Failed to logout. Please try again.',
                          type: SnackbarType.error,
                          duration: const Duration(seconds: 3),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 18.h),
                  backgroundColor: Colors.red.withOpacity(0.15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    side: BorderSide(
                      color: Colors.red.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, size: 20.sp, color: Colors.white),
                    SizedBox(width: 10.w),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.textPrimary.withOpacity(0.12),
            AppTheme.textPrimary.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.textPrimary.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28.sp, color: AppTheme.secondaryColor),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textPrimary.withOpacity(
                AppTheme.textSecondaryOpacity,
              ),
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  State<ProfileMenuItem> createState() => _ProfileMenuItemState();
}

class _ProfileMenuItemState extends State<ProfileMenuItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: _isPressed
                ? [
                    AppTheme.textPrimary.withOpacity(0.18),
                    AppTheme.textPrimary.withOpacity(0.12),
                  ]
                : [
                    AppTheme.textPrimary.withOpacity(0.12),
                    AppTheme.textPrimary.withOpacity(0.06),
                  ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.textPrimary.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          leading: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              widget.icon,
              size: 22.sp,
              color: AppTheme.secondaryColor,
            ),
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textPrimary.withOpacity(
              AppTheme.textSecondaryOpacity,
            ),
            size: 24.sp,
          ),
        ),
      ),
    );
  }
}
