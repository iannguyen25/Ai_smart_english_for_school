import 'package:base_flutter_framework/models/quiz_attempt.dart';
import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../models/exercise_attempt.dart';
import '../../services/exercise_service.dart';
import '../../services/auth_service.dart';
import 'exercise_detail_screen.dart';
import 'edit_exercise_screen.dart';

class ExerciseListScreen extends StatefulWidget {
  final String lessonId;
  final String classroomId;

  const ExerciseListScreen({
    Key? key,
    required this.lessonId,
    required this.classroomId,
  }) : super(key: key);

  @override
  _ExerciseListScreenState createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final ExerciseService _exerciseService = ExerciseService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Exercise> _exercises = [];
  Map<String, ExerciseAttempt?> _bestAttempts = {};
  String? _errorMessage;
  bool _isTeacherOrAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadExercises();
  }

  void _checkUserRole() {
    // Check if current user is teacher or admin
    _isTeacherOrAdmin = _authService.isCurrentUserTeacher || _authService.isCurrentUserAdmin;
    print('User is teacher or admin: $_isTeacherOrAdmin');
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final exercises = await _exerciseService.getExercisesByLesson(widget.lessonId);
      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });

      // Tải thông tin về các lần làm gần nhất
      _loadBestAttempts();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách bài tập: $e';
      });
    }
  }

  Future<void> _loadBestAttempts() async {
    // Only load attempts for students
    if (_isTeacherOrAdmin) {
      return;
    }
    
    final String userId = _authService.currentUser?.id ?? "";
    if (userId.isEmpty) {
      print('Cannot load attempts: no current user');
      return;
    }
    
    for (final exercise in _exercises) {
      try {
        final bestAttempt = await _exerciseService.getBestAttempt(userId, exercise.id!);
        setState(() {
          _bestAttempts[exercise.id!] = bestAttempt;
        });
      } catch (e) {
        print('Error loading best attempt for exercise ${exercise.id}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài tập & Kiểm tra'),
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
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExercises,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Bài học này không có bài tập nào'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exercises.length,
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        final bestAttempt = _bestAttempts[exercise.id];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailScreen(
                    exerciseId: exercise.id!,
                    lessonId: widget.lessonId,
                    classroomId: widget.classroomId,
                  ),
                ),
              ).then((_) {
                // Refresh data when returning from exercise screen
                _loadExercises();
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_isTeacherOrAdmin && bestAttempt != null && bestAttempt.status == AttemptStatus.completed)
                        Icon(
                          bestAttempt.passed ? Icons.check_circle : Icons.incomplete_circle,
                          color: bestAttempt.passed ? Colors.green : Colors.orange,
                        ),
                    ],
                  ),
                  if (exercise.description != null) ...[
                    const SizedBox(height: 8),
                    Text(exercise.description!),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        Icons.timer_outlined,
                        '${exercise.timeLimit} phút',
                      ),
                      _buildInfoChip(
                        Icons.question_answer_outlined,
                        '${exercise.questions.length} câu hỏi',
                      ),
                      _buildInfoChip(
                        Icons.replay,
                        '${exercise.attemptsAllowed} lần làm',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isTeacherOrAdmin && bestAttempt != null && bestAttempt.status == AttemptStatus.completed) ...[
                    LinearProgressIndicator(
                      value: bestAttempt.score / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        bestAttempt.passed ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Điểm số: ${bestAttempt.score.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: bestAttempt.passed ? Colors.green : Colors.orange,
                          ),
                        ),
                        Text(
                          'Lần làm: ${bestAttempt.attemptNumber}/${exercise.attemptsAllowed}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ] else if (!_isTeacherOrAdmin) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chưa làm bài',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseDetailScreen(
                                  exerciseId: exercise.id!,
                                  lessonId: widget.lessonId,
                                  classroomId: widget.classroomId,
                                ),
                              ),
                            ).then((_) {
                              _loadExercises();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Làm bài'),
                        ),
                      ],
                    ),
                  ] else if (_isTeacherOrAdmin) ...[
                    // Teacher/Admin controls
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Edit button
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditExerciseScreen(
                                  exercise: exercise,
                                  onSaved: () {
                                    _loadExercises();
                                  },
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Chỉnh sửa bài tập',
                        ),
                        // View results button
                        IconButton(
                          onPressed: () {
                            // TODO: Navigate to results summary screen
                          },
                          icon: Icon(Icons.assessment, color: Colors.green),
                          tooltip: 'Xem kết quả',
                        ),
                        // Delete button
                        IconButton(
                          onPressed: () {
                            _showDeleteConfirmation(exercise);
                          },
                          icon: Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Xóa bài tập',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa bài tập'),
        content: Text('Bạn có chắc chắn muốn xóa bài tập "${exercise.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _exerciseService.deleteExercise(exercise.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã xóa bài tập thành công')),
                );
                _loadExercises();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 