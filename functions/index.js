const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Firestore references
const db = admin.firestore();

/**
 * Send notification when a student is approved to join a class
 */
exports.onStudentApproved = functions.firestore
  .document('classrooms/{classroomId}/enrollments/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const classroomId = context.params.classroomId;
    const userId = context.params.userId;

    // Check if the student was just approved
    if (before.status !== 'approved' && after.status === 'approved') {
      try {
        // Get classroom details
        const classroomSnapshot = await db.collection('classrooms').doc(classroomId).get();
        const classroom = classroomSnapshot.data();

        if (!classroom) {
          console.log('Classroom not found:', classroomId);
          return null;
        }

        // Get user's FCM token(s) from user document
        const userSnapshot = await db.collection('users').doc(userId).get();
        const user = userSnapshot.data();

        if (!user || !user.fcmTokens) {
          console.log('User or FCM tokens not found for user:', userId);
          return null;
        }

        // Send notification to all user's devices
        const tokens = Object.values(user.fcmTokens).filter(token => token);
        
        if (tokens.length === 0) {
          console.log('No valid FCM tokens found for user:', userId);
          return null;
        }

        const message = {
          notification: {
            title: 'Đã được duyệt vào lớp',
            body: `Bạn đã được duyệt vào lớp ${classroom.name}.`
          },
          data: {
            type: 'class_approval',
            channel_id: 'class_approval',
            target_id: classroomId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK'
          },
          tokens: tokens
        };

        const response = await admin.messaging().sendMulticast(message);
        console.log('Notification sent successfully to', tokens.length, 'devices.');
        console.log('Successful sends:', response.successCount);
        console.log('Failed sends:', response.failureCount);

        return null;
      } catch (error) {
        console.error('Error sending notification:', error);
        return null;
      }
    }

    return null;
  });

/**
 * Send notification when a new lesson is added to a class
 */
exports.onNewLessonAdded = functions.firestore
  .document('classrooms/{classroomId}/lessons/{lessonId}')
  .onCreate(async (snapshot, context) => {
    const lessonData = snapshot.data();
    const classroomId = context.params.classroomId;

    try {
      // Get classroom details
      const classroomSnapshot = await db.collection('classrooms').doc(classroomId).get();
      const classroom = classroomSnapshot.data();

      if (!classroom) {
        console.log('Classroom not found:', classroomId);
        return null;
      }

      // Get all students enrolled in the class
      const enrollmentsSnapshot = await db.collection('classrooms').doc(classroomId)
        .collection('enrollments')
        .where('status', '==', 'approved')
        .get();

      if (enrollmentsSnapshot.empty) {
        console.log('No enrolled students found for classroom:', classroomId);
        return null;
      }

      // Send to all enrolled students
      const sendPromises = enrollmentsSnapshot.docs.map(async (doc) => {
        const userId = doc.id;
        
        // Get user's FCM tokens
        const userSnapshot = await db.collection('users').doc(userId).get();
        const user = userSnapshot.data();

        if (!user || !user.fcmTokens) {
          console.log('User or FCM tokens not found for user:', userId);
          return;
        }

        const tokens = Object.values(user.fcmTokens).filter(token => token);
        
        if (tokens.length === 0) {
          console.log('No valid FCM tokens found for user:', userId);
          return;
        }

        const message = {
          notification: {
            title: 'Bài học mới',
            body: `Bài học mới "${lessonData.title}" đã được thêm vào lớp ${classroom.name}!`
          },
          data: {
            type: 'new_lesson',
            channel_id: 'new_lesson',
            target_id: lessonData.id,
            classroom_id: classroomId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK'
          },
          tokens: tokens
        };

        try {
          const response = await admin.messaging().sendMulticast(message);
          console.log(`Notification sent successfully to user ${userId}: ${response.successCount} success, ${response.failureCount} failures`);
          return response;
        } catch (err) {
          console.error(`Error sending notification to user ${userId}:`, err);
          return null;
        }
      });

      await Promise.all(sendPromises);
      return null;
    } catch (error) {
      console.error('Error in onNewLessonAdded:', error);
      return null;
    }
  });

/**
 * Send notification when a new test is added to a class
 */
