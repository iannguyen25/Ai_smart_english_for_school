import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import 'dart:io';

class CourseService {
  // Singleton pattern
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;
  CourseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  // Collection reference
  CollectionReference get _coursesCollection => _firestore.collection('courses');

  // Get all courses
  Future<List<Course>> getAllCourses() async {
    try {
      final snapshot = await _coursesCollection
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => Course.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting courses: $e');
      throw Exception('Không thể tải danh sách khóa học: $e');
    }
  }

  // Get course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      final doc = await _coursesCollection.doc(courseId).get();
      if (!doc.exists) return null;
      
      return Course.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error getting course: $e');
      return null;
    }
  }

  // Create new course
  Future<String?> createCourse({
    required String name,
    required String description,
    required GradeLevel gradeLevel,
    File? imageFile,
    bool isTextbook = false,
    String textbookName = '',
    String publisher = '',
    bool isPublished = false,
  }) async {
    try {
      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.uploadFile(imageFile, 'courses/images');
      }

      // Create course document
      final docRef = await _coursesCollection.add({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'gradeLevel': _gradeLevelToString(gradeLevel),
        'isTextbook': isTextbook,
        'textbookName': textbookName,
        'publisher': publisher,
        'materialIds': [],
        'questionSetIds': [],
        'templateFlashcardIds': [],
        'createdBy': _authService.currentUser!.id,
        'isPublished': isPublished,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return docRef.id;
    } catch (e) {
      print('Error creating course: $e');
      return null;
    }
  }

  // Update existing course
  Future<bool> updateCourse({
    required String courseId,
    required String name,
    required String description,
    required GradeLevel gradeLevel,
    File? imageFile,
    bool isTextbook = false,
    String textbookName = '',
    String publisher = '',
    bool isPublished = false,
  }) async {
    try {
      // Upload new image if provided
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.uploadFile(imageFile, 'courses/images');
      }

      // Update course document
      final updateData = {
        'name': name,
        'description': description,
        'gradeLevel': _gradeLevelToString(gradeLevel),
        'isTextbook': isTextbook,
        'textbookName': textbookName,
        'publisher': publisher,
        'isPublished': isPublished,
        'updatedAt': Timestamp.now(),
      };

      // Only include imageUrl if a new image was uploaded
      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      }

      await _coursesCollection.doc(courseId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating course: $e');
      return false;
    }
  }

  // Delete course
  Future<bool> deleteCourse(String courseId) async {
    try {
      await _coursesCollection.doc(courseId).delete();
      return true;
    } catch (e) {
      print('Error deleting course: $e');
      return false;
    }
  }

  // Add material to course
  Future<bool> addMaterial(String courseId, String materialId) async {
    try {
      await _coursesCollection.doc(courseId).update({
        'materialIds': FieldValue.arrayUnion([materialId]),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error adding material to course: $e');
      return false;
    }
  }

  // Remove material from course
  Future<bool> removeMaterial(String courseId, String materialId) async {
    try {
      await _coursesCollection.doc(courseId).update({
        'materialIds': FieldValue.arrayRemove([materialId]),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error removing material from course: $e');
      return false;
    }
  }

  // Helper method to convert GradeLevel to string
  String _gradeLevelToString(GradeLevel level) {
    return level.toString().split('.').last;
  }
} 