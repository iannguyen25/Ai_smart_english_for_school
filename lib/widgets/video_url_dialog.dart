import 'package:flutter/material.dart';

class VideoUrlDialog extends StatefulWidget {
  @override
  _VideoUrlDialogState createState() => _VideoUrlDialogState();
}

class _VideoUrlDialogState extends State<VideoUrlDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm video từ URL'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL Video',
                hintText: 'Nhập URL video',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập URL';
                }
                // Thêm validation URL nếu cần
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Nhập tiêu đề video',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tiêu đề';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Nhập mô tả video',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'url': _urlController.text,
                'title': _titleController.text,
                'description': _descriptionController.text,
              });
            }
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}