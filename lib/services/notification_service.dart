import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_item.dart';
import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Notification channels
  static const String ADMIN_APPROVAL_CHANNEL = 'admin_approval_channel';
  static const String NEW_LESSON_CHANNEL = 'new_lesson_channel';
  
  // Notification topics
  static const String ADMIN_TOPIC = 'admin_notifications';
  static const String NEW_LESSON_TOPIC = 'new_lesson_notifications';

  // Define notification channels
  static const String _classApprovalChannel = 'class_approval';
  static const String _newTestChannel = 'new_test';
  static const String _newCommentChannel = 'new_comment';
  static const String _teacherResponseChannel = 'teacher_response';
  static const String _badgeAwardChannel = 'badge_award';
  static const String _dailyReminderChannel = 'daily_reminder';
  
  // Topic mapping for Firebase subscriptions
  static const Map<String, String> _notificationTopics = {
    _classApprovalChannel: 'class_approvals',
    _newTestChannel: 'new_tests',
    _newCommentChannel: 'new_comments',
    _teacherResponseChannel: 'teacher_responses',
    _badgeAwardChannel: 'badge_awards',
    _dailyReminderChannel: 'daily_reminders',
  };

  // Add these new properties
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();
  
  // Initialize notification services
  Future<void> initialize() async {
    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      // Request permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      print('Notification permission status: ${settings.authorizationStatus}');
      
      // Get and save FCM token
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');
      
      if (token != null) {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
          });
          print('FCM token saved to user document');
        }
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('FCM token refreshed: $newToken');
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': newToken,
          });
          print('New FCM token saved to user document');
        }
      });

      // Initialize local notifications
      final initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      final initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification clicked: ${response.payload}');
        },
      );
      print('Local notifications initialized');
      
      // Create notification channels
      await _createNotificationChannel(
        id: ADMIN_APPROVAL_CHANNEL,
        name: 'Admin Approval Notifications',
        description: 'Notifications for admin approval requests',
      );
      print('Admin approval channel created');

      await _createNotificationChannel(
        id: NEW_LESSON_CHANNEL,
        name: 'New Lesson Notifications',
        description: 'Notifications for new approved lessons',
      );
      print('New lesson channel created');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          _localNotifications.show(
            message.hashCode,
            message.notification?.title,
            message.notification?.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                channelDescription: 'This channel is used for important notifications.',
                importance: Importance.max,
                priority: Priority.high,
                enableVibration: true,
                playSound: true,
              ),
            ),
          );
        }
      });

      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
      rethrow;
    }
  }
  
  // Schedule daily notification
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      // Check for exact alarm permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.scheduleExactAlarm.status;
        print('Exact alarm permission status: $status');
        
        if (status.isDenied) {
          final result = await Permission.scheduleExactAlarm.request();
          print('Permission request result: $result');
          
          if (result.isDenied) {
            throw PlatformException(
              code: 'exact_alarms_not_permitted',
              message: 'Exact alarms permission denied',
            );
          }
        }
      }

      // Lấy thời gian hiện tại
      final now = DateTime.now();
      print('Current time: $now');
      
      // Tính thời gian schedule (1 phút sau)
      final scheduledDate = now.add(const Duration(minutes: 1));
      print('Scheduling notification for: $scheduledDate');
      print('Time until notification: ${scheduledDate.difference(now)}');

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            enableLights: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            autoCancel: true,
            showWhen: true,
            when: scheduledDate.millisecondsSinceEpoch,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      print('Notification scheduled successfully');
    } catch (e) {
      print('Error scheduling notification: $e');
      rethrow;
    }
  }
  
  // Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    try {
      print('Showing immediate notification');
      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      print('Immediate notification sent successfully');
    } catch (e) {
      print('Error showing notification: $e');
      rethrow;
    }
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
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

  // Check if device requires exact alarm permission
  Future<bool> _requiresExactAlarmPermission() async {
    if (!Platform.isAndroid) return false;
    
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = deviceInfo.version.sdkInt;
    return sdkInt >= 31; // Android 12 (API level 31) and above
  }

  // Helper method to create notification channel
  Future<void> _createNotificationChannel({
    required String id,
    required String name,
    required String description,
  }) async {
    final androidChannel = AndroidNotificationChannel(
      id,
      name,
      description: description,
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      showBadge: true,
      ledColor: const Color.fromARGB(255, 255, 0, 0),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Thông báo cho admin về bài học mới cần phê duyệt
  Future<void> notifyAdminNewLessonRequest({
    required String lessonId,
    required String lessonTitle,
    required String teacherName,
    required String className,
  }) async {
    try {
      // Lưu thông báo vào Firestore
      await _firestore.collection('notifications').add({
        'type': 'lesson_approval_request',
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'teacherName': teacherName,
        'className': className,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Gửi notification đến admin thông qua topic
      await FirebaseFunctions.instance.httpsCallable('sendNotification').call({
        'topic': ADMIN_TOPIC,
        'notification': {
          'title': 'Yêu cầu phê duyệt bài học mới',
          'body': 'GV $teacherName đã tạo bài "$lessonTitle" cho lớp $className',
        },
        'data': {
          'type': 'lesson_approval_request',
          'lessonId': lessonId,
        },
      });

      print('Sent notification to admin for lesson approval');
    } catch (e) {
      print('Error sending admin notification: $e');
      rethrow;
    }
  }

  // Thông báo cho học sinh về bài học mới được phê duyệt
  Future<void> notifyStudentsNewLesson({
    required String classId,
    required String lessonId,
    required String lessonTitle,
    required String teacherName,
  }) async {
    try {
      // Lấy danh sách học sinh trong lớp
      final classDoc = await _firestore.collection('classes').doc(classId).get();
      final List<String> studentIds = List<String>.from(classDoc.data()?['studentIds'] ?? []);

      // Batch write notifications cho từng học sinh
      final batch = _firestore.batch();
      for (final studentId in studentIds) {
        final notificationRef = _firestore
            .collection('users')
            .doc(studentId)
            .collection('notifications')
            .doc();
        
        batch.set(notificationRef, {
          'type': 'new_lesson',
          'lessonId': lessonId,
          'lessonTitle': lessonTitle,
          'teacherName': teacherName,
          'classId': classId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Gửi notification đến topic của lớp học
      await FirebaseFunctions.instance.httpsCallable('sendNotification').call({
        'topic': 'class_$classId',
        'notification': {
          'title': 'Bài học mới',
          'body': 'GV $teacherName đã đăng bài "$lessonTitle"',
        },
        'data': {
          'type': 'new_lesson',
          'lessonId': lessonId,
          'classId': classId,
        },
      });

      print('Sent notifications to students for new lesson');
    } catch (e) {
      print('Error sending student notifications: $e');
      rethrow;
    }
  }

  // Subscribe admin to admin notifications
  Future<void> subscribeAdminToNotifications(String userId) async {
    try {
      // Verify user is admin
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.data()?['role'] == 'admin') {
        await _firebaseMessaging.subscribeToTopic(ADMIN_TOPIC);
        print('Admin subscribed to notifications');
      }
    } catch (e) {
      print('Error subscribing admin to notifications: $e');
      rethrow;
    }
  }

  // Subscribe student to class notifications
  Future<void> subscribeToClassNotifications(String classId) async {
    try {
      await _firebaseMessaging.subscribeToTopic('class_$classId');
      print('Subscribed to class notifications: $classId');
    } catch (e) {
      print('Error subscribing to class notifications: $e');
      rethrow;
    }
  }

  // Unsubscribe from class notifications
  Future<void> unsubscribeFromClassNotifications(String classId) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('class_$classId');
      print('Unsubscribed from class notifications: $classId');
    } catch (e) {
      print('Error unsubscribing from class notifications: $e');
      rethrow;
    }
  }
} 