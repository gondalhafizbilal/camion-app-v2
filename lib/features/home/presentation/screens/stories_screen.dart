import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:camion/core/utils/app_style.dart';
import 'package:camion/features/home/data/models/stories_model.dart/stories_model.dart';
import 'package:camion/generated/l10n.dart';
import 'package:camion/routing/app_router.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:video_player/video_player.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoriesModel> stories;
  final int initialIndex;
  final String mediaType;
  final int durationPeriod;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.mediaType,
    required this.durationPeriod,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _progressController;
  late final AnimationController _exitController;
  late final Duration _fallbackDuration;
  late final List<_StoryPlaybackItem> _playbackItems;
  late int _currentIndex;

  bool _isPressed = false;
  bool _isDragging = false;
  double _dragDistance = 0;

  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _videoInitialized = {};
  final Map<int, bool> _videoEnded = {};
  final Set<String> _prefetchedImageUrls = <String>{};
  final Map<String, ImageProvider> _cachedImageProviders =
      <String, ImageProvider>{};
  bool _didPrecacheStoryImages = false;

  @override
  void initState() {
    super.initState();
    _fallbackDuration = Duration(seconds: widget.durationPeriod);
    _playbackItems = _buildPlaybackItems(widget.stories);
    _currentIndex = _resolveInitialPlaybackIndex(widget.initialIndex);
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(
      duration: _fallbackDuration,
      vsync: this,
    );
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _initializeVideoControllers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _playbackItems.isNotEmpty) {
        _startProgress();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheStoryImages || _playbackItems.isEmpty) return;
    _didPrecacheStoryImages = true;
    _precacheStoryImages(centerIndex: _currentIndex);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _exitController.dispose();
    _pageController.dispose();
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeVideoControllers() {
    for (int i = 0; i < _playbackItems.length; i++) {
      final story = _playbackItems[i];
      final mediaUrl = story.mediaUrl.trim();
      if (!_isVideoStoryItem(story) || mediaUrl.isEmpty) {
        continue;
      }

      _videoInitialized[i] = false;
      _initializeVideoControllerAtIndex(i, mediaUrl);
    }
  }

  Future<void> _initializeVideoControllerAtIndex(int index, String url) async {
    final controller = await _createVideoController(url);
    if (!mounted || controller == null) return;

    _videoControllers[index] = controller;
    _videoControllers[index]!.addListener(() {
      final videoController = _videoControllers[index];
      if (videoController == null || !videoController.value.isInitialized) {
        return;
      }

      final hasEnded =
          videoController.value.position >= videoController.value.duration &&
          videoController.value.duration > Duration.zero;
      if (hasEnded && _videoEnded[index] != true) {
        if (mounted) {
          setState(() {
            _videoEnded[index] = true;
          });
        } else {
          _videoEnded[index] = true;
        }
      }
    });

    setState(() {
      _videoInitialized[index] = true;
      _videoEnded[index] = false;
    });

    if (index == _currentIndex) {
      _startProgress();
    }
  }

  Future<VideoPlayerController?> _createVideoController(String url) async {
    try {
      final File cachedFile = await DefaultCacheManager().getSingleFile(url);
      final fileController = VideoPlayerController.file(cachedFile);
      await fileController.initialize();
      return fileController;
    } catch (_) {
      try {
        final networkController = VideoPlayerController.networkUrl(
          Uri.parse(url),
        );
        await networkController.initialize();
        return networkController;
      } catch (_) {
        return null;
      }
    }
  }

  void _precacheStoryImages({int? centerIndex}) {
    if (!mounted) return;
    final targets = <int>{};

    if (centerIndex != null) {
      targets.add(centerIndex);
      if (centerIndex > 0) targets.add(centerIndex - 1);
      if (centerIndex < _playbackItems.length - 1) targets.add(centerIndex + 1);
    } else {
      for (int i = 0; i < _playbackItems.length; i++) {
        targets.add(i);
      }
    }

    for (final index in targets) {
      final story = _playbackItems[index];
      if (_isVideoStoryItem(story)) continue;

      final url = story.mediaUrl.trim();
      if (url.isEmpty || _prefetchedImageUrls.contains(url)) {
        continue;
      }

      _prefetchedImageUrls.add(url);
      final provider = _cachedImageProviders.putIfAbsent(
        url,
        () => CachedNetworkImageProvider(url),
      );
      precacheImage(provider, context);
    }
  }

  void _startProgress() {
    if (!mounted || _playbackItems.isEmpty) return;

    final currentStory = _playbackItems[_currentIndex];
    _videoEnded[_currentIndex] = false;

    if (_isVideoStoryItem(currentStory)) {
      final controller = _videoControllers[_currentIndex];
      if (controller == null || _videoInitialized[_currentIndex] != true) {
        return;
      }

      _progressController.stop();
      _progressController.value = 0.0;
      controller.seekTo(Duration.zero);
      controller.play();
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _progressController.duration = Duration(
      seconds: currentStory.duration > 0 ? currentStory.duration : 5,
    );
    _progressController.reset();
    _progressController.forward().then((_) {
      if (!_isPressed && !_isDragging && mounted) {
        _nextStory();
      }
    });
  }

  void _pauseProgress() {
    if (_progressController.isAnimating) {
      _progressController.stop();
    }

    final currentStory = _playbackItems[_currentIndex];
    if (_isVideoStoryItem(currentStory) &&
        _videoControllers[_currentIndex] != null) {
      _videoControllers[_currentIndex]!.pause();
    }
  }

  void _resumeProgress() {
    if (_isDragging || !mounted || _isPressed) return;

    final currentStory = _playbackItems[_currentIndex];
    if (_isVideoStoryItem(currentStory) &&
        _videoControllers[_currentIndex] != null) {
      _videoControllers[_currentIndex]!.play();
      setState(() {});
      return;
    }

    _progressController.forward().then((_) {
      if (!_isPressed && !_isDragging && mounted) {
        _nextStory();
      }
    });
  }

  void _toggleCurrentVideoPlayback() {
    final currentStory = _playbackItems[_currentIndex];
    if (!_isVideoStoryItem(currentStory)) return;

    final controller = _videoControllers[_currentIndex];
    if (controller == null || _videoInitialized[_currentIndex] != true) return;

    if (controller.value.isPlaying) {
      _pauseProgress();
    } else {
      _resumeProgress();
    }
  }

  void _nextStory() {
    if (_videoControllers[_currentIndex] != null) {
      _videoControllers[_currentIndex]!.pause();
    }

    if (_currentIndex < _playbackItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      GoRouter.of(context).pop();
    }
  }

  void _previousStory() {
    if (_videoControllers[_currentIndex] != null) {
      _videoControllers[_currentIndex]!.pause();
    }

    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _restartCurrentStory();
    }
  }

  void _restartCurrentStory() {
    final currentStory = _playbackItems[_currentIndex];
    if (_isVideoStoryItem(currentStory) &&
        _videoControllers[_currentIndex] != null) {
      _videoControllers[_currentIndex]!.seekTo(Duration.zero);
    }
    _startProgress();
  }

  void _exitStory() {
    for (final controller in _videoControllers.values) {
      controller.pause();
    }
    GoRouter.of(context).pop();
  }

  void _shopNow() {
    GoRouter.of(context).push(
      AppRouter.homeSectionDetails,
      extra: {'title': S.of(context).all, 'section': 'all'},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_playbackItems.isEmpty) {
      return const SafeArea(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: _exitController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _dragDistance),
              child: Transform.scale(
                scale: 1 - (_exitController.value * 0.1),
                child: GestureDetector(
                  onLongPressStart: (_) {
                    setState(() {
                      _isPressed = true;
                    });
                    _pauseProgress();
                  },
                  onLongPressEnd: (_) {
                    setState(() {
                      _isPressed = false;
                    });
                    _resumeProgress();
                  },
                  onTapUp: (details) {
                    if (_isDragging) return;

                    final screenWidth = MediaQuery.of(context).size.width;
                    final tapX = details.globalPosition.dx;
                    final currentStory = _playbackItems[_currentIndex];
                    final centerStart = screenWidth * 0.35;
                    final centerEnd = screenWidth * 0.65;

                    if (_isVideoStoryItem(currentStory) &&
                        tapX >= centerStart &&
                        tapX <= centerEnd) {
                      _toggleCurrentVideoPlayback();
                      return;
                    }

                    if (tapX < screenWidth * 0.5) {
                      _previousStory();
                    } else {
                      _nextStory();
                    }
                  },
                  onPanStart: (_) {
                    setState(() {
                      _isDragging = true;
                    });
                    _pauseProgress();
                  },
                  onPanUpdate: (details) {
                    if (details.delta.dy > 0) {
                      setState(() {
                        _dragDistance += details.delta.dy;
                        _dragDistance = _dragDistance.clamp(0.0, 200.0);
                      });

                      _exitController.value = (_dragDistance / 200.0).clamp(
                        0.0,
                        1.0,
                      );
                    }
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _isDragging = false;
                    });

                    if (_dragDistance > 100) {
                      _exitController.forward().then((_) {
                        _exitStory();
                      });
                    } else {
                      _exitController.reverse();
                      setState(() {
                        _dragDistance = 0;
                      });
                      _resumeProgress();
                    }
                  },
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          if (_videoControllers[_currentIndex] != null) {
                            _videoControllers[_currentIndex]!.pause();
                          }
                          setState(() {
                            _currentIndex = index;
                          });
                          _precacheStoryImages(centerIndex: index);
                          _startProgress();
                        },
                        itemCount: _playbackItems.length,
                        itemBuilder: (context, index) {
                          return _buildStoryContent(
                            _playbackItems[index],
                            index,
                          );
                        },
                      ),
                      _buildProgressBar(),
                      _buildCloseButton(),
                      _buildStoryInfo(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStoryContent(_StoryPlaybackItem story, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: _isVideoStoryItem(story)
            ? _buildVideoPlayer(index, screenWidth, screenHeight)
            : _buildImagePlayer(story, screenWidth, screenHeight),
      ),
    );
  }

  Widget _buildVideoPlayer(int index, double screenWidth, double screenHeight) {
    final videoController = _videoControllers[index];
    final isInitialized = _videoInitialized[index] ?? false;

    if (videoController == null || !isInitialized) {
      return Skeletonizer(
        enabled: true,
        child: Container(
          width: screenWidth,
          height: screenHeight * 0.7,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.rectangle,
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return SizedBox(
      width: screenWidth,
      height: screenHeight * 0.7,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: videoController.value.size.width,
            height: videoController.value.size.height,
            child: VideoPlayer(videoController),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlayer(
    _StoryPlaybackItem story,
    double screenWidth,
    double screenHeight,
  ) {
    final url = story.mediaUrl.trim();
    if (url.isEmpty) {
      return _buildMediaUnavailablePlaceholder(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      );
    }
    final provider = _cachedImageProviders.putIfAbsent(
      url,
      () => CachedNetworkImageProvider(url),
    );

    return Image(
      width: screenWidth,
      height: screenHeight * 0.7,
      image: provider,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Skeletonizer(
          enabled: true,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.rectangle,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: const Color(0xFF161616),
        child: _buildMediaUnavailablePlaceholder(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
      ),
    );
  }

  Widget _buildMediaUnavailablePlaceholder({
    required double screenWidth,
    required double screenHeight,
  }) {
    return Container(
      width: screenWidth,
      height: screenHeight * 0.7,
      color: const Color(0xFF161616),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white.withValues(alpha: 0.9),
              size: 34.w,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Image not available',
            style: AppStyle.styleRegular16(
              context,
            ).copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final currentStory = _playbackItems[_currentIndex];
    final currentVideoController = _videoControllers[_currentIndex];
    final isCurrentVideoReady =
        _isVideoStoryItem(currentStory) &&
        currentVideoController != null &&
        _videoInitialized[_currentIndex] == true;
    final storyCount = _playbackItems
        .map((item) => item.storySequenceIndex)
        .toSet()
        .length;
    final currentStoryIndex = currentStory.storySequenceIndex;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 8,
      right: 8,
      child: Row(
        children: List.generate(
          storyCount,
          (storyIndex) => Expanded(
            child: Container(
              height: 3.h,
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5.r),
                color: Colors.white.withAlpha(76),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1.5.r),
                child: AnimatedBuilder(
                  animation: isCurrentVideoReady
                      ? currentVideoController
                      : _progressController,
                  builder: (context, child) {
                    double value = 0.0;
                    final totalFramesInStory = currentStory.totalFramesInStory;
                    final completedFrames =
                        currentStory.framePositionInStory - 1;

                    if (storyIndex < currentStoryIndex) {
                      value = 1.0;
                    } else if (storyIndex == currentStoryIndex) {
                      double currentFrameProgress = _progressController.value;
                      if (isCurrentVideoReady) {
                        final duration = currentVideoController.value.duration;
                        final position = currentVideoController.value.position;
                        if (duration > Duration.zero) {
                          currentFrameProgress =
                              (position.inMilliseconds /
                                      duration.inMilliseconds)
                                  .clamp(0.0, 1.0);
                        }
                      }
                      value = totalFramesInStory <= 1
                          ? currentFrameProgress
                          : ((completedFrames + currentFrameProgress) /
                                    totalFramesInStory)
                                .clamp(0.0, 1.0);
                    }

                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 40,
      right: 8,
      child: GestureDetector(
        onTap: _exitStory,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildStoryInfo() {
    final currentStory = _playbackItems[_currentIndex];

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentStory.description.isNotEmpty)
            Text(
              currentStory.description,
              style: AppStyle.styleRegular16(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                shadows: const [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _shopNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCB262E),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Shop Now',
                style: AppStyle.styleRegular16(
                  context,
                ).copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_StoryPlaybackItem> _buildPlaybackItems(List<StoriesModel> stories) {
    final items = <_StoryPlaybackItem>[];

    for (int storyIndex = 0; storyIndex < stories.length; storyIndex++) {
      final story = stories[storyIndex];
      final playableFrames = story.frames.where((frame) {
        final frameMediaType = frame.mediaType.trim().isNotEmpty
            ? frame.mediaType.trim()
            : 'image';
        final resolvedUrl = _resolveMediaUrl(
          mediaType: frameMediaType,
          mediaUrl: frame.mediaUrl,
          thumbnailUrl: frame.thumbnailUrl,
        );
        return resolvedUrl.isNotEmpty;
      }).toList();

      for (
        int frameIndex = 0;
        frameIndex < playableFrames.length;
        frameIndex++
      ) {
        final frame = playableFrames[frameIndex];
        final frameMediaType = frame.mediaType.trim().isNotEmpty
            ? frame.mediaType.trim()
            : 'image';
        final resolvedUrl = _resolveMediaUrl(
          mediaType: frameMediaType,
          mediaUrl: frame.mediaUrl,
          thumbnailUrl: frame.thumbnailUrl,
        );

        items.add(
          _StoryPlaybackItem(
            storyId: story.id,
            frameId: frame.id,
            title: story.title,
            description: story.description,
            mediaUrl: resolvedUrl,
            mediaType: frameMediaType,
            duration: frame.duration > 0 ? frame.duration : 5,
            thumbnailUrl: frame.thumbnailUrl.trim(),
            storySequenceIndex: storyIndex,
            framePositionInStory: frameIndex + 1,
            totalFramesInStory: playableFrames.length,
          ),
        );
      }
    }

    return items;
  }

  int _resolveInitialPlaybackIndex(int storyIndex) {
    if (_playbackItems.isEmpty || storyIndex <= 0) {
      return 0;
    }

    int playbackIndex = 0;
    for (int i = 0; i < storyIndex && i < widget.stories.length; i++) {
      playbackIndex += _countPlayableFrames(widget.stories[i]);
    }
    return playbackIndex.clamp(0, _playbackItems.length - 1);
  }

  int _countPlayableFrames(StoriesModel story) {
    int count = 0;
    for (final frame in story.frames) {
      final frameMediaType = frame.mediaType.trim().isNotEmpty
          ? frame.mediaType.trim()
          : 'image';
      final resolvedUrl = _resolveMediaUrl(
        mediaType: frameMediaType,
        mediaUrl: frame.mediaUrl,
        thumbnailUrl: frame.thumbnailUrl,
      );
      if (resolvedUrl.isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  bool _isVideoStoryItem(_StoryPlaybackItem story) {
    return _isVideoMediaType(story.mediaType) || _isVideoUrl(story.mediaUrl);
  }

  bool _isVideoMediaType(String mediaType) {
    return mediaType.trim().toLowerCase() == 'video';
  }

  String _resolveMediaUrl({
    required String mediaType,
    required String mediaUrl,
    required String thumbnailUrl,
  }) {
    final normalizedMediaType = mediaType.trim().toLowerCase();
    final normalizedMediaUrl = mediaUrl.trim();
    final normalizedThumbnailUrl = thumbnailUrl.trim();

    if (normalizedMediaType == 'video') {
      return normalizedMediaUrl;
    }

    if (normalizedMediaUrl.isNotEmpty) {
      return normalizedMediaUrl;
    }
    return normalizedThumbnailUrl;
  }

  bool _isVideoUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;

    final path = Uri.tryParse(trimmed)?.path.toLowerCase() ?? trimmed;
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v') ||
        path.endsWith('.webm') ||
        path.endsWith('.mkv') ||
        path.endsWith('.3gp') ||
        path.endsWith('.avi') ||
        path.endsWith('.mpeg') ||
        path.endsWith('.mpg');
  }
}

class _StoryPlaybackItem {
  const _StoryPlaybackItem({
    required this.storyId,
    required this.frameId,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.mediaType,
    required this.duration,
    required this.thumbnailUrl,
    required this.storySequenceIndex,
    required this.framePositionInStory,
    required this.totalFramesInStory,
  });

  final String storyId;
  final String frameId;
  final String title;
  final String description;
  final String mediaUrl;
  final String mediaType;
  final int duration;
  final String thumbnailUrl;
  final int storySequenceIndex;
  final int framePositionInStory;
  final int totalFramesInStory;
}
