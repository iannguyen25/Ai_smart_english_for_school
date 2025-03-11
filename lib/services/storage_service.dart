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
      final ref = _storage.ref().child('$folder/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      throw 'Không thể tải file lên';
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
}
