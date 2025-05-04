import 'package:base_flutter_framework/screens/admin/admin_dashboard_screen.dart';
import 'package:base_flutter_framework/screens/classroom/classroom_list_screen.dart';
import 'package:base_flutter_framework/screens/notifications/notification_history_screen.dart';
import 'package:base_flutter_framework/screens/profile/delete_account_screen.dart';
import 'package:base_flutter_framework/screens/profile/edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/app_user.dart';
import '../../../services/auth_service.dart';
import '../../../services/streak_service.dart';
import '../../../services/badge_service.dart';
import '../../auth/login_screen.dart';
import '../../admin/user_management_screen.dart';
import '../../materials/teacher_materials_screen.dart';
import '../../materials/student_materials_screen.dart';
import '../../profile/badges_screen.dart';
import '../../settings/notification_settings_screen.dart';
import '../../../services/notification_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthService _authService = AuthService();
  final StreakService _streakService = StreakService();
  final BadgeService _badgeService = BadgeService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoadingStats = true;
  int _currentStreak = 0;
  int _longestStreak = 0;
  int _badgeCount = 0;
  int _unreadNotificationCount = 0;
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    // Đảm bảo dữ liệu người dùng được tải khi tab được tạo
    _refreshUserData();
    // Chỉ tải dữ liệu streak và badge cho học sinh
    final user = _authService.currentUser;
    if (user != null && user.roleId == 'student') {
      _loadUserStats();
      _updateStreak();
    }
    _loadUnreadNotifications();
  }

  // Phương thức để tải lại dữ liệu người dùng
  Future<void> _refreshUserData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        await _authService.refreshUserData(currentUser.id!);
        _loadUserStats();
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  // Phương thức tải dữ liệu thống kê của người dùng
  Future<void> _loadUserStats() async {
    setState(() => _isLoadingStats = true);
    
    try {
      // Lấy thông tin streak
      final streakData = await _streakService.getUserStreak();
      
      // Lấy số lượng huy hiệu
      final badgeCount = await _getBadgeCount();
      
      setState(() {
        _currentStreak = streakData['currentStreak'] ?? 0;
        _longestStreak = streakData['longestStreak'] ?? 0;
        _badgeCount = badgeCount;
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error loading user stats: $e');
      setState(() => _isLoadingStats = false);
    }
  }
  
  // Phương thức đếm số lượng huy hiệu
  Future<int> _getBadgeCount() async {
    try {
      final badges = await _badgeService.getUserBadges();
      return badges.length;
    } catch (e) {
      print('Error getting badge count: $e');
      return 0;
    }
  }
  
  // Cập nhật streak khi vào profile tab
  Future<void> _updateStreak() async {
    try {
      await _streakService.updateStreak();
      // Tải lại dữ liệu streak sau khi cập nhật
      _loadUserStats();
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  Future<void> _loadUnreadNotifications() async {
    setState(() => _isLoadingNotifications = true);
    
    try {
      final count = await _notificationService.getUnreadNotificationCount();
      setState(() {
        _unreadNotificationCount = count;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      print('Error loading unread notifications: $e');
      setState(() => _isLoadingNotifications = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.currentUserStream,
      builder: (context, snapshot) {
        final user = snapshot.data ?? _authService.currentUser;

        if (user == null) {
          return const Center(
            child: Text('Vui lòng đăng nhập lại'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Navigate to settings
                },
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 166, 234, 255),
          body: RefreshIndicator(
            onRefresh: _refreshUserData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Profile picture with edit button
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              user.avatar != null && user.avatar!.isNotEmpty
                                  ? NetworkImage(user.avatar!)
                                  : null,
                          child: (user.avatar == null || user.avatar!.isEmpty)
                              ? Icon(Icons.person,
                                  size: 60, color: Colors.grey.shade600)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () async {
                            final result = await Get.to(
                                () => EditProfileScreen(user: user));
                            if (result != null) {
                              // Tải lại dữ liệu người dùng khi quay lại từ màn hình chỉnh sửa
                              _refreshUserData();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // User name
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),

                  // User email
                  Text(
                    user.email ?? 'email@example.com',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  // // Stats section
                  // _buildStatsSection(context),
                  // const SizedBox(height: 32),
                  
                  // Streak and Badges card
                  _buildStreakAndBadgesCard(context),
                  const SizedBox(height: 32),

                  // Options section
                  _buildOptionsSection(),
                  const SizedBox(height: 32),

                  // Sign out button
                  ElevatedButton.icon(
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _authService.signOut();
      Get.offAll(() => LoginScreen());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  Widget _buildStreakAndBadgesCard(BuildContext context) {
    final user = _authService.currentUser;
    // Chỉ hiển thị cho học sinh
    if (user == null || user.roleId != 'student') {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thành tích',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                GestureDetector(
                  onTap: () => Get.to(() => const BadgesScreen()),
                  child: Row(
                    children: [
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Streak row
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chuỗi ngày học',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _isLoadingStats
                          ? const LinearProgressIndicator()
                          : Row(
                              children: [
                                Text(
                                  '$_currentStreak ngày hiện tại',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(Kỷ lục: $_longestStreak ngày)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Badges row
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Huy hiệu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _isLoadingStats
                          ? const LinearProgressIndicator()
                          : Text(
                              'Đạt được $_badgeCount huy hiệu',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Get.to(() => const BadgesScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Xem'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    final user = _authService.currentUser;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tùy chọn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildOptionTile(
              'Chỉnh sửa thông tin',
              Icons.edit,
              () => Get.to(() => EditProfileScreen(user: user ?? User())),
            ),
            _buildOptionTile(
              'Lớp học của tôi',
              Icons.class_,
              () => Get.to(() => const ClassroomListScreen()),
            ),
            _buildOptionTile(
              'Huy hiệu của tôi',
              Icons.emoji_events,
              () => Get.to(() => const BadgesScreen()),
            ),
            _buildOptionTile(
              'Thông báo',
              Icons.notifications_active,
              () => Get.to(() => const NotificationHistoryScreen()),
              badgeCount: _unreadNotificationCount,
            ),
            _buildOptionTile(
              'Lời nhắc học tập',
              Icons.alarm,
              () => AlertDialog(
                title: const Text('Chức năng đang phát triển'),
                content: const Text('Chức năng đang phát triển'),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
            _buildOptionTile(
              'Cài đặt thông báo',
              Icons.notifications,
              () => Get.to(() => const NotificationSettingsScreen()),
            ),
            // _buildOptionTile(
            //   'Cài đặt ngôn ngữ',
            //   Icons.language,
            //   () => Get.toNamed('/language_settings'),
            // ),
            if (_authService.isCurrentUserAdmin)
              _buildOptionTile(
                'Dashboard',
                Icons.dashboard,
                () => Get.to(() => const AdminDashboardScreen()),
              ),
              // _buildOptionTile(
              //   'Trợ giúp & Hỗ trợ',
              //   Icons.help,
              //   () => Get.toNamed('/help'),
              // ),
            // Chỉ hiển thị quản lý người dùng cho admin
            if (_authService.isCurrentUserAdmin)
              _buildOptionTile(
                'Quản lý người dùng',
                Icons.admin_panel_settings,
                () => Get.to(() => const UserManagementScreen()),
              ),
            // Thêm tùy chọn quản lý tài liệu học tập
            if (_authService.isCurrentUserAdmin || _authService.isCurrentUserTeacher)
              _buildOptionTile(
                'Quản lý tài liệu',
                Icons.menu_book,
                () => Get.to(() => const TeacherMaterialsScreen()),
              ),
            _buildOptionTile(
              'Thư viện tài liệu',
              Icons.library_books,
              () => Get.to(() => const StudentMaterialsScreen()),
            ),
            if (_authService.isCurrentUserAdmin)
            _buildOptionTile(
              'Xóa tài khoản',
              Icons.delete_forever,
              () => Get.to(() => DeleteAccountScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String title, IconData icon, VoidCallback onTap, {int? badgeCount}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: badgeCount != null && badgeCount > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
