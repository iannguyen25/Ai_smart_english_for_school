import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/exercise_attempt.dart';
import '../../models/app_user.dart';
import '../../services/exercise_service.dart';
import '../../services/auth_service.dart';
import '../../services/classroom_service.dart';

class ExerciseAttemptsScreen extends StatefulWidget {
  final String exerciseId;
  final String lessonId;
  final String classroomId;

  const ExerciseAttemptsScreen({
    Key? key,
    required this.exerciseId,
    required this.lessonId,
    required this.classroomId,
  }) : super(key: key);

  @override
  _ExerciseAttemptsScreenState createState() => _ExerciseAttemptsScreenState();
}

class _ExerciseAttemptsScreenState extends State<ExerciseAttemptsScreen> with SingleTickerProviderStateMixin {
  final ExerciseService _exerciseService = ExerciseService();
  final AuthService _authService = AuthService();
  final ClassroomService _classroomService = ClassroomService();
  late TabController _tabController;
  bool _isLoading = true;
  List<ExerciseAttempt> _attempts = [];
  Map<String, User> _users = {};
  List<User> _allStudents = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Lấy tất cả attempts của bài tập này
      final attempts = await _exerciseService.getAttemptsByExercise(widget.exerciseId);
      
      // Lấy danh sách học sinh trong lớp
      final classroom = await _classroomService.getClassroom(widget.classroomId);
      if (classroom == null) throw 'Không tìm thấy thông tin lớp học';
      
      final studentIds = classroom.memberIds.where((id) => id != classroom.teacherId).toList();
      final students = await Future.wait(
        studentIds.map((id) => _authService.getUserById(id))
      );
      
      final validStudents = students.whereType<User>().toList();
      
      // Lấy thông tin người dùng cho các attempts
      final attemptUserIds = attempts.map((a) => a.userId).toSet();
      final attemptUsers = await Future.wait(
        attemptUserIds.map((id) => _authService.getUserById(id))
      );
      
      final userMap = {
        for (var user in attemptUsers)
          if (user != null) user.id!: user
      };

      setState(() {
        _attempts = attempts;
        _users = userMap;
        _allStudents = validStudents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  ExerciseAttempt? _getLatestAttempt(String userId) {
    final userAttempts = _attempts.where((attempt) => attempt.userId == userId).toList();
    if (userAttempts.isEmpty) return null;
    return userAttempts.reduce((a, b) => a.startTime.isAfter(b.startTime) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách bài làm'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lịch sử'),
            Tab(text: 'Danh sách'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab Lịch sử
                    _attempts.isEmpty
                        ? const Center(
                            child: Text('Chưa có học viên nào làm bài'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _attempts.length,
                            itemBuilder: (context, index) {
                              final attempt = _attempts[index];
                              final user = _users[attempt.userId];
                              return _buildAttemptCard(attempt, user);
                            },
                          ),
                    
                    // Tab Danh sách
                    ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _allStudents.length,
                      itemBuilder: (context, index) {
                        final student = _allStudents[index];
                        final latestAttempt = _getLatestAttempt(student.id!);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: student.avatar != null
                                          ? NetworkImage(student.avatar!)
                                          : null,
                                      child: student.avatar == null
                                          ? Text(
                                              student.firstName?.substring(0, 1).toUpperCase() ?? '?',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.fullName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            latestAttempt != null
                                                ? 'Lần làm cuối: ${_formatDateTime(latestAttempt.startTime)}'
                                                : 'Chưa làm bài',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (latestAttempt != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: latestAttempt.passed
                                              ? Colors.green.shade100
                                              : Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '${latestAttempt.score.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: latestAttempt.passed
                                                ? Colors.green.shade800
                                                : Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (latestAttempt != null) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildInfoItem(
                                        Icons.timer,
                                        'Thời gian',
                                        _formatDuration(latestAttempt.timeSpentSeconds),
                                      ),
                                      _buildInfoItem(
                                        Icons.check_circle,
                                        'Trạng thái',
                                        latestAttempt.passed ? 'Đạt' : 'Chưa đạt',
                                        textColor: latestAttempt.passed
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      _buildInfoItem(
                                        Icons.format_list_numbered,
                                        'Số lần làm',
                                        '${_attempts.where((a) => a.userId == student.id).length}',
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
    );
  }

  Widget _buildAttemptCard(ExerciseAttempt attempt, User? user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: user?.avatar != null
                      ? NetworkImage(user!.avatar!)
                      : null,
                  child: user?.avatar == null
                      ? Text(
                          user?.firstName?.substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Không xác định',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Lần làm: ${attempt.attemptNumber}',
                        style: TextStyle(
                          color: Colors.grey[600],
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
                    color: attempt.passed
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${attempt.score.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: attempt.passed
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  Icons.calendar_today,
                  'Ngày làm',
                  _formatDateTime(attempt.startTime),
                ),
                _buildInfoItem(
                  Icons.timer,
                  'Thời gian',
                  _formatDuration(attempt.timeSpentSeconds),
                ),
                _buildInfoItem(
                  Icons.check_circle,
                  'Trạng thái',
                  attempt.passed ? 'Đạt' : 'Chưa đạt',
                  textColor: attempt.passed
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {Color? textColor}) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
} 