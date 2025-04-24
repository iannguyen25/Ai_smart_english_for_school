import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum QuestionType {
  multipleChoice,    // Chọn một đáp án
  multiSelect,       // Chọn nhiều đáp án
  trueFalse,         // Đúng/Sai
  fillInBlank,       // Điền vào chỗ trống
  matching,          // Nối câu
  ordering,          // Sắp xếp thứ tự
  shortAnswer,       // Trả lời ngắn
  essay              // Trả lời dài
}

extension QuestionTypeLabel on QuestionType {
  String get label {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Chọn một đáp án';
      case QuestionType.multiSelect:
        return 'Chọn nhiều đáp án';
      case QuestionType.trueFalse:
        return 'Đúng/Sai';
      case QuestionType.fillInBlank:
        return 'Điền vào chỗ trống';
      case QuestionType.matching:
        return 'Nối câu';
      case QuestionType.ordering:
        return 'Sắp xếp thứ tự';
      case QuestionType.shortAnswer:
        return 'Trả lời ngắn';
      case QuestionType.essay:
        return 'Trả lời dài';
    }
  }
}

class Choice {
  final String id;
  final String content;
  final bool isCorrect;
  final String? explanation;
  final Map<String, dynamic>? metadata;

  Choice({
    required this.id,
    required this.content,
    required this.isCorrect,
    this.explanation,
    this.metadata,
  });

  factory Choice.fromMap(Map<String, dynamic> map) {
    return Choice(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      isCorrect: map['isCorrect'] ?? false,
      explanation: map['explanation'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'isCorrect': isCorrect,
      'explanation': explanation,
      'metadata': metadata,
    };
  }
}

class MatchingPair {
  final String id;
  final String premise;
  final String response;
  final String? explanation;

  MatchingPair({
    required this.id,
    required this.premise,
    required this.response,
    this.explanation,
  });

  factory MatchingPair.fromMap(Map<String, dynamic> map) {
    return MatchingPair(
      id: map['id'] ?? '',
      premise: map['premise'] ?? '',
      response: map['response'] ?? '',
      explanation: map['explanation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'premise': premise,
      'response': response,
      'explanation': explanation,
    };
  }
}

class OrderingItem {
  final String id;
  final String content;
  final int correctPosition;
  final String? explanation;

  OrderingItem({
    required this.id,
    required this.content,
    required this.correctPosition,
    this.explanation,
  });

  factory OrderingItem.fromMap(Map<String, dynamic> map) {
    return OrderingItem(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      correctPosition: map['correctPosition'] ?? 0,
      explanation: map['explanation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'correctPosition': correctPosition,
      'explanation': explanation,
    };
  }
}

class Question {
  final String id;
  final String content;
  final QuestionType type;
  final double points;
  final String? explanation;
  final List<Choice>? choices;
  final List<MatchingPair>? matchingPairs;
  final List<OrderingItem>? orderingItems;
  final List<String>? acceptableAnswers;
  final Map<String, dynamic>? metadata;
  final bool shuffleChoices;
  final bool caseSensitive;