exports.onNewTestAdded = functions.firestore
  .document('classrooms/{classroomId}/tests/{testId}')
  .onCreate(async (snapshot, context) => {
    const testData = snapshot.data();
    const classroomId = context.params.classroomId;

    try {
      // Get classroom details
      const classroomSnapshot = await db.collection('classrooms').doc(classroomId).get();
      const classroom = classroomSnapshot.data();

      if (!classroom) {
        console.log('Classroom not found:', classroomId);
        return null;
      }

      // Get all students enrolled in the class
      const enrollmentsSnapshot = await db.collection('classrooms').doc(classroomId)
        .collection('enrollments')
        .where('status', '==', 'approved')
        .get();

      if (enrollmentsSnapshot.empty) {
        console.log('No enrolled students found for classroom:', classroomId);
        return null;
      }

      // Send to all enrolled students
      const sendPromises = enrollmentsSnapshot.docs.map(async (doc) => {
        const userId = doc.id;
        
        // Get user's FCM tokens
        const userSnapshot = await db.collection('users').doc(userId).get();
        const user = userSnapshot.data();

        if (!user || !user.fcmTokens) {
          console.log('User or FCM tokens not found for user:', userId);
          return;
        }

        const tokens = Object.values(user.fcmTokens).filter(token => token);
        
        if (tokens.length === 0) {
          console.log('No valid FCM tokens found for user:', userId);
          return;
        }

        const message = {
          notification: {
            title: 'Bài kiểm tra mới',
            body: `Bạn có một bài kiểm tra mới "${testData.title}" trong lớp ${classroom.name}.`
          },
          data: {
            type: 'new_test',
            channel_id: 'new_test',
            target_id: testData.id,
            classroom_id: classroomId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK'
          },
          tokens: tokens
        };

        try {
          const response = await admin.messaging().sendMulticast(message);
          console.log(`Notification sent successfully to user ${userId}: ${response.successCount} success, ${response.failureCount} failures`);
          return response;
        } catch (err) {
          console.error(`Error sending notification to user ${userId}:`, err);
          return null;
        }
      });

      await Promise.all(sendPromises);
      return null;
    } catch (error) {
      console.error('Error in onNewTestAdded:', error);
      return null;
    }
  });

/**
 * Send notification when a new comment is added to a forum topic
 */
exports.onNewComment = functions.firestore
  .document('forums/{forumId}/comments/{commentId}')
  .onCreate(async (snapshot, context) => {
    const commentData = snapshot.data();
    const forumId = context.params.forumId;
    const commenterId = commentData.userId;

    try {
      // Get forum topic details
      const forumSnapshot = await db.collection('forums').doc(forumId).get();
      const forum = forumSnapshot.data();

      if (!forum) {
        console.log('Forum topic not found:', forumId);
        return null;
      }

      // Get all previous commenters (excluding the current commenter)
      const commentsSnapshot = await db.collection('forums').doc(forumId)
        .collection('comments')
        .where('userId', '!=', commenterId)
        .get();

      // Extract unique user IDs of commenters
      const commentersSet = new Set();
      commentsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        if (data.userId) {
          commentersSet.add(data.userId);
        }
      });

      // Add the forum creator if not the current commenter
      if (forum.createdBy && forum.createdBy !== commenterId) {
        commentersSet.add(forum.createdBy);
      }

      if (commentersSet.size === 0) {
        console.log('No users to notify for forum:', forumId);
        return null;
      }

      // Get user's name who commented
      const commenterSnapshot = await db.collection('users').doc(commenterId).get();
      const commenter = commenterSnapshot.data();
      const commenterName = commenter ? commenter.fullName || 'Người dùng' : 'Người dùng';

      // Send to all interested users
      const userIds = Array.from(commentersSet);
      const sendPromises = userIds.map(async (userId) => {
        // Get user's FCM tokens
        const userSnapshot = await db.collection('users').doc(userId).get();
        const user = userSnapshot.data();

        if (!user || !user.fcmTokens) {
          console.log('User or FCM tokens not found for user:', userId);
          return;
        }

        const tokens = Object.values(user.fcmTokens).filter(token => token);
        
        if (tokens.length === 0) {
          console.log('No valid FCM tokens found for user:', userId);
          return;
        }

        const message = {
          notification: {
            title: 'Bình luận mới',
            body: `${commenterName} đã bình luận trong chủ đề "${forum.title}".`
          },
          data: {
            type: 'new_comment',
            channel_id: 'new_comment',
            target_id: forumId,
            comment_id: commentId,
            click_action: 'FLUTTER_NOTIFICATION_CLICK'
          },
          tokens: tokens
        };

        try {
          const response = await admin.messaging().sendMulticast(message);
          console.log(`Comment notification sent to user ${userId}: ${response.successCount} success, ${response.failureCount} failures`);
          return response;
        } catch (err) {
          console.error(`Error sending comment notification to user ${userId}:`, err);
          return null;
        }
      });

      await Promise.all(sendPromises);
      return null;
    } catch (error) {
      console.error('Error in onNewComment:', error);
      return null;
    }
  });

