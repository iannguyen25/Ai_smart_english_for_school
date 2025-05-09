import 'package:base_flutter_framework/models/content_approval.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson.dart';
import '../models/learning_progress.dart';
import '../models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/flashcard_service.dart';
import '../services/exercise_service.dart';
import '../models/quiz.dart';
import '../models/flashcard.dart';
import '../models/flashcard_item.dart';
import '../models/exercise.dart';

class LessonService {
  // Singleton pattern
  static final LessonService _instance = LessonService._internal();
  factory LessonService() => _instance;
  LessonService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _lessonsCollection => _firestore.collection('lessons');
  CollectionReference get _progressCollection => _firestore.collection('learning_progress');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Lấy danh sách bài học của lớp học
  Future<List<Lesson>> getLessonsByClassroom(String classroomId) async {
    try {
      print('Getting lessons for classroom: $classroomId');
      final snapshot = await _lessonsCollection
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('orderIndex', descending: false)
          .get();

      final lessons = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Lesson.fromMap(data, doc.id);
      }).toList();

      return lessons;
    } catch (e) {
      print('Error getting lessons by classroom: $e');
      return [];
    }
  }

  // Lấy danh sách bài học đã được duyệt của lớp học
  Future<List<Lesson>> getApprovedLessonsByClassroom(String classroomId) async {
    try {
      final snapshot = await _lessonsCollection
          .where('classroomId', isEqualTo: classroomId)
          .where('approvalStatus', isEqualTo: 'approved')
          .orderBy('orderIndex', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Lesson.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting approved lessons: $e');
      throw Exception('Không thể tải danh sách bài học đã duyệt: $e');
    }
  }

  // Lấy danh sách tất cả bài học chờ duyệt
  Future<List<Lesson>> getPendingLessons() async {
    try {
      final snapshot = await _lessonsCollection
          .where('approvalStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Lesson.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting pending lessons: $e');
      throw Exception('Không thể tải danh sách bài học chờ duyệt: $e');
    }
  }

  // Lấy chi tiết bài học từ ID
  Future<Lesson?> getLessonById(String id) async {
    try {
      DocumentSnapshot doc = await _lessonsCollection.doc(id).get();
      if (doc.exists) {
        return Lesson.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting lesson: $e');
      throw Exception('Không thể tải thông tin bài học: $e');
    }
  }

  // Tạo bài học mới
  Future<String> createLesson(Lesson lesson) async {
    try {
      final docRef = await _lessonsCollection.add(lesson.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating lesson: $e');
      throw Exception('Không thể tạo bài học: $e');
    }
  }

  // Cập nhật bài học
  Future<void> updateLesson(String id, Lesson lesson) async {
    try {
      print('=== Debug Permission Info ===');
      print('Lesson ID: $id');
      print('Classroom ID: ${lesson.classroomId}');
      print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');
      
      // Check if user is authenticated
      final isAuth = FirebaseAuth.instance.currentUser != null;
      print('Is authenticated: $isAuth');
      
      // Check if course is closed
      final classroomDoc = await _firestore.collection('classrooms').doc(lesson.classroomId).get();
      final courseId = classroomDoc.data()?['courseId'];
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      final isClosed = courseDoc.data()?['isClosed'] == true;
      print('Is course closed: $isClosed');
      
      // Check if user is teacher
      final isTeacher = classroomDoc.data()?['teacherId'] == FirebaseAuth.instance.currentUser?.uid;
      print('Is teacher: $isTeacher');
      
      // Check if user is admin
      final userDoc = await _firestore.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get();
      final isAdmin = userDoc.data()?['roleId'] == 'admin';
      print('Is admin: $isAdmin');
      
      print('=== End Debug Info ===');
      
      await _lessonsCollection.doc(id).update(lesson.toMap());
    } catch (e) {
      print('Error updating lesson: $e');
      throw Exception('Không thể cập nhật bài học: $e');
    }
  }

  // Xóa bài học
  Future<void> deleteLesson(String id) async {
    try {
      await _lessonsCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting lesson: $e');
      throw Exception('Không thể xóa bài học: $e');
    }
  }

  // Phê duyệt bài học
  Future<void> approveLesson({
    required String lessonId, 
    required String adminId
  }) async {
    try {
      // Lấy bài học hiện tại
      final lesson = await getLessonById(lessonId);
      if (lesson == null) {
        throw Exception('Bài học không tồn tại');
      }
      
      // Cập nhật trạng thái phê duyệt
      final updatedLesson = lesson.updateApprovalStatus(
        status: ApprovalStatus.approved,
        adminId: adminId,
      );
      
      // Lưu lại bài học
      await updateLesson(lessonId, updatedLesson);
    } catch (e) {
      print('Error approving lesson: $e');
      throw Exception('Không thể phê duyệt bài học: $e');
    }
  }
  
  // Từ chối bài học
  Future<void> rejectLesson({
    required String lessonId, 
    required String adminId,
    required String reason
  }) async {
    try {
      // Lấy bài học hiện tại
      final lesson = await getLessonById(lessonId);
      if (lesson == null) {
        throw Exception('Bài học không tồn tại');
      }
      
      // Cập nhật trạng thái phê duyệt
      final updatedLesson = lesson.updateApprovalStatus(
        status: ApprovalStatus.rejected,
        adminId: adminId,
        reason: reason,
      );
      
      // Lưu lại bài học
      await updateLesson(lessonId, updatedLesson);
    } catch (e) {
      print('Error rejecting lesson: $e');
      throw Exception('Không thể từ chối bài học: $e');
    }
  }
  
  // Yêu cầu chỉnh sửa bài học
  Future<void> requestRevision({
    required String lessonId, 
    required String adminId,
    required String reason
  }) async {
    try {
      // Lấy bài học hiện tại
      final lesson = await getLessonById(lessonId);
      if (lesson == null) {
        throw Exception('Bài học không tồn tại');
      }
      
      // Cập nhật trạng thái phê duyệt
      final updatedLesson = lesson.updateApprovalStatus(
        status: ApprovalStatus.revising,
        adminId: adminId,
        reason: reason,
      );
      
      // Lưu lại bài học
      await updateLesson(lessonId, updatedLesson);
    } catch (e) {
      print('Error requesting revision: $e');
      throw Exception('Không thể yêu cầu chỉnh sửa bài học: $e');
    }
  }
  
  // Lấy lịch sử phê duyệt bài học với thông tin người duyệt
  Future<List<Map<String, dynamic>>> getApprovalHistoryWithUserInfo(String lessonId) async {
    try {
      // Lấy bài học
      final lesson = await getLessonById(lessonId);
      if (lesson == null) {
        throw Exception('Bài học không tồn tại');
      }
      
      // Lấy thông tin người duyệt cho từng lịch sử
      List<Map<String, dynamic>> historyWithUserInfo = [];
      
      for (var history in lesson.approvalHistory) {
        // Lấy thông tin người duyệt
        DocumentSnapshot userDoc = await _usersCollection.doc(history.adminId).get();
        String adminName = 'Người dùng không xác định';
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          adminName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}';
        }
        
        historyWithUserInfo.add({
          'status': history.status,
          'adminId': history.adminId,
          'adminName': adminName,
          'reason': history.reason,
          'timestamp': history.timestamp,
        });
      }
      
      return historyWithUserInfo;
    } catch (e) {
      print('Error getting approval history: $e');
      throw Exception('Không thể lấy lịch sử phê duyệt: $e');
    }
  }
  
  // Kiểm tra người dùng có quyền Quản trị viên không
  Future<bool> isAdmin(String userId) async {
    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        return false;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final roles = List<String>.from(userData['roles'] ?? []);
      
      return roles.contains('admin');
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Thêm thư mục vào bài học
  Future<void> addFolderToLesson(String lessonId, LessonFolder folder) async {
    try {
      // Lấy bài học hiện tại
      final lessonDoc = await _lessonsCollection.doc(lessonId).get();
      if (!lessonDoc.exists) {
        throw Exception('Bài học không tồn tại');
      }

      final lessonData = lessonDoc.data() as Map<String, dynamic>;
      List<dynamic> folderList = lessonData['folders'] ?? [];
      
      // Tạo order index mới bằng cách lấy số lượng folder hiện có
      final newFolder = folder.copyWith(orderIndex: folderList.length);
      
      // Thêm folder mới vào danh sách
      folderList.add(newFolder.toMap());
      
      // Cập nhật bài học
      await _lessonsCollection.doc(lessonId).update({
        'folders': folderList,
        'updatedAt': Timestamp.now(),
        'approvalStatus': 'pending', // Đặt lại trạng thái chờ duyệt khi có thay đổi
      });
    } catch (e) {
      print('Error adding folder to lesson: $e');
      throw Exception('Không thể thêm thư mục vào bài học: $e');
    }
  }

  // Cập nhật thư mục trong bài học
  Future<void> updateFolderInLesson(String lessonId, int folderIndex, LessonFolder updatedFolder) async {
    try {
      // Lấy bài học hiện tại
      final lessonDoc = await _lessonsCollection.doc(lessonId).get();
      if (!lessonDoc.exists) {
        throw Exception('Bài học không tồn tại');
      }

      final lessonData = lessonDoc.data() as Map<String, dynamic>;
      List<dynamic> folderList = List.from(lessonData['folders'] ?? []);
      
      if (folderIndex < 0 || folderIndex >= folderList.length) {
        throw Exception('Chỉ số thư mục không hợp lệ');
      }
      
      // Cập nhật folder ở vị trí folderIndex
      folderList[folderIndex] = updatedFolder.toMap();
      
      // Cập nhật bài học
      await _lessonsCollection.doc(lessonId).update({
        'folders': folderList,
        'updatedAt': Timestamp.now(),
        'approvalStatus': 'pending', // Đặt lại trạng thái chờ duyệt khi có thay đổi
      });
    } catch (e) {
      print('Error updating folder in lesson: $e');
      throw Exception('Không thể cập nhật thư mục trong bài học: $e');
    }
  }

  // Xóa thư mục khỏi bài học
  Future<void> deleteFolderFromLesson(String lessonId, int folderIndex) async {
    try {
      // Lấy bài học hiện tại
      final lessonDoc = await _lessonsCollection.doc(lessonId).get();
      if (!lessonDoc.exists) {
        throw Exception('Bài học không tồn tại');
      }

      final lessonData = lessonDoc.data() as Map<String, dynamic>;
      List<dynamic> folderList = List.from(lessonData['folders'] ?? []);
      
      if (folderIndex < 0 || folderIndex >= folderList.length) {
        throw Exception('Chỉ số thư mục không hợp lệ');
      }
      
      // Xóa folder ở vị trí folderIndex
      folderList.removeAt(folderIndex);
      
      // Cập nhật lại order index cho các folder còn lại
      for (int i = 0; i < folderList.length; i++) {
        Map<String, dynamic> folder = folderList[i];
        folder['orderIndex'] = i;
        folderList[i] = folder;
      }
      
      // Cập nhật bài học
      await _lessonsCollection.doc(lessonId).update({
        'folders': folderList,
        'updatedAt': Timestamp.now(),
        'approvalStatus': 'pending', // Đặt lại trạng thái chờ duyệt khi có thay đổi
      });
    } catch (e) {
      print('Error deleting folder from lesson: $e');
      throw Exception('Không thể xóa thư mục khỏi bài học: $e');
    }
  }

  // Thêm item vào thư mục của bài học
  Future<void> addItemToFolder(String lessonId, int folderIndex, LessonItem item) async {
    try {
      // Lấy bài học hiện tại
      final lessonDoc = await _lessonsCollection.doc(lessonId).get();
      if (!lessonDoc.exists) {
        throw Exception('Bài học không tồn tại');
      }

      final lessonData = lessonDoc.data() as Map<String, dynamic>;
      List<dynamic> folderList = List.from(lessonData['folders'] ?? []);
      
      if (folderIndex < 0 || folderIndex >= folderList.length) {
        throw Exception('Chỉ số thư mục không hợp lệ');
      }
      
      Map<String, dynamic> folder = folderList[folderIndex];
      List<dynamic> itemList = List.from(folder['items'] ?? []);
      
      // Tạo order index mới cho item
      final newItem = item.copyWith(orderIndex: itemList.length);
      
      // Thêm item mới vào danh sách
      itemList.add(newItem.toMap());
      
      // Cập nhật folder
      folder['items'] = itemList;
      folderList[folderIndex] = folder;
      
      // Cập nhật bài học
      await _lessonsCollection.doc(lessonId).update({
        'folders': folderList,
        'updatedAt': Timestamp.now(),
        'approvalStatus': 'pending', // Đặt lại trạng thái chờ duyệt khi có thay đổi
      });
    } catch (e) {
      print('Error adding item to folder: $e');
      throw Exception('Không thể thêm nội dung vào thư mục: $e');
    }
  }

  // Cập nhật item trong thư mục
  Future<void> updateItemInFolder(String lessonId, int folderIndex, int itemIndex, LessonItem updatedItem) async {
    try {
      // Lấy bài học hiện tại
      final lessonDoc = await _lessonsCollection.doc(lessonId).get();
      if (!lessonDoc.exists) {
        throw Exception('Bài học không tồn tại');
      }

      final lessonData = lessonDoc.data() as Map<String, dynamic>;
      List<dynamic> folderList = List.from(lessonData['folders'] ?? []);
      
      if (folderIndex < 0 || folderIndex >= folderList.length) {
        throw Exception('Chỉ số thư mục không hợp lệ');
      }
      
      Map<String, dynamic> folder = folderList[folderIndex];
      List<dynamic> itemList = List.from(folder['items'] ?? []);
      
      if (itemIndex < 0 || itemIndex >= itemList.length) {
        throw Exception('Chỉ số nội dung không hợp lệ');
      }
      
      // Cập nhật item ở vị trí itemIndex
      itemList[itemIndex] = updatedItem.toMap();
      
      // Cập nhật folder
      folder['items'] = itemList;
      folderList[folderIndex] = folder;
      
      // Cập nhật bài học
      await _lessonsCollection.doc(lessonId).update({
        'folders': folderList,
        'updatedAt': Timestamp.now(),
        'approvalStatus': 'pending', // Đặt lại trạng thái chờ duyệt khi có thay đổi
      });
    } catch (e) {
      print('Error updating item in folder: $e');
      throw Exception('Không thể cập nhật nội dung trong thư mục: $e');
    }
  }

  // Xóa item khỏi thư mục
  Future<void> deleteItemFromFolder(String lessonId, int folderIndex, int itemIndex) async {
    try {
      // Lấy bài học hiện tại
      final lessonDoc = await _lessonsCollection.doc(lessonId).get();
      if (!lessonDoc.exists) {
        throw Exception('Bài học không tồn tại');
      }

      final lessonData = lessonDoc.data() as Map<String, dynamic>;
      List<dynamic> folderList = List.from(lessonData['folders'] ?? []);
      
      if (folderIndex < 0 || folderIndex >= folderList.length) {
        throw Exception('Chỉ số thư mục không hợp lệ');
      }
      
      Map<String, dynamic> folder = folderList[folderIndex];
      List<dynamic> itemList = List.from(folder['items'] ?? []);
      
      if (itemIndex < 0 || itemIndex >= itemList.length) {
        throw Exception('Chỉ số nội dung không hợp lệ');
      }
      
      // Xóa item ở vị trí itemIndex
      itemList.removeAt(itemIndex);
      
      // Cập nhật lại order index cho các item còn lại
      for (int i = 0; i < itemList.length; i++) {
        Map<String, dynamic> item = itemList[i];
        item['orderIndex'] = i;
        itemList[i] = item;
      }
      
      // Cập nhật folder
      folder['items'] = itemList;
      folderList[folderIndex] = folder;
      
      // Cập nhật bài học
      await _lessonsCollection.doc(lessonId).update({
        'folders': folderList,
        'updatedAt': Timestamp.now(),
        'approvalStatus': 'pending', // Đặt lại trạng thái chờ duyệt khi có thay đổi
      });
    } catch (e) {
      print('Error deleting item from folder: $e');
      throw Exception('Không thể xóa nội dung khỏi thư mục: $e');
    }
  }

  // Thêm flashcard vào bài học
  Future<void> addFlashcardToLesson(String lessonId, String flashcardId) async {
    try {
      final lesson = await getLessonById(lessonId);
      if (lesson == null) {
        throw Exception('Bài học không tồn tại');
      }
      
      if (lesson.flashcardIds.contains(flashcardId)) {
        return; // Flashcard đã tồn tại trong bài học
      }
      
      final updatedFlashcardIds = List<String>.from(lesson.flashcardIds)..add(flashcardId);
      
      await _lessonsCollection.doc(lessonId).update({
        'flashcardIds': updatedFlashcardIds,
        'updatedAt': Timestamp.now(),
        'approvalStatus': 'pending', // Đặt lại trạng thái chờ duyệt khi có thay đổi
      });
    } catch (e) {
      print('Error adding flashcard to lesson: $e');
      throw Exception('Không thể thêm flashcard vào bài học: $e');
    }
  }
  
  // Thêm bài tập vào bài học
  Future<void> addExerciseToLesson(String lessonId, String exerciseId) async {
    try {
      final lesson = await getLessonById(lessonId);
      if (lesson == null) {
        throw Exception('Bài học không tồn tại');
      }
      
      if (lesson.exerciseIds.contains(exerciseId)) {
        return; // Bài tập đã tồn tại trong bài học
      }
      
      final updatedExerciseIds = List<String>.from(lesson.exerciseIds)..add(exerciseId);
      
      await _lessonsCollection.doc(lessonId).update({
        'exerciseIds': updatedExerciseIds,
        'updatedAt': Timestamp.now(),
        'approvalStatus': 'pending', // Đặt lại trạng thái chờ duyệt khi có thay đổi
      });
    } catch (e) {
      print('Error adding exercise to lesson: $e');
      throw Exception('Không thể thêm bài tập vào bài học: $e');
    }
  }
  
  // Đánh dấu học sinh đã hoàn thành bài học
  Future<void> markLessonAsCompleted(String lessonId, String userId) async {
    try {
      final lesson = await getLessonById(lessonId);
      if (lesson == null) {
        throw Exception('Bài học không tồn tại');
      }
      
      if (lesson.completedBy.contains(userId)) {
        return; // Học sinh đã hoàn thành bài học này rồi
      }
      
      final updatedCompletedBy = List<String>.from(lesson.completedBy)..add(userId);
      
      await _lessonsCollection.doc(lessonId).update({
        'completedBy': updatedCompletedBy,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error marking lesson as completed: $e');
      throw Exception('Không thể đánh dấu bài học đã hoàn thành: $e');
    }
  }
  
  // Tạo hoặc cập nhật tiến trình học tập
  Future<void> updateLearningProgress({
    required String userId,
    required String lessonId,
    required String classroomId,
    bool videoWatched = false,
    bool flashcardViewed = false,
    bool exerciseDone = false,
    int score = 0,
    int timeSpentMinutes = 0,
  }) async {
    try {
      // Tìm tiến trình học tập hiện có
      final progressQuery = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where('lessonId', isEqualTo: lessonId)
          .where('classroomId', isEqualTo: classroomId)
          .limit(1)
          .get();
      
      // Tính toán số lượng thành phần và tiến trình
      int completedItems = 0;
      int totalItems = 0;
      
      // Kiểm tra video
      final lesson = await getLessonById(lessonId);
      if (lesson == null) {
        throw Exception('Bài học không tồn tại');
      }
      
      // Chỉ cho phép cập nhật tiến độ của bài học đã được duyệt
      if (lesson.approvalStatus != ApprovalStatus.approved) {
        throw Exception('Bài học chưa được duyệt, không thể cập nhật tiến độ');
      }
      
      final hasVideo = lesson.videos.isNotEmpty;
      final hasFlashcards = lesson.flashcardIds.isNotEmpty;
      final hasExercises = lesson.exerciseIds.isNotEmpty;
      
      if (hasVideo) totalItems++;
      if (hasFlashcards) totalItems++;
      if (hasExercises) totalItems++;
      
      if (hasVideo && videoWatched) completedItems++;
      if (hasFlashcards && flashcardViewed) completedItems++;
      if (hasExercises && exerciseDone) completedItems++;
      
      // Tính phần trăm hoàn thành
      final progressPercent = totalItems > 0 
          ? (completedItems / totalItems) * 100 
          : 0.0;
      
      // Xác định trạng thái
      ProgressStatus status = ProgressStatus.notStarted;
      if (completedItems > 0) {
        status = completedItems == totalItems 
            ? ProgressStatus.completed 
            : ProgressStatus.inProgress;
      }
      
      // Tạo map completedItemIds
      Map<String, bool> completedItemIds = {};
      if (hasVideo) completedItemIds['video'] = videoWatched;
      if (hasFlashcards) completedItemIds['flashcards'] = flashcardViewed;
      if (hasExercises) completedItemIds['exercises'] = exerciseDone;
      
      // Nếu đã có tiến trình, cập nhật, nếu không thì tạo mới
      if (progressQuery.docs.isNotEmpty) {
        final progressDoc = progressQuery.docs.first;
        final existingProgress = LearningProgress.fromMap(
          progressDoc.data() as Map<String, dynamic>, 
          progressDoc.id
        );
        
        // Giữ lại các ghi chú hiện có
        final existingNotes = existingProgress.notes;
        
        // Chỉ cập nhật điểm nếu có bài kiểm tra và điểm mới cao hơn
        final updatedScore = exerciseDone && score > existingProgress.score 
            ? score 
            : existingProgress.score;
        
        await _progressCollection.doc(progressDoc.id).update({
          'status': status.toString().split('.').last,
          'completedItems': completedItems,
          'totalItems': totalItems,
          'progressPercent': progressPercent,
          'timeSpentMinutes': existingProgress.timeSpentMinutes + timeSpentMinutes,
          'lastAccessTime': Timestamp.now(),
          'completedItemIds': completedItemIds,
          'score': updatedScore,
          'updatedAt': Timestamp.now(),
        });
      } else {
        // Tạo mới tiến trình học tập
        final progress = LearningProgress(
          userId: userId,
          lessonId: lessonId,
          classroomId: classroomId,
          status: status,
          completedItems: completedItems,
          totalItems: totalItems,
          progressPercent: progressPercent,
          timeSpentMinutes: timeSpentMinutes,
          lastAccessTime: DateTime.now(),
          completedItemIds: completedItemIds,
          score: score,
        );
        
        await _progressCollection.add(progress.toMap());
      }
      
      // Nếu hoàn thành tất cả, đánh dấu bài học đã hoàn thành
      if (status == ProgressStatus.completed) {
        await markLessonAsCompleted(lessonId, userId);
      }
    } catch (e) {
      print('Error updating learning progress: $e');
      throw Exception('Không thể cập nhật tiến trình học tập: $e');
    }
  }
  
  // Lấy tiến trình học tập của một học sinh trong một bài học
  Future<LearningProgress?> getLearningProgress(String userId, String lessonId, String classroomId) async {
    try {
      final progressQuery = await _progressCollection
          .where('userId', isEqualTo: userId)
          .where('lessonId', isEqualTo: lessonId)
          .where('classroomId', isEqualTo: classroomId)
          .limit(1)
          .get();
      
      if (progressQuery.docs.isEmpty) {
        return null;
      }
      
      final progressDoc = progressQuery.docs.first;
      return LearningProgress.fromMap(
        progressDoc.data() as Map<String, dynamic>, 
        progressDoc.id
      );
    } catch (e) {
      print('Error getting learning progress: $e');
      throw Exception('Không thể lấy tiến trình học tập: $e');
    }
  }
  
  // Lấy tiến trình học tập của tất cả học sinh trong một lớp học
  Future<List<LearningProgress>> getLearningProgressByClassroom(String classroomId) async {
    try {
      final progressQuery = await _progressCollection
          .where('classroomId', isEqualTo: classroomId)
          .get();
      
      return progressQuery.docs
          .map((doc) => LearningProgress.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting learning progress by classroom: $e');
      throw Exception('Không thể lấy tiến trình học tập của lớp học: $e');
    }
  }
  
  // Báo cáo nội dung bài học không phù hợp
  Future<void> reportInappropriateContent({
    required String lessonId,
    required String userId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('content_reports').add({
        'lessonId': lessonId,
        'userId': userId,
        'reason': reason,
        'status': 'pending', // pending, reviewed, dismissed
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error reporting inappropriate content: $e');
      throw Exception('Không thể báo cáo nội dung không phù hợp: $e');
    }
  }
  
  // Lấy danh sách báo cáo nội dung không phù hợp
  Future<List<Map<String, dynamic>>> getContentReports() async {
    try {
      final reportsQuery = await _firestore
          .collection('content_reports')
          .orderBy('createdAt', descending: true)
          .get();
          
      List<Map<String, dynamic>> reports = [];
      
      for (var doc in reportsQuery.docs) {
        final data = doc.data();
        
        // Lấy thông tin bài học
        final lessonDoc = await _lessonsCollection.doc(data['lessonId']).get();
        String lessonTitle = 'Bài học không tồn tại';
        
        if (lessonDoc.exists) {
          final lessonData = lessonDoc.data() as Map<String, dynamic>;
          lessonTitle = lessonData['title'] ?? 'Không có tiêu đề';
        }
        
        // Lấy thông tin người báo cáo
        final userDoc = await _usersCollection.doc(data['userId']).get();
        String userName = 'Người dùng không xác định';
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}';
        }
        
        reports.add({
          'id': doc.id,
          'lessonId': data['lessonId'],
          'lessonTitle': lessonTitle,
          'userId': data['userId'],
          'userName': userName,
          'reason': data['reason'],
          'status': data['status'],
          'createdAt': data['createdAt'],
        });
      }
      
      return reports;
    } catch (e) {
      print('Error getting content reports: $e');
      throw Exception('Không thể lấy danh sách báo cáo nội dung: $e');
    }
  }

  // Tạo bài học mới với các thư mục
  Future<String?> createLessonWithFolders({
    required String title,
    required String description,
    required String classroomId,
    required List<LessonFolder> folders,
    int orderIndex = 0,
    int estimatedMinutes = 0,
    bool isSample = false,
  }) async {
    try {
      final lesson = Lesson(
        title: title,
        description: description,
        classroomId: classroomId,
        orderIndex: orderIndex,
        estimatedMinutes: estimatedMinutes,
        folders: folders,
        approvalStatus: isSample ? ApprovalStatus.approved : ApprovalStatus.pending,
      );

      final docRef = await _lessonsCollection.add(lesson.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating lesson with folders: $e');
      throw Exception('Không thể tạo bài học: $e');
    }
  }

  // Thêm các bài học mẫu vào lớp học
  Future<void> addSampleLessons(String classroomId) async {
    try {
      // Bài học 1: Giới thiệu
      final lesson1Id = await createLessonWithFolders(
        title: 'Bài 1: Giới thiệu',
        description: 'Bài học giới thiệu về khóa học',
        classroomId: classroomId,
        orderIndex: 0,
        estimatedMinutes: 30,
        isSample: true,
        folders: [
          LessonFolder(
            title: 'Tài liệu học tập',
            description: 'Các tài liệu cần thiết cho bài học',
            orderIndex: 0,
            items: [
              LessonItem(
                title: 'Giới thiệu về khóa học',
                type: LessonItemType.document,
                content: 'Nội dung giới thiệu về khóa học và mục tiêu cần đạt được',
              ),
              LessonItem(
                title: 'Hướng dẫn học tập',
                type: LessonItemType.document,
                content: 'Cách thức học tập hiệu quả và sử dụng tài liệu',
              ),
            ],
          ),
        ],
      );

      // Thêm video cho bài 1
      if (lesson1Id != null) {
        final video1 = VideoItem(
          url: 'https://www.youtube.com/watch?v=V6D0R1Amq7w&t=1012s',
          title: 'Video giới thiệu khóa học',
          description: 'Video giới thiệu tổng quan về khóa học và cách học',
        );

        await _lessonsCollection.doc(lesson1Id).update({
          'videoItems': FieldValue.arrayUnion([video1.toMap()]),
        });
      }

      // Bài học 2: Ngữ pháp cơ bản
      final lesson2Id = await createLessonWithFolders(
        title: 'Bài 2: Ngữ pháp cơ bản',
        description: 'Các điểm ngữ pháp cơ bản',
        classroomId: classroomId,
        orderIndex: 1,
        estimatedMinutes: 45,
        isSample: true,
        folders: [
          LessonFolder(
            title: 'Lý thuyết',
            description: 'Phần lý thuyết về ngữ pháp',
            orderIndex: 0,
            items: [
              LessonItem(
                title: 'Thì hiện tại đơn',
                type: LessonItemType.document,
                content: 'Cách sử dụng và cấu trúc của thì hiện tại đơn',
              ),
              LessonItem(
                title: 'Thì hiện tại tiếp diễn',
                type: LessonItemType.document,
                content: 'Cách sử dụng và cấu trúc của thì hiện tại tiếp diễn',
              ),
            ],
          ),
        ],
      );

      // Thêm video và flashcard cho bài 2
      if (lesson2Id != null) {
        // Thêm video
        final video2 = VideoItem(
          url: 'https://www.youtube.com/watch?v=V6D0R1Amq7w&t=1012s',
          title: 'Bài giảng thì hiện tại đơn',
          description: 'Video giảng dạy về thì hiện tại đơn',
        );

        await _lessonsCollection.doc(lesson2Id).update({
          'videoItems': FieldValue.arrayUnion([video2.toMap()]),
        });

        // Thêm flashcard
        final flashcardId = await _createSampleFlashcard(
          lesson2Id,
          classroomId,
          'Flashcard thì hiện tại đơn',
          'Các ví dụ về thì hiện tại đơn',
          [
            {'question': 'I ___ (go) to school every day', 'answer': 'go'},
            {'question': 'She ___ (study) English twice a week', 'answer': 'studies'},
            {'question': 'They ___ (play) football on Sunday', 'answer': 'play'},
          ],
        );

        // Thêm exercise
        final exerciseId = await _createSampleExercise(
          lesson2Id,
          classroomId,
          'Bài tập thì hiện tại đơn',
          'Các bài tập thực hành về thì hiện tại đơn',
          [
            Question(
              id: '1',
              content: 'He ___ (work) in a bank',
              type: QuestionType.fillInBlank,
              points: 1,
              acceptableAnswers: ['works'],
            ),
            Question(
              id: '2',
              content: 'What is the correct form: "She ___ tennis every weekend"',
              type: QuestionType.multipleChoice,
              points: 1,
              choices: [
                Choice(id: '1', content: 'play', isCorrect: false),
                Choice(id: '2', content: 'plays', isCorrect: true),
                Choice(id: '3', content: 'playing', isCorrect: false),
              ],
            ),
          ],
        );

        // Cập nhật lesson với flashcard và exercise IDs
        await _lessonsCollection.doc(lesson2Id).update({
          'flashcardIds': FieldValue.arrayUnion([flashcardId]),
          'exerciseIds': FieldValue.arrayUnion([exerciseId]),
        });
      }

      // Bài học 3: Từ vựng chủ đề gia đình
      final lesson3Id = await createLessonWithFolders(
        title: 'Bài 3: Từ vựng chủ đề gia đình',
        description: 'Học từ vựng về chủ đề gia đình',
        classroomId: classroomId,
        orderIndex: 2,
        estimatedMinutes: 40,
        isSample: true,
        folders: [
          LessonFolder(
            title: 'Từ vựng',
            description: 'Danh sách từ vựng về gia đình',
            orderIndex: 0,
            items: [
              LessonItem(
                title: 'Các thành viên trong gia đình',
                type: LessonItemType.vocabulary,
                content: 'Từ vựng về các thành viên trong gia đình',
              ),
            ],
          ),
        ],
      );

      // Thêm video và flashcard cho bài 3
      if (lesson3Id != null) {
        // Thêm video
        final video3 = VideoItem(
          url: 'https://www.youtube.com/watch?v=V6D0R1Amq7w&t=1012s',
          title: 'Từ vựng về gia đình',
          description: 'Video học từ vựng chủ đề gia đình',
        );

        await _lessonsCollection.doc(lesson3Id).update({
          'videoItems': FieldValue.arrayUnion([video3.toMap()]),
        });

        // Thêm flashcard
        final flashcardId = await _createSampleFlashcard(
          lesson3Id,
          classroomId,
          'Flashcard từ vựng gia đình',
          'Các từ vựng về gia đình',
          [
            {'question': 'father', 'answer': 'bố'},
            {'question': 'mother', 'answer': 'mẹ'},
            {'question': 'sister', 'answer': 'chị/em gái'},
            {'question': 'brother', 'answer': 'anh/em trai'},
          ],
        );

        // Thêm exercise
        final exerciseId = await _createSampleExercise(
          lesson3Id,
          classroomId,
          'Bài tập từ vựng gia đình',
          'Các bài tập thực hành từ vựng về gia đình',
          [
            Question(
              id: '1',
              content: 'What is the meaning of "grandfather"?',
              type: QuestionType.multipleChoice,
              points: 1,
              choices: [
                Choice(id: '1', content: 'ông nội/ngoại', isCorrect: true),
                Choice(id: '2', content: 'bà nội/ngoại', isCorrect: false),
                Choice(id: '3', content: 'cô/dì', isCorrect: false),
              ],
            ),
            Question(
              id: '2',
              content: 'Choose the correct translation for "aunt"',
              type: QuestionType.multipleChoice,
              points: 1,
              choices: [
                Choice(id: '1', content: 'chú/bác', isCorrect: false),
                Choice(id: '2', content: 'cô/dì', isCorrect: true),
                Choice(id: '3', content: 'anh/em trai', isCorrect: false),
              ],
            ),
          ],
        );

        // Cập nhật lesson với flashcard và exercise IDs
        await _lessonsCollection.doc(lesson3Id).update({
          'flashcardIds': FieldValue.arrayUnion([flashcardId]),
          'exerciseIds': FieldValue.arrayUnion([exerciseId]),
        });
      }

    } catch (e) {
      print('Error adding sample lessons: $e');
      throw Exception('Không thể thêm bài học mẫu: $e');
    }
  }

  // Helper function to create sample flashcards
  Future<String> _createSampleFlashcard(String lessonId, String classroomId, String title, String description, List<Map<String, String>> items) async {
    final flashcardService = FlashcardService();
    final flashcard = await flashcardService.createFlashcard(
      Flashcard(
        title: title,
        description: description,
        userId: 'system',
        lessonId: lessonId,
        classroomId: classroomId,
        isPublic: true,
      ),
    );

    if (flashcard != null) {
      // Add flashcard items
      for (var item in items) {
        await flashcardService.createFlashcardItem(
          FlashcardItem(
            flashcardId: flashcard,
            question: item['question']!,
            answer: item['answer']!,
          ),
        );
      }
      return flashcard;
    }
    throw Exception('Failed to create sample flashcard');
  }

  // Helper function to create sample exercise
  Future<String> _createSampleExercise(String lessonId, String classroomId, String title, String description, List<Question> questions) async {
    final exerciseService = ExerciseService();
    
    // Create the exercise first
    final exercise = await exerciseService.createExercise(
      title: title,
      description: description,
      lessonId: lessonId,
      classroomId: classroomId,
      questions: questions,
      difficultyMatrix: const DifficultyMatrix(),
      timeLimit: 300, // 5 minutes
      attemptsAllowed: 3,
      visibility: true,
      createdBy: 'system',
    );

    if (exercise != null) {
      // Save questions to exercise_questions collection
      final batch = FirebaseFirestore.instance.batch();
      
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        final choices = question.choices ?? [];
        final questionData = {
          'exerciseId': exercise.id,
          'questionText': question.content,
          'options': choices.map((c) => c.content).toList(),
          'correctOptionIndex': choices.indexWhere((c) => c.isCorrect),
          'explanation': question.explanation,
          'orderIndex': i,
          'points': question.points,
          'createdAt': Timestamp.now(),
        };
        
        final questionRef = FirebaseFirestore.instance.collection('exercise_questions').doc();
        batch.set(questionRef, questionData);
      }
      
      await batch.commit();
      return exercise.id!;
    }
    throw Exception('Failed to create sample exercise');
  }

  // Helper function to create sample video
  Future<VideoItem> _createSampleVideo(String title, String description, String url) async {
    return VideoItem(
      url: url,
      title: title,
      description: description,
      createdAt: Timestamp.now(),
    );
  }
} 