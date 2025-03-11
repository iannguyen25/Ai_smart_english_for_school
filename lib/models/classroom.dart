import 'package:cloud_firestore/cloud_firestore.dart';

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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.memberIds = memberIds ?? [],
    this.pendingMemberIds = pendingMemberIds ?? [],
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
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
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
    bool? isPublic,
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
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
} 