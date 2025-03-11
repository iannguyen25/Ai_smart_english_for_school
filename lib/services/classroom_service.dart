import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/classroom.dart';
import 'storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  Future<String> createClassroom({
    required String name,
    required String description,
    required String teacherId,
    String? coverImage,
    bool isPublic = false,
  }) async {
    try {
      final inviteCode = _generateInviteCode();

      final classroom = Classroom(
        name: name,
        description: description,
        teacherId: teacherId,
        memberIds: [teacherId], // Tự động thêm giáo viên vào danh sách thành viên
        coverImage: coverImage,
        inviteCode: inviteCode,
        isPublic: isPublic,
      );

      final docRef = await _classroomsRef.add(classroom.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating classroom: $e');
      throw 'Không thể tạo lớp học';
    }
  }

  // Cập nhật thông tin lớp học
  Future<void> updateClassroom(Classroom classroom) async {
    try {
      await _classroomsRef.doc(classroom.id).update({
        'name': classroom.name,
        'description': classroom.description,
        'coverImage': classroom.coverImage,
        'isPublic': classroom.isPublic,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating classroom: $e');
      throw 'Không thể cập nhật lớp học';
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
      final snapshot = await _classroomsRef
          .where('memberIds', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Classroom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
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
      Query classroomsQuery = _classroomsRef;

      // Nếu có userId, lấy các lớp công khai và lớp mà user là thành viên
      if (userId != null) {
        classroomsQuery = classroomsQuery.where(Filter.or(
          Filter('isPublic', isEqualTo: true),
          Filter('memberIds', arrayContains: userId),
        ));
      } else {
        // Nếu không có userId, chỉ lấy lớp công khai
        classroomsQuery = classroomsQuery.where('isPublic', isEqualTo: true);
      }

      final snapshot = await classroomsQuery.get();

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
  Future<Classroom> getClassroomById(String classroomId) async {
    try {
      final doc = await _classroomsRef.doc(classroomId).get();

      if (!doc.exists) {
        throw 'Không tìm thấy lớp học';
      }

      return Classroom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error getting classroom: $e');
      throw 'Không thể tải thông tin lớp học';
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
  Future<void> approveMember(String classroomId, String userId) async {
    try {
      final doc = await _firestore.collection('classrooms').doc(classroomId).get();
      if (!doc.exists) throw 'Lớp học không tồn tại';

      await doc.reference.update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'pendingMemberIds': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print('Error approving member: $e');
      rethrow;
    }
  }

  // Thêm phương thức để giáo viên từ chối yêu cầu
  Future<void> rejectMember(String classroomId, String userId) async {
    try {
      final doc = await _firestore.collection('classrooms').doc(classroomId).get();
      if (!doc.exists) throw 'Lớp học không tồn tại';

      await doc.reference.update({
        'pendingMemberIds': FieldValue.arrayRemove([userId])
      });
    } catch (e) {
      print('Error rejecting member: $e');
      rethrow;
    }
  }
}