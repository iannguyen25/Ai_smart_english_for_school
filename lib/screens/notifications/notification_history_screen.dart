import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({Key? key}) : super(key: key);

  @override
  _NotificationHistoryScreenState createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final NotificationService _notificationService = NotificationService();
  late Future<List<NotificationItem>> _notificationsFuture;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _notificationsFuture = _notificationService.getNotificationHistory();
    });
  }

  Future<void> _markAllAsRead() async {
    setState(() => _loading = true);
    
    try {
      await _notificationService.markAllNotificationsAsRead();
      _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: _loading ? null : _markAllAsRead,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: FutureBuilder<List<NotificationItem>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Text('Lỗi: ${snapshot.error}'),
              );
            }
            
            final notifications = snapshot.data ?? [];
            
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bạn chưa có thông báo nào',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thông báo sẽ xuất hiện khi có hoạt động mới',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationItem(notification);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');
    
    return InkWell(
      onTap: () {
        _markAsRead(notification.id);
        _handleNotificationTap(notification);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: notification.isRead ? null : Colors.blue.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(notification.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateFormat.format(notification.timestamp),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color color;
    
    switch (type) {
      case NotificationType.classApproval:
        iconData = Icons.school;
        color = Colors.green;
        break;
      case NotificationType.newLesson:
        iconData = Icons.book;
        color = Colors.blue;
        break;
      case NotificationType.newTest:
        iconData = Icons.quiz;
        color = Colors.orange;
        break;
      case NotificationType.newComment:
        iconData = Icons.chat;
        color = Colors.purple;
        break;
      case NotificationType.teacherResponse:
        iconData = Icons.feedback;
        color = Colors.teal;
        break;
      case NotificationType.badgeAward:
        iconData = Icons.emoji_events;
        color = Colors.amber;
        break;
      case NotificationType.dailyReminder:
        iconData = Icons.alarm;
        color = Colors.red;
        break;
      case NotificationType.general:
      default:
        iconData = Icons.notifications;
        color = Colors.grey;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case NotificationType.classApproval:
        if (notification.targetId != null && notification.targetId!.isNotEmpty) {
          Get.toNamed(
            '/classroom_detail',
            arguments: {'classId': notification.targetId},
          );
        }
        break;
      case NotificationType.newLesson:
        if (notification.targetId != null && notification.targetId!.isNotEmpty) {
          final parts = notification.targetId!.split(':');
          if (parts.length >= 2) {
            Get.toNamed(
              '/lesson_detail',
              arguments: {
                'classId': parts[0],
                'lessonId': parts[1],
              },
            );
          }
        }
        break;
      case NotificationType.newTest:
        if (notification.targetId != null && notification.targetId!.isNotEmpty) {
          final parts = notification.targetId!.split(':');
          if (parts.length >= 2) {
            Get.toNamed(
              '/test_detail',
              arguments: {
                'classId': parts[0],
                'testId': parts[1],
              },
            );
          }
        }
        break;
      case NotificationType.newComment:
        if (notification.targetId != null && notification.targetId!.isNotEmpty) {
          final parts = notification.targetId!.split(':');
          if (parts.length >= 2) {
            Get.toNamed(
              '/forum_detail',
              arguments: {
                'classId': parts[0],
                'topicId': parts[1],
              },
            );
          }
        }
        break;
      case NotificationType.teacherResponse:
        if (notification.targetId != null && notification.targetId!.isNotEmpty) {
          Get.toNamed(
            '/feedback_detail',
            arguments: {'feedbackId': notification.targetId},
          );
        }
        break;
      case NotificationType.badgeAward:
        Get.toNamed('/badges');
        break;
      case NotificationType.dailyReminder:
      case NotificationType.general:
      default:
        // Do nothing, already on notifications screen
        break;
    }
  }
} 