import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/exercise_attempt.dart';
import '../../models/app_user.dart';
import '../../services/exercise_service.dart';
import '../../services/auth_service.dart';

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

class _ExerciseAttemptsScreenState extends State<ExerciseAttemptsScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<ExerciseAttempt> _attempts = [];
  Map<String, User> _users = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Lấy tất cả attempts của bài tập này
      final attempts = await _exerciseService.getAttemptsByExercise(widget.exerciseId);
      
      // Lấy thông tin người dùng cho các attempts
      final userIds = attempts.map((a) => a.userId).toSet();
      final users = await Future.wait(
        userIds.map((id) => _authService.getUserById(id))
      );
      
      final userMap = {
        for (var user in users)
          if (user != null) user.id!: user
      };

      setState(() {
        _attempts = attempts;
        _users = userMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách bài làm: $e';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách bài làm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttempts,
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
                        onPressed: _loadAttempts,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _attempts.isEmpty
                  ? const Center(
                      child: Text('Chưa có học viên nào làm bài'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _attempts.length,
                      itemBuilder: (context, index) {
                        final attempt = _attempts[index];
                        final user = _users[attempt.userId];
                        
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
                      },
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