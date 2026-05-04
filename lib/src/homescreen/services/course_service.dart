import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-first course store used while backend course APIs are unavailable.
class CourseService extends ChangeNotifier {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  static const String _coursesKey = 'edumate_ai_courses_v1';
  static const String _enrolledCourseIdsKey = 'edumate_ai_enrolled_course_ids_v1';
  static const String _progressKey = 'edumate_ai_course_progress_v1';

  final List<Map<String, dynamic>> _courses = [];
  final Set<String> _enrolledCourseIds = {};
  final Map<String, double> _progressByCourseId = {};

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final savedCourses = prefs.getString(_coursesKey);

    _courses
      ..clear()
      ..addAll(
        savedCourses == null
            ? _cloneCourses(_defaultCourses)
            : _decodeCourseList(savedCourses),
      );

    _enrolledCourseIds
      ..clear()
      ..addAll(
        prefs.getStringList(_enrolledCourseIdsKey) ??
            const ['java-dsa', 'flutter-development', 'adobe-premiere-pro'],
      );

    _progressByCourseId
      ..clear()
      ..addAll(_decodeProgressMap(prefs.getString(_progressKey)));

    _progressByCourseId.putIfAbsent('java-dsa', () => 0.25);
    _progressByCourseId.putIfAbsent('flutter-development', () => 0.30);
    _progressByCourseId.putIfAbsent('adobe-premiere-pro', () => 0.65);
    _applyProgressToCourses();

