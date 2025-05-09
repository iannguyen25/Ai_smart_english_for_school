import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import '../models/exercise_attempt.dart';
import '../models/question_bank.dart';
import '../models/quiz.dart';

class ExerciseService {
  // Singleton pattern
  static final ExerciseService _instance = ExerciseService._internal();
  factory ExerciseService() => _instance;
  ExerciseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _exercisesCollection => _firestore.collection('exercises');
  CollectionReference get _attemptsCollection => _firestore.collection('exercise_attempts');
  CollectionReference get _questionBanksCollection => _firestore.collection('questionBanks');

  // ============= Exercise Methods =============

  // Lấy danh sách bài tập theo lớp học
  Future<List<Exercise>> getExercisesByClassroom(String classroomId) async {
    try {
      final snapshot = await _exercisesCollection
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Exercise.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting exercises: $e');
      throw Exception('Không thể tải danh sách bài tập: $e');
    }
  }

  // Lấy bài tập theo bài học
  Future<List<Exercise>> getExercisesByLesson(String lessonId) async {
    try {
      final snapshot = await _exercisesCollection
          .where('lessonId', isEqualTo: lessonId)
          .orderBy('createdAt')
          .get();

      List<Exercise> exercises = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Fetch questions from exercise_questions collection
        final questionsSnapshot = await _firestore
            .collection('exercise_questions')
            .where('exerciseId', isEqualTo: doc.id)
            .orderBy('orderIndex')
            .get();
        
        // Convert Firestore questions to Question objects
        List<Question> questions = [];
        for (var questionDoc in questionsSnapshot.docs) {
          final questionData = questionDoc.data();
          
          // Convert options array to Choice objects
          List<Choice> choices = [];
          if (questionData['options'] != null && questionData['options'] is List) {
            final options = questionData['options'] as List;
            final correctIndex = questionData['correctOptionIndex'] as int? ?? 0;
            
            for (var i = 0; i < options.length; i++) {
              choices.add(Choice(
                id: i.toString(),
                content: options[i].toString(),
                isCorrect: i == correctIndex,
              ));
            }
          }
          
          // Create Question object
          questions.add(Question(
            id: questionDoc.id,
            content: questionData['questionText'] ?? '',
            type: QuestionType.multipleChoice, // Assuming multiple choice by default
            points: questionData['points'] ?? 1.0,
            choices: choices,
            explanation: questionData['explanation'] ?? '',
          ));
        }
        
        // Create a new map with questions included
        Map<String, dynamic> completeData = Map.from(data);
        completeData['questions'] = questions.map((q) => q.toMap()).toList();
        
        final exercise = Exercise.fromMap(completeData, doc.id);
        exercises.add(exercise);
      }

      return exercises;
    } catch (e) {
      print('Error getting exercises by lesson: $e');
      throw Exception('Không thể tải danh sách bài tập theo bài học: $e');
    }
  }

  // Lấy chi tiết bài tập
  Future<Exercise?> getExerciseById(String exerciseId, {bool forceRefresh = false}) async {
    try {
      print('Fetching exercise with ID: $exerciseId, forceRefresh: $forceRefresh');
      
      final doc = await _firestore.collection('exercises').doc(exerciseId).get();
      if (!doc.exists) {
        print('Exercise document not found');
        return null;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      print('Raw exercise data: ${data['title']}, has questions: ${data.containsKey('questions')}');
      
      // Handle time limit
      int timeLimit = data['timeLimit'] ?? 0;
      print('Time limit from Firestore: $timeLimit');
      
      if (timeLimit <= 0) {
        timeLimit = 15; // Default to 15 minutes
        print('WARNING: timeLimit is zero or null, setting default to $timeLimit minutes');
      }
      
      data['timeLimit'] = timeLimit;
      
      // Handle attempts allowed
      int attemptsAllowed = data['attemptsAllowed'] ?? 1;
      if (attemptsAllowed <= 0) {
        attemptsAllowed = 1; // Default to 1 attempt
        print('WARNING: attemptsAllowed is zero or null, setting default to $attemptsAllowed');
      }
      
      data['attemptsAllowed'] = attemptsAllowed;
      
      // Fetch questions from exercise_questions collection
      print('Fetching questions for exercise: $exerciseId');
      final questionsSnapshot = await _firestore
          .collection('exercise_questions')
          .where('exerciseId', isEqualTo: exerciseId)
          .orderBy('orderIndex')
          .get();
      
      // Convert Firestore questions to Question objects
      List<Question> questions = [];
      for (var doc in questionsSnapshot.docs) {
        final questionData = doc.data();
        print('Found question: ${doc.id}, text: ${questionData['questionText']}');
        
        // Convert options array to Choice objects
        List<Choice> choices = [];
        if (questionData['options'] != null && questionData['options'] is List) {
          final options = questionData['options'] as List;
          final correctIndex = questionData['correctOptionIndex'] as int? ?? 0;
          
          for (var i = 0; i < options.length; i++) {
            choices.add(Choice(
              id: i.toString(),
              content: options[i].toString(),
              isCorrect: i == correctIndex,
            ));
          }
        }
        
        // Create Question object
        questions.add(Question(
          id: doc.id,
          content: questionData['questionText'] ?? '',
          type: QuestionType.multipleChoice, // Assuming multiple choice by default
          points: questionData['points'] ?? 1.0,
          choices: choices,
          explanation: questionData['explanation'] ?? '',
        ));
      }
      
      print('Loaded ${questions.length} questions for exercise: $exerciseId');
      
      // Get basic exercise data
      final exerciseDoc = await _exercisesCollection.doc(exerciseId).get();
      if (!exerciseDoc.exists) {
        print('Exercise document does not exist after fetching questions: $exerciseId');
        return null;
      }
      
      final exerciseData = exerciseDoc.data() as Map<String, dynamic>;
      
      // Create a new map with questions included
      Map<String, dynamic> completeData = Map.from(exerciseData);
      completeData['questions'] = questions.map((q) => q.toMap()).toList();
      
      final exercise = Exercise.fromMap(completeData, exerciseDoc.id);
      print('Parsed exercise: ${exercise.id}, questions: ${exercise.questions.length}');
      
      return exercise;
    } catch (e, stackTrace) {
      print('Error getting exercise: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Không thể tải thông tin bài tập: $e');
    }
  }

  // Tạo bài tập mới
  Future<Exercise> createExercise({
    required String title,
    String? description,
    String? lessonId,
    required String classroomId,
    required List<Question> questions,
    bool shuffle = true,
    required DifficultyMatrix difficultyMatrix,
    required int timeLimit,
    int attemptsAllowed = 1,
    bool visibility = true,
    required String createdBy,
    List<String> questionBankIds = const [],
    List<String> tags = const [],
  }) async {
    try {
      final newExercise = await Exercise.createExercise(
        title: title,
        description: description,
        lessonId: lessonId,
        classroomId: classroomId,
        questions: questions,
        shuffle: shuffle,
        difficultyMatrix: difficultyMatrix,
        timeLimit: timeLimit,
        attemptsAllowed: attemptsAllowed,
        visibility: visibility,
        createdBy: createdBy,
        questionBankIds: questionBankIds,
        tags: tags,
      );
      
      if (newExercise == null) {
        throw Exception('Không thể tạo bài tập - lỗi validation');
      }
      
      return newExercise;
    } catch (e) {
      print('Error creating exercise: $e');
      throw Exception('Không thể tạo bài tập: $e');
    }
  }

  // Tạo bài tập từ ngân hàng câu hỏi
  Future<Exercise> createExerciseFromQuestionBank({
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
      final newExercise = await Exercise.createFromQuestionBank(
        title: title,
        description: description,
        lessonId: lessonId,
        classroomId: classroomId,
        difficultyMatrix: difficultyMatrix,
        questionBankIds: questionBankIds,
        timeLimit: timeLimit,
        attemptsAllowed: attemptsAllowed,
        visibility: visibility,
        createdBy: createdBy,
        tags: tags,
      );
      
      if (newExercise == null) {
        throw Exception('Không thể tạo bài tập từ ngân hàng câu hỏi - không đủ câu hỏi theo ma trận độ khó');
      }
      
      return newExercise;
    } catch (e) {
      print('Error creating exercise from question bank: $e');
      throw Exception('Không thể tạo bài tập từ ngân hàng câu hỏi: $e');
    }
  }

  // Cập nhật bài tập
  Future<void> updateExercise(String id, {
    String? title,
    String? description,
    List<Question>? questions,
    bool? shuffle,
    DifficultyMatrix? difficultyMatrix,
    int? timeLimit,
    int? attemptsAllowed,
    bool? visibility,
    List<String>? tags,
    Timestamp? startTime,
    Timestamp? endTime,
  }) async {
    try {
      print('Starting updateExercise for id: $id');
      
      final exercise = await getExerciseById(id);
      if (exercise == null) {
        throw Exception('Bài tập không tồn tại');
      }
      
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };
      
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (shuffle != null) updates['shuffle'] = shuffle;
      if (difficultyMatrix != null) updates['difficultyMatrix'] = difficultyMatrix.toMap();
      if (timeLimit != null) updates['timeLimit'] = timeLimit;
      if (attemptsAllowed != null) updates['attemptsAllowed'] = attemptsAllowed;
      if (visibility != null) updates['visibility'] = visibility;
      if (tags != null) updates['tags'] = tags;
      if (startTime != null) updates['startTime'] = startTime;
      if (endTime != null) updates['endTime'] = endTime;
      
      print('Applying basic updates to exercise document');
      await _exercisesCollection.doc(id).update(updates);
      
      // Nếu có câu hỏi được cập nhật, xử lý riêng
      if (questions != null) {
        print('Updating ${questions.length} questions for exercise: $id');
        // Xóa tất cả các câu hỏi hiện tại
        final querySnapshot = await _firestore.collection('exercise_questions')
            .where('exerciseId', isEqualTo: id)
            .get();
            
        print('Found ${querySnapshot.docs.length} existing questions to delete');
        
        // Xóa từng câu hỏi hiện tại
        final batch = _firestore.batch();
        for (var doc in querySnapshot.docs) {
          print('Adding delete operation for question: ${doc.id}');
          batch.delete(doc.reference);
        }
        
        // Thêm các câu hỏi mới
        for (int i = 0; i < questions.length; i++) {
          final question = questions[i];
          print('Adding new question: ${question.content} with ${question.choices?.length ?? 0} choices');
          
          final questionData = {
            'exerciseId': id,
            'orderIndex': i,
            'questionText': question.content,
            'type': question.type.toString(), // Convert enum to string if needed
            'points': question.points,
            'explanation': question.explanation ?? '',
          };
          
          // Nếu là câu hỏi trắc nghiệm
          if (question.choices != null && question.choices!.isNotEmpty) {
            final List<String> options = [];
            int correctOptionIndex = -1;
            
            for (int j = 0; j < question.choices!.length; j++) {
              final choice = question.choices![j];
              options.add(choice.content);
              if (choice.isCorrect) {
                correctOptionIndex = j;
              }
            }
            
            questionData['options'] = options;
            questionData['correctOptionIndex'] = correctOptionIndex >= 0 ? correctOptionIndex : 0;
          }
          
          print('Creating new question document with data: $questionData');
          final docRef = _firestore.collection('exercise_questions').doc();
          batch.set(docRef, questionData);
        }
        
        // Commit all changes
        print('Committing all question changes as a batch');
        await batch.commit();
        print('Batch committed successfully');
      }
      
      print('Exercise update completed successfully');
    } catch (e) {
      print('Error updating exercise: $e');
      throw Exception('Không thể cập nhật bài tập: $e');
    }
  }

  // Xóa bài tập
  Future<void> deleteExercise(String id) async {
    try {
      await _exercisesCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting exercise: $e');
      throw Exception('Không thể xóa bài tập: $e');
    }
  }

  // ============= Question Bank Methods =============

  // Lấy danh sách ngân hàng câu hỏi
  Future<List<QuestionBank>> getQuestionBanks(String userId) async {
    try {
      final snapshot = await _questionBanksCollection
          .where(Filter.or(
            Filter('isPublic', isEqualTo: true),
            Filter('createdBy', isEqualTo: userId),
            Filter('sharedWith', arrayContains: userId),
          ))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => QuestionBank.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting question banks: $e');
      throw Exception('Không thể tải danh sách ngân hàng câu hỏi: $e');
    }
  }

  // Lấy ngân hàng câu hỏi theo người tạo
  Future<List<QuestionBank>> getQuestionBanksByCreator(String creatorId) async {
    try {
      final snapshot = await _questionBanksCollection
          .where('createdBy', isEqualTo: creatorId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => QuestionBank.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting question banks by creator: $e');
      throw Exception('Không thể tải danh sách ngân hàng câu hỏi: $e');
    }
  }

  // Lấy chi tiết ngân hàng câu hỏi
  Future<QuestionBank?> getQuestionBankById(String id) async {
    try {
      final doc = await _questionBanksCollection.doc(id).get();
      if (!doc.exists) {
        return null;
      }
      return QuestionBank.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error getting question bank: $e');
      throw Exception('Không thể tải thông tin ngân hàng câu hỏi: $e');
    }
  }

  // Tạo ngân hàng câu hỏi mới
  Future<QuestionBank> createQuestionBank({
    required String title,
    String? description,
    required List<String> topics,
    required String createdBy,
    List<Question> questions = const [],
    bool isPublic = false,
    List<String> sharedWith = const [],
  }) async {
    try {
      final newBank = await QuestionBank.createQuestionBank(
        title: title,
        description: description,
        topics: topics,
        createdBy: createdBy,
        questions: questions,
        isPublic: isPublic,
        sharedWith: sharedWith,
      );
      
      if (newBank == null) {
        throw Exception('Không thể tạo ngân hàng câu hỏi - lỗi validation');
      }
      
      return newBank;
    } catch (e) {
      print('Error creating question bank: $e');
      throw Exception('Không thể tạo ngân hàng câu hỏi: $e');
    }
  }

  // Cập nhật ngân hàng câu hỏi
  Future<void> updateQuestionBank(String id, {
    String? title,
    String? description,
    List<String>? topics,
    List<Question>? questions,
    bool? isPublic,
    List<String>? sharedWith,
  }) async {
    try {
      final bank = await getQuestionBankById(id);
      if (bank == null) {
        throw Exception('Ngân hàng câu hỏi không tồn tại');
      }
      
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };
      
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (topics != null) updates['topics'] = topics;
      if (questions != null) updates['questions'] = questions.map((q) => q.toMap()).toList();
      if (isPublic != null) updates['isPublic'] = isPublic;
      if (sharedWith != null) updates['sharedWith'] = sharedWith;
      
      await _questionBanksCollection.doc(id).update(updates);
    } catch (e) {
      print('Error updating question bank: $e');
      throw Exception('Không thể cập nhật ngân hàng câu hỏi: $e');
    }
  }

  // Thêm câu hỏi vào ngân hàng
  Future<void> addQuestionToBank(String bankId, Question question) async {
    try {
      final bank = await getQuestionBankById(bankId);
      if (bank == null) {
        throw Exception('Ngân hàng câu hỏi không tồn tại');
      }
      
      // Tạo ID mới cho câu hỏi
      final questionId = DateTime.now().millisecondsSinceEpoch.toString();
      final newQuestion = question.copyWith(id: questionId);
      
      final updatedBank = bank.addQuestion(newQuestion);
      
      await _questionBanksCollection.doc(bankId).update({
        'questions': updatedBank.questions.map((q) => q.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error adding question to bank: $e');
      throw Exception('Không thể thêm câu hỏi vào ngân hàng: $e');
    }
  }

  // Cập nhật câu hỏi trong ngân hàng
  Future<void> updateQuestionInBank(String bankId, Question question) async {
    try {
      final bank = await getQuestionBankById(bankId);
      if (bank == null) {
        throw Exception('Ngân hàng câu hỏi không tồn tại');
      }
      
      final updatedBank = bank.updateQuestion(question);
      
      await _questionBanksCollection.doc(bankId).update({
        'questions': updatedBank.questions.map((q) => q.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating question in bank: $e');
      throw Exception('Không thể cập nhật câu hỏi trong ngân hàng: $e');
    }
  }

  // Xóa câu hỏi khỏi ngân hàng
  Future<void> removeQuestionFromBank(String bankId, String questionId) async {
    try {
      final bank = await getQuestionBankById(bankId);
      if (bank == null) {
        throw Exception('Ngân hàng câu hỏi không tồn tại');
      }
      
      final updatedBank = bank.removeQuestion(questionId);
      
      await _questionBanksCollection.doc(bankId).update({
        'questions': updatedBank.questions.map((q) => q.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error removing question from bank: $e');
      throw Exception('Không thể xóa câu hỏi khỏi ngân hàng: $e');
    }
  }

  // Xóa ngân hàng câu hỏi
  Future<void> deleteQuestionBank(String id) async {
    try {
      await _questionBanksCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting question bank: $e');
      throw Exception('Không thể xóa ngân hàng câu hỏi: $e');
    }
  }

  // ============= Exercise Attempt Methods =============

  // Tạo lần làm bài mới
  Future<ExerciseAttempt> createAttempt({
    required String userId,
    required String exerciseId,
    required String lessonId,
    required String classroomId,
  }) async {
    try {
      // Kiểm tra số lần làm và giới hạn
      final exercise = await getExerciseById(exerciseId);
      if (exercise == null) {
        throw Exception('Bài tập không tồn tại');
      }
      
      final attemptCount = await ExerciseAttempt.getAttemptCount(userId, exerciseId);
      if (attemptCount >= exercise.attemptsAllowed) {
        throw Exception('Bạn đã sử dụng hết số lần làm bài cho phép');
      }
      
      final attempt = await ExerciseAttempt.createAttempt(
        userId: userId,
        exerciseId: exerciseId,
        lessonId: lessonId,
        classroomId: classroomId,
      );
      
      if (attempt == null) {
        throw Exception('Không thể tạo lần làm bài mới');
      }
      
      return attempt;
    } catch (e) {
      print('Error creating attempt: $e');
      throw Exception('Không thể tạo lần làm bài mới: $e');
    }
  }

  // Cập nhật câu trả lời
  Future<void> updateAttemptAnswers(String attemptId, Map<String, dynamic> answers) async {
    try {
      final doc = await _attemptsCollection.doc(attemptId).get();
      if (!doc.exists) {
        throw Exception('Lần làm bài không tồn tại');
      }
      
      final attempt = ExerciseAttempt.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      final updatedAttempt = attempt.updateAnswers(answers);
      
      await _attemptsCollection.doc(attemptId).update({
        'answers': updatedAttempt.answers,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating attempt answers: $e');
      throw Exception('Không thể cập nhật câu trả lời: $e');
    }
  }

  // Nộp bài làm
  Future<ExerciseAttempt> submitAttempt(String attemptId) async {
    try {
      final doc = await _attemptsCollection.doc(attemptId).get();
      if (!doc.exists) {
        throw Exception('Lần làm bài không tồn tại');
      }
      
      final attempt = ExerciseAttempt.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      print('Submitting attempt: ${attempt.id} for exercise: ${attempt.exerciseId}');
      print('Answers: ${attempt.answers}');
      
      // Lấy thông tin bài tập
      final exercise = await getExerciseById(attempt.exerciseId);
      if (exercise == null) {
        throw Exception('Bài tập không tồn tại');
      }
      
      // Tính điểm từng câu hỏi
      Map<String, double> questionScores = {};
      double totalScore = 0.0;
      double totalPoints = 0.0;
      
      // Log thông tin chi tiết về câu hỏi và đáp án để debug
      print('Grading ${exercise.questions.length} questions');
      for (final question in exercise.questions) {
        print('Question ID: ${question.id}, content: ${question.content}');
        if (question.choices != null) {
          print('Choices for question ${question.id}:');
          for (var i = 0; i < question.choices!.length; i++) {
            final choice = question.choices![i];
            print('  Choice ${i}: ${choice.id}, content: ${choice.content}, isCorrect: ${choice.isCorrect}');
          }
        }
        
        totalPoints += question.points;
        final answer = attempt.answers[question.id];
        
        print('User answer for ${question.id}: $answer');
        
        if (answer != null) {
          double score = 0.0;
          
          // Trường hợp đặc biệt cho câu hỏi được lưu trong exercise_questions
          if (question.type == QuestionType.multipleChoice) {
            // Kiểm tra xem câu trả lời có phải là đáp án đúng không
            if (question.choices != null && question.choices!.isNotEmpty) {
              // Tìm đáp án đúng
              final correctChoices = question.choices!.where((c) => c.isCorrect).toList();
              
              if (correctChoices.isEmpty) {
                print('WARNING: No correct answer marked for question ${question.id}');
                score = 0.0;
              } else if (correctChoices.length > 1) {
                print('WARNING: Multiple correct answers marked for question ${question.id}');
                score = 0.0;
              } else {
                final correctChoice = correctChoices.first;
                print('Correct choice: ${correctChoice.id}, user answer: $answer');
                score = correctChoice.id == answer ? question.points : 0.0;
              }
            }
          } else {
            // Sử dụng logic chấm điểm mặc định cho các loại câu hỏi khác
            score = _gradeAnswer(question, answer);
          }
                
          print('Score for ${question.id}: $score out of ${question.points}');
          questionScores[question.id] = score;
          totalScore += score;
        } else {
          print('No answer for ${question.id}');
          questionScores[question.id] = 0.0;
        }
      }
      
      // Tính điểm phần trăm và kiểm tra đạt
      final double percentScore = totalPoints > 0.0 ? (totalScore / totalPoints) * 100.0 : 0.0;
      final bool passed = percentScore >= 70.0; // Default passing score
      
      print('Total score: $totalScore out of $totalPoints, percentage: $percentScore%, passed: $passed');
      
      // Hoàn thành attempt
      final completedAttempt = attempt.complete(
        score: percentScore,
        passed: passed,
        questionScores: questionScores,
      );
      
      await _attemptsCollection.doc(attemptId).update(completedAttempt.toMap());
      
      return completedAttempt;
    } catch (e, stackTrace) {
      print('Error submitting attempt: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Không thể nộp bài: $e');
    }
  }

  // Chấm điểm câu trả lời
  double _gradeAnswer(Question question, dynamic answer) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        if (answer is String) {
          final choice = question.choices?.firstWhere(
            (c) => c.id == answer,
            orElse: () => Choice(id: '', content: '', isCorrect: false),
          );
          return choice?.isCorrect == true ? question.points : 0.0;
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

          if (correctChoices.isEmpty) return 0.0;
          
          // Tính điểm cho từng lựa chọn đúng
          double correctCount = 0.0;
          for (final id in selectedChoices) {
            if (correctChoices.contains(id)) {
              correctCount += 1.0;
            } else {
              // Trừ điểm cho lựa chọn sai
              correctCount -= 0.5;
            }
          }
          
          // Đảm bảo điểm không âm
          correctCount = correctCount < 0.0 ? 0.0 : correctCount;
          
          // Tỷ lệ đúng
          final ratio = correctCount / correctChoices.length.toDouble();
          return ratio * question.points;
        }
        break;

      case QuestionType.fillInBlank:
      case QuestionType.shortAnswer:
        if (answer is String) {
          final acceptableAnswers = question.acceptableAnswers ?? [];
          final normalizedAnswer = question.caseSensitive
              ? answer.trim()
              : answer.toLowerCase().trim();
          final isCorrect = acceptableAnswers.any((a) {
            final normalizedAcceptable = question.caseSensitive
                ? a.trim()
                : a.toLowerCase().trim();
            return normalizedAcceptable == normalizedAnswer;
          });
          return isCorrect ? question.points : 0.0;
        }
        break;

      case QuestionType.matching:
        if (answer is Map<String, dynamic>) {
          final pairs = question.matchingPairs ?? [];
          double correctCount = 0.0;
          for (var pair in pairs) {
            if (answer[pair.id] == pair.response) {
              correctCount += 1.0;
            }
          }
          return (correctCount / pairs.length.toDouble()) * question.points;
        }
        break;

      case QuestionType.ordering:
        if (answer is List<String>) {
          final items = question.orderingItems ?? [];
          double correctCount = 0.0;
          for (var i = 0; i < items.length; i++) {
            if (i < answer.length && items[i].id == answer[i]) {
              correctCount += 1.0;
            }
          }
          return (correctCount / items.length.toDouble()) * question.points;
        }
        break;

      case QuestionType.essay:
        // Câu trả lời dài cần giáo viên chấm điểm
        return 0.0;
    }

    return 0.0;
  }

  // Chấm điểm thủ công (cho câu hỏi essay)
  Future<void> gradeEssayQuestion(String attemptId, String questionId, double score, String feedback) async {
    try {
      final doc = await _attemptsCollection.doc(attemptId).get();
      if (!doc.exists) {
        throw Exception('Lần làm bài không tồn tại');
      }
      
      final attempt = ExerciseAttempt.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      // Cập nhật điểm cho câu hỏi
      Map<String, double> updatedScores = Map.from(attempt.questionScores);
      updatedScores[questionId] = score;
      
      // Cập nhật feedback
      Map<String, dynamic> updatedFeedback = Map.from(attempt.feedback ?? {});
      updatedFeedback[questionId] = feedback;
      
      // Tính lại tổng điểm
      final exercise = await getExerciseById(attempt.exerciseId);
      if (exercise == null) {
        throw Exception('Bài tập không tồn tại');
      }
      
      double totalScore = 0.0;
      double totalPoints = 0.0;
      
      for (final question in exercise.questions) {
        totalPoints += question.points;
        totalScore += updatedScores[question.id] ?? 0.0;
      }
      
      final percentScore = totalPoints > 0.0 ? (totalScore / totalPoints) * 100.0 : 0.0;
      final passed = percentScore >= 70.0;
      
      await _attemptsCollection.doc(attemptId).update({
        'questionScores': updatedScores,
        'feedback': updatedFeedback,
        'score': percentScore,
        'passed': passed,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error grading essay question: $e');
      throw Exception('Không thể chấm điểm câu trả lời: $e');
    }
  }

  // Lấy các lần làm bài của một học sinh
  Future<List<ExerciseAttempt>> getAttemptsByUser(String userId, String exerciseId) async {
    try {
      return await ExerciseAttempt.getAttemptsByUser(userId, exerciseId);
    } catch (e) {
      print('Error getting attempts by user: $e');
      throw Exception('Không thể lấy danh sách lần làm bài: $e');
    }
  }

  // Lấy kết quả tốt nhất của một học sinh
  Future<ExerciseAttempt?> getBestAttempt(String userId, String exerciseId) async {
    try {
      return await ExerciseAttempt.getBestAttempt(userId, exerciseId);
    } catch (e) {
      print('Error getting best attempt: $e');
      throw Exception('Không thể lấy kết quả tốt nhất: $e');
    }
  }

  // Lấy kết quả của tất cả học sinh trong một lớp học
  Future<List<ExerciseAttempt>> getAttemptsByClassroom(String classroomId, String exerciseId) async {
    try {
      return await ExerciseAttempt.getAttemptsByClassroom(classroomId, exerciseId);
    } catch (e) {
      print('Error getting attempts by classroom: $e');
      throw Exception('Không thể lấy kết quả của lớp học: $e');
    }
  }

  // Từ bỏ lần làm bài
  Future<void> abandonAttempt(String attemptId) async {
    try {
      final doc = await _attemptsCollection.doc(attemptId).get();
      if (!doc.exists) {
        throw Exception('Lần làm bài không tồn tại');
      }
      
      final attempt = ExerciseAttempt.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      final abandonedAttempt = attempt.abandon();
      
      await _attemptsCollection.doc(attemptId).update(abandonedAttempt.toMap());
    } catch (e) {
      print('Error abandoning attempt: $e');
      throw Exception('Không thể từ bỏ lần làm bài: $e');
    }
  }

  // Cập nhật câu hỏi trong bài tập
  Future<void> updateQuestionInExercise(String exerciseId, Question updatedQuestion) async {
    try {
      print('Starting updateQuestionInExercise for exerciseId: $exerciseId, questionId: ${updatedQuestion.id}');
      print('Question content: ${updatedQuestion.content}');
      print('Question has ${updatedQuestion.choices?.length ?? 0} choices');
      
      if (updatedQuestion.choices != null) {
        for (int i = 0; i < updatedQuestion.choices!.length; i++) {
          print('Choice $i: ${updatedQuestion.choices![i].content}, isCorrect: ${updatedQuestion.choices![i].isCorrect}');
        }
      }
      
      // Tìm document của bài tập
      final exerciseDoc = await _exercisesCollection.doc(exerciseId).get();
      if (!exerciseDoc.exists) {
        print('Error: Exercise with ID $exerciseId not found');
        throw Exception('Không tìm thấy bài tập với ID: $exerciseId');
      }
      
      // Tìm document của câu hỏi
      final querySnapshot = await _firestore.collection('exercise_questions')
          .where('exerciseId', isEqualTo: exerciseId)
          .get();
      
      print('Found ${querySnapshot.docs.length} questions for exercise');
      
      // Tìm câu hỏi cần cập nhật
      DocumentReference? questionDocRef;
      int orderIndex = 0;
      
      for (var doc in querySnapshot.docs) {
        final questionData = doc.data();
        print('Checking question ${doc.id}: ${questionData['questionText']}');
        
        // Tìm theo ID hoặc nội dung câu hỏi
        if (doc.id == updatedQuestion.id || questionData['questionText'] == updatedQuestion.content) {
          questionDocRef = doc.reference;
          orderIndex = questionData['orderIndex'] ?? 0;
          print('Found matching question with id: ${doc.id}, orderIndex: $orderIndex');
          break;
        }
      }
      
      if (questionDocRef == null) {
        print('Question not found, creating new question with ID: ${updatedQuestion.id}');
        // Không tìm thấy câu hỏi, tạo mới
        questionDocRef = _firestore.collection('exercise_questions').doc(updatedQuestion.id);
        orderIndex = querySnapshot.docs.length; // Add at the end
      }
      
      // Chuẩn bị dữ liệu câu hỏi
      final questionData = {
        'exerciseId': exerciseId,
        'orderIndex': orderIndex,
        'questionText': updatedQuestion.content,
        'type': updatedQuestion.type.toString(),
        'points': updatedQuestion.points,
        'explanation': updatedQuestion.explanation ?? '',
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      // Xử lý các lựa chọn
      if (updatedQuestion.choices != null && updatedQuestion.choices!.isNotEmpty) {
        final List<String> options = [];
        final List<Map<String, dynamic>> choicesData = [];
        int correctOptionIndex = -1;
        
        for (int i = 0; i < updatedQuestion.choices!.length; i++) {
          final choice = updatedQuestion.choices![i];
          options.add(choice.content);
          
          choicesData.add({
            'content': choice.content,
            'isCorrect': choice.isCorrect,
            'id': choice.id,
          });
          
          if (choice.isCorrect) {
            correctOptionIndex = i;
          }
        }
        
        questionData['options'] = options;
        questionData['choicesData'] = choicesData;
        questionData['correctOptionIndex'] = correctOptionIndex >= 0 ? correctOptionIndex : 0;
      }
      
      print('Updating question document with data: $questionData');
      await questionDocRef.set(questionData, SetOptions(merge: true));
      print('Question updated successfully with ID: ${questionDocRef.id}');
      
      // Directly update the exercise's questions array for immediate changes
      final Exercise? exercise = await getExerciseById(exerciseId, forceRefresh: true);
      print('Exercise reloaded: ${exercise?.title}, has ${exercise?.questions.length ?? 0} questions');
      
      return;
    } catch (e) {
      print('Error updating question: $e');
      throw Exception('Không thể cập nhật câu hỏi: $e');
    }
  }

  // Lấy tất cả attempts của một bài tập
  Future<List<ExerciseAttempt>> getAttemptsByExercise(String exerciseId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('exercise_attempts')
          .where('exerciseId', isEqualTo: exerciseId)
          .orderBy('startTime', descending: true)
          .get();
          
      return snapshot.docs
          .map((doc) => ExerciseAttempt.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting attempts by exercise: $e');
      return [];
    }
  }
} 