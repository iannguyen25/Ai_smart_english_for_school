import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/input_validator.dart';
import 'base_model.dart';

class User extends BaseModel {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String? roleId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudiedDate;
  final List<String> badges;

  User({
    String? id,
    this.email,
    this.firstName,
    this.lastName,
    this.avatar,
    this.roleId,
    this.createdAt,
    this.updatedAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStudiedDate,
    this.badges = const [],
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      email: map['email'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      avatar: map['avatar'],
      roleId: map['roleId'] ?? '',
      createdAt: map['createdAt'] as Timestamp,
      updatedAt: map['updatedAt'] as Timestamp,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastStudiedDate: map['lastStudiedDate'] != null 
          ? (map['lastStudiedDate'] as Timestamp).toDate() 
          : null,
      badges: List<String>.from(map['badges'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'avatar': avatar,
      'roleId': roleId,
      'createdAt': Timestamp.fromDate(createdAt?.toDate() ?? DateTime.now()),
      'updatedAt': Timestamp.fromDate(updatedAt?.toDate() ?? DateTime.now()),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudiedDate': lastStudiedDate != null 
          ? Timestamp.fromDate(lastStudiedDate!) 
          : null,
      'badges': badges,
    };
  }

  String get fullName => '$firstName $lastName';

  @override
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? avatar,
    String? roleId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStudiedDate,
    List<String>? badges,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStudiedDate: lastStudiedDate ?? this.lastStudiedDate,
      badges: badges ?? this.badges,
    );
  }
  
  // Phương thức tĩnh để lấy tất cả người dùng từ Firestore
  static Future<List<User>> getAllUsers() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();
          
      return snapshot.docs.map((doc) {
        return User.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }
  
  // Phương thức tĩnh để xóa người dùng
  static Future<bool> deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }

  // Thêm phương thức validate
  static Map<String, String?> validate({
    String? email,
    String? firstName,
    String? lastName,
  }) {
    Map<String, String?> errors = {};
    
    final emailError = InputValidator.validateEmail(email);
    if (emailError != null) {
      errors['email'] = emailError;
    }

    final firstNameError = InputValidator.validateName(firstName);
    if (firstNameError != null) {
      errors['firstName'] = firstNameError;
    }

    final lastNameError = InputValidator.validateName(lastName);
    if (lastNameError != null) {
      errors['lastName'] = lastNameError;
    }

    return errors;
  }

  // Validate instance hiện tại
  Map<String, String?> validateInstance() {
    return validate(
      email: email,
      firstName: firstName,
      lastName: lastName,
    );
  }

  // Cập nhật phương thức tạo user để thêm validation
  static Future<User?> createUser({
    required String email,
    required String firstName,
    required String lastName,
    String? avatar,
    String? roleId,
  }) async {
    // Validate input
    final errors = validate(
      email: email,
      firstName: firstName,
      lastName: lastName,
    );

    if (errors.isNotEmpty) {
      print('Validation errors: $errors');
      return null;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').add({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'avatar': avatar,
        'roleId': roleId,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'currentStreak': 0,
        'longestStreak': 0,
        'lastStudiedDate': null,
        'badges': [],
      });

      final userData = await userDoc.get();
      return User.fromMap(userData.data() as Map<String, dynamic>, userData.id);
    } catch (e) {
      print('Error creating user: $e');
      return null;
    }
  }
}
