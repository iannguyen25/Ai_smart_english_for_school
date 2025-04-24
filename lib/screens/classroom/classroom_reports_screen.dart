import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/classroom.dart';
import '../../services/analytics_service.dart';
import '../../services/classroom_service.dart';
import '../../utils/snackbar_helper.dart';
import 'package:get/get.dart';

enum ReportState { loading, loaded, error }

class ClassroomReportsScreen extends StatefulWidget {
  final String classroomId;
  final String className;

  const ClassroomReportsScreen({
    Key? key,
    required this.classroomId,
    required this.className,
  }) : super(key: key);

  @override
  _ClassroomReportsScreenState createState() => _ClassroomReportsScreenState();
}

class _ClassroomReportsScreenState extends State<ClassroomReportsScreen> with SingleTickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  final ClassroomService _classroomService = ClassroomService();
  
  late TabController _tabController;
  ReportState _reportState = ReportState.loading;
  String? _errorMessage;
  
  // Dữ liệu báo cáo
  double _classCompletionRate = 0.0;
  List<Map<String, dynamic>> _studentProgress = [];
  Map<String, dynamic> _testStatistics = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _viewStudentDetails(String studentId, String studentName) {
    // TODO: Implement student detail view
    Get.snackbar(
      'Thông báo',
      'Chức năng xem chi tiết học viên đang được phát triển',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _loadReportData() async {
    setState(() => _reportState = ReportState.loading);
    
    try {
      // Log request
      print('Loading report data for classroom: ${widget.classroomId}');
      
      // Tải tỷ lệ hoàn thành của lớp
      final completionRate = await _analyticsService.getClassCompletionRate(widget.classroomId);
      if (completionRate == null) {
        throw Exception('Completion rate is null');
      }
      print('Completion Rate: $completionRate');
      
      // Tải tiến độ học tập của học sinh
      final studentProgress = await _analyticsService.getStudentProgressInClass(widget.classroomId);
      if (studentProgress == null) {
        throw Exception('Student progress data is null');
      }
      print('Student Progress Count: ${studentProgress.length}');
      
      // Validate và lọc dữ liệu học sinh
      final validStudentProgress = studentProgress.where((student) {
        return student['name'] != null && 
               student['id'] != null && 
               student['progress'] != null;
      }).toList();
      
      if (validStudentProgress.isEmpty) {
        print('Warning: No valid student data found');
      }
      
      // Tải thống kê bài kiểm tra
      final testStatistics = await _analyticsService.getClassTestStatistics(widget.classroomId);
      if (testStatistics == null) {
        throw Exception('Test statistics is null');
      }
      print('Test Statistics: ${testStatistics.length} entries');
      
      if (mounted) {
        setState(() {
          _classCompletionRate = completionRate;
          _studentProgress = validStudentProgress;
          _testStatistics = testStatistics;
          _reportState = ReportState.loaded;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading report data: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _reportState = ReportState.error;
          _errorMessage = 'Không thể tải dữ liệu báo cáo: ${e.toString()}';
        });
        SnackbarHelper.showError(
          context: context,
          message: _errorMessage!,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header với tên lớp học
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Báo cáo lớp học',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.className,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.dashboard),
                      text: 'Tổng quan',
                    ),
                    Tab(
                      icon: Icon(Icons.people),
                      text: 'Học viên',
                    ),
                    Tab(
                      icon: Icon(Icons.analytics),
                      text: 'Chi tiết',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Body content
          Expanded(
            child: _reportState == ReportState.loading
              ? const Center(child: CircularProgressIndicator())
              : _reportState == ReportState.error
                  ? Center(child: Text(_errorMessage!))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildStudentsTab(),
                        _buildDetailsTab(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCompletionCard(),
            const SizedBox(height: 16),
            _buildProgressChart(),
            const SizedBox(height: 16),
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCompletionColor(_classCompletionRate).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: _getCompletionColor(_classCompletionRate),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tỷ lệ hoàn thành',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_classCompletionRate * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _classCompletionRate,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getCompletionColor(_classCompletionRate),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    if (_studentProgress.isEmpty) {
      return _buildEmptyState('Không có dữ liệu tiến độ');
    }

    // Calculate actual progress data
    final progressData = _calculateWeeklyProgress();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tiến độ học tập',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            'Tuần ${value.toInt() + 1}',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: progressData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: Theme.of(context).primaryColor,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _calculateWeeklyProgress() {
    // Group student progress by week
    final now = DateTime.now();
    final weeks = List.generate(4, (index) {
      final weekStart = now.subtract(Duration(days: (3 - index) * 7));
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      final weekProgress = _studentProgress
          .where((student) {
            final lastAccess = student['lastAccessed'] as DateTime?;
            return lastAccess != null && 
                   lastAccess.isAfter(weekStart) && 
                   lastAccess.isBefore(weekEnd);
          })
          .map((student) => student['progress'] as double? ?? 0.0)
          .toList();
      
      return weekProgress.isEmpty ? 0.0 : 
             weekProgress.reduce((a, b) => a + b) / weekProgress.length;
    });
    
    return weeks;
  }

  Widget _buildRecentActivities() {
    if (_studentProgress.isEmpty) {
      return _buildEmptyState('Không có hoạt động gần đây');
    }

    // Lấy các hoạt động gần đây từ dữ liệu học sinh
    final recentActivities = _studentProgress
        .where((student) => student['lastAccessed'] != null)
        .map((student) {
          final lastAccess = student['lastAccessed'] as DateTime;
          final hoursAgo = DateTime.now().difference(lastAccess).inHours;
          
          return {
            'name': student['name'],
            'progress': student['progress'] ?? 0.0,
            'hoursAgo': hoursAgo,
            'type': _getActivityType(student),
          };
        })
        .toList()
      ..sort((a, b) => (b['hoursAgo'] as int).compareTo(a['hoursAgo'] as int));

    if (recentActivities.isEmpty) {
      return _buildEmptyState('Không có hoạt động gần đây');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoạt động gần đây',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentActivities.length > 5 ? 5 : recentActivities.length,
              itemBuilder: (context, index) {
                final activity = recentActivities[index];
                final hoursAgo = activity['hoursAgo'] as int;
                final progress = activity['progress'] as double;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCompletionColor(progress).withOpacity(0.1),
                    child: Icon(
                      _getActivityIcon(activity['type'] as String),
                      color: _getCompletionColor(progress),
                    ),
                  ),
                  title: Text(activity['name'] as String),
                  subtitle: Text(
                    '${hoursAgo} giờ trước',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _getCompletionColor(progress),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getActivityType(Map<String, dynamic> student) {
    final progress = student['progress'] as double? ?? 0.0;
    if (progress >= 0.8) return 'completed';
    if (progress >= 0.5) return 'in_progress';
    return 'started';
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.timer;
      case 'started':
        return Icons.play_circle;
      default:
        return Icons.info;
    }
  }

  Widget _buildStudentsTab() {
    if (_studentProgress.isEmpty) {
      return _buildEmptyState('Không có dữ liệu học viên');
    }
    
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _studentProgress.length,
        itemBuilder: (context, index) {
          final student = _studentProgress[index];
          
          // Validate student data
          if (student['name'] == null || student['id'] == null) {
            return _buildErrorCard('Dữ liệu học viên không hợp lệ');
          }
          
          final progress = student['progress'] as double? ?? 0.0;
          final name = student['name'] as String;
          final id = student['id'] as String;
          
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: _getCompletionColor(progress).withOpacity(0.1),
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                    color: _getCompletionColor(progress),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_getCompletionColor(progress)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}% hoàn thành',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _viewStudentDetails(id, name),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    if (_testStatistics.isEmpty) {
      return const Center(
        child: Text('Chưa có dữ liệu thống kê'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thống kê bài kiểm tra',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Bài kiểm tra',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Tỷ lệ làm bài',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Điểm TB',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: (_testStatistics['lessonStats'] as List).map<DataRow>((stat) {
                          return DataRow(
                            cells: [
                              DataCell(Text(stat['name'])),
                              DataCell(Text('${(stat['completionRate'] * 100).toStringAsFixed(1)}%')),
                              DataCell(Text(stat['averageScore'].toStringAsFixed(1))),
                            ],
                          );
                        }).toList(),
                      ),
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

  Color _getCompletionColor(double value) {
    if (value >= 0.8) return Colors.green;
    if (value >= 0.6) return Colors.blue;
    if (value >= 0.4) return Colors.orange;
    return Colors.red;
  }

  // Lấy màu dựa trên điểm số
  Color _getScoreColor(double score) {
    if (score < 5.0) return Colors.red;
    if (score < 7.0) return Colors.orange;
    return Colors.green;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// Màn hình chi tiết báo cáo học sinh
class StudentReportDetailScreen extends StatefulWidget {
  final String classroomId;
  final String className;
  final String studentId;
  final String studentName;

  const StudentReportDetailScreen({
    Key? key,
    required this.classroomId,
    required this.className,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  _StudentReportDetailScreenState createState() =>
      _StudentReportDetailScreenState();
}

class _StudentReportDetailScreenState extends State<StudentReportDetailScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  bool _isLoading = true;
  Map<String, dynamic> _studentData = {};
  
  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }
  
  // Tải dữ liệu học sinh
  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _analyticsService.getStudentDetailedProgress(
        widget.classroomId,
        widget.studentId,
      );
      
      if (mounted) {
        setState(() {
          _studentData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading student data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(
          context: context,
          message: 'Không thể tải dữ liệu học sinh: ${e.toString()}',
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Báo cáo: ${widget.studentName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStudentData,
            tooltip: 'Làm mới dữ liệu',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildStudentReport(),
    );
  }
  
  // Xây dựng báo cáo học sinh
  Widget _buildStudentReport() {
    final testStatistics = _studentData['testStatistics'] ?? {};
    
    return RefreshIndicator(
      onRefresh: _loadStudentData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin học sinh
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: _studentData['photoUrl'] != null
                          ? NetworkImage(_studentData['photoUrl'])
                          : null,
                      child: _studentData['photoUrl'] == null
                          ? Text(_studentData['name']
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _studentData['name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_studentData['email'] ?? 'N/A'),
                          const SizedBox(height: 4),
                          Text(
                            'Tham gia từ: ${_formatDate(_studentData['joinedAt'])}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tiến độ học tập
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiến độ học tập',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Bài đã học'),
                              const SizedBox(height: 8),
                              Text(
                                '${_studentData['completedLessons'] ?? 0}/${_studentData['totalLessons'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Tỷ lệ hoàn thành'),
                              const SizedBox(height: 8),
                              Text(
                                '${((_studentData['completionRate'] ?? 0) * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _getCompletionColor(
                                      _studentData['completionRate'] ?? 0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _studentData['completionRate'] ?? 0,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCompletionColor(_studentData['completionRate'] ?? 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Streak học tập
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Streak học tập',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Streak hiện tại'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.local_fire_department,
                                      color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_studentData['currentStreak'] ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(' ngày'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text('Streak dài nhất'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.emoji_events, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_studentData['longestStreak'] ?? 0}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(' ngày'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Huy hiệu
            if (_studentData.containsKey('earnedBadges') &&
                (_studentData['earnedBadges'] as List).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Huy hiệu đã đạt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: (_studentData['earnedBadges'] as List).length,
                          itemBuilder: (context, index) {
                            final badge = (_studentData['earnedBadges'] as List)[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      shape: BoxShape.circle,
                                      image: badge['imageUrl'] != null
                                          ? DecorationImage(
                                              image: NetworkImage(badge['imageUrl']),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: badge['imageUrl'] == null
                                        ? const Icon(Icons.emoji_events, size: 30)
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      badge['name'],
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Thống kê bài kiểm tra
            if (testStatistics.containsKey('tests') &&
                (testStatistics['tests'] as List).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kết quả bài kiểm tra',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Đã làm'),
                                const SizedBox(height: 4),
                                Text(
                                  '${testStatistics['completedTests'] ?? 0}/${testStatistics['totalTests'] ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Tỷ lệ làm bài'),
                                const SizedBox(height: 4),
                                Text(
                                  '${((testStatistics['completionRate'] ?? 0) * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text('Điểm trung bình'),
                                const SizedBox(height: 4),
                                Text(
                                  (testStatistics['averageScore'] ?? 0).toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _getScoreColor(
                                        testStatistics['averageScore'] ?? 0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chi tiết bài kiểm tra',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (testStatistics['tests'] as List).length,
                        itemBuilder: (context, index) {
                          final test = (testStatistics['tests'] as List)[index];
                          return ListTile(
                            title: Text(test['quizTitle']),
                            subtitle: Text('Bài học: ${test['lessonTitle']}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getScoreColor(test['score']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getScoreColor(test['score']),
                                ),
                              ),
                              child: Text(
                                '${test['score'].toStringAsFixed(1)}/10',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getScoreColor(test['score']),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Chi tiết bài học
            if (_studentData.containsKey('lessonProgress') &&
                (_studentData['lessonProgress'] as List).isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi tiết tiến độ bài học',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (_studentData['lessonProgress'] as List).length,
                        itemBuilder: (context, index) {
                          final lesson = (_studentData['lessonProgress'] as List)[index];
                          return ListTile(
                            leading: Icon(
                              lesson['isCompleted'] ? Icons.check_circle : Icons.circle_outlined,
                              color: lesson['isCompleted'] ? Colors.green : Colors.grey,
                            ),
                            title: Text(lesson['lessonTitle']),
                            subtitle: Text(
                                'Thời gian đã học: ${lesson['minutesSpent']} phút${lesson['lastAccessed'] != null ? ' | Truy cập: ${_formatDate(lesson['lastAccessed'])}' : ''}'),
                            dense: true,
                          );
                        },
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
  
  // Format date
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  // Lấy màu dựa trên tỷ lệ hoàn thành
  Color _getCompletionColor(double rate) {
    if (rate < 0.3) return Colors.red;
    if (rate < 0.7) return Colors.orange;
    return Colors.green;
  }
  
  // Lấy màu dựa trên điểm số
  Color _getScoreColor(double score) {
    if (score < 5.0) return Colors.red;
    if (score < 7.0) return Colors.orange;
    return Colors.green;
  }
} 