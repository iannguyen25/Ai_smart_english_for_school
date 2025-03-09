import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class Role extends BaseModel {
  final String roleName;
  final String? description;

  Role({
    String? id,
    required this.roleName,
    this.description,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory Role.fromMap(Map<String, dynamic> map, String id) {
    return Role(
      id: id,
      roleName: map['roleName'] ?? '',
      description: map['description'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'roleName': roleName,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  Role copyWith({
    String? id,
    String? roleName,
    String? description,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Role(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 