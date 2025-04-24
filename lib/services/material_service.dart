import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../models/learning_material.dart';
import '../models/app_user.dart';
import 'auth_service.dart';

class MaterialService {
  // Singleton pattern
  static final MaterialService _instance = MaterialService._internal();
  factory MaterialService() => _instance;
  MaterialService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService();

  // Collection references
  CollectionReference get _materialsCollection => _firestore.collection('materials');

  // Lấy danh sách tài liệu của người dùng hiện tại
  Stream<List<LearningMaterial>> getUserMaterials() {
    String? userId = _authService.currentUser?.id;
    if (userId == null) return Stream.value([]);

    return _materialsCollection
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LearningMaterial.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Lấy danh sách tài liệu công khai
  Stream<List<LearningMaterial>> getPublicMaterials() {
    return _materialsCollection
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LearningMaterial.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Lấy chi tiết tài liệu từ ID
  Future<LearningMaterial?> getMaterialById(String id) async {
    try {
      DocumentSnapshot doc = await _materialsCollection.doc(id).get();
      if (doc.exists) {
        return LearningMaterial.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting material: $e');
      return null;
    }
  }

  // Tạo tài liệu mới
  Future<void> createMaterial(LearningMaterial material) async {
    try {
      await _materialsCollection.add(material.toMap());
    } catch (e) {
      print('Error creating material: $e');
      throw Exception('Không thể tạo tài liệu: $e');
    }
  }

  // Cập nhật tài liệu
  Future<void> updateMaterial(String id, LearningMaterial material) async {
    try {
      await _materialsCollection.doc(id).update(material.toMap());
    } catch (e) {
      print('Error updating material: $e');
      throw Exception('Không thể cập nhật tài liệu: $e');
    }
  }

  // Xóa tài liệu
  Future<void> deleteMaterial(String id) async {
    try {
      // Lấy thông tin tài liệu để xóa file nếu có
      DocumentSnapshot doc = await _materialsCollection.doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Xóa file từ storage nếu có
        if (data.containsKey('fileUrl') && data['fileUrl'] != null) {
          String fileUrl = data['fileUrl'];
          if (fileUrl.contains('firebase')) {
            try {
              // Lấy reference từ URL
              Reference ref = _storage.refFromURL(fileUrl);
              await ref.delete();
            } catch (e) {
              print('Error deleting file from storage: $e');
              // Tiếp tục xóa tài liệu ngay cả khi không xóa được file
            }
          }
        }
      }
      
      // Xóa document
      await _materialsCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting material: $e');
      throw Exception('Không thể xóa tài liệu: $e');
    }
  }

  // Tải lên file và trả về URL
  Future<String> uploadFile(File file, String fileName) async {
    try {
      String? userId = _authService.currentUser?.id;
      if (userId == null) throw Exception('Người dùng chưa đăng nhập');
      
      // Tạo reference cho file
      String path = 'materials/$userId/$fileName';
      Reference ref = _storage.ref().child(path);
      
      // Tải lên file
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      
      // Lấy URL tải xuống
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Không thể tải lên tệp: $e');
    }
  }

  // Tăng số lượt tải của tài liệu
  Future<void> incrementDownloadCount(String id) async {
    try {
      await _materialsCollection.doc(id).update({
        'downloads': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing download count: $e');
      // Không ném lỗi, chỉ ghi log
    }
  }

  // Tìm kiếm tài liệu
  Future<List<LearningMaterial>> searchMaterials(String query, {bool publicOnly = true}) async {
    try {
      // Chuyển query thành lowercase để tìm kiếm không phân biệt hoa thường
      query = query.toLowerCase();
      
      // Lấy danh sách tài liệu
      QuerySnapshot snapshot;
      
      if (publicOnly) {
        snapshot = await _materialsCollection
            .where('isPublic', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();
      } else {
        // Lấy cả tài liệu cá nhân của người dùng
        String? userId = _authService.currentUser?.id;
        if (userId == null) {
          snapshot = await _materialsCollection
              .where('isPublic', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .get();
        } else {
          // Không thể thực hiện OR query trực tiếp trong Firestore,
          // nên phải lấy toàn bộ và lọc thủ công
          snapshot = await _materialsCollection
              .orderBy('createdAt', descending: true)
              .get();
        }
      }
      
      // Lọc kết quả theo query
      List<LearningMaterial> materials = snapshot.docs
          .map((doc) => LearningMaterial.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((material) {
            // Kiểm tra xem tài liệu có phù hợp với query không
            bool matchesQuery = material.title.toLowerCase().contains(query) ||
                material.description.toLowerCase().contains(query) ||
                material.tags.any((tag) => tag.toLowerCase().contains(query));
            
            // Kiểm tra quyền truy cập
            if (publicOnly) {
              return matchesQuery && material.isPublic;
            } else {
              String? userId = _authService.currentUser?.id;
              return matchesQuery && (material.isPublic || material.authorId == userId);
            }
          })
          .toList();
      
      return materials;
    } catch (e) {
      print('Error searching materials: $e');
      return [];
    }
  }

  // Kiểm tra người dùng có quyền xem tài liệu không
  Future<bool> canUserAccessMaterial({
    required String materialId,
    required User user,
  }) async {
    try {
      final docSnapshot = await _firestore.collection('learningMaterials').doc(materialId).get();
      if (!docSnapshot.exists) {
        return false;
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      
      // Kiểm tra xem tài liệu có thuộc lớp học không
      final classroomId = data['classroomId'];
      if (classroomId != null && classroomId.isNotEmpty) {
        // Nếu là tác giả hoặc admin, luôn cho phép
        if (data['authorId'] == user.id || user.roleId == 'admin') {
          return true;
        }
        
        // Kiểm tra xem user có thuộc lớp học này không
        final classroomUserRef = _firestore
            .collection('classrooms')
            .doc(classroomId)
            .collection('users')
            .doc(user.id);
            
        final isClassroomMember = await classroomUserRef.get().then((doc) => doc.exists);
        
        if (!isClassroomMember) {
          return false;
        }
      }
      
      // Kiểm tra vai trò người dùng có được phép không
      final allowedRoles = List<String>.from(data['allowedRoles'] ?? ['admin', 'teacher', 'student']);
      if (!allowedRoles.contains(user.roleId)) {
        return false;
      }
      
      // Kiểm tra tài liệu có công khai không
      final isPublic = data['isPublic'] ?? false;
      if (isPublic) {
        return true;
      }
      
      // Tác giả luôn có quyền truy cập
      if (data['authorId'] == user.id) {
        return true;
      }
      
      // Admin luôn có quyền truy cập
      if (user.roleId == 'admin') {
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error checking access permission: $e');
      return false;
    }
  }
} 