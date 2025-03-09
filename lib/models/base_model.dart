import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseModel {
  final String? id;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  BaseModel({
    this.id,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) : 
    this.createdAt = createdAt ?? Timestamp.now(),
    this.updatedAt = updatedAt ?? Timestamp.now();

  Map<String, dynamic> toMap();

  BaseModel copyWith({String? id, Timestamp? createdAt, Timestamp? updatedAt});
} 