import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _rolesCollection;

  RoleService() : _rolesCollection = FirebaseFirestore.instance.collection('roles');

  // Initialize default roles if they don't exist
  Future<void> initializeDefaultRoles() async {
    try {
      // Check if student role exists
      final studentRoleDoc = await _rolesCollection.where('roleName', isEqualTo: 'Student').limit(1).get();
      
      // If student role doesn't exist, create it
      if (studentRoleDoc.docs.isEmpty) {
        await _rolesCollection.add({
          'roleName': 'Student',
          'description': 'Standard user who can access learning materials and track progress',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        print('Created default Student role');
      }
      
      // Check if teacher role exists
      final teacherRoleDoc = await _rolesCollection.where('roleName', isEqualTo: 'Teacher').limit(1).get();
      
      // If teacher role doesn't exist, create it
      if (teacherRoleDoc.docs.isEmpty) {
        await _rolesCollection.add({
          'roleName': 'Teacher',
          'description': 'User who can create and manage classes and content',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        print('Created default Teacher role');
      }
      
      // Check if admin role exists
      final adminRoleDoc = await _rolesCollection.where('roleName', isEqualTo: 'Admin').limit(1).get();
      
      // If admin role doesn't exist, create it
      if (adminRoleDoc.docs.isEmpty) {
        await _rolesCollection.add({
          'roleName': 'Admin',
          'description': 'Administrator with full access to all features',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        print('Created default Admin role');
      }
    } catch (e) {
      print('Error initializing default roles: $e');
    }
  }

  // Get role by ID
  Future<Role?> getRoleById(String roleId) async {
    try {
      final docSnapshot = await _rolesCollection.doc(roleId).get();
      if (!docSnapshot.exists) return null;
      
      return Role.fromMap(docSnapshot.data() as Map<String, dynamic>, docSnapshot.id);
    } catch (e) {
      print('Error getting role by ID: $e');
      return null;
    }
  }

  // Get role by name
  Future<Role?> getRoleByName(String roleName) async {
    try {
      final querySnapshot = await _rolesCollection
          .where('roleName', isEqualTo: roleName)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) return null;
      
      final doc = querySnapshot.docs.first;
      return Role.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error getting role by name: $e');
      return null;
    }
  }

  // Get student role ID
  Future<String?> getStudentRoleId() async {
    try {
      final role = await getRoleByName('Student');
      return role?.id;
    } catch (e) {
      print('Error getting student role ID: $e');
      return null;
    }
  }

  // Get all roles
  Future<List<Role>> getAllRoles() async {
    try {
      final querySnapshot = await _rolesCollection.get();
      return querySnapshot.docs.map((doc) {
        return Role.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      print('Error getting all roles: $e');
      return [];
    }
  }
} 