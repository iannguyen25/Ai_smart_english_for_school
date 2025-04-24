import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum ProgressStatus {
  notStarted,    // Chưa bắt đầu
  inProgress,    // Đang học
  completed,     // Đã hoàn thành
  needReview     // Cần ôn tập lại
}

extension ProgressStatusLabel on ProgressStatus {
  String get label {
    switch (this) {
      case ProgressStatus.notStarted:
        return 'Chưa bắt đầu';
      case ProgressStatus.inProgress:
        return 'Đang học';
      case ProgressStatus.completed:
        return 'Đã hoàn thành';
      case ProgressStatus.needReview:
        return 'Cần ôn tập';
    }
  }
}

class LearningProgress extends BaseModel {
  final String userId;           // ID của học viên
  final String lessonId;         // ID của bài học
  final String classroomId;      // ID của lớp học
  final ProgressStatus status;   // Trạng thái học tập
  final int completedItems;      // Số item đã hoàn thành
  final int totalItems;         // Tổng số item
  final double progressPercent; // Phần trăm hoàn thành (0-100)
  final int timeSpentMinutes;   // Thời gian đã học (phút)
  final DateTime? lastAccessTime; // Thời gian truy cập gần nhất
  final Map<String, bool> completedItemIds; // Map lưu trạng thái hoàn thành của từng item
  final List<String> notes;     // Ghi chú của học viên
  final int score;              // Điểm số (nếu có bài kiểm tra)

