import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';
import 'quiz_attempt.dart';

class ExerciseAttempt extends BaseModel {
  final String userId;
  final String exerciseId;
  final String lessonId;
  final String classroomId;
  final Map<String, dynamic> answers;
  final double score;
  final bool passed;
  final AttemptStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int timeSpentSeconds;
  final Map<String, double> questionScores;
  final Map<String, dynamic>? feedback;
  final int attemptNumber;

  ExerciseAttempt({
    String? id,
    required this.userId,
    required this.exerciseId,
    required this.lessonId,
    required this.classroomId,
    required this.answers,
    this.score = 0.0,
    this.passed = false,
    this.status = AttemptStatus.inProgress,
    required this.startTime,
    this.endTime,
    this.timeSpentSeconds = 0,
    this.questionScores = const {},
    this.feedback,
    this.attemptNumber = 1,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory ExerciseAttempt.fromMap(Map<String, dynamic> map, String id) {
    return ExerciseAttempt(
      id: id,
      userId: map['userId'] ?? '',
      exerciseId: map['exerciseId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      classroomId: map['classroomId'] ?? '',
      answers: map['answers'] ?? {},
      score: (map['score'] ?? 0.0).toDouble(),
      passed: map['passed'] ?? false,
      status: _statusFromString(map['status'] ?? 'inProgress'),
      startTime: map['startTime'] != null 
          ? (map['startTime'] as Timestamp).toDate() 
          : DateTime.now(),
      endTime: map['endTime'] != null 
          ? (map['endTime'] as Timestamp).toDate() 
          : null,
      timeSpentSeconds: map['timeSpentSeconds'] ?? 0,
      questionScores: _convertToDoubleMap(map['questionScores'] ?? {}),
      feedback: map['feedback'],
      attemptNumber: map['attemptNumber'] ?? 1,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  static Map<String, double> _convertToDoubleMap(Map<String, dynamic> map) {
    Map<String, double> result = {};
    map.forEach((key, value) {
      result[key] = (value ?? 0.0).toDouble();
    });
    return result;
  }

  static AttemptStatus _statusFromString(String status) {
    switch (status) {
      case 'inProgress':
        return AttemptStatus.inProgress;
      case 'completed':
        return AttemptStatus.completed;
      case 'abandoned':
        return AttemptStatus.abandoned;
      default:
        return AttemptStatus.inProgress;
    }
  }

  static String _statusToString(AttemptStatus status) {
    switch (status) {
      case AttemptStatus.inProgress:
        return 'inProgress';
      case AttemptStatus.completed:
        return 'completed';
      case AttemptStatus.abandoned:
        return 'abandoned';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'exerciseId': exerciseId,
      'lessonId': lessonId,
      'classroomId': classroomId,
      'answers': answers,
      'score': score,
      'passed': passed,
      'status': _statusToString(status),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'timeSpentSeconds': timeSpentSeconds,
      'questionScores': questionScores,
      'feedback': feedback,
      'attemptNumber': attemptNumber,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  // Calculate time spent on the attempt
  int calculateTimeSpent() {
    if (timeSpentSeconds > 0) {
      // If we already have time tracked, use that value
      // and add any additional time since last track if attempt is still in progress
      if (status == AttemptStatus.inProgress) {
        final now = DateTime.now();
        final additionalTime = now.difference(startTime).inSeconds - timeSpentSeconds;
        return timeSpentSeconds + (additionalTime > 0 ? additionalTime : 0);
      }
      return timeSpentSeconds;
    }
    
    // If endTime exists, calculate between start and end
    if (endTime != null) {
      return endTime!.difference(startTime).inSeconds;
    }
    
    // Otherwise calculate from start until now
    return DateTime.now().difference(startTime).inSeconds;
  }

  // Complete the attempt
  ExerciseAttempt complete({
    required double score,
    required bool passed,
    required Map<String, double> questionScores,
  }) {
    final now = DateTime.now();
    
    // Use existing timeSpentSeconds as base if it's already set
    // This handles cases where the attempt was started earlier but just completed
    int actualTimeSpent;
    if (timeSpentSeconds > 0) {
      // Add only the time since last update
      final lastUpdated = updatedAt?.toDate() ?? startTime;
      final additionalTime = now.difference(lastUpdated).inSeconds;
      actualTimeSpent = timeSpentSeconds + (additionalTime > 0 ? additionalTime : 0);
    } else {
      actualTimeSpent = now.difference(startTime).inSeconds;
    }
    
    print('Completing attempt: Start time: $startTime, End time: $now, Actual time spent: $actualTimeSpent seconds');
    
    return copyWith(
      score: score,
      passed: passed,
      status: AttemptStatus.completed,
      endTime: now,
      timeSpentSeconds: actualTimeSpent,
      questionScores: questionScores,
    );
  }

  // Abandon the attempt
  ExerciseAttempt abandon() {
    return copyWith(
      status: AttemptStatus.abandoned,
      endTime: DateTime.now(),
      timeSpentSeconds: calculateTimeSpent(),
    );
  }

  // Update answers during the exercise
  ExerciseAttempt updateAnswers(Map<String, dynamic> newAnswers) {
    Map<String, dynamic> updatedAnswers = Map.from(answers);
    updatedAnswers.addAll(newAnswers);
    
    return copyWith(
      answers: updatedAnswers,
      updatedAt: Timestamp.now(),
    );
  }

  // Add teacher feedback
  ExerciseAttempt addFeedback(Map<String, dynamic> newFeedback) {
    return copyWith(
      feedback: newFeedback,
      updatedAt: Timestamp.now(),
    );
  }

  // Tạo attempt mới
  static Future<ExerciseAttempt?> createAttempt({
    required String userId,
    required String exerciseId,
    required String lessonId,
    required String classroomId,
  }) async {
    try {
      // Kiểm tra số lần đã làm
      final attemptCount = await getAttemptCount(userId, exerciseId);
      
      final attempt = ExerciseAttempt(
        userId: userId,
        exerciseId: exerciseId,
        lessonId: lessonId,
        classroomId: classroomId,
        answers: {},
        startTime: DateTime.now(),
        attemptNumber: attemptCount + 1,
      );
      
      final doc = await FirebaseFirestore.instance
          .collection('exercise_attempts')
          .add(attempt.toMap());
          
      final data = await doc.get();
      return ExerciseAttempt.fromMap(data.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error creating exercise attempt: $e');
      return null;
    }
  }

  // Lấy số lần đã làm bài
  static Future<int> getAttemptCount(String userId, String exerciseId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('exercise_attempts')
          .where('userId', isEqualTo: userId)
          .where('exerciseId', isEqualTo: exerciseId)
          .where('status', isEqualTo: 'completed')
          .count()
          .get();
          
      return query.count ?? 0;
    } catch (e) {
      print('Error getting attempt count: $e');
      return 0;
    }
  }

  // Lấy danh sách attempts của một người dùng
  static Future<List<ExerciseAttempt>> getAttemptsByUser(String userId, String exerciseId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exercise_attempts')
          .where('userId', isEqualTo: userId)
          .where('exerciseId', isEqualTo: exerciseId)
          .orderBy('attemptNumber', descending: true)
          .get();
          
      return snapshot.docs
          .map((doc) => ExerciseAttempt.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting attempts by user: $e');
      return [];
    }
  }

  // Lấy kết quả cao nhất của một người dùng
  static Future<ExerciseAttempt?> getBestAttempt(String userId, String exerciseId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exercise_attempts')
          .where('userId', isEqualTo: userId)
          .where('exerciseId', isEqualTo: exerciseId)
          .where('status', isEqualTo: 'completed')
          .orderBy('score', descending: true)
          .limit(1)
          .get();
          
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      final doc = snapshot.docs.first;
      return ExerciseAttempt.fromMap(doc.data(), doc.id);
    } catch (e) {
      print('Error getting best attempt: $e');
      return null;
    }
  }

  // Lấy kết quả của tất cả học sinh trong một lớp học
  static Future<List<ExerciseAttempt>> getAttemptsByClassroom(String classroomId, String exerciseId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exercise_attempts')
          .where('classroomId', isEqualTo: classroomId)
          .where('exerciseId', isEqualTo: exerciseId)
          .where('status', isEqualTo: 'completed')
          .get();
          
      return snapshot.docs
          .map((doc) => ExerciseAttempt.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting attempts by classroom: $e');
      return [];
    }
  }

  // Cập nhật attempt
  Future<bool> update() async {
    try {
      if (id == null) return false;
      
      await FirebaseFirestore.instance
          .collection('exercise_attempts')
          .doc(id)
          .update(toMap());
          
      return true;
    } catch (e) {
      print('Error updating exercise attempt: $e');
      return false;
    }
  }

  @override
  ExerciseAttempt copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    String? lessonId,
    String? classroomId,
    Map<String, dynamic>? answers,
    double? score,
    bool? passed,
    AttemptStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? timeSpentSeconds,
    Map<String, double>? questionScores,
    Map<String, dynamic>? feedback,
    int? attemptNumber,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ExerciseAttempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      lessonId: lessonId ?? this.lessonId,
      classroomId: classroomId ?? this.classroomId,
      answers: answers ?? this.answers,
      score: score ?? this.score,
      passed: passed ?? this.passed,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      questionScores: questionScores ?? this.questionScores,
      feedback: feedback ?? this.feedback,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 