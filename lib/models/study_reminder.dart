import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum ReminderType {
  dailyStudy,      // Nhắc nhở học tập hàng ngày
  reviewLesson,    // Nhắc nhở ôn tập bài học
  practiceExam,    // Nhắc nhở làm bài tập/kiểm tra
  vocabulary,      // Nhắc nhở học từ vựng
  speaking,        // Nhắc nhở luyện nói
  listening,       // Nhắc nhở luyện nghe
  custom          // Nhắc nhở tùy chỉnh
}

extension ReminderTypeLabel on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.dailyStudy:
        return 'Học tập hàng ngày';
      case ReminderType.reviewLesson:
        return 'Ôn tập bài học';
      case ReminderType.practiceExam:
        return 'Làm bài tập/kiểm tra';
      case ReminderType.vocabulary:
        return 'Học từ vựng';
      case ReminderType.speaking:
        return 'Luyện nói';
      case ReminderType.listening:
        return 'Luyện nghe';
      case ReminderType.custom:
        return 'Tùy chỉnh';
    }
  }

  String get icon {
    switch (this) {
      case ReminderType.dailyStudy:
        return '📚';
      case ReminderType.reviewLesson:
        return '📖';
      case ReminderType.practiceExam:
        return '✍️';
      case ReminderType.vocabulary:
        return '📝';
      case ReminderType.speaking:
        return '🗣️';
      case ReminderType.listening:
        return '👂';
      case ReminderType.custom:
        return '⭐';
    }
  }
}

enum RepeatType {
  once,           // Một lần
  daily,          // Hàng ngày
  weekly,         // Hàng tuần
  monthly,        // Hàng tháng
  custom          // Tùy chỉnh
}

class StudyReminder extends BaseModel {
  final String userId;           // ID của học viên
  final String? lessonId;        // ID của bài học (nếu có)
  final String title;            // Tiêu đề nhắc nhở
  final String description;      // Mô tả chi tiết
  final ReminderType type;       // Loại nhắc nhở
  final DateTime startTime;      // Thời gian bắt đầu
  final DateTime? endTime;       // Thời gian kết thúc (nếu có)
  final RepeatType repeatType;   // Kiểu lặp lại
  final List<int> repeatDays;    // Các ngày lặp lại (1-7 cho thứ, 1-31 cho ngày)
  final int? repeatInterval;     // Khoảng cách lặp lại (VD: 2 tuần/lần)
  final bool isEnabled;          // Bật/tắt nhắc nhở
  final String? soundUrl;        // URL âm thanh thông báo
  final Map<String, dynamic>? metadata; // Dữ liệu bổ sung

