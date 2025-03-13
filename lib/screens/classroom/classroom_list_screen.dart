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

class ClassroomListScreen extends StatefulWidget {
  const ClassroomListScreen({Key? key}) : super(key: key);

  @override
  _ClassroomListScreenState createState() => _ClassroomListScreenState();
}

class _ClassroomListScreenState extends State<ClassroomListScreen>
    with SingleTickerProviderStateMixin {
  final ClassroomService _classroomService = ClassroomService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  
  List<Classroom> _teachingClassrooms = [];
  List<Classroom> _learningClassrooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClassrooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClassrooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw 'Vui lòng đăng nhập';
      }

      final classrooms = await _classroomService.getUserClassrooms(userId);
      
      setState(() {
        _teachingClassrooms = classrooms.where((c) => c.teacherId == userId).toList();
        _learningClassrooms = classrooms.where((c) => c.teacherId != userId).toList();
        _isLoading = false;
      });
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
        title: const Text('Lớp học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Get.to(() => const SearchClassroomsScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: () async {
              final result = await Get.to(() => const JoinByCodeScreen());
              if (result == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tham gia lớp học thành công')),
                );
                _loadClassrooms(); // Reload danh sách lớp sau khi tham gia
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đang dạy'),
            Tab(text: 'Đang học'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadClassrooms,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildClassroomList(_teachingClassrooms, isTeaching: true),
                    _buildClassroomList(_learningClassrooms, isTeaching: false),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const CreateEditClassroomScreen());
          if (result == true) {
            _loadClassrooms();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClassroomList(List<Classroom> classrooms, {required bool isTeaching}) {
    if (classrooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isTeaching ? Icons.class_ : Icons.school,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isTeaching
                  ? 'Bạn chưa tạo lớp học nào'
                  : 'Bạn chưa tham gia lớp học nào',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            if (isTeaching)
              ElevatedButton(
                onPressed: () async {
                  final result = await Get.to(() => const CreateEditClassroomScreen());
                  if (result == true) {
                    _loadClassrooms();
                  }
                },
                child: const Text('Tạo lớp học'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClassrooms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classrooms.length,
        itemBuilder: (context, index) {
          final classroom = classrooms[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () async {
                final result = await Get.to(
                  () => ClassroomDetailScreen(classroomId: classroom.id!),
                );
                if (result == true) {
                  _loadClassrooms();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (classroom.coverImage != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        classroom.coverImage!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                classroom.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Icon(
                              classroom.isPublic ? Icons.public : Icons.lock,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        if (classroom.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            classroom.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.group, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${classroom.memberIds.length} thành viên',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(classroom.updatedAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
} 