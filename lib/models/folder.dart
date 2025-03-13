import 'package:cloud_firestore/cloud_firestore.dart';

class Folder {
  final String? id;
  final String name;
  final String description;
  final String userId;
  final List<String> flashcardIds;
  final List<String> videoIds;
  final bool isPublic;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Folder({
    this.id,
    required this.name,
    required this.description,
    required this.userId,
    List<String>? flashcardIds,
    List<String>? videoIds,
    this.isPublic = false,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) :
    this.flashcardIds = flashcardIds ?? [],
    this.videoIds = videoIds ?? [],
    this.createdAt = createdAt ?? Timestamp.now(),
    this.updatedAt = updatedAt ?? Timestamp.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'userId': userId,
      'flashcardIds': flashcardIds,
      'videoIds': videoIds,
      'isPublic': isPublic,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map, [String? id]) {
    return Folder(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      flashcardIds: List<String>.from(map['flashcardIds'] ?? []),
      videoIds: List<String>.from(map['videoIds'] ?? []),
      isPublic: map['isPublic'] ?? false,
      createdAt: map['createdAt'] as Timestamp,
      updatedAt: map['updatedAt'] as Timestamp,
    );
  }

  Folder copyWith({
    String? id,
    String? name,
    String? description,
    String? userId,
    List<String>? flashcardIds,
    List<String>? videoIds,
    bool? isPublic,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      flashcardIds: flashcardIds ?? this.flashcardIds,
      videoIds: videoIds ?? this.videoIds,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}