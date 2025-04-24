import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CreateVideoScreen extends StatefulWidget {
  const CreateVideoScreen({Key? key}) : super(key: key);

  @override
  _CreateVideoScreenState createState() => _CreateVideoScreenState();
}

class _CreateVideoScreenState extends State<CreateVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  
  String? _lessonId;
  String? _classroomId;
  bool _isLoading = false;
  bool _isValidYoutubeUrl = false;
  String? _youtubeVideoId;
  YoutubePlayerController? _youtubeController;
  
  @override
  void initState() {
    super.initState();
    _parseArguments();
  }

  void _parseArguments() {
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _lessonId = args['lessonId'];
      _classroomId = args['classroomId'];
      
      if (args['title'] != null) {
        _titleController.text = args['title'];
      }
      
      if (args['description'] != null) {
        _descriptionController.text = args['description'];
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _validateYoutubeUrl(String url) {
    if (url.isEmpty) {
      setState(() {
        _isValidYoutubeUrl = false;
        _youtubeVideoId = null;
        _youtubeController?.dispose();
        _youtubeController = null;
      });
      return;
    }

    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      setState(() {
        _isValidYoutubeUrl = true;
        _youtubeVideoId = videoId;
        _youtubeController?.dispose();
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
      });
    } else {
      setState(() {
        _isValidYoutubeUrl = false;
        _youtubeVideoId = null;
        _youtubeController?.dispose();
        _youtubeController = null;
      });
    }
  }

  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isValidYoutubeUrl) {
      Get.snackbar(
        'Lỗi',
        'URL video YouTube không hợp lệ',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'Bạn chưa đăng nhập';
      }

      // Tạo video mới trong Firestore
      final materialRef = await FirebaseFirestore.instance.collection('materials').add({
        'name': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'authorId': currentUser.uid,
        'lessonId': _lessonId,
        'classroomId': _classroomId,
        'url': _videoUrlController.text.trim(),
        'videoId': _youtubeVideoId,
        'type': 'video', // document, video, link
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật bài học nếu có
      if (_lessonId != null) {
        final lessonDoc = await FirebaseFirestore.instance
            .collection('lessons')
            .doc(_lessonId)
            .get();
        
        if (lessonDoc.exists) {
          final List<dynamic> materialIds = lessonDoc.data()?['materialIds'] ?? [];
          materialIds.add(materialRef.id);
          
          await FirebaseFirestore.instance
              .collection('lessons')
              .doc(_lessonId)
              .update({
            'materialIds': materialIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      // Cập nhật lớp học nếu có
      if (_classroomId != null) {
        final classroomDoc = await FirebaseFirestore.instance
            .collection('classrooms')
            .doc(_classroomId)
            .get();
        
        if (classroomDoc.exists) {
          final List<dynamic> videoIds = classroomDoc.data()?['customVideoIds'] ?? [];
          videoIds.add(materialRef.id);
          
          await FirebaseFirestore.instance
              .collection('classrooms')
              .doc(_classroomId)
              .update({
            'customVideoIds': videoIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      Get.back();
      Get.snackbar(
        'Thành công',
        'Đã thêm video mới',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể thêm video: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm video bài giảng'),
        backgroundColor: Colors.red.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveVideo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề video',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tiêu đề video';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mô tả video';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _videoUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Video YouTube',
                        hintText: 'https://youtube.com/watch?v=...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _validateYoutubeUrl,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập URL video YouTube';
                        }
                        if (!_isValidYoutubeUrl) {
                          return 'URL video YouTube không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // YouTube video preview
                    if (_isValidYoutubeUrl && _youtubeController != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xem trước video:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          YoutubePlayer(
                            controller: _youtubeController!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: Colors.red,
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Video sẽ được thêm vào ${_lessonId != null ? "bài học" : _classroomId != null ? "lớp học" : "tài liệu của bạn"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
