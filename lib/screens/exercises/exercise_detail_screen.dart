import 'package:base_flutter_framework/models/quiz_attempt.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/exercise.dart';
import '../../models/exercise_attempt.dart';
import '../../models/quiz.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';
import '../../services/exercise_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/analytics_service.dart';
import 'edit_exercise_screen.dart';
import 'edit_question_screen.dart';
import '../../services/flashcard_service.dart';
import 'fill_in_the_blank_game.dart';
import 'matching_game.dart';
import '../../services/lesson_service.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;
  final String lessonId;
  final String classroomId;

  const ExerciseDetailScreen({
    Key? key,
    required this.exerciseId,
    required this.lessonId,
    required this.classroomId,
  }) : super(key: key);

  @override
  _ExerciseDetailScreenState createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> with SingleTickerProviderStateMixin {
  final ExerciseService _exerciseService = ExerciseService();
  final _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  final LessonService _lessonService = LessonService();
  final AnalyticsService _analyticsService = AnalyticsService();
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  Exercise? _exercise;
  ExerciseAttempt? _attempt;
  String? _errorMessage;
  
  int _currentQuestionIndex = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  Map<String, dynamic> _answers = {};
  bool _timeExpired = false;
  bool _isTeacherOrAdmin = false;
  bool _hasStarted = false;
  late TabController _tabController;
  List<FlashcardItem> _flashcardItems = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _checkUserRole();
    _loadExercise();
    // _loadFlashcardItems();
  }
  
  void _checkUserRole() {
    _isTeacherOrAdmin = _authService.isCurrentUserTeacher || _authService.isCurrentUserAdmin;
    print('User is teacher or admin: $_isTeacherOrAdmin');
  }
  
  @override
  void dispose() {
    if (_timer != null) {
      print('Cancelling timer on dispose');
      _timer?.cancel();
      _timer = null;
    }
    super.dispose();
  }
  
  Future<void> _loadExercise() async {
    print('DEBUG: Starting _loadExercise()');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _timeExpired = false;
      _hasStarted = false;
    });
    
    try {
      final exercise = await _exerciseService.getExerciseById(widget.exerciseId);
      
      if (exercise == null) {
        throw Exception('Không tìm thấy bài tập');
      }
      
      print('DEBUG: Exercise loaded - ID: ${exercise.id}');
      print('DEBUG: Exercise timeLimit: ${exercise.timeLimit} minutes');
      print('DEBUG: Exercise attemptsAllowed: ${exercise.attemptsAllowed}');
      
      setState(() {
        _exercise = exercise;
        _isLoading = false;
      });
      
      if (_isTeacherOrAdmin) {
        print('DEBUG: User is teacher/admin, skipping attempt handling');
        return;
      }
      
      if (_auth.currentUser != null) {
        print('DEBUG: Checking attempts for user: ${_auth.currentUser!.uid}');
        final attempts = await _exerciseService.getAttemptsByUser(
          _auth.currentUser!.uid, 
          widget.exerciseId,
        );
        
        print('DEBUG: Found ${attempts.length} total attempts');
        
        // Đếm tất cả các attempt đã hoàn thành hoặc đang làm
        final usedAttempts = attempts.where(
          (a) => a.status == AttemptStatus.completed || a.status == AttemptStatus.inProgress
        ).length;
        
        print('DEBUG: Found $usedAttempts used attempts (completed + in-progress)');
        
        if (usedAttempts >= exercise.attemptsAllowed) {
          print('DEBUG: All attempts used ($usedAttempts/${exercise.attemptsAllowed})');
          // Lấy attempt cuối cùng để hiển thị
          final lastAttempt = attempts
              .where((a) => a.status == AttemptStatus.completed)
              .reduce((a, b) => a.attemptNumber > b.attemptNumber ? a : b);
          
          setState(() {
            _attempt = lastAttempt;
            _answers = Map.from(lastAttempt.answers);
            _hasStarted = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bạn đã sử dụng hết số lần làm bài, chỉ có thể xem lại kết quả'),
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Check for in-progress attempt
        final inProgressAttempt = attempts.where(
          (a) => a.status == AttemptStatus.inProgress
        ).firstOrNull;
        
        if (inProgressAttempt != null) {
          print('DEBUG: Found in-progress attempt: ${inProgressAttempt.id}');
          print('DEBUG: Attempt start time: ${inProgressAttempt.startTime}');
          print('DEBUG: Current time: ${DateTime.now()}');
          
          setState(() {
            _attempt = inProgressAttempt;
            _answers = Map.from(inProgressAttempt.answers);
            _hasStarted = true;
          });
          
          print('DEBUG: Calling _startTimer() for in-progress attempt');
          _startTimer();
        }
      }
    } catch (e) {
      print('ERROR in _loadExercise: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải bài tập: $e';
      });
    }
  }
  
  void _startTimer() {
    print('DEBUG: Entering _startTimer()');
    if (_exercise == null || _timer != null) {
      print('DEBUG: Cannot start timer - exercise null? ${_exercise == null}, timer exists? ${_timer != null}');
      return;
    }
    
    if (_attempt?.status != AttemptStatus.inProgress) {
      print('DEBUG: Not starting timer - attempt status: ${_attempt?.status}');
      return;
    }
    
    final startTime = _attempt!.startTime;
    final now = DateTime.now();
    final elapsedSeconds = now.difference(startTime).inSeconds;
    final totalSeconds = _exercise!.timeLimit * 60;
    
    print('DEBUG: Exercise time limit: ${_exercise!.timeLimit} minutes ($totalSeconds seconds)');
    print('DEBUG: Attempt start time: $startTime');
    print('DEBUG: Current time: $now');
    print('DEBUG: Elapsed seconds: $elapsedSeconds');
    
    _remainingSeconds = totalSeconds - elapsedSeconds;
    print('DEBUG: Setting initial remaining seconds: $_remainingSeconds');
    
    if (_remainingSeconds <= 0) {
      print('DEBUG: No time remaining, submitting attempt');
      _timeExpired = true;
      _submitAttempt();
      return;
    }
    
    print('DEBUG: Starting timer with $_remainingSeconds seconds remaining');
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        print('DEBUG: Widget not mounted, cancelling timer');
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          if (_remainingSeconds % 30 == 0) {
            print('DEBUG: Timer update - $_remainingSeconds seconds remaining');
          }
        } else {
          print('DEBUG: Time expired, submitting attempt');
          _timeExpired = true;
          _timer?.cancel();
          _timer = null;
          _submitAttempt();
        }
      });
    });
  }
  
  String get _formattedTime {
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  Future<void> _updateAnswer(String questionId, dynamic answer) async {
    if (_attempt == null || _isSubmitting || !mounted) return;
    
    setState(() {
      _answers[questionId] = answer;
    });
    
    try {
      await _exerciseService.updateAttemptAnswers(
        _attempt!.id!,
        {questionId: answer},
      );
    } catch (e) {
      print('Error updating answer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật câu trả lời: $e')),
        );
      }
    }
  }
  
  Future<void> _submitAttempt() async {
    print('Submitting attempt: _attempt null? ${_attempt == null}, _isSubmitting? $_isSubmitting, status: ${_attempt?.status}');
    
    if (_attempt == null || _isSubmitting || _attempt?.status != AttemptStatus.inProgress || !mounted) {
      print('Not submitting attempt due to conditions not met');
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      print('Calling exerciseService.submitAttempt with ID: ${_attempt!.id!}');
      final completedAttempt = await _exerciseService.submitAttempt(_attempt!.id!);
      
      if (!mounted) {
        print('Widget no longer mounted after submission');
        return;
      }
      
      setState(() {
        _attempt = completedAttempt;
        _isSubmitting = false;
      });
      
      _timer?.cancel();
      _timer = null;
      print('Attempt submitted successfully, score: ${completedAttempt.score}');
      
      // Track quiz activity in analytics
      if (_exercise != null) {
        _analyticsService.trackQuizActivity(
          userId: _auth.currentUser?.uid ?? '',
          lessonId: widget.lessonId,
          classroomId: widget.classroomId,
          quizId: _exercise!.id ?? '',
          quizTitle: _exercise!.title,
          action: 'completed',
          totalQuestions: _exercise!.questions.length,
          answeredQuestions: _answers.length,
          score: completedAttempt.score,
          isCompleted: true,
          timestamp: DateTime.now(),
        );
      }
      
      _showResultDialog(completedAttempt);
    } catch (e) {
      print('Error submitting attempt: $e');
      
      if (!mounted) {
        print('Widget no longer mounted after submission error');
        return;
      }
      
      setState(() {
        _isSubmitting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi nộp bài: $e')),
      );
    }
  }
  
  void _showResultDialog(ExerciseAttempt attempt) {
    if (!mounted) {
      print('Widget no longer mounted, cannot show result dialog');
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          attempt.passed ? 'Chúc mừng!' : 'Đã hoàn thành bài tập',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              attempt.passed ? Icons.check_circle : Icons.info_outline,
              color: attempt.passed ? Colors.green : Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              attempt.passed 
                  ? 'Bạn đã hoàn thành bài tập thành công!'
                  : 'Bạn đã hoàn thành bài tập.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Điểm số: ${attempt.score.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: attempt.passed ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thời gian: ${(attempt.timeSpentSeconds / 60).floor()} phút ${attempt.timeSpentSeconds % 60} giây',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Quay lại danh sách'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Xem chi tiết'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_exercise?.title ?? 'Bài tập'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Kiểm tra'),
            ],
          ),
          actions: [
            if (!_isTeacherOrAdmin && _exercise != null && _attempt?.status == AttemptStatus.inProgress)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _remainingSeconds < 60 ? Colors.red : Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (_isTeacherOrAdmin && _exercise != null) ...[
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditExerciseScreen(
                        exercise: _exercise!,
                        onSaved: () {
                          if (mounted) {
                            _loadExercise();
                          }
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Chỉnh sửa bài tập',
              ),
              IconButton(
                onPressed: () {
                  _showDeleteConfirmation();
                },
                icon: const Icon(Icons.delete),
                tooltip: 'Xóa bài tập',
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            _buildStatusInfo(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
        bottomNavigationBar: !_isTeacherOrAdmin && _hasStarted ? _buildBottomBar() : null,
        floatingActionButton: _isTeacherOrAdmin ? FloatingActionButton(
          onPressed: () {
            // TODO: Navigate to add question screen
          },
          child: const Icon(Icons.add),
          tooltip: 'Thêm câu hỏi',
        ) : null,
      ),
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
              onPressed: _loadExercise,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    
    if (_exercise == null) {
      return const Center(child: Text('Không tìm thấy thông tin bài tập'));
    }

    if (_isTeacherOrAdmin) {
      return _buildTeacherView();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // Tab kiểm tra
        _buildExamTab(),
        
        // Tab luyện tập
        _buildPracticeView(),
      ],
    );
  }
  
  Widget _buildTeacherView() {
    if (_exercise == null) return const SizedBox.shrink();
    
    final questions = _exercise!.questions;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _exercise!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_exercise!.description != null) ...[
                  const SizedBox(height: 8),
                  Text(_exercise!.description!),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.timer_outlined,
                      'Thời gian: ${_exercise!.timeLimit} phút',
                    ),
                    _buildInfoChip(
                      Icons.question_answer_outlined,
                      'Câu hỏi: ${questions.length}',
                    ),
                    _buildInfoChip(
                      Icons.replay,
                      'Lượt làm: ${_exercise!.attemptsAllowed}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Danh sách câu hỏi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (questions.isEmpty) ...[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Icon(Icons.question_mark, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có câu hỏi nào',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to add question screen
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm câu hỏi'),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    question.content,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Loại: ${_getQuestionTypeText(question.type)}'),
                      Text('Điểm: ${question.points}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditQuestionScreen(
                                question: question,
                                exerciseId: _exercise!.id,
                                onSaved: (updatedQuestion) {
                                  _loadExercise();
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Chỉnh sửa câu hỏi',
                      ),
                      IconButton(
                        onPressed: () {
                          _showDeleteQuestionConfirmation(question);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Xóa câu hỏi',
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: Show question details
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }
  
  String _getQuestionTypeText(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Trắc nghiệm';
      case QuestionType.trueFalse:
        return 'Đúng/Sai';
      case QuestionType.multiSelect:
        return 'Nhiều lựa chọn';
      case QuestionType.fillInBlank:
        return 'Điền vào chỗ trống';
      case QuestionType.shortAnswer:
        return 'Trả lời ngắn';
      case QuestionType.essay:
        return 'Trả lời dài';
      case QuestionType.matching:
        return 'Ghép đôi';
      case QuestionType.ordering:
        return 'Sắp xếp';
      default:
        return 'Không xác định';
    }
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
  
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài tập'),
        content: Text('Bạn có chắc chắn muốn xóa bài tập "${_exercise!.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _exerciseService.deleteExercise(_exercise!.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa bài tập thành công')),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteQuestionConfirmation(Question question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa câu hỏi'),
        content: const Text('Bạn có chắc chắn muốn xóa câu hỏi này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng xóa câu hỏi chưa được triển khai')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultView() {
    if (_exercise == null || _attempt == null) return const SizedBox.shrink();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _exercise!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_exercise!.description != null) ...[
                  const SizedBox(height: 8),
                  Text(_exercise!.description!),
                ],
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _attempt!.passed ? Icons.check_circle : Icons.info_outline,
                    color: _attempt!.passed ? Colors.green : Colors.orange,
                    size: 36,
                  ),
                  title: Text(
                    'Điểm số: ${_attempt!.score.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _attempt!.passed ? Colors.green : Colors.orange,
                    ),
                  ),
                  subtitle: Text(
                    'Trạng thái: ${_attempt!.passed ? 'Đạt' : 'Chưa đạt'}',
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _attempt!.score / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _attempt!.passed ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildResultInfoItem(
                      Icons.calendar_today,
                      'Ngày làm',
                      _formatDateTime(_attempt!.startTime),
                    ),
                    _buildResultInfoItem(
                      Icons.timer,
                      'Thời gian làm',
                      '${(_attempt!.timeSpentSeconds / 60).floor()} phút ${_attempt!.timeSpentSeconds % 60} giây',
                    ),
                    _buildResultInfoItem(
                      Icons.replay,
                      'Lần làm',
                      '${_attempt!.attemptNumber}/${_exercise!.attemptsAllowed}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Chi tiết câu trả lời',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _exercise!.questions.length,
          itemBuilder: (context, index) {
            final question = _exercise!.questions[index];
            final answer = _attempt!.answers[question.id];
            final score = _attempt!.questionScores[question.id] ?? 0.0;
            final isCorrect = score >= question.points * 0.5;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}.',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(question.content),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAnswerResult(question, answer),
                    if (question.explanation != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Giải thích:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(question.explanation!),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildResultInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnswerResult(Question question, dynamic answer) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        if (question.choices == null) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: question.choices!.map((choice) {
            final isSelected = answer == choice.id;
            final isCorrect = choice.isCorrect;
            
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isSelected
                    ? (isCorrect ? Icons.check_circle : Icons.cancel)
                    : (isCorrect ? Icons.check_circle_outline : Icons.circle_outlined),
                color: isSelected
                    ? (isCorrect ? Colors.green : Colors.red)
                    : (isCorrect ? Colors.green : Colors.grey),
              ),
              title: Text(choice.content),
              dense: true,
            );
          }).toList(),
        );
      
      case QuestionType.multiSelect:
        if (question.choices == null || answer == null || answer is! List) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: question.choices!.map((choice) {
            final isSelected = (answer as List).contains(choice.id);
            final isCorrect = choice.isCorrect;
            
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isSelected
                    ? (isCorrect ? Icons.check_circle : Icons.cancel)
                    : (isCorrect ? Icons.check_circle_outline : Icons.circle_outlined),
                color: isSelected
                    ? (isCorrect ? Colors.green : Colors.red)
                    : (isCorrect ? Colors.green : Colors.grey),
              ),
              title: Text(choice.content),
              dense: true,
            );
          }).toList(),
        );
      
      case QuestionType.fillInBlank:
      case QuestionType.shortAnswer:
        final correctAnswers = question.acceptableAnswers?.join(', ') ?? '';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Câu trả lời của bạn:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(answer?.toString() ?? 'Chưa trả lời'),
            const SizedBox(height: 8),
            const Text(
              'Câu trả lời đúng:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(correctAnswers),
          ],
        );
      
      default:
        return const Text('Không hỗ trợ hiển thị loại câu hỏi này');
    }
  }
  
  Widget _buildExamTab() {
    if (!_hasStarted) {
      return _buildStartView();
    }

    if (_attempt?.status == AttemptStatus.completed) {
      return _buildResultView();
    }

    if (_attempt?.status == AttemptStatus.inProgress) {
      return _buildExerciseView();
    }

    // Nếu chưa có attempt hoặc attempt không ở trạng thái in_progress/completed
    return _buildStartView();
  }
  
  Widget _buildExerciseView() {
    if (_exercise == null) {
      print('ERROR: Exercise is null in _buildQuestionView');
      return const Center(child: Text('Không tìm thấy thông tin bài tập'));
    }
    
    final questions = _exercise!.questions;
    print('Building question view, questions count: ${questions.length}');
    
    if (questions.isEmpty) {
      print('Questions array is empty for exercise: ${_exercise!.id}');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Bài tập này chưa có câu hỏi nào',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _loadExercise();
              },
              child: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }
    
    if (_currentQuestionIndex >= questions.length) {
      print('WARNING: Current question index out of bounds: $_currentQuestionIndex >= ${questions.length}');
      _currentQuestionIndex = 0;
    }
    
    final currentQuestion = questions[_currentQuestionIndex];
    final hasAnswer = _answers.containsKey(currentQuestion.id);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _exercise!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_exercise!.description != null) ...[
                  const SizedBox(height: 8),
                  Text(_exercise!.description!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / questions.length,
          backgroundColor: Colors.grey.shade300,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Câu ${_currentQuestionIndex + 1}/${questions.length}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            Text(
              'Điểm: ${currentQuestion.points}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentQuestion.content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildQuestionInput(currentQuestion),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuestionInput(Question question) {
    final answer = _answers[question.id];
    
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        if (question.choices == null) return const SizedBox.shrink();
        
        return Column(
          children: question.choices!.map((choice) {
            return RadioListTile<String>(
              title: Text(choice.content),
              value: choice.id,
              groupValue: answer as String?,
              onChanged: (value) {
                if (value != null) {
                  _updateAnswer(question.id, value);
                }
              },
            );
          }).toList(),
        );
      
      case QuestionType.multiSelect:
        if (question.choices == null) return const SizedBox.shrink();
        
        List<String> selectedChoices = [];
        if (answer != null && answer is List) {
          selectedChoices = List<String>.from(answer);
        }
        
        return Column(
          children: question.choices!.map((choice) {
            return CheckboxListTile(
              title: Text(choice.content),
              value: selectedChoices.contains(choice.id),
              onChanged: (value) {
                List<String> updatedChoices = List.from(selectedChoices);
                if (value == true) {
                  updatedChoices.add(choice.id);
                } else {
                  updatedChoices.remove(choice.id);
                }
                _updateAnswer(question.id, updatedChoices);
              },
            );
          }).toList(),
        );
      
      case QuestionType.fillInBlank:
      case QuestionType.shortAnswer:
        return TextFormField(
          initialValue: answer as String?,
          decoration: const InputDecoration(
            hintText: 'Nhập câu trả lời của bạn...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) {
            _updateAnswer(question.id, value);
          },
        );
      
      case QuestionType.essay:
        return TextFormField(
          initialValue: answer as String?,
          decoration: const InputDecoration(
            hintText: 'Nhập câu trả lời của bạn...',
            border: OutlineInputBorder(),
          ),
          maxLines: 8,
          onChanged: (value) {
            _updateAnswer(question.id, value);
          },
        );
      
      default:
        return const Text('Không hỗ trợ loại câu hỏi này');
    }
  }
  
  Widget? _buildBottomBar() {
    if (_exercise == null || _attempt == null || _attempt?.status != AttemptStatus.inProgress) {
      return null;
    }
    
    final questions = _exercise!.questions;
    final hasAnswer = _answers.containsKey(questions[_currentQuestionIndex].id);
    
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentQuestionIndex > 0)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentQuestionIndex--;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Trước'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black,
                ),
              )
            else
              const SizedBox.shrink(),
            if (_currentQuestionIndex < questions.length - 1)
              ElevatedButton.icon(
                onPressed: hasAnswer 
                    ? () {
                        setState(() {
                          _currentQuestionIndex++;
                        });
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Tiếp'),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitAttempt,
                icon: _isSubmitting 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(_isSubmitting ? 'Đang nộp...' : 'Nộp bài'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<bool> _onWillPop() async {
    if (!_hasStarted || _isTeacherOrAdmin || _attempt?.status != AttemptStatus.inProgress) {
      return true;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát khỏi bài tập?'),
        content: const Text('Nếu bạn thoát bây giờ, kết quả hiện tại sẽ được nộp. Bạn có chắc chắn muốn thoát?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('NỘP & THOÁT'),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirmed) {
      await _submitAttempt();
    }
    
    return confirmed;
  }

  Widget _buildStartView() {
    if (_exercise == null) return const SizedBox.shrink();
    
    return FutureBuilder<List<ExerciseAttempt>>(
      future: _exerciseService.getAttemptsByUser(_auth.currentUser!.uid, widget.exerciseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final attempts = snapshot.data ?? [];
        final usedAttempts = attempts.where(
          (a) => a.status == AttemptStatus.completed || a.status == AttemptStatus.inProgress
        ).length;
        
        final remainingAttempts = _exercise!.attemptsAllowed - usedAttempts;
        final canStartNewAttempt = remainingAttempts > 0;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _exercise!.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_exercise!.description != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _exercise!.description!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoItem(
                            Icons.timer_outlined,
                            'Thời gian làm bài',
                            '${_exercise!.timeLimit} phút',
                          ),
                          _buildInfoItem(
                            Icons.question_answer_outlined,
                            'Số câu hỏi',
                            '${_exercise!.questions.length} câu',
                          ),
                          _buildInfoItem(
                            Icons.repeat,
                            'Số lần còn lại',
                            '$remainingAttempts/${_exercise!.attemptsAllowed}',
                            textColor: remainingAttempts > 0 ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (!canStartNewAttempt) ...[
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text(
                        'Bạn đã sử dụng hết số lần làm bài',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Bạn chỉ có thể xem lại kết quả các lần làm trước',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Lưu ý',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Khi bắt đầu làm bài, thời gian sẽ được tính ngay lập tức.'),
                      SizedBox(height: 4),
                      Text('• Đảm bảo bạn có đủ thời gian để hoàn thành bài tập.'),
                      SizedBox(height: 4),
                      Text('• Nếu thoát giữa chừng, kết quả hiện tại sẽ được nộp.'),
                      SizedBox(height: 4),
                      Text('• Chỉ bắt đầu khi bạn đã sẵn sàng.'),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ElevatedButton(
                    onPressed: _startAttempt,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'BẮT ĐẦU LÀM BÀI',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInfoItem(IconData icon, String label, String value, {Color? textColor}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue.shade700),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Future<void> _startAttempt() async {
    if (_exercise == null || _auth.currentUser == null) {
      print('Exercise or user is null, cannot start attempt');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('Creating new attempt');
      final attempt = await _exerciseService.createAttempt(
        userId: _auth.currentUser!.uid,
        exerciseId: widget.exerciseId,
        lessonId: widget.lessonId,
        classroomId: widget.classroomId,
      );
      
      if (!mounted) return;
      
      setState(() {
        _attempt = attempt;
        _isLoading = false;
        _hasStarted = true;
      });
      
      // Track starting quiz in analytics
      _trackQuizStart();
      
      print('Starting timer for new attempt');
      _startTimer();
    } catch (e) {
      print('Error starting attempt: $e');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể bắt đầu bài tập: $e')),
      );
    }
  }

  // Track quiz start
  void _trackQuizStart() {
    if (_exercise == null || _auth.currentUser == null) return;
    
    _analyticsService.trackQuizActivity(
      userId: _auth.currentUser!.uid,
      lessonId: widget.lessonId,
      classroomId: widget.classroomId,
      quizId: _exercise!.id ?? '',
      quizTitle: _exercise!.title,
      action: 'start',
      totalQuestions: _exercise!.questions.length,
      answeredQuestions: 0,
      score: 0.0,
      isCompleted: false,
      timestamp: DateTime.now(),
    );
  }

  // Future<void> _loadFlashcardItems() async {
  //   print('Loading flashcard items for lesson: ${widget.lessonId}');
  //   try {
  //     setState(() {
  //       _isLoading = true;
  //       _errorMessage = null;
  //     });

  //     final flashcardService = FlashcardService();
  //     final flashcards = await flashcardService.getLessonFlashcards(widget.lessonId);
  //     print('Found ${flashcards.length} flashcards');

  //     if (flashcards.isEmpty) {
  //       print('No flashcards found for lesson, using mock data');
  //       // Tạo dữ liệu mock
  //       final mockItems = [
  //         FlashcardItem(
  //           flashcardId: 'mock_1',
  //           question: 'Hello',
  //           answer: 'Xin chào',
  //         ),
  //         FlashcardItem(
  //           flashcardId: 'mock_2',
  //           question: 'Good morning',
  //           answer: 'Chào buổi sáng',
  //         ),
  //         FlashcardItem(
  //           flashcardId: 'mock_3',
  //           question: 'How are you?',
  //           answer: 'Bạn khỏe không?',
  //         ),
  //         FlashcardItem(
  //           flashcardId: 'mock_4',
  //           question: 'Thank you',
  //           answer: 'Cảm ơn',
  //         ),
  //         FlashcardItem(
  //           flashcardId: 'mock_5',
  //           question: 'Goodbye',
  //           answer: 'Tạm biệt',
  //         ),
  //         FlashcardItem(
  //           flashcardId: 'mock_6',
  //           question: 'Please',
  //           answer: 'Làm ơn',
  //         ),
  //         FlashcardItem(
  //           flashcardId: 'mock_7',
  //           question: 'Sorry',
  //           answer: 'Xin lỗi',
  //         ),
  //         FlashcardItem(
  //           flashcardId: 'mock_8',
  //           question: 'Yes',
  //           answer: 'Có',
  //         ),
  //         FlashcardItem(
  //           flashcardId: 'mock_9',
  //           question: 'No',
  //           answer: 'Không',
  //         ),
  //         FlashcardItem(
  //           flashcardId: 'mock_10',
  //           question: 'I love you',
  //           answer: 'Tôi yêu bạn',
  //         ),
  //       ];

  //       setState(() {
  //         _flashcardItems = mockItems;
  //         _isLoading = false;
  //       });
  //       return;
  //     }

  //     // Lấy tất cả items của các flashcard
  //     List<FlashcardItem> allItems = [];
  //     for (var flashcard in flashcards) {
  //       print('Loading items for flashcard: ${flashcard.id}');
  //       if (flashcard.id != null) {
  //         final items = await flashcardService.getFlashcardItems(flashcard.id!);
  //         print('Found ${items.length} items for flashcard ${flashcard.id}');
  //         allItems.addAll(items);
  //       }
  //     }

  //     print('Total items loaded: ${allItems.length}');
  //     setState(() {
  //       _flashcardItems = allItems;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     print('Error loading flashcard items: $e');
  //     setState(() {
  //       _errorMessage = 'Không thể tải flashcard: ${e.toString()}';
  //       _isLoading = false;
  //       _flashcardItems = [];
  //     });
  //   }
  // }

  Widget _buildPracticeView() {
    if (_flashcardItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Chưa có thẻ ghi nhớ để luyện tập',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Chọn trò chơi để luyện tập',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Fill in the blank game
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Điền từ'),
              subtitle: const Text('Điền từ còn thiếu vào chỗ trống'),
              onTap: () {
                // Lọc các flashcard items phù hợp cho trò chơi điền từ
                final validItems = _flashcardItems.where((item) => 
                  item.type == FlashcardItemType.textToText || 
                  item.type == FlashcardItemType.imageToText
                ).toList();

                if (validItems.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không có từ vựng phù hợp cho trò chơi này'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FillInTheBlankGame(
                      items: validItems,
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Matching game
          Card(
            child: ListTile(
              leading: const Icon(Icons.link, color: Colors.green),
              title: const Text('Nối từ'),
              subtitle: const Text('Nối từ với nghĩa tương ứng'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchingGame(
                      items: _flashcardItems,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo() {
    if (_exercise == null || _isTeacherOrAdmin) return const SizedBox.shrink();

    return FutureBuilder<List<ExerciseAttempt>>(
      future: _exerciseService.getAttemptsByUser(_auth.currentUser!.uid, widget.exerciseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final attempts = snapshot.data ?? [];
        final usedAttempts = attempts.where(
          (a) => a.status == AttemptStatus.completed || a.status == AttemptStatus.inProgress
        ).length;
        
        final remainingAttempts = _exercise!.attemptsAllowed - usedAttempts;

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin bài làm:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: 20,
                    color: remainingAttempts > 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Số lần còn lại: $remainingAttempts/${_exercise!.attemptsAllowed}',
                    style: TextStyle(
                      color: remainingAttempts > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              if (_attempt?.status == AttemptStatus.inProgress) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 20,
                      color: _remainingSeconds > 60 ? Colors.blue : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thời gian còn lại: $_formattedTime',
                      style: TextStyle(
                        color: _remainingSeconds > 60 ? Colors.blue : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
              if (remainingAttempts <= 0) ...[
                const SizedBox(height: 12),
                const Text(
                  'Bạn đã sử dụng hết số lần làm bài. Chỉ có thể xem lại kết quả.',
                  style: TextStyle(
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (_timeExpired) ...[
                const SizedBox(height: 12),
                const Text(
                  'Hết thời gian làm bài!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
} 