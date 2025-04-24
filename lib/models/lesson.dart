import 'package:base_flutter_framework/models/content_approval.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

extension ApprovalStatusLabel on ApprovalStatus {
  String get label {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Chờ duyệt';
      case ApprovalStatus.approved:
        return 'Đã duyệt';
      case ApprovalStatus.rejected:
        return 'Từ chối';
      case ApprovalStatus.revising:
        return 'Yêu cầu chỉnh sửa';
      default:
        return 'Chờ duyệt';
    }
  }
}

class VideoItem {
  final String url;
  final String? title;
  final String? description;
  final Timestamp createdAt;

  VideoItem({
    required this.url,
    this.title,
    this.description,
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'title': title,
      'description': description,
      'createdAt': createdAt,
    };
  }

  factory VideoItem.fromMap(Map<String, dynamic> map) {
    return VideoItem(
      url: map['url'] ?? '',
      title: map['title'],
      description: map['description'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  VideoItem copyWith({
    String? url,
    String? title,
    String? description,
    Timestamp? createdAt,
  }) {
    return VideoItem(
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Lesson extends BaseModel {
  final String title;
  final String description;
  final String classroomId;
  final int orderIndex;
  final int estimatedMinutes;
  final List<VideoItem> videos;      // Danh sách video với thông tin chi tiết
  final List<String> flashcardIds;    // ID của các flashcard liên kết
  final List<String> exerciseIds;     // ID của các bài tập liên kết
  final List<String> completedBy;     // Danh sách ID học sinh đã hoàn thành
  final List<LessonFolder> folders;
  final ApprovalStatus approvalStatus; // Trạng thái phê duyệt
  final String? approvedBy;           // ID của QTV đã duyệt
  final String? rejectionReason;      // Lý do từ chối
  final List<ApprovalHistory> approvalHistory; // Lịch sử phê duyệt
  final Timestamp? approvalTime;      // Thời gian phê duyệt gần nhất

  Lesson({
    String? id,
    required this.title,
    required this.description,
    required this.classroomId,
    this.orderIndex = 0,
    this.estimatedMinutes = 0,
    this.videos = const [],
    this.flashcardIds = const [],
    this.exerciseIds = const [],
    this.completedBy = const [],
    this.folders = const [],
    this.approvalStatus = ApprovalStatus.pending,
    this.approvedBy,
    this.rejectionReason,
    this.approvalHistory = const [],
    this.approvalTime,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory Lesson.fromMap(Map<String, dynamic> map, String id) {
    // Handle migration from old videoUrl to new videos array
    List<VideoItem> videos = [];
    
    // Migrate from old videoUrl field if it exists
    if (map['videoUrl'] != null && map['videoUrl'].isNotEmpty) {
      videos.add(VideoItem(
        url: map['videoUrl'],
        title: 'Video bài giảng',
        description: 'Video bài giảng chính',
      ));
    }
    
    // Handle old videos string list if present
    if (map['videos'] is List && map['videos'].isNotEmpty) {
      if (map['videos'][0] is String) {
        // Convert old string list to VideoItem objects
        videos.addAll(
          (map['videos'] as List).map((url) => VideoItem(
            url: url.toString(),
            title: 'Video bài giảng ${videos.length + 1}',
          )).toList()
        );
      }
    }
    
    // Handle new VideoItem format
    if (map['videoItems'] is List) {
      videos = (map['videoItems'] as List)
          .map((item) => VideoItem.fromMap(item))
          .toList();
    }
    
    return Lesson(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      classroomId: map['classroomId'] ?? '',
      orderIndex: map['orderIndex'] ?? 0,
      estimatedMinutes: map['estimatedMinutes'] ?? 0,
      videos: videos,
      flashcardIds: List<String>.from(map['flashcardIds'] ?? []),
      exerciseIds: List<String>.from(map['exerciseIds'] ?? []),
      completedBy: List<String>.from(map['completedBy'] ?? []),
      folders: map['folders'] != null
          ? List<LessonFolder>.from(
              (map['folders'] as List).map(
                (folder) => LessonFolder.fromMap(folder),
              ),
            )
          : [],
      approvalStatus: _approvalStatusFromString(map['approvalStatus'] ?? 'pending'),
      approvedBy: map['approvedBy'],
      rejectionReason: map['rejectionReason'],
      approvalHistory: map['approvalHistory'] != null
          ? List<ApprovalHistory>.from(
              (map['approvalHistory'] as List).map(
                (history) => ApprovalHistory.fromMap(history),
              ),
            )
          : [],
      approvalTime: map['approvalTime'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  static ApprovalStatus _approvalStatusFromString(String status) {
    switch (status) {
      case 'pending':
        return ApprovalStatus.pending;
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'revising':
        return ApprovalStatus.revising;
      default:
        return ApprovalStatus.pending;
    }
  }

  static String _approvalStatusToString(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return 'pending';
      case ApprovalStatus.approved:
        return 'approved';
      case ApprovalStatus.rejected:
        return 'rejected';
      case ApprovalStatus.revising:
        return 'revising';
      default:
        return 'pending';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'classroomId': classroomId,
      'orderIndex': orderIndex,
      'estimatedMinutes': estimatedMinutes,
      'videoItems': videos.map((v) => v.toMap()).toList(),
      'flashcardIds': flashcardIds,
      'exerciseIds': exerciseIds,
      'completedBy': completedBy,
      'folders': folders.map((folder) => folder.toMap()).toList(),
      'approvalStatus': _approvalStatusToString(approvalStatus),
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'approvalHistory': approvalHistory.map((history) => history.toMap()).toList(),
      'approvalTime': approvalTime,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  @override
  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    String? classroomId,
    int? orderIndex,
    int? estimatedMinutes,
    List<VideoItem>? videos,
    List<String>? flashcardIds,
    List<String>? exerciseIds,
    List<String>? completedBy,
    List<LessonFolder>? folders,
    ApprovalStatus? approvalStatus,
    String? approvedBy,
    String? rejectionReason,
    List<ApprovalHistory>? approvalHistory,
    Timestamp? approvalTime,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      classroomId: classroomId ?? this.classroomId,
      orderIndex: orderIndex ?? this.orderIndex,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      videos: videos ?? this.videos,
      flashcardIds: flashcardIds ?? this.flashcardIds,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      completedBy: completedBy ?? this.completedBy,
      folders: folders ?? this.folders,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvalHistory: approvalHistory ?? this.approvalHistory,
      approvalTime: approvalTime ?? this.approvalTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Kiểm tra bài học đã được duyệt chưa
  bool get isApproved => approvalStatus == ApprovalStatus.approved;

  // Đánh dấu học sinh đã hoàn thành bài học
  Lesson markAsCompleted(String userId) {
    if (completedBy.contains(userId)) {
      return this;
    }
    
    final updatedCompletedBy = List<String>.from(completedBy);
    updatedCompletedBy.add(userId);
    
    return copyWith(
      completedBy: updatedCompletedBy,
      updatedAt: Timestamp.now(),
    );
  }

  // Kiểm tra học sinh đã hoàn thành bài học chưa
  bool isCompletedByUser(String userId) {
    return completedBy.contains(userId);
  }

  // Thêm flashcard vào bài học
  Lesson addFlashcard(String flashcardId) {
    if (flashcardIds.contains(flashcardId)) {
      return this;
    }
    
    final updatedFlashcardIds = List<String>.from(flashcardIds);
    updatedFlashcardIds.add(flashcardId);
    
    return copyWith(
      flashcardIds: updatedFlashcardIds,
      updatedAt: Timestamp.now(),
    );
  }

  // Thêm bài tập vào bài học
  Lesson addExercise(String exerciseId) {
    if (exerciseIds.contains(exerciseId)) {
      return this;
    }
    
    final updatedExerciseIds = List<String>.from(exerciseIds);
    updatedExerciseIds.add(exerciseId);
    
    return copyWith(
      exerciseIds: updatedExerciseIds,
      updatedAt: Timestamp.now(),
    );
  }

  // Cập nhật trạng thái phê duyệt
  Lesson updateApprovalStatus({
    required ApprovalStatus status,
    required String adminId,
    String? reason,
  }) {
    final newHistory = ApprovalHistory(
      status: status,
      adminId: adminId,
      reason: reason,
      timestamp: Timestamp.now(),
    );
    
    final updatedHistory = List<ApprovalHistory>.from(approvalHistory)..add(newHistory);
    
    return copyWith(
      approvalStatus: status,
      approvedBy: adminId,
      rejectionReason: status == ApprovalStatus.rejected || status == ApprovalStatus.revising ? reason : null,
      approvalHistory: updatedHistory,
      approvalTime: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );
  }

  // Lấy danh sách bài học của lớp học
  static Future<List<Lesson>> getLessonsByClassroom(String classroomId) async {
    try {
      print('Getting lessons for classroom ID: $classroomId');
      final snapshot = await FirebaseFirestore.instance
          .collection('lessons')
          .where('classroomId', isEqualTo: classroomId)
          .orderBy('orderIndex', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => Lesson.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting lessons for classroom: $e');
      return [];
    }
  }

  // Lấy danh sách bài học chờ duyệt
  static Future<List<Lesson>> getPendingLessons() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lessons')
          .where('approvalStatus', isEqualTo: 'pending')
          .get();

      return snapshot.docs
          .map((doc) => Lesson.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting pending lessons: $e');
      return [];
    }
  }

  // Thêm phương thức validate
  static Map<String, String?> validate({
    String? title,
    String? description,
    String? classroomId,
    int? estimatedMinutes,
    String? videoUrl,
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

    if (classroomId == null || classroomId.isEmpty) {
      errors['classroomId'] = 'ID lớp học không được để trống';
    }

    if (estimatedMinutes != null) {
      final timeError = InputValidator.validateEstimatedMinutes(estimatedMinutes);
      if (timeError != null) {
        errors['estimatedMinutes'] = timeError;
      }
    }
    
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final urlError = InputValidator.validateUrl(videoUrl);
      if (urlError != null) {
        errors['videoUrl'] = urlError;
      }
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      title: title,
      description: description,
      classroomId: classroomId,
      estimatedMinutes: estimatedMinutes,
      videoUrl: videos.isNotEmpty ? videos.first.url : null,
    );
  }

  // Cập nhật phương thức tạo bài học để thêm validation
  static Future<Lesson?> createLesson({
    required String title,
    required String description,
    required String classroomId,
    int orderIndex = 0,
    int estimatedMinutes = 0,
    String? videoUrl,
    List<String> flashcardIds = const [],
    List<String> exerciseIds = const [],
    List<LessonFolder> folders = const [],
  }) async {
    // Validate input
    final errors = validate(
      title: title,
      description: description,
      classroomId: classroomId,
      estimatedMinutes: estimatedMinutes,
      videoUrl: videoUrl,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final lessonDoc = await FirebaseFirestore.instance.collection('lessons').add({
        'title': title,
        'description': description,
        'classroomId': classroomId,
        'orderIndex': orderIndex,
        'estimatedMinutes': estimatedMinutes,
        'videos': videoUrl != null ? [videoUrl] : [],
        'flashcardIds': flashcardIds,
        'exerciseIds': exerciseIds,
        'completedBy': [],
        'folders': folders.map((folder) => folder.toMap()).toList(),
        'approvalStatus': 'pending',
        'approvedBy': null,
        'rejectionReason': null,
        'approvalHistory': [],
        'approvalTime': null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final lessonData = await lessonDoc.get();
      return Lesson.fromMap(lessonData.data() as Map<String, dynamic>, lessonData.id);
    } catch (e) {
      print('Error creating lesson: $e');
      return null;
    }
  }
}

class ApprovalHistory {
  final ApprovalStatus status;
  final String adminId;
  final String? reason;
  final Timestamp timestamp;

  ApprovalHistory({
    required this.status,
    required this.adminId,
    this.reason,
    required this.timestamp,
  });

  factory ApprovalHistory.fromMap(Map<String, dynamic> map) {
    return ApprovalHistory(
      status: Lesson._approvalStatusFromString(map['status'] ?? 'pending'),
      adminId: map['adminId'] ?? '',
      reason: map['reason'],
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': Lesson._approvalStatusToString(status),
      'adminId': adminId,
      'reason': reason,
      'timestamp': timestamp,
    };
  }
}

class LessonFolder {
  final String title;
  final String? description;
  final List<LessonItem> items;
  final int orderIndex;

  LessonFolder({
    required this.title,
    this.description,
    this.items = const [],
    this.orderIndex = 0,
  });

  factory LessonFolder.fromMap(Map<String, dynamic> map) {
    return LessonFolder(
      title: map['title'] ?? '',
      description: map['description'],
      orderIndex: map['orderIndex'] ?? 0,
      items: map['items'] != null
          ? List<LessonItem>.from(
              (map['items'] as List).map(
                (item) => LessonItem.fromMap(item),
              ),
            )
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'orderIndex': orderIndex,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  LessonFolder copyWith({
    String? title,
    String? description,
    List<LessonItem>? items,
    int? orderIndex,
  }) {
    return LessonFolder(
      title: title ?? this.title,
      description: description ?? this.description,
      items: items ?? this.items,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  // Thêm phương thức validate
  static Map<String, String?> validate({
    String? title,
    String? description,
  }) {
    Map<String, String?> errors = {};
    
    final titleError = InputValidator.validateTitle(title);
    if (titleError != null) {
      errors['title'] = titleError;
    }

    if (description != null) {
      final descriptionError = InputValidator.validateDescription(description);
      if (descriptionError != null) {
        errors['description'] = descriptionError;
      }
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      title: title,
      description: description,
    );
  }
}

enum LessonItemType {
  document,    // Tài liệu
  exercise,    // Bài tập
  vocabulary,  // Từ vựng
  video,       // Video
  audio,       // Audio
  quiz         // Bài kiểm tra
}

extension LessonItemTypeLabel on LessonItemType {
  String get label {
    switch (this) {
      case LessonItemType.document:
        return 'Tài liệu';
      case LessonItemType.exercise:
        return 'Bài tập';
      case LessonItemType.vocabulary:
        return 'Từ vựng';
      case LessonItemType.video:
        return 'Video';
      case LessonItemType.audio:
        return 'Audio';
      case LessonItemType.quiz:
        return 'Bài kiểm tra';
    }
  }
}

class LessonItem {
  final String title;
  final String? description;
  final LessonItemType type;
  final String content;
  final int orderIndex;
  final String? materialId;

  LessonItem({
    required this.title,
    this.description,
    required this.type,
    required this.content,
    this.orderIndex = 0,
    this.materialId,
  });

  factory LessonItem.fromMap(Map<String, dynamic> map) {
    return LessonItem(
      title: map['title'] ?? '',
      description: map['description'],
      type: LessonItemType.values.firstWhere(
        (e) => e.toString() == 'LessonItemType.${map['type']}',
        orElse: () => LessonItemType.document,
      ),
      content: map['content'] ?? '',
      orderIndex: map['orderIndex'] ?? 0,
      materialId: map['materialId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'content': content,
      'orderIndex': orderIndex,
      'materialId': materialId,
    };
  }

  LessonItem copyWith({
    String? title,
    String? description,
    LessonItemType? type,
    String? content,
    int? orderIndex,
    String? materialId,
  }) {
    return LessonItem(
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      content: content ?? this.content,
      orderIndex: orderIndex ?? this.orderIndex,
      materialId: materialId ?? this.materialId,
    );
  }

  // Thêm phương thức validate
  static Map<String, String?> validate({
    String? title,
    String? description,
    LessonItemType? type,
    String? content,
  }) {
    Map<String, String?> errors = {};
    
    final titleError = InputValidator.validateTitle(title);
    if (titleError != null) {
      errors['title'] = titleError;
    }

    if (description != null) {
      final descriptionError = InputValidator.validateDescription(description);
      if (descriptionError != null) {
        errors['description'] = descriptionError;
      }
    }

    if (type == null) {
      errors['type'] = 'Loại item không được để trống';
    }

    if (content == null || content.isEmpty) {
      errors['content'] = 'Nội dung item không được để trống';
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      title: title,
      description: description,
      type: type,
      content: content,
    );
  }
} 