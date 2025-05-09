import 'package:base_flutter_framework/models/content_approval.dart';
import 'package:base_flutter_framework/models/flashcard_item.dart';
import 'package:base_flutter_framework/screens/exercises/create_exercise_screen.dart';
import 'package:base_flutter_framework/screens/exercises/fill_in_the_blank_game.dart';
import 'package:base_flutter_framework/screens/exercises/matching_game.dart';
import 'package:base_flutter_framework/screens/flashcards/flashcard_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/lesson.dart';
import '../../models/learning_progress.dart';
import '../../services/lesson_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/flashcard.dart';
import '../../models/exercise.dart';
import '../../services/flashcard_service.dart';
import '../../services/exercise_service.dart';
import '../../screens/flashcards/create_edit_flashcard_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../exercises/exercise_detail_screen.dart';
import '../../services/analytics_service.dart';
import '../classroom/student_progress_detail_screen.dart';

class LessonDetailScreen extends StatefulWidget {
  final String lessonId;
  final String classroomId;

  const LessonDetailScreen({
    Key? key,
    required this.lessonId,
    required this.classroomId,
  }) : super(key: key);

  @override
  _LessonDetailScreenState createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> with SingleTickerProviderStateMixin {
  final _lessonService = LessonService();
  final _userService = UserService();
  final _auth = auth.FirebaseAuth.instance;
  final _flashcardService = FlashcardService();
  final _analyticsService = AnalyticsService();
  
  late TabController _tabController;
  Lesson? _lesson;
  LearningProgress? _progress;
  bool _isLoading = true;
  bool _isLoadingProgress = true;
  String? _errorMessage;
  bool _isTeacher = false;
  bool _isAdmin = false;
  bool _videoWatched = false;
  bool _flashcardViewed = false;
  bool _exerciseDone = false;
  int _score = 0;
  int _timeSpentSeconds = 0;
  DateTime? _startTime;
  List<FlashcardItem> _flashcardItems = [];
  bool _isCourseClosed = false;
  
  // Video controllers
  Map<String, dynamic> _videoControllers = {};
  int _currentVideoIndex = 0;
  bool _isTracking = false;
  double _videoWatchedPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _startTime = DateTime.now();
    _loadLesson().then((_) {
      if (_lesson?.videos != null && _lesson!.videos.isNotEmpty) {
        _initializeVideoController(_lesson!.videos[_currentVideoIndex].url);
      }
    });
    _checkUserRole();
    _loadLearningProgress();
    _loadFlashcardItems();
    _checkCourseStatus();
  }

