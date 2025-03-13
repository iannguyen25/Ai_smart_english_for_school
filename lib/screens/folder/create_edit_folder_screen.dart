import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../models/folder.dart';
import '../../services/folder_service.dart';

class CreateEditFolderScreen extends StatefulWidget {
  final Folder? folder;

  const CreateEditFolderScreen({Key? key, this.folder}) : super(key: key);

  @override
  _CreateEditFolderScreenState createState() => _CreateEditFolderScreenState();
}

class _CreateEditFolderScreenState extends State<CreateEditFolderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _folderService = FolderService();
  final _auth = auth.FirebaseAuth.instance;
  bool _isPublic = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.folder != null) {
      _nameController.text = widget.folder!.name;
      _descriptionController.text = widget.folder!.description;
      _isPublic = widget.folder!.isPublic;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw 'Vui lòng đăng nhập';

      if (widget.folder == null) {
        // Tạo mới
        final folder = Folder(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          userId: userId,
          isPublic: _isPublic,
        );
        await _folderService.createFolder(folder);
      } else {
        // Cập nhật
        await _folderService.updateFolder(widget.folder!.id!, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'isPublic': _isPublic,
        });
      }

      if (!mounted) return;
      Navigator.pop(context, true);
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
        title: Text(widget.folder == null ? 'Tạo thư mục' : 'Chỉnh sửa thư mục'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên thư mục',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên thư mục';
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
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Công khai'),
              subtitle: const Text(
                'Cho phép người khác tìm kiếm và xem thư mục của bạn',
              ),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.folder == null ? 'Tạo thư mục' : 'Lưu thay đổi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 