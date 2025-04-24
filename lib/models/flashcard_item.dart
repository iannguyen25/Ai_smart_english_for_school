import 'package:cloud_firestore/cloud_firestore.dart';

enum FlashcardItemType {
  textToText,    // Text question - Text answer
  imageToText,   // Image question - Text answer
  textToImage,   // Text question - Image answer
  imageToImage,  // Image question - Image answer
  imageOnly,     // Single image, no text or illustration
}

class FlashcardItem {
  final String? id;
  final String flashcardId;
  final String question;           // Text question
  final String answer;            // Text answer
  final String? questionImage;    // Image URL for question
  final String? answerImage;      // Image URL for answer
  final FlashcardItemType type;   // Type of flashcard
  final DateTime createdAt;
  final DateTime updatedAt;

  FlashcardItem({
    this.id,
    required this.flashcardId,
    required this.question,
    required this.answer,
    this.questionImage,
    this.answerImage,
    this.type = FlashcardItemType.textToText,
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
      questionImage: map['questionImage'],
      answerImage: map['answerImage'],
      type: FlashcardItemType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => FlashcardItemType.textToText,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flashcardId': flashcardId,
      'question': question,
      'answer': answer,
      'questionImage': questionImage,
      'answerImage': answerImage,
      'type': type.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FlashcardItem copyWith({
    String? flashcardId,
    String? question,
    String? answer,
    String? questionImage,
    String? answerImage,
    FlashcardItemType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashcardItem(
      id: this.id,
      flashcardId: flashcardId ?? this.flashcardId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      questionImage: questionImage ?? this.questionImage,
      answerImage: answerImage ?? this.answerImage,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 