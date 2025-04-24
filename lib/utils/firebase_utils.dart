import 'package:cloud_firestore/cloud_firestore.dart';

String generateId() {
  return FirebaseFirestore.instance.collection('temp').doc().id;
}

String generateInviteCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = DateTime.now().millisecondsSinceEpoch;
  final result = StringBuffer();
  
  for (var i = 0; i < 6; i++) {
    result.write(chars[random % chars.length]);
  }
  
  return result.toString();
}

extension FirestoreX on FirebaseFirestore {
  CollectionReference get users => collection('users');
  CollectionReference get classrooms => collection('classrooms');
  CollectionReference get notifications => collection('notifications');
}

extension TimestampX on Timestamp {
  DateTime toDateTime() => toDate();
}

extension DateTimeX on DateTime {
  Timestamp toTimestamp() => Timestamp.fromDate(this);
} 