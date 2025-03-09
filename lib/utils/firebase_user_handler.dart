import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/user.dart' as app_models;

class FirebaseUserHandler {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Safely get current user, handling any potential errors
  static User? getCurrentFirebaseUser() {
    try {
      return _auth.currentUser;
    } catch (e) {
      print('Error getting current Firebase user: $e');
      return null;
    }
  }

  // Safely create a user in Firebase Auth with error handling
  static Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error creating user in Firebase Auth: $e');
      rethrow; // Rethrow to let the calling code handle it appropriately
    }
  }

  // Safely sign in with email and password with error handling
  static Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in with Firebase Auth: $e');
      rethrow; // Rethrow to let the calling code handle it appropriately
    }
  }

  // Create user document in Firestore
  static Future<void> createUserDocument({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set(userData);
    } catch (e) {
      print('Error creating user document in Firestore: $e');
      rethrow;
    }
  }

  // Get user document from Firestore
  static Future<DocumentSnapshot?> getUserDocument(String userId) async {
    try {
      return await _firestore.collection('users').doc(userId).get();
    } catch (e) {
      print('Error getting user document from Firestore: $e');
      return null;
    }
  }

  // Convert Firebase User to App User Model safely
  static app_models.User? convertToAppUser(User? firebaseUser, Map<String, dynamic>? userData) {
    if (firebaseUser == null) return null;
    
    try {
      return app_models.User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        firstName: userData?['firstName'] as String? ?? '',
        lastName: userData?['lastName'] as String? ?? '',
        roleId: userData?['roleId'] as String? ?? '',
        avatar: userData?['avatar'] as String?,
        createdAt: userData?['createdAt'] as Timestamp? ?? Timestamp.now(),
        updatedAt: userData?['updatedAt'] as Timestamp? ?? Timestamp.now(),
      );
    } catch (e) {
      print('Error converting Firebase user to app user: $e');
      
      // Return a basic user with minimal information
      return app_models.User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        firstName: '',
        lastName: '',
        roleId: '',
      );
    }
  }
} 