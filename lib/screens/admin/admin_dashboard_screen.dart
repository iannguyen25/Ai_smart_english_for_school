import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../utils/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'user_management_screen.dart';
import 'create_edit_course_screen.dart';
import 'course_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  
  // Dữ liệu báo cáo
  Map<String, dynamic> _systemOverview = {};
  Map<String, dynamic> _resourcesReport = {};
  
  // Thời gian báo cáo
  int _selectedPeriod = 30; // Mặc định 30 ngày
  final List<int> _periodOptions = [7, 30, 90];
  
  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  // Tải dữ liệu dashboard
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Tải tổng quan hệ thống
      final systemOverview = await _analyticsService.getSystemOverview(
        days: _selectedPeriod,
      );
      
      // Tải báo cáo tài nguyên học tập
      final resourcesReport = await _analyticsService.getLearningResourcesReport(
        days: _selectedPeriod,
      );
      
      if (mounted) {
        setState(() {
          _systemOverview = systemOverview;
          _resourcesReport = resourcesReport;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(
          context: context,
          message: 'Không thể tải dữ liệu dashboard: ${e.toString()}',
        );
      }
    }
  }
  
  // Thay đổi khoảng thời gian
  void _changePeriod(int days) {
    setState(() {
      _selectedPeriod = days;
    });
    _loadDashboardData();
  }
  
  // Thêm phương thức để mở màn hình quản lý khóa học
  void _navigateToCourseManagement() {
    Get.to(() => const CourseManagementScreen());
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 82, 81, 81),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<int>(
            tooltip: 'Chọn khoảng thời gian',
            icon: const Icon(Icons.date_range, color: Colors.white),
            onSelected: _changePeriod,
            itemBuilder: (context) => _periodOptions
                .map((days) => PopupMenuItem<int>(
                      value: days,
                      child: Text('$days ngày${_selectedPeriod == days ? ' ✓' : ''}'),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboard(),
    );
  }
  
  // Xây dựng dashboard
  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với thời gian
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Thống kê ${_selectedPeriod} ngày gần đây',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Thống kê tổng quan
            _buildOverviewStats(),
            
            const SizedBox(height: 24),
            
            // Thống kê tài nguyên
            _buildResourcesStats(),
            
            const SizedBox(height: 24),
            
            // Bài học có vấn đề
            if (_resourcesReport.containsKey('problematicLessons') &&
                (_resourcesReport['problematicLessons'] as List).isNotEmpty)
              _buildProblematicLessons(),
            
            const SizedBox(height: 24),
            
            // Nội dung chờ duyệt
            _buildPendingContentSection(),
          ],
        ),
      ),
    );
  }
  
  // Thống kê tổng quan
  Widget _buildOverviewStats() {
    return Card(
      elevation: 0,
      color: const Color(0xFF2D2D2D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Thống kê tổng quan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Người dùng',
                  '${_systemOverview['totalUsers'] ?? 0}',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Lớp học',
                  '${_systemOverview['totalClassrooms'] ?? 0}',
                  Icons.class_,
                  Colors.green,
                ),
                _buildStatCard(
                  'Bài học',
                  '${_systemOverview['totalLessons'] ?? 0}',
                  Icons.book,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Flashcards',
                  '${_systemOverview['totalFlashcards'] ?? 0}',
                  Icons.card_membership,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Thẻ thống kê đơn
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Thống kê tài nguyên học tập
  Widget _buildResourcesStats() {
    final newResourcesData = [
      {
        'title': 'Bài học',
        'total': _resourcesReport['totalLessons'] ?? 0,
        'new': _resourcesReport['newLessons'] ?? 0,
        'icon': Icons.book,
        'color': Colors.blue,
      },
      {
        'title': 'Flashcards',
        'total': _resourcesReport['totalFlashcards'] ?? 0,
        'new': _resourcesReport['newFlashcards'] ?? 0,
        'icon': Icons.card_membership,
        'color': Colors.green,
      },
      {
        'title': 'Bài tập',
        'total': _resourcesReport['totalExercises'] ?? 0,
        'new': _resourcesReport['newExercises'] ?? 0,
        'icon': Icons.assignment,
        'color': Colors.orange,
      },
      {
        'title': 'Bài kiểm tra',
        'total': _resourcesReport['totalQuizzes'] ?? 0,
        'new': _resourcesReport['newQuizzes'] ?? 0,
        'icon': Icons.quiz,
        'color': Colors.purple,
      },
    ];
    
    return Card(
      elevation: 0,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Thống kê tài nguyên',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...newResourcesData.map((resource) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (resource['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      resource['icon'] as IconData,
                      color: resource['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Text(
                      resource['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      (resource['total'] as int).toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if ((resource['new'] as int) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        '+${resource['new']}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  // Thống kê bài học có vấn đề
  Widget _buildProblematicLessons() {
    return Card(
      elevation: 0,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Bài học có vấn đề',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: (_resourcesReport['problematicLessons'] as List).length,
              itemBuilder: (context, index) {
                final lesson = _resourcesReport['problematicLessons'][index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson['lessonTitle'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${lesson['reportCount']} báo cáo',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${lesson['reportCount']} báo cáo',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingContentSection() {
    return Card(
      elevation: 0,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.pending_actions, color: Colors.purple),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nội dung chờ duyệt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPendingContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingContent() {
    if (!_systemOverview.containsKey('pendingContent') ||
        (_systemOverview['pendingContent'] as List).isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text(
            'Không có nội dung nào chờ duyệt',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: (_systemOverview['pendingContent'] as List).length,
      itemBuilder: (context, index) {
        final content = _systemOverview['pendingContent'][index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${content['type'] == 'lesson' ? 'Bài học' : 'Flashcard'} • ${content['authorName'] ?? 'Không xác định'}',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _approveContent('${content['type']}_${content['id']}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectContent('${content['type']}_${content['id']}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Duyệt nội dung
  Future<void> _approveContent(String contentId) async {
    try {
      // Kiểm tra quyền người dùng
      final currentUser = await _authService.getCurrentUserProfile();
      print('Current user role: ${currentUser?.roleId}');
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      if (currentUser.roleId != 'admin' && currentUser.roleId != 'teacher') {
        throw Exception('User does not have permission to approve content');
      }
      
      await _analyticsService.approveContent(contentId);
      _loadDashboardData(); // Tải lại dữ liệu
      if (mounted) {
        SnackbarHelper.showSuccess(
          context: context,
          message: 'Đã duyệt nội dung',
        );
      }
    } catch (e) {
      print('Error approving content: $e');
      if (mounted) {
        SnackbarHelper.showError(
          context: context,
          message: 'Không thể duyệt nội dung: ${e.toString()}',
        );
      }
    }
  }

  // Từ chối nội dung
  Future<void> _rejectContent(String contentId) async {
    try {
      // Kiểm tra quyền người dùng
      final currentUser = await _authService.getCurrentUserProfile();
      print('Current user role: ${currentUser?.roleId}');
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      if (currentUser.roleId != 'admin' && currentUser.roleId != 'teacher') {
        throw Exception('User does not have permission to reject content');
      }
      
      await _analyticsService.rejectContent(contentId);
      _loadDashboardData(); // Tải lại dữ liệu
      if (mounted) {
        SnackbarHelper.showSuccess(
          context: context,
          message: 'Đã từ chối nội dung',
        );
      }
    } catch (e) {
      print('Error rejecting content: $e');
      if (mounted) {
        SnackbarHelper.showError(
          context: context,
          message: 'Không thể từ chối nội dung: ${e.toString()}',
        );
      }
    }
  }

  // Thêm widget CardButton cho các tác vụ quản trị viên
  Widget _buildAdminActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 40,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 