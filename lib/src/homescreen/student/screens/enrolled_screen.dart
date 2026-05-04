// import 'package:ailearning/src/homescreen/teacher/screens/ai_chat_screen.dart';
// import 'package:ailearning/src/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/screens/course_video_player_screen.dart';

class EnrolledScreen extends StatelessWidget {
  const EnrolledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: AppTheme.secondaryColor,
      //   onPressed: () {
      //     ChatService().sendChatMessageWithVideo(
      //       query: 'what is react router dom',
      //       videoUrl: 'https://youtu.be/luAkR9VaLcw?si=y72Bsnk-xR4643yi',
      //     );
      //   },
      //   child: Icon(Icons.smart_toy, color: Colors.black, size: 24.sp),
      // ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: _enrolledCourses.length,
        itemBuilder: (context, index) => EnrolledCourseCard(
          title: _enrolledCourses[index]['title']!,
          instructor: _enrolledCourses[index]['instructor']!,
          progress: _enrolledCourses[index]['progress']!,
          thumbnail: _enrolledCourses[index]['thumbnail']!,
          videoUrls: (_enrolledCourses[index]['videoUrls'] as List<dynamic>)
              .map((e) => e.toString())
              .toList(),
        ),
      ),
    );
  }

  static final List<Map<String, dynamic>> _enrolledCourses = [
    {
      'title': 'JAVA & DSA',
      'instructor': 'Shradha Khapra',
      'progress': 0.25,
      'thumbnail': 'DSA',
      'videoUrls': [
        'https://youtu.be/luAkR9VaLcw?si=y72Bsnk-xR4643yi',
        'https://youtu.be/XQfHvqp7kXU?si=GV_zGM6uHBmdUNOY',
        'https://youtu.be/2uoO_fY1aDs?si=JFph3_U5slTCOM-G',
        'https://youtu.be/0r1SfRoLuzU?list=PLfqMhTWNBTe3LtFWcvwpqTkUSlB32kJop',
        'https://youtu.be/GjHNGM7KN3w?list=PLfqMhTWNBTe3LtFWcvwpqTkUSlB32kJop',
        'https://youtu.be/Dr4PpNa7AYo?list=PLfqMhTWNBTe3LtFWcvwpqTkUSlB32kJop',
        'https://youtu.be/qcSz4ef9UHA?list=PLfqMhTWNBTe3LtFWcvwpqTkUSlB32kJop',
        'https://youtu.be/pFPZ83mgH00?list=PLfqMhTWNBTe3LtFWcvwpqTkUSlB32kJop',
        'https://youtu.be/bQssdSrSGNE?list=PLfqMhTWNBTe3LtFWcvwpqTkUSlB32kJop',
        'https://youtu.be/NTHVTY6w2Co?list=PLfqMhTWNBTe3LtFWcvwpqTkUSlB32kJop',
      ],
    },
    {
      'title': 'Flutter Development',
      'instructor': 'WS cube',
      'progress': 0.30,
      'thumbnail': 'flutter',
      'videoUrls': [
        'https://youtu.be/jqxz7QvdWk8?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        'https://youtu.be/PKDWinlLfAo?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        'https://youtu.be/BqHOtlh3Dd4?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        'https://youtu.be/VPoqbBXzGtA?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        'https://youtu.be/SR-AB3RJWbg?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        'https://youtu.be/p91tt2AwUjM?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        'https://youtu.be/YOHFxBaPGQU?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        'https://youtu.be/B3MoTP3veBk?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        'https://youtu.be/_qkywk2VeHU?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
        'https://youtu.be/JzzBYI2LhLI?list=PLjVLYmrlmjGfGLShoW0vVX_tcyT8u1Y3E',
      ],
    },
    {
      'title': 'Adobe premiere pro',
      'instructor': 'GFX mentor',
      'progress': 0.65,
      'thumbnail': 'adobe',
      'videoUrls': [
        'https://youtu.be/h6eeDgBjZq8?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        'https://youtu.be/TP8wre-Mm1k?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        'https://youtu.be/kCGNe7BFq6g?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        'https://youtu.be/2TyL6ViQDwQ?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        'https://youtu.be/wDbosNeayeA?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        'https://youtu.be/K-WDpib9mv0?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        'https://youtu.be/t--TP6YcI7Q?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        'https://youtu.be/B4j4CMldcdk?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        'https://youtu.be/_WnWwzHIxJo?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
        'https://youtu.be/_cH9wCi4Ihg?list=PLW-zSkCnZ-gABGZU8--ISUauyewG40Yex',
      ],
    },
  ];
}

class EnrolledCourseCard extends StatelessWidget {
  final String title;
  final String instructor;
  final double progress;
  final String thumbnail;
  final List<String> videoUrls;

  const EnrolledCourseCard({
    super.key,
    required this.title,
    required this.instructor,
    required this.progress,
    required this.thumbnail,
    required this.videoUrls,
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

  Widget _buildThumbnail() {
    if (videoUrls.isEmpty) {
      return _buildPlaceholder();
    }

    final videoId = _extractVideoId(videoUrls[0]);
    if (videoId == null || videoId.isEmpty) {
      return _buildPlaceholder();
    }

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
          // Thumbnail
          Padding(padding: EdgeInsets.all(8.w), child: _buildThumbnail()),

          // Course Info
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
                  SizedBox(height: 4.h),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseVideoPlayerScreen(
                              videoUrls: videoUrls,
                              courseTitle: title,
                              instructor: instructor,
                              progress: progress,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                      child: Text(
                        'Continue Learning',
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
