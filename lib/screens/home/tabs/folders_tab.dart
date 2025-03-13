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
        title: const Text('Thư mục'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Get.to(() => const SearchFoldersScreen()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có thư mục nào',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await Get.to(
                            () => const CreateEditFolderScreen(),
                          );
                          if (result == true) {
                            _loadFolders();
                          }
                        },
                        child: const Text('Tạo thư mục mới'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFolders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _folders.length,
                    itemBuilder: (context, index) {
                      final folder = _folders[index];
                      return _buildFolderCard(folder);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const CreateEditFolderScreen());
          if (result == true) {
            _loadFolders();
          }
        },
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }

  Widget _buildFolderCard(Folder folder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await Get.to(
            () => FolderDetailScreen(folderId: folder.id!),
          );
          if (result == true) {
            _loadFolders();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    folder.isPublic ? Icons.folder_shared : Icons.folder,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      folder.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
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
                            () => CreateEditFolderScreen(folder: folder),
                          );
                          if (result == true) {
                            _loadFolders();
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
                              await _folderService.deleteFolder(folder.id!);
                              _loadFolders();
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
              ),
              if (folder.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  folder.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.style,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${folder.flashcardIds.length} bộ thẻ',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.video_library,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${folder.videoIds.length} video',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}