  Question({
    required this.id,
    required this.content,
    required this.type,
    required this.points,
    this.explanation,
    this.choices,
    this.matchingPairs,
    this.orderingItems,
    this.acceptableAnswers,
    this.metadata,
    this.shuffleChoices = true,
    this.caseSensitive = false,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      type: _questionTypeFromString(map['type'] ?? 'multipleChoice'),
      points: (map['points'] ?? 1.0).toDouble(),
      explanation: map['explanation'],
      choices: map['choices'] != null
          ? List<Choice>.from(
              map['choices'].map((x) => Choice.fromMap(x)))
          : null,
      matchingPairs: map['matchingPairs'] != null
          ? List<MatchingPair>.from(
              map['matchingPairs'].map((x) => MatchingPair.fromMap(x)))
          : null,
      orderingItems: map['orderingItems'] != null
          ? List<OrderingItem>.from(
              map['orderingItems'].map((x) => OrderingItem.fromMap(x)))
          : null,
      acceptableAnswers: map['acceptableAnswers'] != null
          ? List<String>.from(map['acceptableAnswers'])
          : null,
      metadata: map['metadata'],
      shuffleChoices: map['shuffleChoices'] ?? true,
      caseSensitive: map['caseSensitive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': _questionTypeToString(type),
      'points': points,
      'explanation': explanation,
      'choices': choices?.map((x) => x.toMap()).toList(),
      'matchingPairs': matchingPairs?.map((x) => x.toMap()).toList(),
      'orderingItems': orderingItems?.map((x) => x.toMap()).toList(),
      'acceptableAnswers': acceptableAnswers,
      'metadata': metadata,
      'shuffleChoices': shuffleChoices,
      'caseSensitive': caseSensitive,
    };
  }

  static QuestionType _questionTypeFromString(String type) {
    switch (type) {
      case 'multipleChoice':
        return QuestionType.multipleChoice;
      case 'multiSelect':
        return QuestionType.multiSelect;
      case 'trueFalse':
        return QuestionType.trueFalse;
      case 'fillInBlank':
        return QuestionType.fillInBlank;
      case 'matching':
        return QuestionType.matching;
      case 'ordering':
        return QuestionType.ordering;
      case 'shortAnswer':
        return QuestionType.shortAnswer;
      case 'essay':
        return QuestionType.essay;
      default:
        return QuestionType.multipleChoice;
    }
  }

  static String _questionTypeToString(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'multipleChoice';
      case QuestionType.multiSelect:
        return 'multiSelect';
      case QuestionType.trueFalse:
        return 'trueFalse';
      case QuestionType.fillInBlank:
        return 'fillInBlank';
      case QuestionType.matching:
        return 'matching';
      case QuestionType.ordering:
        return 'ordering';
      case QuestionType.shortAnswer:
        return 'shortAnswer';
      case QuestionType.essay:
        return 'essay';
    }
  }

  Question copyWith({
    String? id,
    String? content,
    QuestionType? type,
    double? points,
    String? explanation,
    List<Choice>? choices,
    List<MatchingPair>? matchingPairs,
    List<OrderingItem>? orderingItems,
    List<String>? acceptableAnswers,
    Map<String, dynamic>? metadata,
    bool? shuffleChoices,
    bool? caseSensitive,
  }) {
    return Question(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      points: points ?? this.points,
      explanation: explanation ?? this.explanation,
      choices: choices ?? this.choices,
      matchingPairs: matchingPairs ?? this.matchingPairs,
      orderingItems: orderingItems ?? this.orderingItems,
      acceptableAnswers: acceptableAnswers ?? this.acceptableAnswers,
      metadata: metadata ?? this.metadata,
      shuffleChoices: shuffleChoices ?? this.shuffleChoices,
      caseSensitive: caseSensitive ?? this.caseSensitive,
    );
  }
}

class Quiz extends BaseModel {
  final String title;
  final String? description;
  final String lessonId;
  final List<Question> questions;
  final int timeLimit;          // Thời gian làm bài (phút)
  final double passingScore;    // Điểm đạt (%)
  final int maxAttempts;        // Số lần làm tối đa
  final bool shuffleQuestions;  // Xáo trộn câu hỏi
  final bool showAnswers;       // Hiển thị đáp án sau khi làm
  final bool showExplanation;   // Hiển thị giải thích
  final Map<String, dynamic>? metadata;

