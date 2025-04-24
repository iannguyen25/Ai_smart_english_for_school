import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum AnalyticsType {
  lesson,         // Phân tích bài học
  quiz,           // Phân tích bài kiểm tra
  vocabulary,     // Phân tích từ vựng
  speaking,       // Phân tích kỹ năng nói
  listening,      // Phân tích kỹ năng nghe
  reading,        // Phân tích kỹ năng đọc
  writing,        // Phân tích kỹ năng viết
  overall         // Phân tích tổng thể
}

enum PerformanceLevel {
  excellent,    // Xuất sắc (>= 90%)
  good,         // Tốt (>= 80%)
  average,      // Trung bình (>= 60%)
  belowAverage, // Yếu (>= 40%)
  poor          // Kém (< 40%)
}

class SkillMetrics {
  final double accuracy;      // Độ chính xác
  final double speed;         // Tốc độ hoàn thành
  final double consistency;   // Độ ổn định
  final double improvement;   // Mức độ cải thiện
  final Map<String, double> subSkills; // Các kỹ năng phụ

  SkillMetrics({
    required this.accuracy,
    required this.speed,
    required this.consistency,
    required this.improvement,
    required this.subSkills,
  });

  factory SkillMetrics.fromMap(Map<String, dynamic> map) {
    return SkillMetrics(
      accuracy: (map['accuracy'] ?? 0.0).toDouble(),
      speed: (map['speed'] ?? 0.0).toDouble(),
      consistency: (map['consistency'] ?? 0.0).toDouble(),
      improvement: (map['improvement'] ?? 0.0).toDouble(),
      subSkills: Map<String, double>.from(map['subSkills'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accuracy': accuracy,
      'speed': speed,
      'consistency': consistency,
      'improvement': improvement,
      'subSkills': subSkills,
    };
  }

  PerformanceLevel get performanceLevel {
    double avgScore = (accuracy + consistency + improvement) / 3;
    if (avgScore >= 90) return PerformanceLevel.excellent;
    if (avgScore >= 80) return PerformanceLevel.good;
    if (avgScore >= 60) return PerformanceLevel.average;
    if (avgScore >= 40) return PerformanceLevel.belowAverage;
    return PerformanceLevel.poor;
  }
}

class TimeDistribution {
  final Map<String, int> byDay;     // Phân bố theo ngày
  final Map<String, int> byWeek;    // Phân bố theo tuần
  final Map<String, int> byMonth;   // Phân bố theo tháng
  final Map<String, int> bySkill;   // Phân bố theo kỹ năng

  TimeDistribution({
    required this.byDay,
    required this.byWeek,
    required this.byMonth,
    required this.bySkill,
  });

  factory TimeDistribution.fromMap(Map<String, dynamic> map) {
    return TimeDistribution(
      byDay: Map<String, int>.from(map['byDay'] ?? {}),
      byWeek: Map<String, int>.from(map['byWeek'] ?? {}),
      byMonth: Map<String, int>.from(map['byMonth'] ?? {}),
      bySkill: Map<String, int>.from(map['bySkill'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'byDay': byDay,
      'byWeek': byWeek,
      'byMonth': byMonth,
      'bySkill': bySkill,
    };
  }
}

class LearningAnalytics extends BaseModel {
  final String userId;
  final String? classroomId;
  final AnalyticsType type;
  final DateTime startDate;
  final DateTime endDate;
  
  // Thống kê cơ bản
  final int totalLessons;
  final int completedLessons;
  final int totalQuizzes;
  final int completedQuizzes;
  final double averageScore;
  final int totalTimeMinutes;
  final double progressPercent;
  
  // Phân tích chi tiết
  final SkillMetrics skillMetrics;
  final TimeDistribution timeDistribution;
  final Map<String, int> strengthTopics;    // Chủ đề mạnh
  final Map<String, int> weaknessTopics;    // Chủ đề yếu
  final List<String> recommendations;        // Đề xuất cải thiện
  final Map<String, dynamic>? metadata;

  LearningAnalytics({
    String? id,
    required this.userId,
    this.classroomId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.totalLessons,
    required this.completedLessons,
    required this.totalQuizzes,
    required this.completedQuizzes,
    required this.averageScore,
    required this.totalTimeMinutes,
    required this.progressPercent,
    required this.skillMetrics,
    required this.timeDistribution,
    required this.strengthTopics,
    required this.weaknessTopics,
    required this.recommendations,
    this.metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory LearningAnalytics.fromMap(Map<String, dynamic> map, String id) {
    return LearningAnalytics(
      id: id,
      userId: map['userId'] ?? '',
      classroomId: map['classroomId'],
      type: _analyticsTypeFromString(map['type'] ?? 'overall'),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      totalLessons: map['totalLessons'] ?? 0,
      completedLessons: map['completedLessons'] ?? 0,
      totalQuizzes: map['totalQuizzes'] ?? 0,
      completedQuizzes: map['completedQuizzes'] ?? 0,
      averageScore: (map['averageScore'] ?? 0.0).toDouble(),
      totalTimeMinutes: map['totalTimeMinutes'] ?? 0,
      progressPercent: (map['progressPercent'] ?? 0.0).toDouble(),
      skillMetrics: SkillMetrics.fromMap(map['skillMetrics'] ?? {}),
      timeDistribution: TimeDistribution.fromMap(map['timeDistribution'] ?? {}),
      strengthTopics: Map<String, int>.from(map['strengthTopics'] ?? {}),
      weaknessTopics: Map<String, int>.from(map['weaknessTopics'] ?? {}),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      metadata: map['metadata'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'classroomId': classroomId,
      'type': _analyticsTypeToString(type),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'totalLessons': totalLessons,
      'completedLessons': completedLessons,
      'totalQuizzes': totalQuizzes,
      'completedQuizzes': completedQuizzes,
      'averageScore': averageScore,
      'totalTimeMinutes': totalTimeMinutes,
      'progressPercent': progressPercent,
      'skillMetrics': skillMetrics.toMap(),
      'timeDistribution': timeDistribution.toMap(),
      'strengthTopics': strengthTopics,
      'weaknessTopics': weaknessTopics,
      'recommendations': recommendations,
      'metadata': metadata,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  static AnalyticsType _analyticsTypeFromString(String type) {
    switch (type) {
      case 'lesson':
        return AnalyticsType.lesson;
      case 'quiz':
        return AnalyticsType.quiz;
      case 'vocabulary':
        return AnalyticsType.vocabulary;
      case 'speaking':
        return AnalyticsType.speaking;
      case 'listening':
        return AnalyticsType.listening;
      case 'reading':
        return AnalyticsType.reading;
      case 'writing':
        return AnalyticsType.writing;
      case 'overall':
      default:
        return AnalyticsType.overall;
    }
  }

  static String _analyticsTypeToString(AnalyticsType type) {
    switch (type) {
      case AnalyticsType.lesson:
        return 'lesson';
      case AnalyticsType.quiz:
        return 'quiz';
      case AnalyticsType.vocabulary:
        return 'vocabulary';
      case AnalyticsType.speaking:
        return 'speaking';
      case AnalyticsType.listening:
        return 'listening';
      case AnalyticsType.reading:
        return 'reading';
      case AnalyticsType.writing:
        return 'writing';
      case AnalyticsType.overall:
        return 'overall';
    }
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? totalLessons,
    int? completedLessons,
    double? averageScore,
    double? progressPercent,
  }) {
    Map<String, String?> errors = {};

    if (userId == null || userId.isEmpty) {
      errors['userId'] = 'ID người dùng không được để trống';
    }

    if (startDate == null) {
      errors['startDate'] = 'Ngày bắt đầu không được để trống';
    }

    if (endDate == null) {
      errors['endDate'] = 'Ngày kết thúc không được để trống';
    }

    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      errors['dateRange'] = 'Ngày bắt đầu phải trước ngày kết thúc';
    }

    if (totalLessons != null && totalLessons < 0) {
      errors['totalLessons'] = 'Tổng số bài học phải >= 0';
    }

    if (completedLessons != null && completedLessons < 0) {
      errors['completedLessons'] = 'Số bài học đã hoàn thành phải >= 0';
    }

    if (totalLessons != null && completedLessons != null &&
        completedLessons > totalLessons) {
      errors['lessonCount'] = 'Số bài học hoàn thành không thể lớn hơn tổng số';
    }

    if (averageScore != null && (averageScore < 0 || averageScore > 100)) {
      errors['averageScore'] = 'Điểm trung bình phải từ 0 đến 100';
    }

    if (progressPercent != null && (progressPercent < 0 || progressPercent > 100)) {
      errors['progressPercent'] = 'Phần trăm tiến độ phải từ 0 đến 100';
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      totalLessons: totalLessons,
      completedLessons: completedLessons,
      averageScore: averageScore,
      progressPercent: progressPercent,
    );
  }

  // Tạo báo cáo phân tích mới
  static Future<LearningAnalytics?> createAnalytics({
    required String userId,
    String? classroomId,
    required AnalyticsType type,
    required DateTime startDate,
    required DateTime endDate,
    required int totalLessons,
    required int completedLessons,
    required int totalQuizzes,
    required int completedQuizzes,
    required double averageScore,
    required int totalTimeMinutes,
    required double progressPercent,
    required SkillMetrics skillMetrics,
    required TimeDistribution timeDistribution,
    required Map<String, int> strengthTopics,
    required Map<String, int> weaknessTopics,
    required List<String> recommendations,
    Map<String, dynamic>? metadata,
  }) async {
    final errors = validate(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      totalLessons: totalLessons,
      completedLessons: completedLessons,
      averageScore: averageScore,
      progressPercent: progressPercent,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final analyticsDoc = await FirebaseFirestore.instance
          .collection('learning_analytics')
          .add({
        'userId': userId,
        'classroomId': classroomId,
        'type': _analyticsTypeToString(type),
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'totalLessons': totalLessons,
        'completedLessons': completedLessons,
        'totalQuizzes': totalQuizzes,
        'completedQuizzes': completedQuizzes,
        'averageScore': averageScore,
        'totalTimeMinutes': totalTimeMinutes,
        'progressPercent': progressPercent,
        'skillMetrics': skillMetrics.toMap(),
        'timeDistribution': timeDistribution.toMap(),
        'strengthTopics': strengthTopics,
        'weaknessTopics': weaknessTopics,
        'recommendations': recommendations,
        'metadata': metadata,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final analyticsData = await analyticsDoc.get();
      return LearningAnalytics.fromMap(
        analyticsData.data() as Map<String, dynamic>,
        analyticsData.id,
      );
    } catch (e) {
      print('Error creating analytics: $e');
      return null;
    }
  }

  // Lấy báo cáo phân tích theo người dùng và loại
  static Future<List<LearningAnalytics>> getAnalyticsByUser({
    required String userId,
    AnalyticsType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = FirebaseFirestore.instance
          .collection('learning_analytics')
          .where('userId', isEqualTo: userId);

      if (type != null) {
        query = query.where('type', isEqualTo: _analyticsTypeToString(type));
      }

      if (startDate != null) {
        query = query.where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('endDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LearningAnalytics.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting analytics: $e');
      return [];
    }
  }

  // Lấy báo cáo phân tích theo lớp học
  static Future<List<LearningAnalytics>> getAnalyticsByClassroom({
    required String classroomId,
    AnalyticsType? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = FirebaseFirestore.instance
          .collection('learning_analytics')
          .where('classroomId', isEqualTo: classroomId);

      if (type != null) {
        query = query.where('type', isEqualTo: _analyticsTypeToString(type));
      }

      if (startDate != null) {
        query = query.where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('endDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LearningAnalytics.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting classroom analytics: $e');
      return [];
    }
  }

  // Cập nhật báo cáo phân tích
  Future<bool> update({
    AnalyticsType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? totalLessons,
    int? completedLessons,
    int? totalQuizzes,
    int? completedQuizzes,
    double? averageScore,
    int? totalTimeMinutes,
    double? progressPercent,
    SkillMetrics? skillMetrics,
    TimeDistribution? timeDistribution,
    Map<String, int>? strengthTopics,
    Map<String, int>? weaknessTopics,
    List<String>? recommendations,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (id == null) return false;

      final errors = validate(
        userId: userId,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        totalLessons: totalLessons ?? this.totalLessons,
        completedLessons: completedLessons ?? this.completedLessons,
        averageScore: averageScore ?? this.averageScore,
        progressPercent: progressPercent ?? this.progressPercent,
      );

      if (errors.isNotEmpty) {
        print('Validation errors: $errors');
        return false;
      }

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (type != null) updates['type'] = _analyticsTypeToString(type);
      if (startDate != null) {
        updates['startDate'] = Timestamp.fromDate(startDate);
      }
      if (endDate != null) updates['endDate'] = Timestamp.fromDate(endDate);
      if (totalLessons != null) updates['totalLessons'] = totalLessons;
      if (completedLessons != null) {
        updates['completedLessons'] = completedLessons;
      }
      if (totalQuizzes != null) updates['totalQuizzes'] = totalQuizzes;
      if (completedQuizzes != null) {
        updates['completedQuizzes'] = completedQuizzes;
      }
      if (averageScore != null) updates['averageScore'] = averageScore;
      if (totalTimeMinutes != null) {
        updates['totalTimeMinutes'] = totalTimeMinutes;
      }
      if (progressPercent != null) updates['progressPercent'] = progressPercent;
      if (skillMetrics != null) {
        updates['skillMetrics'] = skillMetrics.toMap();
      }
      if (timeDistribution != null) {
        updates['timeDistribution'] = timeDistribution.toMap();
      }
      if (strengthTopics != null) updates['strengthTopics'] = strengthTopics;
      if (weaknessTopics != null) updates['weaknessTopics'] = weaknessTopics;
      if (recommendations != null) {
        updates['recommendations'] = recommendations;
      }
      if (metadata != null) updates['metadata'] = metadata;

      await FirebaseFirestore.instance
          .collection('learning_analytics')
          .doc(id)
          .update(updates);

      return true;
    } catch (e) {
      print('Error updating analytics: $e');
      return false;
    }
  }

  // Xóa báo cáo phân tích
  Future<bool> delete() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('learning_analytics')
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting analytics: $e');
      return false;
    }
  }

  @override
  LearningAnalytics copyWith({
    String? id,
    String? userId,
    String? classroomId,
    AnalyticsType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? totalLessons,
    int? completedLessons,
    int? totalQuizzes,
    int? completedQuizzes,
    double? averageScore,
    int? totalTimeMinutes,
    double? progressPercent,
    SkillMetrics? skillMetrics,
    TimeDistribution? timeDistribution,
    Map<String, int>? strengthTopics,
    Map<String, int>? weaknessTopics,
    List<String>? recommendations,
    Map<String, dynamic>? metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return LearningAnalytics(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      classroomId: classroomId ?? this.classroomId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalLessons: totalLessons ?? this.totalLessons,
      completedLessons: completedLessons ?? this.completedLessons,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      completedQuizzes: completedQuizzes ?? this.completedQuizzes,
      averageScore: averageScore ?? this.averageScore,
      totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
      progressPercent: progressPercent ?? this.progressPercent,
      skillMetrics: skillMetrics ?? this.skillMetrics,
      timeDistribution: timeDistribution ?? this.timeDistribution,
      strengthTopics: strengthTopics ?? this.strengthTopics,
      weaknessTopics: weaknessTopics ?? this.weaknessTopics,
      recommendations: recommendations ?? this.recommendations,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 