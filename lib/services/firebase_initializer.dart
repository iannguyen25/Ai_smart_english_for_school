import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'role_service.dart';

class FirebaseInitializer {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Set up error handling for Firebase Auth
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          print('User is authenticated: ${user.uid}');
        } else {
          print('User is not authenticated');
        }
      }, onError: (error) {
        print('Firebase Auth error: $error');
      });

      print('Firebase initialized successfully');
      
      // Initialize default roles
      await _initializeDefaultData();
    } catch (e) {
      print('Error initializing Firebase: $e');
      if (kDebugMode) {
        // Rethrow in debug mode for easier debugging
        rethrow;
      }
    }
  }

  static Future<void> _initializeDefaultData() async {
    try {
      // Initialize roles
      final roleService = RoleService();
      await roleService.initializeDefaultRoles();
      print('Default data initialized');
    } catch (e) {
      print('Error initializing default data: $e');
      // Continue execution even if this fails
    }
  }

  static Future<void> handleFirebaseError(Object error, StackTrace stackTrace) async {
    print('Firebase error: $error');
    print('Stack trace: $stackTrace');
    
    // You can implement more sophisticated error handling here
    // Like reporting to a monitoring service or showing a specific UI
  }
} 