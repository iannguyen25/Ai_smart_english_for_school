import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationTestScreen extends StatelessWidget {
  final NotificationService _notificationService = NotificationService();

  NotificationTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  await _notificationService.showNotification(
                    title: 'Test ngay lập tức',
                    body: 'Đây là notification test ngay lập tức',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi notification ngay lập tức')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text('Test notification ngay'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _notificationService.scheduleDailyNotification(
                    id: 1,
                    title: 'Test hẹn giờ',
                    body: 'Đây là notification test sau 1 phút',
                    hour: DateTime.now().hour,
                    minute: DateTime.now().minute + 1,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã đặt lịch notification sau 1 phút')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text('Test notification sau 1 phút'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _notificationService.cancelAllNotifications();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã hủy tất cả notifications')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: const Text('Hủy tất cả notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}