import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _loading = true;
  
  // Notification settings states
  bool _classApprovalEnabled = true;
  bool _newLessonEnabled = true;
  bool _newTestEnabled = true;
  bool _newCommentEnabled = true;
  bool _teacherResponseEnabled = true;
  bool _badgeAwardEnabled = true;
  bool _dailyReminderEnabled = true;
  
  // Reminder time
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
    });
    
    // Load notification settings
    _classApprovalEnabled = await _notificationService.getNotificationSetting('class_approval');
    _newLessonEnabled = await _notificationService.getNotificationSetting('new_lesson');
    _newTestEnabled = await _notificationService.getNotificationSetting('new_test');
    _newCommentEnabled = await _notificationService.getNotificationSetting('new_comment');
    _teacherResponseEnabled = await _notificationService.getNotificationSetting('teacher_response');
    _badgeAwardEnabled = await _notificationService.getNotificationSetting('badge_award');
    _dailyReminderEnabled = await _notificationService.getNotificationSetting('daily_reminder');
    
    // Load reminder time
    _reminderTime = await _notificationService.getDailyReminderTime();
    
    setState(() {
      _loading = false;
    });
  }
  
  Future<void> _updateSetting(String key, bool value) async {
    await _notificationService.saveNotificationSetting(key, value);
    
    // Update state based on key
    setState(() {
      switch (key) {
        case 'class_approval':
          _classApprovalEnabled = value;
          break;
        case 'new_lesson':
          _newLessonEnabled = value;
          break;
        case 'new_test':
          _newTestEnabled = value;
          break;
        case 'new_comment':
          _newCommentEnabled = value;
          break;
        case 'teacher_response':
          _teacherResponseEnabled = value;
          break;
        case 'badge_award':
          _badgeAwardEnabled = value;
          break;
        case 'daily_reminder':
          _dailyReminderEnabled = value;
          break;
      }
    });
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    
    if (pickedTime != null && pickedTime != _reminderTime) {
      await _notificationService.setDailyReminderTime(pickedTime);
      setState(() {
        _reminderTime = pickedTime;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Loại thông báo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Class approval notifications
                SwitchListTile(
                  title: const Text('Học sinh được duyệt vào lớp'),
                  subtitle: const Text('Thông báo khi bạn được duyệt vào lớp học'),
                  value: _classApprovalEnabled,
                  onChanged: (value) => _updateSetting('class_approval', value),
                ),
                
                // New lesson notifications
                SwitchListTile(
                  title: const Text('Bài học mới'),
                  subtitle: const Text('Thông báo khi có bài học mới được thêm vào lớp'),
                  value: _newLessonEnabled,
                  onChanged: (value) => _updateSetting('new_lesson', value),
                ),
                
                // New test notifications
                SwitchListTile(
                  title: const Text('Bài kiểm tra mới'),
                  subtitle: const Text('Thông báo khi có bài kiểm tra mới'),
                  value: _newTestEnabled,
                  onChanged: (value) => _updateSetting('new_test', value),
                ),
                
                // New comment notifications
                SwitchListTile(
                  title: const Text('Bình luận mới'),
                  subtitle: const Text('Thông báo khi có bình luận mới trong diễn đàn'),
                  value: _newCommentEnabled,
                  onChanged: (value) => _updateSetting('new_comment', value),
                ),
                
                // Teacher response notifications
                SwitchListTile(
                  title: const Text('Phản hồi từ giáo viên'),
                  subtitle: const Text('Thông báo khi giáo viên phản hồi thắc mắc của bạn'),
                  value: _teacherResponseEnabled,
                  onChanged: (value) => _updateSetting('teacher_response', value),
                ),
                
                // Badge award notifications
                SwitchListTile(
                  title: const Text('Huy hiệu mới'),
                  subtitle: const Text('Thông báo khi bạn nhận được huy hiệu mới'),
                  value: _badgeAwardEnabled,
                  onChanged: (value) => _updateSetting('badge_award', value),
                ),
                
                const Divider(),
                
                // Daily reminder settings
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Nhắc nhở học tập hằng ngày',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                SwitchListTile(
                  title: const Text('Bật nhắc nhở hằng ngày'),
                  subtitle: const Text('Nhận thông báo nhắc nhở học tập đều đặn'),
                  value: _dailyReminderEnabled,
                  onChanged: (value) => _updateSetting('daily_reminder', value),
                ),
                
                ListTile(
                  title: const Text('Giờ nhắc nhở'),
                  subtitle: Text(
                    '${_reminderTime.hour}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.access_time),
                  enabled: _dailyReminderEnabled,
                  onTap: _dailyReminderEnabled ? () => _selectTime(context) : null,
                ),
                
                const SizedBox(height: 16),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Nhắc nhở sẽ được gửi lúc ${_reminderTime.hour}:${_reminderTime.minute.toString().padLeft(2, '0')} nếu bạn chưa học gì trong ngày hôm đó.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
    );
  }
} 