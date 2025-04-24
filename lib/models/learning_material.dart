import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum MaterialType { document, video, audio, image, link, other }

extension MaterialTypeLabel on MaterialType {
  String get label {
    switch (this) {
      case MaterialType.document:
        return 'Tài liệu';
      case MaterialType.video:
        return 'Video';
      case MaterialType.audio:
        return 'Âm thanh';
      case MaterialType.image:
        return 'Hình ảnh';
      case MaterialType.link:
        return 'Đường dẫn';
      default:
        return 'Khác';
    }
  }
}

class LearningMaterial extends BaseModel {
  final String title;
  final String description;
  final String authorId;
  final String? authorName;
  final MaterialType type;
  final String? fileUrl;
  final String? thumbnailUrl;
  final int? fileSize; // Kích thước tính bằng KB
  final String? classroomId; // ID lớp học, null nếu chia sẻ tất cả
  final bool isPublic; // Có công khai cho mọi người không
  final List<String> tags;
  final int downloads;
  final List<String> allowedRoles; // Vai trò có thể xem (admin, teacher, student)

  LearningMaterial({
    String? id,
    required this.title,
    required this.description,
    required this.authorId,
    this.authorName,
    required this.type,
    this.fileUrl,
    this.thumbnailUrl,
    this.fileSize,
    this.classroomId,
    this.isPublic = false,
    this.tags = const [],
    this.downloads = 0,
    this.allowedRoles = const ['admin', 'teacher', 'student'],
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory LearningMaterial.fromMap(Map<String, dynamic> map, String id) {
    return LearningMaterial(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'],
      type: _typeFromString(map['type'] ?? 'document'),
      fileUrl: map['fileUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      fileSize: map['fileSize'],
      classroomId: map['classroomId'],
      isPublic: map['isPublic'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      downloads: map['downloads'] ?? 0,
      allowedRoles: List<String>.from(map['allowedRoles'] ?? ['admin', 'teacher', 'student']),
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  static MaterialType _typeFromString(String type) {
    switch (type) {
      case 'document':
        return MaterialType.document;
      case 'video':
        return MaterialType.video;
      case 'audio':
        return MaterialType.audio;
      case 'image':
        return MaterialType.image;
      case 'link':
        return MaterialType.link;
      default:
        return MaterialType.other;
    }
  }

  static String _typeToString(MaterialType type) {
    switch (type) {
      case MaterialType.document:
        return 'document';
      case MaterialType.video:
        return 'video';
      case MaterialType.audio:
        return 'audio';
      case MaterialType.image:
        return 'image';
      case MaterialType.link:
        return 'link';
      case MaterialType.other:
        return 'other';
    }
  }

  String get typeLabel => type.label;

  String? get fileSizeFormatted {
    if (fileSize == null) return null;
    if (fileSize! < 1024) {
      return '$fileSize KB';
    } else {
      final mbSize = (fileSize! / 1024).toStringAsFixed(1);
      return '$mbSize MB';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'authorId': authorId,
      'authorName': authorName,
      'type': _typeToString(type),
      'fileUrl': fileUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileSize': fileSize,
      'classroomId': classroomId,
      'isPublic': isPublic,
      'tags': tags,
      'downloads': downloads,
      'allowedRoles': allowedRoles,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  @override
  LearningMaterial copyWith({
    String? id,
    String? title,
    String? description,
    String? authorId,
    String? authorName,
    MaterialType? type,
    String? fileUrl,
    String? thumbnailUrl,
    int? fileSize,
    String? classroomId,
    bool? isPublic,
    List<String>? tags,
    int? downloads,
    List<String>? allowedRoles,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return LearningMaterial(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileSize: fileSize ?? this.fileSize,
      classroomId: classroomId ?? this.classroomId,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      downloads: downloads ?? this.downloads,
      allowedRoles: allowedRoles ?? this.allowedRoles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Lấy danh sách tài liệu học tập của lớp học
  static Future<List<LearningMaterial>> getMaterialsByClassroom(String classroomId) async {
    List<LearningMaterial> materials = [];
    
    print('Getting materials for classroom ID: $classroomId');
    
    // Thử truy cập collection "materials" trước
    try {
      print('Trying to access "materials" collection for classroom...');
      final snapshot = await FirebaseFirestore.instance
          .collection('materials')
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('createdAt', descending: true)
          .get();

      materials = snapshot.docs
          .map((doc) => LearningMaterial.fromMap(doc.data(), doc.id))
          .toList();
      
      print('Found ${materials.length} materials in "materials" collection for classroom');
    } catch (e) {
      print('Error getting materials from "materials" collection for classroom: $e');
    }
    
    // Nếu không có kết quả từ "materials", thử "learningMaterials"
    if (materials.isEmpty) {
      try {
        print('Trying to access "learningMaterials" collection for classroom...');
        final snapshot = await FirebaseFirestore.instance
            .collection('learningMaterials')
            .where('classroomId', isEqualTo: classroomId)
            .orderBy('createdAt', descending: true)
            .get();

        materials = snapshot.docs
            .map((doc) => LearningMaterial.fromMap(doc.data(), doc.id))
            .toList();
        
        print('Found ${materials.length} materials in "learningMaterials" collection for classroom');
      } catch (e) {
        print('Error getting materials from "learningMaterials" collection for classroom: $e');
      }
    }
    
    return materials;
  }

  // Lấy danh sách tài liệu công khai
  static Future<List<LearningMaterial>> getPublicMaterials() async {
    List<LearningMaterial> materials = [];
    
    print('Getting public materials');
    
    // Thử truy cập collection "materials" trước
    try {
      print('Trying to access "materials" collection for public materials...');
      final snapshot = await FirebaseFirestore.instance
          .collection('materials')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      materials = snapshot.docs
          .map((doc) => LearningMaterial.fromMap(doc.data(), doc.id))
          .toList();
      
      print('Found ${materials.length} public materials in "materials" collection');
    } catch (e) {
      print('Error getting public materials from "materials" collection: $e');
    }
    
    // Nếu không có kết quả từ "materials", thử "learningMaterials"
    if (materials.isEmpty) {
      try {
        print('Trying to access "learningMaterials" collection for public materials...');
        final snapshot = await FirebaseFirestore.instance
            .collection('learningMaterials')
            .where('isPublic', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        materials = snapshot.docs
            .map((doc) => LearningMaterial.fromMap(doc.data(), doc.id))
            .toList();
        
        print('Found ${materials.length} public materials in "learningMaterials" collection');
      } catch (e) {
        print('Error getting public materials from "learningMaterials" collection: $e');
      }
    }
    
    return materials;
  }

  // Lấy danh sách tài liệu của giáo viên
  static Future<List<LearningMaterial>> getMaterialsByAuthor(String authorId) async {
    List<LearningMaterial> materials = [];
    
    // In ra log cho debugging
    print('Getting materials for author ID: $authorId');
    
    // Thử truy cập collection "materials" trước
    try {
      print('Trying to access "materials" collection...');
      final snapshot = await FirebaseFirestore.instance
          .collection('materials')
          .where('authorId', isEqualTo: authorId)
          .orderBy('createdAt', descending: true)
          .get();

      materials = snapshot.docs
          .map((doc) => LearningMaterial.fromMap(doc.data(), doc.id))
          .toList();
      
      print('Found ${materials.length} materials in "materials" collection');
    } catch (e) {
      print('Error getting materials from "materials" collection: $e');
    }
    
    // Nếu không có kết quả từ "materials", thử "learningMaterials"
    if (materials.isEmpty) {
      try {
        print('Trying to access "learningMaterials" collection...');
        final snapshot = await FirebaseFirestore.instance
            .collection('learningMaterials')
            .where('authorId', isEqualTo: authorId)
            .orderBy('createdAt', descending: true)
            .get();

        materials = snapshot.docs
            .map((doc) => LearningMaterial.fromMap(doc.data(), doc.id))
            .toList();
        
        print('Found ${materials.length} materials in "learningMaterials" collection');
      } catch (e) {
        print('Error getting materials from "learningMaterials" collection: $e');
      }
    }
    
    return materials;
  }

  // Tìm kiếm tài liệu theo từ khóa
  static Future<List<LearningMaterial>> searchMaterials(String query) async {
    try {
      // Firebase không hỗ trợ tìm kiếm text nên chúng ta phải lấy tất cả và lọc
      final snapshot = await FirebaseFirestore.instance
          .collection('learningMaterials')
          .get();

      final allMaterials = snapshot.docs
          .map((doc) => LearningMaterial.fromMap(doc.data(), doc.id))
          .toList();

      // Lọc theo keyword
      final keyword = query.toLowerCase();
      return allMaterials.where((material) =>
          material.title.toLowerCase().contains(keyword) ||
          material.description.toLowerCase().contains(keyword) ||
          material.tags.any((tag) => tag.toLowerCase().contains(keyword))
      ).toList();
    } catch (e) {
      print('Error searching materials: $e');
      return [];
    }
  }

  // Tăng số lượt tải
  Future<bool> incrementDownload() async {
    try {
      if (id == null) return false;
      
      await FirebaseFirestore.instance
          .collection('learningMaterials')
          .doc(id)
          .update({
        'downloads': downloads + 1,
      });
      
      return true;
    } catch (e) {
      print('Error incrementing download count: $e');
      return false;
    }
  }

  // Thêm phương thức validate
  static Map<String, String?> validate({
    String? title,
    String? description,
    String? authorId,
    MaterialType? type,
    String? fileUrl,
    int? fileSize,
    List<String>? tags,
  }) {
    Map<String, String?> errors = {};
    
    final titleError = InputValidator.validateTitle(title);
    if (titleError != null) {
      errors['title'] = titleError;
    }

    final descriptionError = InputValidator.validateDescription(description);
    if (descriptionError != null) {
      errors['description'] = descriptionError;
    }

    if (authorId == null || authorId.isEmpty) {
      errors['authorId'] = 'ID tác giả không được để trống';
    }

    if (type == null) {
      errors['type'] = 'Loại tài liệu không được để trống';
    }

    if (fileUrl != null) {
      final urlError = InputValidator.validateUrl(fileUrl);
      if (urlError != null) {
        errors['fileUrl'] = urlError;
      }
    }

    if (fileSize != null) {
      final fileSizeError = InputValidator.validateFileSize(fileSize);
      if (fileSizeError != null) {
        errors['fileSize'] = fileSizeError;
      }
    }

    if (tags != null) {
      final tagsError = InputValidator.validateTags(tags);
      if (tagsError != null) {
        errors['tags'] = tagsError;
      }
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      title: title,
      description: description,
      authorId: authorId,
      type: type,
      fileUrl: fileUrl,
      fileSize: fileSize,
      tags: tags,
    );
  }

  // Cập nhật phương thức tạo tài liệu để thêm validation
  static Future<LearningMaterial?> createMaterial({
    required String title,
    required String description,
    required String authorId,
    String? authorName,
    required MaterialType type,
    String? fileUrl,
    String? thumbnailUrl,
    int? fileSize,
    String? classroomId,
    bool isPublic = false,
    List<String> tags = const [],
    List<String> allowedRoles = const ['admin', 'teacher', 'student'],
  }) async {
    // Validate input
    final errors = validate(
      title: title,
      description: description,
      authorId: authorId,
      type: type,
      fileUrl: fileUrl,
      fileSize: fileSize,
      tags: tags,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final materialDoc = await FirebaseFirestore.instance.collection('materials').add({
        'title': title,
        'description': description,
        'authorId': authorId,
        'authorName': authorName,
        'type': _typeToString(type),
        'fileUrl': fileUrl,
        'thumbnailUrl': thumbnailUrl,
        'fileSize': fileSize,
        'classroomId': classroomId,
        'isPublic': isPublic,
        'tags': tags,
        'downloads': 0,
        'allowedRoles': allowedRoles,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final materialData = await materialDoc.get();
      return LearningMaterial.fromMap(materialData.data() as Map<String, dynamic>, materialData.id);
    } catch (e) {
      print('Error creating learning material: $e');
      return null;
    }
  }
} 