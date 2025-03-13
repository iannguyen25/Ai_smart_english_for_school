import 'package:base_flutter_framework/screens/flashcards/flashcard_detail_screen.dart';
import 'package:base_flutter_framework/widgets/flashcard_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/folder.dart';
import '../../models/flashcard.dart';
import '../../models/video.dart';
import '../../services/folder_service.dart';
import '../../services/flashcard_service.dart';
import '../../services/video_service.dart';
import 'create_edit_folder_screen.dart';
import '../video/video_player_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:base_flutter_framework/widgets/video_info_dialog.dart';
import 'package:base_flutter_framework/widgets/video_url_dialog.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class FolderDetailScreen extends StatefulWidget {
  final String folderId;

  const FolderDetailScreen({Key? key, required this.folderId})
      : super(key: key);

  @override
  _FolderDetailScreenState createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen>
    with SingleTickerProviderStateMixin {
  final _folderService = FolderService();
  final _flashcardService = FlashcardService();
  final _videoService = VideoService();
  final _auth = auth.FirebaseAuth.instance;
  late TabController _tabController;
  Folder? _folder;
  List<Flashcard> _flashcards = [];
  List<Video> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFolder();
  }

  Future<void> _loadFolder() async {
    try {
      setState(() => _isLoading = true);
      final folder = await _folderService.getFolderById(widget.folderId);

      // Load cả flashcards và videos
      List<Flashcard> flashcards = [];
      List<Video> videos = [];

      if (folder.flashcardIds.isNotEmpty) {
        flashcards =
            await _flashcardService.getFlashcardsByIds(folder.flashcardIds);
      }

      if (folder.videoIds.isNotEmpty) {
        videos = await _videoService.getVideosByIds(folder.videoIds);
      }

      setState(() {
        _folder = folder;
        _flashcards = flashcards;
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _folder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thư mục')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isOwner = _folder!.userId == _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(_folder!.name),
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Chỉnh sửa'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Xóa', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    final result = await Get.to(
                      () => CreateEditFolderScreen(folder: _folder),
                    );
                    if (result == true) {
                      _loadFolder();
                    }
                    break;
                  case 'delete':
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận xóa'),
                        content: const Text(
                          'Bạn có chắc chắn muốn xóa thư mục này?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Xóa',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await _folderService.deleteFolder(_folder!.id!);
                        if (!mounted) return;
                        Navigator.pop(context, true);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                    break;
                }
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bộ thẻ'),
            Tab(text: 'Video'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFlashcardsTab(),
          _buildVideosTab(),
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              onPressed: _showAddContentSheet,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildFlashcardsTab() {
    if (_flashcards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có bộ thẻ nào',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flashcards.length,
      itemBuilder: (context, index) {
        final flashcard = _flashcards[index];
        final count = flashcard.items?.length ?? 0;
        return Card(
          child: ListTile(
            title: Text(flashcard.title),
            subtitle: Text(
              '${count} thẻ',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: _folder!.userId == _auth.currentUser?.uid
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.red,
                    onPressed: () => _removeFlashcard(flashcard.id!),
                  )
                : null,
            onTap: () => Get.to(
              () => FlashcardDetailScreen(flashcardId: flashcard.id!),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideosTab() {
    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có video nào',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (video.thumbnailUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    video.thumbnailUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              ListTile(
                title: Text(video.title),
                subtitle: Text(
                  _formatDuration(video.duration),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                trailing: _folder!.userId == _auth.currentUser?.uid
                    ? IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                        onPressed: () => _removeVideo(video.id!),
                      )
                    : null,
                onTap: () => Get.to(
                  () => VideoPlayerScreen(videoId: video.id!),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddContentSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.card_membership),
              title: const Text('Chọn từ bộ thẻ của tôi'),
              onTap: () {
                Navigator.pop(context);
                _showFlashcardPicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Tải video lên'),
              onTap: () {
                Navigator.pop(context);
                _uploadVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Thêm video từ URL'),
              onTap: () {
                Navigator.pop(context);
                _addVideoFromUrl();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFlashcardPicker() async {
    try {
      setState(() => _isLoading = true);

      // Log user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      print('Current userId: $userId');
      if (userId == null) return;

      // Log trước khi gọi getUserFlashcards
      print('Fetching flashcards for user: $userId');
      final flashcards = await _flashcardService.getUserFlashcards(userId);
      print('Fetched flashcards: ${flashcards.length}');
      // Log chi tiết từng flashcard
      flashcards.forEach((flashcard) {
        print(
            'Flashcard: ${flashcard.id} - ${flashcard.title} - Items: ${flashcard.items?.length ?? 0}');
      });

      setState(() => _isLoading = false);

      if (!mounted) return;

      // Log folder hiện tại
      print('Current folder flashcardIds: ${_folder?.flashcardIds}');

      // Lọc ra những flashcard chưa có trong folder
      final availableFlashcards = flashcards
          .where((f) => !(_folder?.flashcardIds.contains(f.id) ?? false))
          .toList();

      print('Available flashcards: ${availableFlashcards.length}');
      // Log chi tiết flashcard có thể chọn
      availableFlashcards.forEach((flashcard) {
        print('Available: ${flashcard.id} - ${flashcard.title}');
      });

      final selectedFlashcards = await showDialog<List<Flashcard>>(
        context: context,
        builder: (context) => FlashcardPickerDialog(
          flashcards: availableFlashcards,
        ),
      );

      // Log kết quả chọn
      print('Selected flashcards: ${selectedFlashcards?.length ?? 0}');

      if (selectedFlashcards != null && selectedFlashcards.isNotEmpty) {
        await _folderService.addFlashcardsToFolder(
          _folder!.id!,
          selectedFlashcards.map((f) => f.id!).toList(),
        );
        _loadFolder(); // Reload folder data

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm bộ thẻ vào thư mục')),
          );
        }
      }
    } catch (e) {
      print('Error in _showFlashcardPicker: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _uploadVideo() async {
    try {
      // Sử dụng ImagePicker thay vì FilePicker
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // Giới hạn thời lượng video
      );

      if (video == null) return;

      // Hiển thị dialog nhập thông tin video
      final videoInfo = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => VideoInfoDialog(),
      );

      if (videoInfo == null) return;

      setState(() => _isLoading = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Upload video và tạo thumbnail
      final videoUrl = await _videoService.uploadVideo(
        File(video.path),
        userId,
      );

      // Tạo video mới
      final newVideo = Video(
        title: videoInfo['title'] ?? 'Untitled',
        description: videoInfo['description'] ?? '',
        userId: userId,
        videoUrl: videoUrl,
        isPublic: false,
      );

      // Lưu video vào database
      final videoId = await _videoService.createVideo(newVideo);

      // Thêm video vào folder
      await _folderService.addVideosToFolder(_folder!.id!, [videoId]);

      // Reload folder
      _loadFolder();

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video đã được tải lên thành công')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải video: $e')),
        );
      }
      print('Error uploading video: $e');
    }
  }

  Future<void> _addVideoFromUrl() async {
    try {
      final videoInfo = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => VideoUrlDialog(),
      );

      if (videoInfo == null) return;

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Tạo video mới
      final video = Video(
        title: videoInfo['title'] ?? 'Untitled',
        description: videoInfo['description'] ?? '',
        userId: userId,
        videoUrl: videoInfo['url'] ?? '',
        isPublic: false,
      );

      // Lưu video vào database
      final videoId = await _videoService.createVideo(video);

      // Thêm video vào folder
      await _folderService.addVideosToFolder(_folder!.id!, [videoId]);

      // Reload folder
      _loadFolder();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeFlashcard(String flashcardId) async {
    try {
      await _folderService.removeFlashcardFromFolder(
        _folder!.id!,
        flashcardId,
      );
      _loadFolder();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _removeVideo(String videoId) async {
    try {
      await _folderService.removeVideoFromFolder(
        _folder!.id!,
        videoId,
      );
      _loadFolder();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds - minutes * 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
