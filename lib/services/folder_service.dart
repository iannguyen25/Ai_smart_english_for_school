import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/folder.dart';

class FolderService {
  final _db = FirebaseFirestore.instance;

  // Tạo thư mục mới
  Future<String> createFolder(Folder folder) async {
    try {
      final doc = await _db.collection('folders').add(folder.toMap());
      return doc.id;
    } catch (e) {
      print('Error creating folder: $e');
      rethrow;
    }
  }

  // Cập nhật thư mục
  Future<void> updateFolder(String folderId, Map<String, dynamic> data) async {
    try {
      await _db.collection('folders').doc(folderId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating folder: $e');
      rethrow;
    }
  }

  // Xóa thư mục
  Future<void> deleteFolder(String folderId) async {
    try {
      await _db.collection('folders').doc(folderId).delete();
    } catch (e) {
      print('Error deleting folder: $e');
      rethrow;
    }
  }

  // Lấy thư mục theo ID
  Future<Folder> getFolderById(String folderId) async {
    try {
      final doc = await _db.collection('folders').doc(folderId).get();
      if (!doc.exists) throw 'Thư mục không tồn tại';
      return Folder.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting folder: $e');
      rethrow;
    }
  }

  // Lấy danh sách thư mục của user
  Future<List<Folder>> getUserFolders(String userId) async {
    try {
      final snapshot = await _db
          .collection('folders')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Folder.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting user folders: $e');
      // Trả về list rỗng thay vì throw error
      return [];
    }
  }

  // Tìm kiếm thư mục
  Future<List<Folder>> searchFolders(String query) async {
    try {
      // Tìm theo tên hoặc mô tả
      final snapshot = await _db
          .collection('folders')
          .where('isPublic', isEqualTo: true)
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => Folder.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error searching folders: $e');
      rethrow;
    }
  }

  // Thêm flashcard vào thư mục
  Future<void> addFlashcardToFolder(String folderId, String flashcardId) async {
    try {
      await _db.collection('folders').doc(folderId).update({
        'flashcardIds': FieldValue.arrayUnion([flashcardId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding flashcard to folder: $e');
      rethrow;
    }
  }

  // Thêm video vào thư mục
  Future<void> addVideoToFolder(String folderId, String videoId) async {
    try {
      await _db.collection('folders').doc(folderId).update({
        'videoIds': FieldValue.arrayUnion([videoId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding video to folder: $e');
      rethrow;
    }
  }

  // Xóa flashcard khỏi thư mục
  Future<void> removeFlashcardFromFolder(String folderId, String flashcardId) async {
    try {
      await _db.collection('folders').doc(folderId).update({
        'flashcardIds': FieldValue.arrayRemove([flashcardId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing flashcard from folder: $e');
      rethrow;
    }
  }

  // Xóa video khỏi thư mục
  Future<void> removeVideoFromFolder(String folderId, String videoId) async {
    try {
      await _db.collection('folders').doc(folderId).update({
        'videoIds': FieldValue.arrayRemove([videoId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing video from folder: $e');
      rethrow;
    }
  }

  // Thêm flashcards vào folder
  Future<void> addFlashcardsToFolder(
    String folderId,
    List<String> flashcardIds,
  ) async {
    try {
      await _db.collection('folders').doc(folderId).update({
        'flashcardIds': FieldValue.arrayUnion(flashcardIds),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding flashcards to folder: $e');
      rethrow;
    }
  }

  // Thêm videos vào folder
  Future<void> addVideosToFolder(
    String folderId,
    List<String> videoIds,
  ) async {
    try {
      await _db.collection('folders').doc(folderId).update({
        'videoIds': FieldValue.arrayUnion(videoIds),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding videos to folder: $e');
      rethrow;
    }
  }
} 