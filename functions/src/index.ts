import { onRequest } from 'firebase-functions/v2/https';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import * as admin from 'firebase-admin';
import { Response } from 'express';
import type { Request } from 'firebase-functions/v2/https';

admin.initializeApp();

interface NotificationData {
  notification: {
    title: string;
    body: string;
  };
  topic?: string;
  userId?: string;
  data?: Record<string, string>;
}

// Gửi notification đến topic hoặc user cụ thể
export const sendNotification = onRequest(async (req: Request, res: Response) => {
  try {
    const data = req.body as NotificationData;
    const notification = {
      title: data.notification.title,
      body: data.notification.body,
    };
    const messageData = data.data || {};

    let message: admin.messaging.TopicMessage | admin.messaging.TokenMessage;

    if (data.topic) {
      message = {
        topic: data.topic,
        notification,
        data: messageData,
      };
    } else if (data.userId) {
      const userDoc = await admin.firestore().collection('users').doc(data.userId).get();
      const fcmToken = userDoc.data()?.fcmToken;
      if (fcmToken) {
        message = {
          token: fcmToken,
          notification,
          data: messageData,
        };
      } else {
        throw new Error('User FCM token not found');
      }
    } else {
      throw new Error('Either topic or userId must be provided');
    }

    const response = await admin.messaging().send(message);
    res.json({ success: true, messageId: response });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ error: 'Failed to send notification' });
  }
});

interface LessonData {
  status: string;
  classId: string;
  teacherId: string;
  title: string;
}

// Trigger khi bài học được phê duyệt
export const onLessonApproved = onDocumentUpdated('lessons/{lessonId}', async (event) => {
  const before = event.data?.before.data() as LessonData;
  const after = event.data?.after.data() as LessonData;
  const lessonId = event.params.lessonId;

  // Chỉ xử lý khi status chuyển từ 'pending' sang 'approved'
  if (before.status === 'pending' && after.status === 'approved') {
    try {
      // Lấy thông tin lớp học và giáo viên
      const classDoc = await admin.firestore().collection('classes').doc(after.classId).get();
      const teacherDoc = await admin.firestore().collection('users').doc(after.teacherId).get();
      
      if (!classDoc.exists || !teacherDoc.exists) {
        throw new Error('Class or teacher not found');
      }

      const teacherName = teacherDoc.data()?.displayName;

      // Gửi notification đến tất cả học sinh trong lớp
      await admin.messaging().send({
        topic: `class_${after.classId}`,
        notification: {
          title: 'Bài học mới',
          body: `GV ${teacherName} đã đăng bài "${after.title}"`,
        },
        data: {
          type: 'new_lesson',
          lessonId: lessonId,
          classId: after.classId,
        },
      });

      console.log('Sent notifications for approved lesson:', lessonId);
    } catch (error) {
      console.error('Error processing lesson approval:', error);
    }
  }
}); 