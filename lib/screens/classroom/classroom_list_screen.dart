import 'package:base_flutter_framework/models/course.dart';
import 'package:base_flutter_framework/screens/classroom/join_by_code_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/classroom.dart';
import '../../services/classroom_service.dart';
import '../../services/auth_service.dart';
import 'classroom_detail_screen.dart';
import 'create_edit_classroom_screen.dart';
import 'search_classrooms_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../models/app_user.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../services/course_service.dart';

class ClassroomListScreen extends StatefulWidget {
  const ClassroomListScreen({Key? key}) : super(key: key);

  @override
  _ClassroomListScreenState createState() => _ClassroomListScreenState();
}

class _ClassroomListScreenState extends State<ClassroomListScreen>
    with SingleTickerProviderStateMixin {
  final ClassroomService _classroomService = ClassroomService();
  final AuthService _authService = AuthService();
  final CourseService _courseService = CourseService();
  late TabController _tabController;

  List<Classroom> _teachingClassrooms = [];
  List<Classroom> _learningClassrooms = [];
  List<Course> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedCourseId;

  // Thêm getter để kiểm tra vai trò
  bool get _showTeachingTab => _authService.isCurrentUserTeacher || _authService.isCurrentUserAdmin;
  bool get _showLearningTab => !_authService.isCurrentUserTeacher || _authService.isCurrentUserAdmin;
  
  // Tính số lượng tab dựa trên vai trò
  int get _tabCount {
    if (_authService.isCurrentUserAdmin) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw 'Vui lòng đăng nhập';
      }

      // Load courses
      print('Loading courses...');
      _courses = await _courseService.getAllCourses();
      print('Loaded ${_courses.length} courses: ${_courses.map((c) => c.name).join(', ')}');

      // Load classrooms
      final classrooms = await _classroomService.getUserClassrooms(userId);

      setState(() {
        _teachingClassrooms =
            classrooms.where((c) => c.teacherId == userId).toList();
        _learningClassrooms =
            classrooms.where((c) => c.memberIds.contains(userId)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Classroom> _getFilteredClassrooms(List<Classroom> classrooms) {
    if (_selectedCourseId == null) return classrooms;
    return classrooms.where((c) => c.courseId == _selectedCourseId).toList();
  }

  @override
  Widget build(BuildContext context) {
    print('Building with ${_courses.length} courses');
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        // backgroundColor: const Color.fromARGB(255, 181, 232, 249),
        title: const Text(
          'Lớp học',
          style: TextStyle(
              color: Colors.black, fontSize: 24, fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            if (_showTeachingTab)
              const Tab(text: '    Dạy    '),
            if (_showLearningTab)
              const Tab(text: '    Học    '),
          ],
          indicatorWeight: 3,
          indicatorColor: Colors.black.withOpacity(0.5),
          labelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
          unselectedLabelStyle:
              const TextStyle(fontSize: 14, color: Colors.black),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black.withOpacity(0.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Get.to(() => const SearchClassroomsScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_alt_outlined),
            onPressed: () => Get.to(() => const JoinByCodeScreen()),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 222, 242, 249),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Thêm dropdown lọc theo khóa học
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.white,
                      child: DropdownButton<String>(
                        value: _selectedCourseId,
                        hint: const Text('Lọc theo khóa học'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Tất cả'),
                          ),
                          ..._courses.map((course) => DropdownMenuItem(
                                value: course.id,
                                child: Text(course.name),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCourseId = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          if (_showTeachingTab)
                            // Tab Dạy
                            RefreshIndicator(
                              onRefresh: _loadData,
                              child: _getFilteredClassrooms(_teachingClassrooms).isEmpty
                                  ? _buildEmptyState(true)
                                  : _buildClassroomGrid(_getFilteredClassrooms(_teachingClassrooms), true),
                            ),
                          if (_showLearningTab)
                            // Tab Học
                            RefreshIndicator(
                              onRefresh: _loadData,
                              child: _getFilteredClassrooms(_learningClassrooms).isEmpty
                                  ? _buildEmptyState(false)
                                  : _buildClassroomGrid(_getFilteredClassrooms(_learningClassrooms), false),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _showTeachingTab
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Get.to(() => const CreateEditClassroomScreen());
                if (result == true) {
                  _loadData();
                }
              },
              child: const Icon(Icons.add),
              tooltip: 'Tạo lớp học mới',
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isTeachingTab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTeachingTab ? Icons.school_outlined : Icons.menu_book_outlined,
              size: 80,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isTeachingTab ? 'Chưa có lớp dạy nào' : 'Chưa tham gia lớp học nào',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isTeachingTab
                ? 'Tạo lớp học để bắt đầu dạy học'
                : 'Tham gia lớp học để bắt đầu học',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              if (isTeachingTab) {
                final result =
                    await Get.to(() => const CreateEditClassroomScreen());
                if (result == true) {
                  _loadData();
                }
              } else {
                Get.to(() {}
                    // => const JoinClassroomScreen()
                    );
              }
            },
            icon: Icon(isTeachingTab ? Icons.add : Icons.group_add),
            label: Text(isTeachingTab ? 'Tạo lớp học mới' : 'Tham gia lớp học'),
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

  Widget _buildClassroomGrid(List<Classroom> classrooms, bool isTeachingTab) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: classrooms.length,
        itemBuilder: (context, index) {
          final classroom = classrooms[index];
          return _buildClassroomCard(classroom, isTeachingTab);
        },
      ),
    );
  }

  Widget _buildClassroomCard(Classroom classroom, bool isTeachingTab) {
    final classroomColors = [
      const Color(0xFFE8F5E9), // Light Green
      const Color(0xFFE3F2FD), // Light Blue
      const Color(0xFFF3E5F5), // Light Purple
      const Color(0xFFE0F7FA), // Light Cyan
      const Color(0xFFFFF3E0), // Light Orange
      const Color(0xFFEDE7F6), // Light Deep Purple
    ];

    // Sử dụng hash của ID classroom để chọn màu cố định cho mỗi classroom
    final colorIndex = classroom.id.hashCode % classroomColors.length;
    final classroomColor = classroomColors[colorIndex.abs()];

    return GestureDetector(
      onTap: () =>
          Get.to(() => ClassroomDetailScreen(classroomId: classroom.id!)),
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
            // Classroom header
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: classroomColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  isTeachingTab ? Icons.school : Icons.menu_book,
                  size: 40,
                  color: classroomColor.withOpacity(0.8),
                ),
              ),
            ),
            // Classroom info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            classroom.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isTeachingTab)
                          GestureDetector(
                            onTap: () => _showClassroomOptions(classroom),
                            child: const Icon(
                              Icons.more_vert,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      classroom.description,
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
                          Icons.people_outline,
                          '${classroom.memberIds.length}',
                        ),
                        _buildStat(
                          Icons.calendar_today_outlined,
                          _formatDate(classroom.createdAt),
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

  void _showClassroomOptions(Classroom classroom) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_authService.isCurrentUserAdmin || _authService.isCurrentUserAdmin) ... [ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa'),
              onTap: () async {
                Get.back();
                final result = await Get.to(
                  () => CreateEditClassroomScreen(classroom: classroom),
                );
                if (result == true) {
                  _loadData();
                }
              },
            ),],
            if (_authService.isCurrentUserAdmin)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () => _deleteClassroom(classroom),
              ),
            if (_authService.isCurrentUserAdmin || _authService.isCurrentUserAdmin)
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ mã lớp'),
                onTap: () {
                  Get.back();
                  _shareClassroomCode(classroom);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteClassroom(Classroom classroom) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xóa lớp học'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa lớp học này không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      Get.back(); // Đóng bottom sheet
      return;
    }

    try {
      Get.back(); // Đóng bottom sheet
      await _classroomService.deleteClassroom(classroom.id!);
      _loadData(); // Tải lại danh sách
      
      Get.snackbar(
        'Thành công',
        'Đã xóa lớp học',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xóa lớp học: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _shareClassroomCode(Classroom classroom) {
    Get.dialog(
      AlertDialog(
        title: const Text('Mã lớp học'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chia sẻ mã này cho học viên để họ có thể tham gia lớp học của bạn:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    classroom.inviteCode ?? "",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: classroom.inviteCode ?? ""));
                      Get.snackbar(
                        'Đã sao chép',
                        'Mã lớp học đã được sao chép vào bộ nhớ tạm',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }
}
