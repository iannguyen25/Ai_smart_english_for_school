import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class Flashcard extends BaseModel {
  final String title;
  final String description;
  final String userId;
  final bool isPublic;

  Flashcard({
    String? id,
    required this.title,
    required this.description,
    required this.userId,
    required this.isPublic,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory Flashcard.fromMap(Map<String, dynamic> map, String id) {
    return Flashcard(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      isPublic: map['isPublic'] ?? false,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'isPublic': isPublic,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  Flashcard copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    bool? isPublic,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 