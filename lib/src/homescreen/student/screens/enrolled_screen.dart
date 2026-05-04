import 'package:ailearning/src/homescreen/services/course_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/screens/course_video_player_screen.dart';

class EnrolledScreen extends StatefulWidget {
  const EnrolledScreen({super.key});

  @override
  State<EnrolledScreen> createState() => _EnrolledScreenState();
}

class _EnrolledScreenState extends State<EnrolledScreen> {
  final CourseService _courseService = CourseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _courseService.addListener(_onCoursesChanged);
    _loadCourses();
  }

  @override
  void dispose() {
    _courseService.removeListener(_onCoursesChanged);
    super.dispose();
  }

  Future<void> _loadCourses() async {
    await _courseService.ensureLoaded();
    if (mounted) setState(() => _isLoading = false);
  }

  void _onCoursesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courseService.enrolledCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryColor),
            )
          : courses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return EnrolledCourseCard(
                  title: course['title'] as String? ?? 'Course',
                  instructor:
                      course['instructor'] as String? ?? 'Unknown Instructor',
                  progress: (course['progress'] as num?)?.toDouble() ?? 0,
                  videoUrls: _extractVideoUrls(course['videoUrls']),
                  onProgressChanged: () {
                    if (mounted) setState(() {});
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64.sp,
              color: AppTheme.textPrimary.withOpacity(
                AppTheme.textTertiaryOpacity,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No enrolled courses yet',
              style: TextStyle(
                fontSize: 18.sp,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Enroll from the Courses tab to start learning.',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textPrimary.withOpacity(
                  AppTheme.textSecondaryOpacity,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
}

class EnrolledCourseCard extends StatelessWidget {
  final String title;
  final String instructor;
  final double progress;
  final List<String> videoUrls;
  final VoidCallback onProgressChanged;

  const EnrolledCourseCard({
    super.key,
    required this.title,
    required this.instructor,
    required this.progress,
    required this.videoUrls,
    required this.onProgressChanged,
  });

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
    } catch (e) {
      return null;
    }
  }

  String _getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  Widget _buildThumbnail() {
    if (videoUrls.isEmpty) return _buildPlaceholder();

    final videoId = _extractVideoId(videoUrls[0]);
    if (videoId == null || videoId.isEmpty) return _buildPlaceholder();

    return Container(
      width: 120.w,
      height: 120.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(12.r)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(12.r)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _getThumbnailUrl(videoId),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholder(),
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
                    ),
                  ),
                );
              },
            ),
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 40.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 120.w,
      height: 120.h,
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withOpacity(AppTheme.containerOpacity * 2),
        borderRadius: BorderRadius.all(Radius.circular(12.r)),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 40.sp,
          color: AppTheme.textPrimary.withOpacity(AppTheme.textTertiaryOpacity),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withOpacity(AppTheme.containerOpacity),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.textPrimary.withOpacity(AppTheme.borderOpacity),
        ),
      ),
      child: Row(
        children: [
          Padding(padding: EdgeInsets.all(8.w), child: _buildThumbnail()),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.sp),
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
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textPrimary.withOpacity(
                            AppTheme.textSecondaryOpacity,
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
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
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: videoUrls.isEmpty
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CourseVideoPlayerScreen(
                                        videoUrls: videoUrls,
                                        courseTitle: title,
                                        instructor: instructor,
                                        progress: progress,
                                      ),
                                ),
                              ).then((_) => onProgressChanged());
                            },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                      child: Text(
                        videoUrls.isEmpty
                            ? 'No Videos Yet'
                            : 'Continue Learning',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
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
