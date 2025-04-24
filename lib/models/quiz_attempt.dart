import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

enum AttemptStatus {
  inProgress,
  completed,
  abandoned
}

extension AttemptStatusLabel on AttemptStatus {
  String get label {
    switch (this) {
      case AttemptStatus.inProgress:
        return 'Đang làm';
      case AttemptStatus.completed:
        return 'Đã hoàn thành';
      case AttemptStatus.abandoned:
        return 'Đã bỏ dở';
    }
  }
}

class QuizAttempt extends BaseModel {
  final String userId;
  final String quizId;
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

  QuizAttempt({
    String? id,
    required this.userId,
    required this.quizId,
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
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory QuizAttempt.fromMap(Map<String, dynamic> map, String id) {
    return QuizAttempt(
      id: id,
      userId: map['userId'] ?? '',
      quizId: map['quizId'] ?? '',
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
      'quizId': quizId,
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
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  // Calculate time spent
  int calculateTimeSpent() {
    final now = DateTime.now();
    final end = endTime ?? now;
    return end.difference(startTime).inSeconds;
  }

  // Complete the attempt
  QuizAttempt complete({
    required double score,
    required bool passed,
    required Map<String, double> questionScores,
  }) {
    return copyWith(
      score: score,
      passed: passed,
      status: AttemptStatus.completed,
      endTime: DateTime.now(),
      timeSpentSeconds: calculateTimeSpent(),
      questionScores: questionScores,
    );
  }

  // Abandon the attempt
  QuizAttempt abandon() {
    return copyWith(
      status: AttemptStatus.abandoned,
      endTime: DateTime.now(),
      timeSpentSeconds: calculateTimeSpent(),
    );
  }

  // Update answers during the quiz
  QuizAttempt updateAnswers(Map<String, dynamic> newAnswers) {
    Map<String, dynamic> updatedAnswers = Map.from(answers);
    updatedAnswers.addAll(newAnswers);
    
    return copyWith(
      answers: updatedAnswers,
      updatedAt: Timestamp.now(),
    );
  }

  // Add teacher feedback
  QuizAttempt addFeedback(Map<String, dynamic> newFeedback) {
    return copyWith(
      feedback: newFeedback,
      updatedAt: Timestamp.now(),
    );
  }

  @override
  QuizAttempt copyWith({
    String? id,
    String? userId,
    String? quizId,
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
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      quizId: quizId ?? this.quizId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 