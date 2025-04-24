import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/streak_service.dart';

class StreakWidget extends StatefulWidget {
  const StreakWidget({Key? key}) : super(key: key);

  @override
  _StreakWidgetState createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget> {
  final StreakService _streakService = StreakService();
  bool _isLoading = true;
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastStudiedDate;
  
  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }
  
  Future<void> _loadStreakData() async {
    setState(() => _isLoading = true);
    
    try {
      final streakData = await _streakService.getUserStreak();
      
      setState(() {
        _currentStreak = streakData['currentStreak'] ?? 0;
        _longestStreak = streakData['longestStreak'] ?? 0;
        _lastStudiedDate = streakData['lastStudiedDate'] != null 
            ? (streakData['lastStudiedDate'] as dynamic).toDate() 
            : null;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading streak data: $e');
      setState(() => _isLoading = false);
    }
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Chưa học lần nào';
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _getStreakMessage() {
    if (_currentStreak == 0) {
      return 'Hãy bắt đầu học để tạo chuỗi ngày học!';
    } else if (_currentStreak == 1) {
      return 'Bạn đã bắt đầu! Hãy tiếp tục học mỗi ngày.';
    } else if (_currentStreak < 5) {
      return 'Khá tốt! Hãy giữ đà này nhé.';
    } else if (_currentStreak < 10) {
      return 'Tuyệt vời! Bạn đang làm rất tốt.';
    } else if (_currentStreak < 30) {
      return 'Ấn tượng! Bạn thực sự kiên trì.';
    } else {
      return 'Xuất sắc! Bạn là học viên chăm chỉ nhất!';
    }
  }
  
  bool _canContinueToday() {
    if (_lastStudiedDate == null) return true;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      _lastStudiedDate!.year,
      _lastStudiedDate!.month,
      _lastStudiedDate!.day,
    );
    
    // Có thể tiếp tục nếu không phải hôm nay
    return !today.isAtSameMomentAs(lastDate);
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.deepOrange),
                SizedBox(width: 8),
                Text(
                  'Chuỗi ngày học',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current streak
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Current streak
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_currentStreak',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _getStreakColor(_currentStreak),
                        ),
                      ),
                      const Text('Ngày hiện tại'),
                    ],
                  ),
                  
                  // Divider
                  Container(
                    height: 60,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  
                  // Best streak
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_longestStreak',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text('Kỷ lục'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Divider
            Divider(color: Colors.grey.shade300),
            
            // Message
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _getStreakMessage(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Last studied
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Học gần nhất: ${_formatDate(_lastStudiedDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Button to continue
            if (_canContinueToday())
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Học ngay để duy trì streak'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // Navigate to lessons screen
                  Navigator.of(context).pushNamed('/classrooms');
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Color _getStreakColor(int streak) {
    if (streak == 0) return Colors.grey;
    if (streak < 3) return Colors.blue;
    if (streak < 7) return Colors.green;
    if (streak < 14) return Colors.orange;
    if (streak < 30) return Colors.deepOrange;
    return Colors.red;
  }
} 