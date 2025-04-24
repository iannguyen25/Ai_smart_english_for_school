import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  classApproval,
  newLesson,
  newTest,
  newComment,
  teacherResponse,
  badgeAward,
  dailyReminder,
  general
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final String? targetId;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.targetId,
    this.isRead = false,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      type: _typeFromString(map['type'] ?? ''),
      targetId: map['targetId'],
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'type': _typeToString(type),
      'targetId': targetId,
      'isRead': isRead,
    };
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    NotificationType? type,
    String? targetId,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      isRead: isRead ?? this.isRead,
    );
  }

  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'class_approval':
        return NotificationType.classApproval;
      case 'new_lesson':
        return NotificationType.newLesson;
      case 'new_test':
        return NotificationType.newTest;
      case 'new_comment':
        return NotificationType.newComment;
      case 'teacher_response':
        return NotificationType.teacherResponse;
      case 'badge_award':
        return NotificationType.badgeAward;
      case 'daily_reminder':
        return NotificationType.dailyReminder;
      default:
        return NotificationType.general;
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.classApproval:
        return 'class_approval';
      case NotificationType.newLesson:
        return 'new_lesson';
      case NotificationType.newTest:
        return 'new_test';
      case NotificationType.newComment:
        return 'new_comment';
      case NotificationType.teacherResponse:
        return 'teacher_response';
      case NotificationType.badgeAward:
        return 'badge_award';
      case NotificationType.dailyReminder:
        return 'daily_reminder';
      case NotificationType.general:
        return 'general';
    }
  }
} 