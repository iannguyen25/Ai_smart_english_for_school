import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class FlashcardItem extends BaseModel {
  final String flashcardId;
  final String question;
  final String answer;
  final String? image;

  FlashcardItem({
    String? id,
    required this.flashcardId,
    required this.question,
    required this.answer,
    this.image,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory FlashcardItem.fromMap(Map<String, dynamic> map, String id) {
    return FlashcardItem(
      id: id,
      flashcardId: map['flashcardId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
      image: map['image'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'flashcardId': flashcardId,
      'question': question,
      'answer': answer,
      'image': image,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  FlashcardItem copyWith({
    String? id,
    String? flashcardId,
    String? question,
    String? answer,
    String? image,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return FlashcardItem(
      id: id ?? this.id,
      flashcardId: flashcardId ?? this.flashcardId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 