import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';
import 'quiz.dart';

enum DifficultyLevel {
  easy,
  medium,
  hard
}

extension DifficultyLevelLabel on DifficultyLevel {
  String get label {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Dễ';
      case DifficultyLevel.medium:
        return 'Trung bình';
      case DifficultyLevel.hard:
        return 'Khó';
    }
  }
}

class QuestionBank extends BaseModel {
  final String title;
  final String? description;
  final List<String> topics;
  final String createdBy;
  final List<Question> questions;
  final bool isPublic;
  final List<String> sharedWith;

  QuestionBank({
    String? id,
    required this.title,
    this.description,
    required this.topics,
    required this.createdBy,
    required this.questions,
    this.isPublic = false,
    this.sharedWith = const [],
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory QuestionBank.fromMap(Map<String, dynamic> map, String id) {
    return QuestionBank(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      topics: List<String>.from(map['topics'] ?? []),
      createdBy: map['createdBy'] ?? '',
      questions: map['questions'] != null
          ? List<Question>.from(
              map['questions'].map((x) => Question.fromMap(x)))
          : [],
      isPublic: map['isPublic'] ?? false,
      sharedWith: List<String>.from(map['sharedWith'] ?? []),
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'topics': topics,
      'createdBy': createdBy,
      'questions': questions.map((x) => x.toMap()).toList(),
      'isPublic': isPublic,
      'sharedWith': sharedWith,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  // Get questions by difficulty
  List<Question> getQuestionsByDifficulty(DifficultyLevel level) {
    return questions.where((q) {
      final metadata = q.metadata;
      if (metadata == null || !metadata.containsKey('difficulty')) {
        return false;
      }
      
      final difficultyStr = metadata['difficulty'];
      DifficultyLevel questionLevel;
      
      switch (difficultyStr) {
        case 'easy':
          questionLevel = DifficultyLevel.easy;
          break;
        case 'medium':
          questionLevel = DifficultyLevel.medium;
          break;
        case 'hard':
          questionLevel = DifficultyLevel.hard;
          break;
        default:
          return false;
      }
      
      return questionLevel == level;
    }).toList();
  }

  // Get questions by topic
  List<Question> getQuestionsByTopic(String topic) {
    return questions.where((q) {
      final metadata = q.metadata;
      if (metadata == null || !metadata.containsKey('topics')) {
        return false;
      }
      
      final questionTopics = List<String>.from(metadata['topics']);
      return questionTopics.contains(topic);
    }).toList();
  }

  // Add a question
  QuestionBank addQuestion(Question question) {
    final updatedQuestions = List<Question>.from(questions);
    updatedQuestions.add(question);
    
    return copyWith(
      questions: updatedQuestions,
      updatedAt: Timestamp.now(),
    );
  }

  // Remove a question
  QuestionBank removeQuestion(String questionId) {
    final updatedQuestions = questions.where((q) => q.id != questionId).toList();
    
    return copyWith(
      questions: updatedQuestions,
      updatedAt: Timestamp.now(),
    );
  }

  // Update a question
  QuestionBank updateQuestion(Question updatedQuestion) {
    final index = questions.indexWhere((q) => q.id == updatedQuestion.id);
    if (index == -1) {
      return this;
    }
    
    final updatedQuestions = List<Question>.from(questions);
    updatedQuestions[index] = updatedQuestion;
    
    return copyWith(
      questions: updatedQuestions,
      updatedAt: Timestamp.now(),
    );
  }

  // Validate
  static Map<String, String?> validate({
    String? title,
    String? createdBy,
    List<Question>? questions,
  }) {
    Map<String, String?> errors = {};

    if (title == null || title.isEmpty) {
      errors['title'] = 'Tiêu đề không được để trống';
    }

    if (createdBy == null || createdBy.isEmpty) {
      errors['createdBy'] = 'ID người tạo không được để trống';
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      title: title,
      createdBy: createdBy,
      questions: questions,
    );
  }

  // Tạo ngân hàng câu hỏi mới
  static Future<QuestionBank?> createQuestionBank({
    required String title,
    String? description,
    required List<String> topics,
    required String createdBy,
    List<Question> questions = const [],
    bool isPublic = false,
    List<String> sharedWith = const [],
  }) async {
    final errors = validate(
      title: title,
      createdBy: createdBy,
      questions: questions,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final bankDoc = await FirebaseFirestore.instance
          .collection('questionBanks')
          .add({
        'title': title,
        'description': description,
        'topics': topics,
        'createdBy': createdBy,
        'questions': questions.map((x) => x.toMap()).toList(),
        'isPublic': isPublic,
        'sharedWith': sharedWith,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final bankData = await bankDoc.get();
      return QuestionBank.fromMap(
        bankData.data() as Map<String, dynamic>,
        bankData.id,
      );
    } catch (e) {
      print('Error creating question bank: $e');
      return null;
    }
  }

  // Lấy ngân hàng câu hỏi theo người tạo
  static Future<List<QuestionBank>> getQuestionBanksByCreator(String creatorId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questionBanks')
          .where('createdBy', isEqualTo: creatorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => QuestionBank.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting question banks: $e');
      return [];
    }
  }

  // Lấy ngân hàng câu hỏi công khai và được chia sẻ
  static Future<List<QuestionBank>> getAccessibleQuestionBanks(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questionBanks')
          .where(Filter.or(
            Filter('isPublic', isEqualTo: true),
            Filter('createdBy', isEqualTo: userId),
            Filter('sharedWith', arrayContains: userId),
          ))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => QuestionBank.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting accessible question banks: $e');
      return [];
    }
  }

  @override
  QuestionBank copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? topics,
    String? createdBy,
    List<Question>? questions,
    bool? isPublic,
    List<String>? sharedWith,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return QuestionBank(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      topics: topics ?? this.topics,
      createdBy: createdBy ?? this.createdBy,
      questions: questions ?? this.questions,
      isPublic: isPublic ?? this.isPublic,
      sharedWith: sharedWith ?? this.sharedWith,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 