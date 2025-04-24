import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/badge.dart' as app_badge;
import '../../services/badge_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({Key? key}) : super(key: key);

  @override
  _BadgesScreenState createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> with SingleTickerProviderStateMixin {
  final BadgeService _badgeService = BadgeService();
  final _auth = FirebaseAuth.instance;
  
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _earnedBadges = [];
  List<app_badge.Badge> _availableBadges = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBadges();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadBadges() async {
    setState(() => _isLoading = true);
    
    try {
      // Lấy danh sách huy hiệu đã đạt được
      final earnedBadges = await _badgeService.getUserBadgesWithDetails();
      
      // Lấy tất cả huy hiệu
      final allBadges = await _badgeService.getAllBadges();
      
      // Lọc ra các huy hiệu chưa đạt được và không ẩn
      final earnedBadgeIds = earnedBadges
          .map((item) => (item['badge'] as app_badge.Badge).id)
          .whereType<String>()
          .toSet();
          
      final availableBadges = allBadges
          .where((badge) => !earnedBadgeIds.contains(badge.id) && !badge.isHidden)
          .toList();
      
      setState(() {
        _earnedBadges = earnedBadges;
        _availableBadges = availableBadges;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading badges: $e');
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải huy hiệu: ${e.toString()}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Huy hiệu của tôi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đã đạt được'),
            Tab(text: 'Chưa đạt được'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEarnedBadgesTab(),
                _buildAvailableBadgesTab(),
              ],
            ),
    );
  }
  
  Widget _buildEarnedBadgesTab() {
    if (_earnedBadges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Bạn chưa đạt được huy hiệu nào',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy tiếp tục học tập để đạt được huy hiệu nhé!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _earnedBadges.length,
      itemBuilder: (context, index) {
        final item = _earnedBadges[index];
        final badge = item['badge'] as app_badge.Badge;
        final userBadge = item['userBadge'];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.shade50,
              child: Image.network(
                badge.iconUrl,
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.emoji_events,
                    size: 32,
                    color: Colors.amber.shade700,
                  );
                },
              ),
            ),
            title: Text(
              badge.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(badge.description),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Đạt được: ${_formatDate(userBadge.earnedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: userBadge.level > 1
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green,
                    child: Text(
                      'Lv${userBadge.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
  
  Widget _buildAvailableBadgesTab() {
    if (_availableBadges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Bạn đã đạt được tất cả huy hiệu!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thật tuyệt vời, hãy tiếp tục duy trì thành tích nhé!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableBadges.length,
      itemBuilder: (context, index) {
        final badge = _availableBadges[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              child: Icon(
                Icons.lock_outline,
                size: 32,
                color: Colors.grey.shade400,
              ),
            ),
            title: Text(
              badge.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(badge.description),
                const SizedBox(height: 8),
                Text(
                  _getBadgeRequirementText(badge),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _getBadgeRequirementText(app_badge.Badge badge) {
    switch (badge.type) {
      case app_badge.BadgeType.streak:
        final days = badge.requirements['streakDays'] ?? 0;
        return 'Yêu cầu: Học liên tục $days ngày';
      case app_badge.BadgeType.performance:
        if (badge.requirements['perfectScore'] == true) {
          return 'Yêu cầu: Đạt điểm tối đa trong bài kiểm tra';
        } else if (badge.requirements['completionTime'] != null) {
          final minutes = badge.requirements['completionTime'];
          return 'Yêu cầu: Hoàn thành bài học dưới $minutes phút';
        }
        return 'Yêu cầu: Đạt hiệu suất cao trong bài học';
      case app_badge.BadgeType.completion:
        if (badge.requirements['completedLessons'] != null) {
          final count = badge.requirements['completedLessons'];
          return 'Yêu cầu: Hoàn thành $count bài học';
        } else if (badge.requirements['completedLessonsWeekly'] != null) {
          final count = badge.requirements['completedLessonsWeekly'];
          return 'Yêu cầu: Hoàn thành $count bài học trong tuần';
        }
        return 'Yêu cầu: Hoàn thành các bài học';
      case app_badge.BadgeType.activity:
        if (badge.requirements['flashcardSets'] != null) {
          final count = badge.requirements['flashcardSets'];
          return 'Yêu cầu: Xem hết $count bộ flashcard';
        }
        return 'Yêu cầu: Hoàn thành các hoạt động học tập';
      default:
        return 'Hoàn thành điều kiện đặc biệt';
    }
  }
} 