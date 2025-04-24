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
  
  // Thêm ScrollController và biến để theo dõi trạng thái cuộn
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;
  Color _appBarColor = Colors.blue.shade700;
  Color _appBarColorCollapsed = Colors.blue.shade900;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Khởi tạo ScrollController và lắng nghe sự kiện cuộn
    _scrollController = ScrollController()
      ..addListener(_onScroll);
      
    _loadFolder();
  }
  
  void _onScroll() {
    // Tính toán tỷ lệ cuộn (từ 0.0 đến 1.0)
    final double offset = _scrollController.offset;
    final double maxExtent = 180.0; // Chiều cao tối đa của SliverAppBar
    
    // Giới hạn tỷ lệ từ 0.0 đến 1.0
    final double scrollRatio = (offset / maxExtent).clamp(0.0, 1.0);
    final bool isScrolled = scrollRatio > 0.1;
    
    if (mounted && (_scrollOffset != scrollRatio || _isScrolled != isScrolled)) {
      setState(() {
        _scrollOffset = scrollRatio;
        _isScrolled = isScrolled;
        
        // Tính toán màu gradient dựa trên tỷ lệ cuộn
        _appBarColor = Color.lerp(
          Colors.blue.shade700,
          _appBarColorCollapsed,
          scrollRatio
        )!;
      });
    }
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              floating: false,
              pinned: true,
              elevation: _isScrolled ? 4 : 0,
              backgroundColor: _appBarColor,
              flexibleSpace: FlexibleSpaceBar(
                title: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16 - _scrollOffset * 2, // Giảm kích thước font khi cuộn
                  ),
                  child: Text(_folder!.name),
                ),
                titlePadding: EdgeInsets.lerp(
                  const EdgeInsets.only(left: 16, bottom: 16),
                  const EdgeInsets.only(left: 56, bottom: 16),
                  _scrollOffset
                ),
                collapseMode: CollapseMode.pin,
                background: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _appBarColor,
                        Color.lerp(Colors.blue.shade500, _appBarColorCollapsed, _scrollOffset)!,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -20,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 200 * (1 - _scrollOffset * 0.5),
                          height: 200 * (1 - _scrollOffset * 0.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1 * (1 - _scrollOffset * 0.5)),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -50,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 180 * (1 - _scrollOffset * 0.5),
                          height: 180 * (1 - _scrollOffset * 0.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1 * (1 - _scrollOffset * 0.5)),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 70 * (1 - _scrollOffset),
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          opacity: 1 - _scrollOffset,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              _folder!.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
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
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _appBarColor,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(_isScrolled ? 0.2 : 0.1),
                        width: _isScrolled ? 1.0 : 0.5,
                      ),
                    ),
                    boxShadow: _isScrolled 
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ] 
                      : [],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.style),
                        text: 'Bộ thẻ',
                      ),
                      Tab(
                        icon: Icon(Icons.video_library),
                        text: 'Video',
                      ),
                    ],
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFlashcardsTab(),
            _buildVideosTab(),
          ],
        ),
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              onPressed: _showAddContentSheet,
              child: const Icon(Icons.add),
              backgroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildFlashcardsTab() {
    if (_flashcards.isEmpty) {
      return _buildEmptyState(
        icon: Icons.style_outlined,
        message: 'Chưa có bộ thẻ nào',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: _flashcards.length,
        itemBuilder: (context, index) {
          final flashcard = _flashcards[index];
          final count = flashcard.items?.length ?? 0;
          
          // Tạo màu dựa trên ID của flashcard
          final colorIndex = flashcard.id.hashCode % 5;
          final cardColors = [
            Colors.blue.shade50,
            Colors.green.shade50,
            Colors.purple.shade50,
            Colors.orange.shade50,
            Colors.teal.shade50,
          ];
          final iconColors = [
            Colors.blue.shade700,
            Colors.green.shade700,
            Colors.purple.shade700,
            Colors.orange.shade700,
            Colors.teal.shade700,
          ];
          
          return GestureDetector(
            onTap: () => Get.to(
              () => FlashcardDetailScreen(flashcardId: flashcard.id!),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  // Header
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: cardColors[colorIndex],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.style,
                        size: 40,
                        color: iconColors[colorIndex],
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  flashcard.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_folder!.userId == _auth.currentUser?.uid)
                                GestureDetector(
                                  onTap: () => _removeFlashcard(flashcard.id!),
                                  child: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${count} thẻ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  size: 14,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Học ngay',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideosTab() {
    if (_videos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.video_library_outlined,
        message: 'Chưa có video nào',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final video = _videos[index];
          
          // Tạo màu dựa trên ID của video
          final colorIndex = video.id.hashCode % 5;
          final cardColors = [
            Colors.red.shade50,
            Colors.amber.shade50,
            Colors.indigo.shade50,
            Colors.pink.shade50,
            Colors.cyan.shade50,
          ];
          final iconColors = [
            Colors.red.shade700,
            Colors.amber.shade700,
            Colors.indigo.shade700,
            Colors.pink.shade700,
            Colors.cyan.shade700,
          ];
          
          return GestureDetector(
            onTap: () {
              Get.to(() => VideoPlayerScreen(videoId: video.id!));
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  // Thumbnail
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: cardColors[colorIndex],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 40,
                        color: iconColors[colorIndex],
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  video.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_folder!.userId == _auth.currentUser?.uid)
                                GestureDetector(
                                  onTap: () => _removeVideo(video.id!),
                                  child: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            video.description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  size: 14,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Xem ngay',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm nội dung vào thư mục này',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
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

      setState(() {
        _isLoading = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải video lên...')),
        );
      });

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw 'Vui lòng đăng nhập để tải video lên';
      }

      // Kiểm tra kích thước file
      final file = File(video.path);
      final fileSize = await file.length();
      final fileSizeInMB = fileSize / (1024 * 1024);
      
      if (fileSizeInMB > 50) {
        throw 'Video quá lớn. Vui lòng chọn video nhỏ hơn 50MB';
      }

      // Upload video và tạo thumbnail
      final videoUrl = await _videoService.uploadVideo(
        file,
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
        String errorMessage = 'Lỗi khi tải video lên';
        
        if (e.toString().contains('permission') || 
            e.toString().contains('Permission denied') ||
            e.toString().contains('unauthorized')) {
          errorMessage = 'Không có quyền tải video lên. Vui lòng kiểm tra quyền truy cập Firebase Storage.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Lỗi kết nối mạng. Vui lòng kiểm tra kết nối internet của bạn.';
        } else if (e.toString().contains('cancelled')) {
          errorMessage = 'Quá trình tải lên đã bị hủy.';
        } else {
          errorMessage = 'Lỗi: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _uploadVideo,
            ),
          ),
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
