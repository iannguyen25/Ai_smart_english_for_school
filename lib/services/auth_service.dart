import 'package:base_flutter_framework/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart' as app_models;
import '../repositories/user_repository.dart';
import '../utils/firebase_user_handler.dart';
import 'dart:async';

class AuthResult {
  final bool success;
  final String? error;
  final app_models.User? user;

  AuthResult({required this.success, this.error, this.user});
}

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Thêm stream để lắng nghe thay đổi của currentUser
  final _currentUserController = StreamController<User?>.broadcast();
  Stream<User?> get currentUserStream => _currentUserController.stream;

  // Khởi tạo currentUser từ Firebase Auth
  Future<void> initCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    print('Init Current User - Firebase User: $firebaseUser'); // Debug log

    if (firebaseUser != null) {
      try {
        final doc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();
        print('Init Current User - User Document: ${doc.data()}'); // Debug log

        if (doc.exists) {
          _currentUser = User.fromMap(doc.data()!, doc.id);
          _currentUserController.add(_currentUser); // Thông báo thay đổi
          print(
              'Init Current User - Current User set to: $_currentUser'); // Debug log
        }
      } catch (e) {
        print('Error initializing current user: $e');
        _currentUser = null;
        _currentUserController.add(null);
      }
    } else {
      print('No Firebase user logged in');
      _currentUser = null;
      _currentUserController.add(null);
    }
  }

  // Lắng nghe thay đổi của Firebase Auth
  void _setupAuthStateListener() {
    _auth.authStateChanges().listen((firebaseUser) async {
      print('Auth State Changed - Firebase User: $firebaseUser'); // Debug log

      if (firebaseUser != null) {
        try {
          final doc =
              await _firestore.collection('users').doc(firebaseUser.uid).get();
          if (doc.exists) {
            _currentUser = User.fromMap(doc.data()!, doc.id);
            _currentUserController.add(_currentUser);
            print(
                'Auth State Changed - Current User set to: $_currentUser'); // Debug log
          }
        } catch (e) {
          print('Error updating current user: $e');
          _currentUser = null;
          _currentUserController.add(null);
        }
      } else {
        _currentUser = null;
        _currentUserController.add(null);
      }
    });
  }

  // Constructor để setup auth state listener
  AuthService.internal() {
    _setupAuthStateListener();
  }

  // Dispose để cleanup
  void dispose() {
    _currentUserController.close();
  }

  // Get the current signed-in user
  app_models.User? get currentAppUser {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;

      // Just return a basic user object with the uid and email
      // For the full profile, use getCurrentUserProfile()
      return app_models.User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        firstName: '',
        lastName: '',
        roleId: '',
        createdAt: Timestamp.fromDate(DateTime.now()),
        updatedAt: Timestamp.fromDate(DateTime.now()),
      );
    } catch (e) {
      print('Error in currentUser getter: $e');
      return null;
    }
  }

  // Get full user profile from Firestore
  Future<app_models.User?> getCurrentUserProfile() async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;

      final userDoc =
          await FirebaseUserHandler.getUserDocument(firebaseUser.uid);
      if (userDoc == null || !userDoc.exists) return null;

      return FirebaseUserHandler.convertToAppUser(
          firebaseUser, userDoc.data() as Map<String, dynamic>?);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Stream of auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

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
      final userCredential =
          await FirebaseUserHandler.createUserWithEmailAndPassword(
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
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // Không tự động đăng nhập sau khi tạo tài khoản
      // _currentUser = user;
      return AuthResult(success: true, user: user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Exception during registration: ${e.code} - ${e.message}');
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      print('Registration error: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Sign in with email and password
  Future<AuthResult> login({
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
        
        // Check if user is active
        if (userData['isActive'] == false) {
          return AuthResult(
            success: false,
            error: 'Tài khoản của bạn đã bị khóa. Vui lòng liên hệ quản trị viên.',
          );
        }

        final user = FirebaseUserHandler.convertToAppUser(userCredential.user, userData);
        _currentUser = user;
        return AuthResult(success: true, user: user);
      } catch (e) {
        print('Error fetching user data after login: $e');
        return AuthResult(success: false, error: 'Không thể tải thông tin người dùng');
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
      await _auth.signOut();
      _currentUser = null;
      clearUserCache();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(success: true);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Exception during password reset: ${e.code} - ${e.message}');
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
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (firstName != null) updates['firstName'] = firstName;
      if (lastName != null) updates['lastName'] = lastName;
      if (avatar != null) updates['avatar'] = avatar;

      await _firestore.collection('users').doc(userId).update(updates);

      // Cập nhật currentUser nếu là user hiện tại
      if (_currentUser?.id == userId) {
        _currentUser = _currentUser?.copyWith(
          firstName: firstName ?? _currentUser?.firstName,
          lastName: lastName ?? _currentUser?.lastName,
          avatar: avatar ?? _currentUser?.avatar,
          updatedAt: Timestamp.fromDate(DateTime.now()),
        );
      }

      clearUserFromCache(userId);
      return AuthResult(success: true, user: _currentUser);
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
      final user = _auth.currentUser;
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
      print(
          'Firebase Auth Exception during password change: ${e.code} - ${e.message}');
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      print('Password change error: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Delete user account
  Future<AuthResult> deleteUserAccount(String password) async {
    try {
      final user = _auth.currentUser;
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
      print(
          'Firebase Auth Exception during account deletion: ${e.code} - ${e.message}');
      return AuthResult(success: false, error: e.message);
    } catch (e) {
      print('Account deletion error: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }

  // Get user by ID
  Future<app_models.User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;

      // Chuyển đổi Timestamp thành DateTime khi đọc từ Firestore
      final createdAt = data['createdAt'] as Timestamp?;
      final updatedAt = data['updatedAt'] as Timestamp?;

      return app_models.User(
        id: doc.id,
        email: data['email'] ?? '',
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        avatar: data['avatar'],
        roleId: data['roleId'] ?? '',
        createdAt: createdAt ?? Timestamp.now(),
        updatedAt: updatedAt ?? Timestamp.now(),
      );
    } catch (e) {
      print('Error getting user by ID: $e');
      throw 'Không thể tải thông tin người dùng';
    }
  }

  // Cache user data to reduce database reads
  final Map<String, app_models.User> _userCache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  final Map<String, DateTime> _cacheTimestamps = {};

  // Get user by ID with caching
  Future<app_models.User?> getUserByIdCached(String userId) async {
    // Check if user is in cache and cache is still valid
    if (_userCache.containsKey(userId)) {
      final cacheTime = _cacheTimestamps[userId];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheDuration) {
        return _userCache[userId];
      }
    }

    // If not in cache or cache expired, fetch from database
    try {
      final user = await getUserById(userId);
      if (user != null) {
        // Update cache
        _userCache[userId] = user;
        _cacheTimestamps[userId] = DateTime.now();
      }
      return user;
    } catch (e) {
      // If error occurs, return cached version if available
      if (_userCache.containsKey(userId)) {
        return _userCache[userId];
      }
      rethrow;
    }
  }

  // Clear user cache
  void clearUserCache() {
    _userCache.clear();
    _cacheTimestamps.clear();
  }

  // Clear specific user from cache
  void clearUserFromCache(String userId) {
    _userCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  // Refresh user data from Firestore
  Future<void> refreshUserData(String userId) async {
    try {
      print('Refreshing user data for ID: $userId');
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        print('User document not found');
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      // Chuyển đổi Timestamp thành DateTime khi đọc từ Firestore
      final createdAt = data['createdAt'] as Timestamp?;
      final updatedAt = data['updatedAt'] as Timestamp?;

      final refreshedUser = app_models.User(
        id: doc.id,
        email: data['email'] ?? '',
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        avatar: data['avatar'],
        roleId: data['roleId'] ?? '',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      // Cập nhật currentUser và thông báo thay đổi
      _currentUser = refreshedUser;
      _currentUserController.add(_currentUser);

      print('User data refreshed successfully: ${_currentUser?.avatar}');
    } catch (e) {
      print('Error refreshing user data: $e');
      rethrow;
    }
  }

  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;
  
  // Kiểm tra xem người dùng hiện tại có phải là quản trị viên hay không
  // Giả sử roleId = 'admin' là quản trị viên
  bool get isCurrentUserAdmin {
    final user = currentUser;
    // Kiểm tra roleId được thiết lập là 'admin'
    final isAdmin = user?.roleId == 'admin';
    return isAdmin;
  }
  
  // Kiểm tra xem người dùng hiện tại có phải là giáo viên không
  // Giả sử roleId = 'teacher' là giáo viên
  bool get isCurrentUserTeacher {
    final user = currentUser;
    // Kiểm tra roleId được thiết lập là 'teacher'
    return user?.roleId == 'teacher';
  }

  // Toggle user active status
  Future<AuthResult> toggleUserActive(String userId, bool isActive) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult(success: false, error: 'No user is signed in');
      }

      // Update user's active status in Firestore
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': Timestamp.now(),
      });

      // If the current user is being deactivated, sign them out
      if (userId == user.uid && !isActive) {
        await signOut();
      }

      return AuthResult(success: true);
    } catch (e) {
      print('Error toggling user active status: $e');
      return AuthResult(success: false, error: e.toString());
    }
  }
}
