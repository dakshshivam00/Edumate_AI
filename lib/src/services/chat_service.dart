import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ailearning/src/common/user_role_service.dart';

class ChatService {
  static const String _baseUrl = 'http://35.238.224.109';
  // static const String _baseUrl =
      // 'https://welcomed-wildcat-actively.ngrok-free.app';
  static const String _accessTokenKey = 'chat_access_token';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserRoleService _userRoleService = UserRoleService();

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
      print('Chat: Failed to extract video ID from URL: $e');
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
        print('Chat: Using stored access token');
        return storedToken;
      }

      print('Chat: No stored token found, fetching from /auth endpoint...');

      // Get Firebase user
      final user = _auth.currentUser;
      if (user == null) {
        print('Chat: Firebase user is null - user not authenticated');
        return null;
      }

      // Get Firebase token
      print('Chat: Getting Firebase token...');
      final firebaseToken = await user.getIdToken(true);
      if (firebaseToken == null) {
        print('Chat: Failed to get Firebase token');
        return null;
      }
      print('Chat: Firebase token received');

      // Get user role to determine user_type
      final isStudent = await _userRoleService.isStudent();
      final userType = isStudent ? 'user' : 'teacher';
      print('Chat: User type: $userType');

      // Call /auth endpoint to get access token
      final authUrl = Uri.parse('$_baseUrl/auth?user_type=$userType');
      final authBody = jsonEncode({'firebase_token': firebaseToken});

      print('Chat: Calling /auth endpoint...');
      final authResponse = await http.post(
        authUrl,
        headers: {'Content-Type': 'application/json'},
        body: authBody,
      );

      print('Chat: /auth response status: ${authResponse.statusCode}');
      print('Chat: /auth response body: ${authResponse.body}');

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
            print(
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
            print('Chat: Access token received and stored successfully');
            return accessToken;
          } else {
            print('Chat: Failed to extract access token from /auth response');
            return null;
          }
        } catch (e) {
          print('Chat: Failed to parse /auth response: $e');
          return null;
        }
      } else {
        print(
          'Chat: /auth endpoint error: ${authResponse.statusCode} - ${authResponse.body}',
        );
        return null;
      }
    } catch (e, stackTrace) {
      print('Chat: Exception getting access token: $e');
      print('Chat: Stack trace: $stackTrace');
      return null;
    }
  }

  /// Send chat message to backend with streaming response
  /// [query] - The chat query/message
  /// Returns a stream of response chunks
  Stream<String> sendChatMessageStream({required String query}) async* {
    try {
      // Get access token (from storage or /auth endpoint)
      final accessToken = await _getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('Chat: Failed to get access token');
        yield 'error:Failed to get access token. Please try again.';
        return;
      }

      // Build URL with query parameters
      final uri = Uri.parse('$_baseUrl/chat');

      print('Chat: Preparing streaming request');
      print('Chat: Query: $query');
      print('Chat: Sending request to: $uri');

      // Create streaming request
      final request = http.Request('POST', uri);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'query': query});

      final streamedResponse = await request.send();

      print('Chat: Stream response status: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        // Handle streaming response
        await for (final chunk
            in streamedResponse.stream
                .transform(const Utf8Decoder())
                .transform(const LineSplitter())) {
          if (chunk.isNotEmpty) {
            // Handle Server-Sent Events format
            if (chunk.startsWith('data: ')) {
              final data = chunk.substring(6).trim();
              if (data.isNotEmpty && data != '[DONE]') {
                try {
                  // Try to parse as JSON
                  final jsonData = jsonDecode(data) as Map<String, dynamic>;
                  if (jsonData.containsKey('content') ||
                      jsonData.containsKey('text') ||
                      jsonData.containsKey('delta')) {
                    final content =
                        jsonData['content'] ??
                        jsonData['text'] ??
                        jsonData['delta'];
                    if (content != null) {
                      yield content.toString();
                    }
                  } else {
                    // If no content field, yield the entire chunk
                    yield data;
                  }
                } catch (e) {
                  // If not JSON, yield as plain text
                  yield data;
                }
              }
            } else if (!chunk.startsWith('event:') &&
                !chunk.startsWith('id:') &&
                chunk.trim().isNotEmpty) {
              // Handle plain text streaming
              yield chunk;
            }
          }
        }
      } else {
        // Handle error
        final errorBody = await streamedResponse.stream
            .transform(const Utf8Decoder())
            .join();
        print('Chat API Error: Status ${streamedResponse.statusCode}');
        print('Chat API Error Response: $errorBody');

        // If unauthorized (401), clear stored token
        if (streamedResponse.statusCode == 401) {
          print('Chat: Token expired or invalid, clearing stored token...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_accessTokenKey);
          print('Chat: Stored token cleared');
        }

        yield 'error:${streamedResponse.statusCode}:$errorBody';
      }
    } catch (e, stackTrace) {
      print('Chat API Exception: $e');
      print('Chat API Stack Trace: $stackTrace');
      yield 'error:${e.toString()}';
    }
  }

  /// Send chat message to backend (non-streaming, for backward compatibility)
  /// [query] - The chat query/message
  /// Returns the response data or null on error
  Future<Map<String, dynamic>?> sendChatMessage({required String query}) async {
    try {
      // Get access token (from storage or /auth endpoint)
      final accessToken = await _getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('Chat: Failed to get access token');
        return {'error': 'Failed to get access token. Please try again.'};
      }

      // Build URL with query parameters
      final uri = Uri.parse(
        '$_baseUrl/chat',
      ).replace(queryParameters: {'query': query});

      print('Chat: Preparing request');
      print('Chat: Query: $query');
      print('Chat: Sending request to: $uri');

      // Send POST request with access token in Authorization header
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      // Print response details
      print('Chat API Response Status: ${response.statusCode}');
      print('Chat API Response Headers: ${response.headers}');
      print('Chat API Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;
          print('Chat: Successfully received response');
          print('Chat: Response data: $responseData');
          return responseData;
        } catch (e) {
          print('Chat: Failed to parse JSON response: $e');
          print('Chat: Raw response body: ${response.body}');
          return {'raw_response': response.body};
        }
      } else {
        print('Chat API Error: Status ${response.statusCode}');
        print('Chat API Error Response: ${response.body}');

        // If unauthorized (401), clear stored token and try to get a new one
        if (response.statusCode == 401) {
          print('Chat: Token expired or invalid, clearing stored token...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_accessTokenKey);
          print('Chat: Stored token cleared');

          // Try to get a new token and retry the request
          final newAccessToken = await _getAccessToken();
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            print('Chat: Retrying with new access token...');
            final retryResponse = await http.post(
              uri,
              headers: {'Authorization': 'Bearer $newAccessToken'},
            );

            if (retryResponse.statusCode >= 200 &&
                retryResponse.statusCode < 300) {
              try {
                final responseData =
                    jsonDecode(retryResponse.body) as Map<String, dynamic>;
                print('Chat: Successfully received response after retry');
                return responseData;
              } catch (e) {
                print('Chat: Failed to parse retry response: $e');
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
      // Print error details
      print('Chat API Exception: $e');
      print('Chat API Stack Trace: $stackTrace');
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
    try {
      // Get access token (from storage or /auth endpoint)
      final accessToken = await _getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        print('Chat: Failed to get access token');
        yield 'error:Failed to get access token. Please try again.';
        return;
      }

      // Build URL with query parameters
      final uri = Uri.parse('$_baseUrl/chat');

      // Extract video ID and query parameters from URL
      final extractedVideoId = _extractVideoIdAndParams(videoUrl);

      print('Chat: Preparing streaming request with video URL');
      print('Chat: Query: $query');
      print('Chat: Original Video URL: $videoUrl');
      print('Chat: Extracted Video ID: $extractedVideoId');
      print('Chat: Sending request to: $uri');

      // Create streaming request with JSON body
      final request = http.Request('POST', uri);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Content-Type'] = 'application/json';

      // Encode the request body as JSON with extracted video ID
      request.body = jsonEncode({
        'query': query,
        'video_url': extractedVideoId,
      });

      final streamedResponse = await request.send();

      print('Chat: Stream response status: ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        // Handle streaming response
        await for (final chunk
            in streamedResponse.stream
                .transform(const Utf8Decoder())
                .transform(const LineSplitter())) {
          if (chunk.isNotEmpty) {
            // Handle Server-Sent Events format
            if (chunk.startsWith('data: ')) {
              final data = chunk.substring(6).trim();
              if (data.isNotEmpty && data != '[DONE]') {
                try {
                  // Try to parse as JSON
                  final jsonData = jsonDecode(data) as Map<String, dynamic>;
                  // Handle format: {"type": "response", "content": "..."}
                  if (jsonData.containsKey('content')) {
                    final content = jsonData['content'];
                    if (content != null) {
                      yield content.toString();
                    }
                  } else if (jsonData.containsKey('text') ||
                      jsonData.containsKey('delta')) {
                    final content = jsonData['text'] ?? jsonData['delta'];
                    if (content != null) {
                      yield content.toString();
                    }
                  } else {
                    // If no content field, yield the entire chunk
                    yield data;
                  }
                } catch (e) {
                  // If not JSON, yield as plain text
                  yield data;
                }
              }
            } else if (!chunk.startsWith('event:') &&
                !chunk.startsWith('id:') &&
                chunk.trim().isNotEmpty) {
              // Handle plain text streaming
              yield chunk;
            }
          }
        }
      } else {
        // Handle error
        final errorBody = await streamedResponse.stream
            .transform(const Utf8Decoder())
            .join();
        print('Chat API Error: Status ${streamedResponse.statusCode}');
        print('Chat API Error Response: $errorBody');

        // If unauthorized (401), clear stored token
        if (streamedResponse.statusCode == 401) {
          print('Chat: Token expired or invalid, clearing stored token...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_accessTokenKey);
          print('Chat: Stored token cleared');
        }

        yield 'error:${streamedResponse.statusCode}:$errorBody';
      }
    } catch (e, stackTrace) {
      print('Chat API Exception: $e');
      print('Chat API Stack Trace: $stackTrace');
      yield 'error:${e.toString()}';
    }
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
        print('Chat: Failed to get access token');
        return {'error': 'Failed to get access token. Please try again.'};
      }

      // Build URL with query parameters
      final uri = Uri.parse(
        'https://welcomed-wildcat-actively.ngrok-free.app/chat',
      );

      // Extract video ID and query parameters from URL
      final extractedVideoId = _extractVideoIdAndParams(videoUrl);

      print('Chat: Preparing request with video URL');
      print('Chat: Query: $query');
      print('Chat: Original Video URL: $videoUrl');
      print('Chat: Extracted Video ID: $extractedVideoId');
      print('Chat: Sending request to: $uri');

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

      // Print response details
      print('Chat API Response Status: ${response.statusCode}');
      print('Chat API Response Headers: ${response.headers}');
      print('Chat API Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final responseData =
              jsonDecode(response.body) as Map<String, dynamic>;
          print('Chat: Successfully received response');
          print('Chat: Response data: $responseData');
          return responseData;
        } catch (e) {
          print('Chat: Failed to parse JSON response: $e');
          print('Chat: Raw response body: ${response.body}');
          return {'raw_response': response.body};
        }
      } else {
        print('Chat API Error: Status ${response.statusCode}');
        print('Chat API Error Response: ${response.body}');

        // If unauthorized (401), clear stored token
        if (response.statusCode == 401) {
          print('Chat: Token expired or invalid, clearing stored token...');
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_accessTokenKey);
          print('Chat: Stored token cleared');
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
      // Print error details
      print('Chat API Exception: $e');
      print('Chat API Stack Trace: $stackTrace');
      return {'error': e.toString()};
    }
  }
}
