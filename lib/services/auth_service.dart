import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_models;
import '../repositories/user_repository.dart';
import '../utils/firebase_user_handler.dart';

class AuthResult {
  final bool success;
  final String? error;
  final app_models.User? user;

  AuthResult({required this.success, this.error, this.user});
}

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserRepository _userRepository = UserRepository();

  // Get the current signed-in user
  app_models.User? get currentUser {
    try {
      final firebaseUser = FirebaseUserHandler.getCurrentFirebaseUser();
      if (firebaseUser == null) return null;

      // Just return a basic user object with the uid and email
      // For the full profile, use getCurrentUserProfile()
      return app_models.User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        firstName: '',
        lastName: '',
        roleId: '',
      );
    } catch (e) {
      print('Error in currentUser getter: $e');
      return null;
    }
  }

  // Get full user profile from Firestore
  Future<app_models.User?> getCurrentUserProfile() async {
    try {
      final firebaseUser = FirebaseUserHandler.getCurrentFirebaseUser();
      if (firebaseUser == null) return null;
      
      final userDoc = await FirebaseUserHandler.getUserDocument(firebaseUser.uid);
      if (userDoc == null || !userDoc.exists) return null;
      
      return FirebaseUserHandler.convertToAppUser(
        firebaseUser, 
        userDoc.data() as Map<String, dynamic>?
      );
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Register a new user
  Future<AuthResult> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String roleId,
  }) async {
    try {
      // Create the user in Firebase Auth with our safe handler
      final userCredential = await FirebaseUserHandler.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential == null || userCredential.user == null) {
        return AuthResult(success: false, error: 'Failed to create user');
      }

      // Create user document in Firestore
      final userData = {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'roleId': roleId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await FirebaseUserHandler.createUserDocument(
        userId: userCredential.user!.uid,
        userData: userData,
      );

      // Create user model
      final user = app_models.User(
        id: userCredential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        roleId: roleId,
      );

      return AuthResult(success: true, user: user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during registration: ${e.code} - ${e.message}');
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      print('Registration error: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with our safe handler
      final userCredential = await FirebaseUserHandler.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential == null || userCredential.user == null) {
        return AuthResult(success: false, error: 'Failed to sign in');
      }

      // Get user data from Firestore
      try {
        final userDoc = await FirebaseUserHandler.getUserDocument(userCredential.user!.uid);
        if (userDoc == null || !userDoc.exists) {
          return AuthResult(success: false, error: 'User data not found');
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final user = FirebaseUserHandler.convertToAppUser(userCredential.user, userData);

        return AuthResult(success: true, user: user);
      } catch (e) {
        print('Error fetching user data after login: $e');
        // Even if we can't get the user data from Firestore, the auth was successful
        // Return a basic user object with the information we have
        return AuthResult(
          success: true,
          user: app_models.User(
            id: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            firstName: '',
            lastName: '',
            roleId: '',
          ),
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during login: ${e.code} - ${e.message}');
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      print('Login error: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return AuthResult(success: true);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during password reset: ${e.code} - ${e.message}');
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      print('Password reset error: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Update user profile
  Future<AuthResult> updateUserProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? avatar,
  }) async {
    try {
      final userData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };
      
      if (firstName != null) userData['firstName'] = firstName;
      if (lastName != null) userData['lastName'] = lastName;
      if (avatar != null) userData['avatar'] = avatar;
      
      await _firestore.collection('users').doc(userId).update(userData);
      
      // Get updated user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return AuthResult(success: false, error: 'User not found');
      }
      
      final user = app_models.User.fromMap(userDoc.data() as Map<String, dynamic>, userId);
      return AuthResult(success: true, user: user);
    } catch (e) {
      print('Update profile error: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }
  
  // Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return AuthResult(success: false, error: 'No user is signed in');
      }
      
      // Re-authenticate user to confirm current password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Change password
      await user.updatePassword(newPassword);
      
      return AuthResult(success: true);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during password change: ${e.code} - ${e.message}');
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      print('Password change error: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }
  
  // Delete user account
  Future<AuthResult> deleteUserAccount(String password) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return AuthResult(success: false, error: 'No user is signed in');
      }
      
      // Re-authenticate user to confirm password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Delete user data from Firestore first
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete user account from Firebase Auth
      await user.delete();
      
      return AuthResult(success: true);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Exception during account deletion: ${e.code} - ${e.message}');
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      print('Account deletion error: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }
} 