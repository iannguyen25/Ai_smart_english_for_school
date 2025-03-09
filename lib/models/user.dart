import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_model.dart';

class User extends BaseModel {
  final String? email;
  final String?
      password; // Note: We usually don't store passwords in model objects for security
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String? roleId;

  User({
    String? id,
    this.email,
    this.password,
    this.firstName,
    this.lastName,
    this.avatar,
    this.roleId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
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
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
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
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String get fullName => '$firstName $lastName';

  @override
  User copyWith({
    String? id,
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    String? avatar,
    String? roleId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
