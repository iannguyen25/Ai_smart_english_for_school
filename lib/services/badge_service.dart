import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/badge.dart';
import '../models/user_badge.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  CollectionReference get _badgesCollection => _firestore.collection('badges');
  CollectionReference get _userBadgesCollection => _firestore.collection('user_badges');
  
  // Lấy tất cả huy hiệu
  Future<List<Badge>> getAllBadges() async {
    try {
      final snapshot = await _badgesCollection.get();
      
      return snapshot.docs
          .map((doc) => Badge.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting badges: $e');
      return [];
    }
  }
  
  // Lấy huy hiệu theo loại
  Future<List<Badge>> getBadgesByType(BadgeType type) async {
    try {
      final snapshot = await _badgesCollection
          .where('type', isEqualTo: _badgeTypeToString(type))
          .get();
      
      return snapshot.docs
          .map((doc) => Badge.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting badges by type: $e');
      return [];
    }
  }
  
  // Chuyển đổi BadgeType thành chuỗi
  String _badgeTypeToString(BadgeType type) {
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
  
  // Tạo huy hiệu mới
  Future<Badge?> createBadge({
    required String name,
    required String description,
    required String iconUrl,
    required BadgeType type,
    required Map<String, dynamic> requirements,
    bool isHidden = false,
    bool isOneTime = true,
  }) async {
    try {
      final badgeDoc = await _badgesCollection.add({
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
  
  // Lấy danh sách huy hiệu của người dùng
  Future<List<UserBadge>> getUserBadges({String? userId}) async {
    try {
      final user = userId ?? _auth.currentUser?.uid;
      if (user == null) return [];
      
      final snapshot = await _userBadgesCollection
          .where('userId', isEqualTo: user)
          .orderBy('earnedAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => UserBadge.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting user badges: $e');
      return [];
    }
  }
  
  // Kiểm tra và trao huy hiệu cho người dùng
  Future<UserBadge?> awardBadgeToUser({
    required String userId,
    required String badgeId,
    String? metadata,
  }) async {
    try {
      // Kiểm tra xem huy hiệu có tồn tại không
      final badgeDoc = await _badgesCollection.doc(badgeId).get();
      if (!badgeDoc.exists) {
        print('Badge does not exist');
        return null;
      }
      
      // Lấy thông tin huy hiệu
      final badgeData = badgeDoc.data() as Map<String, dynamic>;
      final isOneTime = badgeData['isOneTime'] ?? true;
      
      // Kiểm tra xem người dùng đã có huy hiệu này chưa
      if (isOneTime) {
        final existingBadge = await _userBadgesCollection
            .where('userId', isEqualTo: userId)
            .where('badgeId', isEqualTo: badgeId)
            .limit(1)
            .get();
        
        if (existingBadge.docs.isNotEmpty) {
          print('User already has this badge');
          return UserBadge.fromMap(
            existingBadge.docs.first.data() as Map<String, dynamic>,
            existingBadge.docs.first.id,
          );
        }
      }
      
      // Tạo huy hiệu mới cho người dùng
      final userBadgeDoc = await _userBadgesCollection.add({
        'userId': userId,
        'badgeId': badgeId,
        'earnedAt': Timestamp.now(),
        'level': 1,
        'metadata': metadata,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      // Cập nhật danh sách huy hiệu trong người dùng
      await _firestore.collection('users').doc(userId).update({
        'badges': FieldValue.arrayUnion([badgeId]),
        'updatedAt': Timestamp.now(),
      });
      
      // Trả về huy hiệu đã tạo
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
  
  // Lấy chi tiết huy hiệu bằng ID
  Future<Badge?> getBadgeById(String badgeId) async {
    try {
      final badgeDoc = await _badgesCollection.doc(badgeId).get();
      
      if (!badgeDoc.exists) return null;
      
      return Badge.fromMap(
        badgeDoc.data() as Map<String, dynamic>,
        badgeDoc.id,
      );
    } catch (e) {
      print('Error getting badge: $e');
      return null;
    }
  }
  
  // Lấy danh sách huy hiệu người dùng với chi tiết
  Future<List<Map<String, dynamic>>> getUserBadgesWithDetails({String? userId}) async {
    try {
      final user = userId ?? _auth.currentUser?.uid;
      if (user == null) return [];
      
      // Lấy danh sách huy hiệu người dùng
      final userBadges = await getUserBadges(userId: user);
      
      // Tạo danh sách kết quả
      final result = <Map<String, dynamic>>[];
      
      // Lấy chi tiết từng huy hiệu
      for (final userBadge in userBadges) {
        final badge = await getBadgeById(userBadge.badgeId);
        if (badge != null) {
          result.add({
            'userBadge': userBadge,
            'badge': badge,
          });
        }
      }
      
      return result;
    } catch (e) {
      print('Error getting user badges with details: $e');
      return [];
    }
  }
  
  // Tạo các huy hiệu mặc định
  Future<void> createDefaultBadges() async {
    try {
      // Kiểm tra xem đã có huy hiệu nào chưa
      final existingBadges = await getAllBadges();
      if (existingBadges.isNotEmpty) {
        print('Badges already exist, skipping default creation');
        return;
      }
      
      // Các huy hiệu streak
      await createBadge(
        name: 'Chăm chỉ',
        description: 'Học liên tục 5 ngày',
        iconUrl: 'assets/images/badges/streak_5.png',
        type: BadgeType.streak,
        requirements: {'streakDays': 5},
      );
      
      await createBadge(
        name: 'Kiên trì',
        description: 'Học liên tục 10 ngày',
        iconUrl: 'assets/images/badges/streak_10.png',
        type: BadgeType.streak,
        requirements: {'streakDays': 10},
      );
      
      await createBadge(
        name: 'Bền bỉ',
        description: 'Học liên tục 30 ngày',
        iconUrl: 'assets/images/badges/streak_30.png',
        type: BadgeType.streak,
        requirements: {'streakDays': 30},
      );
      
      // Huy hiệu hoàn thành
      await createBadge(
        name: 'Thành tích đầu tiên',
        description: 'Hoàn thành bài học đầu tiên',
        iconUrl: 'assets/images/badges/first_lesson.png',
        type: BadgeType.completion,
        requirements: {'completedLessons': 1},
      );
      
      await createBadge(
        name: 'Chuyên cần',
        description: 'Học đủ tất cả bài trong tuần',
        iconUrl: 'assets/images/badges/weekly_completion.png',
        type: BadgeType.completion,
        requirements: {'completedLessonsWeekly': 7},
      );
      
      // Huy hiệu hiệu suất
      await createBadge(
        name: 'Bài tập siêu sao',
        description: 'Đạt điểm tối đa bài kiểm tra',
        iconUrl: 'assets/images/badges/perfect_score.png',
        type: BadgeType.performance,
        requirements: {'perfectScore': true},
      );
      
      await createBadge(
        name: 'Tốc độ ánh sáng',
        description: 'Hoàn thành bài học dưới 5 phút',
        iconUrl: 'assets/images/badges/speed.png',
        type: BadgeType.performance,
        requirements: {'completionTime': 5},
      );
      
      // Huy hiệu hoạt động
      await createBadge(
        name: 'Chăm chỉ flashcard',
        description: 'Xem hết 10 bộ flashcard',
        iconUrl: 'assets/images/badges/flashcard_master.png',
        type: BadgeType.activity,
        requirements: {'flashcardSets': 10},
      );
      
      print('Created default badges');
    } catch (e) {
      print('Error creating default badges: $e');
    }
  }
} 