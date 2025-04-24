import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/classroom.dart';
import '../../models/app_user.dart';
import '../../services/classroom_service.dart';
import '../../services/auth_service.dart';

class MemberListScreen extends StatefulWidget {
  final Classroom classroom;

  const MemberListScreen({
    Key? key,
    required this.classroom,
  }) : super(key: key);

  @override
  _MemberListScreenState createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  final ClassroomService _classroomService = ClassroomService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String? _errorMessage;
  List<User> _members = [];
  List<User> _pendingMembers = [];
  bool _isTeacher = false;
  late Classroom _classroom;

  @override
  void initState() {
    super.initState();
    _classroom = widget.classroom;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Refresh classroom data first
      final updatedClassroom = await _classroomService.getClassroom(_classroom.id!);
      if (updatedClassroom != null) {
        _classroom = updatedClassroom;
      }

      final currentUser = _authService.currentUser;
      _isTeacher = _classroom.teacherId == currentUser?.id;

      // Load approved members
      final members = await Future.wait(
        _classroom.memberIds
            .map((id) => _authService.getUserByIdCached(id)),
      );

      // Load pending members
      final pendingMembers = await Future.wait(
        _classroom.pendingMemberIds
            .map((id) => _authService.getUserByIdCached(id)),
      );

      if (mounted) {
        setState(() {
          _members = members.whereType<User>().toList();
          _pendingMembers = pendingMembers.whereType<User>().toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveMember(User user) async {
    setState(() => _isLoading = true);
    
    try {
      await _classroomService.approveStudent(_classroom.id!, user.id!);
      await _loadMembers(); // Refresh the data
      
      Get.snackbar(
        'Thành công',
        'Đã phê duyệt ${user.firstName} ${user.lastName}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Lỗi',
        'Không thể phê duyệt thành viên: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rejectMember(User user) async {
    setState(() => _isLoading = true);
    
    try {
      await _classroomService.rejectStudent(_classroom.id!, user.id!);
      await _loadMembers(); // Refresh the data
      
      Get.snackbar(
        'Thành công',
        'Đã từ chối ${user.firstName} ${user.lastName}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Lỗi',
        'Không thể từ chối thành viên: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _removeMember(User user) async {
    // Show confirmation dialog
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn xóa ${user.firstName} ${user.lastName} khỏi lớp học không?'),
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

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    try {
      await _classroomService.removeMember(_classroom.id!, user.id!);
      await _loadMembers(); // Refresh the data
      
      Get.snackbar(
        'Thành công',
        'Đã xóa ${user.firstName} ${user.lastName} khỏi lớp học',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar(
        'Lỗi',
        'Không thể xóa thành viên: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý thành viên'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMembers,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_pendingMembers.isNotEmpty && _isTeacher) ...[
            const Text(
              'Đang chờ duyệt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingMembers.length,
              itemBuilder: (context, index) {
                final member = _pendingMembers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          member.avatar != null ? NetworkImage(member.avatar!) : null,
                      child: member.avatar == null
                          ? Text(member.firstName![0].toUpperCase())
                          : null,
                    ),
                    title: Text('${member.firstName} ${member.lastName}'),
                    subtitle: const Text('Đang chờ duyệt'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          color: Colors.green,
                          onPressed: () => _approveMember(member),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined),
                          color: Colors.red,
                          onPressed: () => _rejectMember(member),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 32),
          ],
          
          const Text(
            'Thành viên',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              final member = _members[index];
              final isTeacher = member.id == _classroom.teacherId;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        member.avatar != null ? NetworkImage(member.avatar!) : null,
                    child: member.avatar == null
                        ? Text(member.firstName![0].toUpperCase())
                        : null,
                  ),
                  title: Text('${member.firstName} ${member.lastName}'),
                  subtitle: Text(isTeacher ? 'Giáo viên' : 'Học viên'),
                  trailing: _isTeacher && !isTeacher
                      ? IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.red,
                          onPressed: () => _removeMember(member),
                        )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
