import 'package:base_flutter_framework/screens/admin/admin_dashboard_screen.dart';
import 'package:base_flutter_framework/screens/flashcards/create_edit_flashcard_screen.dart';
import 'package:base_flutter_framework/screens/folder/create_edit_folder_screen.dart';
import 'package:base_flutter_framework/screens/home/tabs/ai_chat_tab.dart';
import 'package:base_flutter_framework/screens/home/tabs/flashcards_tab.dart';
import 'package:base_flutter_framework/screens/home/tabs/folders_tab.dart';
import 'package:base_flutter_framework/screens/notifications/notification_history_screen.dart';
import 'package:base_flutter_framework/screens/settings/notification_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../classroom/classroom_list_screen.dart';
import '../../classroom/join_by_code_screen.dart';
import '../../classroom/create_edit_classroom_screen.dart';
import '../../translate/translate_screen.dart';
import '../../../models/classroom.dart';
import '../../../models/user.dart';
import '../../../services/classroom_service.dart';
import '../../../services/auth_service.dart';
import '../../admin/user_management_screen.dart';
import '../../admin/course_management_screen.dart';
import '../../admin/content_management_screen.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  _DashboardTabState createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final ClassroomService _classroomService = ClassroomService();
  final AuthService _authService = AuthService();

  List<Classroom> _recentClassrooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecentClassrooms();
  }

  Future<void> _loadRecentClassrooms() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final classrooms = await _classroomService.getUserClassrooms(userId);
      setState(() {
        _recentClassrooms =
            classrooms.take(3).toList(); // Chỉ lấy 3 lớp gần đây nhất
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
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Get.to(() => const NotificationHistoryScreen());
            },
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 166, 234, 255),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chào mừng quay trở lại, ${user?.firstName ?? 'Student'}!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hãy tiếp tục hành trình học tập của bạn',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Learning progress
            Text(
              'Lớp học',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Quick Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                // Xem danh sách lớp học
                _buildQuickActionCard(
                  icon: Icons.class_,
                  title: 'Danh sách lớp học',
                  subtitle: 'Xem tất cả lớp học của bạn',
                  onTap: () => Get.to(() => const ClassroomListScreen()),
                  color: Colors.blue,
                ),

                

                // Tham gia lớp học
                _buildQuickActionCard(
                  width: double.infinity,
                  icon: Icons.keyboard,
                  title: 'Nhập mã lớp',
                  subtitle: 'Tham gia lớp học bằng mã',
                  onTap: () async {
                    final result = await Get.to(() => const JoinByCodeScreen());
                    if (result == true) {
                      // Refresh nếu cần
                    }
                  },
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Text(
            //   'Flashcard',
            //   style: Theme.of(context).textTheme.titleLarge,
            // ),
            // const SizedBox(height: 16),

            // GridView.count(
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   crossAxisCount: 2,
            //   mainAxisSpacing: 16,
            //   crossAxisSpacing: 16,
            //   childAspectRatio: 1.5,
            //   children: [
            //     _buildQuickActionCard(
            //       icon: Icons.collections,
            //       title: 'Danh sách flashcard',
            //       subtitle: 'Xem tất cả flashcard của bạn',
            //       onTap: () => Get.to(() => const FlashcardsTab()),
            //       color: Colors.blue,
            //     ),
            //     _buildQuickActionCard(
            //       icon: Icons.add_circle_outline,
            //       title: 'Tạo flashcard',
            //       subtitle: 'Tạo flashcard mới',
            //       onTap: () {
            //         Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => CreateEditFlashcardScreen(),
            //           ),
            //         );
            //       },
            //       color: Colors.green,
            //     ),
            //   ],
            // ),

            // const SizedBox(height: 24),

            Text(
              'Tra từ điển',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3.0,
              children: [
                _buildQuickActionCard(
                  icon: Icons.translate,
                  title: 'Tra từ điển',
                  subtitle: 'Tìm kiếm từ và thêm vào bộ thẻ ghi nhớ',
                  onTap: () => Get.to(() => TranslateScreen()),
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

             Text(
              'Hỏi đáp cùng AI',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3.0,
              children: [
                _buildQuickActionCard(
                  icon: Icons.translate,
                  title: 'Hỏi đáp cùng AI',
                  subtitle: 'Hỏi đáp cùng AI',
                  onTap: () => Get.to(() =>  AIChatTab()),
                  color: Colors.purple,
                ),
              ],
            ),

            // Text(
            //   'Thư mục',
            //   style: Theme.of(context).textTheme.titleLarge,
            // ),
            // const SizedBox(height: 16),

            // GridView.count(
            //   shrinkWrap: true,
            //   physics: const NeverScrollableScrollPhysics(),
            //   crossAxisCount: 2,
            //   mainAxisSpacing: 16,
            //   crossAxisSpacing: 16,
            //   childAspectRatio: 1.5,
            //   children: [
            //     _buildQuickActionCard(
            //       icon: Icons.collections,
            //       title: 'Danh sách thư mục',
            //       subtitle: 'Xem tất cả thư mục của bạn',
            //       onTap: () => Get.to(() => const FoldersTab()),
            //       color: Colors.blue,
            //     ),
            //     _buildQuickActionCard(
            //       icon: Icons.add_circle_outline,
            //       title: 'Tạo folder',
            //       subtitle: 'Tạo folder mới',
            //       onTap: () {
            //         Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => CreateEditFolderScreen(),
            //           ),
            //         );
            //       },
            //       color: Colors.green,
            //     ),
            //   ],
            // ),

            const SizedBox(height: 24),

            // Admin Management Section
            if (_authService.currentUser?.roleId == 'admin') ...[
              Text(
                'Quản lý hệ thống',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildQuickActionCard(
                    icon: Icons.people,
                    title: 'Quản lý người dùng',
                    subtitle: 'Quản lý tài khoản và phân quyền',
                    onTap: () => Get.to(() => const UserManagementScreen()),
                    color: Colors.blue,
                  ),
                  _buildQuickActionCard(
                    icon: Icons.school,
                    title: 'Quản lý khóa học',
                    subtitle: 'Quản lý khóa học và bài học',
                    onTap: () => Get.to(() => const CourseManagementScreen()),
                    color: Colors.green,
                  ),
                  _buildQuickActionCard(
                    icon: Icons.article,
                    title: 'Quản lý nội dung',
                    subtitle: 'Duyệt và quản lý nội dung',
                    onTap: () => Get.to(() => const ContentManagementScreen()),
                    color: Colors.orange,
                  ),
                  _buildQuickActionCard(
                    icon: Icons.article,
                    title: 'Dashboard tổng quan',
                    subtitle: 'Duyệt và quản lý nội dung',
                    onTap: () => Get.to(() => const AdminDashboardScreen()),
                    color: Colors.purple,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    double? width,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    softWrap: true,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    String title,
    double progress,
    Color color,
  ) {
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
