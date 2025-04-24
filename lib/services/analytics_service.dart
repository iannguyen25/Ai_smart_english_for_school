import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/classroom.dart';
import '../models/lesson.dart';
import '../models/app_user.dart';
import '../models/quiz_attempt.dart';
import '../models/exercise_attempt.dart';
import '../models/feedback.dart' as app_models;
import 'lesson_service.dart';
import 'user_service.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LessonService _lessonService = LessonService();
  final UserService _userService = UserService();
  
  // ======== TEACHER ANALYTICS ========
  
  // Tính phần trăm hoàn thành bài học của lớp
  Future<double> getClassCompletionRate(String classroomId) async {
    try {
      // Lấy danh sách học sinh trong lớp
      final classroom = await _firestore.collection('classrooms').doc(classroomId).get();
      if (!classroom.exists) return 0;
      
      final classData = classroom.data() as Map<String, dynamic>;
      final List<dynamic> memberIds = classData['memberIds'] ?? [];
      
      if (memberIds.isEmpty) return 0;
      
      // Lấy danh sách bài học của lớp
      final lessons = await _lessonService.getLessonsByClassroom(classroomId);
      if (lessons.isEmpty) return 0;
      
      double totalCompletionRate = 0;
      
      // Tính tỷ lệ hoàn thành cho mỗi học sinh
      for (String memberId in memberIds) {
        int completedLessons = 0;
        
        for (Lesson lesson in lessons) {
          // Kiểm tra xem học sinh đã hoàn thành bài học chưa
          final progress = await _firestore
              .collection('learning_progress')
              .where('userId', isEqualTo: memberId)
              .where('lessonId', isEqualTo: lesson.id)
              .where('completed', isEqualTo: true)
              .get();
          
          if (progress.docs.isNotEmpty) {
            completedLessons++;
          }
        }
        
        // Tính tỷ lệ hoàn thành của học sinh
        final studentCompletionRate = lessons.isNotEmpty 
            ? completedLessons / lessons.length 
            : 0;
        
        totalCompletionRate += studentCompletionRate;
      }
      
      // Tính trung bình tỷ lệ hoàn thành của cả lớp
      return totalCompletionRate / memberIds.length;
    } catch (e) {
      print('Error getting class completion rate: $e');
      return 0;
    }
  }
  
  // Lấy tiến độ học tập của từng học sinh trong lớp
  Future<List<Map<String, dynamic>>> getStudentProgressInClass(String classroomId) async {
    try {
      // Lấy danh sách học sinh trong lớp
      final classroom = await _firestore.collection('classrooms').doc(classroomId).get();
      if (!classroom.exists) return [];
      
      final classData = classroom.data() as Map<String, dynamic>;
      final List<dynamic> memberIds = classData['memberIds'] ?? [];
      
      if (memberIds.isEmpty) return [];
      
      // Lấy danh sách bài học của lớp
      final lessons = await _lessonService.getLessonsByClassroom(classroomId);
      if (lessons.isEmpty) return [];
      
      List<Map<String, dynamic>> studentsProgress = [];
      
      // Lấy thông tin tiến độ cho mỗi học sinh
      for (String memberId in memberIds) {
        final user = await _userService.getUserById(memberId);
        if (user == null) continue;
        
        List<Map<String, dynamic>> lessonStatus = [];
        int completedLessons = 0;
        
        // Kiểm tra trạng thái từng bài học
        for (Lesson lesson in lessons) {
          final progress = await _firestore
              .collection('learning_progress')
              .where('userId', isEqualTo: memberId)
              .where('lessonId', isEqualTo: lesson.id)
              .get();
          
          bool isCompleted = false;
          int minutesSpent = 0;
          
          if (progress.docs.isNotEmpty) {
            final progressData = progress.docs.first.data();
            isCompleted = progressData['completed'] ?? false;
            minutesSpent = progressData['minutesSpent'] ?? 0;
            
            if (isCompleted) {
              completedLessons++;
            }
          }
          
          lessonStatus.add({
            'lessonId': lesson.id,
            'lessonTitle': lesson.title,
            'isCompleted': isCompleted,
            'minutesSpent': minutesSpent,
          });
        }
        
        // Tính tỷ lệ hoàn thành
        final completionRate = lessons.isNotEmpty 
            ? completedLessons / lessons.length 
            : 0;
        
        studentsProgress.add({
          'userId': memberId,
          'name': user.fullName,
          'email': user.email,
          'photoUrl': user.avatar,
          'completedLessons': completedLessons,
          'totalLessons': lessons.length,
          'completionRate': completionRate,
          'lessonStatus': lessonStatus,
        });
      }
      
      // Sắp xếp theo tỷ lệ hoàn thành giảm dần
      studentsProgress.sort((a, b) => 
          (b['completionRate'] as double).compareTo(a['completionRate'] as double));
      
      return studentsProgress;
    } catch (e) {
      print('Error getting student progress: $e');
      return [];
    }
  }
  
  // Lấy thống kê bài kiểm tra của lớp
  Future<Map<String, dynamic>> getClassTestStatistics(String classroomId) async {
    try {
      // Lấy danh sách học sinh trong lớp
      final classroom = await _firestore.collection('classrooms').doc(classroomId).get();
      if (!classroom.exists) return {};
      
      final classData = classroom.data() as Map<String, dynamic>;
      final List<dynamic> memberIds = classData['memberIds'] ?? [];
      
      if (memberIds.isEmpty) return {};
      
      // Lấy danh sách bài học của lớp
      final lessons = await _lessonService.getLessonsByClassroom(classroomId);
      if (lessons.isEmpty) return {};
      
      // Thống kê cho từng bài học
      List<Map<String, dynamic>> lessonStats = [];
      
      for (Lesson lesson in lessons) {
        // Lấy danh sách bài kiểm tra của bài học
        final quizzes = await _firestore
            .collection('quizzes')
            .where('lessonId', isEqualTo: lesson.id)
            .get();
        
        for (var quiz in quizzes.docs) {
          final quizId = quiz.id;
          final quizData = quiz.data();
          final quizTitle = quizData['title'] ?? 'Bài kiểm tra';
          
          // Đếm số học sinh đã làm bài kiểm tra
          int studentsSubmitted = 0;
          double totalScore = 0;
          
          // Kiểm tra từng học sinh
          for (String memberId in memberIds) {
            final attempts = await _firestore
                .collection('quiz_attempts')
                .where('userId', isEqualTo: memberId)
                .where('quizId', isEqualTo: quizId)
                .where('status', isEqualTo: 'completed')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .get();
            
            if (attempts.docs.isNotEmpty) {
              studentsSubmitted++;
              totalScore += attempts.docs.first.data()['score'] ?? 0;
            }
          }
          
          // Tính điểm trung bình
          final averageScore = studentsSubmitted > 0 
              ? totalScore / studentsSubmitted 
              : 0;
          
          lessonStats.add({
            'lessonId': lesson.id,
            'lessonTitle': lesson.title,
            'quizId': quizId,
            'quizTitle': quizTitle,
            'studentsSubmitted': studentsSubmitted,
            'totalStudents': memberIds.length,
            'submissionRate': memberIds.isNotEmpty 
                ? studentsSubmitted / memberIds.length 
                : 0,
            'averageScore': averageScore,
          });
        }
      }
      
      // Tìm học sinh nổi bật và học sinh yếu
      List<Map<String, dynamic>> outstandingStudents = [];
      List<Map<String, dynamic>> strugglingStudents = [];
      
      for (String memberId in memberIds) {
        final user = await _userService.getUserById(memberId);
        if (user == null) continue;
        
        int completedLessons = 0;
        double totalTestScore = 0;
        int totalTests = 0;
        
        // Kiểm tra tiến độ bài học
        for (Lesson lesson in lessons) {
          final progress = await _firestore
              .collection('learning_progress')
              .where('userId', isEqualTo: memberId)
              .where('lessonId', isEqualTo: lesson.id)
              .where('completed', isEqualTo: true)
              .get();
          
          if (progress.docs.isNotEmpty) {
            completedLessons++;
          }
          
          // Kiểm tra điểm bài kiểm tra
          final quizzes = await _firestore
              .collection('quizzes')
              .where('lessonId', isEqualTo: lesson.id)
              .get();
          
          for (var quiz in quizzes.docs) {
            final attempts = await _firestore
                .collection('quiz_attempts')
                .where('userId', isEqualTo: memberId)
                .where('quizId', isEqualTo: quiz.id)
                .where('status', isEqualTo: 'completed')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .get();
            
            if (attempts.docs.isNotEmpty) {
              totalTests++;
              totalTestScore += attempts.docs.first.data()['score'] ?? 0;
            }
          }
        }
        
        // Tính điểm trung bình
        final averageScore = totalTests > 0 
            ? totalTestScore / totalTests 
            : 0;
        
        // Tính tỷ lệ hoàn thành
        final completionRate = lessons.isNotEmpty 
            ? completedLessons / lessons.length 
            : 0;
        
        // Xác định học sinh nổi bật (điểm cao và hoàn thành nhiều)
        if (averageScore >= 8.0 && completionRate >= 0.7) {
          outstandingStudents.add({
            'userId': memberId,
            'name': user.fullName,
            'email': user.email,
            'photoUrl': user.avatar,
            'completionRate': completionRate,
            'averageScore': averageScore,
          });
        }
        
        // Xác định học sinh yếu (điểm thấp hoặc hoàn thành ít)
        if (averageScore < 5.0 || completionRate < 0.3) {
          strugglingStudents.add({
            'userId': memberId,
            'name': user.fullName,
            'email': user.email,
            'photoUrl': user.avatar,
            'completionRate': completionRate,
            'averageScore': averageScore,
            'reason': averageScore < 5.0 ? 'Điểm thấp' : 'Tiến độ chậm',
          });
        }
      }
      
      // Sắp xếp học sinh nổi bật theo điểm trung bình giảm dần
      outstandingStudents.sort((a, b) => 
          (b['averageScore'] as double).compareTo(a['averageScore'] as double));
      
      // Sắp xếp học sinh yếu theo điểm trung bình tăng dần
      strugglingStudents.sort((a, b) => 
          (a['averageScore'] as double).compareTo(b['averageScore'] as double));
      
      return {
        'lessonStats': lessonStats,
        'outstandingStudents': outstandingStudents.take(5).toList(), // Top 5
        'strugglingStudents': strugglingStudents.take(5).toList(), // Top 5 cần hỗ trợ
      };
    } catch (e) {
      print('Error getting class test statistics: $e');
      return {};
    }
  }
  
  // Lấy thông tin chi tiết về một học sinh
  Future<Map<String, dynamic>> getStudentDetailedProgress(String classroomId, String studentId) async {
    try {
      final user = await _userService.getUserById(studentId);
      if (user == null) return {};
      
      // Lấy danh sách bài học của lớp
      final lessons = await _lessonService.getLessonsByClassroom(classroomId);
      if (lessons.isEmpty) return {};
      
      // Đếm số bài đã học
      int completedLessons = 0;
      List<Map<String, dynamic>> lessonProgress = [];
      
      for (Lesson lesson in lessons) {
        final progress = await _firestore
            .collection('learning_progress')
            .where('userId', isEqualTo: studentId)
            .where('lessonId', isEqualTo: lesson.id)
            .get();
        
        bool isCompleted = false;
        int minutesSpent = 0;
        DateTime? lastAccessed;
        
        if (progress.docs.isNotEmpty) {
          final progressData = progress.docs.first.data();
          isCompleted = progressData['completed'] ?? false;
          minutesSpent = progressData['minutesSpent'] ?? 0;
          lastAccessed = progressData['updatedAt'] != null 
              ? (progressData['updatedAt'] as Timestamp).toDate() 
              : null;
          
          if (isCompleted) {
            completedLessons++;
          }
        }
        
        lessonProgress.add({
          'lessonId': lesson.id,
          'lessonTitle': lesson.title,
          'isCompleted': isCompleted,
          'minutesSpent': minutesSpent,
          'lastAccessed': lastAccessed,
        });
      }
      
      // Lấy thông tin huy hiệu đã đạt
      final badges = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: studentId)
          .get();
      
      List<Map<String, dynamic>> earnedBadges = [];
      
      for (var badge in badges.docs) {
        final badgeData = badge.data();
        earnedBadges.add({
          'badgeId': badge.id,
          'name': badgeData['name'] ?? 'Huy hiệu',
          'description': badgeData['description'] ?? '',
          'imageUrl': badgeData['imageUrl'] ?? '',
          'earnedAt': badgeData['earnedAt'] != null 
              ? (badgeData['earnedAt'] as Timestamp).toDate() 
              : null,
        });
      }
      
      // Lấy thông tin streak
      final streakDoc = await _firestore
          .collection('user_streaks')
          .doc(studentId)
          .get();
      
      int currentStreak = 0;
      int longestStreak = 0;
      
      if (streakDoc.exists) {
        final streakData = streakDoc.data() as Map<String, dynamic>;
        currentStreak = streakData['currentStreak'] ?? 0;
        longestStreak = streakData['longestStreak'] ?? 0;
      }
      
      // Lấy thống kê bài kiểm tra
      List<Map<String, dynamic>> testStatistics = [];
      int totalTests = 0;
      int completedTests = 0;
      double totalScore = 0;
      
      for (Lesson lesson in lessons) {
        final quizzes = await _firestore
            .collection('quizzes')
            .where('lessonId', isEqualTo: lesson.id)
            .get();
        
        for (var quiz in quizzes.docs) {
          final quizId = quiz.id;
          final quizData = quiz.data();
          final quizTitle = quizData['title'] ?? 'Bài kiểm tra';
          
          totalTests++;
          
          final attempts = await _firestore
              .collection('quiz_attempts')
              .where('userId', isEqualTo: studentId)
              .where('quizId', isEqualTo: quizId)
              .where('status', isEqualTo: 'completed')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
          
          if (attempts.docs.isNotEmpty) {
            completedTests++;
            final attemptData = attempts.docs.first.data();
            final score = attemptData['score'] ?? 0;
            totalScore += score;
            
            testStatistics.add({
              'quizId': quizId,
              'quizTitle': quizTitle,
              'lessonId': lesson.id,
              'lessonTitle': lesson.title,
              'score': score,
              'passed': attemptData['passed'] ?? false,
              'attemptedAt': attemptData['createdAt'] != null 
                  ? (attemptData['createdAt'] as Timestamp).toDate() 
                  : null,
            });
          }
        }
      }
      
      // Sắp xếp theo thời gian làm bài mới nhất
      testStatistics.sort((a, b) {
        final dateA = a['attemptedAt'] as DateTime?;
        final dateB = b['attemptedAt'] as DateTime?;
        
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        
        return dateB.compareTo(dateA);
      });
      
      return {
        'userId': studentId,
        'name': user.fullName,
        'email': user.email,
        'photoUrl': user.avatar,
        'joinedAt': user.createdAt,
        'completedLessons': completedLessons,
        'totalLessons': lessons.length,
        'completionRate': lessons.isNotEmpty ? completedLessons / lessons.length : 0,
        'lessonProgress': lessonProgress,
        'earnedBadges': earnedBadges,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'testStatistics': {
          'totalTests': totalTests,
          'completedTests': completedTests,
          'completionRate': totalTests > 0 ? completedTests / totalTests : 0,
          'averageScore': completedTests > 0 ? totalScore / completedTests : 0,
          'tests': testStatistics,
        },
      };
    } catch (e) {
      print('Error getting student detailed progress: $e');
      return {};
    }
  }
  
  // ======== ADMIN ANALYTICS ========
  
  // Lấy tổng quan hệ thống
  Future<Map<String, dynamic>> getSystemOverview({int days = 30}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      final startTimestamp = Timestamp.fromDate(startDate);

      List<Map<String, dynamic>> pendingContent = [];

      // Lấy danh sách bài học chờ duyệt
      final pendingLessons = await _firestore
          .collection('lessons')
          .where('approvalStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      for (var doc in pendingLessons.docs) {
        final data = doc.data();
        final authorId = data['authorId'] ?? '';
        String authorName = 'Không xác định';

        if (authorId.isNotEmpty) {
          final authorDoc = await _firestore.collection('users').doc(authorId).get();
          if (authorDoc.exists) {
            final authorData = authorDoc.data() as Map<String, dynamic>;
            authorName = '${authorData['firstName'] ?? ''} ${authorData['lastName'] ?? ''}'.trim();
          }
        }

        pendingContent.add({
          'id': doc.id,
          'title': data['title'] ?? 'Không có tiêu đề',
          'type': 'lesson',
          'authorId': authorId,
          'authorName': authorName,
          'createdAt': data['createdAt'],
          'description': data['description'] ?? '',
        });
      }

      // Lấy danh sách flashcard chờ duyệt
      final pendingFlashcards = await _firestore
          .collection('flashcards')
          .where('approvalStatus', isEqualTo: 'pending')
          .get();

      for (var doc in pendingFlashcards.docs) {
        final data = doc.data();
        final authorId = data['userId'] ?? '';
        String authorName = 'Không xác định';

        if (authorId.isNotEmpty) {
          final authorDoc = await _firestore.collection('users').doc(authorId).get();
          if (authorDoc.exists) {
            final authorData = authorDoc.data() as Map<String, dynamic>;
            authorName = '${authorData['firstName'] ?? ''} ${authorData['lastName'] ?? ''}'.trim();
          }
        }

        pendingContent.add({
          'id': doc.id,
          'title': data['title'] ?? 'Không có tiêu đề',
          'type': 'flashcard',
          'authorId': authorId,
          'authorName': authorName,
          'createdAt': data['createdAt'],
          'description': data['description'] ?? '',
        });
      }

      // Lấy thống kê người dùng hoạt động
      final activeUsers = await _firestore
          .collection('user_activities')
          .where('lastActiveAt', isGreaterThan: startTimestamp)
          .get();

      // Lấy top lớp học tích cực
      final classroomsSnapshot = await _firestore
          .collection('classrooms')
          .orderBy('updatedAt', descending: true)
          .limit(5)
          .get();

      List<Map<String, dynamic>> topClassrooms = [];
      for (var doc in classroomsSnapshot.docs) {
        final data = doc.data();
        final teacherId = data['teacherId'] ?? '';
        String teacherName = 'Không xác định';

        if (teacherId.isNotEmpty) {
          final teacherDoc = await _firestore.collection('users').doc(teacherId).get();
          if (teacherDoc.exists) {
            final teacherData = teacherDoc.data() as Map<String, dynamic>;
            teacherName = '${teacherData['firstName'] ?? ''} ${teacherData['lastName'] ?? ''}'.trim();
          }
        }

        topClassrooms.add({
          'id': doc.id,
          'className': data['name'] ?? 'Không có tên',
          'teacherId': teacherId,
          'teacherName': teacherName,
          'memberCount': (data['memberIds'] as List?)?.length ?? 0,
          'activities': data['activityCount'] ?? 0,
        });
      }

      return {
        'activeUsers': activeUsers.docs.length,
        'pendingContent': pendingContent,
        'topActiveClassrooms': topClassrooms,
      };
    } catch (e) {
      print('Error getting system overview: $e');
      throw e.toString();
    }
  }
  
  // Lấy báo cáo tài nguyên học tập
  Future<Map<String, dynamic>> getLearningResourcesReport({int days = 30}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      final startTimestamp = Timestamp.fromDate(startDate);
      
      // Tổng số bài học
      final totalLessonsSnapshot = await _firestore
          .collection('lessons')
          .count()
          .get();
      
      final totalLessons = totalLessonsSnapshot.count;
      
      // Bài học mới trong khoảng thời gian
      final newLessonsSnapshot = await _firestore
          .collection('lessons')
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .count()
          .get();
      
      final newLessons = newLessonsSnapshot.count;
      
      // Tổng số flashcard
      final totalFlashcardsSnapshot = await _firestore
          .collection('flashcards')
          .count()
          .get();
      
      final totalFlashcards = totalFlashcardsSnapshot.count;
      
      // Flashcard mới trong khoảng thời gian
      final newFlashcardsSnapshot = await _firestore
          .collection('flashcards')
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .count()
          .get();
      
      final newFlashcards = newFlashcardsSnapshot.count;
      
      // Tổng số bài tập
      final totalExercisesSnapshot = await _firestore
          .collection('exercises')
          .count()
          .get();
      
      final totalExercises = totalExercisesSnapshot.count;
      
      // Bài tập mới trong khoảng thời gian
      final newExercisesSnapshot = await _firestore
          .collection('exercises')
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .count()
          .get();
      
      final newExercises = newExercisesSnapshot.count;
      
      // Tổng số bài kiểm tra
      final totalQuizzesSnapshot = await _firestore
          .collection('quizzes')
          .count()
          .get();
      
      final totalQuizzes = totalQuizzesSnapshot.count;
      
      // Bài kiểm tra mới trong khoảng thời gian
      final newQuizzesSnapshot = await _firestore
          .collection('quizzes')
          .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
          .count()
          .get();
      
      final newQuizzes = newQuizzesSnapshot.count;
      
      // Tìm bài học có vấn đề (nhiều báo lỗi)
      final problemLessons = await _firestore
          .collection('feedbacks')
          .where('type', isEqualTo: 'report')
          .get();
      
      // Đếm số báo cáo lỗi cho mỗi bài học
      Map<String, int> lessonReportCounts = {};
      Map<String, String> lessonTitles = {};
      
      for (var feedback in problemLessons.docs) {
        final data = feedback.data();
        final lessonId = data['lessonId'];
        
        if (lessonId != null) {
          lessonReportCounts[lessonId] = (lessonReportCounts[lessonId] ?? 0) + 1;
          
          // Lấy tiêu đề bài học nếu chưa có
          if (!lessonTitles.containsKey(lessonId)) {
            final lessonDoc = await _firestore.collection('lessons').doc(lessonId).get();
            if (lessonDoc.exists) {
              lessonTitles[lessonId] = lessonDoc.data()?['title'] ?? 'Bài học';
            } else {
              lessonTitles[lessonId] = 'Bài học không xác định';
            }
          }
        }
      }
      
      // Chuyển đổi thành danh sách và sắp xếp theo số báo cáo giảm dần
      List<Map<String, dynamic>> problematicLessons = lessonReportCounts.entries
          .where((entry) => entry.value >= 2) // Chỉ lấy bài học có từ 2 báo cáo trở lên
          .map((entry) => {
            'lessonId': entry.key,
            'lessonTitle': lessonTitles[entry.key] ?? 'Bài học',
            'reportCount': entry.value,
          })
          .toList();
      
      problematicLessons.sort((a, b) => 
          (b['reportCount'] as int).compareTo(a['reportCount'] as int));
      
      return {
        'totalLessons': totalLessons,
        'newLessons': newLessons,
        'totalFlashcards': totalFlashcards,
        'newFlashcards': newFlashcards,
        'totalExercises': totalExercises,
        'newExercises': newExercises,
        'totalQuizzes': totalQuizzes,
        'newQuizzes': newQuizzes,
        'problematicLessons': problematicLessons.take(10).toList(), // Top 10 bài học có vấn đề
        'periodDays': days,
      };
    } catch (e) {
      print('Error getting learning resources report: $e');
      return {};
    }
  }

  // ======== CONTENT MODERATION ========
  
  // Duyệt nội dung
  Future<void> approveContent(String contentId) async {
    try {
      // Kiểm tra xem đây là bài học hay flashcard
      bool isLesson = false;
      bool isFlashcard = false;
      Map<String, dynamic>? contentData;
      String contentType = "";
      String authorIdField = "";
      
      // Kiểm tra lesson
      final lessonDoc = await _firestore.collection('lessons').doc(contentId).get();
      if (lessonDoc.exists) {
        isLesson = true;
        contentData = lessonDoc.data();
        contentType = "lesson";
        authorIdField = "authorId";
      } else {
        // Kiểm tra flashcard
        final flashcardDoc = await _firestore.collection('flashcards').doc(contentId).get();
        if (flashcardDoc.exists) {
          isFlashcard = true;
          contentData = flashcardDoc.data();
          contentType = "flashcard";
          authorIdField = "userId";
        }
      }
      
      if (!isLesson && !isFlashcard) {
        throw 'Không tìm thấy nội dung';
      }

      // Cập nhật trạng thái thành approved
      await _firestore.collection(isLesson ? 'lessons' : 'flashcards').doc(contentId).update({
        'approvalStatus': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      
      // Thông báo cho người tạo
      await _firestore.collection('notifications').add({
        'userId': contentData![authorIdField],
        'title': 'Nội dung đã được duyệt',
        'message': 'Nội dung "${contentData['title']}" của bạn đã được phê duyệt',
        'type': 'content_approved',
        'contentId': contentId,
        'contentType': contentType,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error approving content: $e');
      throw e.toString();
    }
  }

  // Từ chối nội dung
  Future<void> rejectContent(String contentId) async {
    try {
      // Kiểm tra xem đây là bài học hay flashcard
      bool isLesson = false;
      bool isFlashcard = false;
      Map<String, dynamic>? contentData;
      String contentType = "";
      String authorIdField = "";
      
      // Kiểm tra lesson
      final lessonDoc = await _firestore.collection('lessons').doc(contentId).get();
      if (lessonDoc.exists) {
        isLesson = true;
        contentData = lessonDoc.data();
        contentType = "lesson";
        authorIdField = "authorId";
      } else {
        // Kiểm tra flashcard
        final flashcardDoc = await _firestore.collection('flashcards').doc(contentId).get();
        if (flashcardDoc.exists) {
          isFlashcard = true;
          contentData = flashcardDoc.data();
          contentType = "flashcard";
          authorIdField = "userId";
        }
      }
      
      if (!isLesson && !isFlashcard) {
        throw 'Không tìm thấy nội dung';
      }

      // Cập nhật trạng thái thành rejected
      await _firestore.collection(isLesson ? 'lessons' : 'flashcards').doc(contentId).update({
        'approvalStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      
      // Thông báo cho người tạo
      await _firestore.collection('notifications').add({
        'userId': contentData![authorIdField],
        'title': 'Nội dung bị từ chối',
        'message': 'Nội dung "${contentData['title']}" của bạn đã bị từ chối',
        'type': 'content_rejected',
        'contentId': contentId,
        'contentType': contentType,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error rejecting content: $e');
      throw e.toString();
    }
  }
} 