import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/course.dart';
import '../../services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreateEditCourseScreen extends StatefulWidget {
  final Course? course;

  const CreateEditCourseScreen({Key? key, this.course}) : super(key: key);

  @override
  _CreateEditCourseScreenState createState() => _CreateEditCourseScreenState();
}

class _CreateEditCourseScreenState extends State<CreateEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = false;
  
  // Các controller
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _textbookNameController = TextEditingController();
  final _publisherController = TextEditingController();
  
  // Các giá trị mặc định
  GradeLevel _selectedGradeLevel = GradeLevel.grade1;
  bool _isTextbook = false;
  bool _isPublished = false;
  
  @override
  void initState() {
    super.initState();
    
    // Nếu đang chỉnh sửa, điền thông tin khóa học
    if (widget.course != null) {
      _nameController.text = widget.course!.name;
      _descriptionController.text = widget.course!.description;
      _selectedGradeLevel = widget.course!.gradeLevel;
      _isTextbook = widget.course!.isTextbook;
      _textbookNameController.text = widget.course!.textbookName;
      _publisherController.text = widget.course!.publisher;
      _isPublished = widget.course!.isPublished;
      _imageUrl = widget.course!.imageUrl;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _textbookNameController.dispose();
    _publisherController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }
  
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;
    
    try {
      // Tạo tên file duy nhất từ timestamp
      final String fileName = 'course_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Tạo reference đến storage
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('course_images')
          .child(fileName);
      
      // Upload file
      final UploadTask uploadTask = storageRef.putFile(_imageFile!);
      
      // Chờ upload hoàn tất
      final TaskSnapshot snapshot = await uploadTask;
      
      // Lấy URL của file đã upload
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải lên hình ảnh: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade700,
      );
      return null;
    }
  }
  
  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Upload ảnh nếu có chọn file mới
      final String? imageUrl = await _uploadImage();
      
      // Thông tin khóa học
      final courseData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'gradeLevel': _selectedGradeLevel.toString().split('.').last,
        'isTextbook': _isTextbook,
        'textbookName': _textbookNameController.text.trim(),
        'publisher': _publisherController.text.trim(),
        'materialIds': widget.course?.materialIds ?? [],
        'questionSetIds': widget.course?.questionSetIds ?? [],
        'templateFlashcardIds': widget.course?.templateFlashcardIds ?? [],
        'createdBy': _authService.currentUser!.id,
        'isPublished': _isPublished,
        'updatedAt': Timestamp.now(),
      };
      
      // Thêm createdAt cho khóa học mới
      if (widget.course == null) {
        courseData['createdAt'] = Timestamp.now();
      }
      
      // Lưu vào Firestore
      if (widget.course == null) {
        // Tạo mới
        await FirebaseFirestore.instance
            .collection('courses')
            .add(courseData);
        
        if (!mounted) return;
        
        setState(() => _isLoading = false);
        
        Get.snackbar(
          'Thành công',
          'Đã tạo khóa học mới',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        Get.back(result: true);
        Navigator.pop(context);
      } else {
        // Cập nhật
        await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.course!.id)
            .update(courseData);
        
        if (!mounted) return;
        
        setState(() => _isLoading = false);
        
        Get.snackbar(
          'Thành công',
          'Đã cập nhật khóa học',
          snackPosition: SnackPosition.BOTTOM,
        );
        
        Get.back(result: true);
      }
    } catch (e) {
      print('Error saving course: $e');
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      Get.snackbar(
        'Lỗi',
        'Không thể lưu khóa học: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade700,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course == null ? 'Tạo khóa học mới' : 'Chỉnh sửa khóa học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveCourse,
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
                    // Ảnh bìa
                    Center(
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _imageUrl != null && _imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(
                                          Icons.image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_photo_alternate,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tên khóa học
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên khóa học',
                        hintText: 'Nhập tên khóa học (vd: Lớp 5, Starter...)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên khóa học';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Mô tả
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        hintText: 'Mô tả chi tiết về khóa học',
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
                    
                    // Loại lớp
                    const Text(
                      'Lớp:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<GradeLevel>(
                      value: _selectedGradeLevel,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: GradeLevel.values.map((level) {
                        return DropdownMenuItem<GradeLevel>(
                          value: level,
                          child: Text(level.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGradeLevel = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Loại tài liệu
                    SwitchListTile(
                      title: const Text('Sách giáo khoa'),
                      subtitle: const Text('Bật nếu là SGK, tắt nếu là tài liệu riêng của trung tâm'),
                      value: _isTextbook,
                      onChanged: (value) {
                        setState(() {
                          _isTextbook = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Nếu là SGK thì hiển thị thêm các trường
                    if (_isTextbook) ...[
                      TextFormField(
                        controller: _textbookNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên sách giáo khoa',
                          hintText: 'Nhập tên SGK',
                          border: OutlineInputBorder(),
                        ),
                        validator: _isTextbook
                            ? (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập tên SGK';
                                }
                                return null;
                              }
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _publisherController,
                        decoration: const InputDecoration(
                          labelText: 'Nhà xuất bản',
                          hintText: 'Nhập tên nhà xuất bản',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Trạng thái xuất bản
                    SwitchListTile(
                      title: const Text('Xuất bản'),
                      subtitle: const Text(
                        'Khóa học đã xuất bản sẽ hiển thị trong danh sách công khai',
                      ),
                      value: _isPublished,
                      onChanged: (value) {
                        setState(() {
                          _isPublished = value;
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