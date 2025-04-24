import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum ContentType {
  lesson,      // Bài học
  quiz,        // Bài kiểm tra
  material,    // Tài liệu học tập
  exercise,    // Bài tập
  media        // Media (audio, video, image)
}

class VersionChange {
  final String field;         // Trường thay đổi
  final dynamic oldValue;     // Giá trị cũ
  final dynamic newValue;     // Giá trị mới
  final String? description;  // Mô tả thay đổi

  VersionChange({
    required this.field,
    required this.oldValue,
    required this.newValue,
    this.description,
  });

  factory VersionChange.fromMap(Map<String, dynamic> map) {
    return VersionChange(
      field: map['field'] ?? '',
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'description': description,
    };
  }
}

class ContentVersion extends BaseModel {
  final String contentId;           // ID của nội dung
  final ContentType type;           // Loại nội dung
  final String authorId;            // ID người tạo version
  final int versionNumber;          // Số version
  final String title;               // Tiêu đề version
  final String? description;        // Mô tả version
  final List<VersionChange> changes; // Danh sách thay đổi
  final Map<String, dynamic> content; // Nội dung version
  final bool isPublished;           // Đã xuất bản chưa
  final Map<String, dynamic>? metadata; // Dữ liệu bổ sung

  ContentVersion({
    String? id,
    required this.contentId,
    required this.type,
    required this.authorId,
    required this.versionNumber,
    required this.title,
    this.description,
    required this.changes,
    required this.content,
    this.isPublished = false,
    this.metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory ContentVersion.fromMap(Map<String, dynamic> map, String id) {
    return ContentVersion(
      id: id,
      contentId: map['contentId'] ?? '',
      type: _contentTypeFromString(map['type'] ?? 'lesson'),
      authorId: map['authorId'] ?? '',
      versionNumber: map['versionNumber'] ?? 1,
      title: map['title'] ?? '',
      description: map['description'],
      changes: List<VersionChange>.from(
        (map['changes'] ?? []).map((x) => VersionChange.fromMap(x))),
      content: Map<String, dynamic>.from(map['content'] ?? {}),
      isPublished: map['isPublished'] ?? false,
      metadata: map['metadata'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'type': _contentTypeToString(type),
      'authorId': authorId,
      'versionNumber': versionNumber,
      'title': title,
      'description': description,
      'changes': changes.map((x) => x.toMap()).toList(),
      'content': content,
      'isPublished': isPublished,
      'metadata': metadata,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  static ContentType _contentTypeFromString(String type) {
    switch (type) {
      case 'lesson':
        return ContentType.lesson;
      case 'quiz':
        return ContentType.quiz;
      case 'material':
        return ContentType.material;
      case 'exercise':
        return ContentType.exercise;
      case 'media':
        return ContentType.media;
      default:
        return ContentType.lesson;
    }
  }

  static String _contentTypeToString(ContentType type) {
    switch (type) {
      case ContentType.lesson:
        return 'lesson';
      case ContentType.quiz:
        return 'quiz';
      case ContentType.material:
        return 'material';
      case ContentType.exercise:
        return 'exercise';
      case ContentType.media:
        return 'media';
    }
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? contentId,
    String? authorId,
    int? versionNumber,
    String? title,
    Map<String, dynamic>? content,
  }) {
    Map<String, String?> errors = {};

    if (contentId == null || contentId.isEmpty) {
      errors['contentId'] = 'ID nội dung không được để trống';
    }

    if (authorId == null || authorId.isEmpty) {
      errors['authorId'] = 'ID tác giả không được để trống';
    }

    if (versionNumber != null && versionNumber < 1) {
      errors['versionNumber'] = 'Số version phải >= 1';
    }

    if (title == null || title.isEmpty) {
      errors['title'] = 'Tiêu đề không được để trống';
    }

    if (content == null || content.isEmpty) {
      errors['content'] = 'Nội dung không được để trống';
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      contentId: contentId,
      authorId: authorId,
      versionNumber: versionNumber,
      title: title,
      content: content,
    );
  }

  // Tạo version mới
  static Future<ContentVersion?> createVersion({
    required String contentId,
    required ContentType type,
    required String authorId,
    required int versionNumber,
    required String title,
    String? description,
    required List<VersionChange> changes,
    required Map<String, dynamic> content,
    bool isPublished = false,
    Map<String, dynamic>? metadata,
  }) async {
    final errors = validate(
      contentId: contentId,
      authorId: authorId,
      versionNumber: versionNumber,
      title: title,
      content: content,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final versionDoc = await FirebaseFirestore.instance
          .collection('content_versions')
          .add({
        'contentId': contentId,
        'type': _contentTypeToString(type),
        'authorId': authorId,
        'versionNumber': versionNumber,
        'title': title,
        'description': description,
        'changes': changes.map((x) => x.toMap()).toList(),
        'content': content,
        'isPublished': isPublished,
        'metadata': metadata,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final versionData = await versionDoc.get();
      return ContentVersion.fromMap(
        versionData.data() as Map<String, dynamic>,
        versionData.id,
      );
    } catch (e) {
      print('Error creating version: $e');
      return null;
    }
  }

  // Lấy version theo nội dung
  static Future<List<ContentVersion>> getVersionsByContent(String contentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('content_versions')
          .where('contentId', isEqualTo: contentId)
          .orderBy('versionNumber', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ContentVersion.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting versions: $e');
      return [];
    }
  }

  // Lấy version mới nhất
  static Future<ContentVersion?> getLatestVersion(String contentId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('content_versions')
          .where('contentId', isEqualTo: contentId)
          .orderBy('versionNumber', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ContentVersion.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      print('Error getting latest version: $e');
      return null;
    }
  }

  // Lấy version đã xuất bản mới nhất
  static Future<ContentVersion?> getLatestPublishedVersion(
    String contentId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('content_versions')
          .where('contentId', isEqualTo: contentId)
          .where('isPublished', isEqualTo: true)
          .orderBy('versionNumber', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ContentVersion.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      print('Error getting latest published version: $e');
      return null;
    }
  }

  // Xuất bản version
  Future<bool> publish() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('content_versions')
          .doc(id)
          .update({
        'isPublished': true,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error publishing version: $e');
      return false;
    }
  }

  // Hủy xuất bản version
  Future<bool> unpublish() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('content_versions')
          .doc(id)
          .update({
        'isPublished': false,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error unpublishing version: $e');
      return false;
    }
  }

  // Xóa version
  Future<bool> delete() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('content_versions')
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting version: $e');
      return false;
    }
  }

  // So sánh với version khác
  Map<String, List<VersionChange>> compareWith(ContentVersion other) {
    Map<String, List<VersionChange>> differences = {};

    content.forEach((key, value) {
      if (!other.content.containsKey(key)) {
        differences[key] = [
          VersionChange(
            field: key,
            oldValue: null,
            newValue: value,
            description: 'Field added',
          )
        ];
      } else if (other.content[key] != value) {
        differences[key] = [
          VersionChange(
            field: key,
            oldValue: other.content[key],
            newValue: value,
            description: 'Field modified',
          )
        ];
      }
    });

    other.content.forEach((key, value) {
      if (!content.containsKey(key)) {
        differences[key] = [
          VersionChange(
            field: key,
            oldValue: value,
            newValue: null,
            description: 'Field removed',
          )
        ];
      }
    });

    return differences;
  }

  @override
  ContentVersion copyWith({
    String? id,
    String? contentId,
    ContentType? type,
    String? authorId,
    int? versionNumber,
    String? title,
    String? description,
    List<VersionChange>? changes,
    Map<String, dynamic>? content,
    bool? isPublished,
    Map<String, dynamic>? metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ContentVersion(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      type: type ?? this.type,
      authorId: authorId ?? this.authorId,
      versionNumber: versionNumber ?? this.versionNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      changes: changes ?? this.changes,
      content: content ?? this.content,
      isPublished: isPublished ?? this.isPublished,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 