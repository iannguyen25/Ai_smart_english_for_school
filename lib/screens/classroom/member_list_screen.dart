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
  bool _isTeacher = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _authService.currentUser;
      _isTeacher = widget.classroom.teacherId == currentUser?.id;

      final members = await Future.wait(
        widget.classroom.memberIds
            .map((id) => _authService.getUserByIdCached(id)),
      );

      setState(() {
        _members = members.whereType<User>().toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _removeMember(User member) async {
    if (!_isTeacher || member.id == widget.classroom.teacherId) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa thành viên'),
          content: Text(
              'Bạn có chắc chắn muốn xóa ${member.firstName} ${member.lastName} khỏi lớp học không?'),
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
      await _classroomService.removeMember(widget.classroom.id!, member.id!);

      setState(() {
        _members.removeWhere((m) => m.id == member.id);
      });

      Get.snackbar(
        'Thành công',
        'Đã xóa thành viên khỏi lớp học',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thành viên'),
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final isTeacher = member.id == widget.classroom.teacherId;

        return Card(
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
    );
  }
}
