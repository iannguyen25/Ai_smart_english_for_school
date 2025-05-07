import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/classroom.dart';
import '../models/lesson.dart';
import '../models/app_user.dart';
import '../models/quiz_attempt.dart';
import '../models/exercise_attempt.dart';
import '../models/feedback.dart' as app_models;
import 'lesson_service.dart';
import 'user_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      print('DEBUG: Starting getClassCompletionRate for classroom: $classroomId');
      
      // Check cache first
      if (_completionRateCache.containsKey(classroomId)) {
        final cacheTime = _cacheTimestamps[classroomId];
        if (cacheTime != null && 
            DateTime.now().difference(cacheTime) < _cacheDuration) {
          print('DEBUG: Using cached completion rate: ${_completionRateCache[classroomId]}');
          return _completionRateCache[classroomId]!;
        }
      }

      final classroom = await _firestore.collection('classrooms').doc(classroomId).get();
      if (!classroom.exists) {
        print('DEBUG: Classroom not found');
        return 0;
      }
      
      final classData = classroom.data() as Map<String, dynamic>;
      final String teacherId = classData['teacherId'] ?? '';
      final List<dynamic> memberIds = (classData['memberIds'] ?? [])
          .where((id) => id != teacherId) // Loại bỏ ID của giáo viên
          .toList();
      
      print('DEBUG: Found ${memberIds.length} students in classroom');
      
      if (memberIds.isEmpty) {
        print('DEBUG: No students found');
        return 0;
      }
      
      final lessons = await _lessonService.getLessonsByClassroom(classroomId);
      print('DEBUG: Found ${lessons.length} lessons in classroom');
      
      if (lessons.isEmpty) {
        print('DEBUG: No lessons found');
        return 0;
      }
      
      double totalCompletionRate = 0;
      
      for (String memberId in memberIds) {
        print('DEBUG: Processing student: $memberId');
        double studentTotalProgress = 0;
        
        for (Lesson lesson in lessons) {
          print('DEBUG: Checking lesson: ${lesson.id}');
          final progress = await _firestore
              .collection('learning_progress')
              .where('userId', isEqualTo: memberId)
              .where('lessonId', isEqualTo: lesson.id)
              .where('classroomId', isEqualTo: classroomId)
              .get();
          
          print('DEBUG: Found ${progress.docs.length} progress documents');
          
          if (progress.docs.isNotEmpty) {
            final progressData = progress.docs.first.data();
            print('DEBUG: Progress data: $progressData');
            
            // Kiểm tra các hoạt động học tập
            final completedItemIds = progressData['completedItemIds'] as Map<String, dynamic>? ?? {};
            final timeSpentMinutes = progressData['timeSpentMinutes'] as int? ?? 0;
            final progressPercent = progressData['progressPercent'] as num? ?? 0.0;
            
            // Tính điểm tiến độ dựa trên các hoạt động
            double lessonProgress = 0;
            
            // Nếu đã xem video
            if (completedItemIds['video'] == true) {
              lessonProgress += 0.4; // 40% cho việc xem video
            }
            
            // Nếu đã làm bài tập
            if (completedItemIds['exercises'] == true) {
              lessonProgress += 0.6; // 60% cho việc làm bài tập
            }
            
            // Nếu có thời gian học tập
            if (timeSpentMinutes > 0) {
              lessonProgress = lessonProgress > 0 ? lessonProgress : 0.2; // Tối thiểu 20% nếu có học
            }
            
            // Nếu có progressPercent từ hệ thống
            if (progressPercent > 0) {
              lessonProgress = lessonProgress > 0 ? lessonProgress : progressPercent / 100;
            }
            
            studentTotalProgress += lessonProgress;
            print('DEBUG: Lesson progress: $lessonProgress');
          }
        }
        
        // Tính trung bình tiến độ của học sinh
        final studentCompletionRate = lessons.isNotEmpty 
            ? studentTotalProgress / lessons.length
            : 0;
        
        print('DEBUG: Student completion rate: $studentCompletionRate');
        totalCompletionRate += studentCompletionRate;
      }
      
      final classCompletionRate = totalCompletionRate / memberIds.length;
      print('DEBUG: Final class completion rate: $classCompletionRate');

      // Update cache
      _completionRateCache[classroomId] = classCompletionRate;
      _cacheTimestamps[classroomId] = DateTime.now();

      return classCompletionRate;
    } catch (e) {
      print('ERROR in getClassCompletionRate: $e');
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

      double totalProgress = 0;
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
          
          // Lấy các thông tin tiến độ
          final completedItemIds = progressData['completedItemIds'] as Map<String, dynamic>? ?? {};
          final timeSpentMinutes = progressData['timeSpentMinutes'] as int? ?? 0;
          final progressPercent = progressData['progressPercent'] as num? ?? 0.0;
          
          // Tính tiến độ cho bài học này
          double lessonProgress = 0;
          
          // Nếu đã xem video
          if (completedItemIds['video'] == true) {
            lessonProgress += 0.4; // 40% cho việc xem video
          }
          
          // Nếu đã làm bài tập
          if (completedItemIds['exercises'] == true) {
            lessonProgress += 0.6; // 60% cho việc làm bài tập
          }
          
          // Nếu có thời gian học tập
          if (timeSpentMinutes > 0) {
            lessonProgress = lessonProgress > 0 ? lessonProgress : 0.2; // Tối thiểu 20% nếu có học
          }
          
          // Nếu có progressPercent từ hệ thống
          if (progressPercent > 0) {
            lessonProgress = lessonProgress > 0 ? lessonProgress : progressPercent / 100;
          }
          
          totalProgress += lessonProgress;

          // Update lastAccessed if this entry is more recent
          if (progressData['lastAccessTime'] != null) {
            final progressLastAccessed = (progressData['lastAccessTime'] as Timestamp).toDate();
            if (lastAccessed == null || progressLastAccessed.isAfter(lastAccessed)) {
              lastAccessed = progressLastAccessed;
            }
          }
        }
      }
      
      // Tính trung bình tiến độ
      final completionRate = lessons.isNotEmpty ? totalProgress / lessons.length : 0.0;
      
      // Get user info
      final user = await _userService.getUserById(studentId);
      
      return {
        'id': studentId,
        'name': user?.fullName ?? 'Unknown',
        'progress': completionRate,
        'totalLessons': lessons.length,
        'completedLessons': (completionRate * lessons.length).round(),
        'lastAccessed': lastAccessed
      };
    } catch (e) {
      print('ERROR in getStudentProgressInClass: $e');
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
      print('DEBUG: Starting getStudentDetailedProgress');
      print('- Classroom ID: $classroomId');
      print('- Student ID: $studentId');

      final user = await _userService.getUserById(studentId);
      print('DEBUG: User data fetched: ${user != null}');
      if (user == null) return {};
      
      // Lấy danh sách bài học của lớp
      final lessons = await _lessonService.getLessonsByClassroom(classroomId);
      print('DEBUG: Lessons fetched: ${lessons.length} lessons');
      if (lessons.isEmpty) return {};
      
      // Đếm số bài đã học
      int completedLessons = 0;
      List<Map<String, dynamic>> lessonProgressList = [];
      
      print('DEBUG: Fetching learning progress for each lesson');
      for (Lesson lesson in lessons) {
        print('DEBUG: Processing lesson: ${lesson.title}');
        final progress = await _firestore
            .collection('learning_progress')
            .where('userId', isEqualTo: studentId)
            .where('lessonId', isEqualTo: lesson.id)
            .where('classroomId', isEqualTo: classroomId)
            .get();
        
        print('DEBUG: Progress docs found: ${progress.docs.length}');
        
        bool isCompleted = false;
        int minutesSpent = 0;
        DateTime? lastAccessed;
        double lessonProgress = 0.0;
        
        if (progress.docs.isNotEmpty) {
          final progressData = progress.docs.first.data();
          print('DEBUG: Progress data: $progressData');
          
          // Check completion based on multiple criteria
          final status = progressData['status'] as String?;
          final progressPercent = progressData['progressPercent'] as num?;
          final completedItems = progressData['completedItems'] as int?;
          final totalItems = progressData['totalItems'] as int?;
          final completedItemIds = progressData['completedItemIds'] as Map<String, dynamic>?;
          
          print('DEBUG: Completion criteria:');
          print('- Status: $status');
          print('- Progress Percent: $progressPercent');
          print('- Completed Items: $completedItems/$totalItems');
          print('- Completed Item IDs: $completedItemIds');
          
          // Calculate lesson progress
          if (completedItemIds != null) {
            // Nếu đã xem video
            if (completedItemIds['video'] == true) {
              lessonProgress += 0.4; // 40% cho việc xem video
            }
            
            // Nếu đã làm bài tập
            if (completedItemIds['exercises'] == true) {
              lessonProgress += 0.6; // 60% cho việc làm bài tập
            }
            
            // Nếu đã xem flashcard
            if (completedItemIds['flashcards'] == true) {
              lessonProgress += 0.3; // 30% cho việc xem flashcard
            }
          }
          
          // Check status and progress
          if (status == 'completed') {
            isCompleted = true;
            lessonProgress = 1.0;
          }
          // Check progress percent
          else if (progressPercent != null) {
            lessonProgress = progressPercent / 100;
            // Nếu tiến độ >= 80% thì coi như hoàn thành
            if (progressPercent >= 80) {
              isCompleted = true;
            }
          }
          // Check completed items
          else if (completedItems != null && totalItems != null && totalItems > 0) {
            lessonProgress = completedItems / totalItems;
            // Nếu hoàn thành >= 80% số items thì coi như hoàn thành
            if (completedItems >= (totalItems * 0.8)) {
              isCompleted = true;
            }
          }
          // Check completedItemIds
          else if (completedItemIds != null && completedItemIds.isNotEmpty) {
            // Nếu hoàn thành >= 80% các hoạt động thì coi như hoàn thành
            final totalActivities = completedItemIds.length;
            final completedActivities = completedItemIds.values.where((v) => v == true).length;
            if (totalActivities > 0) {
              lessonProgress = completedActivities / totalActivities;
              if (lessonProgress >= 0.8) {
                isCompleted = true;
              }
            }
          }
          
          // Nếu có thời gian học tập nhưng chưa có tiến độ
          if (minutesSpent > 0 && lessonProgress == 0) {
            lessonProgress = 0.2; // Tối thiểu 20% nếu có học
          }
          
          minutesSpent = progressData['timeSpentMinutes'] ?? 0;
          lastAccessed = progressData['lastAccessTime'] != null 
              ? (progressData['lastAccessTime'] as Timestamp).toDate() 
              : null;
          
          if (isCompleted) {
            completedLessons++;
          }
          
          print('DEBUG: Lesson progress calculation:');
          print('- Lesson: ${lesson.title}');
          print('- Progress: ${(lessonProgress * 100).toStringAsFixed(1)}%');
          print('- Is Completed: $isCompleted');
          print('- Minutes Spent: $minutesSpent');
        }
        
        lessonProgressList.add({
          'lessonId': lesson.id,
          'lessonTitle': lesson.title,
          'isCompleted': isCompleted,
          'minutesSpent': minutesSpent,
          'lastAccessed': lastAccessed,
          'progress': lessonProgress,
        });
      }
      
      // Calculate overall completion rate
      final completionRate = lessons.isNotEmpty ? completedLessons / lessons.length : 0.0;
      
      print('DEBUG: Final calculations:');
      print('- Completed Lessons: $completedLessons/${lessons.length}');
      print('- Completion Rate: $completionRate');
      
      print('DEBUG: Fetching badges');
      // Lấy thông tin huy hiệu đã đạt
      final badges = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: studentId)
          .get();
      
      print('DEBUG: Badges found: ${badges.docs.length}');
      
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
      
      print('DEBUG: Fetching streaks');
      // Lấy thông tin streak từ user document
      final userDoc = await _firestore
          .collection('users')
          .doc(studentId)
          .get();
      
      print('DEBUG: User doc exists: ${userDoc.exists}');
      
      int currentStreak = 0;
      int longestStreak = 0;
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        currentStreak = userData['currentStreak'] ?? 0;
        longestStreak = userData['longestStreak'] ?? 0;
      }
      
      print('DEBUG: Fetching quiz statistics');
      // Lấy thống kê bài kiểm tra
      List<Map<String, dynamic>> testStatistics = [];
      int totalTests = 0;
      int completedTests = 0;
      double totalScore = 0;
      
      for (Lesson lesson in lessons) {
        print('DEBUG: Processing quizzes for lesson: ${lesson.title}');
        final quizzes = await _firestore
            .collection('quizzes')
            .where('lessonId', isEqualTo: lesson.id)
            .get();
        
        print('DEBUG: Quizzes found: ${quizzes.docs.length}');
        
        for (var quiz in quizzes.docs) {
          final quizId = quiz.id;
          final quizData = quiz.data();
          final quizTitle = quizData['title'] ?? 'Bài kiểm tra';
          
          totalTests++;
          
          print('DEBUG: Fetching attempts for quiz: $quizTitle');
          final attempts = await _firestore
              .collection('quiz_attempts')
              .where('userId', isEqualTo: studentId)
              .where('quizId', isEqualTo: quizId)
              .where('status', isEqualTo: 'completed')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();
          
          print('DEBUG: Quiz attempts found: ${attempts.docs.length}');
          
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
      
      print('DEBUG: Preparing final response');
      final response = {
        'userId': studentId,
        'name': user.fullName,
        'email': user.email,
        'photoUrl': user.avatar,
        'joinedAt': user.createdAt,
        'completedLessons': completedLessons,
        'totalLessons': lessons.length,
        'completionRate': completionRate,
        'lessonProgress': lessonProgressList,
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
      
      print('DEBUG: Response prepared:');
      print('- Completed Lessons: ${response['completedLessons']}/${response['totalLessons']}');
      print('- Lesson Progress Items: ${(response['lessonProgress'] as List?)?.length ?? 0}');
      print('- Earned Badges: ${(response['earnedBadges'] as List?)?.length ?? 0}');
      final testStats = response['testStatistics'] as Map<String, dynamic>?;
      print('- Test Statistics: ${testStats?['totalTests'] ?? 0} total, ${testStats?['completedTests'] ?? 0} completed');
      
      return response;
    } catch (e, stackTrace) {
      print('ERROR in getStudentDetailedProgress: $e');
      print('Stack trace: $stackTrace');
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
      
      // Lấy danh sách tất cả các lớp học
      final classroomsSnapshot = await _firestore.collection('classrooms').get();
      final classrooms = classroomsSnapshot.docs;
      
      // Khởi tạo list để lưu thông tin chi tiết cho mỗi loại tài nguyên
      List<Map<String, dynamic>> lessonDetails = [];
      List<Map<String, dynamic>> flashcardDetails = [];
      List<Map<String, dynamic>> exerciseDetails = [];
      List<Map<String, dynamic>> quizDetails = [];
      
      // Tổng số và số mới cho mỗi loại tài nguyên
      int totalLessons = 0;
      int newLessons = 0;
      int totalFlashcards = 0;
      int newFlashcards = 0;
      int totalExercises = 0;
      int newExercises = 0;
      int totalQuizzes = 0;
      int newQuizzes = 0;
      
      // Xử lý thông tin cho từng lớp học
      for (var classroom in classrooms) {
        final classroomId = classroom.id;
        final classroomName = classroom.data()['name'] ?? 'Lớp không xác định';
        
        // Thống kê bài học
        final lessonsSnapshot = await _firestore
            .collection('lessons')
            .where('classroomId', isEqualTo: classroomId)
            .get();
            
        // Lọc bài học mới trong code thay vì dùng query
        final classroomNewLessons = lessonsSnapshot.docs.where((doc) {
          final createdAt = doc.data()['createdAt'] as Timestamp?;
          return createdAt != null && createdAt.toDate().isAfter(startDate);
        }).length;
            
        lessonDetails.add({
          'classroomId': classroomId,
          'classroomName': classroomName,
          'total': lessonsSnapshot.docs.length,
          'new': classroomNewLessons,
        });
        
        totalLessons += lessonsSnapshot.docs.length;
        newLessons += classroomNewLessons;
        
        // Thống kê flashcards
        final flashcardsSnapshot = await _firestore
            .collection('flashcards')
            .where('classroomId', isEqualTo: classroomId)
            .get();
            
        // Lọc flashcards mới trong code
        final classroomNewFlashcards = flashcardsSnapshot.docs.where((doc) {
          final createdAt = doc.data()['createdAt'] as Timestamp?;
          return createdAt != null && createdAt.toDate().isAfter(startDate);
        }).length;
            
        flashcardDetails.add({
          'classroomId': classroomId,
          'classroomName': classroomName,
          'total': flashcardsSnapshot.docs.length,
          'new': classroomNewFlashcards,
        });
        
        totalFlashcards += flashcardsSnapshot.docs.length;
        newFlashcards += classroomNewFlashcards;
        
        // Thống kê bài tập
        final exercisesSnapshot = await _firestore
            .collection('exercises')
            .where('classroomId', isEqualTo: classroomId)
            .get();
            
        // Lọc bài tập mới trong code
        final classroomNewExercises = exercisesSnapshot.docs.where((doc) {
          final createdAt = doc.data()['createdAt'] as Timestamp?;
          return createdAt != null && createdAt.toDate().isAfter(startDate);
        }).length;
            
        exerciseDetails.add({
          'classroomId': classroomId,
          'classroomName': classroomName,
          'total': exercisesSnapshot.docs.length,
          'new': classroomNewExercises,
        });
        
        totalExercises += exercisesSnapshot.docs.length;
        newExercises += classroomNewExercises;
        
        // Thống kê bài kiểm tra
        final quizzesSnapshot = await _firestore
            .collection('quizzes')
            .where('classroomId', isEqualTo: classroomId)
            .get();
            
        // Lọc bài kiểm tra mới trong code
        final classroomNewQuizzes = quizzesSnapshot.docs.where((doc) {
          final createdAt = doc.data()['createdAt'] as Timestamp?;
          return createdAt != null && createdAt.toDate().isAfter(startDate);
        }).length;
            
        quizDetails.add({
          'classroomId': classroomId,
          'classroomName': classroomName,
          'total': quizzesSnapshot.docs.length,
          'new': classroomNewQuizzes,
        });
        
        totalQuizzes += quizzesSnapshot.docs.length;
        newQuizzes += classroomNewQuizzes;
      }
      
      // Sắp xếp chi tiết theo số lượng tài nguyên giảm dần
      lessonDetails.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
      flashcardDetails.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
      exerciseDetails.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
      quizDetails.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
      
      return {
        'totalLessons': totalLessons,
        'newLessons': newLessons,
        'totalFlashcards': totalFlashcards,
        'newFlashcards': newFlashcards,
        'totalExercises': totalExercises,
        'newExercises': newExercises,
        'totalQuizzes': totalQuizzes,
        'newQuizzes': newQuizzes,
        'lessonDetails': lessonDetails,
        'flashcardDetails': flashcardDetails,
        'exerciseDetails': exerciseDetails,
        'quizDetails': quizDetails,
        'periodDays': days,
      };
    } catch (e) {
      print('ERROR in getLearningResourcesReport: $e');
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
      print('DEBUG: Tracking video activity:');
      print('- User ID: $userId');
      print('- Lesson ID: $lessonId');
      print('- Classroom ID: $classroomId');
      print('- Video ID: $videoId');
      print('- Video Title: $videoTitle');
      print('- Action: $action');
      print('- Is Completed: $isCompleted');
      print('- Watched Percentage: $watchedPercentage');
      print('- Timestamp: $timestamp');

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
      
      print('DEBUG: Video activity tracked successfully');
      
      // Nếu video hoàn thành (xem hơn 80%), cập nhật learning_progress
      if (isCompleted) {
        print('DEBUG: Video completed, updating learning progress');
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
          int totalItems = 3; // Cố định số lượng items (video, flashcards, exercises)
          double progressPercent = totalItems > 0 ? (completedItems / totalItems) * 100 : 0;
          
          print('DEBUG: Updating learning progress:');
          print('- Progress ID: $progressId');
          print('- Completed Items: $completedItems/$totalItems');
          print('- Progress Percent: $progressPercent');
          print('- Completed Item IDs: $completedItemIds');
          
          // Cập nhật tiến độ học tập
          await _firestore.collection('learning_progress').doc(progressId).update({
            'completedItemIds': completedItemIds,
            'completedItems': completedItems,
            'totalItems': totalItems,
            'progressPercent': progressPercent,
            'lastAccessTime': Timestamp.fromDate(timestamp),
            'status': progressPercent >= 70 ? 'completed' : 'inProgress',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          print('DEBUG: Learning progress updated successfully');
        } else {
          print('DEBUG: No learning progress found to update');
        }
      }
    } catch (e) {
      print('ERROR tracking video activity: $e');
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
      print('DEBUG: ====== FLASHCARD TRACKING START ======');
      print('DEBUG: Input parameters:');
      print('- User ID: $userId');
      print('- Lesson ID: $lessonId');
      print('- Classroom ID: $classroomId');
      print('- Flashcard ID: $flashcardId');
      print('- Flashcard Title: $flashcardTitle');
      print('- Action: $action');
      print('- Total Cards: $totalCards');
      print('- Viewed Cards: $viewedCards');
      print('- Timestamp: $timestamp');

      // Calculate viewed percentage
      final viewedPercentage = totalCards > 0 ? viewedCards / totalCards : 0.0;
      final isCompleted = viewedPercentage >= 0.8 || action == 'completed';
      
      print('DEBUG: Calculated metrics:');
      print('- Viewed Percentage: ${(viewedPercentage * 100).toStringAsFixed(1)}%');
      print('- Is Completed: $isCompleted');
      print('- Action Type: $action');
      
      // Lưu vào collection user_flashcard_tracking
      final trackingDoc = await _firestore.collection('user_flashcard_tracking').add({
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
      
      print('DEBUG: Flashcard activity tracked successfully');
      print('- Tracking Document ID: ${trackingDoc.id}');
      
      // Nếu flashcard hoàn thành, kiểm tra và trao huy hiệu
      if (isCompleted) {
        print('DEBUG: Flashcard is completed, checking for badge eligibility');
        
        // Kiểm tra xem đây có phải là flashcard đầu tiên người dùng hoàn thành không
        final previousCompletions = await _firestore
            .collection('user_flashcard_tracking')
            .where('userId', isEqualTo: userId)
            .where('isCompleted', isEqualTo: true)
            .get();
            
        print('DEBUG: Found ${previousCompletions.docs.length} previous completed flashcards');
        
        // Nếu đây là flashcard đầu tiên hoàn thành
        if (previousCompletions.docs.length == 1) {
          print('DEBUG: This is the first flashcard completion');
          
          // Tìm huy hiệu "Khởi đầu" bằng requirements.type
          final badgeQuery = await _firestore
              .collection('badges')
              .where('requirements.type', isEqualTo: 'first_flashcard_completion')
              .get();
              
          print('DEBUG: Found ${badgeQuery.docs.length} badges with type first_flashcard_completion');
          
          if (badgeQuery.docs.isNotEmpty) {
            final badgeId = badgeQuery.docs.first.id;
            final badgeData = badgeQuery.docs.first.data();
            print('DEBUG: Found first flashcard badge: ${badgeData['name']} (ID: $badgeId)');
            print('DEBUG: Badge data: $badgeData');
            
            // Kiểm tra xem người dùng đã có huy hiệu này chưa
            final existingBadge = await _firestore
                .collection('user_badges')
                .where('userId', isEqualTo: userId)
                .where('badgeId', isEqualTo: badgeId)
                .limit(1)
                .get();
                
            print('DEBUG: User has ${existingBadge.docs.length} existing badges');
            
            // Nếu chưa có, trao huy hiệu
            if (existingBadge.docs.isEmpty) {
              print('DEBUG: First flashcard badge not found in database');
              print('DEBUG: Creating new first flashcard badge');
              
              try {
                // Tạo huy hiệu mới
                final badgeDoc = await _firestore.collection('badges').add({
                  'name': 'Khởi đầu',
                  'description': 'Lần đầu học Flashcard',
                  'iconUrl': 'https://firebasestorage.googleapis.com/v0/b/la-english.firebasestorage.app/o/badges%2F1746771139233.png?alt=media&token=26ce6e8e-52aa-45b6-87b7-38287e3605cc',
                  'type': 'activity',
                  'requirements': {
                    'type': 'first_flashcard_completion',
                  },
                  'isOneTime': true,
                  'isHidden': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                print('DEBUG: Created new first flashcard badge with ID: ${badgeDoc.id}');
                
                // Trao huy hiệu cho người dùng
                final userBadgeDoc = await _firestore.collection('user_badges').add({
                  'userId': userId,
                  'badgeId': badgeDoc.id,
                  'earnedAt': Timestamp.fromDate(timestamp),
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                print('DEBUG: Successfully awarded new first flashcard badge to user');
                print('DEBUG: User badge document created with ID: ${userBadgeDoc.id}');
                
                // Cập nhật danh sách huy hiệu trong user document
                await _firestore.collection('users').doc(userId).update({
                  'badges': FieldValue.arrayUnion([badgeDoc.id]),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                print('DEBUG: Updated user document with new badge');

                // Hiển thị dialog chúc mừng
                _showBadgeCongratulationsDialog('Khởi đầu', 'https://firebasestorage.googleapis.com/v0/b/la-english.firebasestorage.app/o/badges%2F1746771139233.png?alt=media&token=26ce6e8e-52aa-45b6-87b7-38287e3605cc');
                print('DEBUG: Showing congratulation dialog');

                // Tạo thông báo chúc mừng
                await _firestore.collection('notifications').add({
                  'userId': userId,
                  'type': 'badge_earned',
                  'title': 'Chúc mừng! 🎉',
                  'message': 'Bạn đã nhận được huy hiệu "Khởi đầu" cho việc hoàn thành flashcard đầu tiên!',
                  'badgeId': badgeDoc.id,
                  'badgeName': 'Khởi đầu',
                  'badgeIconUrl': 'https://firebasestorage.googleapis.com/v0/b/la-english.firebasestorage.app/o/badges%2F1746771139233.png?alt=media&token=26ce6e8e-52aa-45b6-87b7-38287e3605cc',
                  'createdAt': FieldValue.serverTimestamp(),
                  'read': false,
                });
                print('DEBUG: Created congratulation notification for user');
              } catch (e) {
                print('DEBUG: Error creating and awarding badge: $e');
              }
            } else {
              print('DEBUG: User already has first flashcard badge: ${badgeData['name']}');
            }
          } else {
            print('DEBUG: First flashcard badge not found in database');
            print('DEBUG: Creating new first flashcard badge');
            
            try {
              // Tạo huy hiệu mới
              final badgeDoc = await _firestore.collection('badges').add({
                'name': 'Khởi đầu',
                'description': 'Lần đầu học Flashcard',
                'iconUrl': 'https://firebasestorage.googleapis.com/v0/b/la-english.firebasestorage.app/o/badges%2F1746771139233.png?alt=media&token=26ce6e8e-52aa-45b6-87b7-38287e3605cc',
                'type': 'activity',
                'requirements': {
                  'type': 'first_flashcard_completion',
                },
                'isOneTime': true,
                'isHidden': false,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              
              print('DEBUG: Created new first flashcard badge with ID: ${badgeDoc.id}');
              
              // Trao huy hiệu cho người dùng
              final userBadgeDoc = await _firestore.collection('user_badges').add({
                'userId': userId,
                'badgeId': badgeDoc.id,
                'earnedAt': Timestamp.fromDate(timestamp),
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              
              print('DEBUG: Successfully awarded new first flashcard badge to user');
              print('DEBUG: User badge document created with ID: ${userBadgeDoc.id}');
              
              // Cập nhật danh sách huy hiệu trong user document
              await _firestore.collection('users').doc(userId).update({
                'badges': FieldValue.arrayUnion([badgeDoc.id]),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              print('DEBUG: Updated user document with new badge');

              // Hiển thị dialog chúc mừng
              _showBadgeCongratulationsDialog('Khởi đầu', 'https://firebasestorage.googleapis.com/v0/b/la-english.firebasestorage.app/o/badges%2F1746771139233.png?alt=media&token=26ce6e8e-52aa-45b6-87b7-38287e3605cc');
              print('DEBUG: Showing congratulation dialog');

              // Tạo thông báo chúc mừng
              await _firestore.collection('notifications').add({
                'userId': userId,
                'type': 'badge_earned',
                'title': 'Chúc mừng! 🎉',
                'message': 'Bạn đã nhận được huy hiệu "Khởi đầu" cho việc hoàn thành flashcard đầu tiên!',
                'badgeId': badgeDoc.id,
                'badgeName': 'Khởi đầu',
                'badgeIconUrl': 'https://firebasestorage.googleapis.com/v0/b/la-english.firebasestorage.app/o/badges%2F1746771139233.png?alt=media&token=26ce6e8e-52aa-45b6-87b7-38287e3605cc',
                'createdAt': FieldValue.serverTimestamp(),
                'read': false,
              });
              print('DEBUG: Created congratulation notification for user');
            } catch (e) {
              print('DEBUG: Error creating and awarding badge: $e');
            }
          }
        } else {
          print('DEBUG: Not the first flashcard completion (previous completions: ${previousCompletions.docs.length})');
        }
      }
      
      print('DEBUG: ====== FLASHCARD TRACKING END ======');
    } catch (e) {
      print('ERROR tracking flashcard activity: $e');
      print('DEBUG: ====== FLASHCARD TRACKING FAILED ======');
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
      print('DEBUG: ====== QUIZ TRACKING START ======');
      print('DEBUG: Input parameters:');
      print('- User ID: $userId');
      print('- Lesson ID: $lessonId');
      print('- Classroom ID: $classroomId');
      print('- Quiz ID: $quizId');
      print('- Quiz Title: $quizTitle');
      print('- Action: $action');
      print('- Total Questions: $totalQuestions');
      print('- Answered Questions: $answeredQuestions');
      print('- Score: $score');
      print('- Is Completed: $isCompleted');
      print('- Timestamp: $timestamp');

      // Calculate progress percentage
      final progressPercentage = totalQuestions > 0 ? answeredQuestions / totalQuestions : 0.0;
      
      print('DEBUG: Calculated metrics:');
      print('- Progress Percentage: ${(progressPercentage * 100).toStringAsFixed(1)}%');
      
      // Lưu vào collection user_quiz_tracking
      final trackingDoc = await _firestore.collection('user_quiz_tracking').add({
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
      
      print('DEBUG: Quiz activity tracked successfully');
      print('- Tracking Document ID: ${trackingDoc.id}');
      
      // Nếu quiz đã hoàn thành, cập nhật learning_progress
      if (isCompleted) {
        print('DEBUG: Quiz completed, updating learning progress');
        final progressQuery = await _firestore
            .collection('learning_progress')
            .where('userId', isEqualTo: userId)
            .where('lessonId', isEqualTo: lessonId)
            .where('classroomId', isEqualTo: classroomId)
            .get();
            
        if (progressQuery.docs.isNotEmpty) {
          final progressId = progressQuery.docs.first.id;
          final progressData = progressQuery.docs.first.data();
          
          print('DEBUG: Found existing learning progress:');
          print('- Progress ID: $progressId');
          print('- Current progress data: $progressData');
          
          // Lấy completedItemIds hoặc tạo mới nếu chưa có
          Map<String, dynamic> completedItemIds = 
            (progressData['completedItemIds'] as Map<String, dynamic>?) ?? {};
          
          // Đánh dấu quiz đã hoàn thành
          completedItemIds['exercises'] = true;
          
          // Tính lại phần trăm hoàn thành
          int completedItems = completedItemIds.values.where((value) => value == true).length;
          int totalItems = 3; // Cố định số lượng items (video, flashcards, exercises)
          double progressPercent = totalItems > 0 ? (completedItems / totalItems) * 100 : 0;
          
          print('DEBUG: Updating learning progress:');
          print('- Completed Items: $completedItems/$totalItems');
          print('- Progress Percent: ${progressPercent.toStringAsFixed(1)}%');
          print('- Completed Item IDs: $completedItemIds');
          
          // Cập nhật tiến độ học tập
          await _firestore.collection('learning_progress').doc(progressId).update({
            'completedItemIds': completedItemIds,
            'completedItems': completedItems,
            'totalItems': totalItems,
            'progressPercent': progressPercent,
            'lastAccessTime': Timestamp.fromDate(timestamp),
            'lastScore': score,
            'status': progressPercent >= 70 ? 'completed' : 'inProgress',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          print('DEBUG: Learning progress updated successfully');
          
          // Lưu kết quả bài kiểm tra
          final attemptDoc = await _firestore.collection('quiz_attempts').add({
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
          
          print('DEBUG: Quiz attempt saved successfully');
          print('- Attempt Document ID: ${attemptDoc.id}');
        } else {
          print('DEBUG: No learning progress found to update');
        }
      }
      
      print('DEBUG: ====== QUIZ TRACKING END ======');
    } catch (e) {
      print('ERROR tracking quiz activity: $e');
      print('DEBUG: ====== QUIZ TRACKING FAILED ======');
    }
  }

  // Hiển thị dialog chúc mừng
  void _showBadgeCongratulationsDialog(String badgeName, String badgeIconUrl) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon huy hiệu
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(badgeIconUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Tiêu đề
              Text(
                'Chúc mừng! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 10),
              // Nội dung
              Text(
                'Bạn đã nhận được huy hiệu\n"$badgeName"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              // Nút đóng
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('Tuyệt vời!'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
} 