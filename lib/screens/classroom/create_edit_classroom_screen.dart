import 'package:base_flutter_framework/widgets/image_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../models/classroom.dart';
import '../../services/classroom_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class CreateEditClassroomScreen extends StatefulWidget {
  final Classroom? classroom;

  const CreateEditClassroomScreen({Key? key, this.classroom}) : super(key: key);

  @override
  _CreateEditClassroomScreenState createState() =>
      _CreateEditClassroomScreenState();
}

class _CreateEditClassroomScreenState extends State<CreateEditClassroomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ClassroomService _classroomService = ClassroomService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  bool _isPublic = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _coverImagePath;
  bool get _isEditMode => widget.classroom != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.classroom!.name;
      _descriptionController.text = widget.classroom!.description;
      _isPublic = widget.classroom!.isPublic;
      _coverImagePath = widget.classroom!.coverImage;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? coverImageUrl = _coverImagePath;

      // Upload new image if selected
      if (_coverImagePath != null && _coverImagePath!.startsWith('file://')) {
        final file = File(_coverImagePath!.replaceFirst('file://', ''));
        coverImageUrl = await _storageService.uploadFile(
          file,
          'classroom_covers',
        );
      }

      if (_isEditMode) {
        final updatedClassroom = widget.classroom!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          coverImage: coverImageUrl,
          isPublic: _isPublic,
        );

        await _classroomService.updateClassroom(updatedClassroom);
      } else {
        await _classroomService.createClassroom(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          teacherId: _authService.currentUser!.id!,
          coverImage: coverImageUrl,
          isPublic: _isPublic,
        );
      }

      Get.back(result: true);
      Get.snackbar(
        'Thành công',
        _isEditMode ? 'Đã cập nhật lớp học' : 'Đã tạo lớp học',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Chỉnh sửa lớp học' : 'Tạo lớp học mới'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(
              'Lưu',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ImagePickerWidget(
                      initialImageUrl: _coverImagePath,
                      onImageSelected: (path) {
                        setState(() {
                          _coverImagePath = path;
                        });
                      },
                      aspectRatio: 16 / 9,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên lớp học',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên lớp học';
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
                          return 'Vui lòng nhập mô tả';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Công khai'),
                      subtitle: const Text(
                        'Cho phép mọi người tìm thấy lớp học này',
                      ),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
