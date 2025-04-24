import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class UploadMaterialScreen extends StatefulWidget {
  const UploadMaterialScreen({Key? key}) : super(key: key);

  @override
  _UploadMaterialScreenState createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _lessonId;
  String? _classroomId;
  bool _isLoading = false;
  
  File? _selectedFile;
  String? _fileName;
  
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
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileName = path.basename(_selectedFile!.path);
          
          // Mặc định tên tài liệu là tên file
          if (_nameController.text.isEmpty) {
            _nameController.text = _fileName!.split('.').first;
          }
        });
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể chọn tệp: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _uploadMaterial() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng chọn tệp để tải lên',
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

      // Tải tệp lên Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('materials')
          .child('${DateTime.now().millisecondsSinceEpoch}_$_fileName');
          
      final uploadTask = storageRef.putFile(_selectedFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      
      final fileUrl = await snapshot.ref.getDownloadURL();
      final fileSize = await _selectedFile!.length();
      final fileExtension = path.extension(_fileName!).replaceAll('.', '');

      // Tạo tài liệu mới trong Firestore
      final materialRef = await FirebaseFirestore.instance.collection('materials').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'authorId': currentUser.uid,
        'lessonId': _lessonId,
        'classroomId': _classroomId,
        'url': fileUrl,
        'fileName': _fileName,
        'fileSize': fileSize,
        'fileType': fileExtension,
        'type': 'document', // document, video, link
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

      Get.back();
      Get.snackbar(
        'Thành công',
        'Đã tải lên tài liệu mới',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải lên tài liệu: ${e.toString()}',
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
        title: const Text('Tải lên tài liệu'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _uploadMaterial,
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
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên tài liệu',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên tài liệu';
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
                    const SizedBox(height: 24),
                    const Text(
                      'Tệp tài liệu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedFile == null
                                  ? Icons.upload_file
                                  : Icons.description,
                              size: 48,
                              color: Colors.blue.shade800,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFile == null
                                  ? 'Chọn tệp để tải lên'
                                  : _fileName!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedFile == null
                                    ? Colors.grey.shade600
                                    : Colors.black,
                              ),
                            ),
                            if (_selectedFile != null)
                              Text(
                                '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Định dạng hỗ trợ: PDF, DOC, DOCX, PPT, PPTX, XLS, XLSX, TXT',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Kích thước tối đa: 10MB',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadMaterial,
        backgroundColor: Colors.white,
        child: const Icon(Icons.save),
      ),
    );
  }
}
