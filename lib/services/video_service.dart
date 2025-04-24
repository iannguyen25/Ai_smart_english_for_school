import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video.dart';

class VideoService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Upload video
  Future<String> uploadVideo(File videoFile, String userId) async {
    try {
      print('Starting video upload for user: $userId');
      // Tạo tên file ngẫu nhiên
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${userId}.mp4';
      final ref = _storage.ref().child('videos/$fileName');

      // Upload video với metadata
      final metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {'userId': userId},
      );

      // Upload với retry logic
      String videoUrl = '';
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          print('Upload attempt ${retryCount + 1}');
          // Upload video
          final uploadTask = ref.putFile(videoFile, metadata);
          
          // Theo dõi tiến trình upload
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
          });
          
          // Đợi upload hoàn tất
          await uploadTask;
          
          // Lấy URL của video
          videoUrl = await ref.getDownloadURL();
          print('Video uploaded successfully: $videoUrl');
          break; // Thoát khỏi vòng lặp nếu thành công
        } catch (e) {
          retryCount++;
          print('Upload attempt failed: $e');
          if (retryCount >= maxRetries) {
            rethrow; // Ném lại lỗi nếu đã thử hết số lần
          }
          // Đợi trước khi thử lại
          await Future.delayed(Duration(seconds: 2 * retryCount));
        }
      }

      // Tạo thumbnail
      String? thumbnailUrl;
      try {
        final thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: videoUrl,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG,
          quality: 75,
        );

        if (thumbnailPath != null) {
          final thumbnailRef = _storage.ref().child('thumbnails/$fileName.jpg');
          final thumbnailMetadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'userId': userId},
          );
          final thumbnailUpload = await thumbnailRef.putFile(File(thumbnailPath), thumbnailMetadata);
          thumbnailUrl = await thumbnailUpload.ref.getDownloadURL();
          print('Thumbnail created: $thumbnailUrl');
        }
      } catch (e) {
        print('Error creating thumbnail: $e');
        // Tiếp tục mà không có thumbnail
      }

      return videoUrl;
    } catch (e) {
      print('Error uploading video: $e');
      throw 'Không thể tải video lên. Vui lòng kiểm tra quyền truy cập và thử lại.';
    }
  }

  // Tạo video mới
  Future<String> createVideo(Video video) async {
    try {
      final doc = await _db.collection('videos').add(video.toMap());
      return doc.id;
    } catch (e) {
      print('Error creating video: $e');
      rethrow;
    }
  }

  // Cập nhật video
  Future<void> updateVideo(String videoId, Map<String, dynamic> data) async {
    try {
      await _db.collection('videos').doc(videoId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating video: $e');
      rethrow;
    }
  }

  // Xóa video
  Future<void> deleteVideo(String videoId) async {
    try {
      final doc = await _db.collection('videos').doc(videoId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      
      // Xóa file video và thumbnail từ storage
      if (data['videoUrl'] != null) {
        await _storage.refFromURL(data['videoUrl']).delete();
      }
      if (data['thumbnailUrl'] != null) {
        await _storage.refFromURL(data['thumbnailUrl']).delete();
      }

      // Xóa document
      await doc.reference.delete();
    } catch (e) {
      print('Error deleting video: $e');
      rethrow;
    }
  }

  // Lấy video theo ID
  Future<Video> getVideoById(String videoId) async {
    try {
      final doc = await _db.collection('videos').doc(videoId).get();
      if (!doc.exists) throw 'Video không tồn tại';
      return Video.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting video: $e');
      rethrow;
    }
  }

  // Lấy danh sách video theo IDs
  Future<List<Video>> getVideosByIds(List<String> videoIds) async {
    try {
      if (videoIds.isEmpty) return [];
      
      final docs = await _db
          .collection('videos')
          .where(FieldPath.documentId, whereIn: videoIds)
          .get();
      
      return docs.docs
          .map((doc) => Video.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting videos: $e');
      rethrow;
    }
  }

  // Tìm kiếm video
  Future<List<Video>> searchVideos(String query) async {
    try {
      final snapshot = await _db
          .collection('videos')
          .where('isPublic', isEqualTo: true)
          .orderBy('title')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => Video.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error searching videos: $e');
      rethrow;
    }
  }

  // Thêm phương thức getUserVideos
  Future<List<Video>> getUserVideos(String userId) async {
    try {
      final snapshot = await _db
          .collection('videos')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Video.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting user videos: $e');
      rethrow;
    }
  }
} 