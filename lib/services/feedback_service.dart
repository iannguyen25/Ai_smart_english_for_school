import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../models/feedback.dart' as app_models;

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Collection references
  CollectionReference get _feedbacksCollection => _firestore.collection('feedbacks');
  
  // Tạo một phản hồi mới
  Future<app_models.Feedback?> createFeedback({
    required String classId,
    String? lessonId,
    required app_models.FeedbackType type,
    required String content,
    List<File> attachments = const [],
    bool isAnonymous = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated');
        return null;
      }
      
      // Upload attachments if any
      List<String> attachmentUrls = [];
      if (attachments.isNotEmpty) {
        attachmentUrls = await _uploadAttachments(attachments);
      }
      
      return app_models.Feedback.createFeedback(
        userId: user.uid,
        classId: classId,
        lessonId: lessonId,
        type: type,
        content: content,
        attachments: attachmentUrls,
        isAnonymous: isAnonymous,
      );
    } catch (e) {
      print('Error creating feedback: $e');
      return null;
    }
  }
  
  // Upload các file đính kèm
  Future<List<String>> _uploadAttachments(List<File> files) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      
      List<String> urls = [];
      
      for (final file in files) {
        final fileName = path.basename(file.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storagePath = 'feedback_attachments/${user.uid}/${timestamp}_$fileName';
        
        final ref = _storage.ref().child(storagePath);
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        
        final downloadUrl = await snapshot.ref.getDownloadURL();
        urls.add(downloadUrl);
      }
      
      return urls;
    } catch (e) {
      print('Error uploading attachments: $e');
      return [];
    }
  }
  
  // Lấy feedback theo ID
  Future<app_models.Feedback?> getFeedbackById(String feedbackId) async {
    try {
      final doc = await _feedbacksCollection.doc(feedbackId).get();
      
      if (!doc.exists) {
        print('Feedback not found');
        return null;
      }
      
      return app_models.Feedback.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      print('Error getting feedback: $e');
      return null;
    }
  }
  
  // Lấy danh sách phản hồi của học sinh hiện tại
  Future<List<app_models.Feedback>> getCurrentUserFeedbacks() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      
      return app_models.Feedback.getStudentFeedbacks(user.uid);
    } catch (e) {
      print('Error getting current user feedbacks: $e');
      return [];
    }
  }
  
  // Lấy danh sách phản hồi của lớp học
  Future<List<app_models.Feedback>> getClassFeedbacks(String classId) async {
    try {
      return app_models.Feedback.getClassFeedbacks(classId);
    } catch (e) {
      print('Error getting class feedbacks: $e');
      return [];
    }
  }
  
  // Lấy danh sách phản hồi của bài học
  Future<List<app_models.Feedback>> getLessonFeedbacks(String lessonId) async {
    try {
      return app_models.Feedback.getLessonFeedbacks(lessonId);
    } catch (e) {
      print('Error getting lesson feedbacks: $e');
      return [];
    }
  }
  
  // Lọc phản hồi theo trạng thái
  Future<List<app_models.Feedback>> getFeedbacksByStatus(
    String classId,
    app_models.FeedbackStatus status,
  ) async {
    try {
      return app_models.Feedback.getFeedbacksByStatus(classId, status);
    } catch (e) {
      print('Error getting feedbacks by status: $e');
      return [];
    }
  }
  
  // Lọc phản hồi theo loại
  Future<List<app_models.Feedback>> getFeedbacksByType(
    String classId,
    app_models.FeedbackType type,
  ) async {
    try {
      return app_models.Feedback.getFeedbacksByType(classId, type);
    } catch (e) {
      print('Error getting feedbacks by type: $e');
      return [];
    }
  }
  
  // Trả lời phản hồi (dành cho giáo viên)
  Future<bool> respondToFeedback(String feedbackId, String response) async {
    try {
      final feedback = await getFeedbackById(feedbackId);
      if (feedback == null) return false;
      
      return feedback.respondToFeedback(response);
    } catch (e) {
      print('Error responding to feedback: $e');
      return false;
    }
  }
  
  // Đóng phản hồi (dành cho giáo viên)
  Future<bool> closeFeedback(String feedbackId) async {
    try {
      final feedback = await getFeedbackById(feedbackId);
      if (feedback == null) return false;
      
      return feedback.closeFeedback();
    } catch (e) {
      print('Error closing feedback: $e');
      return false;
    }
  }
  
  // Kiểm tra quyền truy cập (chỉ giáo viên của lớp học hoặc admin mới có quyền)
  Future<bool> canAccessFeedback(String classId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Kiểm tra vai trò của người dùng
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final roleId = userData['roleId'] as String?;
      
      // Nếu là admin, cho phép truy cập
      if (roleId == 'admin') return true;
      
      // Nếu là giáo viên, kiểm tra xem có phải giáo viên của lớp không
      if (roleId == 'teacher') {
        final classDoc = await _firestore.collection('classrooms').doc(classId).get();
        if (!classDoc.exists) return false;
        
        final classData = classDoc.data() as Map<String, dynamic>;
        final teacherId = classData['teacherId'] as String?;
        
        return teacherId == user.uid;
      }
      
      return false;
    } catch (e) {
      print('Error checking feedback access permission: $e');
      return false;
    }
  }
} 