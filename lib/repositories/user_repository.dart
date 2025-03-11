import 'package:base_flutter_framework/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';

class UserRepository extends BaseRepository<User> {
  UserRepository() : super('users');

  @override
  Future<String> add(Map<String, dynamic> data) async {
    final docRef = await collection.add(data);
    return docRef.id;
  }

  @override
  Future<User?> getById(String id) async {
    final doc = await collection.doc(id).get();
    if (!doc.exists) return null;

    return User.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  @override
  Future<List<User>> getAll() async {
    final querySnapshot = await collection.get();
    return querySnapshot.docs.map((doc) {
      return User.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  @override
  Future<List<User>> query(
      Query Function(CollectionReference) queryBuilder) async {
    final querySnapshot = await queryBuilder(collection).get();
    return querySnapshot.docs.map((doc) {
      return User.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    await collection.doc(id).update(data);
  }

  @override
  Future<void> delete(String id) async {
    await collection.doc(id).delete();
  }

  // Additional methods specific to User
  Future<User?> getUserByEmail(String email) async {
    final querySnapshot =
        await collection.where('email', isEqualTo: email).limit(1).get();
    if (querySnapshot.docs.isEmpty) return null;

    final doc = querySnapshot.docs.first;
    return User.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
