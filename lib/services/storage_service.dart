import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<SharedPreferences> init() async {
    return SharedPreferences.getInstance();}


  // Upload file to Firebase Storage
  Future<String> uploadFile(File file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final ref = _storage.ref().child(folder).child(fileName);

      // Set metadata to prevent caching issues
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'timestamp': DateTime.now().toString()}
      );

      // Upload file with metadata
      final uploadTask = ref.putFile(file, metadata);
      
      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Không thể tải lên ảnh: ${e.toString()}');
    }
  }

  // Delete file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
      // Don't throw error as this is not critical
    }
  }

  // Delete multiple files from Firebase Storage
  Future<void> deleteFiles(List<String> fileUrls) async {
    try {
      await Future.wait(
        fileUrls.map((url) => deleteFile(url)),
      );
    } catch (e) {
      print('Error deleting files: $e');
      // Don't throw error as this is not critical
    }
  }

  Future<String?> uploadFlashcardImage(String userId, String flashcardId, File file) async {
    try {
      final fileName = path.basename(file.path);
      final ref = _storage.ref()
          .child('flashcards')
          .child(userId)
          .child(flashcardId)
          .child(fileName);

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading flashcard image: $e');
      return null;
    }
  }

  // Tải ảnh lên Firebase Storage
  Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      // Tạo tên file duy nhất bằng timestamp
      final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final storageRef = _storage.ref().child('$folder/$fileName');
      
      // Tải file lên
      final uploadTask = await storageRef.putFile(imageFile);
      
      // Lấy URL của file đã tải lên
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
  
  // Xóa ảnh từ Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
