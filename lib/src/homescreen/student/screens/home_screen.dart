import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/common/global_snackbar.dart';
import 'package:ailearning/src/homescreen/services/course_service.dart';
import 'package:ailearning/src/homescreen/student/screens/enrolled_screen.dart';
import 'package:ailearning/src/homescreen/teacher/screens/ai_chat_screen.dart';
import 'package:ailearning/src/homescreen/student/screens/profile_screen.dart';
import 'package:ailearning/src/screens/course_video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CourseMarketplaceScreen(),
    const EnrolledScreen(),
    const TeacherAIChatScreen(userRole: 'student'),
    const ProfileScreen(userRole: 'student'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.primaryColor,
        selectedItemColor: AppTheme.secondaryColor,
        unselectedItemColor: AppTheme.textPrimary.withOpacity(
          AppTheme.textTertiaryOpacity,
        ),
        selectedFontSize: 12.sp,
        unselectedFontSize: 12.sp,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Enrolled'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class CourseMarketplaceScreen extends StatefulWidget {
  const CourseMarketplaceScreen({super.key});

  @override
  State<CourseMarketplaceScreen> createState() =>
      _CourseMarketplaceScreenState();
}

class _CourseMarketplaceScreenState extends State<CourseMarketplaceScreen> {
  final CourseService _courseService = CourseService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _courseService.addListener(_onCoursesChanged);
    _searchController.addListener(() => setState(() {}));
    _loadCourses();
  }

  @override
  void dispose() {
    _courseService.removeListener(_onCoursesChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    await _courseService.ensureLoaded();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onCoursesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _enroll(Map<String, dynamic> course) async {
    final title = course['title'] as String? ?? 'Course';
    final enrolled = await _courseService.enrollCourseByTitle(title);
    if (!mounted) return;

    GlobalScaffoldManager().showSnackbar(
      enrolled ? 'Enrolled in $title' : 'Unable to enroll in this course',
      type: enrolled ? SnackbarType.success : SnackbarType.error,
      duration: const Duration(seconds: 2),
    );
  }

  void _continueCourse(Map<String, dynamic> course) {
    final videos = _extractVideoUrls(course['videoUrls']);
    if (videos.isEmpty) {
      GlobalScaffoldManager().showSnackbar(
        'No videos available for this course yet',
        type: SnackbarType.info,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CourseVideoPlayerScreen(
          videoUrls: videos,
          courseTitle: course['title'] as String? ?? 'Course',
          instructor: course['instructor'] as String?,
          progress: (course['progress'] as num?)?.toDouble() ?? 0,
        ),
      ),
    );
  }

  List<String> _extractVideoUrls(dynamic rawVideos) {
    final videos = (rawVideos as List?) ?? const [];
    return videos
        .map((video) {
          if (video is Map) {
            return (video['url'] ?? video['videoUrl'] ?? '').toString();
          }
          return video.toString();
        })
        .where((url) => url.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final courses = _courseService.marketplaceCourses.where((course) {
      if (query.isEmpty) return true;
      final title = (course['title'] as String? ?? '').toLowerCase();
      final instructor = (course['instructor'] as String? ?? '').toLowerCase();
      final category = (course['category'] as String? ?? '').toLowerCase();
      return title.contains(query) ||
          instructor.contains(query) ||
          category.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar - Pinned at top, not scrollable
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextFormField(
              controller: _searchController,
              cursorColor: AppTheme.secondaryColor,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.textPrimary.withOpacity(
                    AppTheme.textTertiaryOpacity,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.textPrimary.withOpacity(
                  AppTheme.containerOpacity,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 16.w,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.borderOpacity,
                    ),
                  ),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.borderOpacity,
                    ),
                  ),
                ),

                hintStyle: TextStyle(
                  color: AppTheme.textPrimary.withOpacity(
                    AppTheme.textTertiaryOpacity,
                  ),
                  fontSize: 16.sp,
                ),
              ),
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16.sp),
            ),
          ),

          // Scrollable content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.secondaryColor,
                    ),
                  )
                : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured Courses
                  Text(
                    'Featured Courses',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Course List
                  if (courses.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 96.h),
                      child: Center(
                        child: Text(
                          'No courses found',
                          style: TextStyle(
                            color: AppTheme.textPrimary.withOpacity(
                              AppTheme.textSecondaryOpacity,
                            ),
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: courses.length,
                      itemBuilder: (context, index) {
                        final course = courses[index];
                        final title = course['title'] as String? ?? 'Course';
                        final isEnrolled = _courseService.isEnrolled(title);
                        return CourseCard(
                          course: course,
                          isEnrolled: isEnrolled,
                          onEnroll: () => _enroll(course),
                          onContinue: () => _continueCourse(course),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final bool isEnrolled;
  final VoidCallback onEnroll;
  final VoidCallback onContinue;

  const CourseCard({
    super.key,
    required this.course,
    required this.isEnrolled,
    required this.onEnroll,
    required this.onContinue,
  });

  String? _firstVideoUrl() {
    final videos = (course['videoUrls'] as List?) ?? const [];
    if (videos.isEmpty) return null;

    final firstVideo = videos.first;
    if (firstVideo is Map) {
      final url = (firstVideo['url'] ?? firstVideo['videoUrl'] ?? '')
          .toString();
      return url.isEmpty ? null : url;
    }

    final url = firstVideo.toString();
    return url.isEmpty ? null : url;
  }

  String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _thumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  Widget _buildCourseThumbnail() {
    final firstVideoUrl = _firstVideoUrl();
    final videoId = firstVideoUrl == null ? null : _extractVideoId(firstVideoUrl);

    if (videoId == null || videoId.isEmpty) {
      return _buildThumbnailPlaceholder();
    }

    return SizedBox(
      height: 150.h,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _thumbnailUrl(videoId),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildThumbnailPlaceholder(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppTheme.textPrimary.withOpacity(
                    AppTheme.containerOpacity * 2,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppTheme.secondaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
            ),
            Container(color: Colors.black.withOpacity(0.28)),
            Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 54.sp,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      height: 150.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withOpacity(AppTheme.containerOpacity * 2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 48.sp,
          color: AppTheme.textPrimary.withOpacity(AppTheme.textTertiaryOpacity),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = course['title'] as String? ?? 'Course';
    final instructor = course['instructor'] as String? ?? 'Unknown Instructor';
    final price = course['price'] as String? ?? 'Free';
    final rating = (course['rating'] as num?)?.toDouble() ?? 0;
    final students = (course['students'] as num?)?.toInt() ?? 0;
    final progress = (course['progress'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.textPrimary.withOpacity(AppTheme.containerOpacity),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.textPrimary.withOpacity(AppTheme.borderOpacity),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourseThumbnail(),

            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    instructor,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textPrimary.withOpacity(
                        AppTheme.textSecondaryOpacity,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      Expanded(child: SizedBox()),
                      Icon(
                        Icons.star,
                        size: 14.sp,
                        color: AppTheme.secondaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '($students students)',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textPrimary.withOpacity(
                            AppTheme.textSecondaryOpacity,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isEnrolled) ...[
                    SizedBox(height: 10.h),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.textPrimary.withOpacity(
                        AppTheme.containerOpacity,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.secondaryColor,
                      ),
                      minHeight: 4.h,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${(progress * 100).toInt()}% completed',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textPrimary.withOpacity(
                          AppTheme.textSecondaryOpacity,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isEnrolled ? onContinue : onEnroll,
                      child: Text(isEnrolled ? 'Continue Learning' : 'Enroll'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
