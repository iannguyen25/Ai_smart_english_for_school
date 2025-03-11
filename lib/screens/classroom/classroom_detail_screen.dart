import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/classroom.dart';
import '../../services/classroom_service.dart';
import '../../services/auth_service.dart';
import 'create_edit_classroom_screen.dart';
import 'member_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../services/user_service.dart';
import '../../models/app_user.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final String classroomId;

  const ClassroomDetailScreen({
    Key? key,
    required this.classroomId,
  }) : super(key: key);

  @override
  _ClassroomDetailScreenState createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen>
    with SingleTickerProviderStateMixin {
  final _classroomService = ClassroomService();
  final _userService = UserService();
  final _auth = auth.FirebaseAuth.instance;
  TabController? _tabController;
  Classroom? classroom;
  User? teacher;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isMember = false;
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _loadClassroom();
  }

  Future<void> _loadClassroom() async {
    try {
      setState(() => _isLoading = true);
      final data = await _classroomService.getClassroomById(widget.classroomId);

      // Load thông tin giáo viên
      final teacherData = await _userService.getUserById(data.teacherId);

      // Kiểm tra xem có phải là giáo viên không
      final authUser = _auth.currentUser;
      final isTeacher = authUser != null && data.teacherId == authUser.uid;

      // Tạo TabController mới
      _tabController?.dispose();
      _tabController = TabController(
        length: isTeacher ? 2 : 1,
        vsync: this,
      );

      setState(() {
        classroom = data;
        teacher = teacherData;
        _isMember = data.memberIds.contains(authUser?.uid);
        _isTeacher = isTeacher;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _joinClassroom() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'Vui lòng đăng nhập để tham gia lớp học';
      }

      await _classroomService.addMember(widget.classroomId, currentUser.uid!);

      Get.snackbar(
        'Thành công',
        'Đã tham gia lớp học',
        snackPosition: SnackPosition.BOTTOM,
      );

      _loadClassroom();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _leaveClassroom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rời lớp học'),
          content:
              const Text('Bạn có chắc chắn muốn rời khỏi lớp học này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Rời lớp'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw 'Vui lòng đăng nhập';

      await _classroomService.removeMember(
          widget.classroomId, currentUser.uid!);

      Get.snackbar(
        'Thành công',
        'Đã rời khỏi lớp học',
        snackPosition: SnackPosition.BOTTOM,
      );

      _loadClassroom();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _deleteClassroom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa lớp học'),
          content: const Text(
              'Bạn có chắc chắn muốn xóa lớp học này không? Hành động này không thể hoàn tác.'),
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

    try {
      await _classroomService.deleteClassroom(widget.classroomId);

      Get.back(result: true);
      Get.snackbar(
        'Thành công',
        'Đã xóa lớp học',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showOptions() {
    if (classroom == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isTeacher) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Chỉnh sửa'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Get.to(() => CreateEditClassroomScreen(
                          classroom: classroom,
                        ));
                    if (result == true) {
                      _loadClassroom();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.group_add),
                  title: const Text('Quản lý thành viên'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Get.to(() => MemberListScreen(
                          classroom: classroom!,
                        ));
                    if (result == true) {
                      _loadClassroom();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Chia sẻ mã mời'),
                  onTap: () {
                    Navigator.pop(context);
                    _showInviteCode();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Xóa lớp học',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteClassroom();
                  },
                ),
              ] else if (_isMember) ...[
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Rời lớp học',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _leaveClassroom();
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInviteCode() {
    if (classroom?.inviteCode == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Mã mời'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                classroom!.inviteCode!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chia sẻ mã này cho người khác để họ có thể tham gia lớp học',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: classroom!.inviteCode!));
                Get.snackbar(
                  'Thành công',
                  'Đã sao chép mã mời',
                  snackPosition: SnackPosition.BOTTOM,
                );
                Navigator.pop(context);
              },
              child: const Text('Sao chép'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || classroom == null || _tabController == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lớp học')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final authUser = _auth.currentUser;
    final isTeacher = authUser != null && classroom!.teacherId == authUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(classroom!.name),
        bottom: TabBar(
          controller: _tabController!,
          tabs: [
            const Tab(text: 'Thông tin'),
            if (isTeacher) const Tab(text: 'Chờ duyệt'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController!,
        children: [
          _buildInfoTab(),
          if (isTeacher) _buildPendingTab(),
        ],
      ),
      floatingActionButton: _isMember
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigate to assignments or study materials
              },
              icon: const Icon(Icons.book),
              label: const Text('Học tập'),
            )
          : null,
    );
  }

  Widget _buildInfoTab() {
    if (classroom == null) {
      return const Center(
        child: Text('Không tìm thấy lớp học'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (classroom!.coverImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                classroom!.coverImage!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),

          // Thông tin lớp học
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classroom!.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              classroom!.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      _buildJoinButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Giáo viên'),
                    subtitle: Text(
                      teacher?.fullName ?? 'Đang tải...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.group, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${classroom!.memberIds.length} thành viên',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (classroom!.isPublic) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.public, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Công khai',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Danh sách thành viên
          Card(
            child: ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Thành viên'),
              subtitle: Text('${classroom!.memberIds.length} người'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.to(() => MemberListScreen(classroom: classroom!));
              },
            ),
          ),
          const SizedBox(height: 16),

          // Các tính năng khác của lớp học sẽ được thêm ở đây
          // Ví dụ: Bài tập, tài liệu học tập, thông báo, v.v.
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    final authUser = _auth.currentUser;
    if (authUser == null) return const SizedBox.shrink();

    final isMember = classroom?.memberIds.contains(authUser.uid) ?? false;
    final isTeacher = classroom?.teacherId == authUser.uid;

    if (isTeacher) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: () async {
        try {
          if (isMember) {
            await _classroomService.leaveClassroom(widget.classroomId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã rời khỏi lớp học')),
            );
          } else {
            await _classroomService.joinClassroom(widget.classroomId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã tham gia lớp học')),
            );
          }
          // Reload classroom data
          _loadClassroom();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      },
      child: Text(isMember ? 'Rời lớp' : 'Tham gia'),
    );
  }

  Future<String> _getUserName(String userId) async {
    try {
      final user = await _userService.getUserById(userId);
      return (user?.firstName ?? "Unknown") + ' ' + (user?.lastName ?? "");
    } catch (e) {
      print('Error getting user name: $e');
      return 'Giáo viên';
    }
  }

  Widget _buildPendingTab() {
    if (classroom == null) return const SizedBox.shrink();

    final pendingMemberIds = classroom!.pendingMemberIds ?? [];

    if (pendingMemberIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có yêu cầu tham gia nào',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: pendingMemberIds.length,
      itemBuilder: (context, index) {
        final userId = pendingMemberIds[index];
        return FutureBuilder<User?>(
          future: _userService.getUserById(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                leading: CircleAvatar(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                title: Text('Đang tải...'),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.error_outline),
                ),
                title: Text('Lỗi: ${snapshot.error}'),
              );
            }

            final user = snapshot.data!;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    user.avatar != null ? NetworkImage(user.avatar!) : null,
                child: user.avatar == null
                    ? Text(user.firstName![0].toUpperCase())
                    : null,
              ),
              title: Text(user.fullName),
              subtitle: Text(user.email ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    color: Colors.green,
                    onPressed: () async {
                      try {
                        await _classroomService.approveMember(
                          widget.classroomId,
                          userId,
                        );
                        _loadClassroom(); // Reload data
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã chấp nhận yêu cầu tham gia')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                  ),
                  // Nút từ chối
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    color: Colors.red,
                    onPressed: () async {
                      try {
                        await _classroomService.rejectMember(
                          widget.classroomId,
                          userId,
                        );
                        _loadClassroom(); // Reload data
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Đã từ chối yêu cầu tham gia')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
