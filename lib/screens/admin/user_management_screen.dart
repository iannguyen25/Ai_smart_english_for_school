import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import 'create_user_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AuthService _authService = AuthService();
  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Tải danh sách người dùng từ Firestore
      final users = await User.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách người dùng: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem người dùng hiện tại có phải quản trị viên không
    if (!_authService.isCurrentUserAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quản lý người dùng')),
        body: const Center(
          child: Text(
            'Bạn không có quyền truy cập màn hình này.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, 
                          size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('Chưa có người dùng nào.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Get.to(() => const CreateUserScreen())
                                  ?.then((value) {
                                if (value == true) {
                                  _loadUsers();
                                }
                              });
                            },
                            child: const Text('Tạo người dùng mới'),
                          ),
                        ],
                      ),
                    )
                  : _buildUserList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const CreateUserScreen())?.then((value) {
            if (value == true) {
              _loadUsers();
            }
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Tạo người dùng mới',
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                user.firstName != null && user.firstName!.isNotEmpty
                    ? user.firstName![0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!user.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Đã khóa',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(user.email ?? 'email@example.com'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      user.roleId == 'admin'
                          ? 'Quản trị viên'
                          : user.roleId == 'teacher'
                              ? 'Giáo viên'
                              : 'Học sinh',
                      style: TextStyle(
                        color: user.roleId == 'admin'
                            ? Colors.red
                            : user.roleId == 'teacher'
                                ? Colors.green
                                : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!user.isActive) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• Tài khoản bị khóa',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                _showUserOptions(user);
              },
            ),
          ),
        );
      },
    );
  }

  void _showUserOptions(User user) {
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
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Chỉnh sửa'),
              onTap: () {
                Get.back();
                // Mở màn hình chỉnh sửa người dùng
                Get.to(() => CreateUserScreen(user: user))?.then((value) {
                  if (value == true) {
                    _loadUsers();
                  }
                });
              },
            ),
            ListTile(
              leading: Icon(
                user.isActive ? Icons.lock : Icons.lock_open,
                color: user.isActive ? Colors.red : Colors.green,
              ),
              title: Text(
                user.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                style: TextStyle(
                  color: user.isActive ? Colors.red : Colors.green,
                ),
              ),
              onTap: () {
                Get.back();
                _toggleUserActive(user);
              },
            ),
            if (user.roleId != 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Đặt làm quản trị viên'),
                onTap: () {
                  Get.back();
                  _setUserAsAdmin(user);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    // Xác nhận xóa người dùng
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa người dùng ${user.fullName}?'),
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

    if (confirm == true) {
      try {
        final success = await User.deleteUser(user.id!);
        if (success) {
          Get.snackbar(
            'Thành công',
            'Đã xóa người dùng',
            snackPosition: SnackPosition.BOTTOM,
          );
          _loadUsers();
        } else {
          Get.snackbar(
            'Lỗi',
            'Không thể xóa người dùng',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Lỗi',
          'Không thể xóa người dùng: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _setUserAsAdmin(User user) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận thay đổi'),
        content: Text('Bạn có chắc chắn muốn đặt ${user.fullName} là quản trị viên?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Cập nhật vai trò của người dùng trong Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.id)
            .update({'roleId': 'admin'});
            
        Get.snackbar(
          'Thành công',
          'Đã đặt người dùng làm quản trị viên',
          snackPosition: SnackPosition.BOTTOM,
        );
        _loadUsers();
      } catch (e) {
        Get.snackbar(
          'Lỗi',
          'Không thể cập nhật vai trò người dùng: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  Future<void> _toggleUserActive(User user) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text(user.isActive ? 'Xác nhận khóa tài khoản' : 'Xác nhận mở khóa tài khoản'),
        content: Text(
          user.isActive
              ? 'Bạn có chắc chắn muốn khóa tài khoản của ${user.fullName}?'
              : 'Bạn có chắc chắn muốn mở khóa tài khoản của ${user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: user.isActive ? Colors.red : Colors.green,
            ),
            child: Text(user.isActive ? 'Khóa' : 'Mở khóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await _authService.toggleUserActive(user.id!, !user.isActive);
        if (result.success) {
          Get.snackbar(
            'Thành công',
            user.isActive ? 'Đã khóa tài khoản' : 'Đã mở khóa tài khoản',
            snackPosition: SnackPosition.BOTTOM,
          );
          _loadUsers();
        } else {
          Get.snackbar(
            'Lỗi',
            result.error ?? 'Không thể thực hiện thao tác',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
        Get.snackbar(
          'Lỗi',
          'Không thể thực hiện thao tác: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
} 