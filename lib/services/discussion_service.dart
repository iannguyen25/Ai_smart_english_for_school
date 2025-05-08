import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import '../models/discussion.dart';
import 'user_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:meta/meta.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiscussionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'discussions';
  final UserService _userService = UserService();
  StreamSubscription? _discussionSubscription;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DiscussionService() {
    _initNotifications();
    // Enable debug prints
    debugPrint = (String? message, {int? wrapWidth}) {
      dev.log(message ?? '', name: 'DiscussionService');
    };
  }

  Future<void> _initNotifications() async {
    // Yêu cầu quyền thông báo
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Cấu hình thông báo local
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng nhấn vào thông báo
      },
    );

    // Lắng nghe thông báo khi app đang chạy
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(
          title: message.notification!.title ?? 'Tin nhắn mới',
          body: message.notification!.body ?? '',
          payload: message.data['discussionId'],
        );
      }
    });

    // Lắng nghe thông báo khi app ở background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'discussion_channel',
      'Thảo luận',
      channelDescription: 'Thông báo về thảo luận mới',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Subscribe to classroom notifications
  Future<void> subscribeToClassroom(String classroomId) async {
    try {
      // Đăng ký topic
      await _messaging.subscribeToTopic('classroom_$classroomId');
      
      // Lưu token vào Firestore
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('user_tokens').doc(token).set({
          'userId': _auth.currentUser?.uid,
          'classroomIds': FieldValue.arrayUnion([classroomId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Unsubscribe from classroom notifications
  Future<void> unsubscribeFromClassroom(String classroomId) async {
    try {
      await _messaging.unsubscribeFromTopic('classroom_$classroomId');
      
      // Xóa token khỏi Firestore
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('user_tokens').doc(token).update({
          'classroomIds': FieldValue.arrayRemove([classroomId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Lấy danh sách discussions của một classroom
  Future<List<Discussion>> getClassroomDiscussions(String classroomId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('classroomId', isEqualTo: classroomId)
          .where('parentId', isNull: true) // Chỉ lấy các bài viết gốc
          .orderBy('isPinned', descending: true) // Ghim lên đầu
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Discussion.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting classroom discussions: $e');
      rethrow;
    }
  }

  // Lấy danh sách replies của một discussion
  Future<List<Discussion>> getDiscussionReplies(String discussionId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('parentId', isEqualTo: discussionId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Discussion.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting discussion replies: $e');
      rethrow;
    }
  }

  // Get real-time stream of classroom discussions
  Stream<List<Discussion>> getClassroomDiscussionsStream(String classroomId) {
    return _firestore
        .collection(_collection)
        .where('classroomId', isEqualTo: classroomId)
        .where('parentId', isNull: true)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Discussion.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Create new discussion with notification
  Future<Discussion> createDiscussion({
    required String userId,
    required String classroomId,
    required String content,
    required DiscussionType type,
    String? parentId,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      
      // Lấy thông tin người dùng
      final user = await _userService.getUserById(userId);
      
      final discussion = Discussion(
        id: docRef.id,
        userId: userId,
        classroomId: classroomId,
        content: content,
        type: type,
        parentId: parentId,
        isPinned: false,
        createdAt: Timestamp.now(),
        userName: user?.fullName,
        userAvatar: user?.avatar,
      );

      await docRef.set(discussion.toMap());

      // Bỏ qua phần tạo notification và FCM message vì không có quyền
      // TODO: Implement notification system with proper permissions

      return discussion;
    } catch (e) {
      rethrow;
    }
  }

  // Update discussion
  Future<void> updateDiscussion(String discussionId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(discussionId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Delete discussion
  Future<void> deleteDiscussion(String discussionId) async {
    try {
      // Xóa tất cả replies trước
      final replies = await getDiscussionReplies(discussionId);
      
      for (var reply in replies) {
        await _firestore.collection(_collection).doc(reply.id).delete();
      }
      
      // Sau đó xóa discussion chính
      await _firestore.collection(_collection).doc(discussionId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Toggle pin discussion
  Future<void> togglePinDiscussion(String discussionId, bool isPinned) async {
    try {
      await _firestore.collection(_collection).doc(discussionId).update({
        'isPinned': isPinned,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Clean up resources
  void dispose() {
    _discussionSubscription?.cancel();
  }
}

// Xử lý thông báo khi app ở background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
} 