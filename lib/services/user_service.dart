import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<User?> getUserById(String userId) async {
    try {
      print('Getting user data for ID: $userId');
      final doc = await _db.collection('users').doc(userId).get();
      print('User document exists: ${doc.exists}');
      
      if (!doc.exists) {
        print('User document not found');
        return null;
      }

      final data = doc.data()!;
      return User.fromMap(data, doc.id);
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