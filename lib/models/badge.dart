import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

enum BadgeType {
  streak,         // Liên quan đến chuỗi ngày học
  performance,    // Liên quan đến điểm số và hiệu suất
  completion,     // Liên quan đến hoàn thành bài học
  activity,       // Liên quan đến các hoạt động như xem flashcard
  misc            // Khác
}

extension BadgeTypeExtension on BadgeType {
  String get label {
    switch (this) {
      case BadgeType.streak:
        return 'Chuỗi ngày học';
      case BadgeType.performance:
        return 'Hiệu suất';
      case BadgeType.completion:
        return 'Hoàn thành';
      case BadgeType.activity:
        return 'Hoạt động';
      case BadgeType.misc:
        return 'Khác';
    }
  }
}

class Badge extends BaseModel {
  final String name;              // Tên huy hiệu (vd: "Chăm chỉ")
  final String description;       // Mô tả huy hiệu
  final String iconUrl;           // URL của biểu tượng huy hiệu
  final BadgeType type;           // Loại huy hiệu
  final Map<String, dynamic> requirements; // Yêu cầu để đạt được huy hiệu
  final bool isHidden;            // Có ẩn huy hiệu không
  final bool isOneTime;           // Chỉ nhận một lần
  
  Badge({
    String? id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.requirements,
    this.isHidden = false,
    this.isOneTime = true,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
  
  factory Badge.fromMap(Map<String, dynamic> map, String id) {
    return Badge(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconUrl: map['iconUrl'] ?? '',
      type: _badgeTypeFromString(map['type'] ?? 'misc'),
      requirements: Map<String, dynamic>.from(map['requirements'] ?? {}),
      isHidden: map['isHidden'] ?? false,
      isOneTime: map['isOneTime'] ?? true,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }
  
  static BadgeType _badgeTypeFromString(String type) {
    switch (type) {
      case 'streak':
        return BadgeType.streak;
      case 'performance':
        return BadgeType.performance;
      case 'completion':
        return BadgeType.completion;
      case 'activity':
        return BadgeType.activity;
      default:
        return BadgeType.misc;
    }
  }
  
  static String _badgeTypeToString(BadgeType type) {
    switch (type) {
      case BadgeType.streak:
        return 'streak';
      case BadgeType.performance:
        return 'performance';
      case BadgeType.completion:
        return 'completion';
      case BadgeType.activity:
        return 'activity';
      case BadgeType.misc:
        return 'misc';
    }
  }
  
  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'type': _badgeTypeToString(type),
      'requirements': requirements,
      'isHidden': isHidden,
      'isOneTime': isOneTime,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }
  
  @override
  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    BadgeType? type,
    Map<String, dynamic>? requirements,
    bool? isHidden,
    bool? isOneTime,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      type: type ?? this.type,
      requirements: requirements ?? this.requirements,
      isHidden: isHidden ?? this.isHidden,
      isOneTime: isOneTime ?? this.isOneTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Validate dữ liệu
  static Map<String, String?> validate({
    String? name,
    String? description,
    String? iconUrl,
  }) {
    Map<String, String?> errors = {};
    
    if (name == null || name.isEmpty) {
      errors['name'] = 'Tên huy hiệu không được để trống';
    }
    
    if (description == null || description.isEmpty) {
      errors['description'] = 'Mô tả huy hiệu không được để trống';
    }
    
    if (iconUrl == null || iconUrl.isEmpty) {
      errors['iconUrl'] = 'URL biểu tượng không được để trống';
    }
    
    return errors;
  }
  
  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      name: name,
      description: description,
      iconUrl: iconUrl,
    );
  }
  
  // Tạo mới huy hiệu
  static Future<Badge?> createBadge({
    required String name,
    required String description,
    required String iconUrl,
    required BadgeType type,
    required Map<String, dynamic> requirements,
    bool isHidden = false,
    bool isOneTime = true,
  }) async {
    final errors = validate(
      name: name,
      description: description,
      iconUrl: iconUrl,
    );
    
    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }
    
    try {
      final badgeDoc = await FirebaseFirestore.instance
          .collection('badges')
          .add({
        'name': name,
        'description': description,
        'iconUrl': iconUrl,
        'type': _badgeTypeToString(type),
        'requirements': requirements,
        'isHidden': isHidden,
        'isOneTime': isOneTime,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      final badgeData = await badgeDoc.get();
      return Badge.fromMap(
        badgeData.data() as Map<String, dynamic>,
        badgeData.id,
      );
    } catch (e) {
      print('Error creating badge: $e');
      return null;
    }
  }
  
  // Lấy tất cả huy hiệu
  static Future<List<Badge>> getAllBadges() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('badges')
          .get();
      
      return snapshot.docs
          .map((doc) => Badge.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting badges: $e');
      return [];
    }
  }
  
  // Lấy huy hiệu theo loại
  static Future<List<Badge>> getBadgesByType(BadgeType type) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('badges')
          .where('type', isEqualTo: _badgeTypeToString(type))
          .get();
      
      return snapshot.docs
          .map((doc) => Badge.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting badges by type: $e');
      return [];
    }
  }
} 