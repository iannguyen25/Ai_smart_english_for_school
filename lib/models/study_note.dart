import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum NoteType {
  generalNote,    // Ghi chú chung
  question,       // Câu hỏi
  important,      // Điểm quan trọng
  reminder,       // Nhắc nhở
  bookmark        // Đánh dấu
}

extension NoteTypeLabel on NoteType {
  String get label {
    switch (this) {
      case NoteType.generalNote:
        return 'Ghi chú';
      case NoteType.question:
        return 'Câu hỏi';
      case NoteType.important:
        return 'Quan trọng';
      case NoteType.reminder:
        return 'Nhắc nhở';
      case NoteType.bookmark:
        return 'Đánh dấu';
    }
  }

  String get icon {
    switch (this) {
      case NoteType.generalNote:
        return '📝';
      case NoteType.question:
        return '❓';
      case NoteType.important:
        return '⭐';
      case NoteType.reminder:
        return '⏰';
      case NoteType.bookmark:
        return '🔖';
    }
  }
}

class StudyNote extends BaseModel {
  final String userId;           // ID của học viên
  final String lessonId;         // ID của bài học
  final String? itemId;          // ID của item trong bài học (null nếu ghi chú chung)
  final NoteType type;           // Loại ghi chú
  final String content;          // Nội dung ghi chú
  final String? highlightedText; // Đoạn text được highlight (nếu có)
  final int? position;           // Vị trí trong nội dung (nếu có)
  final List<String> tags;       // Tags để phân loại
  final bool isResolved;         // Đã giải quyết chưa (cho câu hỏi)
  final DateTime? reminderTime;   // Thời gian nhắc nhở (cho reminder)
  final Map<String, dynamic>? metadata; // Dữ liệu bổ sung

