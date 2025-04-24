import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_item.dart';
import 'package:get/get.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Define notification channels
  static const String _classApprovalChannel = 'class_approval';
  static const String _newLessonChannel = 'new_lesson';
  static const String _newTestChannel = 'new_test';
  static const String _newCommentChannel = 'new_comment';
  static const String _teacherResponseChannel = 'teacher_response';
  static const String _badgeAwardChannel = 'badge_award';
  static const String _dailyReminderChannel = 'daily_reminder';
  
  // Topic mapping for Firebase subscriptions
  static const Map<String, String> _notificationTopics = {
    _classApprovalChannel: 'class_approvals',
    _newLessonChannel: 'new_lessons',
    _newTestChannel: 'new_tests',
    _newCommentChannel: 'new_comments',
    _teacherResponseChannel: 'teacher_responses',
    _badgeAwardChannel: 'badge_awards',
    _dailyReminderChannel: 'daily_reminders',
  };

  // Add these new properties
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();
  
  // Initialize notification services
  Future<void> initialize() async {
    // Request permission
    await _requestPermission();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Set up foreground notification handling
    await _setupForegroundNotification();
    
    // Set up background & terminated notification handling
    await _setupBackgroundNotification();
    
    // Retrieve and sync user notification preferences
    await syncNotificationSettings();
    
    // Get FCM token for this device and update in Firestore
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await updateFcmToken(token);
    }
    
    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      updateFcmToken(newToken);
    });
    
    debugPrint('FCM Token: $token');
  }
  
  // Request permission to receive notifications
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }
  
  // Initialize local notification plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          onDidReceiveLocalNotification: (id, title, body, payload) async {
            // iOS specific notification callback
          },
        );
        
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification taps
        _handleNotificationTap(details.payload);
      },
    );
    
    // Create Android notification channels
    if (Platform.isAndroid) {
      await _createAndroidNotificationChannels();
    }
  }
  
  // Create notification channels for Android
  Future<void> _createAndroidNotificationChannels() async {
    // Class approval channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _classApprovalChannel,
          'Duyệt lớp',
          description: 'Thông báo khi bạn được duyệt vào lớp học',
          importance: Importance.high,
        ));
        
    // New lesson channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _newLessonChannel,
          'Bài học mới',
          description: 'Thông báo khi có bài học mới được thêm vào lớp',
          importance: Importance.high,
        ));
        
    // New test channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _newTestChannel,
          'Bài kiểm tra mới',
          description: 'Thông báo khi có bài kiểm tra mới',
          importance: Importance.high,
        ));
        
    // New comment channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _newCommentChannel,
          'Bình luận mới',
          description: 'Thông báo khi có bình luận mới',
          importance: Importance.defaultImportance,
        ));
        
    // Teacher response channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _teacherResponseChannel,
          'Phản hồi từ giáo viên',
          description: 'Thông báo khi giáo viên phản hồi thắc mắc của bạn',
          importance: Importance.high,
        ));
        
    // Badge award channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _badgeAwardChannel,
          'Huy hiệu mới',
          description: 'Thông báo khi bạn nhận được huy hiệu mới',
          importance: Importance.high,
        ));
        
    // Daily reminder channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _dailyReminderChannel,
          'Nhắc nhở học tập',
          description: 'Nhắc nhở học tập hằng ngày',
          importance: Importance.defaultImportance,
        ));
  }
  
  // Handle foreground messages
  Future<void> _setupForegroundNotification() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });
  }
  
  // Handle background and terminated app messages
  Future<void> _setupBackgroundNotification() async {
    // Handle message when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('onMessageOpenedApp: ${message.data}');
      // Save to history
      saveNotificationToHistory(message);
      _handleNotificationTap(jsonEncode(message.data));
    });
    
    // Check if app was opened from a notification when terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App started by notification: ${initialMessage.data}');
      // Save to history
      saveNotificationToHistory(initialMessage);
      _handleNotificationTap(jsonEncode(initialMessage.data));
    }
    
    // Process any pending notifications saved from background state
    await _processPendingNotifications();
  }
  
  // Show a local notification based on FCM message
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    // Extract notification data
    final String title = notification?.title ?? 'Thông báo mới';
    final String body = notification?.body ?? '';
    final String channelId = message.data['channel_id'] as String? ?? _dailyReminderChannel;
    
    if (notification != null) {
      // Save to notification history
      await saveNotificationToHistory(message);
      
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId,
            icon: android?.smallIcon ?? 'mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
  
  // Handle notification tap action
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    
    try {
      Map<String, dynamic> data = jsonDecode(payload);
      String type = data['type'] ?? '';
      String targetId = data['target_id'] ?? '';
      
      debugPrint('Notification tap handler: $type, $targetId');
      
      // Use Get.toNamed for navigation based on notification type
      switch (type) {
        case 'class_approval':
          if (targetId.isNotEmpty) {
            Get.toNamed('/classroom_detail', arguments: {'classId': targetId});
          }
          break;
        case 'new_lesson':
          if (targetId.isNotEmpty) {
            final parts = targetId.split(':');
            if (parts.length >= 2) {
              Get.toNamed('/lesson_detail', arguments: {
                'classId': parts[0],
                'lessonId': parts[1],
              });
            }
          }
          break;
        case 'new_test':
          if (targetId.isNotEmpty) {
            final parts = targetId.split(':');
            if (parts.length >= 2) {
              Get.toNamed('/test_detail', arguments: {
                'classId': parts[0],
                'testId': parts[1],
              });
            }
          }
          break;
        case 'new_comment':
          if (targetId.isNotEmpty) {
            final parts = targetId.split(':');
            if (parts.length >= 2) {
              Get.toNamed('/forum_detail', arguments: {
                'classId': parts[0],
                'topicId': parts[1],
              });
            }
          }
          break;
        case 'teacher_response':
          if (targetId.isNotEmpty) {
            Get.toNamed('/feedback_detail', arguments: {'feedbackId': targetId});
          }
          break;
        case 'badge_award':
          Get.toNamed('/badges');
          break;
        case 'daily_reminder':
          Get.toNamed('/home');
          break;
        default:
          Get.toNamed('/notifications');
          break;
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  // Subscribe user to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }
  
  // Unsubscribe user from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
  
  // Subscribe to classroom topic
  Future<void> subscribeToClassroom(String classroomId) async {
    await subscribeToTopic('classroom_$classroomId');
  }
  
  // Unsubscribe from classroom topic
  Future<void> unsubscribeFromClassroom(String classroomId) async {
    await unsubscribeFromTopic('classroom_$classroomId');
  }
  
  // Save notification settings
  Future<void> saveNotificationSetting(String channel, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_$channel', enabled);
    
    // Update Firebase topic subscription based on setting
    final topic = _notificationTopics[channel];
    if (topic != null) {
      if (enabled) {
        await subscribeToTopic(topic);
      } else {
        await unsubscribeFromTopic(topic);
      }
    }
  }
  
  // Get notification setting
  Future<bool> getNotificationSetting(String channel) async {
    final prefs = await SharedPreferences.getInstance();
    // Default is true (notifications enabled)
    return prefs.getBool('notification_$channel') ?? true;
  }
  
  // Sync notification settings with Firebase subscriptions
  Future<void> syncNotificationSettings() async {
    for (final entry in _notificationTopics.entries) {
      final channel = entry.key;
      final topic = entry.value;
      
      final enabled = await getNotificationSetting(channel);
      if (enabled) {
        await subscribeToTopic(topic);
      } else {
        await unsubscribeFromTopic(topic);
      }
    }
  }
  
  // Set daily reminder time
  Future<void> setDailyReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', time.hour);
    await prefs.setInt('reminder_minute', time.minute);
    
    // Re-subscribe to ensure the new time takes effect
    final enabled = await getNotificationSetting(_dailyReminderChannel);
    if (enabled) {
      await unsubscribeFromTopic(_notificationTopics[_dailyReminderChannel]!);
      await subscribeToTopic(_notificationTopics[_dailyReminderChannel]!);
    }
  }
  
  // Get daily reminder time
  Future<TimeOfDay> getDailyReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('reminder_hour') ?? 20; // Default 8 PM
    final minute = prefs.getInt('reminder_minute') ?? 0;
    
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Update FCM token in Firestore using Cloud Functions
  Future<void> updateFcmToken(String token) async {
    try {
      // Call the Cloud Function to update the token
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('updateFcmToken');
      final result = await callable.call({
        'token': token,
      });
      
      debugPrint('FCM token updated in Firestore: ${result.data['success']}');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  // Store notification in Firestore for history
  Future<void> saveNotificationToHistory(RemoteMessage message) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    final String notificationId = _uuid.v4();
    final notificationData = message.data;
    final notification = message.notification;
    
    if (notification != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .set({
          'id': notificationId,
          'title': notification.title ?? 'Thông báo mới',
          'body': notification.body ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'type': notificationData['type'] ?? 'general',
          'targetId': notificationData['target_id'],
          'isRead': false,
        });
      } catch (e) {
        debugPrint('Error saving notification to history: $e');
      }
    }
  }

  // Get notification history for current user
  Future<List<NotificationItem>> getNotificationHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => NotificationItem.fromMap({
                ...doc.data(),
                'id': doc.id, // Ensure id is set from document id
              }))
          .toList();
    } catch (e) {
      debugPrint('Error getting notification history: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    final user = _auth.currentUser;
    if (user == null) return 0;
    
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();
      
      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting unread notification count: $e');
      return 0;
    }
  }
  
  // Process pending notifications saved in SharedPreferences
  Future<void> _processPendingNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingNotifications = prefs.getStringList('pending_notifications') ?? [];
      
      if (pendingNotifications.isNotEmpty) {
        for (final notificationJson in pendingNotifications) {
          try {
            final Map<String, dynamic> notificationData = jsonDecode(notificationJson);
            
            // Create a RemoteMessage-like structure to reuse existing logic
            final messageData = notificationData['data'] as Map<String, dynamic>? ?? {};
            
            // Save to notification history
            final user = _auth.currentUser;
            if (user != null) {
              final String notificationId = _uuid.v4();
              await _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .doc(notificationId)
                  .set({
                'id': notificationId,
                'title': notificationData['title'] ?? 'Thông báo mới',
                'body': notificationData['body'] ?? '',
                'timestamp': notificationData['timestamp'] != null
                    ? Timestamp.fromMillisecondsSinceEpoch(notificationData['timestamp'])
                    : FieldValue.serverTimestamp(),
                'type': messageData['type'] ?? 'general',
                'targetId': messageData['target_id'],
                'isRead': false,
              });
            }
          } catch (e) {
            debugPrint('Error processing pending notification: $e');
          }
        }
        
        // Clear the pending notifications
        await prefs.setStringList('pending_notifications', []);
      }
    } catch (e) {
      debugPrint('Error processing pending notifications: $e');
    }
  }

  // Send a notification to a specific user or topic
  Future<void> notify({
    required String title,
    required String body,
    String? userId,
    String? topic,
    String? type,
    String? targetId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Call the Cloud Function to send the notification
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendNotification');
      final result = await callable.call({
        'title': title,
        'body': body,
        'userId': userId,
        'topic': topic,
        'type': type ?? 'general',
        'targetId': targetId,
        'data': additionalData,
      });
      
      debugPrint('Notification sent: ${result.data['success']}');
    } catch (e) {
      debugPrint('Error sending notification: $e');
      throw Exception('Failed to send notification: $e');
    }
  }
} 