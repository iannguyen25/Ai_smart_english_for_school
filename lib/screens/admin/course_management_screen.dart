import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/course.dart';
import '../../services/auth_service.dart';
import 'create_edit_course_screen.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({Key? key}) : super(key: key);

  @override
  _CourseManagementScreenState createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  List<Course> _courses = [];
  String? _errorMessage;
  
  // Bộ lọc
  bool _showPublishedOnly = false;
  GradeLevel? _filterGradeLevel;
  
  @override
  void initState() {
    super.initState();
    _loadCourses();
  }
  
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Tạo query cơ bản
      Query query = _firestore.collection('courses');
      
      // Thêm các điều kiện lọc
      if (_showPublishedOnly) {
        query = query.where('isPublished', isEqualTo: true);
      }
      
      if (_filterGradeLevel != null) {
        query = query.where('gradeLevel', isEqualTo: _gradeLevelToString(_filterGradeLevel!));
      }
      
      // Sắp xếp và lấy dữ liệu
      final snapshot = await query
          .orderBy('updatedAt', descending: true)
          .get();
      
      // Chuyển đổi dữ liệu thành danh sách đối tượng Course
      final courses = snapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading courses: $e');
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách khóa học: ${e.toString()}';
      });
    }
  }
  
  // Chuyển đổi GradeLevel thành chuỗi để truy vấn Firestore
  String _gradeLevelToString(GradeLevel level) {
    switch (level) {
      case GradeLevel.grade1:
        return 'grade1';
      case GradeLevel.grade2:
        return 'grade2';
      case GradeLevel.grade3:
        return 'grade3';
      case GradeLevel.grade4:
        return 'grade4';
      case GradeLevel.grade5:
        return 'grade5';
      case GradeLevel.grade6:
        return 'grade6';
      case GradeLevel.grade7:
        return 'grade7';
      case GradeLevel.grade8:
        return 'grade8';
      case GradeLevel.grade9:
        return 'grade9';
      case GradeLevel.custom:
        return 'custom';
    }
  }
  
  // Xóa khóa học
  Future<void> _deleteCourse(Course course) async {
    try {
      // Hiển thị dialog xác nhận
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Xóa khóa học'),
            content: Text('Bạn có chắc chắn muốn xóa khóa học "${course.name}" không? Hành động này không thể hoàn tác.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Xóa'),
              ),
            ],
          );
        },
      );
      
      if (confirm != true) return;
      
      // Xóa khóa học
      await _firestore.collection('courses').doc(course.id).delete();
      
      // Hiển thị thông báo thành công
      Get.snackbar(
        'Thành công',
        'Đã xóa khóa học',
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Tải lại danh sách
      _loadCourses();
    } catch (e) {
      print('Error deleting course: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể xóa khóa học: ${e.toString()}',
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
        title: const Text('Quản lý khóa học'),
        actions: [
          // Nút lọc
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          // Nút làm mới
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade300,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCourses,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _courses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book,
                            color: Colors.grey.shade400,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chưa có khóa học nào',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToCreateCourse(),
                            icon: const Icon(Icons.add),
                            label: const Text('Tạo khóa học'),
                          ),
                        ],
                      ),
                    )
                  : _buildCourseList(),
      // FAB để tạo khóa học mới
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateCourse,
        child: const Icon(Icons.add),
        tooltip: 'Tạo khóa học mới',
      ),
    );
  }
  
  // Hiển thị dialog lọc
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Tạm thời lưu giá trị để không thay đổi state gốc
        bool tempShowPublished = _showPublishedOnly;
        GradeLevel? tempFilterGrade = _filterGradeLevel;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Lọc khóa học'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lọc theo trạng thái xuất bản
                  SwitchListTile(
                    title: const Text('Chỉ hiện đã xuất bản'),
                    value: tempShowPublished,
                    onChanged: (value) {
                      setState(() {
                        tempShowPublished = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Lọc theo cấp lớp
                  DropdownButtonFormField<GradeLevel?>(
                    value: tempFilterGrade,
                    decoration: const InputDecoration(
                      labelText: 'Lọc theo lớp',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<GradeLevel?>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      ...GradeLevel.values.map((level) {
                        return DropdownMenuItem<GradeLevel?>(
                          value: level,
                          child: Text(level.label),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        tempFilterGrade = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Áp dụng bộ lọc
                    this.setState(() {
                      _showPublishedOnly = tempShowPublished;
                      _filterGradeLevel = tempFilterGrade;
                    });
                    
                    // Tải lại danh sách
                    _loadCourses();
                    
                    // Đóng dialog
                    Navigator.pop(context);
                  },
                  child: const Text('Áp dụng'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Chuyển đến màn hình tạo khóa học
  void _navigateToCreateCourse() async {
    final result = await Get.to(() => const CreateEditCourseScreen());
    if (result == true) {
      _loadCourses();
    }
  }
  
  // Chuyển đến màn hình chỉnh sửa khóa học
  void _navigateToEditCourse(Course course) async {
    final result = await Get.to(() => CreateEditCourseScreen(course: course));
    if (result == true) {
      _loadCourses();
    }
  }
  
  // Xây dựng danh sách khóa học
  Widget _buildCourseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề và hình ảnh
              course.imageUrl != null && course.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                      child: Image.network(
                        course.imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 80,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 80,
                      color: Colors.grey.shade100,
                      width: double.infinity,
                      child: Center(
                        child: Icon(
                          Icons.menu_book,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
              
              // Thông tin khóa học
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên và trạng thái
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: course.isPublished
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            course.isPublished ? 'Đã xuất bản' : 'Bản nháp',
                            style: TextStyle(
                              fontSize: 12,
                              color: course.isPublished
                                  ? Colors.green.shade800
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Mô tả
                    Text(
                      course.description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Thông tin chi tiết
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.class_,
                          course.gradeLevel.label,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.book,
                          course.isTextbook ? 'SGK' : 'Riêng',
                        ),
                        if (course.isTextbook && course.textbookName.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.bookmark,
                            course.textbookName,
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Các hành động
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _navigateToEditCourse(course),
                          icon: const Icon(Icons.edit),
                          label: const Text('Chỉnh sửa'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _deleteCourse(course),
                          icon: const Icon(Icons.delete),
                          label: const Text('Xóa'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Widget hiển thị thông tin dạng chip
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
} 