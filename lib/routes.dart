import 'package:base_flutter_framework/screens/admin/admin_dashboard_screen.dart';
import 'package:base_flutter_framework/screens/admin/user_management_screen.dart';
import 'package:base_flutter_framework/screens/admin/create_edit_course_screen.dart';
import 'package:flutter/material.dart';

import 'screens/materials/teacher_materials_screen.dart';
import 'screens/materials/student_materials_screen.dart';
import 'screens/notifications/notification_history_screen.dart';
import 'screens/flashcards/create_edit_flashcard_screen.dart';
import 'screens/materials/upload_material_screen.dart';
import 'screens/materials/create_video_screen.dart';
import 'screens/exercises/create_exercise_screen.dart';

class Routes {
  static Map<String, WidgetBuilder> routes = {
    '/user_management': (context) => const UserManagementScreen(),
    '/course_management': (context) => const CreateEditCourseScreen(),
    
    // Màn hình quản lý tài liệu
    '/teacher_materials': (context) => const TeacherMaterialsScreen(),
    '/student_materials': (context) => const StudentMaterialsScreen(),
    
    // Màn hình thông báo
    '/notifications': (context) => const NotificationHistoryScreen(),

    // Màn hình dashboard
    'dashboard': (context) => const AdminDashboardScreen(),
    
    // Thêm mới tài liệu học tập
    '/materials/videos/create': (context) => const CreateVideoScreen(),
    '/flashcards/create': (context) => const CreateEditFlashcardScreen(),
    '/materials/upload': (context) => const UploadMaterialScreen(),
    '/exercises/create': (context) => const CreateExerciseScreen(),
  };
} 