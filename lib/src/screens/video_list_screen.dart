import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:ailearning/src/screens/course_video_player_screen.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Screen that displays a list of YouTube videos from URLs
///
/// Usage:
/// ```dart
/// VideoListScreen(
///   videoUrls: [
///     'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
///     'https://youtu.be/jNQXAC9IVRw',
///   ],
/// )
/// ```
class VideoListScreen extends StatelessWidget {
  final List<String> videoUrls;
  final String? title;

  const VideoListScreen({super.key, required this.videoUrls, this.title});

  @override
  Widget build(BuildContext context) {
    // Convert URLs to video IDs and filter invalid ones
    final videoItems = <VideoItem>[];

    for (int i = 0; i < videoUrls.length; i++) {
      final videoId = YoutubePlayer.convertUrlToId(videoUrls[i]);
      if (videoId != null) {
        videoItems.add(
          VideoItem(
            videoId: videoId,
            title: 'Video ${i + 1}',
            url: videoUrls[i],
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Video List'),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),

      body: videoItems.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: videoItems.length,
              itemBuilder: (context, index) => VideoListItem(
                videoItem: videoItems[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseVideoPlayerScreen(
                        videoUrls: [videoItems[index].url],
                        courseTitle: videoItems[index].title,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
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
            'No valid videos found',
            style: TextStyle(
              fontSize: 18.sp,
              color: AppTheme.textPrimary.withOpacity(
                AppTheme.textSecondaryOpacity,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Please provide valid YouTube URLs',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textPrimary.withOpacity(
                AppTheme.textTertiaryOpacity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoItem {
  final String videoId;
  final String title;
  final String url;

  VideoItem({required this.videoId, required this.title, required this.url});
}

class VideoListItem extends StatelessWidget {
  final VideoItem videoItem;
  final VoidCallback onTap;

  const VideoListItem({
    super.key,
    required this.videoItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl =
        'https://img.youtube.com/vi/${videoItem.videoId}/0.jpg';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppTheme.textPrimary.withOpacity(AppTheme.containerOpacity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textPrimary.withOpacity(AppTheme.borderOpacity),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: Image.network(
                thumbnailUrl,
                width: 160.w,
                height: 90.h,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 160.w,
                    height: 90.h,
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
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 160.w,
                    height: 90.h,
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.containerOpacity * 2,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.video_library_outlined,
                        size: 32.sp,
                        color: AppTheme.textPrimary.withOpacity(
                          AppTheme.textTertiaryOpacity,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Video Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline,
                          size: 20.sp,
                          color: AppTheme.secondaryColor,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            videoItem.title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'YouTube',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Arrow Icon
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: AppTheme.textPrimary.withOpacity(
                  AppTheme.textSecondaryOpacity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
