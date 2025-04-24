import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/folder.dart';
import '../../../services/folder_service.dart';
import '../../folder/create_edit_folder_screen.dart';
import '../../folder/folder_detail_screen.dart';
import '../../folder/search_folders_screen.dart';

class FoldersTab extends StatefulWidget {
  const FoldersTab({Key? key}) : super(key: key);

  @override
  _FoldersTabState createState() => _FoldersTabState();
}

class _FoldersTabState extends State<FoldersTab> {
  final _folderService = FolderService();
  final _auth = FirebaseAuth.instance;
  List<Folder> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      setState(() => _isLoading = true);
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'Vui lòng đăng nhập';

      final folders = await _folderService.getUserFolders(userId);
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư mục của tôi'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Get.to(() => const SearchFoldersScreen()),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFolders,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _folders.length,
                      itemBuilder: (context, index) {
                        final folder = _folders[index];
                        return _buildFolderCard(folder);
                      },
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(
            () => const CreateEditFolderScreen(),
          );
          if (result == true) {
            _loadFolders();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Tạo thư mục mới',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_outlined,
              size: 80,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chưa có thư mục nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tạo thư mục để lưu trữ bộ thẻ và video',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Get.to(
                () => const CreateEditFolderScreen(),
              );
              if (result == true) {
                _loadFolders();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Tạo thư mục mới'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderCard(Folder folder) {
    final folderColors = [
      const Color(0xFFE3F2FD), // Light Blue
      const Color(0xFFE8F5E9), // Light Green
      const Color(0xFFFFF3E0), // Light Orange
      const Color(0xFFE1F5FE), // Lighter Blue
      const Color(0xFFF3E5F5), // Light Purple
      const Color(0xFFE0F7FA), // Light Cyan
    ];
    
    // Sử dụng hash của ID folder để chọn màu cố định cho mỗi folder
    final colorIndex = folder.id.hashCode % folderColors.length;
    final folderColor = folderColors[colorIndex.abs()];
    final iconColor = folderColor.withOpacity(0.8);
    
    return GestureDetector(
      onTap: () => Get.to(() => FolderDetailScreen(folderId: folder.id!)),
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
            // Folder header with icon
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: folderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.folder,
                  size: 60,
                  color: iconColor,
                ),
              ),
            ),
            // Folder info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      folder.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStat(
                          Icons.style_outlined,
                          '${folder.flashcardIds.length}',
                        ),
                        _buildStat(
                          Icons.video_library_outlined,
                          '${folder.videoIds.length}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String count) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}