  StudyNote({
    String? id,
    required this.userId,
    required this.lessonId,
    this.itemId,
    required this.type,
    required this.content,
    this.highlightedText,
    this.position,
    this.tags = const [],
    this.isResolved = false,
    this.reminderTime,
    this.metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory StudyNote.fromMap(Map<String, dynamic> map, String id) {
    return StudyNote(
      id: id,
      userId: map['userId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      itemId: map['itemId'],
      type: _typeFromString(map['type'] ?? 'generalNote'),
      content: map['content'] ?? '',
      highlightedText: map['highlightedText'],
      position: map['position'],
      tags: List<String>.from(map['tags'] ?? []),
      isResolved: map['isResolved'] ?? false,
      reminderTime: map['reminderTime'] != null 
          ? (map['reminderTime'] as Timestamp).toDate()
          : null,
      metadata: map['metadata'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  static NoteType _typeFromString(String type) {
    switch (type) {
      case 'generalNote':
        return NoteType.generalNote;
      case 'question':
        return NoteType.question;
      case 'important':
        return NoteType.important;
      case 'reminder':
        return NoteType.reminder;
      case 'bookmark':
        return NoteType.bookmark;
      default:
        return NoteType.generalNote;
    }
  }

  static String _typeToString(NoteType type) {
    switch (type) {
      case NoteType.generalNote:
        return 'generalNote';
      case NoteType.question:
        return 'question';
      case NoteType.important:
        return 'important';
      case NoteType.reminder:
        return 'reminder';
      case NoteType.bookmark:
        return 'bookmark';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lessonId': lessonId,
      'itemId': itemId,
      'type': _typeToString(type),
      'content': content,
      'highlightedText': highlightedText,
      'position': position,
      'tags': tags,
      'isResolved': isResolved,
      'reminderTime': reminderTime != null 
          ? Timestamp.fromDate(reminderTime!)
          : null,
      'metadata': metadata,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  @override
  StudyNote copyWith({
    String? id,
    String? userId,
    String? lessonId,
    String? itemId,
    NoteType? type,
    String? content,
    String? highlightedText,
    int? position,
    List<String>? tags,
    bool? isResolved,
    DateTime? reminderTime,
    Map<String, dynamic>? metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return StudyNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      content: content ?? this.content,
      highlightedText: highlightedText ?? this.highlightedText,
      position: position ?? this.position,
      tags: tags ?? this.tags,
      isResolved: isResolved ?? this.isResolved,
      reminderTime: reminderTime ?? this.reminderTime,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? userId,
    String? lessonId,
    String? content,
    List<String>? tags,
    DateTime? reminderTime,
  }) {
    Map<String, String?> errors = {};

    if (userId == null || userId.isEmpty) {
      errors['userId'] = 'ID học viên không được để trống';
    }

    if (lessonId == null || lessonId.isEmpty) {
      errors['lessonId'] = 'ID bài học không được để trống';
    }

    if (content == null || content.isEmpty) {
      errors['content'] = 'Nội dung không được để trống';
    }

    if (content != null && content.length > 2000) {
      errors['content'] = 'Nội dung không được quá 2000 ký tự';
    }

    if (tags != null) {
      if (tags.length > 10) {
        errors['tags'] = 'Không được quá 10 tags';
      }
      for (var tag in tags) {
        if (tag.length > 30) {
          errors['tags'] = 'Mỗi tag không được quá 30 ký tự';
          break;
        }
      }
    }

    if (reminderTime != null && reminderTime.isBefore(DateTime.now())) {
      errors['reminderTime'] = 'Thời gian nhắc nhở phải là thời gian trong tương lai';
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      userId: userId,
      lessonId: lessonId,
      content: content,
      tags: tags,
      reminderTime: reminderTime,
    );
  }

  // Tạo mới ghi chú
  static Future<StudyNote?> createNote({
    required String userId,
    required String lessonId,
    String? itemId,
    required NoteType type,
    required String content,
    String? highlightedText,
    int? position,
    List<String> tags = const [],
    DateTime? reminderTime,
    Map<String, dynamic>? metadata,
  }) async {
    final errors = validate(
      userId: userId,
      lessonId: lessonId,
      content: content,
      tags: tags,
      reminderTime: reminderTime,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final noteDoc = await FirebaseFirestore.instance
          .collection('study_notes')
          .add({
        'userId': userId,
        'lessonId': lessonId,
        'itemId': itemId,
        'type': _typeToString(type),
        'content': content,
        'highlightedText': highlightedText,
        'position': position,
        'tags': tags,
        'isResolved': false,
        'reminderTime': reminderTime != null 
            ? Timestamp.fromDate(reminderTime)
            : null,
        'metadata': metadata,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final noteData = await noteDoc.get();
      return StudyNote.fromMap(
        noteData.data() as Map<String, dynamic>,
        noteData.id,
      );
    } catch (e) {
      print('Error creating study note: $e');
      return null;
    }
  }

  // Lấy tất cả ghi chú của một bài học
  static Future<List<StudyNote>> getNotesByLesson(
    String userId,
    String lessonId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('study_notes')
          .where('userId', isEqualTo: userId)
          .where('lessonId', isEqualTo: lessonId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StudyNote.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting notes: $e');
      return [];
    }
  }

  // Lấy tất cả ghi chú của một item
  static Future<List<StudyNote>> getNotesByItem(
    String userId,
    String lessonId,
    String itemId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('study_notes')
          .where('userId', isEqualTo: userId)
          .where('lessonId', isEqualTo: lessonId)
          .where('itemId', isEqualTo: itemId)
          .orderBy('position')
          .get();

      return snapshot.docs
          .map((doc) => StudyNote.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting notes: $e');
      return [];
    }
  }

  // Lấy tất cả bookmark
  static Future<List<StudyNote>> getBookmarks(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('study_notes')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: _typeToString(NoteType.bookmark))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StudyNote.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting bookmarks: $e');
      return [];
    }
  }

  // Lấy tất cả câu hỏi chưa giải quyết
  static Future<List<StudyNote>> getUnresolvedQuestions(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('study_notes')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: _typeToString(NoteType.question))
          .where('isResolved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StudyNote.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting unresolved questions: $e');
      return [];
    }
  }

  // Lấy tất cả reminder sắp đến
  static Future<List<StudyNote>> getUpcomingReminders(String userId) async {
    try {
      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection('study_notes')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: _typeToString(NoteType.reminder))
          .where('reminderTime', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('reminderTime')
          .get();

      return snapshot.docs
          .map((doc) => StudyNote.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting upcoming reminders: $e');
      return [];
    }
  }

  // Cập nhật nội dung ghi chú
  Future<bool> updateContent(String newContent) async {
    try {
      if (id == null) return false;

      final errors = validate(content: newContent);
      if (errors.containsKey('content')) {
        print(errors['content']);
        return false;
      }

      await FirebaseFirestore.instance
          .collection('study_notes')
          .doc(id)
          .update({
        'content': newContent,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating note content: $e');
      return false;
    }
  }

  // Đánh dấu câu hỏi đã giải quyết
  Future<bool> markAsResolved() async {
    try {
      if (id == null || type != NoteType.question) return false;

      await FirebaseFirestore.instance
          .collection('study_notes')
          .doc(id)
          .update({
        'isResolved': true,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error marking question as resolved: $e');
      return false;
    }
  }

  // Cập nhật tags
  Future<bool> updateTags(List<String> newTags) async {
    try {
      if (id == null) return false;

      final errors = validate(tags: newTags);
      if (errors.containsKey('tags')) {
        print(errors['tags']);
        return false;
      }

      await FirebaseFirestore.instance
          .collection('study_notes')
          .doc(id)
          .update({
        'tags': newTags,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating tags: $e');
      return false;
    }
  }

  // Cập nhật thời gian nhắc nhở
  Future<bool> updateReminderTime(DateTime newReminderTime) async {
    try {
      if (id == null || type != NoteType.reminder) return false;

      final errors = validate(reminderTime: newReminderTime);
      if (errors.containsKey('reminderTime')) {
        print(errors['reminderTime']);
        return false;
      }

      await FirebaseFirestore.instance
          .collection('study_notes')
          .doc(id)
          .update({
        'reminderTime': Timestamp.fromDate(newReminderTime),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating reminder time: $e');
      return false;
    }
  }

  // Xóa ghi chú
  Future<bool> delete() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('study_notes')
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }
} 