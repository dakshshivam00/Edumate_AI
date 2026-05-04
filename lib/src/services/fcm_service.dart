import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class FCMService {
  static const String _baseUrl = 'http://35.238.224.109';
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Request FCM token and send to backend
  /// [isStudent] determines if user_type is "user" (student) or "teacher"
  Future<bool> sendFCMTokenToBackend(bool isStudent) async {
    try {
      // Request FCM token
      print('FCM: Requesting FCM token from Firebase...');
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) {
        print('FCM: Failed to get FCM token - token is null');
        return false;
      }

      // Print received FCM token
      print('FCM: Successfully received FCM token from Firebase');
      print('FCM Token: $fcmToken');

      // Get Firebase auth token
      final user = _auth.currentUser;
      if (user == null) {
        print('FCM: Firebase user is null');
        return false;
      }

      print('FCM: Getting Firebase auth token...');
      final firebaseToken = await user.getIdToken();
      if (firebaseToken == null) {
        print('FCM: Failed to get Firebase auth token');
        return false;
      }
      print('FCM: Firebase auth token received');

      // Get timezone
      final timezone = DateTime.now().timeZoneName;
      print('FCM: Device timezone: $timezone');

      // Determine user_type based on isStudent toggle
      final userType = isStudent ? 'user' : 'teacher';
      print('FCM: User type: $userType');

      // Prepare request body
      final body = {
        'firebase_token': firebaseToken,
        'device_data': {'fcm_token': fcmToken, 'timezone': timezone},
      };
      print('FCM: Preparing request body with FCM token and device data');

      // Send to backend
      final url = Uri.parse('$_baseUrl/auth?user_type=$userType');
      print('FCM: Sending FCM token to backend: $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      // Print response details
      print('FCM Token API Response Status: ${response.statusCode}');
      print('FCM Token API Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('FCM Token sent successfully');
        return true;
      } else {
        print(
          'FCM Token API Error: Status ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e, stackTrace) {
      // Print error details
      print('FCM Token API Exception: $e');
      print('FCM Token API Stack Trace: $stackTrace');
      // Return false on error, but don't throw to avoid blocking auth flow
      return false;
    }
  }

  /// Request notification permissions (optional, but recommended)
  Future<bool> requestNotificationPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }
}
