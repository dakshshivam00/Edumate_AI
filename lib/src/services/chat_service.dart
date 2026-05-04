import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ailearning/src/common/user_role_service.dart';

class ChatService {
  static const String _baseUrl = 'http://35.238.224.109';
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _geminiModel = 'gemini-2.5-flash';
  static const String _geminiApiKey = 'AIzaSyCJERlnWUjhJVmoWyzt3XVLhdRnOxtym8o';
  // static const String _baseUrl =
      // 'https://welcomed-wildcat-actively.ngrok-free.app';
  static const String _accessTokenKey = 'chat_access_token';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRoleService _userRoleService = UserRoleService();

  Future<String?> _generateWithGemini(String prompt) async {
    try {
      final uri = Uri.parse(
        '$_geminiBaseUrl/models/$_geminiModel:generateContent',
      );
      debugPrint('Gemini: Request URL: $uri');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _geminiApiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );

      debugPrint('Gemini: Status: ${response.statusCode}');
      debugPrint('Gemini: Raw response: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = payload['candidates'];
      if (candidates is! List || candidates.isEmpty) return null;

      final first = candidates.first;
      if (first is! Map) return null;
      final content = first['content'];
      if (content is! Map) return null;
      final parts = content['parts'];
      if (parts is! List) return null;

      final buffer = StringBuffer();
      for (final part in parts) {
        if (part is Map && part['text'] != null) {
          buffer.write(part['text'].toString());
        }
      }
      final text = buffer.toString().trim();
      debugPrint('Gemini: Parsed text length: ${text.length}');
      return text.isEmpty ? null : text;
    } catch (e, stackTrace) {
      debugPrint('Gemini: Exception: $e');
      debugPrint('Gemini: Stack trace: $stackTrace');
      return null;
    }
  }

  /// Extract video ID and query parameters from YouTube URL
  /// Returns format: "videoId?queryParams" or just "videoId" if no query params
  String _extractVideoIdAndParams(String videoUrl) {
    try {
      final uri = Uri.parse(videoUrl);
      String? videoId;
      String queryParams = '';

      // Handle youtu.be format: https://youtu.be/VIDEO_ID?si=...
      if (uri.host.contains('youtu.be')) {
        if (uri.pathSegments.isNotEmpty) {
          videoId = uri.pathSegments[0];
        }
        // Get all query parameters
        if (uri.queryParameters.isNotEmpty) {
          queryParams = uri.queryParameters.entries
              .map((e) => '${e.key}=${e.value}')
              .join('&');
        }
      }
      // Handle youtube.com format: https://www.youtube.com/watch?v=VIDEO_ID&si=...
      else if (uri.host.contains('youtube.com')) {
        videoId = uri.queryParameters['v'];
        // Get all query parameters except 'v'
        final otherParams = uri.queryParameters.entries
            .where((e) => e.key != 'v')
            .map((e) => '${e.key}=${e.value}')
            .join('&');
        if (otherParams.isNotEmpty) {
          queryParams = otherParams;
        }
      }

      if (videoId == null || videoId.isEmpty) {
        // If we can't extract, return original URL
        return videoUrl;
      }

      // Return format: "videoId?queryParams" or just "videoId"
      return queryParams.isNotEmpty ? '$videoId?$queryParams' : videoId;
    } catch (e) {
      debugPrint('Chat: Failed to extract video ID from URL: $e');
      // Return original URL if extraction fails
      return videoUrl;
    }
  }

  /// Get access token from /auth endpoint or use stored token
  /// Returns the access token or null on error
  Future<String?> _getAccessToken() async {
    try {
      // Check if we have a stored access token
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(_accessTokenKey);
      if (storedToken != null && storedToken.isNotEmpty) {
        debugPrint('Chat: Using stored access token');
        return storedToken;
      }

      debugPrint('Chat: No stored token found, fetching from /auth endpoint...');

      // Get Firebase user
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('Chat: Firebase user is null - user not authenticated');
        return null;
      }

      // Get Firebase token
      debugPrint('Chat: Getting Firebase token...');
      final firebaseToken = await user.getIdToken(true);
      if (firebaseToken == null) {
        debugPrint('Chat: Failed to get Firebase token');
        return null;
      }
      debugPrint('Chat: Firebase token received');

      // Get user role to determine user_type
      final isStudent = await _userRoleService.isStudent();
      final userType = isStudent ? 'user' : 'teacher';
      debugPrint('Chat: User type: $userType');

      // Call /auth endpoint to get access token
      final authUrl = Uri.parse('$_baseUrl/auth?user_type=$userType');
      final authBody = jsonEncode({'firebase_token': firebaseToken});

      debugPrint('Chat: Calling /auth endpoint...');
      final authResponse = await http.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: authBody,
      );

