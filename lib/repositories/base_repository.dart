import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseRepository<T> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath;

  BaseRepository(this.collectionPath);

  CollectionReference get collection => _firestore.collection(collectionPath);

  // Create
  Future<String> add(Map<String, dynamic> data);

  // Read
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<List<T>> query(Query Function(CollectionReference) queryBuilder);

  // Update
  Future<void> update(String id, Map<String, dynamic> data);

  // Delete
  Future<void> delete(String id);
} 