import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/base_repository.dart';
import '../models/base_model.dart';

class AIInteraction extends BaseModel {
  final String userId;
  final String prompt;
  final String response;

  AIInteraction({
    String? id,
    required this.userId,
    required this.prompt,
    required this.response,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory AIInteraction.fromMap(Map<String, dynamic> map, String id) {
    return AIInteraction(
      id: id,
      userId: map['userId'] ?? '',
      prompt: map['prompt'] ?? '',
      response: map['response'] ?? '',
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'prompt': prompt,
      'response': response,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  AIInteraction copyWith({
    String? id,
    String? userId,
    String? prompt,
    String? response,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return AIInteraction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      prompt: prompt ?? this.prompt,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AIInteractionRepository extends BaseRepository<AIInteraction> {
  AIInteractionRepository() : super('ai_interactions');

  @override
  Future<String> add(Map<String, dynamic> data) async {
    final docRef = await collection.add(data);
    return docRef.id;
  }

  @override
  Future<AIInteraction?> getById(String id) async {
    final doc = await collection.doc(id).get();
    if (!doc.exists) return null;
    
    return AIInteraction.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Future<List<AIInteraction>> getAll() async {
    final querySnapshot = await collection.get();
    return querySnapshot.docs.map((doc) {
      return AIInteraction.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  @override
  Future<List<AIInteraction>> query(Query Function(CollectionReference) queryBuilder) async {
    final querySnapshot = await queryBuilder(collection).get();
    return querySnapshot.docs.map((doc) {
      return AIInteraction.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    await collection.doc(id).update(data);
  }

  @override
  Future<void> delete(String id) async {
    await collection.doc(id).delete();
  }

  Future<List<AIInteraction>> getByUserId(String userId) async {
    return query((ref) => ref.where('userId', isEqualTo: userId).orderBy('createdAt', descending: true));
  }
}

class AIService {
  final AIInteractionRepository _repository = AIInteractionRepository();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Get conversation history for a user
  Future<List<AIInteraction>> getUserConversationHistory(String userId) async {
    return _repository.getByUserId(userId);
  }

  // Generate a new AI response
  Future<AIInteraction> generateResponse({
    required String userId,
    required String prompt,
    String? flashcardId,
  }) async {
    try {
      // Call Firebase Cloud Function to generate AI response
      final result = await _functions.httpsCallable('generateAIResponse').call({
        'prompt': prompt,
        'userId': userId,
        'flashcardId': flashcardId,
      });

      final response = result.data['response'] as String;

      // Save the interaction
      final interaction = AIInteraction(
        userId: userId,
        prompt: prompt,
        response: response,
      );

      final id = await _repository.add(interaction.toMap());
      return interaction.copyWith(id: id);
    } catch (e) {
      throw Exception('Failed to generate AI response: ${e.toString()}');
    }
  }

  // Generate vocabulary exercises based on user level
  Future<String> generateVocabularyExercises({
    required String userId,
    required String level,
    String? topic,
  }) async {
    try {
      final result = await _functions.httpsCallable('generateVocabularyExercises').call({
        'userId': userId,
        'level': level,
        'topic': topic,
      });

      return result.data['exercises'] as String;
    } catch (e) {
      throw Exception('Failed to generate vocabulary exercises: ${e.toString()}');
    }
  }

  // Generate grammar exercises based on user level
  Future<String> generateGrammarExercises({
    required String userId,
    required String level,
    String? topic,
  }) async {
    try {
      final result = await _functions.httpsCallable('generateGrammarExercises').call({
        'userId': userId,
        'level': level,
        'topic': topic,
      });

      return result.data['exercises'] as String;
    } catch (e) {
      throw Exception('Failed to generate grammar exercises: ${e.toString()}');
    }
  }

  // Translate text
  Future<String> translateText({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    try {
      final result = await _functions.httpsCallable('translateText').call({
        'text': text,
        'targetLanguage': targetLanguage,
        'sourceLanguage': sourceLanguage,
      });

      return result.data['translation'] as String;
    } catch (e) {
      throw Exception('Failed to translate text: ${e.toString()}');
    }
  }

  // Check grammar and get corrections
  Future<Map<String, dynamic>> checkGrammar(String text) async {
    try {
      final result = await _functions.httpsCallable('checkGrammar').call({
        'text': text,
      });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to check grammar: ${e.toString()}');
    }
  }

  // Generate flashcards from text
  Future<List<Map<String, String>>> generateFlashcardsFromText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      final result = await _functions.httpsCallable('generateFlashcards').call({
        'text': text,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      });

      final List<dynamic> flashcardsData = result.data['flashcards'];
      return flashcardsData.map((card) => Map<String, String>.from(card)).toList();
    } catch (e) {
      throw Exception('Failed to generate flashcards: ${e.toString()}');
    }
  }
} 