/**
 * Send notification when a teacher responds to a student's feedback/question
 */
exports.onTeacherFeedbackResponse = functions.firestore
  .document('feedback/{feedbackId}/responses/{responseId}')
  .onCreate(async (snapshot, context) => {
    const responseData = snapshot.data();
    const feedbackId = context.params.feedbackId;
    
    try {
      // Get the feedback details
      const feedbackSnapshot = await db.collection('feedback').doc(feedbackId).get();
      const feedback = feedbackSnapshot.data();
      
      if (!feedback) {
        console.log('Feedback not found:', feedbackId);
        return null;
      }
      
      // Get the student who submitted the feedback
      const studentId = feedback.studentId;
      const studentSnapshot = await db.collection('users').doc(studentId).get();
      const student = studentSnapshot.data();
      
      if (!student || !student.fcmTokens) {
        console.log('Student or FCM tokens not found:', studentId);
        return null;
      }
      
      // Get the teacher who responded
      const teacherId = responseData.teacherId;
      const teacherSnapshot = await db.collection('users').doc(teacherId).get();
      const teacher = teacherSnapshot.data();
      const teacherName = teacher ? teacher.fullName || 'Giáo viên' : 'Giáo viên';
      
      // Send notification to the student
      const tokens = Object.values(student.fcmTokens).filter(token => token);
      
      if (tokens.length === 0) {
        console.log('No valid FCM tokens found for student:', studentId);
        return null;
      }
      
      const message = {
        notification: {
          title: 'Phản hồi từ giáo viên',
          body: `${teacherName} đã phản hồi thắc mắc của bạn.`
        },
        data: {
          type: 'teacher_response',
          channel_id: 'teacher_response',
          target_id: feedbackId,
          response_id: responseId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        tokens: tokens
      };
      
      const response = await admin.messaging().sendMulticast(message);
      console.log(`Teacher response notification sent to student ${studentId}: ${response.successCount} success, ${response.failureCount} failures`);
      
      return null;
    } catch (error) {
      console.error('Error in onTeacherFeedbackResponse:', error);
      return null;
    }
  });

/**
 * Send notification when a student earns a new badge
 */
exports.onBadgeAwarded = functions.firestore
  .document('users/{userId}/badges/{badgeId}')
  .onCreate(async (snapshot, context) => {
    const badgeData = snapshot.data();
    const userId = context.params.userId;
    const badgeId = context.params.badgeId;
    
    try {
      // Get badge details
      const badgeRefSnapshot = await db.collection('badges').doc(badgeId).get();
      const badge = badgeRefSnapshot.data();
      
      if (!badge) {
        console.log('Badge not found:', badgeId);
        return null;
      }
      
      // Get user details
      const userSnapshot = await db.collection('users').doc(userId).get();
      const user = userSnapshot.data();
      
      if (!user || !user.fcmTokens) {
        console.log('User or FCM tokens not found:', userId);
        return null;
      }
      
      // Send notification to the user
      const tokens = Object.values(user.fcmTokens).filter(token => token);
      
      if (tokens.length === 0) {
        console.log('No valid FCM tokens found for user:', userId);
        return null;
      }
      
      const message = {
        notification: {
          title: 'Huy hiệu mới!',
          body: `Chúc mừng! Bạn vừa nhận được huy hiệu "${badge.name}".`
        },
        data: {
          type: 'badge_award',
          channel_id: 'badge_award',
          target_id: badgeId,
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        tokens: tokens
      };
      
      const response = await admin.messaging().sendMulticast(message);
      console.log(`Badge notification sent to user ${userId}: ${response.successCount} success, ${response.failureCount} failures`);
      
      return null;
    } catch (error) {
      console.error('Error in onBadgeAwarded:', error);
      return null;
    }
  });

/**
 * Update FCM token for a user
 */
exports.updateFcmToken = functions.https.onCall(async (data, context) => {
  // Ensure user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to update FCM token'
    );
  }
  
  const { token } = data;
  const userId = context.auth.uid;
  
  if (!token) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'FCM token must be provided'
    );
  }
  
  try {
    // Generate a unique key for this token
    const tokenKey = admin.firestore.Timestamp.now().toMillis().toString();
    
    // Update user document
    await db.collection('users').doc(userId).update({
      [`fcmTokens.${tokenKey}`]: token,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error updating FCM token:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update FCM token',
      error
    );
  }
});