      debugPrint('Chat: /auth response status: ${authResponse.statusCode}');
      debugPrint('Chat: /auth response body: ${authResponse.body}');

      if (authResponse.statusCode >= 200 && authResponse.statusCode < 300) {
        try {
          final authData =
              jsonDecode(authResponse.body) as Map<String, dynamic>;

          // Extract access token from response
          String? accessToken;
          if (authData.containsKey('access_token')) {
            accessToken = authData['access_token'] as String;
          } else if (authData.containsKey('token')) {
            accessToken = authData['token'] as String;
          } else if (authData.containsKey('accessToken')) {
            accessToken = authData['accessToken'] as String;
          } else {
            // Try to get first string value if key is unknown
            debugPrint(
              'Chat: Warning - access token key not found, trying to extract from response',
            );
            final firstValue = authData.values.first;
            if (firstValue is String) {
              accessToken = firstValue;
            }
          }

          if (accessToken != null && accessToken.isNotEmpty) {
            // Store the access token for future use
            await prefs.setString(_accessTokenKey, accessToken);
            debugPrint('Chat: Access token received and stored successfully');
            return accessToken;
          } else {
            debugPrint('Chat: Failed to extract access token from /auth response');
            return null;
          }
        } catch (e) {
          debugPrint('Chat: Failed to parse /auth response: $e');
          return null;
        }
      } else {
        debugPrint(
          'Chat: /auth endpoint error: ${authResponse.statusCode} - ${authResponse.body}',
        );
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Chat: Exception getting access token: $e');
      debugPrint('Chat: Stack trace: $stackTrace');
      return null;
    }
  }

  /// Send chat message to backend with streaming response
  /// [query] - The chat query/message
  /// Returns a stream of response chunks
  Stream<String> sendChatMessageStream({required String query}) async* {
    final text = await _generateWithGemini(query);
    if (text == null || text.isEmpty) {
      yield 'error:Server error. Please try again.';
      return;
    }
    yield text;
  }

  /// Send chat message to backend (non-streaming, for backward compatibility)
  /// [query] - The chat query/message
  /// Returns the response data or null on error
  Future<Map<String, dynamic>?> sendChatMessage({required String query}) async {
    try {
      // Get access token (from storage or /auth endpoint)
      final accessToken = await _getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('Chat: Failed to get access token');
        return {'error': 'Failed to get access token. Please try again.'};
      }

      // Build URL with query parameters
      final uri = Uri.parse(
        '$_baseUrl/chat',
      ).replace(queryParameters: {'query': query});

      debugPrint('Chat: Preparing request');
      debugPrint('Chat: Query: $query');
      debugPrint('Chat: Sending request to: $uri');

      // Send POST request with access token in Authorization header
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      // debugPrint response details
      debugPrint('Chat API Response Status: ${response.statusCode}');
      debugPrint('Chat API Response Headers: ${response.headers}');
      debugPrint('Chat API Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint('Chat: Successfully received response');
          debugPrint('Chat: Response data: $responseData');
          return responseData;
        } catch (e) {
          debugPrint('Chat: Failed to parse JSON response: $e');
          debugPrint('Chat: Raw response body: ${response.body}');
          return {'raw_response': response.body};
        }
      } else {
        debugPrint('Chat API Error: Status ${response.statusCode}');
        debugPrint('Chat API Error Response: ${response.body}');

        // If unauthorized (401), clear stored token and try to get a new one
        if (response.statusCode == 401) {
          debugPrint('Chat: Token expired or invalid, clearing stored token...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_accessTokenKey);
          debugPrint('Chat: Stored token cleared');

          // Try to get a new token and retry the request
          final newAccessToken = await _getAccessToken();
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            debugPrint('Chat: Retrying with new access token...');
            final retryResponse = await http.post(
              uri,
              headers: {'Authorization': 'Bearer $newAccessToken'},
            );

            if (retryResponse.statusCode >= 200 &&
                retryResponse.statusCode < 300) {
              try {
                final responseData =
                    jsonDecode(retryResponse.body) as Map<String, dynamic>;
                debugPrint('Chat: Successfully received response after retry');
                return responseData;
              } catch (e) {
                debugPrint('Chat: Failed to parse retry response: $e');
                return {'raw_response': retryResponse.body};
              }
            }
          }
        }

        // Try to parse error response
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return errorData;
        } catch (e) {
          return {'error': response.body, 'status_code': response.statusCode};
        }
      }
    } catch (e, stackTrace) {
      // debugPrint error details
      debugPrint('Chat API Exception: $e');
      debugPrint('Chat API Stack Trace: $stackTrace');
      return {'error': e.toString()};
    }
  }

  /// Send chat message with video URL to backend with streaming response
  /// [query] - The chat query/message
  /// [videoUrl] - The video URL to include in the request
  /// Returns a stream of response chunks
  Stream<String> sendChatMessageWithVideoStream({
    required String query,
    required String videoUrl,
  }) async* {
    final extractedVideoId = _extractVideoIdAndParams(videoUrl);
    final prompt =
        'Use this YouTube video context: $extractedVideoId\n\nUser question: $query';
    final text = await _generateWithGemini(prompt);
    if (text == null || text.isEmpty) {
      yield 'error:Server error. Please try again.';
      return;
    }
    yield text;
  }

  /// Send chat message with video URL to backend
  /// [query] - The chat query/message
  /// [videoUrl] - The video URL to include in the request
  /// Returns the response data or null on error
  Future<Map<String, dynamic>?> sendChatMessageWithVideo({
    required String query,
    required String videoUrl,
  }) async {
    try {
      // Get access token (from storage or /auth endpoint)
      final accessToken = await _getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('Chat: Failed to get access token');
        return {'error': 'Failed to get access token. Please try again.'};
      }

      // Build URL with query parameters
      final uri = Uri.parse(
        'https://welcomed-wildcat-actively.ngrok-free.app/chat',
      );

      // Extract video ID and query parameters from URL
      final extractedVideoId = _extractVideoIdAndParams(videoUrl);

      debugPrint('Chat: Preparing request with video URL');
      debugPrint('Chat: Query: $query');
      debugPrint('Chat: Original Video URL: $videoUrl');
      debugPrint('Chat: Extracted Video ID: $extractedVideoId');
      debugPrint('Chat: Sending request to: $uri');

      // Send POST request with access token in Authorization header
      final requestBody = jsonEncode({
        'query': query,
        'video_url': extractedVideoId,
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      // debugPrint response details
      debugPrint('Chat API Response Status: ${response.statusCode}');
      debugPrint('Chat API Response Headers: ${response.headers}');
      debugPrint('Chat API Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint('Chat: Successfully received response');
          debugPrint('Chat: Response data: $responseData');
          return responseData;
        } catch (e) {
          debugPrint('Chat: Failed to parse JSON response: $e');
          debugPrint('Chat: Raw response body: ${response.body}');
          return {'raw_response': response.body};
        }
      } else {
        debugPrint('Chat API Error: Status ${response.statusCode}');
        debugPrint('Chat API Error Response: ${response.body}');

        // If unauthorized (401), clear stored token
        if (response.statusCode == 401) {
          debugPrint('Chat: Token expired or invalid, clearing stored token...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_accessTokenKey);
          debugPrint('Chat: Stored token cleared');
        }

        // Try to parse error response
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          return errorData;
        } catch (e) {
          return {'error': response.body, 'status_code': response.statusCode};
        }
      }
    } catch (e, stackTrace) {
      // debugPrint error details
      debugPrint('Chat API Exception: $e');
      debugPrint('Chat API Stack Trace: $stackTrace');
      return {'error': e.toString()};
    }
  }
}
