import 'package:cloud_firestore/cloud_firestore.dart';

enum ClassroomStatus {
  active,    // Đang hoạt động
  archived   // Đã lưu trữ
}

extension ClassroomStatusLabel on ClassroomStatus {
  String get label {
    switch (this) {
      case ClassroomStatus.active:
        return 'Đang hoạt động';
      case ClassroomStatus.archived:
        return 'Đã lưu trữ';
    }
  }
}

class Classroom {
  final String? id;
  final String name;
  final String description;
  final String teacherId;
  final List<String> memberIds;
  final List<String> pendingMemberIds;
  final String? coverImage;
  final String? inviteCode;
  final bool isPublic;
  final String? courseId;
  final ClassroomStatus status;
  final List<String> customLessonIds;     // Bài học riêng
  final List<String> customFlashcardIds;  // Flashcard riêng
  final List<String> customVideoIds;      // Video bài giảng riêng
  final List<String> forumTopicIds;       // Chủ đề diễn đàn
  final DateTime createdAt;
  final DateTime updatedAt;

  Classroom({
    this.id,
    required this.name,
    required this.description,
    required this.teacherId,
    List<String>? memberIds,
    List<String>? pendingMemberIds,
    this.coverImage,
    this.inviteCode,
    this.isPublic = false,
    this.courseId,
    this.status = ClassroomStatus.active,
    List<String>? customLessonIds,
    List<String>? customFlashcardIds,
    List<String>? customVideoIds,
    List<String>? forumTopicIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.memberIds = memberIds ?? [],
    this.pendingMemberIds = pendingMemberIds ?? [],
    this.customLessonIds = customLessonIds ?? [],
    this.customFlashcardIds = customFlashcardIds ?? [],
    this.customVideoIds = customVideoIds ?? [],
    this.forumTopicIds = forumTopicIds ?? [],
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  factory Classroom.fromMap(Map<String, dynamic> map, [String? id]) {
    return Classroom(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      teacherId: map['teacherId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      pendingMemberIds: List<String>.from(map['pendingMemberIds'] ?? []),
      coverImage: map['coverImage'],
      inviteCode: map['inviteCode'],
      isPublic: map['isPublic'] ?? false,
      courseId: map['courseId'],
      status: _statusFromString(map['status'] ?? 'active'),
      customLessonIds: List<String>.from(map['customLessonIds'] ?? []),
      customFlashcardIds: List<String>.from(map['customFlashcardIds'] ?? []),
      customVideoIds: List<String>.from(map['customVideoIds'] ?? []),
      forumTopicIds: List<String>.from(map['forumTopicIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static ClassroomStatus _statusFromString(String status) {
    switch (status) {
      case 'active':
        return ClassroomStatus.active;
      case 'archived':
        return ClassroomStatus.archived;
      default:
        return ClassroomStatus.active;
    }
  }

  static String _statusToString(ClassroomStatus status) {
    switch (status) {
      case ClassroomStatus.active:
        return 'active';
      case ClassroomStatus.archived:
        return 'archived';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'memberIds': memberIds,
      'pendingMemberIds': pendingMemberIds,
      'coverImage': coverImage,
      'inviteCode': inviteCode,
      'isPublic': isPublic,
      'courseId': courseId,
      'status': _statusToString(status),
      'customLessonIds': customLessonIds,
      'customFlashcardIds': customFlashcardIds,
      'customVideoIds': customVideoIds,
      'forumTopicIds': forumTopicIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Classroom copyWith({
    String? name,
    String? description,
    String? teacherId,
    List<String>? memberIds,
    List<String>? pendingMemberIds,
    String? coverImage,
    String? inviteCode,
    String? courseId,
    bool? isPublic,
    ClassroomStatus? status,
    List<String>? customLessonIds,
    List<String>? customFlashcardIds,
    List<String>? customVideoIds,
    List<String>? forumTopicIds,
    DateTime? updatedAt,
  }) {
    return Classroom(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      memberIds: memberIds ?? this.memberIds,
      pendingMemberIds: pendingMemberIds ?? this.pendingMemberIds,
      coverImage: coverImage ?? this.coverImage,
      inviteCode: inviteCode ?? this.inviteCode,
      isPublic: isPublic ?? this.isPublic,
      courseId: courseId ?? this.courseId,
      status: status ?? this.status,
      customLessonIds: customLessonIds ?? this.customLessonIds,
      customFlashcardIds: customFlashcardIds ?? this.customFlashcardIds,
      customVideoIds: customVideoIds ?? this.customVideoIds,
      forumTopicIds: forumTopicIds ?? this.forumTopicIds,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
} 