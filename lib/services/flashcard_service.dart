import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flashcard.dart';
import '../models/flashcard_item.dart';
import 'storage_service.dart';

class FlashcardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  // Collection references
  CollectionReference get _flashcardsRef => _firestore.collection('flashcards');
  CollectionReference get _flashcardItemsRef =>
      _firestore.collection('flashcard_items');

  // Create a new flashcard set
  Future<String> createFlashcard(Flashcard flashcard) async {
    try {
      final docRef = await _flashcardsRef.add(flashcard.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating flashcard: $e');
      throw 'Không thể tạo bộ thẻ mới';
    }
  }

  // Update an existing flashcard set
  Future<void> updateFlashcard(Flashcard flashcard) async {
    try {
      await _flashcardsRef.doc(flashcard.id).update(flashcard.toMap());
    } catch (e) {
      print('Error updating flashcard: $e');
      throw 'Không thể cập nhật bộ thẻ';
    }
  }

  // Get a flashcard set by ID
  Future<Flashcard?> getFlashcardById(String id) async {
    try {
      final doc = await _flashcardsRef.doc(id).get();
      if (!doc.exists) return null;
      return Flashcard.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error getting flashcard: $e');
      throw 'Không thể tải bộ thẻ';
    }
  }

  // Get all flashcards for a user
  Future<List<Flashcard>> getUserFlashcards(String userId) async {
    try {
      print('Getting flashcards from Firestore for user: $userId');
      // Lấy danh sách flashcards
      final flashcardsSnapshot = await _firestore
          .collection('flashcards')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      print('Firestore query returned: ${flashcardsSnapshot.docs.length} documents');
      
      // Tạo list flashcards với items rỗng
      final flashcards = flashcardsSnapshot.docs
          .map((doc) {
            print('Processing flashcard document: ${doc.id}');
            print('Document data: ${doc.data()}');
            return Flashcard.fromMap(doc.data(), doc.id);
          })
          .toList();

      // Lấy items cho từng flashcard
      for (var flashcard in flashcards) {
        print('Getting items for flashcard: ${flashcard.id}');
        final itemsSnapshot = await _firestore
            .collection('flashcard_items')
            .where('flashcardId', isEqualTo: flashcard.id)
            .get();

        print('Found ${itemsSnapshot.docs.length} items for flashcard ${flashcard.id}');
        
        final items = itemsSnapshot.docs
            .map((doc) => FlashcardItem.fromMap(doc.data(), doc.id))
            .toList();

        // Cập nhật flashcard với items
        flashcards[flashcards.indexOf(flashcard)] = flashcard.copyWith(items: items);
      }

      print('Returning ${flashcards.length} flashcards with items');
      return flashcards;
    } catch (e) {
      print('Error getting user flashcards: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Get public flashcards
  Future<List<Flashcard>> getPublicFlashcards() async {
    try {
      // Chỉ query theo isPublic và approvalStatus
      final snapshot = await _flashcardsRef
          .where('isPublic', isEqualTo: true)
          .where('approvalStatus', isEqualTo: 'approved')
          .get();
      
      final flashcards = snapshot.docs.map((doc) {
        return Flashcard.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Sắp xếp locally
      flashcards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return flashcards;
    } catch (e) {
      print('Error getting public flashcards: $e');
      throw 'Không thể tải danh sách bộ thẻ công khai';
    }
  }

  // Search flashcards
  Future<List<Flashcard>> searchFlashcards({
    required String query,
    String? userId,
  }) async {
    try {
      Query flashcardsQuery = _flashcardsRef;

      // If userId is provided, get user's private cards and all public cards
      if (userId != null) {
        flashcardsQuery = flashcardsQuery.where(Filter.or(
          Filter('userId', isEqualTo: userId),
          Filter('isPublic', isEqualTo: true),
        ));
      } else {
        // If no userId, only get public cards
        flashcardsQuery = flashcardsQuery.where('isPublic', isEqualTo: true);
      }

      final snapshot = await flashcardsQuery.get();

      // Filter results locally based on title and description
      final results = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['title'] as String).toLowerCase();
        final description = (data['description'] as String).toLowerCase();
        final searchQuery = query.toLowerCase();

        return title.contains(searchQuery) || description.contains(searchQuery);
      }).map((doc) {
        return Flashcard.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      return results;
    } catch (e) {
      print('Error searching flashcards: $e');
      throw 'Không thể tìm kiếm bộ thẻ';
    }
  }

  // Delete a flashcard set and its items
  Future<void> deleteFlashcard(String flashcardId) async {
    try {
      // Delete all items first
      final itemsSnapshot = await _flashcardItemsRef
          .where('flashcardId', isEqualTo: flashcardId)
          .get();

      for (var doc in itemsSnapshot.docs) {
        final item =
            FlashcardItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (item.questionImage != null) {
          await _storageService.deleteFile(item.questionImage!);
        }
        if (item.answerImage != null) {
          await _storageService.deleteFile(item.answerImage!);
        }
        await doc.reference.delete();
      }

      // Then delete the flashcard set
      await _flashcardsRef.doc(flashcardId).delete();
    } catch (e) {
      print('Error deleting flashcard: $e');
      throw 'Không thể xóa bộ thẻ';
    }
  }

  // Toggle flashcard visibility
  Future<void> toggleFlashcardVisibility(String flashcardId) async {
    try {
      final doc = await _flashcardsRef.doc(flashcardId).get();
      if (!doc.exists) throw 'Bộ thẻ không tồn tại';

      final currentVisibility =
          (doc.data() as Map<String, dynamic>)['isPublic'] ?? false;
      await doc.reference.update({
        'isPublic': !currentVisibility,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error toggling flashcard visibility: $e');
      throw 'Không thể thay đổi trạng thái công khai';
    }
  }

  // Create a new flashcard item
  Future<String> createFlashcardItem(FlashcardItem item) async {
    try {
      final docRef = await _flashcardItemsRef.add(item.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating flashcard item: $e');
      throw 'Không thể tạo thẻ mới';
    }
  }

  // Update an existing flashcard item
  Future<void> updateFlashcardItem(FlashcardItem item) async {
    try {
      await _flashcardItemsRef.doc(item.id).update(item.toMap());
    } catch (e) {
      print('Error updating flashcard item: $e');
      throw 'Không thể cập nhật thẻ';
    }
  }

  // Get all items for a flashcard set
  Future<List<FlashcardItem>> getFlashcardItems(String flashcardId) async {
    try {
      final snapshot = await _flashcardItemsRef
          .where('flashcardId', isEqualTo: flashcardId)
          .orderBy('createdAt')
          .get();

      return snapshot.docs.map((doc) {
        return FlashcardItem.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting flashcard items: $e');
      throw 'Không thể tải danh sách thẻ';
    }
  }

  // Delete a flashcard item
  Future<void> deleteFlashcardItem(String itemId) async {
    try {
      final doc = await _flashcardItemsRef.doc(itemId).get();
      if (!doc.exists) return;

      final item =
          FlashcardItem.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      if (item.questionImage != null) {
        await _storageService.deleteFile(item.questionImage!);
      }
      if (item.answerImage != null) {
        await _storageService.deleteFile(item.answerImage!);
      }

      await doc.reference.delete();
    } catch (e) {
      print('Error deleting flashcard item: $e');
      throw 'Không thể xóa thẻ';
    }
  }

  // Thêm phương thức getFlashcardsByIds
  Future<List<Flashcard>> getFlashcardsByIds(List<String> flashcardIds) async {
    try {
      if (flashcardIds.isEmpty) return [];

      // Lấy danh sách flashcards
      final flashcardsSnapshot = await _firestore
          .collection('flashcards')
          .where(FieldPath.documentId, whereIn: flashcardIds)
          .get();

      // Tạo list flashcards với items rỗng
      final flashcards = flashcardsSnapshot.docs
          .map((doc) => Flashcard.fromMap(doc.data(), doc.id))
          .toList();

      // Lấy items cho từng flashcard
      for (var flashcard in flashcards) {
        final itemsSnapshot = await _firestore
            .collection('flashcard_items')
            .where('flashcardId', isEqualTo: flashcard.id)
            .get();

        final items = itemsSnapshot.docs
            .map((doc) => FlashcardItem.fromMap(doc.data(), doc.id))
            .toList();

        // Cập nhật flashcard với items
        flashcards[flashcards.indexOf(flashcard)] = flashcard.copyWith(items: items);
      }

      return flashcards;
    } catch (e) {
      print('Error getting flashcards: $e');
      rethrow;
    }
  }

  // Get flashcards by lesson ID
  Future<List<Flashcard>> getLessonFlashcards(String lessonId) async {
    try {
      // Chỉ query theo lessonId, không dùng orderBy
      final snapshot = await _flashcardsRef
          .where('lessonId', isEqualTo: lessonId)
          .get();
      
      final flashcards = snapshot.docs.map((doc) => 
        Flashcard.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();

      // Sắp xếp locally
      flashcards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return flashcards;
    } catch (e) {
      print('Error getting lesson flashcards: $e');
      throw 'Không thể tải danh sách thẻ ghi nhớ của bài học';
    }
  }
}
