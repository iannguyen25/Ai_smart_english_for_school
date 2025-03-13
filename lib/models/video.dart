import 'package:cloud_firestore/cloud_firestore.dart';

class Video {
  final String? id;
  final String title;
  final String description;
  final String userId;
  final String videoUrl;
  final String? thumbnailUrl;
  final bool isPublic;
  final int duration; // Thời lượng video tính bằng giây
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Video({
    this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.isPublic = false,
    this.duration = 0,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) :
    this.createdAt = createdAt ?? Timestamp.now(),
    this.updatedAt = updatedAt ?? Timestamp.now();

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'userId': userId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'isPublic': isPublic,
      'duration': duration,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Video.fromMap(Map<String, dynamic> map, [String? id]) {
    return Video(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      videoUrl: map['videoUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      isPublic: map['isPublic'] ?? false,
      duration: map['duration'] ?? 0,
      createdAt: map['createdAt'] as Timestamp,
      updatedAt: map['updatedAt'] as Timestamp,
    );
  }
}