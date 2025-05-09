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
  
  // Cache for completion rates
  final Map<String, double> _completionRateCache = {};
  final Duration _cacheDuration = Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // ======== TEACHER ANALYTICS ========
  
  // Tính phần trăm hoàn thành bài học của lớp
  Future<double> getClassCompletionRate(String classroomId) async {
    try {
      // Check cache first
      if (_completionRateCache.containsKey(classroomId)) {
        final cacheTime = _cacheTimestamps[classroomId];
        if (cacheTime != null && 
            DateTime.now().difference(cacheTime) < _cacheDuration) {
          return _completionRateCache[classroomId]!;
        }
      }

      final classroom = await _firestore.collection('classrooms').doc(classroomId).get();
      if (!classroom.exists) return 0;
      
      final classData = classroom.data() as Map<String, dynamic>;
      final List<dynamic> memberIds = classData['memberIds'] ?? [];
      
      if (memberIds.isEmpty) return 0;
      final lessons = await _lessonService.getLessonsByClassroom(classroomId);
      if (lessons.isEmpty) return 0;
      
      double totalCompletionRate = 0;
      
      for (String memberId in memberIds) {
        int completedLessons = 0;
        
        for (Lesson lesson in lessons) {
          final progress = await _firestore
              .collection('learning_progress')
              .where('userId', isEqualTo: memberId)
              .where('lessonId', isEqualTo: lesson.id)
              .where('classroomId', isEqualTo: classroomId)
              .get();
          
          if (progress.docs.isNotEmpty) {
            final progressData = progress.docs.first.data();
            
            // Check completion based on multiple criteria
            final status = progressData['status'] as String?;
            final progressPercent = progressData['progressPercent'] as num?;
            final completedItems = progressData['completedItems'] as int?;
            final totalItems = progressData['totalItems'] as int?;
            final completedItemIds = progressData['completedItemIds'] as Map<String, dynamic>?;
            
            bool isCompleted = false;
            
            // Check status
            if (status == 'completed') {
              isCompleted = true;
            }
            // Check progress percent
            else if (progressPercent != null && progressPercent >= 100) {
              isCompleted = true;
            }
            // Check completed items
            else if (completedItems != null && totalItems != null && 
                     completedItems > 0 && completedItems >= totalItems) {
              isCompleted = true;
            }
            // Check completedItemIds
            else if (completedItemIds != null && completedItemIds.isNotEmpty &&
                     completedItemIds.values.every((v) => v == true)) {
              isCompleted = true;
            }
            
            if (isCompleted) {
              completedLessons++;
            }
          }
        }
        
        final studentCompletionRate = lessons.isNotEmpty 
            ? completedLessons / lessons.length 
            : 0;
        
        totalCompletionRate += studentCompletionRate;
      }
      
      final classCompletionRate = totalCompletionRate / memberIds.length;

      // Update cache
      _completionRateCache[classroomId] = classCompletionRate;
      _cacheTimestamps[classroomId] = DateTime.now();

      return classCompletionRate;
    } catch (e) {
      return 0;
    }
  }
  
  // Lấy tiến độ học tập của học sinh trong lớp
  Future<Map<String, dynamic>> getStudentProgressInClass(String classroomId, String studentId) async {
    try {
      final lessons = await _lessonService.getLessonsByClassroom(classroomId);
      
      if (lessons.isEmpty) {
        return {
          'id': studentId,
          'name': 'Unknown',
          'progress': 0.0,
          'totalLessons': 0,
          'completedLessons': 0,
          'lastAccessed': null
        };
      }

      int completedLessons = 0;
      DateTime? lastAccessed;
      
      for (Lesson lesson in lessons) {
        final progress = await _firestore
            .collection('learning_progress')
            .where('userId', isEqualTo: studentId)
            .where('lessonId', isEqualTo: lesson.id)
            .where('classroomId', isEqualTo: classroomId)
            .get();
        
        if (progress.docs.isNotEmpty) {
          final progressData = progress.docs.first.data();
          
          // Check completion based on multiple criteria
          final status = progressData['status'] as String?;
          final progressPercent = progressData['progressPercent'] as num?;
          final completedItems = progressData['completedItems'] as int?;
          final totalItems = progressData['totalItems'] as int?;
          final completedItemIds = progressData['completedItemIds'] as Map<String, dynamic>?;
          
          bool isCompleted = false;
          
          // Check status
          if (status == 'completed') {
            isCompleted = true;
          }
          // Check progress percent
          else if (progressPercent != null && progressPercent >= 100) {
            isCompleted = true;
          }
          // Check completed items
          else if (completedItems != null && totalItems != null && 
                   completedItems > 0 && completedItems >= totalItems) {
            isCompleted = true;
          }
          // Check completedItemIds
          else if (completedItemIds != null && completedItemIds.isNotEmpty &&
                   completedItemIds.values.every((v) => v == true)) {
            isCompleted = true;
          }
          
          if (isCompleted) {
            completedLessons++;
          }

          // Update lastAccessed if this entry is more recent
          if (progressData['lastAccessTime'] != null) {
            final progressLastAccessed = (progressData['lastAccessTime'] as Timestamp).toDate();
            if (lastAccessed == null || progressLastAccessed.isAfter(lastAccessed)) {
              lastAccessed = progressLastAccessed;
            }
          }
        }
      }
      
      final completionRate = lessons.isNotEmpty ? completedLessons / lessons.length : 0.0;
      
      // Get user info
      final user = await _userService.getUserById(studentId);
      
      return {
        'id': studentId,
        'name': user?.fullName ?? 'Unknown',
        'progress': completionRate,
        'totalLessons': lessons.length,
        'completedLessons': completedLessons,
        'lastAccessed': lastAccessed
      };
    } catch (e) {
      return {
        'id': studentId,
        'name': 'Error',
        'progress': 0.0,
        'totalLessons': 0,
        'completedLessons': 0,
        'lastAccessed': null
      };
    }
  }
  
  // Lấy thống kê bài kiểm tra của lớp
  Future<Map<String, dynamic>?> getClassTestStatistics(String classroomId) async {
    try {
      // Get classroom data
      final classroomDoc = await _firestore.collection('classrooms').doc(classroomId).get();
      if (!classroomDoc.exists) {
        return null;
      }
      
      // Get approved lessons
      final lessonsQuery = await _firestore.collection('lessons')
          .where('approved', isEqualTo: true)
          .get();
      
      final lessons = lessonsQuery.docs.map((doc) => {
        'id': doc.id,
        'title': doc.data()['title'] ?? 'Bài học',
        'quizId': doc.data()['quizId'],
      }).toList();
      
      // Get all members of the classroom
      final memberIds = List<String>.from(classroomDoc.data()?['memberIds'] ?? []);
      
      // Calculate stats for each lesson
      final lessonStats = <Map<String, dynamic>>[];
      
      for (final lesson in lessons) {
        int completedCount = 0;
        int attemptedCount = 0;
        double totalScore = 0;
        int quizAttempts = 0;
        final String lessonId = lesson['id'];
        
        for (final memberId in memberIds) {
          // Check if student has learning progress for this lesson
          final progressQuery = await _firestore
              .collection('users')
              .doc(memberId)
              .collection('learning_progress')
              .where('lessonId', isEqualTo: lessonId)
              .where('classroomId', isEqualTo: classroomId)
              .get();
              
          // Consider a lesson completed if there's a progress document
          if (progressQuery.docs.isNotEmpty) {
            final progressData = progressQuery.docs.first.data();
            // Mark as completed if progress is >= 0.8 (80%)
            if ((progressData['progress'] ?? 0.0) >= 0.8) {
              completedCount++;
            }
            // Mark as attempted if they have any progress at all
            if ((progressData['progress'] ?? 0.0) > 0.0) {
              attemptedCount++;
            }
          }
          
          // Check quiz scores if there's a quiz for this lesson
          if (lesson['quizId'] != null) {
            final quizResultsQuery = await _firestore
                .collection('users')
                .doc(memberId)
                .collection('quiz_results')
                .where('quizId', isEqualTo: lesson['quizId'])
                .where('classroomId', isEqualTo: classroomId)
                .get();
                
            if (quizResultsQuery.docs.isNotEmpty) {
              quizAttempts += quizResultsQuery.docs.length;
              for (final quizDoc in quizResultsQuery.docs) {
                final score = quizDoc.data()['score'] ?? 0.0;
                totalScore += score;
              }
            }
          }
        }
        
        final completionRate = memberIds.isEmpty ? 0.0 : completedCount / memberIds.length;
        final attemptRate = memberIds.isEmpty ? 0.0 : attemptedCount / memberIds.length;
        final averageScore = quizAttempts > 0 ? totalScore / quizAttempts : 0.0;
        
        lessonStats.add({
          'lessonId': lessonId,
          'lessonTitle': lesson['title'],
          'name': lesson['title'],
          'completionRate': completionRate,
          'attemptRate': attemptRate,
          'completedCount': completedCount,
          'attemptedCount': attemptedCount,
          'totalStudents': memberIds.length,
          'averageScore': averageScore,
          'quizAttempts': quizAttempts,
        });
      }
      
      return {
        'lessonStats': lessonStats,
      };
      
    } catch (error) {
      return null;
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
            .where('classroomId', isEqualTo: classroomId)
            .get();
        
        bool isCompleted = false;
        int minutesSpent = 0;
        DateTime? lastAccessed;
        
        if (progress.docs.isNotEmpty) {
          final progressData = progress.docs.first.data();
          
          // Check completion based on multiple criteria
          final status = progressData['status'] as String?;
          final progressPercent = progressData['progressPercent'] as num?;
          final completedItems = progressData['completedItems'] as int?;
          final totalItems = progressData['totalItems'] as int?;
          final completedItemIds = progressData['completedItemIds'] as Map<String, dynamic>?;
          
          // Check status
          if (status == 'completed') {
            isCompleted = true;
          }
          // Check progress percent
          else if (progressPercent != null && progressPercent >= 100) {
            isCompleted = true;
          }
          // Check completed items
          else if (completedItems != null && totalItems != null && 
                  completedItems > 0 && completedItems >= totalItems) {
            isCompleted = true;
          }
          // Check completedItemIds
          else if (completedItemIds != null && completedItemIds.isNotEmpty &&
                  completedItemIds.values.every((v) => v == true)) {
            isCompleted = true;
          }
          
          minutesSpent = progressData['timeSpentMinutes'] ?? 0;
          lastAccessed = progressData['lastAccessTime'] != null 
              ? (progressData['lastAccessTime'] as Timestamp).toDate() 
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

      // Lấy tổng số người dùng
      final totalUsersSnapshot = await _firestore
          .collection('users')
          .count()
          .get();
      final totalUsers = totalUsersSnapshot.count;

      // Lấy tổng số lớp học
      final totalClassroomsSnapshot = await _firestore
          .collection('classrooms')
          .count()
          .get();
      final totalClassrooms = totalClassroomsSnapshot.count;

      // Lấy tổng số bài học
      final totalLessonsSnapshot = await _firestore
          .collection('lessons')
          .count()
          .get();
      final totalLessons = totalLessonsSnapshot.count;

      // Lấy tổng số flashcards
      final totalFlashcardsSnapshot = await _firestore
          .collection('flashcards')
          .count()
          .get();
      final totalFlashcards = totalFlashcardsSnapshot.count;

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
        'totalUsers': totalUsers,
        'totalClassrooms': totalClassrooms,
        'totalLessons': totalLessons,
        'totalFlashcards': totalFlashcards,
        'activeUsers': activeUsers.docs.length,
        'pendingContent': pendingContent,
        'topActiveClassrooms': topClassrooms,
      };
    } catch (e) {
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
      throw e.toString();
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
      throw e.toString();
    }
  }
  
  // ======== VIDEO TRACKING ========
  
  // Track video activity
  Future<void> trackVideoActivity({
    required String userId,
    required String lessonId,
    required String classroomId,
    required String videoId,
    required String videoTitle,
    required String action,
    required bool isCompleted,
    required double watchedPercentage,
    required DateTime timestamp,
  }) async {
    try {
      // Lưu vào collection user_video_tracking
      await _firestore.collection('user_video_tracking').add({
        'userId': userId,
        'lessonId': lessonId,
        'classroomId': classroomId,
        'videoId': videoId,
        'videoTitle': videoTitle,
        'action': action,
        'isCompleted': isCompleted,
        'watchedPercentage': watchedPercentage,
        'timestamp': Timestamp.fromDate(timestamp),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Nếu video hoàn thành (xem hơn 80%), cập nhật learning_progress
      if (isCompleted) {
        final progressQuery = await _firestore
            .collection('learning_progress')
            .where('userId', isEqualTo: userId)
            .where('lessonId', isEqualTo: lessonId)
            .where('classroomId', isEqualTo: classroomId)
            .get();
            
        if (progressQuery.docs.isNotEmpty) {
          final progressId = progressQuery.docs.first.id;
          final progressData = progressQuery.docs.first.data();
          
          // Lấy completedItemIds hoặc tạo mới nếu chưa có
          Map<String, dynamic> completedItemIds = 
            (progressData['completedItemIds'] as Map<String, dynamic>?) ?? {};
          
          // Đánh dấu video đã xem
          completedItemIds['video'] = true;
          
          // Tính lại phần trăm hoàn thành
          int completedItems = completedItemIds.values.where((value) => value == true).length;
          int totalItems = completedItemIds.length;
          double progressPercent = totalItems > 0 ? (completedItems / totalItems) * 100 : 0;
          
          // Cập nhật tiến độ học tập
          await _firestore.collection('learning_progress').doc(progressId).update({
            'completedItemIds': completedItemIds,
            'completedItems': completedItems,
            'progressPercent': progressPercent,
            'lastAccessTime': Timestamp.fromDate(timestamp),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error tracking video activity: $e');
    }
  }
  
  // ======== FLASHCARD TRACKING ========
  
  // Track flashcard activity
  Future<void> trackFlashcardActivity({
    required String userId,
    required String lessonId,
    required String classroomId,
    required String flashcardId,
    required String flashcardTitle,
    required String action,
    required int totalCards,
    required int viewedCards,
    required DateTime timestamp,
  }) async {
    try {
      // Calculate viewed percentage
      final viewedPercentage = totalCards > 0 ? viewedCards / totalCards : 0.0;
      final isCompleted = viewedPercentage >= 0.8; // Đánh dấu hoàn thành khi xem >= 80% thẻ
      
      // Lưu vào collection user_flashcard_tracking
      await _firestore.collection('user_flashcard_tracking').add({
        'userId': userId,
        'lessonId': lessonId,
        'classroomId': classroomId,
        'flashcardId': flashcardId,
        'flashcardTitle': flashcardTitle,
        'action': action,
        'totalCards': totalCards,
        'viewedCards': viewedCards,
        'viewedPercentage': viewedPercentage,
        'isCompleted': isCompleted,
        'timestamp': Timestamp.fromDate(timestamp),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Nếu flashcard hoàn thành (xem hơn 80%), cập nhật learning_progress
      if (isCompleted) {
        final progressQuery = await _firestore
            .collection('learning_progress')
            .where('userId', isEqualTo: userId)
            .where('lessonId', isEqualTo: lessonId)
            .where('classroomId', isEqualTo: classroomId)
            .get();
            
        if (progressQuery.docs.isNotEmpty) {
          final progressId = progressQuery.docs.first.id;
          final progressData = progressQuery.docs.first.data();
          
          // Lấy completedItemIds hoặc tạo mới nếu chưa có
          Map<String, dynamic> completedItemIds = 
            (progressData['completedItemIds'] as Map<String, dynamic>?) ?? {};
          
          // Đánh dấu flashcard đã xem
          completedItemIds['flashcards'] = true;
          
          // Tính lại phần trăm hoàn thành
          int completedItems = completedItemIds.values.where((value) => value == true).length;
          int totalItems = completedItemIds.length;
          double progressPercent = totalItems > 0 ? (completedItems / totalItems) * 100 : 0;
          
          // Cập nhật tiến độ học tập
          await _firestore.collection('learning_progress').doc(progressId).update({
            'completedItemIds': completedItemIds,
            'completedItems': completedItems,
            'progressPercent': progressPercent,
            'lastAccessTime': Timestamp.fromDate(timestamp),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error tracking flashcard activity: $e');
    }
  }
  
  // ======== QUIZ/EXERCISE TRACKING ========
  
  // Track quiz activity
  Future<void> trackQuizActivity({
    required String userId,
    required String lessonId,
    required String classroomId,
    required String quizId,
    required String quizTitle,
    required String action,
    required int totalQuestions,
    required int answeredQuestions,
    required double score,
    required bool isCompleted,
    required DateTime timestamp,
  }) async {
    try {
      // Calculate progress percentage
      final progressPercentage = totalQuestions > 0 ? answeredQuestions / totalQuestions : 0.0;
      
      // Lưu vào collection user_quiz_tracking
      await _firestore.collection('user_quiz_tracking').add({
        'userId': userId,
        'lessonId': lessonId,
        'classroomId': classroomId,
        'quizId': quizId, 
        'quizTitle': quizTitle,
        'action': action,
        'totalQuestions': totalQuestions,
        'answeredQuestions': answeredQuestions,
        'progressPercentage': progressPercentage,
        'score': score,
        'isCompleted': isCompleted,
        'timestamp': Timestamp.fromDate(timestamp),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Nếu quiz đã hoàn thành, cập nhật learning_progress
      if (isCompleted) {
        final progressQuery = await _firestore
            .collection('learning_progress')
            .where('userId', isEqualTo: userId)
            .where('lessonId', isEqualTo: lessonId)
            .where('classroomId', isEqualTo: classroomId)
            .get();
            
        if (progressQuery.docs.isNotEmpty) {
          final progressId = progressQuery.docs.first.id;
          final progressData = progressQuery.docs.first.data();
          
          // Lấy completedItemIds hoặc tạo mới nếu chưa có
          Map<String, dynamic> completedItemIds = 
            (progressData['completedItemIds'] as Map<String, dynamic>?) ?? {};
          
          // Đánh dấu quiz đã hoàn thành
          completedItemIds['exercises'] = true;
          
          // Tính lại phần trăm hoàn thành
          int completedItems = completedItemIds.values.where((value) => value == true).length;
          int totalItems = completedItemIds.length;
          double progressPercent = totalItems > 0 ? (completedItems / totalItems) * 100 : 0;
          
          // Cập nhật tiến độ học tập
          await _firestore.collection('learning_progress').doc(progressId).update({
            'completedItemIds': completedItemIds,
            'completedItems': completedItems,
            'progressPercent': progressPercent,
            'lastAccessTime': Timestamp.fromDate(timestamp),
            'lastScore': score,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          // Lưu kết quả bài kiểm tra
          await _firestore.collection('quiz_attempts').add({
            'userId': userId,
            'lessonId': lessonId,
            'classroomId': classroomId,
            'quizId': quizId,
            'score': score,
            'totalQuestions': totalQuestions,
            'answeredQuestions': answeredQuestions,
            'createdAt': Timestamp.fromDate(timestamp),
            'status': 'completed',
            'passed': score >= 0.7, // Đạt nếu điểm trên 70%
          });
        }
      }
    } catch (e) {
      print('Error tracking quiz activity: $e');
    }
  }
} 