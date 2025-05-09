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
    required String? name,
    required String? description,
    required String? iconUrl,
    required BadgeType type,
    required Map<String, dynamic> requirements,
    required bool isHidden,
    required bool isOneTime,
  }) async {
    if (name == null || name.isEmpty || 
        description == null || description.isEmpty || 
        iconUrl == null || iconUrl.isEmpty) {
      print('Error creating badge: Required fields are empty');
      return null;
    }
    
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
      print('DEBUG: Starting badge award process for user: $userId, badge: $badgeId');
      
      // Kiểm tra xem huy hiệu có tồn tại không
      final badgeDoc = await _badgesCollection.doc(badgeId).get();
      if (!badgeDoc.exists) {
        print('DEBUG: Badge does not exist with ID: $badgeId');
        return null;
      }
      
      // Lấy thông tin huy hiệu
      final badgeData = badgeDoc.data() as Map<String, dynamic>;
      final isOneTime = badgeData['isOneTime'] ?? true;
      print('DEBUG: Badge data: ${badgeData['name']}, isOneTime: $isOneTime');
      
      // Kiểm tra xem người dùng đã có huy hiệu này chưa
      if (isOneTime) {
        final existingBadge = await _userBadgesCollection
            .where('userId', isEqualTo: userId)
            .where('badgeId', isEqualTo: badgeId)
            .limit(1)
            .get();
        
        if (existingBadge.docs.isNotEmpty) {
          print('DEBUG: User already has this badge: ${badgeData['name']}');
          return UserBadge.fromMap(
            existingBadge.docs.first.data() as Map<String, dynamic>,
            existingBadge.docs.first.id,
          );
        }
      }
      
      print('DEBUG: Creating new badge for user');
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
      
      print('DEBUG: Updating user document with new badge');
      // Cập nhật danh sách huy hiệu trong người dùng
      await _firestore.collection('users').doc(userId).update({
        'badges': FieldValue.arrayUnion([badgeId]),
        'updatedAt': Timestamp.now(),
      });
      
      // Trả về huy hiệu đã tạo
      final userBadgeData = await userBadgeDoc.get();
      print('DEBUG: Successfully awarded badge: ${badgeData['name']} to user: $userId');
      return UserBadge.fromMap(
        userBadgeData.data() as Map<String, dynamic>,
        userBadgeData.id,
      );
    } catch (e) {
      print('DEBUG: Error awarding badge: $e');
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
  
  // Cập nhật huy hiệu
  Future<Badge?> updateBadge({
    required String badgeId,
    required String? name,
    required String? description,
    required String? iconUrl,
    required BadgeType type,
    required Map<String, dynamic> requirements,
    required bool isHidden,
    required bool isOneTime,
  }) async {
    if (name == null || name.isEmpty || 
        description == null || description.isEmpty || 
        iconUrl == null || iconUrl.isEmpty) {
      print('Error updating badge: Required fields are empty');
      return null;
    }
    
    try {
      final badgeDoc = await _badgesCollection.doc(badgeId).get();
      if (!badgeDoc.exists) return null;
      
      final updatedData = {
        'name': name,
        'description': description,
        'iconUrl': iconUrl,
        'type': _badgeTypeToString(type),
        'requirements': requirements,
        'isHidden': isHidden,
        'isOneTime': isOneTime,
        'updatedAt': Timestamp.now(),
      };
      
      await _badgesCollection.doc(badgeId).update(updatedData);
      
      return Badge.fromMap(updatedData, badgeId);
    } catch (e) {
      print('Error updating badge: $e');
      return null;
    }
  }
  
  // Xóa huy hiệu
  Future<bool> deleteBadge(String badgeId) async {
    try {
      // Kiểm tra xem có người dùng nào đang sở hữu huy hiệu này không
      final userBadges = await _userBadgesCollection
          .where('badgeId', isEqualTo: badgeId)
          .limit(1)
          .get();
      
      if (userBadges.docs.isNotEmpty) {
        print('Cannot delete badge: Some users are still using this badge');
        return false;
      }
      
      await _badgesCollection.doc(badgeId).delete();
      return true;
    } catch (e) {
      print('Error deleting badge: $e');
      return false;
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
        isHidden: false,
        isOneTime: true,
      );
      
      await createBadge(
        name: 'Kiên trì',
        description: 'Học liên tục 10 ngày',
        iconUrl: 'assets/images/badges/streak_10.png',
        type: BadgeType.streak,
        requirements: {'streakDays': 10},
        isHidden: false,
        isOneTime: true,
      );
      
      await createBadge(
        name: 'Bền bỉ',
        description: 'Học liên tục 30 ngày',
        iconUrl: 'assets/images/badges/streak_30.png',
        type: BadgeType.streak,
        requirements: {'streakDays': 30},
        isHidden: false,
        isOneTime: true,
      );
      
      // Huy hiệu hoàn thành
      await createBadge(
        name: 'Thành tích đầu tiên',
        description: 'Hoàn thành bài học đầu tiên',
        iconUrl: 'assets/images/badges/first_lesson.png',
        type: BadgeType.completion,
        requirements: {'completedLessons': 1},
        isHidden: false,
        isOneTime: true,
      );
      
      await createBadge(
        name: 'Chuyên cần',
        description: 'Học đủ tất cả bài trong tuần',
        iconUrl: 'assets/images/badges/weekly_completion.png',
        type: BadgeType.completion,
        requirements: {'completedLessonsWeekly': 7},
        isHidden: false,
        isOneTime: true,
      );
      
      // Huy hiệu hiệu suất
      await createBadge(
        name: 'Bài tập siêu sao',
        description: 'Đạt điểm tối đa bài kiểm tra',
        iconUrl: 'assets/images/badges/perfect_score.png',
        type: BadgeType.performance,
        requirements: {'perfectScore': true},
        isHidden: false,
        isOneTime: true,
      );
      
      await createBadge(
        name: 'Tốc độ ánh sáng',
        description: 'Hoàn thành bài học dưới 5 phút',
        iconUrl: 'assets/images/badges/speed.png',
        type: BadgeType.performance,
        requirements: {'completionTime': 5},
        isHidden: false,
        isOneTime: true,
      );
      
      // Huy hiệu hoạt động
      await createBadge(
        name: 'Chăm chỉ flashcard',
        description: 'Xem hết 10 bộ flashcard',
        iconUrl: 'assets/images/badges/flashcard_master.png',
        type: BadgeType.activity,
        requirements: {'flashcardSets': 10},
        isHidden: false,
        isOneTime: true,
      );
      
      print('Created default badges');
    } catch (e) {
      print('Error creating default badges: $e');
    }
  }

  // Tạo huy hiệu cho việc hoàn thành flashcard đầu tiên
  Future<Badge?> createFirstFlashcardBadge() async {
    print('DEBUG: Creating first flashcard badge');
    try {
      final badge = await createBadge(
        name: 'Flashcard Đầu Tiên',
        description: 'Hoàn thành flashcard đầu tiên của bạn',
        iconUrl: 'assets/images/badges/first_flashcard.png',
        type: BadgeType.activity,
        requirements: {
          'type': 'flashcard_completion',
          'count': 1,
        },
        isHidden: false,
        isOneTime: true,
      );
      print('DEBUG: First flashcard badge created: ${badge?.name}');
      return badge;
    } catch (e) {
      print('DEBUG: Error creating first flashcard badge: $e');
      return null;
    }
  }

  // Kiểm tra và trao huy hiệu cho việc hoàn thành flashcard
  Future<void> checkAndAwardFlashcardBadge(String userId) async {
    print('DEBUG: Checking flashcard badge eligibility for user: $userId');
    try {
      // Kiểm tra xem người dùng đã có huy hiệu flashcard đầu tiên chưa
      final userBadges = await getUserBadges(userId: userId);
      print('DEBUG: Current user badges count: ${userBadges.length}');

      // Tìm huy hiệu flashcard đầu tiên
      final firstFlashcardBadge = await _badgesCollection
          .where('name', isEqualTo: 'Flashcard Đầu Tiên')
          .limit(1)
          .get();

      if (firstFlashcardBadge.docs.isEmpty) {
        print('DEBUG: First flashcard badge not found, creating new one');
        final newBadge = await createFirstFlashcardBadge();
        if (newBadge != null) {
          print('DEBUG: Awarding new first flashcard badge to user');
          await awardBadgeToUser(
            userId: userId,
            badgeId: newBadge.id!,
            metadata: 'First flashcard completion',
          );
        }
      } else {
        final badgeId = firstFlashcardBadge.docs.first.id;
        print('DEBUG: Found existing first flashcard badge: $badgeId');
        
        // Kiểm tra xem người dùng đã có huy hiệu này chưa
        final hasBadge = userBadges.any((badge) => badge.badgeId == badgeId);
        if (!hasBadge) {
          print('DEBUG: Awarding first flashcard badge to user');
          await awardBadgeToUser(
            userId: userId,
            badgeId: badgeId,
            metadata: 'First flashcard completion',
          );
        } else {
          print('DEBUG: User already has first flashcard badge');
        }
      }
    } catch (e) {
      print('DEBUG: Error checking flashcard badge: $e');
    }
  }

  // Show badge notification
  Future<void> showBadgeNotification(String badgeName) async {
    print('DEBUG: New badge awarded: $badgeName');
    // TODO: Implement notification logic
  }
} 