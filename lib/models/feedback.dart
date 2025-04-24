import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum FeedbackType {
  question,    // Thắc mắc về bài học
  report,      // Báo lỗi bài học
  suggestion   // Góp ý cải thiện
}

extension FeedbackTypeLabel on FeedbackType {
  String get label {
    switch (this) {
      case FeedbackType.question:
        return 'Hỏi bài';
      case FeedbackType.report:
        return 'Báo lỗi';
      case FeedbackType.suggestion:
        return 'Góp ý';
    }
  }
}

enum FeedbackStatus {
  pending,     // Chờ phản hồi
  responded,   // Đã phản hồi
  closed       // Đã đóng
}

extension FeedbackStatusLabel on FeedbackStatus {
  String get label {
    switch (this) {
      case FeedbackStatus.pending:
        return 'Chờ phản hồi';
      case FeedbackStatus.responded:
        return 'Đã phản hồi';
      case FeedbackStatus.closed:
        return 'Đã đóng';
    }
  }
}

class Feedback extends BaseModel {
  final String userId;        // ID học sinh gửi phản hồi
  final String? lessonId;     // ID bài học (nếu có)
  final String classId;       // ID lớp học
  final FeedbackType type;    // Loại phản hồi
  final String content;       // Nội dung phản hồi
  final List<String> attachments; // Danh sách URL của file đính kèm
  final bool isAnonymous;     // Ẩn danh hay không
  final FeedbackStatus status; // Trạng thái phản hồi
  final String? response;     // Phản hồi của giáo viên
  final DateTime? respondedAt; // Thời gian phản hồi

