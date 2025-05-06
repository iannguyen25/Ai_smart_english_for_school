import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/classroom.dart';
import 'storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course.dart';
import '../services/auth_service.dart';

class ClassroomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  CollectionReference get _classroomsRef => _firestore.collection('classrooms');

  // Tạo mã mời ngẫu nhiên
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // Tạo lớp học mới
  Future<String?> createClassroom(Classroom classroom) async {
    try {
      // Tạo lớp học
      final docRef = await _classroomsRef.add(classroom.toMap());
      
      // Nếu có courseId, sao chép học liệu từ khóa học
      if (classroom.courseId != null) {
        await copyCourseContentToClassroom(classroom.courseId!, docRef.id);
      }
      
      return docRef.id;
    } catch (e) {
      print('Error creating classroom: $e');
      return null;
    }
  }

  // Cập nhật thông tin lớp học
  Future<bool> updateClassroom(Classroom classroom) async {
    try {
      if (classroom.id == null) return false;
      
      await _classroomsRef.doc(classroom.id).update(classroom.toMap());
      return true;
    } catch (e) {
      print('Error updating classroom: $e');
      return false;
    }
  }

  // Thêm thành viên vào lớp
  Future<void> addMember(String classroomId, String userId) async {
    try {
      await _classroomsRef.doc(classroomId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error adding member: $e');
      throw 'Không thể thêm thành viên';
    }
  }

  // Xóa thành viên khỏi lớp
  Future<void> removeMember(String classroomId, String userId) async {
    try {
      final doc = await _classroomsRef.doc(classroomId).get();
      final classroom = Classroom.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Không cho phép xóa giáo viên
      if (userId == classroom.teacherId) {
        throw 'Không thể xóa giáo viên khỏi lớp';
      }

      await _classroomsRef.doc(classroomId).update({
        'memberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error removing member: $e');
      throw 'Không thể xóa thành viên';
    }
  }

  // Tham gia lớp bằng mã mời
  Future<void> joinClassroomByCode(String inviteCode, String userId) async {
    try {
      if (userId.isEmpty) throw 'Vui lòng đăng nhập';

      final code = inviteCode.trim().toUpperCase();
      print('Searching for classroom with invite code: $code');

      final querySnapshot = await _firestore
          .collection('classrooms')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'Mã mời không hợp lệ hoặc đã hết hạn';
      }

      final classroomDoc = querySnapshot.docs.first;
      final classroomData = classroomDoc.data();
      print('Found classroom: ${classroomData['name']}');

      // Kiểm tra xem đã là thành viên
      final memberIds = List<String>.from(classroomData['memberIds'] ?? []);
      if (memberIds.contains(userId)) {
        throw 'Bạn đã là thành viên của lớp học này';
      }

      // Nếu lớp công khai, thêm vào memberIds
      if (classroomData['isPublic'] == true) {
        print('Public classroom - adding member directly');
        await classroomDoc.reference.update({
          'memberIds': FieldValue.arrayUnion([userId])
        });
        return;
      }

      // Nếu lớp private, thêm vào pendingMemberIds
      print('Private classroom - adding to pending list');
      await classroomDoc.reference.update({
        'pendingMemberIds': FieldValue.arrayUnion([userId])
      });

      throw 'Yêu cầu tham gia đã được gửi. Vui lòng chờ giáo viên phê duyệt.';
    } catch (e) {
      print('Error joining classroom by code: $e');
      if (e is String) {
        rethrow;
      }
      throw 'Có lỗi xảy ra. Vui lòng thử lại sau.';
    }
  }

  // Lấy danh sách lớp học của một người dùng
  Future<List<Classroom>> getUserClassrooms(String userId) async {
    try {
      print('Getting classrooms for user: $userId');
      
      final authService = AuthService();
      final isAdmin = authService.isCurrentUserAdmin;
      print('Is admin: $isAdmin');

      if (isAdmin) {
        print('User is admin, getting all classrooms');
        final snapshot = await _classroomsRef.get();
        return snapshot.docs.map((doc) => Classroom.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      } else {
        print('User is not admin, getting teaching and learning classrooms');
        // Lấy lớp học mà user là giáo viên
        final teachingSnapshot = await _classroomsRef
            .where('teacherId', isEqualTo: userId)
            .get();
            
        // Lấy lớp học mà user là thành viên
        final learningSnapshot = await _classroomsRef
            .where('memberIds', arrayContains: userId)
            .get();
            
        // Gộp kết quả và loại bỏ trùng lặp
        final teachingClassrooms = teachingSnapshot.docs.map((doc) => Classroom.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        final learningClassrooms = learningSnapshot.docs.map((doc) => Classroom.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        
        // Loại bỏ các lớp học trùng lặp (nếu user vừa là giáo viên vừa là thành viên)
        final allClassrooms = [...teachingClassrooms];
        for (var classroom in learningClassrooms) {
          if (!allClassrooms.any((c) => c.id == classroom.id)) {
            allClassrooms.add(classroom);
          }
        }
        
        // Sắp xếp theo updatedAt giảm dần
        allClassrooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        
        return allClassrooms;
      }
    } catch (e) {
      print('Error getting user classrooms: $e');
      throw 'Không thể tải danh sách lớp học';
    }
  }

  // Tìm kiếm lớp học
  Future<List<Classroom>> searchClassrooms({
    required String query,
    String? userId,
  }) async {
    try {
      print('Searching classrooms with query: $query for user: $userId');
      
      final authService = AuthService();
      final isAdmin = authService.isCurrentUserAdmin;
      print('Is admin: $isAdmin');

      Query classroomsQuery = _classroomsRef;

      if (isAdmin) {
        print('User is admin, searching all classrooms');
        // Admin có thể tìm kiếm tất cả lớp học
      } else if (userId != null) {
        print('User is not admin, searching only accessible classrooms');
        // Nếu không phải admin, chỉ tìm trong các lớp:
        // 1. Lớp mà user là giáo viên
        // 2. Lớp mà user là thành viên
        // 3. Lớp công khai
        classroomsQuery = classroomsQuery.where(Filter.or(
          Filter('teacherId', isEqualTo: userId),
          Filter('memberIds', arrayContains: userId),
          // Filter('isPublic', isEqualTo: true),
        ));
      } else {
        print('No user ID, searching only public classrooms');
        // Nếu không có userId, chỉ tìm lớp công khai
        classroomsQuery = classroomsQuery.where('isPublic', isEqualTo: true);
      }

      final snapshot = await classroomsQuery.get();
      print('Found ${snapshot.docs.length} classrooms before filtering');

      // Lọc kết quả theo query
      final results = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] as String).toLowerCase();
        final description = (data['description'] as String).toLowerCase();
        final searchQuery = query.toLowerCase();

        return name.contains(searchQuery) || description.contains(searchQuery);
      }).map((doc) {
        return Classroom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      print('Found ${results.length} classrooms after filtering');
      return results;
    } catch (e) {
      print('Error searching classrooms: $e');
      throw 'Không thể tìm kiếm lớp học';
    }
  }

  // Xóa lớp học
  Future<void> deleteClassroom(String classroomId) async {
    try {
      final doc = await _classroomsRef.doc(classroomId).get();
      if (!doc.exists) return;

      final classroom = Classroom.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Xóa ảnh bìa nếu có
      if (classroom.coverImage != null) {
        await _storageService.deleteFile(classroom.coverImage!);
      }

      await doc.reference.delete();
    } catch (e) {
      print('Error deleting classroom: $e');
      throw 'Không thể xóa lớp học';
    }
  }

  // Lấy thông tin lớp học theo ID
  Future<Classroom?> getClassroom(String classroomId) async {
    try {
      final doc = await _classroomsRef.doc(classroomId).get();
      if (doc.exists) {
        return Classroom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting classroom: $e');
      return null;
    }
  }

  Future<void> joinClassroom(String classroomId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'Vui lòng đăng nhập';

      // Lấy thông tin lớp học
      final classroomDoc = await _firestore.collection('classrooms').doc(classroomId).get();
      if (!classroomDoc.exists) {
        throw 'Lớp học không tồn tại';
      }

      final classroomData = classroomDoc.data()!;

      // Kiểm tra xem đã là thành viên chưa
      if ((classroomData['memberIds'] as List).contains(userId)) {
        throw 'Bạn đã là thành viên của lớp học này';
      }

      // Cập nhật danh sách thành viên
      await _firestore.collection('classrooms').doc(classroomId).update({
        'memberIds': FieldValue.arrayUnion([userId])
      });
    } catch (e) {
      print('Error joining classroom: $e');
      rethrow;
    }
  }

  Future<void> leaveClassroom(String classroomId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'Vui lòng đăng nhập';

      final classroomDoc = await _firestore.collection('classrooms').doc(classroomId).get();
      if (!classroomDoc.exists) {
        throw 'Lớp học không tồn tại';
      }

      // Không cho phép giáo viên rời lớp
      if (classroomDoc.data()!['teacherId'] == userId) {
        throw 'Giáo viên không thể rời lớp học';
      }

      await _firestore.collection('classrooms').doc(classroomId).update({
        'memberIds': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      print('Error leaving classroom: $e');
      rethrow;
    }
  }

  // Thêm phương thức tạo mã mời mới
  Future<String> generateInviteCode(String classroomId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw 'Vui lòng đăng nhập';

      // Lấy thông tin lớp học
      final doc = await _firestore.collection('classrooms').doc(classroomId).get();
      if (!doc.exists) throw 'Lớp học không tồn tại';

      // Kiểm tra quyền (chỉ giáo viên mới được tạo mã mời)
      if (doc.data()!['teacherId'] != userId) {
        throw 'Bạn không có quyền tạo mã mời';
      }

      // Tạo mã mời ngẫu nhiên 6 ký tự
      final random = Random();
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final code = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();

      // Cập nhật mã mời mới
      await doc.reference.update({
        'inviteCode': code,
      });

      return code;
    } catch (e) {
      print('Error generating invite code: $e');
      rethrow;
    }
  }

  // Thêm phương thức để giáo viên duyệt yêu cầu
  Future<bool> approveStudent(String classroomId, String userId) async {
    try {
      final classroom = await getClassroom(classroomId);
      if (classroom == null) return false;
      
      // Kiểm tra xem có trong danh sách chờ không
      if (!classroom.pendingMemberIds.contains(userId)) {
        return false;
      }
      
      // Cập nhật Firestore (atomic operation)
      await _firestore.collection('classrooms').doc(classroomId).update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'pendingMemberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });
      
      return true;
    } catch (e) {
      print('Error approving student: $e');
      return false;
    }
  }

  // Thêm phương thức để giáo viên từ chối yêu cầu
  Future<bool> rejectStudent(String classroomId, String userId) async {
    try {
      // Xóa khỏi danh sách chờ
      await _firestore.collection('classrooms').doc(classroomId).update({
        'pendingMemberIds': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });
      
      return true;
    } catch (e) {
      print('Error rejecting student: $e');
      return false;
    }
  }

  // Sao chép học liệu từ khóa học sang lớp học
  Future<bool> copyCourseContentToClassroom(String courseId, String classroomId) async {
    try {
      // Lấy thông tin khóa học
      final courseDoc = await _firestore.collection('courses').doc(courseId).get();
      if (!courseDoc.exists) return false;
      
      final course = Course.fromMap(courseDoc.data()!, courseId);
      
      // Sao chép bài học
      List<String> newLessonIds = [];
      if (course.materialIds.isNotEmpty) {
        // Lấy tất cả bài học từ khóa học
        final lessonSnapshot = await _firestore.collection('learning_materials')
            .where('id', whereIn: course.materialIds)
            .get();
            
        // Sao chép từng bài học
        for (var doc in lessonSnapshot.docs) {
          final lessonData = doc.data();
          lessonData['classroomId'] = classroomId;
          lessonData['isCustom'] = true;
          lessonData['createdAt'] = Timestamp.now();
          lessonData['updatedAt'] = Timestamp.now();
          
          // Tạo bài học mới
          final newLessonRef = await _firestore.collection('learning_materials').add(lessonData);
          newLessonIds.add(newLessonRef.id);
        }
      }
      
      // Sao chép bộ flashcard
      List<String> newFlashcardIds = [];
      if (course.templateFlashcardIds.isNotEmpty) {
        // Lấy tất cả flashcard từ khóa học
        final flashcardSnapshot = await _firestore.collection('flashcards')
            .where('id', whereIn: course.templateFlashcardIds)
            .get();
            
        // Sao chép từng flashcard
        for (var doc in flashcardSnapshot.docs) {
          final flashcardData = doc.data();
          flashcardData['classroomId'] = classroomId;
          flashcardData['isCustom'] = true;
          flashcardData['createdAt'] = Timestamp.now();
          flashcardData['updatedAt'] = Timestamp.now();
          
          // Tạo flashcard mới
          final newFlashcardRef = await _firestore.collection('flashcards').add(flashcardData);
          newFlashcardIds.add(newFlashcardRef.id);
        }
      }
      
      // Cập nhật lớp học với ID học liệu đã sao chép
      await _firestore.collection('classrooms').doc(classroomId).update({
        'customLessonIds': FieldValue.arrayUnion(newLessonIds),
        'customFlashcardIds': FieldValue.arrayUnion(newFlashcardIds),
        'updatedAt': Timestamp.now(),
      });
      
      return true;
    } catch (e) {
      print('Error copying course content: $e');
      return false;
    }
  }
}