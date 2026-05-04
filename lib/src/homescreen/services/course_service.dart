import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ailearning/src/common/user_role_service.dart';

/// Service to manage enrolled courses across the app
class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  static const String _baseUrl = 'http://35.238.224.109';
  static const String _accessTokenKey = 'course_access_token';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRoleService _userRoleService = UserRoleService();

  /// Get access token from /auth endpoint or use stored token
  Future<String?> _getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(_accessTokenKey);
      if (storedToken != null && storedToken.isNotEmpty) {
        print('Course: Using stored access token');
        return storedToken;
      }

      print('Course: No stored token found, fetching from /auth endpoint...');

      final user = _auth.currentUser;
      if (user == null) {
        print('Course: Firebase user is null');
        return null;
      }

      final firebaseToken = await user.getIdToken(true);
      if (firebaseToken == null) {
        print('Course: Failed to get Firebase token');
        return null;
      }

      final isStudent = await _userRoleService.isStudent();
      final userType = isStudent ? 'user' : 'teacher';

      final authUrl = Uri.parse('$_baseUrl/auth?user_type=$userType');
      final authBody = jsonEncode({'firebase_token': firebaseToken});

      print('Course: Calling /auth endpoint...');
      final authResponse = await http.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: authBody,
      );

      print('Course: /auth response status: ${authResponse.statusCode}');
      print('Course: /auth response body: ${authResponse.body}');

      if (authResponse.statusCode >= 200 && authResponse.statusCode < 300) {
        try {
          final authData =
              jsonDecode(authResponse.body) as Map<String, dynamic>;

          String? accessToken;
          if (authData.containsKey('access_token')) {
            accessToken = authData['access_token'] as String;
          } else if (authData.containsKey('token')) {
            accessToken = authData['token'] as String;
          } else if (authData.containsKey('accessToken')) {
            accessToken = authData['accessToken'] as String;
          } else {
            final firstValue = authData.values.first;
            if (firstValue is String) {
              accessToken = firstValue;
            }
          }

          if (accessToken != null && accessToken.isNotEmpty) {
            await prefs.setString(_accessTokenKey, accessToken);
            print('Course: Access token received and stored');
            return accessToken;
          }
          return null;
        } catch (e) {
          print('Course: Failed to parse /auth response: $e');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Course: Exception getting access token: $e');
      return null;
    }
  }

  /// Create course via API
  Future<Map<String, dynamic>?> createCourse({
    required String title,
    required String description,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('Course: Failed to get access token');
        return {'error': 'Failed to get access token'};
      }

      // Build URL with query parameters
      final uri = Uri.parse('$_baseUrl/create-course').replace(
        queryParameters: {
          'course_title': title,
          'course_description': description,
        },
      );

      print('Course: Creating course via API');
      print('Course: Title: $title');
      print('Course: Description: $description');
      print('Course: URL: $uri');

      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      // Print response details
      print('Course API Response Status: ${response.statusCode}');
      print('Course API Response Headers: ${response.headers}');
      print('Course API Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;
          print('Course: Successfully created course');
          print('Course: Response data: $responseData');
          return responseData;
        } catch (e) {
          print('Course: Failed to parse JSON response: $e');
          print('Course: Raw response body: ${response.body}');
          return {'raw_response': response.body};
        }
      } else {
        print('Course API Error: Status ${response.statusCode}');
        print('Course API Error Response: ${response.body}');

        if (response.statusCode == 401) {
          print('Course: Token expired, clearing stored token...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_accessTokenKey);
        }

        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return errorData;
        } catch (e) {
          return {'error': response.body, 'status_code': response.statusCode};
        }
      }
    } catch (e, stackTrace) {
      print('Course API Exception: $e');
      print('Course API Stack Trace: $stackTrace');
      return {'error': e.toString()};
    }
  }

  final List<Map<String, dynamic>> _enrolledCourses = [
    {
      'title': 'Flutter Development Masterclass',
      'instructor': 'John Doe',
      'progress': 0.65,
      'thumbnail': 'https://picsum.photos/400/300?random=1',
      'videoUrls': [
        'https://www.youtube.com/watch?v=1ukSR1GRtMU',
        'https://www.youtube.com/watch?v=GIIQ1FZgZQI',
        'https://www.youtube.com/watch?v=qeGFV5LELpk',
        'https://www.youtube.com/watch?v=kJQP7kiw5Fk',
      ],
    },
    {
      'title': 'Machine Learning Fundamentals',
      'instructor': 'Jane Smith',
      'progress': 0.30,
      'thumbnail': 'https://picsum.photos/400/300?random=2',
      'videoUrls': [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/watch?v=jNQXAC9IVRw',
        'https://www.youtube.com/watch?v=9bZkp7q19f0',
      ],
    },
    {
      'title': 'Web Development Bootcamp',
      'instructor': 'Mike Johnson',
      'progress': 0.85,
      'thumbnail': 'https://picsum.photos/400/300?random=3',
      'videoUrls': [
        'https://www.youtube.com/watch?v=kJQP7kiw5Fk',
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/watch?v=jNQXAC9IVRw',
      ],
    },
  ];

  List<Map<String, dynamic>> get enrolledCourses =>
      List.unmodifiable(_enrolledCourses);

  /// Add a course to enrolled courses after purchase
  void addEnrolledCourse({
    required String title,
    required String instructor,
    required String thumbnail,
    required List<String> videoUrls,
    double progress = 0.0,
  }) {
    // Check if course already exists
    final exists = _enrolledCourses.any((course) => course['title'] == title);
    if (!exists) {
      _enrolledCourses.add({
        'title': title,
        'instructor': instructor,
        'progress': progress,
        'thumbnail': thumbnail,
        'videoUrls': videoUrls,
      });
    }
  }

  /// Check if a course is already enrolled
  bool isEnrolled(String courseTitle) {
    return _enrolledCourses.any((course) => course['title'] == courseTitle);
  }

  // Teacher courses management
  final List<Map<String, dynamic>> _teacherCourses = [
    {
      'title': 'Flutter Development Masterclass',
      'description': 'Learn Flutter development from scratch',
      'instructor': 'John Doe',
      'thumbnail': 'https://picsum.photos/400/300?random=4',
      'videoUrls': [
        'https://www.youtube.com/watch?v=1ukSR1GRtMU',
        'https://www.youtube.com/watch?v=GIIQ1FZgZQI',
      ],
    },
    {
      'title': 'Machine Learning Fundamentals',
      'description': 'Introduction to machine learning concepts',
      'instructor': 'Jane Smith',
      'thumbnail': 'https://picsum.photos/400/300?random=5',
      'videoUrls': [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://www.youtube.com/watch?v=jNQXAC9IVRw',
      ],
    },
  ];

  List<Map<String, dynamic>> get teacherCourses =>
      List.unmodifiable(_teacherCourses);

  /// Add a new course for teachers
  void addTeacherCourse({
    required String title,
    required String description,
    String? instructor,
    String? thumbnail,
    List<String> videoUrls = const [],
  }) {
    _teacherCourses.add({
      'title': title,
      'description': description,
      'instructor': instructor ?? '',
      'thumbnail': thumbnail ?? '',
      'videoUrls': videoUrls,
    });
  }

  /// Add a video to an existing teacher course
  void addVideoToCourse({
    required String courseTitle,
    required String videoTitle,
    required String videoUrl,
  }) {
    final courseIndex = _teacherCourses.indexWhere(
      (course) => course['title'] == courseTitle,
    );
    if (courseIndex != -1) {
      final videoUrls =
          _teacherCourses[courseIndex]['videoUrls'] as List<dynamic>;
      // Convert existing string URLs to map format if needed
      final updatedVideos = videoUrls.asMap().entries.map((entry) {
        final index = entry.key;
        final video = entry.value;
        if (video is String) {
          return {'title': 'Video ${index + 1}', 'url': video};
        }
        return video;
      }).toList();
      updatedVideos.add({'title': videoTitle, 'url': videoUrl});
      _teacherCourses[courseIndex]['videoUrls'] = updatedVideos;
    }
  }

  /// Get course by title
  Map<String, dynamic>? getTeacherCourse(String courseTitle) {
    try {
      return _teacherCourses.firstWhere(
        (course) => course['title'] == courseTitle,
      );
    } catch (e) {
      return null;
    }
  }
}
