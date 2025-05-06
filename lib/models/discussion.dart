import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum DiscussionType {
  question,       // Câu hỏi
  answer,         // Câu trả lời
  comment,        // Bình luận
  explanation,    // Giải thích
  feedback,       // Phản hồi
  suggestion      // Đề xuất
}

extension DiscussionTypeLabel on DiscussionType {
  String get label {
    switch (this) {
      case DiscussionType.question:
        return 'Câu hỏi';
      case DiscussionType.answer:
        return 'Câu trả lời';
      case DiscussionType.comment:
        return 'Bình luận';
      case DiscussionType.explanation:
        return 'Giải thích';
      case DiscussionType.feedback:
        return 'Phản hồi';
      case DiscussionType.suggestion:
        return 'Đề xuất';
    }
  }

  String get icon {
    switch (this) {
      case DiscussionType.question:
        return '❓';
      case DiscussionType.answer:
        return '✅';
      case DiscussionType.comment:
        return '💭';
      case DiscussionType.explanation:
        return '📝';
      case DiscussionType.feedback:
        return '📢';
      case DiscussionType.suggestion:
        return '💡';
    }
  }
}

class Discussion extends BaseModel {
  final String userId;           // ID của người tạo
  final String? classroomId;     // ID của lớp học
  final String? lessonId;        // ID của bài học (nếu có)
  final String? itemId;          // ID của item trong bài học (nếu có)
  final String? parentId;        // ID của discussion cha (nếu là reply)
  final String content;          // Nội dung thảo luận
  final DiscussionType type;     // Loại thảo luận
  final List<String> mentions;   // Danh sách người dùng được mention (@)
  final List<String> attachments; // Danh sách file đính kèm
  final List<String> likes;      // Danh sách người dùng đã like
  final bool isResolved;         // Đánh dấu đã giải quyết (cho câu hỏi)
  final bool isPinned;           // Ghim thảo luận
  final Map<String, dynamic>? metadata; // Dữ liệu bổ sung
  final String? userName;        // Tên người dùng
  final String? userAvatar;      // Avatar người dùng

