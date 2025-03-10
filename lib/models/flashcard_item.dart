import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardItem {
  final String? id;
  final String flashcardId;
  final String question;
  final String answer;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardItem({
    this.id,
    required this.flashcardId,
    required this.question,
    required this.answer,
    this.image,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();

  factory FlashcardItem.fromMap(Map<String, dynamic> map, String id) {
    return FlashcardItem(
      id: id,
      flashcardId: map['flashcardId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      image: map['image'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flashcardId': flashcardId,
      'question': question,
      'answer': answer,
      'image': image,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FlashcardItem copyWith({
    String? flashcardId,
    String? question,
    String? answer,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashcardItem(
      id: this.id,
      flashcardId: flashcardId ?? this.flashcardId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 