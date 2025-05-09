import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../services/sample_content_service.dart';
import '../../models/lesson.dart';
import '../../models/video.dart';
import '../../models/flashcard.dart';
import '../../models/exercise.dart';
import '../../models/quiz.dart';
import '../flashcards/create_edit_flashcard_screen.dart';
import '../exercises/create_exercise_screen.dart';
import '../flashcards/flashcard_detail_screen.dart';
import '../exercises/exercise_detail_screen.dart';

class SampleContentDetailScreen extends StatefulWidget {
  final String lessonId;
  final String courseId;

  const SampleContentDetailScreen({
    Key? key,
    required this.lessonId,
    required this.courseId,
  }) : super(key: key);

  @override
  _SampleContentDetailScreenState createState() => _SampleContentDetailScreenState();
}

class _SampleContentDetailScreenState extends State<SampleContentDetailScreen> {
  final SampleContentService _sampleContentService = SampleContentService();
  final _videoUrlController = TextEditingController();
  final _videoTitleController = TextEditingController();
  final _videoDescriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý nội dung mẫu'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Video'),
              Tab(text: 'Flashcard'),
              Tab(text: 'Bài tập'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildVideoTab(),
            _buildFlashcardTab(),
            _buildExerciseTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Thêm video mới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _videoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'URL Video',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _videoTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _videoDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addVideo,
                    child: const Text('Thêm video'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Danh sách video',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('lessons')
                .doc(widget.lessonId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Lỗi: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final videos = (data?['videoItems'] as List<dynamic>?) ?? [];

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return Card(
                    child: ListTile(
                      title: Text(video['title'] ?? ''),
                      subtitle: Text(video['description'] ?? ''),
                      onTap: () => _showVideoPreviewDialog(video),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeVideo(index),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Thêm flashcard mới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddFlashcardDialog(),
                    child: const Text('Tạo flashcard mới'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Danh sách flashcard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('lessons')
                .doc(widget.lessonId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print('Lỗi khi lấy dữ liệu lesson: ${snapshot.error}');
                return Text('Lỗi: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final flashcardIds = List<String>.from(data?['flashcardIds'] ?? []);
              print('Flashcard IDs: $flashcardIds');

              if (flashcardIds.isEmpty) {
                return const Center(
                  child: Text('Chưa có flashcard nào'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: flashcardIds.length,
                itemBuilder: (context, index) {
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('flashcards')
                        .doc(flashcardIds[index])
                        .snapshots(),
                    builder: (context, flashcardSnapshot) {
                      if (!flashcardSnapshot.hasData) {
                        return const SizedBox();
                      }

                      final flashcardData = flashcardSnapshot.data?.data() as Map<String, dynamic>?;
                      print('Flashcard data: $flashcardData');

                      return Card(
                        child: ListTile(
                          title: Text(flashcardData?['title'] ?? ''),
                          subtitle: Text(flashcardData?['description'] ?? ''),
                          onTap: () {
                            Get.to(() => FlashcardDetailScreen(
                              flashcardId: flashcardIds[index]
                            ));
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeFlashcard(flashcardIds[index]),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Thêm bài tập mới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddExerciseDialog(),
                    child: const Text('Tạo bài tập mới'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Danh sách bài tập',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('lessons')
                .doc(widget.lessonId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Lỗi: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final exerciseIds = (data?['exerciseIds'] as List<dynamic>?) ?? [];

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exerciseIds.length,
                itemBuilder: (context, index) {
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('exercises')
                        .doc(exerciseIds[index])
                        .snapshots(),
                    builder: (context, exerciseSnapshot) {
                      if (!exerciseSnapshot.hasData) {
                        return const SizedBox();
                      }

                      final exerciseData = exerciseSnapshot.data?.data() as Map<String, dynamic>?;
                      return Card(
                        child: ListTile(
                          title: Text(exerciseData?['title'] ?? ''),
                          subtitle: Text(exerciseData?['description'] ?? ''),
                          onTap: () {
                            Get.to(() => ExerciseDetailScreen(
                              exerciseId: exerciseIds[index],
                              lessonId: widget.lessonId,
                              classroomId: widget.courseId,
                            ));
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeExercise(exerciseIds[index]),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addVideo() async {
    if (_videoUrlController.text.isEmpty ||
        _videoTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('Bắt đầu thêm video mới...');
      print('URL: ${_videoUrlController.text}');
      print('Title: ${_videoTitleController.text}');
      print('Description: ${_videoDescriptionController.text}');

      final video = VideoItem(
        url: _videoUrlController.text,
        title: _videoTitleController.text,
        description: _videoDescriptionController.text,
      );

      print('Video object created: ${video.toMap()}');

      await _sampleContentService.addVideoToLesson(widget.lessonId, video);

      print('Video đã được thêm vào lesson ${widget.lessonId}');

      _videoUrlController.clear();
      _videoTitleController.clear();
      _videoDescriptionController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm video thành công')),
      );
    } catch (e) {
      print('Lỗi khi thêm video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeVideo(int index) async {
    try {
      await _sampleContentService.removeVideoFromLesson(widget.lessonId, index);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa video thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _showAddFlashcardDialog() async {
    try {
      final result = await Get.to(() => CreateEditFlashcardScreen(
        lessonId: widget.lessonId,
        classroomId: widget.courseId,
        initialTitle: 'Flashcard mẫu',
        initialDescription: 'Flashcard mẫu cho bài học',
        isSample: true,
      ));

      if (result == true) {
        // Refresh the lesson document to get updated flashcardIds
        final lessonDoc = await FirebaseFirestore.instance
            .collection('lessons')
            .doc(widget.lessonId)
            .get();
            
        if (lessonDoc.exists) {
          final data = lessonDoc.data() as Map<String, dynamic>;
          final flashcardIds = List<String>.from(data['flashcardIds'] ?? []);
          
          // Update the lesson with the new flashcard ID if it's not already included
          if (flashcardIds.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('lessons')
                .doc(widget.lessonId)
                .update({
              'flashcardIds': flashcardIds,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm flashcard thành công')),
        );
      }
    } catch (e) {
      print('Lỗi khi thêm flashcard: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeFlashcard(String flashcardId) async {
    try {
      await FirebaseFirestore.instance
          .collection('lessons')
          .doc(widget.lessonId)
          .update({
        'flashcardIds': FieldValue.arrayRemove([flashcardId]),
      });

      await FirebaseFirestore.instance
          .collection('flashcards')
          .doc(flashcardId)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _showAddExerciseDialog() async {
    try {
      final result = await Get.to(() => CreateExerciseScreen(
        lessonId: widget.lessonId,
        classroomId: widget.courseId,
        initialTitle: 'Bài tập mẫu',
        initialDescription: 'Bài tập mẫu cho bài học',
        isSample: true,
      ));

      if (result == true) {
        // Refresh the lesson document to get updated exerciseIds
        final lessonDoc = await FirebaseFirestore.instance
            .collection('lessons')
            .doc(widget.lessonId)
            .get();
            
        if (lessonDoc.exists) {
          final data = lessonDoc.data() as Map<String, dynamic>;
          final exerciseIds = List<String>.from(data['exerciseIds'] ?? []);
          
          // Update the lesson with the new exercise ID if it's not already included
          if (exerciseIds.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('lessons')
                .doc(widget.lessonId)
                .update({
              'exerciseIds': exerciseIds,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm bài tập thành công')),
        );
      }
    } catch (e) {
      print('Lỗi khi thêm bài tập: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeExercise(String exerciseId) async {
    try {
      await FirebaseFirestore.instance
          .collection('lessons')
          .doc(widget.lessonId)
          .update({
        'exerciseIds': FieldValue.arrayRemove([exerciseId]),
      });

      await FirebaseFirestore.instance
          .collection('exercises')
          .doc(exerciseId)
          .delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _showVideoPreviewDialog(Map<String, dynamic> video) async {
    print('=== Bắt đầu xem video ===');
    print('Video data: $video');
    print('Video URL: ${video['url']}');
    print('Video title: ${video['title']}');
    print('Video description: ${video['description']}');

    if (video['url'] == null) {
      print('Lỗi: URL video là null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL video không hợp lệ')),
      );
      return;
    }

    // Extract video ID from YouTube URL
    String? videoId;
    try {
      videoId = YoutubePlayer.convertUrlToId(video['url']);
      print('Extracted YouTube video ID: $videoId');
    } catch (e) {
      print('Error extracting video ID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL video không hợp lệ')),
      );
      return;
    }

    if (videoId == null) {
      print('Không thể trích xuất ID video');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL video không hợp lệ')),
      );
      return;
    }

    final YoutubePlayerController youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                video['title'] ?? 'Không có tiêu đề',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(
                  controller: youtubeController,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.amber,
                  progressColors: const ProgressBarColors(
                    playedColor: Colors.amber,
                    handleColor: Colors.amberAccent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                video['description'] ?? 'Không có mô tả',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      youtubeController.dispose();
                      Navigator.pop(context);
                    },
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoUrlController.dispose();
    _videoTitleController.dispose();
    _videoDescriptionController.dispose();
    super.dispose();
  }
} 