  Future<void> _checkCourseStatus() async {
    try {
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.classroomId)
          .get();
      
      if (courseDoc.exists) {
        final courseData = courseDoc.data();
        setState(() {
          _isCourseClosed = courseData?['isClosed'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking course status: $e');
    }
  }

  // Thêm nút chỉnh sửa bài học
  Widget _buildEditButton() {
    if (_isCourseClosed) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, color: Colors.orange.shade900),
            const SizedBox(width: 8),
            Text(
              'Khóa học đã bị khóa',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.edit),
      onPressed: () {
        // Chuyển đến màn hình chỉnh sửa bài học
        Get.toNamed('/lessons/edit', arguments: {
          'lessonId': widget.lessonId,
          'classroomId': widget.classroomId,
        });
      },
    );
  }
  
  @override
  void dispose() {
    // Dispose all video controllers
    _videoControllers.forEach((_, controller) {
      if (controller is YoutubePlayerController) {
        controller.dispose();
      } else if (controller is VideoPlayerController) {
        controller.dispose();
      }
    });
    _videoControllers.clear();
    
    // Lưu thời gian học tập khi thoát
    _updateLearningProgress();
    
    super.dispose();
  }
  
  Future<void> _loadFlashcardItems() async {
    print('Loading flashcard items for lesson: ${widget.lessonId}');
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final flashcardService = FlashcardService();
      final flashcards = await flashcardService.getLessonFlashcards(widget.lessonId);
      print('Found ${flashcards.length} flashcards');

      if (flashcards.isEmpty) {
        print('No flashcards found for lesson, using mock data');
        // Tạo dữ liệu mock
        final mockItems = [
          FlashcardItem(
            flashcardId: 'mock_1',
            question: 'Hello',
            answer: 'Xin chào',
          ),
          FlashcardItem(
            flashcardId: 'mock_2',
            question: 'Good morning',
            answer: 'Chào buổi sáng',
          ),
          FlashcardItem(
            flashcardId: 'mock_3',
            question: 'How are you?',
            answer: 'Bạn khỏe không?',
          ),
          FlashcardItem(
            flashcardId: 'mock_4',
            question: 'Thank you',
            answer: 'Cảm ơn',
          ),
          FlashcardItem(
            flashcardId: 'mock_5',
            question: 'Goodbye',
            answer: 'Tạm biệt',
          ),
          FlashcardItem(
            flashcardId: 'mock_6',
            question: 'Please',
            answer: 'Làm ơn',
          ),
          FlashcardItem(
            flashcardId: 'mock_7',
            question: 'Sorry',
            answer: 'Xin lỗi',
          ),
          FlashcardItem(
            flashcardId: 'mock_8',
            question: 'Yes',
            answer: 'Có',
          ),
          FlashcardItem(
            flashcardId: 'mock_9',
            question: 'No',
            answer: 'Không',
          ),
          FlashcardItem(
            flashcardId: 'mock_10',
            question: 'I love you',
            answer: 'Tôi yêu bạn',
          ),
        ];

        setState(() {
          _flashcardItems = mockItems;
          _isLoading = false;
        });
        return;
      }

      // Lấy tất cả items của các flashcard
      List<FlashcardItem> allItems = [];
      for (var flashcard in flashcards) {
        print('Loading items for flashcard: ${flashcard.id}');
        if (flashcard.id != null) {
          final items = await flashcardService.getFlashcardItems(flashcard.id!);
          print('Found ${items.length} items for flashcard ${flashcard.id}');
          allItems.addAll(items);
        }
      }

      print('Total items loaded: ${allItems.length}');
      setState(() {
        _flashcardItems = allItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading flashcard items: $e');
      setState(() {
        _errorMessage = 'Không thể tải flashcard: ${e.toString()}';
        _isLoading = false;
        _flashcardItems = [];
      });
    }
  }

  // Tính toán thời gian học tập
  int _calculateTimeSpent() {
    if (_startTime == null) return 0;
    final now = DateTime.now();
    final difference = now.difference(_startTime!);
    return difference.inMinutes;
  }
  
  // Cập nhật tiến trình học tập
  Future<void> _updateLearningProgress() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || _lesson == null) return;
      
      // Tính toán thời gian đã học
      final now = DateTime.now();
      final timeDiff = now.difference(_startTime ?? now);
      final minutesSpent = (timeDiff.inSeconds / 60).ceil();
      
      await _lessonService.updateLearningProgress(
        userId: currentUser.uid,
        lessonId: widget.lessonId,
        classroomId: widget.classroomId,
        videoWatched: _videoWatched,
        flashcardViewed: _flashcardViewed,
        exerciseDone: _exerciseDone,
        timeSpentMinutes: minutesSpent,
      );
      
      // Tải lại tiến trình mới
      _loadLearningProgress();
    } catch (e) {
      print('Error updating learning progress: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật tiến độ học tập: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // Tải thông tin bài học
  Future<void> _loadLesson() async {
    try {
      setState(() => _isLoading = true);
      
      final lesson = await _lessonService.getLessonById(widget.lessonId);
      
      if (lesson == null) {
        throw 'Không tìm thấy bài học';
      }
      
      if (!mounted) return;

      setState(() {
        _lesson = lesson;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      print('Error loading lesson: $e');
    }
  }
  
  Future<void> _checkUserRole() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      
      // Kiểm tra vai trò người dùng
      final userDoc = await _userService.getUserById(currentUser.uid);
      if (userDoc != null) {
        // Kiểm tra nếu là admin
        if (userDoc.roleId == 'admin') {
          setState(() {
            _isAdmin = true;
            _isTeacher = true; // Admin có tất cả quyền của teacher
          });
          return; // Không cần kiểm tra thêm nếu là admin
        }
        
        // Kiểm tra nếu là giáo viên của lớp học này
        if (userDoc.roleId == 'teacher') {
          setState(() => _isTeacher = true);
        }
      }
    } catch (e) {
      print('Error checking user role: $e');
    }
  }
  
  Future<void> _loadLearningProgress() async {
    try {
      setState(() => _isLoadingProgress = true);
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() => _isLoadingProgress = false);
        return;
      }
      
      final progress = await _lessonService.getLearningProgress(
        currentUser.uid,
        widget.lessonId,
        widget.classroomId
      );
      
      if (!mounted) return;
      
      setState(() {
        _progress = progress;
        if (progress != null) {
          _videoWatched = progress.completedItemIds['video'] ?? false;
          _flashcardViewed = progress.completedItemIds['flashcards'] ?? false;
          _exerciseDone = progress.completedItemIds['exercises'] ?? false;
        }
        _isLoadingProgress = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoadingProgress = false);
      print('Error loading learning progress: $e');
    }
  }
  
  // Khởi tạo video controller
  void _initializeVideoController(String url) async {
    try {
      print('Initializing video controller with URL: $url');
      
      // Nếu controller cho URL này đã tồn tại và vẫn hoạt động, không khởi tạo lại
      if (_videoControllers.containsKey(url)) {
        if (_videoControllers[url] is YoutubePlayerController) {
          final controller = _videoControllers[url] as YoutubePlayerController;
          if (controller.value.isReady) {
            print('Reusing existing YouTube controller');
            return;
          }
        } else if (_videoControllers[url] is VideoPlayerController) {
          final controller = _videoControllers[url] as VideoPlayerController;
          if (controller.value.isInitialized) {
            print('Reusing existing video controller');
            return;
          }
        }
      }
      
      // Dispose existing controllers first
      if (_videoControllers.containsKey(url)) {
        if (_videoControllers[url] is YoutubePlayerController) {
          (_videoControllers[url] as YoutubePlayerController).dispose();
        } else if (_videoControllers[url] is VideoPlayerController) {
          (_videoControllers[url] as VideoPlayerController).dispose();
        }
        _videoControllers.remove(url);
      }
      
      // Loại bỏ ký tự @ nếu có ở đầu URL
      url = url.startsWith('@') ? url.substring(1) : url;
      print('URL after removing @ (if any): $url');
      
      // Kiểm tra nếu là YouTube video
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        print('Detected YouTube video URL');
        
        // Tách lấy video ID, bỏ qua các tham số khác như playlist
        String? videoId;
        if (url.contains('youtube.com/watch')) {
          videoId = Uri.parse(url).queryParameters['v'];
          print('Extracted video ID from standard YouTube URL: $videoId');
        } else if (url.contains('youtu.be/')) {
          videoId = url.split('youtu.be/')[1].split('?')[0];
          print('Extracted video ID from short YouTube URL: $videoId');
        }
        
        if (videoId != null && videoId.isNotEmpty) {
          print('Initializing YouTube player with video ID: $videoId');
          
          _videoControllers[url] = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              showLiveFullscreenButton: false,
            ),
          );
          
          // Thêm listener để tracking tiến trình xem video
          (_videoControllers[url] as YoutubePlayerController).addListener(() {
            final playerValue = (_videoControllers[url] as YoutubePlayerController).value;
            if (playerValue.isReady) {
              // Chỉ track khi video đang chạy
              if (playerValue.isPlaying && !_isTracking && _lesson != null) {
                _startVideoTracking();
              }
              
              // Tính toán phần trăm đã xem
              if (playerValue.position.inSeconds > 0 && playerValue.metaData.duration.inSeconds > 0) {
                final percentage = playerValue.position.inSeconds / playerValue.metaData.duration.inSeconds;
                
                // Cập nhật trạng thái phần trăm đã xem
                setState(() {
                  _videoWatchedPercentage = percentage;
                });
                
                // Tự động đánh dấu hoàn thành khi đạt 80%
                if (percentage >= 0.8 && !_videoWatched) {
                  setState(() {
                    _videoWatched = true;
                  });
                  _updateLearningProgress();
                  _logVideoActivity(
                    videoId: videoId ?? '', 
                    videoTitle: _lesson!.videos[_currentVideoIndex].title ?? 'Unknown',
                    isCompleted: true,
                    watchedPercentage: percentage
                  );
                }
                
                // Log hoạt động mỗi 10% xem
                if ((percentage * 10).floor() > (_videoWatchedPercentage * 10).floor()) {
                  _logVideoActivity(
                    videoId: videoId ?? '', 
                    videoTitle: _lesson!.videos[_currentVideoIndex].title ?? 'Unknown',
                    isCompleted: false,
                    watchedPercentage: percentage
                  );
                }
              }
            }
          });
          
          setState(() {
            _videoControllers[url] = _videoControllers[url];
          }); // Trigger rebuild to show video player
        } else {
          print('Could not extract YouTube video ID from URL: $url');
          throw Exception('URL YouTube không hợp lệ');
        }
      } else {
        print('Detected direct video URL, initializing video player');
        
        _videoControllers[url] = VideoPlayerController.network(url);
        
        (_videoControllers[url] as VideoPlayerController).initialize().then((_) {
          print('Video player initialized successfully');
          if (mounted) {
            setState(() {
              _videoControllers[url] = _videoControllers[url];
            }); // Trigger rebuild to show video player
            
            // Thêm listener để tracking tiến trình xem video
            (_videoControllers[url] as VideoPlayerController).addListener(() {
              final controller = _videoControllers[url] as VideoPlayerController;
              
              // Chỉ track khi video đang chạy
              if (controller.value.isPlaying && !_isTracking && _lesson != null) {
                _startVideoTracking();
              }
              
              // Tính toán phần trăm đã xem
              if (controller.value.position.inSeconds > 0 && controller.value.duration.inSeconds > 0) {
                final percentage = controller.value.position.inSeconds / controller.value.duration.inSeconds;
                
                // Cập nhật trạng thái phần trăm đã xem
                setState(() {
                  _videoWatchedPercentage = percentage;
                });
                
                // Tự động đánh dấu hoàn thành khi đạt 80%
                if (percentage >= 0.8 && !_videoWatched) {
                  setState(() {
                    _videoWatched = true;
                  });
                  _updateLearningProgress();
                  _logVideoActivity(
                    videoId: url, 
                    videoTitle: _lesson!.videos[_currentVideoIndex].title ?? 'Unknown',
                    isCompleted: true,
                    watchedPercentage: percentage
                  );
                }
                
                // Log hoạt động mỗi 10% xem
                if ((percentage * 10).floor() > (_videoWatchedPercentage * 10).floor()) {
                  _logVideoActivity(
                    videoId: url, 
                    videoTitle: _lesson!.videos[_currentVideoIndex].title ?? 'Unknown',
                    isCompleted: false,
                    watchedPercentage: percentage
                  );
                }
              }
            });
          }
        }).catchError((error) {
          print('Error initializing video player: $error');
          throw Exception('Không thể tải video: $error');
        });
      }
    } catch (e) {
      print('Error in _initializeVideoController: $e');
      
      // Reset controllers
      _videoControllers.forEach((_, controller) {
        if (controller is YoutubePlayerController) {
          controller.dispose();
        } else if (controller is VideoPlayerController) {
          controller.dispose();
        }
      });
      _videoControllers.clear();
      
      setState(() {
        _videoControllers.clear();
      });
      
      throw Exception('Không thể tải video: $e');
    }
  }
  
  // Track video viewing session
  void _startVideoTracking() {
    setState(() {
      _isTracking = true;
    });
    
    // Log bắt đầu xem video
    if (_lesson != null && _currentVideoIndex < _lesson!.videos.length) {
      final videoId = _lesson!.videos[_currentVideoIndex].url.contains('youtube')
          ? _extractYouTubeVideoId(_lesson!.videos[_currentVideoIndex].url)
          : _lesson!.videos[_currentVideoIndex].url;
      
      _logVideoActivity(
        videoId: videoId, 
        videoTitle: _lesson!.videos[_currentVideoIndex].title ?? 'Unknown',
        isCompleted: false,
        watchedPercentage: 0.0,
        action: 'start_watching'
      );
    }
  }
  
  // Extract YouTube video ID
  String _extractYouTubeVideoId(String url) {
    if (url.contains('youtube.com/watch')) {
      return Uri.parse(url).queryParameters['v'] ?? url;
    } else if (url.contains('youtu.be/')) {
      return url.split('youtu.be/')[1].split('?')[0];
    }
    return url;
  }
  
  // Log video activity to firestore
  void _logVideoActivity({
    required String videoId,
    required String videoTitle,
    required bool isCompleted,
    required double watchedPercentage,
    String action = 'progress_update'
  }) {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _lesson == null) return;
    
    _analyticsService.trackVideoActivity(
      userId: currentUser.uid,
      lessonId: widget.lessonId,
      classroomId: widget.classroomId,
      videoId: videoId,
      videoTitle: videoTitle,
      action: action,
      isCompleted: isCompleted,
      watchedPercentage: watchedPercentage,
      timestamp: DateTime.now(),
    );
  }
  
  // Đánh dấu đã xem video
  void _toggleVideoWatched() {
    setState(() {
      _videoWatched = !_videoWatched;
    });
    _updateLearningProgress();
  }
  
  // Đánh dấu đã xem flashcard
  void _toggleFlashcardViewed() {
    setState(() {
      _flashcardViewed = !_flashcardViewed;
    });
    _updateLearningProgress();
  }
  
  // Đánh dấu đã làm bài tập
  void _toggleExerciseDone() {
    setState(() {
      _exerciseDone = !_exerciseDone;
    });
    _updateLearningProgress();
  }
  
  // Kiểm tra tiến trình
  bool _isLessonCompleted() {
    if (_lesson == null) return false;
    
    bool hasVideo = _lesson!.videos.isNotEmpty;
    bool hasFlashcards = _lesson!.flashcardIds.isNotEmpty;
    bool hasExercises = _lesson!.exerciseIds.isNotEmpty;
    
    // Nếu không có thành phần nào, coi như đã hoàn thành
    if (!hasVideo && !hasFlashcards && !hasExercises) return true;
    
    // Kiểm tra từng thành phần
    bool videoCompleted = !hasVideo || _videoWatched;
    bool flashcardsCompleted = !hasFlashcards || _flashcardViewed;
    bool exercisesCompleted = !hasExercises || _exerciseDone;
    
    return videoCompleted && flashcardsCompleted && exercisesCompleted;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading || _lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết bài học')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson!.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.video_library),
              child: const Text('Video'),
            ),
            Tab(
              icon: Icon(Icons.style),
              child: const Text('Flashcard'),
            ),
            Tab(
              icon: Icon(Icons.assignment),
              child: const Text('Bài tập'),
            ),
            Tab(
              icon: Icon(Icons.fitness_center),
              child: const Text('Luyện tập'),
            ),
          ],
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: _showApprovalOptions,
              tooltip: 'Quản lý phê duyệt',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                _showReportContentDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Báo cáo nội dung'),
                  ],
                ),
              ),
            ],
          ),
          if (_lesson != null && _isAdmin) _buildEditButton(),
        ],
      ),
      body: Column(
        children: [
          // Status indicator for teachers and admins
          if (_isTeacher || _isAdmin)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getApprovalStatusColor(_lesson!.approvalStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getApprovalStatusIcon(_lesson!.approvalStatus),
                    color: _getApprovalStatusColor(_lesson!.approvalStatus),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trạng thái: ${_lesson!.approvalStatus.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getApprovalStatusColor(_lesson!.approvalStatus),
                        ),
                      ),
                      if (_lesson!.rejectionReason != null)
                        Text(
                          'Lý do: ${_lesson!.rejectionReason}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Video Tab
                _buildVideoTab(),
                
                // Flashcard Tab
                _buildFlashcardTab(),
                
                // Exercise Tab
                _buildExerciseTab(),
                
                // Practice Tab
                _buildPracticeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrackingItem(String title, IconData icon, Color color, bool isChecked, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Checkbox(
            value: isChecked,
            onChanged: (value) => onToggle(),
            activeColor: Colors.indigo.shade700,
          ),
        ],
      ),
    );
  }
  
  Widget _buildFolderCard(LessonFolder folder, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.folder, color: Colors.amber),
        title: Text(
          folder.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          folder.description ?? '${folder.items.length} nội dung',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          if (folder.items.isEmpty)
            const ListTile(
              title: Text('Chưa có nội dung'),
              subtitle: Text('Thư mục này hiện chưa có nội dung'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: folder.items.length,
              itemBuilder: (context, itemIndex) {
                final item = folder.items[itemIndex];
                return _buildLessonItemTile(item);
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildLessonItemTile(LessonItem item) {
    IconData icon;
    Color color;
    
    switch (item.type) {
      case LessonItemType.document:
        icon = Icons.description;
        color = Colors.blue;
        break;
      case LessonItemType.exercise:
        icon = Icons.assignment;
        color = Colors.green;
        break;
      case LessonItemType.vocabulary:
        icon = Icons.menu_book;
        color = Colors.purple;
        break;
      case LessonItemType.video:
        icon = Icons.videocam;
        color = Colors.red;
        break;
      case LessonItemType.audio:
        icon = Icons.audiotrack;
        color = Colors.orange;
        break;
      case LessonItemType.quiz:
        icon = Icons.quiz;
        color = Colors.teal;
        break;
    }
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(item.title),
      subtitle: item.description != null ? Text(
        item.description!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ) : null,
      trailing: item.materialId != null ? const Icon(Icons.open_in_new) : null,
      onTap: item.materialId != null ? () {
        // TODO: Open material
        Get.snackbar(
          'Thông báo',
          'Tính năng đang phát triển',
          snackPosition: SnackPosition.BOTTOM,
        );
      } : null,
    );
  }
  
  void _showApprovalOptions() {
    if (!_isAdmin || _lesson == null) return;
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getApprovalStatusColor(_lesson!.approvalStatus).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getApprovalStatusIcon(_lesson!.approvalStatus),
                    color: _getApprovalStatusColor(_lesson!.approvalStatus),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trạng thái hiện tại: ${_lesson!.approvalStatus.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getApprovalStatusColor(_lesson!.approvalStatus),
                        ),
                      ),
                      if (_lesson!.rejectionReason != null)
                        Text(
                          'Lý do: ${_lesson!.rejectionReason}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            
            // Phê duyệt
            if (_lesson!.approvalStatus != ApprovalStatus.approved)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Phê duyệt'),
                subtitle: const Text('Cho phép hiển thị với học viên'),
                onTap: () {
                  Get.back();
                  _approveLesson();
                },
              ),
            
            // Từ chối
            if (_lesson!.approvalStatus != ApprovalStatus.rejected)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Từ chối'),
                subtitle: const Text('Không cho phép hiển thị'),
                onTap: () {
                  Get.back();
                  _showRejectDialog();
                },
              ),
            
            // Yêu cầu chỉnh sửa
            if (_lesson!.approvalStatus != ApprovalStatus.revising)
              ListTile(
                leading: const Icon(Icons.edit_note, color: Colors.blue),
                title: const Text('Yêu cầu chỉnh sửa'),
                subtitle: const Text('Gửi yêu cầu chỉnh sửa cho giáo viên'),
                onTap: () {
                  Get.back();
                  _showRevisionDialog();
                },
              ),
            
            // Xem lịch sử phê duyệt
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Lịch sử phê duyệt'),
              onTap: () {
                Get.back();
                _showApprovalHistory();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _approveLesson() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'Vui lòng đăng nhập';
      }
      
      await _lessonService.approveLesson(
        lessonId: widget.lessonId,
        adminId: currentUser.uid,
      );
      
      Get.snackbar(
        'Thành công',
        'Đã phê duyệt bài học',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      _loadLesson();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể phê duyệt bài học: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  void _showRejectDialog() {
    final reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Từ chối bài học'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng cung cấp lý do từ chối:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do',
                hintText: 'Nhập lý do từ chối bài học',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập lý do từ chối',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              Get.back();
              
              try {
                final currentUser = _auth.currentUser;
                if (currentUser == null) {
                  throw 'Vui lòng đăng nhập';
                }
                
                await _lessonService.rejectLesson(
                  lessonId: widget.lessonId,
                  adminId: currentUser.uid,
                  reason: reasonController.text.trim(),
                );
                
                Get.snackbar(
                  'Thành công',
                  'Đã từ chối bài học',
                  snackPosition: SnackPosition.BOTTOM,
                );
                
                _loadLesson();
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Không thể từ chối bài học: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }
  
  void _showRevisionDialog() {
    final reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Yêu cầu chỉnh sửa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng cung cấp yêu cầu chỉnh sửa:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Yêu cầu',
                hintText: 'Nhập yêu cầu chỉnh sửa',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập yêu cầu chỉnh sửa',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              Get.back();
              
              try {
                final currentUser = _auth.currentUser;
                if (currentUser == null) {
                  throw 'Vui lòng đăng nhập';
                }
                
                await _lessonService.requestRevision(
                  lessonId: widget.lessonId,
                  adminId: currentUser.uid,
                  reason: reasonController.text.trim(),
                );
                
                Get.snackbar(
                  'Thành công',
                  'Đã gửi yêu cầu chỉnh sửa',
                  snackPosition: SnackPosition.BOTTOM,
                );
                
                _loadLesson();
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Không thể gửi yêu cầu chỉnh sửa: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showApprovalHistory() async {
    try {
      // Hiển thị dialog loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );
      
      // Lấy lịch sử phê duyệt
      final historyList = await _lessonService.getApprovalHistoryWithUserInfo(widget.lessonId);
      
      // Đóng dialog loading
      Get.back();
      
      if (historyList.isEmpty) {
        Get.snackbar(
          'Thông báo',
          'Không có lịch sử phê duyệt',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      // Hiển thị lịch sử phê duyệt
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lịch sử phê duyệt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: historyList.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final history = historyList[index];
                      final status = history['status'] as ApprovalStatus;
                      final timestamp = history['timestamp'] as Timestamp?;
                      final date = timestamp?.toDate() ?? DateTime.now();
                      
                      return ListTile(
                        leading: Icon(
                          _getApprovalStatusIcon(status),
                          color: _getApprovalStatusColor(status),
                        ),
                        title: Text(
                          status.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getApprovalStatusColor(status),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Người duyệt: ${history['adminName']}'),
                            Text('Thời gian: ${_formatDate(date)}'),
                            if (history['reason'] != null)
                              Text('Lý do: ${history['reason']}'),
                          ],
                        ),
                        isThreeLine: history['reason'] != null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Đóng'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      // Đóng dialog loading nếu có lỗi
      Get.back();
      
      Get.snackbar(
        'Lỗi',
        'Không thể tải lịch sử phê duyệt: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  void _showReportContentDialog() {
    final reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Báo cáo nội dung'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng cho biết lý do bạn báo cáo nội dung này:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do',
                hintText: 'Nhập lý do báo cáo',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập lý do báo cáo',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              Get.back();
              
              try {
                final currentUser = _auth.currentUser;
                if (currentUser == null) {
                  throw 'Vui lòng đăng nhập';
                }
                
                await _lessonService.reportInappropriateContent(
                  lessonId: widget.lessonId,
                  userId: currentUser.uid,
                  reason: reasonController.text.trim(),
                );
                
                Get.snackbar(
                  'Thành công',
                  'Đã gửi báo cáo của bạn. Chúng tôi sẽ xem xét sớm.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Không thể gửi báo cáo: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Báo cáo'),
          ),
        ],
      ),
    );
  }
  
  // Helper methods for approval status
  IconData _getApprovalStatusIcon(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return Icons.pending;
      case ApprovalStatus.approved:
        return Icons.check_circle;
      case ApprovalStatus.rejected:
        return Icons.cancel;
      case ApprovalStatus.revising:
        return Icons.edit_note;
      default:
        return Icons.pending;
    }
  }
  
  Color _getApprovalStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return Colors.orange;
      case ApprovalStatus.approved:
        return Colors.green;
      case ApprovalStatus.rejected:
        return Colors.red;
      case ApprovalStatus.revising:
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  // Build video tab content
  Widget _buildVideoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lesson!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _lesson!.description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
                if (_lesson!.estimatedMinutes > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 20,
                        color: Colors.indigo.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Thời gian học: ${_lesson!.estimatedMinutes} phút',
                        style: TextStyle(
                          color: Colors.indigo.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Video section - Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Video bài giảng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
              if (_isTeacher && _isCourseClosed || _isAdmin && _isCourseClosed)
                ElevatedButton.icon(
                  onPressed: _showAddVideoDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm video'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Video section
          if (_lesson!.videos.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.videocam_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Bài học này chưa có video',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  if (_isTeacher || _isAdmin) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddVideoDialog,
                      icon: const Icon(Icons.video_call_outlined),
                      label: const Text('Thêm video bài giảng'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Playing current video
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current video title and description
                  Text(
                    _lesson!.videos[_currentVideoIndex].title ?? 'Video bài giảng',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_lesson!.videos[_currentVideoIndex].description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _lesson!.videos[_currentVideoIndex].description!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // Current video player
                  if (_videoControllers[_lesson!.videos[_currentVideoIndex].url] != null) ...[
                    if (_videoControllers[_lesson!.videos[_currentVideoIndex].url] is YoutubePlayerController)
                      YoutubePlayer(
                        controller: _videoControllers[_lesson!.videos[_currentVideoIndex].url],
                        showVideoProgressIndicator: true,
                        onReady: () {
                          print('YouTube player ready');
                        },
                        onEnded: (metaData) {
                          setState(() {
                            _videoWatched = true;
                            _videoWatchedPercentage = 1.0;
                          });
                          _updateLearningProgress();
                          
                          final videoId = _extractYouTubeVideoId(_lesson!.videos[_currentVideoIndex].url);
                          _logVideoActivity(
                            videoId: videoId,
                            videoTitle: _lesson!.videos[_currentVideoIndex].title ?? 'Unknown',
                            isCompleted: true,
                            watchedPercentage: 1.0,
                            action: 'finished_watching'
                          );
                        },
                        progressIndicatorColor: Colors.red,
                        progressColors: const ProgressBarColors(
                          playedColor: Colors.red,
                          handleColor: Colors.redAccent,
                        ),
                      )
                    else if (_videoControllers[_lesson!.videos[_currentVideoIndex].url] is VideoPlayerController &&
                            (_videoControllers[_lesson!.videos[_currentVideoIndex].url] as VideoPlayerController).value.isInitialized)
                      AspectRatio(
                        aspectRatio: (_videoControllers[_lesson!.videos[_currentVideoIndex].url] as VideoPlayerController).value.aspectRatio,
                        child: VideoPlayer(_videoControllers[_lesson!.videos[_currentVideoIndex].url]),
                      )
                    else
                      const Center(child: CircularProgressIndicator()),
                  ] else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'Không thể tải video',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isTeacher || _isAdmin) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _initializeVideoController(_lesson!.videos[_currentVideoIndex].url),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                          ),
                          TextButton.icon(
                            onPressed: () => _showDeleteVideoDialog(_currentVideoIndex),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Xóa video này', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            
            // List of videos
            if (_lesson!.videos.length > 1) ...[
              const SizedBox(height: 24),
              Text(
                'Danh sách video',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade700,
                ),
              ),
              const SizedBox(height: 12),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lesson!.videos.length,
                itemBuilder: (context, index) {
                  final video = _lesson!.videos[index];
                  final isCurrentVideo = _currentVideoIndex == index;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: isCurrentVideo 
                        ? BorderSide(color: Colors.indigo.shade300, width: 2)
                        : BorderSide.none,
                    ),
                    elevation: isCurrentVideo ? 3 : 1,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isCurrentVideo 
                          ? Colors.indigo.shade100 
                          : Colors.grey.shade200,
                        child: Icon(
                          video.url.contains('youtube') 
                            ? Icons.play_circle_fill 
                            : Icons.videocam,
                          color: isCurrentVideo 
                            ? Colors.indigo 
                            : Colors.grey.shade700,
                        ),
                      ),
                      title: Text(
                        video.title ?? 'Video ${index + 1}',
                        style: TextStyle(
                          fontWeight: isCurrentVideo 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        ),
                      ),
                      subtitle: video.description != null 
                        ? Text(
                            video.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCurrentVideo)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Đang phát',
                                style: TextStyle(
                                  color: Colors.indigo,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (_isTeacher || _isAdmin) ...[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditVideoDialog(index),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Sửa thông tin video',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteVideoDialog(index),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Xóa video',
                            ),
                          ]
                        ],
                      ),
                      onTap: () {
                        if (!isCurrentVideo) {
                          setState(() {
                            _currentVideoIndex = index;
                          });
                          _initializeVideoController(video.url);
                        }
                      },
                    ),
                  );
                },
              ),
            ],
          ],
          
          const SizedBox(height: 24),
          
          // Learning progress
          if (!_isLoadingProgress && !_isTeacher)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tiến độ học tập',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_progress != null)
                        Text(
                          '${_progress!.progressPercent.toInt()}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _progress != null ? _progress!.progressPercent / 100 : 0.0,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade700),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Folders
          if (_lesson!.folders.isNotEmpty) ...[
            Text(
              'Nội dung bài học',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade700,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lesson!.folders.length,
              itemBuilder: (context, index) {
                final folder = _lesson!.folders[index];
                return _buildFolderCard(folder, index);
              },
            ),
          ],
          
          // Add progress indicator in the video section
          if (!_isLoadingProgress && _videoWatchedPercentage > 0 && _videoWatchedPercentage < 1.0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _videoWatchedPercentage,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _videoWatchedPercentage >= 0.8 ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_videoWatchedPercentage * 100).toInt()}%',
                  style: TextStyle(
                    color: _videoWatchedPercentage >= 0.8 ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  // Build flashcard tab content
  Widget _buildFlashcardTab() {
    return FutureBuilder<List<Flashcard>>(
      future: _flashcardService.getLessonFlashcards(widget.lessonId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Lỗi: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        
        final flashcards = snapshot.data ?? [];
        
        if (flashcards.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isTeacher || _isAdmin) ...[
                  Icon(Icons.style, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Thêm thẻ ghi nhớ vào bài học',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Giúp học sinh học từ vựng hiệu quả hơn',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isCourseClosed)
                    ElevatedButton.icon(
                      onPressed: _showAddFlashcardDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm thẻ ghi nhớ'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                ] else ...[
                  Icon(Icons.style, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Bài học này chưa có thẻ ghi nhớ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: flashcards.length + (_isTeacher || _isAdmin ? 1 : 0),
          itemBuilder: (context, index) {
            if ((_isTeacher || _isAdmin) && index == 0) {
              // Add button at the top for teachers and admins
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: _showAddFlashcardDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm thẻ ghi nhớ'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              );
            }
            
            final actualIndex = (_isTeacher || _isAdmin) ? index - 1 : index;
            final flashcard = flashcards[actualIndex];
            
            // Hiển thị tất cả flashcard cho giáo viên và admin
            // Chỉ hiển thị flashcard đã được phê duyệt cho học sinh
            if (!_isTeacher && !_isAdmin && flashcard.approvalStatus != ApprovalStatus.approved) {
              return const SizedBox.shrink();
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  // Navigate to flashcard detail screen
                  Get.to(() => FlashcardDetailScreen(flashcardId: flashcard.id ?? ''));
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              flashcard.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (_isTeacher || _isAdmin)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getApprovalStatusColor(flashcard.approvalStatus).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getApprovalStatusColor(flashcard.approvalStatus),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getApprovalStatusIcon(flashcard.approvalStatus),
                                        color: _getApprovalStatusColor(flashcard.approvalStatus),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        flashcard.approvalStatus.name,
                                        style: TextStyle(
                                          color: _getApprovalStatusColor(flashcard.approvalStatus),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isCourseClosed)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _showDeleteFlashcardDialog(flashcard),
                                    tooltip: 'Xóa thẻ ghi nhớ',
                                  ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        flashcard.description,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (flashcard.approvalStatus == ApprovalStatus.pending && (_isTeacher || _isAdmin))
                        Text(
                          'Đang chờ phê duyệt. Học sinh sẽ không thấy thẻ này cho đến khi được duyệt.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Build exercise tab content
  Widget _buildExerciseTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lesson == null) {
      return const Center(child: Text('Không tìm thấy thông tin bài học'));
    }

    if (_isTeacher || _isAdmin) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh sách bài tập',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isCourseClosed)
                  ElevatedButton.icon(
                    onPressed: _showAddExerciseDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm bài tập'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Exercise>>(
              future: ExerciseService().getExercisesByLesson(_lesson!.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Không thể tải danh sách bài tập: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }

                final exercises = snapshot.data ?? [];
                if (exercises.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Bài học này chưa có bài tập',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(exercise.title),
                        subtitle: exercise.description != null
                            ? Text(exercise.description!)
                            : null,
                        trailing: Text('${exercise.questions.length} câu hỏi'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseDetailScreen(
                                exerciseId: exercise.id!,
                                lessonId: _lesson!.id!,
                                classroomId: _lesson!.classroomId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    } else {
      return FutureBuilder<List<Exercise>>(
        future: ExerciseService().getExercisesByLesson(_lesson!.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Không thể tải danh sách bài tập: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          final exercises = snapshot.data ?? [];
          if (exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Bài học này chưa có bài tập',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(exercise.title),
                  subtitle: exercise.description != null
                      ? Text(exercise.description!)
                      : null,
                  trailing: Text('${exercise.questions.length} câu hỏi'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseDetailScreen(
                          exerciseId: exercise.id!,
                          lessonId: _lesson!.id!,
                          classroomId: _lesson!.classroomId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    }
  }
  
  // Show dialog to add video
  void _showAddVideoDialog() {
    final videoUrlController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    bool isUploadingFile = false;
    String? selectedFilePath;
    
    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm video bài giảng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tab chọn kiểu thêm video
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() {
                          isUploadingFile = false;
                          selectedFilePath = null;
                        }),
                        icon: const Icon(Icons.link),
                        label: const Text('URL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !isUploadingFile ? Colors.indigo : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() {
                          isUploadingFile = true;
                          videoUrlController.clear();
                        }),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Tải lên'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUploadingFile ? Colors.indigo : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Form fields for title and description
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề video',
                    hintText: 'Nhập tiêu đề video',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả video',
                    hintText: 'Nhập mô tả ngắn về nội dung video',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                // URL or file upload section
                if (!isUploadingFile) ...[
                  const Text('Nhập URL video bài giảng (YouTube hoặc video trực tiếp):'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: videoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL Video',
                      hintText: 'https://youtube.com/...',
                    ),
                  ),
                ] else ...[
                  if (selectedFilePath != null)
                    Text(
                      'File đã chọn: ${selectedFilePath!.split('/').last}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  else
                    const Text('Chọn file video từ máy của bạn:'),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Sử dụng ImagePicker thay vì FilePicker
                      final ImagePicker picker = ImagePicker();
                      final XFile? video = await picker.pickVideo(
                        source: ImageSource.gallery,
                        maxDuration: const Duration(minutes: 10), // Giới hạn thời lượng video
                      );
                      
                      if (video != null) {
                        setState(() {
                          selectedFilePath = video.path;
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(selectedFilePath != null ? 'Chọn file khác' : 'Chọn file'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate input
                if (titleController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Lỗi',
                    'Vui lòng nhập tiêu đề video',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                
                if (!isUploadingFile && videoUrlController.text.trim().isEmpty) {
                  Get.snackbar(
                    'Lỗi',
                    'Vui lòng nhập URL video',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                
                if (isUploadingFile && selectedFilePath == null) {
                  Get.snackbar(
                    'Lỗi',
                    'Vui lòng chọn file video',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                
                Get.back();
                
                try {
                  String videoUrl;
                  
                  if (isUploadingFile) {
                    // Kiểm tra kích thước file
                    final file = File(selectedFilePath!);
                    final fileSize = await file.length();
                    final fileSizeInMB = fileSize / (1024 * 1024);
                    
                    if (fileSizeInMB > 50) {
                      throw 'Video quá lớn. Vui lòng chọn video nhỏ hơn 50MB';
                    }
                    
                    // Show loading dialog
                    Get.dialog(
                      const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false,
                    );
                    
                    try {
                      // Upload file to storage
                      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
                      final storageRef = FirebaseStorage.instance.ref().child('videos/$fileName');
                      
                      // Upload với metadata
                      final metadata = SettableMetadata(
                        contentType: 'video/mp4',
                        customMetadata: {'userId': _auth.currentUser?.uid ?? ''},
                      );
                      
                      // Upload file
                      await storageRef.putFile(file, metadata);
                      videoUrl = await storageRef.getDownloadURL();
                    } catch (uploadError) {
                      print('Error uploading video: $uploadError');
                      // Đóng dialog loading
                      Get.back();
                      
                      String errorMessage = 'Lỗi khi tải video lên';
                      if (uploadError.toString().contains('permission') || 
                          uploadError.toString().contains('Permission denied') ||
                          uploadError.toString().contains('unauthorized')) {
                        errorMessage = 'Không có quyền tải video lên. Vui lòng kiểm tra quyền truy cập Firebase Storage.';
                      } else if (uploadError.toString().contains('network')) {
                        errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
                      } else if (uploadError.toString().contains('cancelled')) {
                        errorMessage = 'Quá trình tải lên đã bị hủy.';
                      } else {
                        errorMessage = 'Lỗi: ${uploadError.toString()}';
                      }
                      
                      throw errorMessage;
                    }
                    
                    // Đóng dialog loading
                    Get.back();
                  } else {
                    videoUrl = videoUrlController.text.trim();
                  }
                  
                  // Lấy bài học hiện tại
                  final lesson = await _lessonService.getLessonById(widget.lessonId);
                  if (lesson == null) {
                    throw 'Bài học không tồn tại';
                  }
                  
                  // Tạo VideoItem mới
                  final videoItem = VideoItem(
                    url: videoUrl,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim().isNotEmpty 
                        ? descriptionController.text.trim() 
                        : null,
                  );
                  
                  // Cập nhật danh sách video
                  final updatedLesson = lesson.copyWith(
                    videos: List<VideoItem>.from(lesson.videos)..add(videoItem),
                    updatedAt: Timestamp.now(),
                  );
                  
                  await _lessonService.updateLesson(widget.lessonId, updatedLesson);
                  
                  Get.snackbar(
                    'Thành công',
                    'Đã thêm video bài giảng',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  
                  // Tải lại dữ liệu bài học
                  _loadLesson();
                  
                } catch (e) {
                  Get.snackbar(
                    'Lỗi',
                    e.toString(),
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 5),
                    mainButton: TextButton(
                      onPressed: _showAddVideoDialog,
                      child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                    ),
                  );
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Show dialog to add flashcard
  void _showAddFlashcardDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Thêm thẻ ghi nhớ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên bộ thẻ',
                hintText: 'Nhập tên bộ thẻ ghi nhớ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Nhập mô tả ngắn gọn',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập tên bộ thẻ',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              Get.back();
              
              // Chuyển đến màn hình tạo flashcard
              final result = await Get.to(
                () => CreateEditFlashcardScreen(
                  initialTitle: nameController.text.trim(),
                  initialDescription: descriptionController.text.trim(),
                  lessonId: widget.lessonId,
                  classroomId: widget.classroomId,
                ),
              );
              
              if (result == true) {
                _loadLesson();
              }
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }
  
  // Show dialog to add exercise
  void _showAddExerciseDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final timeLimitController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Thêm bài tập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề bài tập',
                hintText: 'Nhập tiêu đề bài tập',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Nhập mô tả ngắn gọn',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeLimitController,
              decoration: const InputDecoration(
                labelText: 'Thời gian làm bài (phút)',
                hintText: 'Nhập thời gian làm bài',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập tiêu đề bài tập',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              Get.back();
              
              // Chuyển đến màn hình tạo bài tập
              final result = await Get.to(() => CreateExerciseScreen(
                lessonId: widget.lessonId,
                classroomId: widget.classroomId,
                initialTitle: titleController.text.trim(),
                initialDescription: descriptionController.text.trim(),
                initialTimeLimit: timeLimitController.text.trim(),
              ));

              if (result == true) {
                _loadLesson();
              }
            },
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
  }

  // Add this method to handle flashcard deletion
  void _showDeleteFlashcardDialog(Flashcard flashcard) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa thẻ ghi nhớ'),
        content: const Text('Bạn có chắc chắn muốn xóa thẻ ghi nhớ này không?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                await _flashcardService.deleteFlashcard(flashcard.id!);
                Get.snackbar(
                  'Thành công',
                  'Đã xóa thẻ ghi nhớ',
                  snackPosition: SnackPosition.BOTTOM,
                );
                setState(() {}); // Refresh the list
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Không thể xóa thẻ ghi nhớ: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Add this method to handle video deletion
  void _showDeleteVideoDialog(int videoIndex) {
    final video = _lesson!.videos[videoIndex];
    final videoTitle = video.title ?? 'Video ${videoIndex + 1}';
    
    Get.dialog(
      AlertDialog(
        title: const Text('Xóa video'),
        content: Text('Bạn có chắc chắn muốn xóa video "$videoTitle" không?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                // Get current lesson
                final lesson = await _lessonService.getLessonById(widget.lessonId);
                if (lesson == null) throw 'Bài học không tồn tại';
                
                // Remove video at index
                final videos = List<VideoItem>.from(lesson.videos);
                final removedVideo = videos.removeAt(videoIndex);
                
                // Update lesson
                final updatedLesson = lesson.copyWith(
                  videos: videos,
                  updatedAt: Timestamp.now(),
                );
                
                await _lessonService.updateLesson(widget.lessonId, updatedLesson);
                
                // Delete video file from storage if it's not a YouTube video
                if (!removedVideo.url.contains('youtube.com') && !removedVideo.url.contains('youtu.be')) {
                  try {
                    final storageRef = FirebaseStorage.instance.refFromURL(removedVideo.url);
                    await storageRef.delete();
                  } catch (e) {
                    print('Error deleting video file: $e');
                  }
                }
                
                Get.snackbar(
                  'Thành công',
                  'Đã xóa video',
                  snackPosition: SnackPosition.BOTTOM,
                );
                
                // Reset video controllers and reload lesson
                setState(() {
                  _currentVideoIndex = 0;
                  _videoControllers.clear();
                });
                _loadLesson();
                
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Không thể xóa video: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Add edit video dialog
  void _showEditVideoDialog(int videoIndex) {
    final video = _lesson!.videos[videoIndex];
    final titleController = TextEditingController(text: video.title);
    final descriptionController = TextEditingController(text: video.description);
    
    Get.dialog(
      AlertDialog(
        title: const Text('Chỉnh sửa thông tin video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề video',
                hintText: 'Nhập tiêu đề video',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả video',
                hintText: 'Nhập mô tả ngắn về nội dung video',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate input
              if (titleController.text.trim().isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập tiêu đề video',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              Get.back();
              
              try {
                // Lấy bài học hiện tại
                final lesson = await _lessonService.getLessonById(widget.lessonId);
                if (lesson == null) {
                  throw 'Bài học không tồn tại';
                }
                
                // Cập nhật video item
                final updatedVideo = video.copyWith(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isNotEmpty 
                      ? descriptionController.text.trim() 
                      : null,
                );
                
                // Cập nhật danh sách video
                final videosList = List<VideoItem>.from(lesson.videos);
                videosList[videoIndex] = updatedVideo;
                
                final updatedLesson = lesson.copyWith(
                  videos: videosList,
                  updatedAt: Timestamp.now(),
                );
                
                await _lessonService.updateLesson(widget.lessonId, updatedLesson);
                
                Get.snackbar(
                  'Thành công',
                  'Đã cập nhật thông tin video',
                  snackPosition: SnackPosition.BOTTOM,
                );
                
                // Tải lại dữ liệu bài học
                _loadLesson();
              } catch (e) {
                Get.snackbar(
                  'Lỗi',
                  'Không thể cập nhật thông tin video: ${e.toString()}',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeTab() {
    if (_flashcardItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Chưa có thẻ ghi nhớ để luyện tập',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Chọn trò chơi để luyện tập',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Fill in the blank game
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Điền từ'),
              subtitle: const Text('Điền từ còn thiếu vào chỗ trống'),
              onTap: () {
                // Lọc các flashcard items phù hợp cho trò chơi điền từ
                final validItems = _flashcardItems.where((item) => 
                  item.type == FlashcardItemType.textToText || 
                  item.type == FlashcardItemType.imageToText
                ).toList();

                if (validItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không có từ vựng phù hợp cho trò chơi này'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FillInTheBlankGame(
                      items: validItems,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Matching game
          Card(
            child: ListTile(
              leading: const Icon(Icons.link, color: Colors.green),
              title: const Text('Nối từ'),
              subtitle: const Text('Nối từ với nghĩa tương ứng'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchingGame(
                      items: _flashcardItems,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentProgressCard(Map<String, dynamic> student) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: student['photoUrl'] != null
              ? NetworkImage(student['photoUrl'])
              : null,
          child: student['photoUrl'] == null
              ? Text(student['name'][0].toUpperCase())
              : null,
        ),
        title: Text(student['name']),
        subtitle: Text(
          'Hoàn thành: ${(student['progress'] * 100).toStringAsFixed(1)}%',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.analytics),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentProgressDetailScreen(
                  studentId: student['id'],
                  classroomId: widget.classroomId,
                  studentName: student['name'],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}   