  LearningProgress({
    String? id,
    required this.userId,
    required this.lessonId,
    required this.classroomId,
    this.status = ProgressStatus.notStarted,
    this.completedItems = 0,
    this.totalItems = 0,
    this.progressPercent = 0.0,
    this.timeSpentMinutes = 0,
    this.lastAccessTime,
    this.completedItemIds = const {},
    this.notes = const [],
    this.score = 0,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory LearningProgress.fromMap(Map<String, dynamic> map, String id) {
    return LearningProgress(
      id: id,
      userId: map['userId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      classroomId: map['classroomId'] ?? '',
      status: _statusFromString(map['status'] ?? 'notStarted'),
      completedItems: map['completedItems'] ?? 0,
      totalItems: map['totalItems'] ?? 0,
      progressPercent: (map['progressPercent'] ?? 0.0).toDouble(),
      timeSpentMinutes: map['timeSpentMinutes'] ?? 0,
      lastAccessTime: map['lastAccessTime'] != null 
          ? (map['lastAccessTime'] as Timestamp).toDate()
          : null,
      completedItemIds: Map<String, bool>.from(map['completedItemIds'] ?? {}),
      notes: List<String>.from(map['notes'] ?? []),
      score: map['score'] ?? 0,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  static ProgressStatus _statusFromString(String status) {
    switch (status) {
      case 'notStarted':
        return ProgressStatus.notStarted;
      case 'inProgress':
        return ProgressStatus.inProgress;
      case 'completed':
        return ProgressStatus.completed;
      case 'needReview':
        return ProgressStatus.needReview;
      default:
        return ProgressStatus.notStarted;
    }
  }

  static String _statusToString(ProgressStatus status) {
    switch (status) {
      case ProgressStatus.notStarted:
        return 'notStarted';
      case ProgressStatus.inProgress:
        return 'inProgress';
      case ProgressStatus.completed:
        return 'completed';
      case ProgressStatus.needReview:
        return 'needReview';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lessonId': lessonId,
      'classroomId': classroomId,
      'status': _statusToString(status),
      'completedItems': completedItems,
      'totalItems': totalItems,
      'progressPercent': progressPercent,
      'timeSpentMinutes': timeSpentMinutes,
      'lastAccessTime': lastAccessTime != null 
          ? Timestamp.fromDate(lastAccessTime!)
          : null,
      'completedItemIds': completedItemIds,
      'notes': notes,
      'score': score,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  @override
  LearningProgress copyWith({
    String? id,
    String? userId,
    String? lessonId,
    String? classroomId,
    ProgressStatus? status,
    int? completedItems,
    int? totalItems,
    double? progressPercent,
    int? timeSpentMinutes,
    DateTime? lastAccessTime,
    Map<String, bool>? completedItemIds,
    List<String>? notes,
    int? score,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return LearningProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      classroomId: classroomId ?? this.classroomId,
      status: status ?? this.status,
      completedItems: completedItems ?? this.completedItems,
      totalItems: totalItems ?? this.totalItems,
      progressPercent: progressPercent ?? this.progressPercent,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      lastAccessTime: lastAccessTime ?? this.lastAccessTime,
      completedItemIds: completedItemIds ?? this.completedItemIds,
      notes: notes ?? this.notes,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? userId,
    String? lessonId,
    String? classroomId,
    int? timeSpentMinutes,
    List<String>? notes,
    int? score,
  }) {
    Map<String, String?> errors = {};

    if (userId == null || userId.isEmpty) {
      errors['userId'] = 'ID học viên không được để trống';
    }

    if (lessonId == null || lessonId.isEmpty) {
      errors['lessonId'] = 'ID bài học không được để trống';
    }

    if (classroomId == null || classroomId.isEmpty) {
      errors['classroomId'] = 'ID lớp học không được để trống';
    }

    if (timeSpentMinutes != null && timeSpentMinutes < 0) {
      errors['timeSpentMinutes'] = 'Thời gian học không được âm';
    }

    if (notes != null) {
      for (var note in notes) {
        if (note.length > 1000) {
          errors['notes'] = 'Ghi chú không được quá 1000 ký tự';
          break;
        }
      }
    }

    if (score != null && (score < 0 || score > 100)) {
      errors['score'] = 'Điểm số phải từ 0 đến 100';
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      userId: userId,
      lessonId: lessonId,
      classroomId: classroomId,
      timeSpentMinutes: timeSpentMinutes,
      notes: notes,
      score: score,
    );
  }

  // Tạo mới tiến độ học tập
  static Future<LearningProgress?> createProgress({
    required String userId,
    required String lessonId,
    required String classroomId,
    required int totalItems,
  }) async {
    final errors = validate(
      userId: userId,
      lessonId: lessonId,
      classroomId: classroomId,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final progressDoc = await FirebaseFirestore.instance
          .collection('learning_progress')
          .add({
        'userId': userId,
        'lessonId': lessonId,
        'classroomId': classroomId,
        'status': _statusToString(ProgressStatus.notStarted),
        'completedItems': 0,
        'totalItems': totalItems,
        'progressPercent': 0.0,
        'timeSpentMinutes': 0,
        'lastAccessTime': null,
        'completedItemIds': {},
        'notes': [],
        'score': 0,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final progressData = await progressDoc.get();
      return LearningProgress.fromMap(
        progressData.data() as Map<String, dynamic>,
        progressData.id,
      );
    } catch (e) {
      print('Error creating learning progress: $e');
      return null;
    }
  }

  // Lấy tiến độ học tập của học viên cho một bài học
  static Future<LearningProgress?> getProgress(
    String userId,
    String lessonId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('learning_progress')
          .where('userId', isEqualTo: userId)
          .where('lessonId', isEqualTo: lessonId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return LearningProgress.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    } catch (e) {
      print('Error getting learning progress: $e');
      return null;
    }
  }

  // Cập nhật tiến độ khi hoàn thành một item
  Future<bool> completeItem(String itemId) async {
    try {
      if (id == null) return false;

      // Cập nhật map completedItemIds
      final newCompletedItemIds = Map<String, bool>.from(completedItemIds);
      newCompletedItemIds[itemId] = true;

      // Tính toán lại số item đã hoàn thành và phần trăm
      final newCompletedItems = newCompletedItemIds.values
          .where((completed) => completed)
          .length;
      final newProgressPercent =
          (newCompletedItems / totalItems * 100).roundToDouble();

      // Xác định trạng thái mới
      ProgressStatus newStatus;
      if (newCompletedItems == totalItems) {
        newStatus = ProgressStatus.completed;
      } else if (newCompletedItems > 0) {
        newStatus = ProgressStatus.inProgress;
      } else {
        newStatus = status;
      }

      // Cập nhật trong Firestore
      await FirebaseFirestore.instance
          .collection('learning_progress')
          .doc(id)
          .update({
        'completedItemIds': newCompletedItemIds,
        'completedItems': newCompletedItems,
        'progressPercent': newProgressPercent,
        'status': _statusToString(newStatus),
        'lastAccessTime': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error completing item: $e');
      return false;
    }
  }

  // Thêm ghi chú mới
  Future<bool> addNote(String note) async {
    try {
      if (id == null) return false;

      final newNotes = List<String>.from(notes)..add(note);

      await FirebaseFirestore.instance
          .collection('learning_progress')
          .doc(id)
          .update({
        'notes': newNotes,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error adding note: $e');
      return false;
    }
  }

  // Cập nhật điểm số
  Future<bool> updateScore(int newScore) async {
    try {
      if (id == null) return false;

      if (newScore < 0 || newScore > 100) {
        print('Score must be between 0 and 100');
        return false;
      }

      await FirebaseFirestore.instance
          .collection('learning_progress')
          .doc(id)
          .update({
        'score': newScore,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating score: $e');
      return false;
    }
  }

  // Cập nhật thời gian học
  Future<bool> updateTimeSpent(int additionalMinutes) async {
    try {
      if (id == null) return false;

      if (additionalMinutes < 0) {
        print('Additional time cannot be negative');
        return false;
      }

      final newTimeSpent = timeSpentMinutes + additionalMinutes;

      await FirebaseFirestore.instance
          .collection('learning_progress')
          .doc(id)
          .update({
        'timeSpentMinutes': newTimeSpent,
        'lastAccessTime': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error updating time spent: $e');
      return false;
    }
  }

  // Đánh dấu cần ôn tập
  Future<bool> markForReview() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('learning_progress')
          .doc(id)
          .update({
        'status': _statusToString(ProgressStatus.needReview),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error marking for review: $e');
      return false;
    }
  }

  // Lấy danh sách bài học cần ôn tập của học viên
  static Future<List<LearningProgress>> getLessonsNeedReview(
    String userId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('learning_progress')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: _statusToString(ProgressStatus.needReview))
          .get();

      return snapshot.docs
          .map((doc) => LearningProgress.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting lessons need review: $e');
      return [];
    }
  }

  // Lấy thống kê học tập của học viên trong một lớp
  static Future<Map<String, dynamic>> getStudentStats(
    String userId,
    String classroomId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('learning_progress')
          .where('userId', isEqualTo: userId)
          .where('classroomId', isEqualTo: classroomId)
          .get();

      final progresses = snapshot.docs
          .map((doc) => LearningProgress.fromMap(doc.data(), doc.id))
          .toList();

      // Tính toán các chỉ số thống kê
      final totalLessons = progresses.length;
      final completedLessons = progresses
          .where((p) => p.status == ProgressStatus.completed)
          .length;
      final totalTimeSpent =
          progresses.fold(0, (sum, p) => sum + p.timeSpentMinutes);
      final averageScore =
          progresses.fold(0, (sum, p) => sum + p.score) / totalLessons;
      final averageProgress = progresses.fold(
              0.0, (sum, p) => sum + p.progressPercent) /
          totalLessons;

      return {
        'totalLessons': totalLessons,
        'completedLessons': completedLessons,
        'totalTimeSpentMinutes': totalTimeSpent,
        'averageScore': averageScore,
        'averageProgress': averageProgress,
      };
    } catch (e) {
      print('Error getting student stats: $e');
      return {};
    }
  }
} 