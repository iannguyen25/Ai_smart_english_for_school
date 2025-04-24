import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class UserBadge extends BaseModel {
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final int level;          // Cấp độ của huy hiệu (nếu có)
  final String? metadata;   // Dữ liệu bổ sung về việc đạt được huy hiệu

  UserBadge({
    String? id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    this.level = 1,
    this.metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory UserBadge.fromMap(Map<String, dynamic> map, String id) {
    return UserBadge(
      id: id,
      userId: map['userId'] ?? '',
      badgeId: map['badgeId'] ?? '',
      earnedAt: (map['earnedAt'] as Timestamp).toDate(),
      level: map['level'] ?? 1,
      metadata: map['metadata'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'] ?? map['createdAt'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'badgeId': badgeId,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'level': level,
      'metadata': metadata,
      'createdAt': createdAt ?? Timestamp.now(),
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  @override
  UserBadge copyWith({
    String? id,
    String? userId,
    String? badgeId,
    DateTime? earnedAt,
    int? level,
    String? metadata,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return UserBadge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      badgeId: badgeId ?? this.badgeId,
      earnedAt: earnedAt ?? this.earnedAt,
      level: level ?? this.level,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Thêm huy hiệu mới cho người dùng
  static Future<UserBadge?> awardBadgeToUser({
    required String userId,
    required String badgeId,
    int level = 1,
    String? metadata,
  }) async {
    try {
      // Kiểm tra xem người dùng đã có huy hiệu này chưa
      final existingBadges = await FirebaseFirestore.instance
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .where('badgeId', isEqualTo: badgeId)
          .get();
      
      // Nếu đã có huy hiệu và là huy hiệu một lần, không thêm nữa
      if (existingBadges.docs.isNotEmpty) {
        // Kiểm tra xem huy hiệu có thể nâng cấp không
        final existingBadge = UserBadge.fromMap(
          existingBadges.docs.first.data(), 
          existingBadges.docs.first.id
        );
        
        // Nếu cấp độ mới cao hơn, cập nhật cấp độ
        if (level > existingBadge.level) {
          await FirebaseFirestore.instance
              .collection('user_badges')
              .doc(existingBadge.id)
              .update({
            'level': level,
            'updatedAt': Timestamp.now(),
          });
          
          return existingBadge.copyWith(level: level);
        }
        
        return existingBadge;
      }
      
      // Thêm huy hiệu mới
      final now = DateTime.now();
      final userBadgeDoc = await FirebaseFirestore.instance
          .collection('user_badges')
          .add({
        'userId': userId,
        'badgeId': badgeId,
        'earnedAt': Timestamp.fromDate(now),
        'level': level,
        'metadata': metadata,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      // Cập nhật danh sách huy hiệu trong người dùng
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'badges': FieldValue.arrayUnion([badgeId]),
        'updatedAt': Timestamp.now(),
      });
      
      final userBadgeData = await userBadgeDoc.get();
      return UserBadge.fromMap(
        userBadgeData.data() as Map<String, dynamic>,
        userBadgeData.id,
      );
    } catch (e) {
      print('Error awarding badge: $e');
      return null;
    }
  }
  
  // Lấy danh sách huy hiệu của người dùng
  static Future<List<UserBadge>> getUserBadges(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .orderBy('earnedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => UserBadge.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting user badges: $e');
      return [];
    }
  }
  
  // Kiểm tra xem người dùng đã có huy hiệu chưa
  static Future<bool> hasUserEarnedBadge(String userId, String badgeId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .where('badgeId', isEqualTo: badgeId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking badge: $e');
      return false;
    }
  }
} 