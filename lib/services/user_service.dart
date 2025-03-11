import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) {
        return null;
      }
      return User.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Future<List<User>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final snapshots = await Future.wait(
        userIds.map((id) => _db.collection('users').doc(id).get())
      );

      return snapshots
          .where((doc) => doc.exists)
          .map((doc) => User.fromMap(doc.data()!, doc.id))
          .toList();
    } catch (e) {
      print('Error getting users: $e');
      rethrow;
    }
  }
}