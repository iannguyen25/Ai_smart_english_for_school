import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class ClassMember extends BaseModel {
  final String classId;
  final String userId;
  final Timestamp joinedAt;
  final String status; // Can be 'pending', 'active', 'inactive', etc.

  ClassMember({
    String? id,
    required this.classId,
    required this.userId,
    Timestamp? joinedAt,
    required this.status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : 
    this.joinedAt = joinedAt ?? Timestamp.now(),
    super(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

  factory ClassMember.fromMap(Map<String, dynamic> map, String id) {
    return ClassMember(
      id: id,
      classId: map['classId'] ?? '',
      userId: map['userId'] ?? '',
      joinedAt: map['joinedAt'] ?? Timestamp.now(),
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'userId': userId,
      'joinedAt': joinedAt,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  ClassMember copyWith({
    String? id,
    String? classId,
    String? userId,
    Timestamp? joinedAt,
    String? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ClassMember(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      userId: userId ?? this.userId,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 