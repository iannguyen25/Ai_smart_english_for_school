import 'package:base_flutter_framework/widgets/image_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../models/classroom.dart';
import '../../services/classroom_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/course_service.dart';
import '../../services/sample_content_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/course.dart';

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
  final CourseService _courseService = CourseService();
  final SampleContentService _sampleContentService = SampleContentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isPublic = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _coverImagePath;
  bool get _isEditMode => widget.classroom != null;
  bool _isCourseClosed = false;

  List<Course> _courses = [];
  Course? _selectedCourse;
  String? _inviteCode;
  File? _coverImageFile;
  String? _coverImageUrl;
  
  bool _useSampleContent = false;
  List<Map<String, dynamic>> _sampleContents = [];
  Map<String, dynamic>? _selectedSampleContent;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    
    if (_isEditMode) {
      _nameController.text = widget.classroom!.name;
      _descriptionController.text = widget.classroom!.description;
      _isPublic = widget.classroom!.isPublic;
      _inviteCode = widget.classroom!.inviteCode;
      _coverImageUrl = widget.classroom!.coverImage;
      
      if (widget.classroom!.courseId != null) {
        _loadSelectedCourse(widget.classroom!.courseId!);
      }
    } else {
      _generateInviteCode();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    
    for (int i = 0; i < 6; i++) {
      result += chars[(random + i) % chars.length];
    }
    
    setState(() {
      _inviteCode = result;
    });
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    
    try {
      final courses = await _courseService.getAllCourses();
      print('Loaded courses: ${courses.length}');
      courses.forEach((course) {
        print('Course: ${course.name} (${course.id})');
      });
      
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading courses: $e');
      setState(() => _isLoading = false);
      
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách khóa học: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
        isDismissible: true,
      );
    }
  }

  Future<void> _loadSelectedCourse(String courseId) async {
    try {
      final course = await _courseService.getCourseById(courseId);
      if (course != null) {
        setState(() {
          _selectedCourse = course;
        });
      }
    } catch (e) {
      print('Error loading selected course: $e');
    }
  }

  Future<void> _loadSampleContents(String courseId) async {
    try {
      final contents = await _sampleContentService.getSampleContentByCourse(courseId);
      setState(() {
        _sampleContents = contents;
        _selectedSampleContent = null;
      });
    } catch (e) {
      print('Error loading sample contents: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách tài liệu mẫu: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _onCourseSelected(Course? course) {
    setState(() {
      _selectedCourse = course;
      _useSampleContent = false;
      _selectedSampleContent = null;
      _sampleContents = [];
      _isCourseClosed = course?.isClosed ?? false;
    });
    
    if (course != null && course.id != null) {
      _loadSampleContents(course.id!);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _coverImageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadCoverImage() async {
    if (_coverImageFile == null) return _coverImageUrl;
    
    try {
      final String fileName = 'classroom_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String? downloadUrl = await _storageService.uploadFile(
        _coverImageFile!,
        'classroom_covers/$fileName',
      );
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading cover image: $e');
      return null;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? coverImageUrl = _coverImagePath;

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
          inviteCode: _inviteCode,
          courseId: _selectedCourse?.id,
          updatedAt: DateTime.now(),
        );

        await _classroomService.updateClassroom(updatedClassroom);
        Get.back(result: true);
        Get.snackbar(
          'Thành công',
          'Đã cập nhật lớp học',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        final classroom = Classroom(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          teacherId: _auth.currentUser?.uid ?? '',
          memberIds: _auth.currentUser?.uid != null ? [_auth.currentUser!.uid] : [],
          coverImage: coverImageUrl,
          inviteCode: _inviteCode,
          isPublic: _isPublic,
          courseId: _selectedCourse?.id,
          status: ClassroomStatus.active,
        );
        
        final classroomId = await _classroomService.createClassroom(classroom);
        
        if (classroomId != null) {
          if (_useSampleContent && _selectedSampleContent != null) {
            try {
              final lessonId = _selectedSampleContent!['id'];
              if (lessonId != null) {
                await _classroomService.addLessonToClassroom(
                  classroomId,
                  lessonId,
                );
              }
            } catch (e) {
              print('Error adding sample content: $e');
            }
          }

          Get.back(result: true);
          Get.snackbar(
            'Thành công',
            'Đã tạo lớp học mới',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          throw 'Không thể tạo lớp học';
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Thêm getter để kiểm tra điều kiện lưu
  bool get _canSave {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    return name.isNotEmpty && 
           description.isNotEmpty && 
           _selectedCourse != null && 
           !_isCourseClosed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Chỉnh sửa lớp học' : 'Tạo lớp học mới'),
        actions: [
          TextButton(
            onPressed: _isLoading || !_canSave ? null : _save,
            child: Text(
              !_canSave ? 'Lưu' : 
              _isCourseClosed ? 'Khóa học đã bị khóa' : 'Lưu',
              style: TextStyle(
                color: _isLoading || !_canSave ? Colors.black.withOpacity(0.5) : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Text(
                      'Chọn khóa học:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Course>(
                      value: _selectedCourse,
                      decoration: const InputDecoration(
                        labelText: 'Chọn khóa học',
                        border: OutlineInputBorder(),
                      ),
                      items: _courses.map((course) {
                        return DropdownMenuItem<Course>(
                          value: course,
                          child: Text(
                            course.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _onCourseSelected,
                      validator: (value) {
                        if (value == null) {
                          return 'Vui lòng chọn khóa học';
                        }
                        return null;
                      },
                      isExpanded: true,
                    ),
                    if (_selectedCourse != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isCourseClosed ? Colors.orange.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isCourseClosed ? Colors.orange.shade100 : Colors.blue.shade100
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Thông tin khóa học: ${_selectedCourse!.name}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (_isCourseClosed)
                                  Icon(
                                    Icons.lock,
                                    color: Colors.orange.shade700,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedCourse!.description,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cấp độ: ${_selectedCourse!.gradeLevel.label}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                            if (_selectedCourse!.materialIds.isNotEmpty || 
                                _selectedCourse!.templateFlashcardIds.isNotEmpty) ...[
                              Text(
                                'Học liệu: ${_selectedCourse!.materialIds.length} bài học, ${_selectedCourse!.templateFlashcardIds.length} bộ flashcard',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (_isCourseClosed) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Khóa học này đã bị khóa và không thể tạo lớp học mới.',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            initialValue: _inviteCode,
                            decoration: const InputDecoration(
                              labelText: 'Mã mời',
                              hintText: 'Mã mời tự động',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _generateInviteCode,
                          tooltip: 'Tạo mã mới',
                        ),
                      ],
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
                    if (_selectedCourse != null && _sampleContents.isNotEmpty) ...[
                      SwitchListTile(
                        title: const Text('Sử dụng tài liệu mẫu'),
                        value: _useSampleContent,
                        onChanged: (value) {
                          setState(() {
                            _useSampleContent = value;
                            if (!value) {
                              _selectedSampleContent = null;
                            }
                          });
                        },
                      ),
                      if (_useSampleContent) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedSampleContent,
                          decoration: const InputDecoration(
                            labelText: 'Chọn tài liệu mẫu',
                            border: OutlineInputBorder(),
                          ),
                          items: _sampleContents.map((content) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: content,
                              child: Text(content['title'] ?? 'Không có tiêu đề'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSampleContent = value;
                            });
                          },
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