  Quiz({
    String? id,
    required this.title,
    this.description,
    required this.lessonId,
    required this.questions,
    required this.timeLimit,
    required this.passingScore,
    this.maxAttempts = 1,
    this.shuffleQuestions = true,
    this.showAnswers = true,
    this.showExplanation = true,
    this.metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory Quiz.fromMap(Map<String, dynamic> map, String id) {
    return Quiz(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      lessonId: map['lessonId'] ?? '',
      questions: map['questions'] != null
          ? List<Question>.from(
              map['questions'].map((x) => Question.fromMap(x)))
          : [],
      timeLimit: map['timeLimit'] ?? 60,
      passingScore: (map['passingScore'] ?? 70.0).toDouble(),
      maxAttempts: map['maxAttempts'] ?? 1,
      shuffleQuestions: map['shuffleQuestions'] ?? true,
      showAnswers: map['showAnswers'] ?? true,
      showExplanation: map['showExplanation'] ?? true,
      metadata: map['metadata'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'lessonId': lessonId,
      'questions': questions.map((x) => x.toMap()).toList(),
      'timeLimit': timeLimit,
      'passingScore': passingScore,
      'maxAttempts': maxAttempts,
      'shuffleQuestions': shuffleQuestions,
      'showAnswers': showAnswers,
      'showExplanation': showExplanation,
      'metadata': metadata,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? title,
    String? lessonId,
    List<Question>? questions,
    int? timeLimit,
    double? passingScore,
    int? maxAttempts,
  }) {
    Map<String, String?> errors = {};

    if (title == null || title.isEmpty) {
      errors['title'] = 'Tiêu đề không được để trống';
    }

    if (lessonId == null || lessonId.isEmpty) {
      errors['lessonId'] = 'ID bài học không được để trống';
    }

    if (questions == null || questions.isEmpty) {
      errors['questions'] = 'Phải có ít nhất một câu hỏi';
    }

    if (timeLimit != null && timeLimit < 1) {
      errors['timeLimit'] = 'Thời gian làm bài phải lớn hơn 0';
    }

    if (passingScore != null && (passingScore < 0 || passingScore > 100)) {
      errors['passingScore'] = 'Điểm đạt phải từ 0 đến 100';
    }

    if (maxAttempts != null && maxAttempts < 1) {
      errors['maxAttempts'] = 'Số lần làm tối đa phải lớn hơn 0';
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      title: title,
      lessonId: lessonId,
      questions: questions,
      timeLimit: timeLimit,
      passingScore: passingScore,
      maxAttempts: maxAttempts,
    );
  }

  // Tạo quiz mới
  static Future<Quiz?> createQuiz({
    required String title,
    String? description,
    required String lessonId,
    required List<Question> questions,
    required int timeLimit,
    required double passingScore,
    int maxAttempts = 1,
    bool shuffleQuestions = true,
    bool showAnswers = true,
    bool showExplanation = true,
    Map<String, dynamic>? metadata,
  }) async {
    final errors = validate(
      title: title,
      lessonId: lessonId,
      questions: questions,
      timeLimit: timeLimit,
      passingScore: passingScore,
      maxAttempts: maxAttempts,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final quizDoc = await FirebaseFirestore.instance
          .collection('quizzes')
          .add({
        'title': title,
        'description': description,
        'lessonId': lessonId,
        'questions': questions.map((x) => x.toMap()).toList(),
        'timeLimit': timeLimit,
        'passingScore': passingScore,
        'maxAttempts': maxAttempts,
        'shuffleQuestions': shuffleQuestions,
        'showAnswers': showAnswers,
        'showExplanation': showExplanation,
        'metadata': metadata,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final quizData = await quizDoc.get();
      return Quiz.fromMap(
        quizData.data() as Map<String, dynamic>,
        quizData.id,
      );
    } catch (e) {
      print('Error creating quiz: $e');
      return null;
    }
  }

  // Lấy quiz theo bài học
  static Future<List<Quiz>> getQuizzesByLesson(String lessonId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('quizzes')
          .where('lessonId', isEqualTo: lessonId)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => Quiz.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting quizzes: $e');
      return [];
    }
  }

  // Cập nhật quiz
  Future<bool> update({
    String? title,
    String? description,
    List<Question>? questions,
    int? timeLimit,
    double? passingScore,
    int? maxAttempts,
    bool? shuffleQuestions,
    bool? showAnswers,
    bool? showExplanation,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (id == null) return false;

      final errors = validate(
        title: title ?? this.title,
        lessonId: lessonId,
        questions: questions ?? this.questions,
        timeLimit: timeLimit ?? this.timeLimit,
        passingScore: passingScore ?? this.passingScore,
        maxAttempts: maxAttempts ?? this.maxAttempts,
      );

      if (errors.isNotEmpty) {
        print('Validation errors: $errors');
        return false;
      }

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (questions != null) {
        updates['questions'] = questions.map((x) => x.toMap()).toList();
      }
      if (timeLimit != null) updates['timeLimit'] = timeLimit;
      if (passingScore != null) updates['passingScore'] = passingScore;
      if (maxAttempts != null) updates['maxAttempts'] = maxAttempts;
      if (shuffleQuestions != null) {
        updates['shuffleQuestions'] = shuffleQuestions;
      }
      if (showAnswers != null) updates['showAnswers'] = showAnswers;
      if (showExplanation != null) {
        updates['showExplanation'] = showExplanation;
      }
      if (metadata != null) updates['metadata'] = metadata;

      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(id)
          .update(updates);

      return true;
    } catch (e) {
      print('Error updating quiz: $e');
      return false;
    }
  }

  // Xóa quiz
  Future<bool> delete() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('quizzes')
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting quiz: $e');
      return false;
    }
  }

  // Chấm điểm câu trả lời
  double gradeAnswer({
    required Question question,
    required dynamic answer,
  }) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        if (answer is String) {
          final choice = question.choices?.firstWhere(
            (c) => c.id == answer,
            orElse: () => Choice(id: '', content: '', isCorrect: false),
          );
          return choice?.isCorrect == true ? question.points : 0;
        }
        break;

      case QuestionType.multiSelect:
        if (answer is List<String>) {
          final correctChoices = question.choices
              ?.where((c) => c.isCorrect)
              .map((c) => c.id)
              .toList() ??
              [];
          final selectedChoices = answer;

          if (correctChoices.length != selectedChoices.length) return 0;

          final allCorrect = correctChoices.every(
              (id) => selectedChoices.contains(id));
          return allCorrect ? question.points : 0;
        }
        break;

      case QuestionType.fillInBlank:
      case QuestionType.shortAnswer:
        if (answer is String) {
          final acceptableAnswers = question.acceptableAnswers ?? [];
          final normalizedAnswer = question.caseSensitive
              ? answer
              : answer.toLowerCase();
          final isCorrect = acceptableAnswers.any((a) {
            final normalizedAcceptable = question.caseSensitive
                ? a
                : a.toLowerCase();
            return normalizedAcceptable == normalizedAnswer;
          });
          return isCorrect ? question.points : 0;
        }
        break;

      case QuestionType.matching:
        if (answer is Map<String, String>) {
          final pairs = question.matchingPairs ?? [];
          var correctCount = 0;
          for (var pair in pairs) {
            if (answer[pair.id] == pair.response) {
              correctCount++;
            }
          }
          return (correctCount / pairs.length) * question.points;
        }
        break;

      case QuestionType.ordering:
        if (answer is List<String>) {
          final items = question.orderingItems ?? [];
          var correctCount = 0;
          for (var i = 0; i < items.length; i++) {
            if (i < answer.length && items[i].id == answer[i]) {
              correctCount++;
            }
          }
          return (correctCount / items.length) * question.points;
        }
        break;

      case QuestionType.essay:
        // Câu trả lời dài cần giáo viên chấm điểm
        return -1;
    }

    return 0;
  }

  // Tính điểm tổng
  double calculateTotalScore(Map<String, dynamic> answers) {
    double totalScore = 0;
    double totalPoints = 0;

    for (var question in questions) {
      if (question.type != QuestionType.essay) {
        totalPoints += question.points;
        if (answers.containsKey(question.id)) {
          totalScore += gradeAnswer(
            question: question,
            answer: answers[question.id],
          );
        }
      }
    }

    return totalPoints > 0 ? (totalScore / totalPoints) * 100 : 0;
  }

  @override
  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    String? lessonId,
    List<Question>? questions,
    int? timeLimit,
    double? passingScore,
    int? maxAttempts,
    bool? shuffleQuestions,
    bool? showAnswers,
    bool? showExplanation,
    Map<String, dynamic>? metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lessonId: lessonId ?? this.lessonId,
      questions: questions ?? this.questions,
      timeLimit: timeLimit ?? this.timeLimit,
      passingScore: passingScore ?? this.passingScore,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      showAnswers: showAnswers ?? this.showAnswers,
      showExplanation: showExplanation ?? this.showExplanation,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 