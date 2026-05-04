import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/homescreen/services/course_service.dart';
import 'package:ailearning/src/common/global_snackbar.dart';
import 'package:ailearning/src/homescreen/teacher/screens/ai_chat_screen.dart';
import 'package:ailearning/src/homescreen/teacher/screens/teacher_course_detail_screen.dart';
import 'package:ailearning/src/homescreen/student/screens/profile_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TeacherCoursesScreen(),
    const TeacherAIChatScreen(),
    const ProfileScreen(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'My Courses',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class TeacherCoursesScreen extends StatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  final CourseService _courseService = CourseService();

  @override
  Widget build(BuildContext context) {
    final courses = _courseService.teacherCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCourseDialog(context),
            tooltip: 'Add New Course',
          ),
        ],
      ),
      body: courses.isEmpty
          ? Center(
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
                    'No courses yet',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: AppTheme.textPrimary.withOpacity(
                        AppTheme.textSecondaryOpacity,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Create your first course',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textPrimary.withOpacity(
                        AppTheme.textTertiaryOpacity,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: () => _showAddCourseDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Course'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: courses.length,
              itemBuilder: (context, index) => TeacherCourseCard(
                course: courses[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TeacherCourseDetailScreen(course: courses[index]),
                    ),
                  ).then((_) {
                    // Refresh the list when returning from detail screen
                    if (mounted) {
                      setState(() {});
                    }
                  });
                },
                onAddVideo: () => _showAddVideoDialog(context, courses[index]),
              ),
            ),
    );
  }

  void _showAddCourseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter course title',
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter course description',
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty) {
                GlobalScaffoldManager().showSnackbar(
                  'Please fill all fields',
                  type: SnackbarType.error,
                  duration: const Duration(seconds: 2),
                );
                return;
              }

              final title = titleController.text.trim();
              final description = descriptionController.text.trim();

              // Call API to create course
              final response = await _courseService.createCourse(
                title: title,
                description: description,
              );

              // Print the response
              print('Create Course Response: $response');

              if (response != null && response.containsKey('error')) {
                GlobalScaffoldManager().showSnackbar(
                  'Failed to create course: ${response['error']}',
                  type: SnackbarType.error,
                  duration: const Duration(seconds: 3),
                );
                return;
              }

              // Also add to local list
              _courseService.addTeacherCourse(
                title: title,
                description: description,
              );

              Navigator.pop(context);
              // Trigger rebuild by calling setState on the parent
              final teacherState = context
                  .findAncestorStateOfType<_TeacherCoursesScreenState>();
              if (teacherState != null && teacherState.mounted) {
                teacherState.setState(() {});
              }

              GlobalScaffoldManager().showSnackbar(
                'Course added successfully',
                type: SnackbarType.success,
                duration: const Duration(seconds: 2),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddVideoDialog(BuildContext context, Map<String, dynamic> course) {
    final videoTitleController = TextEditingController();
    final videoUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Video to ${course['title']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: videoTitleController,
                decoration: const InputDecoration(
                  labelText: 'Video Title',
                  hintText: 'Enter video title',
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: videoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  hintText: 'https://www.youtube.com/watch?v=...',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
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

              _courseService.addVideoToCourse(
                courseTitle: course['title'],
                videoTitle: videoTitleController.text.trim(),
                videoUrl: videoUrlController.text.trim(),
              );

              Navigator.pop(context);
              if (mounted) {
                setState(() {});
              }

              GlobalScaffoldManager().showSnackbar(
                'Video added successfully',
                type: SnackbarType.success,
                duration: const Duration(seconds: 2),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class TeacherCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final VoidCallback onTap;
  final VoidCallback onAddVideo;

  const TeacherCourseCard({
    super.key,
    required this.course,
    required this.onTap,
    required this.onAddVideo,
  });

  String? _extractVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      String? videoId;

      // Handle youtu.be format: https://youtu.be/VIDEO_ID
      if (uri.host.contains('youtu.be')) {
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }
      // Handle youtube.com format: https://www.youtube.com/watch?v=VIDEO_ID
      else if (uri.host.contains('youtube.com')) {
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

  Widget _buildThumbnail(List videoUrls) {
    if (videoUrls.isEmpty) {
      return _buildPlaceholder();
    }

    final firstVideo = videoUrls[0];
    String? firstVideoUrl;
    if (firstVideo is Map) {
      firstVideoUrl =
          firstVideo['url'] as String? ?? firstVideo['videoUrl'] as String?;
    } else if (firstVideo is String) {
      firstVideoUrl = firstVideo;
    }

    if (firstVideoUrl == null || firstVideoUrl.isEmpty) {
      return _buildPlaceholder();
    }

    final videoId = _extractVideoId(firstVideoUrl);
    if (videoId == null || videoId.isEmpty) {
      return _buildPlaceholder();
    }

    return Container(
      width: 80.w,
      height: 80.h,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _getThumbnailUrl(videoId),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder();
              },
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
            // Play icon overlay
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 32.sp,
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
      width: 80.w,
      height: 80.h,
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withOpacity(AppTheme.containerOpacity * 2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 32.sp,
          color: AppTheme.textPrimary.withOpacity(AppTheme.textTertiaryOpacity),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoUrls = course['videoUrls'] as List;
    final videoCount = videoUrls.length;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Header
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    // Thumbnail
                    _buildThumbnail(videoUrls),
                    SizedBox(width: 16.w),

                    // Course Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course['title'] ?? 'Untitled Course',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            course['instructor'] ?? 'Unknown Instructor',
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
                                '$videoCount ${videoCount == 1 ? 'video' : 'videos'}',
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

              // Video List
              if (videoUrls.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.containerOpacity * 0.5,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12.r),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Videos:',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary.withOpacity(
                            AppTheme.textSecondaryOpacity,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      ...videoUrls.asMap().entries.map((entry) {
                        final index = entry.key;
                        final video = entry.value;
                        final videoTitle = video is Map
                            ? video['title'] as String? ?? 'Video ${index + 1}'
                            : 'Video ${index + 1}';
                        return Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Row(
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                size: 14.sp,
                                color: AppTheme.secondaryColor,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  videoTitle,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppTheme.textPrimary.withOpacity(
                                      AppTheme.textSecondaryOpacity,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

              // Add Video Button
              Padding(
                padding: EdgeInsets.all(16.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAddVideo,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Video'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
