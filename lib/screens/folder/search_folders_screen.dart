import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/folder.dart';
import '../../services/folder_service.dart';
import 'folder_detail_screen.dart';

class SearchFoldersScreen extends StatefulWidget {
  const SearchFoldersScreen({Key? key}) : super(key: key);

  @override
  _SearchFoldersScreenState createState() => _SearchFoldersScreenState();
}

class _SearchFoldersScreenState extends State<SearchFoldersScreen> {
  final _folderService = FolderService();
  final _searchController = TextEditingController();
  List<Folder> _searchResults = [];
  bool _isLoading = false;

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await _folderService.searchFolders(query);
      setState(() {
        _searchResults = results;
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
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm thư mục...',
            border: InputBorder.none,
          ),
          onChanged: (value) => _search(value),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Nhập từ khóa để tìm kiếm'
                            : 'Không tìm thấy kết quả',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final folder = _searchResults[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          folder.isPublic ? Icons.folder_shared : Icons.folder,
                          color: Colors.blue,
                        ),
                        title: Text(folder.name),
                        subtitle: Text(folder.description),
                        onTap: () => Get.to(
                          () => FolderDetailScreen(folderId: folder.id!),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 