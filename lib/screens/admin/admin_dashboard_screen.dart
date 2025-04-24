import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';
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
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Chọn khoảng thời gian
          PopupMenuButton<int>(
            tooltip: 'Chọn khoảng thời gian',
            icon: const Icon(Icons.date_range),
            onSelected: _changePeriod,
            itemBuilder: (context) => _periodOptions
                .map((days) => PopupMenuItem<int>(
                      value: days,
                      child: Text('$days ngày${_selectedPeriod == days ? ' ✓' : ''}'),
                    ))
                .toList(),
          ),
          // Làm mới dữ liệu
          IconButton(
            icon: const Icon(Icons.refresh),
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
            // Tiêu đề phần
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Tổng quan hệ thống (${_selectedPeriod} ngày gần đây)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Thống kê người dùng
            _buildStatCards(),
            
            const SizedBox(height: 24),
            
            // Top lớp học tích cực
            if (_systemOverview.containsKey('topActiveClassrooms') &&
                (_systemOverview['topActiveClassrooms'] as List).isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top lớp học tích cực',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          for (var classroom in _systemOverview['topActiveClassrooms'])
                            ListTile(
                              title: Text(classroom['className']),
                              subtitle: Text('Giáo viên: ${classroom['teacherName']}'),
                              trailing: Text(
                                '${classroom['activities']} hoạt động',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              leading: CircleAvatar(
                                child: Text(
                                  classroom['className']
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 24),
            
            // Tiêu đề phần tài nguyên học tập
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Tài nguyên học tập',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Thống kê tài nguyên
            _buildResourcesStats(),
            
            const SizedBox(height: 24),
            
            // Bài học có vấn đề
            if (_resourcesReport.containsKey('problematicLessons') &&
                (_resourcesReport['problematicLessons'] as List).isNotEmpty)
              _buildProblematicLessons(),
            
            const SizedBox(height: 24),
            
            // Nội dung chờ duyệt
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Nội dung chờ duyệt',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            _buildPendingContent(),

            const SizedBox(height: 24),

            // Quản lý hệ thống
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Quản lý hệ thống',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildAdminActionCard(
                  title: 'Quản lý người dùng',
                  icon: Icons.people,
                  color: Colors.blue,
                  onTap: () => Get.to(() => const UserManagementScreen()),
                ),
                _buildAdminActionCard(
                  title: 'Quản lý khóa học',
                  icon: Icons.book,
                  color: Colors.green,
                  onTap: _navigateToCourseManagement,
                ),
                _buildAdminActionCard(
                  title: 'Quản lý bài học',
                  icon: Icons.class_,
                  color: Colors.orange,
                  onTap: () {
                    // Điều hướng đến màn hình quản lý bài học
                  },
                ),
                _buildAdminActionCard(
                  title: 'Quản lý nội dung',
                  icon: Icons.content_paste,
                  color: Colors.purple,
                  onTap: () {
                    // Điều hướng đến màn hình quản lý nội dung
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Thẻ thống kê
  Widget _buildStatCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Tổng học sinh',
          value: _systemOverview['totalStudents']?.toString() ?? '0',
          subtitle: '+${_systemOverview['newStudents'] ?? 0} mới',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Lớp học đang chạy',
          value: _systemOverview['totalClassrooms']?.toString() ?? '0',
          subtitle: '${_systemOverview['totalCourses'] ?? 0} khóa học',
          icon: Icons.class_,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Phản hồi',
          value: _systemOverview['totalFeedbacks']?.toString() ?? '0',
          subtitle: '+${_systemOverview['newFeedbacks'] ?? 0} mới',
          icon: Icons.feedback,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Học sinh hoạt động hằng ngày',
          value: _systemOverview['dailyActiveUsers']?.toString() ?? '0',
          subtitle: 'DAU',
          icon: Icons.trending_up,
          color: Colors.purple,
        ),
      ],
    );
  }
  
  // Thẻ thống kê đơn
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var resource in newResourcesData)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      resource['icon'] as IconData,
                      color: resource['color'] as Color,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Text(resource['title'] as String),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        (resource['total'] as int).toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if ((resource['new'] as int) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+${resource['new']}',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Thống kê bài học có vấn đề
  Widget _buildProblematicLessons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bài học có vấn đề',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var lesson in _resourcesReport['problematicLessons'])
                  ListTile(
                    title: Text(lesson['lessonTitle']),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        '${lesson['reportCount']} báo cáo',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    leading: const Icon(Icons.warning, color: Colors.orange),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Thống kê nội dung chờ duyệt
  Widget _buildPendingContent() {
    if (!_systemOverview.containsKey('pendingContent') ||
        (_systemOverview['pendingContent'] as List).isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Không có nội dung nào đang chờ duyệt',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (var content in _systemOverview['pendingContent'])
              ListTile(
                title: Text(content['title']),
                subtitle: Text(
                  '${content['type']} • Tạo bởi: ${content['authorName']} • ${DateFormat('dd/MM/yyyy HH:mm').format((content['createdAt'] as Timestamp).toDate())}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _approveContent(content['id']),
                      tooltip: 'Duyệt nội dung',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => _rejectContent(content['id']),
                      tooltip: 'Từ chối',
                    ),
                  ],
                ),
                onTap: () => _viewContentDetails(content),
              ),
          ],
        ),
      ),
    );
  }

  // Xem chi tiết nội dung
  void _viewContentDetails(Map<String, dynamic> content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(content['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Loại: ${content['type']}'),
              const SizedBox(height: 8),
              Text('Tác giả: ${content['authorName']}'),
              const SizedBox(height: 8),
              Text('Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format((content['createdAt'] as Timestamp).toDate())}'),
              const SizedBox(height: 16),
              const Text('Nội dung:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(content['description'] ?? 'Không có mô tả'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveContent(content['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Duyệt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Duyệt nội dung
  Future<void> _approveContent(String contentId) async {
    try {
      await _analyticsService.approveContent(contentId);
      _loadDashboardData(); // Tải lại dữ liệu
      if (mounted) {
        SnackbarHelper.showSuccess(
          context: context,
          message: 'Đã duyệt nội dung',
        );
      }
    } catch (e) {
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
      await _analyticsService.rejectContent(contentId);
      _loadDashboardData(); // Tải lại dữ liệu
      if (mounted) {
        SnackbarHelper.showSuccess(
          context: context,
          message: 'Đã từ chối nội dung',
        );
      }
    } catch (e) {
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