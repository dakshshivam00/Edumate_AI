import 'package:shared_preferences/shared_preferences.dart';

class UserRoleService {
  static const String _roleKey = 'user_role';
  static const String _studentRole = 'student';
  static const String _teacherRole = 'teacher';

  /// Save user role (student or teacher)
  /// Returns true if successful, false if failed
  Future<bool> saveUserRole(bool isStudent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roleKey, isStudent ? _studentRole : _teacherRole);
      return true;
    } catch (e) {
      // Non-blocking: if SharedPreferences fails, return false
      return false;
    }
  }

  /// Get user role
  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_roleKey);
    } catch (e) {
      // If SharedPreferences fails, return null (default to student)
      return null;
    }
  }

  /// Check if user is student
  Future<bool> isStudent() async {
    final role = await getUserRole();
    return role == _studentRole || role == null; // Default to student
  }

  /// Check if user is teacher
  Future<bool> isTeacher() async {
    final role = await getUserRole();
    return role == _teacherRole;
  }

  /// Clear user role (on logout)
  /// Returns true if successful, false if failed (non-blocking)
  Future<bool> clearUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_roleKey);
      return true;
    } catch (e) {
      // Non-blocking: if SharedPreferences fails, still return false
      // This allows logout to proceed even if clearing role fails
      return false;
    }
  }
}