  Feedback({
    String? id,
    required this.userId,
    this.lessonId,
    required this.classId,
    required this.type,
    required this.content,
    this.attachments = const [],
    this.isAnonymous = false,
    this.status = FeedbackStatus.pending,
    this.response,
    this.respondedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory Feedback.fromMap(Map<String, dynamic> map, String id) {
    return Feedback(
      id: id,
      userId: map['userId'] ?? '',
      lessonId: map['lessonId'],
      classId: map['classId'] ?? '',
      type: _typeFromString(map['type'] ?? 'question'),
      content: map['content'] ?? '',
      attachments: List<String>.from(map['attachments'] ?? []),
      isAnonymous: map['isAnonymous'] ?? false,
      status: _statusFromString(map['status'] ?? 'pending'),
      response: map['response'],
      respondedAt: map['respondedAt'] != null 
          ? (map['respondedAt'] as Timestamp).toDate() 
          : null,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  static FeedbackType _typeFromString(String type) {
    switch (type) {
      case 'question':
        return FeedbackType.question;
      case 'report':
        return FeedbackType.report;
      case 'suggestion':
        return FeedbackType.suggestion;
      default:
        return FeedbackType.question;
    }
  }

  static String _typeToString(FeedbackType type) {
    switch (type) {
      case FeedbackType.question:
        return 'question';
      case FeedbackType.report:
        return 'report';
      case FeedbackType.suggestion:
        return 'suggestion';
    }
  }

  static FeedbackStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return FeedbackStatus.pending;
      case 'responded':
        return FeedbackStatus.responded;
      case 'closed':
        return FeedbackStatus.closed;
      default:
        return FeedbackStatus.pending;
    }
  }

  static String _statusToString(FeedbackStatus status) {
    switch (status) {
      case FeedbackStatus.pending:
        return 'pending';
      case FeedbackStatus.responded:
        return 'responded';
      case FeedbackStatus.closed:
        return 'closed';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lessonId': lessonId,
      'classId': classId,
      'type': _typeToString(type),
      'content': content,
      'attachments': attachments,
      'isAnonymous': isAnonymous,
      'status': _statusToString(status),
      'response': response,
      'respondedAt': respondedAt != null 
          ? Timestamp.fromDate(respondedAt!) 
          : null,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  @override
  Feedback copyWith({
    String? id,
    String? userId,
    String? lessonId,
    String? classId,
    FeedbackType? type,
    String? content,
    List<String>? attachments,
    bool? isAnonymous,
    FeedbackStatus? status,
    String? response,
    DateTime? respondedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Feedback(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      classId: classId ?? this.classId,
      type: type ?? this.type,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      status: status ?? this.status,
      response: response ?? this.response,
      respondedAt: respondedAt ?? this.respondedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? content,
  }) {
    Map<String, String?> errors = {};

    if (content == null || content.isEmpty) {
      errors['content'] = 'Nội dung không được để trống';
    } else if (content.length < 10) {
      errors['content'] = 'Nội dung quá ngắn (ít nhất 10 ký tự)';
    } else if (content.length > 1000) {
      errors['content'] = 'Nội dung quá dài (tối đa 1000 ký tự)';
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      content: content,
    );
  }

  // Tạo phản hồi mới
  static Future<Feedback?> createFeedback({
    required String userId,
    required String classId,
    String? lessonId,
    required FeedbackType type,
    required String content,
    List<String> attachments = const [],
    bool isAnonymous = false,
  }) async {
    // Validate dữ liệu
    final errors = validate(content: content);
    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final feedbackDoc = await FirebaseFirestore.instance
          .collection('feedbacks')
          .add({
        'userId': userId,
        'classId': classId,
        'lessonId': lessonId,
        'type': _typeToString(type),
        'content': content,
        'attachments': attachments,
        'isAnonymous': isAnonymous,
        'status': _statusToString(FeedbackStatus.pending),
        'response': null,
        'respondedAt': null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final feedbackData = await feedbackDoc.get();
      return Feedback.fromMap(
        feedbackData.data() as Map<String, dynamic>,
        feedbackData.id,
      );
    } catch (e) {
      print('Error creating feedback: $e');
      return null;
    }
  }

  // Cập nhật phản hồi của giáo viên
  Future<bool> respondToFeedback(String response) async {
    try {
      if (id == null) return false;

      // Validate phản hồi
      if (response.isEmpty) {
        print('Response cannot be empty');
        return false;
      }

      await FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(id)
          .update({
        'response': response,
        'status': _statusToString(FeedbackStatus.responded),
        'respondedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error responding to feedback: $e');
      return false;
    }
  }

  // Đóng phản hồi
  Future<bool> closeFeedback() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('feedbacks')
          .doc(id)
          .update({
        'status': _statusToString(FeedbackStatus.closed),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error closing feedback: $e');
      return false;
    }
  }

  // Lấy danh sách phản hồi của học sinh
  static Future<List<Feedback>> getStudentFeedbacks(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Feedback.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting student feedbacks: $e');
      return [];
    }
  }

  // Lấy danh sách phản hồi của lớp học
  static Future<List<Feedback>> getClassFeedbacks(String classId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('classId', isEqualTo: classId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Feedback.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting class feedbacks: $e');
      return [];
    }
  }

  // Lấy danh sách phản hồi của bài học
  static Future<List<Feedback>> getLessonFeedbacks(String lessonId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('lessonId', isEqualTo: lessonId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Feedback.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting lesson feedbacks: $e');
      return [];
    }
  }

  // Lọc phản hồi theo trạng thái
  static Future<List<Feedback>> getFeedbacksByStatus(
    String classId,
    FeedbackStatus status,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('classId', isEqualTo: classId)
          .where('status', isEqualTo: _statusToString(status))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Feedback.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting feedbacks by status: $e');
      return [];
    }
  }
  
  // Lọc phản hồi theo loại
  static Future<List<Feedback>> getFeedbacksByType(
    String classId,
    FeedbackType type,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('classId', isEqualTo: classId)
          .where('type', isEqualTo: _typeToString(type))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Feedback.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting feedbacks by type: $e');
      return [];
    }
  }
} 