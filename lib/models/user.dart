import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  teacher,
  admin
}

class User {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == map['role'],
        orElse: () => UserRole.student,
      ),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (map['lastLoginAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role.toString().split('.').last,
      'isActive': isActive,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  User copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    bool? isActive,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  bool isAdmin() => role == UserRole.admin;
  
  bool isTeacher() => role == UserRole.teacher;
  
  bool isStudent() => role == UserRole.student;
  
  bool canManageUsers() => isAdmin();
  
  bool canManageContent() => isAdmin() || isTeacher();
  
  bool canAccessExercises() => isActive;

  @override
  String toString() => 'User(id: $id, email: $email, displayName: $displayName, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
} 