  Discussion({
    String? id,
    required this.userId,
    this.classroomId,
    this.lessonId,
    this.itemId,
    this.parentId,
    required this.content,
    required this.type,
    this.mentions = const [],
    this.attachments = const [],
    this.likes = const [],
    this.isResolved = false,
    this.isPinned = false,
    this.metadata,
    this.userName,
    this.userAvatar,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory Discussion.fromMap(Map<String, dynamic> map, String id) {
    return Discussion(
      id: id,
      userId: map['userId'] ?? '',
      classroomId: map['classroomId'],
      lessonId: map['lessonId'],
      itemId: map['itemId'],
      parentId: map['parentId'],
      content: map['content'] ?? '',
      type: _typeFromString(map['type'] ?? 'comment'),
      mentions: List<String>.from(map['mentions'] ?? []),
      attachments: List<String>.from(map['attachments'] ?? []),
      likes: List<String>.from(map['likes'] ?? []),
      isResolved: map['isResolved'] ?? false,
      isPinned: map['isPinned'] ?? false,
      metadata: map['metadata'],
      userName: map['userName'],
      userAvatar: map['userAvatar'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  static DiscussionType _typeFromString(String type) {
    switch (type) {
      case 'question':
        return DiscussionType.question;
      case 'answer':
        return DiscussionType.answer;
      case 'comment':
        return DiscussionType.comment;
      case 'explanation':
        return DiscussionType.explanation;
      case 'feedback':
        return DiscussionType.feedback;
      case 'suggestion':
        return DiscussionType.suggestion;
      default:
        return DiscussionType.comment;
    }
  }

  static String _typeToString(DiscussionType type) {
    switch (type) {
      case DiscussionType.question:
        return 'question';
      case DiscussionType.answer:
        return 'answer';
      case DiscussionType.comment:
        return 'comment';
      case DiscussionType.explanation:
        return 'explanation';
      case DiscussionType.feedback:
        return 'feedback';
      case DiscussionType.suggestion:
        return 'suggestion';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'classroomId': classroomId,
      'lessonId': lessonId,
      'itemId': itemId,
      'parentId': parentId,
      'content': content,
      'type': _typeToString(type),
      'mentions': mentions,
      'attachments': attachments,
      'likes': likes,
      'isResolved': isResolved,
      'isPinned': isPinned,
      'metadata': metadata,
      'userName': userName,
      'userAvatar': userAvatar,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  @override
  Discussion copyWith({
    String? id,
    String? userId,
    String? classroomId,
    String? lessonId,
    String? itemId,
    String? parentId,
    String? content,
    DiscussionType? type,
    List<String>? mentions,
    List<String>? attachments,
    List<String>? likes,
    bool? isResolved,
    bool? isPinned,
    Map<String, dynamic>? metadata,
    String? userName,
    String? userAvatar,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Discussion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      classroomId: classroomId ?? this.classroomId,
      lessonId: lessonId ?? this.lessonId,
      itemId: itemId ?? this.itemId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      type: type ?? this.type,
      mentions: mentions ?? this.mentions,
      attachments: attachments ?? this.attachments,
      likes: likes ?? this.likes,
      isResolved: isResolved ?? this.isResolved,
      isPinned: isPinned ?? this.isPinned,
      metadata: metadata ?? this.metadata,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? content,
  }) {
    Map<String, String?> errors = {};
    
    if (content == null || content.trim().isEmpty) {
      errors['content'] = 'Nội dung không được để trống';
    }
    
    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      content: content,
    );
  }

  // Create a new discussion
  static Future<Discussion?> create({
    required String userId,
    required String content,
    required DiscussionType type,
    String? classroomId,
    String? lessonId,
    String? itemId,
    String? parentId,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('discussions').add({
        'userId': userId,
        'classroomId': classroomId,
        'content': content,
        'type': _typeToString(type),
        'lessonId': lessonId,
        'itemId': itemId,
        'parentId': parentId,
        'mentions': [],
        'attachments': [],
        'likes': [],
        'isResolved': false,
        'isPinned': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final data = await doc.get();
      return Discussion.fromMap(data.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error creating discussion: $e');
      return null;
    }
  }

  // Lấy thảo luận theo bài học
  static Future<List<Discussion>> getDiscussionsByLesson(
    String lessonId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = FirebaseFirestore.instance
          .collection('discussions')
          .where('lessonId', isEqualTo: lessonId)
          .where('parentId', isNull: true)
          .orderBy('isPinned', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Discussion.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting discussions: $e');
      return [];
    }
  }

  // Lấy các reply của một thảo luận
  static Future<List<Discussion>> getReplies(
    String discussionId, {
    String? classroomId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = FirebaseFirestore.instance
          .collection('discussions')
          .where('parentId', isEqualTo: discussionId)
          .orderBy('createdAt', descending: false);

      final snapshot = await query.get();
      var replies = snapshot.docs
          .map((doc) => Discussion.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by createdAt
      replies.sort((a, b) {
        final aTime = a.createdAt?.toDate() ?? DateTime.now();
        final bTime = b.createdAt?.toDate() ?? DateTime.now();
        return aTime.compareTo(bTime);
      });

      return replies.take(limit).toList();
    } catch (e) {
      print('Error getting replies: $e');
      return [];
    }
  }

  // Cập nhật nội dung thảo luận
  Future<bool> updateContent(String newContent) async {
    try {
      if (id == null) return false;

      final errors = validate(content: newContent);
      if (errors.isNotEmpty) {
        print('Validation errors: $errors');
        return false;
      }

      await FirebaseFirestore.instance
          .collection('discussions')
          .doc(id)
          .update({
        'content': newContent,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating discussion: $e');
      return false;
    }
  }

  // Like/Unlike thảo luận
  Future<bool> toggleLike(String userId) async {
    try {
      if (id == null) return false;

      final List<String> updatedLikes = List.from(likes);
      if (updatedLikes.contains(userId)) {
        updatedLikes.remove(userId);
      } else {
        updatedLikes.add(userId);
      }

      await FirebaseFirestore.instance
          .collection('discussions')
          .doc(id)
          .update({
        'likes': updatedLikes,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Đánh dấu đã giải quyết (cho câu hỏi)
  Future<bool> markAsResolved() async {
    try {
      if (id == null || type != DiscussionType.question) return false;

      await FirebaseFirestore.instance
          .collection('discussions')
          .doc(id)
          .update({
        'isResolved': true,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error marking as resolved: $e');
      return false;
    }
  }

  // Ghim/Bỏ ghim thảo luận
  Future<bool> togglePin() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('discussions')
          .doc(id)
          .update({
        'isPinned': !isPinned,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error toggling pin: $e');
      return false;
    }
  }

  // Xóa thảo luận
  Future<bool> delete() async {
    try {
      if (id == null) return false;

      // Xóa tất cả các reply trước
      final replies = await getReplies(id!, classroomId: classroomId);
      for (var reply in replies) {
        await reply.delete();
      }

      await FirebaseFirestore.instance
          .collection('discussions')
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting discussion: $e');
      return false;
    }
  }

  // Lấy số lượng reply của một thảo luận
  static Future<int> getReplyCount(String discussionId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('discussions')
          .where('parentId', isEqualTo: discussionId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting reply count: $e');
      return 0;
    }
  }

  // Tìm kiếm thảo luận
  static Future<List<Discussion>> searchDiscussions(
    String query, {
    String? lessonId,
    int limit = 20,
  }) async {
    try {
      var baseQuery = FirebaseFirestore.instance
          .collection('discussions')
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThanOrEqualTo: query + '\uf8ff')
          .orderBy('content')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lessonId != null) {
        baseQuery = baseQuery.where('lessonId', isEqualTo: lessonId);
      }

      final snapshot = await baseQuery.get();
      return snapshot.docs
          .map((doc) => Discussion.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error searching discussions: $e');
      return [];
    }
  }
} 