import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/analytics_service.dart';
import '../../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProgressDetailScreen extends StatefulWidget {
  final String studentId;
  final String classroomId;
  final String studentName;

  const StudentProgressDetailScreen({
    Key? key,
    required this.studentId,
    required this.classroomId,
    required this.studentName,
  }) : super(key: key);

  @override
  _StudentProgressDetailScreenState createState() => _StudentProgressDetailScreenState();
}

class _StudentProgressDetailScreenState extends State<StudentProgressDetailScreen> {
  final _analyticsService = AnalyticsService();
  final _userService = UserService();
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('DEBUG: Loading student data for:');
      print('- Student ID: ${widget.studentId}');
      print('- Classroom ID: ${widget.classroomId}');
      print('- Student Name: ${widget.studentName}');

      final studentData = await _analyticsService.getStudentDetailedProgress(
        widget.classroomId,
        widget.studentId,
      );

      print('DEBUG: Received student data:');
      print('- Progress: ${studentData['progress']}');
      print('- Completed Lessons: ${studentData['completedLessons']}/${studentData['totalLessons']}');
      print('- Total Time Spent: ${studentData['totalTimeSpent']}');
      print('- Last Accessed: ${studentData['lastAccessed']}');
      
      if (studentData.containsKey('lessonProgress')) {
        print('DEBUG: Lesson Progress Data:');
        final lessons = studentData['lessonProgress'] as List;
        print('- Number of lessons: ${lessons.length}');
        for (var lesson in lessons) {
          print('  Lesson: ${lesson['lessonTitle']}');
          print('  - Completed: ${lesson['isCompleted']}');
          print('  - Time Spent: ${lesson['minutesSpent']} minutes');
          print('  - Video Progress: ${lesson['videoProgress']}');
          print('  - Flashcards Progress: ${lesson['flashcardsProgress']}');
          print('  - Exercises Progress: ${lesson['exercisesProgress']}');
        }
      }

      if (studentData.containsKey('quizStats')) {
        print('DEBUG: Quiz Statistics:');
        final quizzes = studentData['quizStats'] as List;
        print('- Number of quizzes: ${quizzes.length}');
        for (var quiz in quizzes) {
          print('  Quiz: ${quiz['quizTitle']}');
          print('  - Average Score: ${quiz['averageScore']}');
          print('  - Attempts: ${quiz['attempts']}');
        }
      }

      if (!mounted) return;

      setState(() {
        _studentData = studentData;
        _isLoading = false;
      });
    } catch (e) {
      print('ERROR in _loadStudentData: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa có';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes phút';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours giờ ${remainingMinutes > 0 ? '$remainingMinutes phút' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết tiến độ - ${widget.studentName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Lỗi: $_errorMessage'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tổng quan
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tổng quan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Tỷ lệ hoàn thành',
                                      '${(_studentData?['progress'] ?? 0.0 * 100).toStringAsFixed(1)}%',
                                      Icons.check_circle,
                                      Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Bài đã hoàn thành',
                                      '${_studentData?['completedLessons'] ?? 0}/${_studentData?['totalLessons'] ?? 0}',
                                      Icons.book,
                                      Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'Tổng thời gian học',
                                      _formatDuration(_studentData?['totalTimeSpent'] ?? 0),
                                      Icons.timer,
                                      Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildStatCard(
                                      'Lần truy cập cuối',
                                      _formatDate(_studentData?['lastAccessed']),
                                      Icons.access_time,
                                      Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chi tiết từng bài học
                      if (_studentData?.containsKey('lessonProgress') == true)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Chi tiết bài học',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: (_studentData!['lessonProgress'] as List).length,
                                  itemBuilder: (context, index) {
                                    final lesson = (_studentData!['lessonProgress'] as List)[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ExpansionTile(
                                        leading: Icon(
                                          lesson['isCompleted'] ? Icons.check_circle : Icons.circle_outlined,
                                          color: lesson['isCompleted'] ? Colors.green : Colors.grey,
                                        ),
                                        title: Text(lesson['lessonTitle']),
                                        subtitle: Text(
                                          'Thời gian học: ${_formatDuration(lesson['minutesSpent'])}',
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                _buildProgressItem(
                                                  'Video',
                                                  lesson['videoWatched'] ?? false,
                                                  lesson['videoProgress'] ?? 0.0,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildProgressItem(
                                                  'Flashcards',
                                                  lesson['flashcardsViewed'] ?? false,
                                                  lesson['flashcardsProgress'] ?? 0.0,
                                                ),
                                                const SizedBox(height: 8),
                                                _buildProgressItem(
                                                  'Bài tập',
                                                  lesson['exercisesDone'] ?? false,
                                                  lesson['exercisesProgress'] ?? 0.0,
                                                ),
                                                if (lesson['lastAccessed'] != null) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Truy cập cuối: ${_formatDate(lesson['lastAccessed'])}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ],
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
                        ),

                      // Thống kê bài kiểm tra
                      if (_studentData?.containsKey('quizStats') == true)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thống kê bài kiểm tra',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: (_studentData!['quizStats'] as List).length,
                                  itemBuilder: (context, index) {
                                    final quiz = (_studentData!['quizStats'] as List)[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(quiz['quizTitle']),
                                        subtitle: Text(
                                          'Điểm trung bình: ${quiz['averageScore'].toStringAsFixed(1)}/10',
                                        ),
                                        trailing: Text(
                                          '${quiz['attempts']} lần làm',
                                          style: const TextStyle(
                                            color: Colors.grey,
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
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String title, bool isCompleted, double progress) {
    return Row(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.circle_outlined,
          color: isCompleted ? Colors.green : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: isCompleted ? Colors.green : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 