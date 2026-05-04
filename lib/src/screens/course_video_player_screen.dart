import 'package:ailearning/src/homescreen/teacher/screens/ai_chat_screen.dart';
import 'package:ailearning/src/homescreen/services/course_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ailearning/src/common/app_theme.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Screen that plays course videos with YouTube-style playlist
/// Auto-plays the first video or resumes from progress
/// Can handle both single videos and playlists
class CourseVideoPlayerScreen extends StatefulWidget {
  final List<String> videoUrls;
  final String courseTitle;
  final String? instructor;
  final double progress;

  const CourseVideoPlayerScreen({
    super.key,
    required this.videoUrls,
    required this.courseTitle,
    this.instructor,
    this.progress = 0.0,
  });

  @override
  State<CourseVideoPlayerScreen> createState() =>
      _CourseVideoPlayerScreenState();
}

class _CourseVideoPlayerScreenState extends State<CourseVideoPlayerScreen> {
  final CourseService _courseService = CourseService();
  List<VideoItem> _videoItems = [];
  int _currentVideoIndex = 0;
  YoutubePlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  double _courseProgress = 0;

  @override
  void initState() {
    super.initState();
    _courseProgress = widget.progress;
    _initializeVideos();
    _calculateCurrentVideoIndex();
    _loadSavedProgress();
    if (_videoItems.isNotEmpty) {
      _initializePlayer();
    } else {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'No valid videos found';
      });
    }
  }

  Future<void> _loadSavedProgress() async {
    await _courseService.ensureLoaded();
    if (!mounted) return;

    final savedProgress = _courseService.getCourseProgress(widget.courseTitle);
    if (savedProgress <= _courseProgress || _videoItems.isEmpty) return;

    setState(() {
      _courseProgress = savedProgress;
      _calculateCurrentVideoIndex();
    });
  }

  void _initializeVideos() {
    _videoItems = [];
    for (int i = 0; i < widget.videoUrls.length; i++) {
      final videoId = YoutubePlayer.convertUrlToId(widget.videoUrls[i]);
      if (videoId != null) {
        _videoItems.add(
          VideoItem(
            videoId: videoId,
            title: 'Lesson ${i + 1}',
            url: widget.videoUrls[i],
            isWatched: false,
          ),
        );
      }
    }
  }

  void _calculateCurrentVideoIndex() {
    // Calculate which video to start based on progress
    // Example: 0.65 progress = 65% completed = start from video at 65% of total videos
    if (_videoItems.isEmpty) return;

    final totalVideos = _videoItems.length;
    final progressPercent = _courseProgress;

    // Calculate watched videos (approximately)
    final watchedVideos = (totalVideos * progressPercent).floor();

    // Start from the next unwatched video (or first if none watched)
    _currentVideoIndex = watchedVideos < totalVideos ? watchedVideos : 0;

    // Mark previous videos as watched
    for (int i = 0; i < _currentVideoIndex; i++) {
      if (i < _videoItems.length) {
        _videoItems[i].isWatched = true;
      }
    }
  }

  void _initializePlayer() {
    if (_videoItems.isEmpty || _currentVideoIndex >= _videoItems.length) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'No valid videos found';
      });
      return;
    }

    try {
      final videoId = _videoItems[_currentVideoIndex].videoId;
      if (videoId.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Invalid video ID';
        });
        return;
      }

      // Dispose previous controller if exists
      _controller?.dispose();

      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true, // Let the package handle timing
          mute: false,
          loop: false,
          controlsVisibleAtStart: true,
          enableCaption: false,
          hideControls: false,
          forceHD: false,
          startAt: 0,
        ),
      )..addListener(_listener);

      // Set loading to false after a delay to allow initialization
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && _controller != null) {
          setState(() => _isLoading = false);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to initialize video player: ${e.toString()}';
        });
      }
    }
  }

  void _listener() {
    if (_controller == null) return;

    if (_controller!.value.hasError) {
      if (mounted) {
        setState(() {
          _hasError = true;
          try {
            _errorMessage = _controller!.value.errorCode.toString();
          } catch (e) {
            _errorMessage = 'Unknown error occurred';
          }
        });
      }
    }
  }

  void _switchVideo(int index) {
    if (index == _currentVideoIndex || index >= _videoItems.length) return;

    setState(() {
      _currentVideoIndex = index;
      _isLoading = true;
      _hasError = false;
    });

    // Dispose and recreate controller for new video
    _controller?.dispose();
    _controller = null;

    // Reinitialize with new video
    _initializePlayer();
  }

  void _onVideoEnded() {
    // Mark current video as watched
    if (_currentVideoIndex < _videoItems.length) {
      setState(() {
        _videoItems[_currentVideoIndex].isWatched = true;
      });
      _courseService.markLessonWatched(
        courseTitle: widget.courseTitle,
        lessonIndex: _currentVideoIndex,
        lessonCount: _videoItems.length,
      );
      _courseProgress = (_currentVideoIndex + 1) / _videoItems.length;
    }

    // Auto-play next video if available
    if (_currentVideoIndex < _videoItems.length - 1) {
      _switchVideo(_currentVideoIndex + 1);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.secondaryColor,
        onPressed: () {
          final currentVideoUrl = _currentVideoIndex < _videoItems.length
              ? _videoItems[_currentVideoIndex].url
              : null;
          final allowedLessonCount = _allowedLessonCount();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherAIChatScreen(
                videoUrl: currentVideoUrl,
                courseTitle: widget.courseTitle,
                courseProgress: _courseProgress,
                currentLessonIndex: _currentVideoIndex,
                allowedLessonTitles: _videoItems
                    .take(allowedLessonCount)
                    .map((video) => video.title)
                    .toList(),
              ),
            ),
          );
        },
        child: Icon(
          Icons.support_agent_rounded,
          color: Colors.black,
          size: 24.sp,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: AppTheme.secondaryColor,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.courseTitle,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    color: AppTheme.secondaryColor,
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Video Player
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _hasError
                  ? _buildErrorState()
                  : _buildPlayer(),
            ),

            // Playlist Header (only show if multiple videos)
            if (_videoItems.length > 1) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Course Content',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${_videoItems.length} lessons',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textPrimary.withOpacity(
                          AppTheme.textSecondaryOpacity,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Playlist
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _videoItems.length,
                  itemBuilder: (context, index) => PlaylistVideoItem(
                    video: _videoItems[index],
                    isActive: index == _currentVideoIndex,
                    onTap: () => _switchVideo(index),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _allowedLessonCount() {
    if (_videoItems.isEmpty) return 0;
    final progressBasedCount = (_videoItems.length * _courseProgress).ceil();
    final count = [
      progressBasedCount,
      _currentVideoIndex + 1,
      1,
    ].reduce((value, element) => value > element ? value : element);
    return count.clamp(1, _videoItems.length).toInt();
  }

  Widget _buildPlayer() {
    if (_controller == null || _currentVideoIndex >= _videoItems.length) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Video Player Container
          AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(
              controller: _controller!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: AppTheme.secondaryColor,
              progressColors: ProgressBarColors(
                playedColor: AppTheme.secondaryColor,
                handleColor: AppTheme.secondaryColor,
                bufferedColor: AppTheme.textPrimary.withOpacity(0.3),
                backgroundColor: AppTheme.textPrimary.withOpacity(0.1),
              ),
              onReady: () {
                // onReady means WebView is loaded, but YouTube API might still be initializing
                // Let autoPlay handle the actual playback timing
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              },
              onEnded: (metadata) {
                _onVideoEnded();
              },
            ),
          ),

          // Video Info Section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.textPrimary.withOpacity(
                    AppTheme.borderOpacity,
                  ),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  _videoItems[_currentVideoIndex].title,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (widget.instructor != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    widget.instructor!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textPrimary.withOpacity(
                        AppTheme.textSecondaryOpacity,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppTheme.primaryColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.secondaryColor),
            SizedBox(height: 16.h),
            Text(
              'Loading video...',
              style: TextStyle(
                fontSize: 16.sp,
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

  Widget _buildErrorState() {
    return Container(
      color: AppTheme.primaryColor,
      padding: EdgeInsets.all(24.w),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: AppTheme.textPrimary.withOpacity(
                AppTheme.textTertiaryOpacity,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Error Loading Video',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage ?? 'Unable to load this video',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textPrimary.withOpacity(
                  AppTheme.textSecondaryOpacity,
                ),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                  _errorMessage = null;
                });
                _initializePlayer();
              },
              child: Text('Retry', style: TextStyle(fontSize: 16.sp)),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoItem {
  final String videoId;
  final String title;
  final String url;
  bool isWatched;

  VideoItem({
    required this.videoId,
    required this.title,
    required this.url,
    required this.isWatched,
  });
}

class PlaylistVideoItem extends StatelessWidget {
  final VideoItem video;
  final bool isActive;
  final VoidCallback onTap;

  const PlaylistVideoItem({
    super.key,
    required this.video,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = 'https://img.youtube.com/vi/${video.videoId}/0.jpg';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.textPrimary.withOpacity(
                  AppTheme.selectedContainerOpacity,
                )
              : AppTheme.primaryColor,
          border: Border(
            left: BorderSide(
              color: isActive ? AppTheme.secondaryColor : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                thumbnailUrl,
                width: 120.w,
                height: 68.h,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 120.w,
                    height: 68.h,
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
                    width: 120.w,
                    height: 68.h,
                    color: AppTheme.textPrimary.withOpacity(
                      AppTheme.containerOpacity * 2,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
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

            SizedBox(width: 12.w),

            // Video Info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isActive)
                        Icon(
                          Icons.play_arrow,
                          size: 16.sp,
                          color: AppTheme.secondaryColor,
                        ),
                      if (isActive) SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          video.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (video.isWatched && !isActive)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14.sp,
                            color: AppTheme.secondaryColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Watched',
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
                ],
              ),
            ),

            // More Options
            IconButton(
              icon: Icon(
                Icons.more_vert,
                size: 20.sp,
                color: AppTheme.textPrimary.withOpacity(
                  AppTheme.textSecondaryOpacity,
                ),
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
