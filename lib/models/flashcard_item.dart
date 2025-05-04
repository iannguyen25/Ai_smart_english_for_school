import 'package:cloud_firestore/cloud_firestore.dart';

enum FlashcardItemType {
  textToText,    // Text question - Text answer
  imageToImage,  // Image question - Image answer (both with captions)
  imageToText,   // Image question (with caption) - Text answer
}

class FlashcardItem {
  final String? id;
  final String flashcardId;
  final String question;           // Text question
  final String answer;            // Text answer
  final String? questionImage;    // Image URL for question
  final String? answerImage;      // Image URL for answer
  final String? questionCaption;  // Caption for question image
  final String? answerCaption;    // Caption for answer image
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
    this.questionCaption,
    this.answerCaption,
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
      questionCaption: map['questionCaption'],
      answerCaption: map['answerCaption'],
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
      'questionCaption': questionCaption,
      'answerCaption': answerCaption,
      'type': type.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  FlashcardItem copyWith({
    String? id,
    String? flashcardId,
    String? question,
    String? answer,
    String? questionImage,
    String? answerImage,
    String? questionCaption,
    String? answerCaption,
    FlashcardItemType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashcardItem(
      id: id ?? this.id,
      flashcardId: flashcardId ?? this.flashcardId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      questionImage: questionImage ?? this.questionImage,
      answerImage: answerImage ?? this.answerImage,
      questionCaption: questionCaption ?? this.questionCaption,
      answerCaption: answerCaption ?? this.answerCaption,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 