  StudyReminder({
    String? id,
    required this.userId,
    this.lessonId,
    required this.title,
    required this.description,
    required this.type,
    required this.startTime,
    this.endTime,
    this.repeatType = RepeatType.once,
    this.repeatDays = const [],
    this.repeatInterval,
    this.isEnabled = true,
    this.soundUrl,
    this.metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory StudyReminder.fromMap(Map<String, dynamic> map, String id) {
    return StudyReminder(
      id: id,
      userId: map['userId'] ?? '',
      lessonId: map['lessonId'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: _typeFromString(map['type'] ?? 'custom'),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null 
          ? (map['endTime'] as Timestamp).toDate()
          : null,
      repeatType: _repeatTypeFromString(map['repeatType'] ?? 'once'),
      repeatDays: List<int>.from(map['repeatDays'] ?? []),
      repeatInterval: map['repeatInterval'],
      isEnabled: map['isEnabled'] ?? true,
      soundUrl: map['soundUrl'],
      metadata: map['metadata'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  static ReminderType _typeFromString(String type) {
    switch (type) {
      case 'dailyStudy':
        return ReminderType.dailyStudy;
      case 'reviewLesson':
        return ReminderType.reviewLesson;
      case 'practiceExam':
        return ReminderType.practiceExam;
      case 'vocabulary':
        return ReminderType.vocabulary;
      case 'speaking':
        return ReminderType.speaking;
      case 'listening':
        return ReminderType.listening;
      case 'custom':
        return ReminderType.custom;
      default:
        return ReminderType.custom;
    }
  }

  static String _typeToString(ReminderType type) {
    switch (type) {
      case ReminderType.dailyStudy:
        return 'dailyStudy';
      case ReminderType.reviewLesson:
        return 'reviewLesson';
      case ReminderType.practiceExam:
        return 'practiceExam';
      case ReminderType.vocabulary:
        return 'vocabulary';
      case ReminderType.speaking:
        return 'speaking';
      case ReminderType.listening:
        return 'listening';
      case ReminderType.custom:
        return 'custom';
    }
  }

  static RepeatType _repeatTypeFromString(String type) {
    switch (type) {
      case 'once':
        return RepeatType.once;
      case 'daily':
        return RepeatType.daily;
      case 'weekly':
        return RepeatType.weekly;
      case 'monthly':
        return RepeatType.monthly;
      case 'custom':
        return RepeatType.custom;
      default:
        return RepeatType.once;
    }
  }

  static String _repeatTypeToString(RepeatType type) {
    switch (type) {
      case RepeatType.once:
        return 'once';
      case RepeatType.daily:
        return 'daily';
      case RepeatType.weekly:
        return 'weekly';
      case RepeatType.monthly:
        return 'monthly';
      case RepeatType.custom:
        return 'custom';
    }
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lessonId': lessonId,
      'title': title,
      'description': description,
      'type': _typeToString(type),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'repeatType': _repeatTypeToString(repeatType),
      'repeatDays': repeatDays,
      'repeatInterval': repeatInterval,
      'isEnabled': isEnabled,
      'soundUrl': soundUrl,
      'metadata': metadata,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  @override
  StudyReminder copyWith({
    String? id,
    String? userId,
    String? lessonId,
    String? title,
    String? description,
    ReminderType? type,
    DateTime? startTime,
    DateTime? endTime,
    RepeatType? repeatType,
    List<int>? repeatDays,
    int? repeatInterval,
    bool? isEnabled,
    String? soundUrl,
    Map<String, dynamic>? metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return StudyReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      isEnabled: isEnabled ?? this.isEnabled,
      soundUrl: soundUrl ?? this.soundUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validate dữ liệu
  static Map<String, String?> validate({
    String? userId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    List<int>? repeatDays,
    int? repeatInterval,
  }) {
    Map<String, String?> errors = {};

    if (userId == null || userId.isEmpty) {
      errors['userId'] = 'ID học viên không được để trống';
    }

    if (title == null || title.isEmpty) {
      errors['title'] = 'Tiêu đề không được để trống';
    }

    if (title != null && title.length > 100) {
      errors['title'] = 'Tiêu đề không được quá 100 ký tự';
    }

    if (description != null && description.length > 500) {
      errors['description'] = 'Mô tả không được quá 500 ký tự';
    }

    if (startTime == null) {
      errors['startTime'] = 'Thời gian bắt đầu không được để trống';
    }

    if (startTime != null && startTime.isBefore(DateTime.now())) {
      errors['startTime'] = 'Thời gian bắt đầu phải là thời gian trong tương lai';
    }

    if (endTime != null && endTime.isBefore(startTime ?? DateTime.now())) {
      errors['endTime'] = 'Thời gian kết thúc phải sau thời gian bắt đầu';
    }

    if (repeatDays != null) {
      for (var day in repeatDays) {
        if (day < 1 || day > 31) {
          errors['repeatDays'] = 'Ngày lặp lại không hợp lệ';
          break;
        }
      }
    }

    if (repeatInterval != null && repeatInterval < 1) {
      errors['repeatInterval'] = 'Khoảng cách lặp lại phải lớn hơn 0';
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      userId: userId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      repeatDays: repeatDays,
      repeatInterval: repeatInterval,
    );
  }

  // Tạo mới nhắc nhở
  static Future<StudyReminder?> createReminder({
    required String userId,
    String? lessonId,
    required String title,
    required String description,
    required ReminderType type,
    required DateTime startTime,
    DateTime? endTime,
    RepeatType repeatType = RepeatType.once,
    List<int> repeatDays = const [],
    int? repeatInterval,
    bool isEnabled = true,
    String? soundUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final errors = validate(
      userId: userId,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      repeatDays: repeatDays,
      repeatInterval: repeatInterval,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final reminderDoc = await FirebaseFirestore.instance
          .collection('study_reminders')
          .add({
        'userId': userId,
        'lessonId': lessonId,
        'title': title,
        'description': description,
        'type': _typeToString(type),
        'startTime': Timestamp.fromDate(startTime),
        'endTime': endTime != null ? Timestamp.fromDate(endTime) : null,
        'repeatType': _repeatTypeToString(repeatType),
        'repeatDays': repeatDays,
        'repeatInterval': repeatInterval,
        'isEnabled': isEnabled,
        'soundUrl': soundUrl,
        'metadata': metadata,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final reminderData = await reminderDoc.get();
      return StudyReminder.fromMap(
        reminderData.data() as Map<String, dynamic>,
        reminderData.id,
      );
    } catch (e) {
      print('Error creating reminder: $e');
      return null;
    }
  }

  // Lấy tất cả nhắc nhở của học viên
  static Future<List<StudyReminder>> getReminders(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('study_reminders')
          .where('userId', isEqualTo: userId)
          .where('isEnabled', isEqualTo: true)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => StudyReminder.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting reminders: $e');
      return [];
    }
  }

  // Lấy nhắc nhở cho một bài học
  static Future<List<StudyReminder>> getRemindersByLesson(
    String userId,
    String lessonId,
  ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('study_reminders')
          .where('userId', isEqualTo: userId)
          .where('lessonId', isEqualTo: lessonId)
          .where('isEnabled', isEqualTo: true)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => StudyReminder.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting lesson reminders: $e');
      return [];
    }
  }

  // Lấy nhắc nhở sắp đến
  static Future<List<StudyReminder>> getUpcomingReminders(
    String userId, {
    Duration window = const Duration(days: 7),
  }) async {
    try {
      final now = DateTime.now();
      final endWindow = now.add(window);

      final snapshot = await FirebaseFirestore.instance
          .collection('study_reminders')
          .where('userId', isEqualTo: userId)
          .where('isEnabled', isEqualTo: true)
          .where('startTime', isGreaterThan: Timestamp.fromDate(now))
          .where('startTime', isLessThan: Timestamp.fromDate(endWindow))
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => StudyReminder.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting upcoming reminders: $e');
      return [];
    }
  }

  // Cập nhật thông tin nhắc nhở
  Future<bool> update({
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    RepeatType? repeatType,
    List<int>? repeatDays,
    int? repeatInterval,
    bool? isEnabled,
    String? soundUrl,
  }) async {
    try {
      if (id == null) return false;

      final errors = validate(
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        repeatDays: repeatDays,
        repeatInterval: repeatInterval,
      );

      if (errors.isNotEmpty) {
        print('Validation errors: $errors');
        return false;
      }

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (startTime != null) updates['startTime'] = Timestamp.fromDate(startTime);
      if (endTime != null) {
        updates['endTime'] = Timestamp.fromDate(endTime);
      }
      if (repeatType != null) {
        updates['repeatType'] = _repeatTypeToString(repeatType);
      }
      if (repeatDays != null) updates['repeatDays'] = repeatDays;
      if (repeatInterval != null) updates['repeatInterval'] = repeatInterval;
      if (isEnabled != null) updates['isEnabled'] = isEnabled;
      if (soundUrl != null) updates['soundUrl'] = soundUrl;

      await FirebaseFirestore.instance
          .collection('study_reminders')
          .doc(id)
          .update(updates);

      return true;
    } catch (e) {
      print('Error updating reminder: $e');
      return false;
    }
  }

  // Bật/tắt nhắc nhở
  Future<bool> toggleEnabled() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('study_reminders')
          .doc(id)
          .update({
        'isEnabled': !isEnabled,
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error toggling reminder: $e');
      return false;
    }
  }

  // Xóa nhắc nhở
  Future<bool> delete() async {
    try {
      if (id == null) return false;

      await FirebaseFirestore.instance
          .collection('study_reminders')
          .doc(id)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting reminder: $e');
      return false;
    }
  }

  // Tính toán thời gian nhắc nhở tiếp theo
  DateTime? getNextReminderTime() {
    final now = DateTime.now();
    
    if (!isEnabled || (endTime != null && endTime!.isBefore(now))) {
      return null;
    }

    switch (repeatType) {
      case RepeatType.once:
        return startTime.isAfter(now) ? startTime : null;
      
      case RepeatType.daily:
        final today = DateTime(now.year, now.month, now.day,
            startTime.hour, startTime.minute);
        return today.isAfter(now) ? today : today.add(Duration(days: 1));
      
      case RepeatType.weekly:
        if (repeatDays.isEmpty) return null;
        
        var nextDate = DateTime(now.year, now.month, now.day,
            startTime.hour, startTime.minute);
        
        while (!repeatDays.contains(nextDate.weekday) ||
               nextDate.isBefore(now)) {
          nextDate = nextDate.add(Duration(days: 1));
        }
        
        return nextDate;
      
      case RepeatType.monthly:
        if (repeatDays.isEmpty) return null;
        
        var nextDate = DateTime(now.year, now.month, repeatDays.first,
            startTime.hour, startTime.minute);
        
        while (nextDate.isBefore(now)) {
          nextDate = DateTime(nextDate.year,
              nextDate.month + 1, repeatDays.first,
              startTime.hour, startTime.minute);
        }
        
        return nextDate;
      
      case RepeatType.custom:
        if (repeatInterval == null) return null;
        
        var nextDate = startTime;
        while (nextDate.isBefore(now)) {
          nextDate = nextDate.add(Duration(days: repeatInterval ?? 0));
        }
        
        return nextDate;
    }
  }
} 