    _loaded = true;
    await _save();
    notifyListeners();
  }

  List<Map<String, dynamic>> get marketplaceCourses =>
      _cloneCourses(_courses);

  List<Map<String, dynamic>> get teacherCourses => _cloneCourses(_courses);

  List<Map<String, dynamic>> get enrolledCourses => _cloneCourses(
    _courses.where((course) => _enrolledCourseIds.contains(course['id'])),
  );

  int get enrolledCount => _enrolledCourseIds.length;

  int get completedCount => enrolledCourses
      .where((course) => ((course['progress'] as num?)?.toDouble() ?? 0) >= 1)
      .length;

  double get averageProgress {
    final courses = enrolledCourses;
    if (courses.isEmpty) return 0;
    final total = courses.fold<double>(
      0,
      (sum, course) => sum + ((course['progress'] as num?)?.toDouble() ?? 0),
    );
    return total / courses.length;
  }

  int get totalLessons => _courses.fold<int>(
    0,
    (sum, course) => sum + ((course['videoUrls'] as List?)?.length ?? 0),
  );

  Future<Map<String, dynamic>> createCourse({
    required String title,
    required String description,
    String? instructor,
  }) async {
    await ensureLoaded();

    final id = _uniqueIdForTitle(title);
    final course = {
      'id': id,
      'title': title,
      'description': description,
      'instructor': instructor?.trim().isNotEmpty == true
          ? instructor!.trim()
          : 'Edumate AI Teacher',
      'price': 'Free',
      'rating': 0.0,
      'students': 0,
      'category': 'Teacher Course',
      'progress': 0.0,
      'thumbnail': '',
      'videoUrls': <Map<String, String>>[],
    };

    // Keep newly created courses at the top of teacher/student lists.
    _courses.insert(0, course);
    await _saveAndNotify();
    return {'success': true, 'course': _cloneCourse(course)};
  }

  Future<void> addTeacherCourse({
    required String title,
    required String description,
    String? instructor,
    String? thumbnail,
    List<String> videoUrls = const [],
  }) async {
    await ensureLoaded();

    final existing = _findCourseByTitle(title);
    if (existing != null) return;

    final response = await createCourse(
      title: title,
      description: description,
      instructor: instructor,
    );
    final course = response['course'] as Map<String, dynamic>;
    if (thumbnail != null && thumbnail.isNotEmpty) {
      _findCourseById(course['id'] as String)?['thumbnail'] = thumbnail;
    }
    // Preserve incoming lesson order when insert(0) is used in addVideoToCourse.
    for (final url in videoUrls.reversed) {
      await addVideoToCourse(
        courseTitle: title,
        videoTitle: 'Lesson ${videoUrls.indexOf(url) + 1}',
        videoUrl: url,
      );
    }
  }

  Future<bool> addVideoToCourse({
    required String courseTitle,
    required String videoTitle,
    required String videoUrl,
  }) async {
    await ensureLoaded();

    final course = _findCourseByTitle(courseTitle);
    if (course == null) return false;

    final videos = _videoListFor(course);
    // Keep newly added lessons visible first in course detail/cards.
    videos.insert(0, {'title': videoTitle, 'url': videoUrl});
    course['videoUrls'] = videos;
    await _saveAndNotify();
    return true;
  }

  Future<bool> deleteVideoFromCourse({
    required String courseTitle,
    required int index,
  }) async {
    await ensureLoaded();

    final course = _findCourseByTitle(courseTitle);
    if (course == null) return false;

    final videos = _videoListFor(course);
    if (index < 0 || index >= videos.length) return false;

    videos.removeAt(index);
    course['videoUrls'] = videos;
    await _saveAndNotify();
    return true;
  }

  Future<bool> enrollCourseByTitle(String courseTitle) async {
    await ensureLoaded();

    final course = _findCourseByTitle(courseTitle);
    if (course == null) return false;

    _enrolledCourseIds.add(course['id'] as String);
    _progressByCourseId.putIfAbsent(course['id'] as String, () => 0);
    _applyProgressToCourses();
    await _saveAndNotify();
    return true;
  }

  bool isEnrolled(String courseTitle) {
    final course = _findCourseByTitle(courseTitle);
    return course != null && _enrolledCourseIds.contains(course['id']);
  }

  double getCourseProgress(String courseTitle) {
    final course = _findCourseByTitle(courseTitle);
    if (course == null) return 0;
    return _progressByCourseId[course['id']] ??
        ((course['progress'] as num?)?.toDouble() ?? 0);
  }

  Future<void> updateProgress(String courseTitle, double progress) async {
    await ensureLoaded();

    final course = _findCourseByTitle(courseTitle);
    if (course == null) return;

    final clamped = progress.clamp(0.0, 1.0).toDouble();
    final current = getCourseProgress(courseTitle);
    if (clamped < current) return;

    _progressByCourseId[course['id'] as String] = clamped;
    course['progress'] = clamped;
    await _saveAndNotify();
  }

  Future<void> markLessonWatched({
    required String courseTitle,
    required int lessonIndex,
    required int lessonCount,
  }) async {
    if (lessonCount <= 0) return;
    await updateProgress(courseTitle, (lessonIndex + 1) / lessonCount);
  }

  Map<String, dynamic>? getTeacherCourse(String courseTitle) {
    final course = _findCourseByTitle(courseTitle);
    return course == null ? null : _cloneCourse(course);
  }

  Map<String, dynamic>? getCourseByTitle(String courseTitle) =>
      getTeacherCourse(courseTitle);

  List<String> lessonTitlesFor(String courseTitle) {
    final course = _findCourseByTitle(courseTitle);
    if (course == null) return const [];
    return _videoListFor(course)
        .asMap()
        .entries
        .map((entry) => entry.value['title'] ?? 'Lesson ${entry.key + 1}')
        .toList();
  }

  List<String> videoUrlsFor(String courseTitle) {
    final course = _findCourseByTitle(courseTitle);
    if (course == null) return const [];
    return _videoListFor(course)
        .map((video) => video['url'] ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }

  Future<void> resetLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coursesKey);
    await prefs.remove(_enrolledCourseIdsKey);
    await prefs.remove(_progressKey);
    _loaded = false;
    await ensureLoaded();
  }

  Future<void> _saveAndNotify() async {
    _applyProgressToCourses();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_coursesKey, jsonEncode(_courses));
    await prefs.setStringList(
      _enrolledCourseIdsKey,
      _enrolledCourseIds.toList(),
    );
    await prefs.setString(_progressKey, jsonEncode(_progressByCourseId));
  }

  void _applyProgressToCourses() {
    for (final course in _courses) {
      final id = course['id'] as String?;
      if (id == null) continue;
      course['progress'] = _progressByCourseId[id] ??
          ((course['progress'] as num?)?.toDouble() ?? 0);
    }
  }

  Map<String, dynamic>? _findCourseByTitle(String title) {
    final normalized = title.trim().toLowerCase();
    for (final course in _courses) {
      if ((course['title'] as String? ?? '').trim().toLowerCase() ==
          normalized) {
        return course;
      }
    }
    return null;
  }

  Map<String, dynamic>? _findCourseById(String id) {
    for (final course in _courses) {
      if (course['id'] == id) return course;
    }
    return null;
  }

  String _uniqueIdForTitle(String title) {
    final base = _slugify(title);
    var candidate = base;
    var suffix = 2;
    while (_courses.any((course) => course['id'] == candidate)) {
      candidate = '$base-$suffix';
      suffix++;
    }
    return candidate;
  }

  String _slugify(String input) {
    final slug = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'course' : slug;
  }

  List<Map<String, String>> _videoListFor(Map<String, dynamic> course) {
    final rawVideos = (course['videoUrls'] as List?) ?? [];
    return rawVideos.asMap().entries.map((entry) {
      final video = entry.value;
      if (video is Map) {
        return {
          'title':
              (video['title'] ?? video['name'] ?? 'Lesson ${entry.key + 1}')
                  .toString(),
          'url': (video['url'] ?? video['videoUrl'] ?? '').toString(),
        };
      }
      return {'title': 'Lesson ${entry.key + 1}', 'url': video.toString()};
    }).toList();
  }

  static List<Map<String, dynamic>> _decodeCourseList(String value) {
    try {
      final decoded = jsonDecode(value) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((course) => Map<String, dynamic>.from(course))
          .toList();
    } catch (_) {
      return _cloneCourses(_defaultCourses);
    }
  }

  static Map<String, double> _decodeProgressMap(String? value) {
    if (value == null) return {};
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return decoded.map(
        (key, progress) => MapEntry(
          key,
          progress is num ? progress.toDouble() : double.tryParse('$progress') ?? 0,
        ),
      );
    } catch (_) {
      return {};
    }
  }

  static Map<String, dynamic> _cloneCourse(Map<String, dynamic> course) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(course)) as Map);

  static List<Map<String, dynamic>> _cloneCourses(Iterable<dynamic> courses) =>
      courses
          .map((course) => _cloneCourse(Map<String, dynamic>.from(course)))
          .toList();

  static final List<Map<String, dynamic>> _defaultCourses = [
    {
      'id': 'java-dsa',
      'title': 'JAVA & DSA',
      'description': 'Step-by-step Java and data structures practice.',
      'instructor': 'Shradha Khapra',
      'price': 'Free',
      'rating': 4.9,
      'students': 12,
      'category': 'Programming',
      'progress': 0.25,
      'thumbnail': '',
      'videoUrls': [
        {
          'title': 'Java introduction',
          'url': 'https://youtu.be/luAkR9VaLcw?si=y72Bsnk-xR4643yi',
        },
        {
          'title': 'Variables and data types',
          'url': 'https://youtu.be/XQfHvqp7kXU?si=GV_zGM6uHBmdUNOY',
        },
        {
          'title': 'Operators',
          'url': 'https://youtu.be/2uoO_fY1aDs?si=JFph3_U5slTCOM-G',
        },
        {
          'title': 'Conditional statements',
          'url':
              'https://youtu.be/0r1SfRoLuzU?list=PLfqMhTWNBTe3LtFWcvwpqTkUSlB32kJop',
        },
        {
          'title': 'Loops',
          'url':
              'https://youtu.be/GjHNGM7KN3w?list=PLfqMhTWNBTe3LtFWcvwpqTkUSlB32kJop',
        },
        {
          'title': 'Patterns',
          'url':
              'https://youtu.be/Dr4PpNa7AYo?list=PLfqMhTWNBTe3LtFWcvwpqTkUSlB32kJop',
        },
      ],
    },
    {
      'id': 'flutter-development',
      'title': 'Flutter Development',
      'description': 'Build mobile apps with Flutter widgets and navigation.',
      'instructor': 'WS Cube',
      'price': 'Free',
      'rating': 4.8,
      'students': 9,
      'category': 'Mobile',
      'progress': 0.30,
      'thumbnail': '',
      'videoUrls': [
        {
          'title': 'Flutter setup',
          'url':
              'https://youtu.be/jqxz7QvdWk8?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        },
        {
          'title': 'First app',
          'url':
              'https://youtu.be/PKDWinlLfAo?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        },
        {
          'title': 'Widgets',
          'url':
              'https://youtu.be/BqHOtlh3Dd4?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        },
        {
          'title': 'Layouts',
          'url':
              'https://youtu.be/VPoqbBXzGtA?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        },
        {
          'title': 'Navigation',
          'url':
              'https://youtu.be/SR-AB3RJWbg?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        },
      ],
    },
    {
      'id': 'adobe-premiere-pro',
      'title': 'Adobe Premiere Pro',
      'description': 'Edit videos with timelines, cuts, audio, and exports.',
      'instructor': 'GFX Mentor',
      'price': 'Free',
      'rating': 4.7,
      'students': 7,
      'category': 'Editing',
      'progress': 0.65,
      'thumbnail': '',
      'videoUrls': [
        {
          'title': 'Premiere Pro basics',
          'url':
              'https://youtu.be/h6eeDgBjZq8?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        },
        {
          'title': 'Timeline editing',
          'url':
              'https://youtu.be/TP8wre-Mm1k?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        },
        {
          'title': 'Audio cleanup',
          'url':
              'https://youtu.be/kCGNe7BFq6g?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        },
        {
          'title': 'Export settings',
          'url':
              'https://youtu.be/2TyL6ViQDwQ?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        },
      ],
    },
    {
      'id': 'machine-learning',
      'title': 'Machine Learning Fundamentals',
      'description': 'Learn core ML concepts, models, and evaluation.',
      'instructor': 'Jane Smith',
      'price': '\$79.99',
      'rating': 4.9,
      'students': 23,
      'category': 'AI',
      'progress': 0.0,
      'thumbnail': '',
      'videoUrls': [
        {
          'title': 'What is machine learning?',
          'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        },
        {
          'title': 'Supervised learning',
          'url': 'https://www.youtube.com/watch?v=jNQXAC9IVRw',
        },
        {
          'title': 'Model evaluation',
          'url': 'https://www.youtube.com/watch?v=9bZkp7q19f0',
        },
      ],
    },
    {
      'id': 'web-development',
      'title': 'Web Development Bootcamp',
      'description': 'HTML, CSS, JavaScript, and frontend fundamentals.',
      'instructor': 'Mike Johnson',
      'price': '\$59.99',
      'rating': 4.7,
      'students': 18,
      'category': 'Web',
      'progress': 0.0,
      'thumbnail': '',
      'videoUrls': [
        {
          'title': 'HTML foundations',
          'url': 'https://www.youtube.com/watch?v=kJQP7kiw5Fk',
        },
        {
          'title': 'CSS layout',
          'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        },
        {
          'title': 'JavaScript basics',
          'url': 'https://www.youtube.com/watch?v=jNQXAC9IVRw',
        },
      ],
    },
    {
      'id': 'ui-ux-design',
      'title': 'UI/UX Design',
      'description': 'Design usable interfaces, flows, and prototypes.',
      'instructor': 'David Brown',
      'price': '\$39.99',
      'rating': 4.6,
      'students': 10,
      'category': 'Design',
      'progress': 0.0,
      'thumbnail': '',
      'videoUrls': [
        {
          'title': 'Design thinking',
          'url': 'https://www.youtube.com/watch?v=GIIQ1FZgZQI',
        },
        {
          'title': 'Wireframes',
          'url': 'https://www.youtube.com/watch?v=qeGFV5LELpk',
        },
      ],
    },
  ];
}
