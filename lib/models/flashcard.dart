import 'package:base_flutter_framework/models/content_approval.dart';
import 'package:base_flutter_framework/models/flashcard_item.dart';
import 'package:base_flutter_framework/models/lesson.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Flashcard {
  final String? id;
  final String title;
  final String description;
  final String userId;
  final List<FlashcardItem>? items;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lessonId;
  final String? classroomId;
  final ApprovalStatus approvalStatus;
  final String? rejectionReason;

  Flashcard({
    this.id,
    required this.title,
    required this.description,
    required this.userId,
    this.items,
    this.isPublic = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lessonId,
    this.classroomId,
    this.approvalStatus = ApprovalStatus.pending,
    this.rejectionReason,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  factory Flashcard.fromMap(Map<String, dynamic> map, [String? id]) {
    return Flashcard(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      items: null,
      isPublic: map['isPublic'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lessonId: map['lessonId'],
      classroomId: map['classroomId'],
      approvalStatus: ApprovalStatus.values.firstWhere(
        (e) => e.name == (map['approvalStatus'] ?? 'pending'),
        orElse: () => ApprovalStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'items': items?.map((item) => item.toMap()).toList(),
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lessonId': lessonId,
      'classroomId': classroomId,
      'approvalStatus': approvalStatus.name,
      'rejectionReason': rejectionReason,
    };
  }

  Flashcard copyWith({
    String? title,
    String? description,
    String? userId,
    List<FlashcardItem>? items,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lessonId,
    String? classroomId,
    ApprovalStatus? approvalStatus,
    String? rejectionReason,
  }) {
    return Flashcard(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lessonId: lessonId ?? this.lessonId,
      classroomId: classroomId ?? this.classroomId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
