import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/homescreen/services/course_service.dart';
import 'package:ailearning/src/common/global_snackbar.dart';
import 'package:ailearning/src/screens/course_video_player_screen.dart';

class TeacherCourseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const TeacherCourseDetailScreen({super.key, required this.course});

  @override
  State<TeacherCourseDetailScreen> createState() =>
      _TeacherCourseDetailScreenState();
}

class _TeacherCourseDetailScreenState extends State<TeacherCourseDetailScreen> {
  final CourseService _courseService = CourseService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _courseService.addListener(_onCoursesChanged);
    _loadCourse();
  }

  @override
  void dispose() {
    _courseService.removeListener(_onCoursesChanged);
    super.dispose();
  }

  Future<void> _loadCourse() async {
    await _courseService.ensureLoaded();
    if (mounted) setState(() => _isLoading = false);
  }

  void _onCoursesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final originalTitle = widget.course['title'] as String? ?? '';
    final course = _courseService.getTeacherCourse(originalTitle) ??
        Map<String, dynamic>.from(widget.course);
    final videoUrls = (course['videoUrls'] as List?) ?? [];
    final courseTitle = course['title'] as String? ?? 'Untitled Course';
    final instructor = course['instructor'] as String? ?? 'Unknown Instructor';

    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddVideoDialog(context),
            tooltip: 'Add Video',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.secondaryColor),
            )
          : videoUrls.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
                    size: 64.sp,
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.textTertiaryOpacity,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No videos yet',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: AppTheme.textPrimary.withOpacity(
                        AppTheme.textSecondaryOpacity,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Add your first video to this course',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textPrimary.withOpacity(
                        AppTheme.textTertiaryOpacity,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: () => _showAddVideoDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Video'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Course Info Card
                Container(
                  margin: EdgeInsets.all(16.w),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.containerOpacity,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppTheme.textPrimary.withOpacity(
                        AppTheme.borderOpacity,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60.w,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          Icons.school,
                          size: 32.sp,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              courseTitle,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'By $instructor',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppTheme.textPrimary.withOpacity(
                                  AppTheme.textSecondaryOpacity,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.video_library,
                                  size: 16.sp,
                                  color: AppTheme.secondaryColor,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${videoUrls.length} ${videoUrls.length == 1 ? 'video' : 'videos'}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppTheme.textPrimary.withOpacity(
                                      AppTheme.textSecondaryOpacity,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Videos List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: videoUrls.length,
                    itemBuilder: (context, index) {
                      final video = videoUrls[index];
                      final videoUrl = video is Map
                          ? video['url'] as String? ??
                                video['videoUrl'] as String? ??
                                ''
                          : video as String;
                      final videoTitle = video is Map
                          ? video['title'] as String? ?? 'Video ${index + 1}'
                          : 'Video ${index + 1}';

                      // Extract URLs for video player
                      final urls = videoUrls
                          .map((v) {
                            if (v is Map) {
                              return v['url'] as String? ??
                                  v['videoUrl'] as String? ??
                                  '';
                            }
                            return v as String;
                          })
                          .toList()
                          .cast<String>();

                      return VideoListItem(
                        videoTitle: videoTitle,
                        videoUrl: videoUrl,
                        index: index,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseVideoPlayerScreen(
                                videoUrls: urls,
                                courseTitle: courseTitle,
                                instructor: instructor,
                                progress: 0.0,
                              ),
                            ),
                          );
                        },
                        onDelete: () => _showDeleteVideoDialog(context, index),
                      );
                    },
                  ),
                ),

                // Add Video Button (if videos exist)
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.textPrimary.withOpacity(
                          AppTheme.borderOpacity,
                        ),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddVideoDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Video'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showAddVideoDialog(BuildContext context) {
    final videoTitleController = TextEditingController();
    final videoUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: AppTheme.textPrimary.withOpacity(AppTheme.borderOpacity),
          ),
        ),
        title: Text(
          'Add Video to ${widget.course['title']}',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18.sp),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: videoTitleController,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Video Title',
                  labelStyle: TextStyle(color: AppTheme.textPrimary),
                  hintText: 'Enter video title',
                  hintStyle: TextStyle(
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.textTertiaryOpacity,
                    ),
                  ),
                  filled: true,
                  fillColor: AppTheme.textPrimary.withOpacity(
                    AppTheme.containerOpacity,
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppTheme.secondaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: videoUrlController,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Video URL',
                  labelStyle: TextStyle(color: AppTheme.textPrimary),
                  hintText: 'https://www.youtube.com/watch?v=...',
                  hintStyle: TextStyle(
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.textTertiaryOpacity,
                    ),
                  ),
                  filled: true,
                  fillColor: AppTheme.textPrimary.withOpacity(
                    AppTheme.containerOpacity,
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppTheme.secondaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (videoTitleController.text.trim().isEmpty) {
                GlobalScaffoldManager().showSnackbar(
                  'Please enter a video title',
                  type: SnackbarType.error,
                  duration: const Duration(seconds: 2),
                );
                return;
              }
              if (videoUrlController.text.trim().isEmpty) {
                GlobalScaffoldManager().showSnackbar(
                  'Please enter a video URL',
                  type: SnackbarType.error,
                  duration: const Duration(seconds: 2),
                );
                return;
              }

              final added = await _courseService.addVideoToCourse(
                courseTitle: widget.course['title'] as String,
                videoTitle: videoTitleController.text.trim(),
                videoUrl: videoUrlController.text.trim(),
              );

              if (!added) {
                GlobalScaffoldManager().showSnackbar(
                  'Unable to add video',
                  type: SnackbarType.error,
                  duration: const Duration(seconds: 2),
                );
                return;
              }

              Navigator.pop(context);

              GlobalScaffoldManager().showSnackbar(
                'Video added successfully',
                type: SnackbarType.success,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: AppTheme.buttonForeground,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteVideoDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: AppTheme.textPrimary.withOpacity(AppTheme.borderOpacity),
          ),
        ),
        title: Text(
          'Delete Video',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this video?',
          style: TextStyle(
            color: AppTheme.textPrimary.withOpacity(
              AppTheme.textSecondaryOpacity,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final deleted = await _courseService.deleteVideoFromCourse(
                courseTitle: widget.course['title'] as String,
                index: index,
              );
              if (deleted) {
                Navigator.pop(context);
                GlobalScaffoldManager().showSnackbar(
                  'Video deleted successfully',
                  type: SnackbarType.success,
                  duration: const Duration(seconds: 2),
                );
              } else {
                GlobalScaffoldManager().showSnackbar(
                  'Unable to delete video',
                  type: SnackbarType.error,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class VideoListItem extends StatelessWidget {
  final String videoTitle;
  final String videoUrl;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const VideoListItem({
    super.key,
    required this.videoTitle,
    required this.videoUrl,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      String? videoId;

      if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      } else if (uri.host.contains('youtube.com')) {
        videoId = uri.queryParameters['v'];
      }

      return videoId;
    } catch (e) {
      return null;
    }
  }

  String _getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _extractVideoId(videoUrl);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withOpacity(AppTheme.containerOpacity),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.textPrimary.withOpacity(AppTheme.borderOpacity),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 120.w,
                  height: 68.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.containerOpacity * 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: videoId != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                _getThumbnailUrl(videoId),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: AppTheme.textPrimary.withOpacity(
                                          AppTheme.containerOpacity * 2,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            color: AppTheme.secondaryColor,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                              ),
                              Container(
                                color: Colors.black.withOpacity(0.3),
                                child: Center(
                                  child: Icon(
                                    Icons.play_circle_filled,
                                    size: 32.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _buildPlaceholder(),
                  ),
                ),
                SizedBox(width: 12.w),

                // Video Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        videoTitle,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Tap to preview',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textPrimary.withOpacity(
                            AppTheme.textSecondaryOpacity,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete Button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.withOpacity(0.8),
                    size: 24.sp,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete video',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.textPrimary.withOpacity(AppTheme.containerOpacity * 2),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 32.sp,
          color: AppTheme.textPrimary.withOpacity(AppTheme.textTertiaryOpacity),
        ),
      ),
    );
  }
}
