import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/badge.dart';
import '../services/badge_service.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BadgeService _badgeService = BadgeService();
  
  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  // Cập nhật streak khi người dùng học
  Future<bool> updateStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final userDoc = await _usersCollection.doc(user.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Lấy các giá trị hiện tại
      final int currentStreak = userData['currentStreak'] ?? 0;
      final int longestStreak = userData['longestStreak'] ?? 0;
      final Timestamp? lastStudiedDate = userData['lastStudiedDate'];
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Nếu chưa có ngày học cuối cùng, đây là lần đầu tiên
      if (lastStudiedDate == null) {
        await _usersCollection.doc(user.uid).update({
          'currentStreak': 1,
          'longestStreak': 1,
          'lastStudiedDate': Timestamp.fromDate(today),
          'updatedAt': Timestamp.now(),
        });
        
        // Kiểm tra huy hiệu streak 1 ngày
        await _checkAndAwardStreakBadges(user.uid, 1);
        
        return true;
      }
      
      // Chuyển đổi timestamp thành DateTime
      final lastDate = lastStudiedDate.toDate();
      final lastDateNormalized = DateTime(lastDate.year, lastDate.month, lastDate.day);
      
      // Tính khoảng cách giữa ngày hôm nay và ngày học cuối cùng
      final difference = today.difference(lastDateNormalized).inDays;
      
      // Nếu là cùng ngày, không cập nhật streak
      if (difference == 0) {
        return true;
      }
      
      // Nếu học liên tiếp ngày hôm sau
      if (difference == 1) {
        final newStreak = currentStreak + 1;
        final newLongestStreak = newStreak > longestStreak ? newStreak : longestStreak;
        
        await _usersCollection.doc(user.uid).update({
          'currentStreak': newStreak,
          'longestStreak': newLongestStreak,
          'lastStudiedDate': Timestamp.fromDate(today),
          'updatedAt': Timestamp.now(),
        });
        
        // Kiểm tra các huy hiệu streak
        await _checkAndAwardStreakBadges(user.uid, newStreak);
        
        return true;
      }
      
      // Nếu bỏ 1 ngày hoặc nhiều ngày, reset streak
      await _usersCollection.doc(user.uid).update({
        'currentStreak': 1,
        'lastStudiedDate': Timestamp.fromDate(today),
        'updatedAt': Timestamp.now(),
      });
      
      return true;
    } catch (e) {
      print('Error updating streak: $e');
      return false;
    }
  }
  
  // Lấy thông tin streak của người dùng
  Future<Map<String, dynamic>> getUserStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'currentStreak': 0,
          'longestStreak': 0,
          'lastStudiedDate': null,
        };
      }
      
      final userDoc = await _usersCollection.doc(user.uid).get();
      if (!userDoc.exists) {
        return {
          'currentStreak': 0,
          'longestStreak': 0,
          'lastStudiedDate': null,
        };
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      return {
        'currentStreak': userData['currentStreak'] ?? 0,
        'longestStreak': userData['longestStreak'] ?? 0,
        'lastStudiedDate': userData['lastStudiedDate'],
      };
    } catch (e) {
      print('Error getting user streak: $e');
      return {
        'currentStreak': 0,
        'longestStreak': 0,
        'lastStudiedDate': null,
      };
    }
  }
  
  // Kiểm tra và cấp huy hiệu liên quan đến streak
  Future<void> _checkAndAwardStreakBadges(String userId, int streak) async {
    // Các mốc streak thường được trao thưởng
    final streakMilestones = [5, 10, 30, 60, 100, 365];
    
    // Kiểm tra từng mốc
    for (final milestone in streakMilestones) {
      if (streak == milestone) {
        try {
          // Lấy huy hiệu streak tương ứng
          final badges = await _badgeService.getBadgesByType(BadgeType.streak);
          final streakBadge = badges.firstWhere(
            (badge) => badge.requirements['streakDays'] == milestone,
            orElse: () => badges.firstWhere(
              (badge) => badge.name.contains('$milestone'),
              orElse: () => badges.first,
            ),
          );
          
          // Trao thưởng cho người dùng
          await _badgeService.awardBadgeToUser(
            userId: userId,
            badgeId: streakBadge.id!,
            metadata: 'Đạt chuỗi $milestone ngày học liên tiếp',
          );
        } catch (e) {
          print('Error awarding streak badge: $e');
        }
        break; // Chỉ trao một huy hiệu tại một thời điểm
      }
    }
  }
  
  // Kiểm tra xem người dùng có thể tiếp tục streak hôm nay không
  Future<bool> canContinueStreakToday() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final userDoc = await _usersCollection.doc(user.uid).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final Timestamp? lastStudiedDate = userData['lastStudiedDate'];
      
      // Nếu chưa từng học, có thể bắt đầu streak
      if (lastStudiedDate == null) return true;
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Chuyển đổi timestamp thành DateTime
      final lastDate = lastStudiedDate.toDate();
      final lastDateNormalized = DateTime(lastDate.year, lastDate.month, lastDate.day);
      
      // Nếu đã học hôm nay, không thể tiếp tục
      if (lastDateNormalized.isAtSameMomentAs(today)) {
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error checking streak continuation: $e');
      return false;
    }
  }
} 