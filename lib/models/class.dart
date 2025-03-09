import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class Class extends BaseModel {
  final String className;
  final String? description;

  Class({
    String? id,
    required this.className,
    this.description,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory Class.fromMap(Map<String, dynamic> map, String id) {
    return Class(
      id: id,
      className: map['className'] ?? '',
      description: map['description'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  Class copyWith({
    String? id,
    String? className,
    String? description,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Class(
      id: id ?? this.id,
      className: className ?? this.className,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 