import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class SearchHistory extends BaseModel {
  final String userId;
  final String word;
  final String? meaning;
  final Timestamp? searchedAt;
  
  SearchHistory({
    String? id,
    required this.userId,
    required this.word,
    this.meaning,
    this.searchedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory SearchHistory.fromMap(Map<String, dynamic> map, String id) {
    return SearchHistory(
      id: id,
      userId: map['userId'] ?? '',
      word: map['word'] ?? '',
      meaning: map['meaning'],
      searchedAt: map['searchedAt'] as Timestamp? ?? Timestamp.now(),
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'word': word,
      'meaning': meaning,
      'searchedAt': searchedAt ?? Timestamp.now(),
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  @override
  SearchHistory copyWith({
    String? id,
    String? userId,
    String? word,
    String? meaning,
    Timestamp? searchedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return SearchHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      searchedAt: searchedAt ?? this.searchedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Lưu lịch sử tìm kiếm mới
  static Future<void> saveSearchHistory({
    required String userId,
    required String word,
    String? meaning,
  }) async {
    try {
      // Kiểm tra xem từ này đã được tìm kiếm trước đó chưa
      final existingQuery = await FirebaseFirestore.instance
          .collection('searchHistory')
          .where('userId', isEqualTo: userId)
          .where('word', isEqualTo: word)
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        // Cập nhật thời gian tìm kiếm mới nhất
        final existingDoc = existingQuery.docs.first;
        await FirebaseFirestore.instance
            .collection('searchHistory')
            .doc(existingDoc.id)
            .update({
          'searchedAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'meaning': meaning,
        });
      } else {
        // Tạo bản ghi mới
        final newHistory = SearchHistory(
          userId: userId,
          word: word,
          meaning: meaning,
          searchedAt: Timestamp.now(),
        );

        await FirebaseFirestore.instance
            .collection('searchHistory')
            .add(newHistory.toMap());
      }
    } catch (e) {
      print('Error saving search history: $e');
    }
  }

  // Lấy lịch sử tìm kiếm của người dùng
  static Future<List<SearchHistory>> getUserSearchHistory(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('searchHistory')
          .where('userId', isEqualTo: userId)
          .orderBy('searchedAt', descending: true)
          .limit(20) // Giới hạn 20 từ gần nhất
          .get();

      return snapshot.docs
          .map((doc) => SearchHistory.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting user search history: $e');
      return [];
    }
  }

  // Xóa một mục lịch sử tìm kiếm
  static Future<bool> deleteSearchHistory(String historyId) async {
    try {
      await FirebaseFirestore.instance
          .collection('searchHistory')
          .doc(historyId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting search history: $e');
      return false;
    }
  }

  // Xóa tất cả lịch sử tìm kiếm của người dùng
  static Future<bool> clearUserSearchHistory(String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('searchHistory')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error clearing user search history: $e');
      return false;
    }
  }
} 