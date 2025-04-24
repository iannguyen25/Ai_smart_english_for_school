import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';
import 'quiz.dart';
import 'question_bank.dart';

class DifficultyMatrix {
  final int easyCount;
  final int mediumCount;
  final int hardCount;

  const DifficultyMatrix({
    this.easyCount = 0,
    this.mediumCount = 0,
    this.hardCount = 0,
  });

  factory DifficultyMatrix.fromMap(Map<String, dynamic> map) {
    return DifficultyMatrix(
      easyCount: map['easyCount'] ?? 0,
      mediumCount: map['mediumCount'] ?? 0,
      hardCount: map['hardCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'easyCount': easyCount,
      'mediumCount': mediumCount,
      'hardCount': hardCount,
    };
  }

  int get totalQuestions => easyCount + mediumCount + hardCount;
}

class Exercise extends BaseModel {
  final String title;
  final String? description;
  final String? lessonId;
  final String classroomId;
  final List<Question> questions;
  final bool shuffle;
  final DifficultyMatrix difficultyMatrix;
  final int timeLimit;
  final int attemptsAllowed;
  final bool visibility;
  final String createdBy;
  final List<String> questionBankIds;
  final List<String> tags;

  Exercise({
    String? id,
    required this.title,
    this.description,
    this.lessonId,
    required this.classroomId,
    required this.questions,
    this.shuffle = true,
    this.difficultyMatrix = const DifficultyMatrix(),
    required this.timeLimit,
    this.attemptsAllowed = 1,
    this.visibility = true,
    required this.createdBy,
    this.questionBankIds = const [],
    this.tags = const [],
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory Exercise.fromMap(Map<String, dynamic> map, String id) {
    // Debug logging
    if (map['questions'] == null) {
      print('WARNING: questions is null in Exercise.fromMap for id: $id');
    } else if (!(map['questions'] is List) || (map['questions'] as List).isEmpty) {
      print('WARNING: questions is empty or not a List in Exercise.fromMap for id: $id');
      print('questions type: ${map['questions'].runtimeType}, value: ${map['questions']}');
    }
    
    List<Question> parsedQuestions = [];
    if (map['questions'] != null && map['questions'] is List) {
      try {
        parsedQuestions = List<Question>.from(
          (map['questions'] as List).map((x) => Question.fromMap(x))
        );
        print('Successfully parsed ${parsedQuestions.length} questions for exercise: $id');
      } catch (e) {
        print('ERROR parsing questions in Exercise.fromMap: $e');
        // Try to parse and recover what we can
        for (var i = 0; i < (map['questions'] as List).length; i++) {
          try {
            final questionMap = (map['questions'] as List)[i];
            final question = Question.fromMap(questionMap);
            parsedQuestions.add(question);
          } catch (e) {
            print('Failed to parse question at index $i: $e');
          }
        }
      }
    }
    
    return Exercise(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      lessonId: map['lessonId'],
      classroomId: map['classroomId'] ?? '',
      questions: parsedQuestions,
      shuffle: map['shuffle'] ?? true,
      difficultyMatrix: map['difficultyMatrix'] != null
          ? DifficultyMatrix.fromMap(map['difficultyMatrix'])
          : const DifficultyMatrix(),
      timeLimit: map['timeLimit'] ?? 0,
      attemptsAllowed: map['attemptsAllowed'] ?? 1,
      visibility: map['visibility'] ?? true,
      createdBy: map['createdBy'] ?? '',
      questionBankIds: List<String>.from(map['questionBankIds'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
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
      'classroomId': classroomId,
      'questions': questions.map((x) => x.toMap()).toList(),
      'shuffle': shuffle,
      'difficultyMatrix': difficultyMatrix.toMap(),
      'timeLimit': timeLimit,
      'attemptsAllowed': attemptsAllowed,
      'visibility': visibility,
      'createdBy': createdBy,
      'questionBankIds': questionBankIds,
      'tags': tags,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? title,
    String? classroomId,
    List<Question>? questions,
    DifficultyMatrix? difficultyMatrix,
    int? timeLimit,
    int? attemptsAllowed,
    String? createdBy,
  }) {
    Map<String, String?> errors = {};

    if (title == null || title.isEmpty) {
      errors['title'] = 'Tiêu đề không được để trống';
    }

    if (classroomId == null || classroomId.isEmpty) {
      errors['classroomId'] = 'ID lớp học không được để trống';
    }

    if (questions == null || questions.isEmpty) {
      errors['questions'] = 'Phải có ít nhất một câu hỏi';
    }
    
    if (difficultyMatrix != null && 
        difficultyMatrix.totalQuestions > 0 &&
        (questions == null || questions.length < difficultyMatrix.totalQuestions)) {
      errors['difficultyMatrix'] = 'Không đủ câu hỏi để đáp ứng ma trận độ khó';
    }

    if (timeLimit != null && timeLimit < 0) {
      errors['timeLimit'] = 'Thời gian làm bài không được âm';
    }

    if (attemptsAllowed != null && attemptsAllowed < 1) {
      errors['attemptsAllowed'] = 'Số lần làm tối đa phải lớn hơn 0';
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
      classroomId: classroomId,
      questions: questions,
      difficultyMatrix: difficultyMatrix,
      timeLimit: timeLimit,
      attemptsAllowed: attemptsAllowed,
      createdBy: createdBy,
    );
  }

  // Tạo bài tập mới
  static Future<Exercise?> createExercise({
    required String title,
    String? description,
    String? lessonId,
    required String classroomId,
    required List<Question> questions,
    bool shuffle = true,
    DifficultyMatrix difficultyMatrix = const DifficultyMatrix(),
    required int timeLimit,
    int attemptsAllowed = 1,
    bool visibility = true,
    required String createdBy,
    List<String> questionBankIds = const [],
    List<String> tags = const [],
  }) async {
    final errors = validate(
      title: title,
      classroomId: classroomId,
      questions: questions,
      difficultyMatrix: difficultyMatrix,
      timeLimit: timeLimit,
      attemptsAllowed: attemptsAllowed,
      createdBy: createdBy,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final exerciseDoc = await FirebaseFirestore.instance
          .collection('exercises')
          .add({
        'title': title,
        'description': description,
        'lessonId': lessonId,
        'classroomId': classroomId,
        'questions': questions.map((x) => x.toMap()).toList(),
        'shuffle': shuffle,
        'difficultyMatrix': difficultyMatrix.toMap(),
        'timeLimit': timeLimit,
        'attemptsAllowed': attemptsAllowed,
        'visibility': visibility,
        'createdBy': createdBy,
        'questionBankIds': questionBankIds,
        'tags': tags,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final exerciseData = await exerciseDoc.get();
      return Exercise.fromMap(
        exerciseData.data() as Map<String, dynamic>,
        exerciseData.id,
      );
    } catch (e) {
      print('Error creating exercise: $e');
      return null;
    }
  }

  // Lấy bài tập theo ID lớp học
  static Future<List<Exercise>> getExercisesByClassroom(String classroomId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Exercise.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting exercises: $e');
      return [];
    }
  }

  // Lấy bài tập theo ID bài học
  static Future<List<Exercise>> getExercisesByLesson(String lessonId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('lessonId', isEqualTo: lessonId)
          .orderBy('createdAt')
          .get();

      return snapshot.docs
          .map((doc) => Exercise.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting exercises by lesson: $e');
      return [];
    }
  }

  // Lấy bài tập theo người tạo
  static Future<List<Exercise>> getExercisesByCreator(String creatorId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exercises')
          .where('createdBy', isEqualTo: creatorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Exercise.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting exercises by creator: $e');
      return [];
    }
  }

  // Tạo bài tập từ ngân hàng câu hỏi
  static Future<Exercise?> createFromQuestionBank({
    required String title,
    String? description,
    String? lessonId,
    required String classroomId,
    required DifficultyMatrix difficultyMatrix,
    required List<String> questionBankIds,
    required int timeLimit,
    int attemptsAllowed = 1,
    bool visibility = true,
    required String createdBy,
    List<String> tags = const [],
  }) async {
    try {
      List<Question> selectedQuestions = [];
      List<Question> easyQuestions = [];
      List<Question> mediumQuestions = [];
      List<Question> hardQuestions = [];
      
      // Lấy câu hỏi từ ngân hàng
      for (final bankId in questionBankIds) {
        final doc = await FirebaseFirestore.instance
            .collection('questionBanks')
            .doc(bankId)
            .get();
            
        if (!doc.exists) continue;
        
        final bank = QuestionBank.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        
        // Phân loại câu hỏi theo độ khó
        for (final question in bank.questions) {
          final metadata = question.metadata;
          if (metadata == null || !metadata.containsKey('difficulty')) {
            continue;
          }
          
          switch (metadata['difficulty']) {
            case 'easy':
              easyQuestions.add(question);
              break;
            case 'medium':
              mediumQuestions.add(question);
              break;
            case 'hard':
              hardQuestions.add(question);
              break;
          }
        }
      }
      
      // Chọn ngẫu nhiên theo số lượng từ ma trận độ khó
      easyQuestions.shuffle();
      mediumQuestions.shuffle();
      hardQuestions.shuffle();
      
      // Lấy câu hỏi theo số lượng yêu cầu
      selectedQuestions.addAll(easyQuestions.take(difficultyMatrix.easyCount));
      selectedQuestions.addAll(mediumQuestions.take(difficultyMatrix.mediumCount));
      selectedQuestions.addAll(hardQuestions.take(difficultyMatrix.hardCount));
      
      // Kiểm tra đủ số lượng câu hỏi chưa
      if (selectedQuestions.length < difficultyMatrix.totalQuestions) {
        print('Không đủ câu hỏi theo ma trận độ khó');
        return null;
      }
      
      // Tạo bài tập mới
      return await createExercise(
        title: title,
        description: description,
        lessonId: lessonId,
        classroomId: classroomId,
        questions: selectedQuestions,
        difficultyMatrix: difficultyMatrix,
        timeLimit: timeLimit,
        attemptsAllowed: attemptsAllowed,
        visibility: visibility,
        createdBy: createdBy,
        questionBankIds: questionBankIds,
        tags: tags,
      );
    } catch (e) {
      print('Error creating exercise from question bank: $e');
      return null;
    }
  }

  @override
  Exercise copyWith({
    String? id,
    String? title,
    String? description,
    String? lessonId,
    String? classroomId,
    List<Question>? questions,
    bool? shuffle,
    DifficultyMatrix? difficultyMatrix,
    int? timeLimit,
    int? attemptsAllowed,
    bool? visibility,
    String? createdBy,
    List<String>? questionBankIds,
    List<String>? tags,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lessonId: lessonId ?? this.lessonId,
      classroomId: classroomId ?? this.classroomId,
      questions: questions ?? this.questions,
      shuffle: shuffle ?? this.shuffle,
      difficultyMatrix: difficultyMatrix ?? this.difficultyMatrix,
      timeLimit: timeLimit ?? this.timeLimit,
      attemptsAllowed: attemptsAllowed ?? this.attemptsAllowed,
      visibility: visibility ?? this.visibility,
      createdBy: createdBy ?? this.createdBy,
      questionBankIds: questionBankIds ?? this.questionBankIds,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 