import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum GradeLevel {
  grade1,    // Lớp 1
  grade2,    // Lớp 2
  grade3,    // Lớp 3
  grade4,    // Lớp 4
  grade5,    // Lớp 5
  grade6,    // Lớp 6
  grade7,    // Lớp 7
  grade8,    // Lớp 8
  grade9,    // Lớp 9
  custom     // Tùy chỉnh
}

extension GradeLevelLabel on GradeLevel {
  String get label {
    switch (this) {
      case GradeLevel.grade1:
        return 'Lớp 1';
      case GradeLevel.grade2:
        return 'Lớp 2';
      case GradeLevel.grade3:
        return 'Lớp 3';
      case GradeLevel.grade4:
        return 'Lớp 4';
      case GradeLevel.grade5:
        return 'Lớp 5';
      case GradeLevel.grade6:
        return 'Lớp 6';
      case GradeLevel.grade7:
        return 'Lớp 7';
      case GradeLevel.grade8:
        return 'Lớp 8';
      case GradeLevel.grade9:
        return 'Lớp 9';
      case GradeLevel.custom:
        return 'Tùy chỉnh';
    }
  }
  
  int get gradeNumber {
    switch (this) {
      case GradeLevel.grade1:
        return 1;
      case GradeLevel.grade2:
        return 2;
      case GradeLevel.grade3:
        return 3;
      case GradeLevel.grade4:
        return 4;
      case GradeLevel.grade5:
        return 5;
      case GradeLevel.grade6:
        return 6;
      case GradeLevel.grade7:
        return 7;
      case GradeLevel.grade8:
        return 8;
      case GradeLevel.grade9:
        return 9;
      case GradeLevel.custom:
        return 0;
    }
  }
}

class Course extends BaseModel {
  final String name;             // Tên khóa học (có thể là tên SGK, Unit,...)
  final String description;      // Mô tả
  final String? imageUrl;        // Ảnh minh họa
  final GradeLevel gradeLevel;   // Cấp lớp (Lớp 1-9)
  final bool isTextbook;         // Là SGK hay tài liệu riêng của trung tâm
  final String textbookName;     // Tên sách giáo khoa (nếu là SGK)
  final String publisher;        // Nhà xuất bản (nếu là SGK)
  final List<String> materialIds; // Tài liệu chung (ID)
  final List<String> questionSetIds; // Bộ câu hỏi dùng chung (ID)
  final List<String> templateFlashcardIds; // Flashcard mẫu (ID)
  final String createdBy;        // ID của admin tạo khóa học
  final bool isPublished;        // Trạng thái xuất bản

  Course({
    String? id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.gradeLevel,
    this.isTextbook = false,
    this.textbookName = '',
    this.publisher = '',
    List<String>? materialIds,
    List<String>? questionSetIds,
    List<String>? templateFlashcardIds,
    required this.createdBy,
    this.isPublished = false,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : 
    this.materialIds = materialIds ?? [],
    this.questionSetIds = questionSetIds ?? [],
    this.templateFlashcardIds = templateFlashcardIds ?? [],
    super(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

  factory Course.fromMap(Map<String, dynamic> map, String id) {
    return Course(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      gradeLevel: _gradeLevelFromString(map['gradeLevel'] ?? 'custom'),
      isTextbook: map['isTextbook'] ?? false,
      textbookName: map['textbookName'] ?? '',
      publisher: map['publisher'] ?? '',
      materialIds: List<String>.from(map['materialIds'] ?? []),
      questionSetIds: List<String>.from(map['questionSetIds'] ?? []),
      templateFlashcardIds: List<String>.from(map['templateFlashcardIds'] ?? []),
      createdBy: map['createdBy'] ?? '',
      isPublished: map['isPublished'] ?? false,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  static GradeLevel _gradeLevelFromString(String level) {
    switch (level) {
      case 'grade1':
        return GradeLevel.grade1;
      case 'grade2':
        return GradeLevel.grade2;
      case 'grade3':
        return GradeLevel.grade3;
      case 'grade4':
        return GradeLevel.grade4;
      case 'grade5':
        return GradeLevel.grade5;
      case 'grade6':
        return GradeLevel.grade6;
      case 'grade7':
        return GradeLevel.grade7;
      case 'grade8':
        return GradeLevel.grade8;
      case 'grade9':
        return GradeLevel.grade9;
      case 'custom':
        return GradeLevel.custom;
      default:
        return GradeLevel.custom;
    }
  }

  static String _gradeLevelToString(GradeLevel level) {
    switch (level) {
      case GradeLevel.grade1:
        return 'grade1';
      case GradeLevel.grade2:
        return 'grade2';
      case GradeLevel.grade3:
        return 'grade3';
      case GradeLevel.grade4:
        return 'grade4';
      case GradeLevel.grade5:
        return 'grade5';
      case GradeLevel.grade6:
        return 'grade6';
      case GradeLevel.grade7:
        return 'grade7';
      case GradeLevel.grade8:
        return 'grade8';
      case GradeLevel.grade9:
        return 'grade9';
      case GradeLevel.custom:
        return 'custom';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'gradeLevel': _gradeLevelToString(gradeLevel),
      'isTextbook': isTextbook,
      'textbookName': textbookName,
      'publisher': publisher,
      'materialIds': materialIds,
      'questionSetIds': questionSetIds,
      'templateFlashcardIds': templateFlashcardIds,
      'createdBy': createdBy,
      'isPublished': isPublished,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  @override
  Course copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    GradeLevel? gradeLevel,
    bool? isTextbook,
    String? textbookName,
    String? publisher,
    List<String>? materialIds,
    List<String>? questionSetIds,
    List<String>? templateFlashcardIds,
    String? createdBy,
    bool? isPublished,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      isTextbook: isTextbook ?? this.isTextbook,
      textbookName: textbookName ?? this.textbookName,
      publisher: publisher ?? this.publisher,
      materialIds: materialIds ?? this.materialIds,
      questionSetIds: questionSetIds ?? this.questionSetIds,
      templateFlashcardIds: templateFlashcardIds ?? this.templateFlashcardIds,
      createdBy: createdBy ?? this.createdBy,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? name,
    String? description,
    String? createdBy,
  }) {
    Map<String, String?> errors = {};

    if (name == null || name.isEmpty) {
      errors['name'] = 'Tên khóa học không được để trống';
    }

    if (description == null || description.isEmpty) {
      errors['description'] = 'Mô tả không được để trống';
    }

    if (createdBy == null || createdBy.isEmpty) {
      errors['createdBy'] = 'ID người tạo không được để trống';
    }

    return errors;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 