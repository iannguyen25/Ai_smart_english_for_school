import 'package:base_flutter_framework/models/content_approval.dart';
import 'package:base_flutter_framework/models/quiz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lesson.dart';
import '../models/flashcard.dart';
import '../models/flashcard_item.dart';
import '../models/exercise.dart';
import '../models/video.dart';
import 'lesson_service.dart';
import 'flashcard_service.dart';
import 'exercise_service.dart';
import 'video_service.dart';

class SampleContentService {
  static final SampleContentService _instance = SampleContentService._internal();
  factory SampleContentService() => _instance;
  SampleContentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LessonService _lessonService = LessonService();
  final FlashcardService _flashcardService = FlashcardService();
  final ExerciseService _exerciseService = ExerciseService();
  final VideoService _videoService = VideoService();

  // Collection reference
  CollectionReference get _sampleContentCollection => _firestore.collection('sample_content');

  // Create a new sample lesson
  Future<String?> createSampleLesson({
    required String title,
    required String description,
    required String courseId,
    List<LessonFolder>? folders,
    List<VideoItem>? videos,
    List<Map<String, dynamic>>? flashcards,
    List<Map<String, dynamic>>? exercises,
  }) async {
    try {
      print('SampleContentService: Bắt đầu tạo bài học mẫu');
      print('Title: $title');
      print('Description: $description');
      print('Course ID: $courseId');

      // First create the lesson
      final lesson = Lesson(
        title: title,
        description: description,
        classroomId: courseId,
        orderIndex: 0,
        estimatedMinutes: 0,
        videos: videos ?? [],
        flashcardIds: [],
        exerciseIds: [],
        folders: folders ?? [],
        approvalStatus: ApprovalStatus.approved,
      );

      print('Tạo lesson object thành công');
      print('Lesson data: ${lesson.toMap()}');

      // Add to lessons collection
      final lessonRef = await _firestore.collection('lessons').add(lesson.toMap());
      final lessonId = lessonRef.id;
      print('Thêm lesson vào Firestore thành công');
      print('Lesson ID: $lessonId');

      // Verify the lesson was created
      final createdLesson = await _firestore.collection('lessons').doc(lessonId).get();
      if (!createdLesson.exists) {
        throw Exception('Không thể tạo lesson trong Firestore');
      }
      print('Xác nhận lesson đã được tạo thành công');

      // Add to sample_content collection
      await _firestore.collection('sample_content').doc(lessonId).set({
        'title': title,
        'description': description,
        'courseId': courseId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      print('Thêm vào collection sample_content thành công');

      // Create flashcards if provided
      if (flashcards != null && flashcards.isNotEmpty) {
        print('Bắt đầu tạo flashcards');
        for (var flashcard in flashcards) {
          final flashcardId = await createSampleFlashcard(
            lessonId,
            courseId,
            flashcard['title'],
            flashcard['description'],
            List<Map<String, String>>.from(flashcard['items']),
          );
          print('Tạo flashcard thành công: $flashcardId');
        }
      }

      // Create exercises if provided
      if (exercises != null && exercises.isNotEmpty) {
        print('Bắt đầu tạo exercises');
        for (var exercise in exercises) {
          final exerciseId = await createSampleExercise(
            lessonId,
            courseId,
            exercise['title'],
            exercise['description'],
            List<Question>.from(exercise['questions']),
          );
          print('Tạo exercise thành công: $exerciseId');
        }
      }

      print('Hoàn thành tạo bài học mẫu');
      return lessonId;
    } catch (e) {
      print('Lỗi trong SampleContentService.createSampleLesson:');
      print(e.toString());
      rethrow;
    }
  }

  // Get all sample content
  Future<List<Map<String, dynamic>>> getAllSampleContent() async {
    try {
      final snapshot = await _sampleContentCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting sample content: $e');
      throw Exception('Không thể lấy danh sách tài liệu mẫu: $e');
    }
  }

  // Get sample content by course
  Future<List<Map<String, dynamic>>> getSampleContentByCourse(String courseId) async {
    try {
      final snapshot = await _sampleContentCollection
          .where('courseId', isEqualTo: courseId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting sample content by course: $e');
      throw Exception('Không thể lấy danh sách tài liệu mẫu của khóa học: $e');
    }
  }

  // Deactivate sample content
  Future<void> deactivateSampleContent(String lessonId) async {
    try {
      await _firestore.collection('lessons').doc(lessonId).update({
        'isSample': false,
      });
    } catch (e) {
      print('Error deactivating sample content: $e');
      rethrow;
    }
  }

  // Create a sample flashcard
  Future<String?> createSampleFlashcard(
    String lessonId,
    String classroomId,
    String title,
    String description,
    List<Map<String, String>> items,
  ) async {
    try {
      print('Bắt đầu tạo flashcard mẫu');
      print('Title: $title');
      print('Description: $description');
      print('Lesson ID: $lessonId');
      print('Classroom ID: $classroomId');
      print('Items: $items');

      // Create new flashcard
      final newFlashcard = Flashcard(
        title: title,
        description: description,
        userId: 'system',
        lessonId: lessonId,
        classroomId: classroomId,
        isPublic: true,
        approvalStatus: ApprovalStatus.approved,
      );

      print('Tạo flashcard object thành công');
      print('Flashcard data: ${newFlashcard.toMap()}');

      // Create flashcard in Firestore
      final flashcardId = await _flashcardService.createFlashcard(newFlashcard);
      print('Tạo flashcard trong Firestore thành công');
      print('Flashcard ID: $flashcardId');

      if (flashcardId != null) {
        // Create flashcard items
        for (var item in items) {
          if (item['question']?.isNotEmpty == true && item['answer']?.isNotEmpty == true) {
            final flashcardItem = FlashcardItem(
              flashcardId: flashcardId,
              question: item['question']!,
              answer: item['answer']!,
              type: FlashcardItemType.textToText,
            );
            await _flashcardService.createFlashcardItem(flashcardItem);
            print('Tạo flashcard item thành công: ${flashcardItem.toMap()}');
          }
        }

        // Update lesson with new flashcard ID
        await _firestore.collection('lessons').doc(lessonId).update({
          'flashcardIds': FieldValue.arrayUnion([flashcardId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Cập nhật lesson với flashcard ID thành công');

        return flashcardId;
      }

      return null;
    } catch (e) {
      print('Lỗi khi tạo flashcard mẫu:');
      print(e.toString());
      rethrow;
    }
  }

  // Create a sample exercise
  Future<String?> createSampleExercise(
    String lessonId,
    String classroomId,
    String title,
    String description,
    List<Question> questions,
  ) async {
    try {
      final newExercise = Exercise(
        title: title,
        description: description,
        lessonId: lessonId,
        classroomId: classroomId,
        questions: questions,
        difficultyMatrix: const DifficultyMatrix(),
        timeLimit: 300,
        attemptsAllowed: 3,
        createdBy: 'system',
      );
      final exercise = await _exerciseService.createExercise(
        title: newExercise.title,
        description: newExercise.description,
        lessonId: newExercise.lessonId,
        classroomId: newExercise.classroomId,
        questions: newExercise.questions,
        difficultyMatrix: newExercise.difficultyMatrix,
        timeLimit: newExercise.timeLimit,
        attemptsAllowed: newExercise.attemptsAllowed,
        visibility: newExercise.visibility,
        createdBy: newExercise.createdBy,
      );
      return exercise.id;
    } catch (e) {
      print('Error creating sample exercise: $e');
      return null;
    }
  }

  // Add video to an existing lesson
  Future<void> addVideoToLesson(String lessonId, VideoItem video) async {
    try {
      print('Bắt đầu thêm video vào lesson: $lessonId');
      print('Video data: ${video.toMap()}');

      // Get current lesson
      final lessonDoc = await _firestore.collection('lessons').doc(lessonId).get();
      if (!lessonDoc.exists) {
        throw Exception('Lesson không tồn tại');
      }

      final lessonData = lessonDoc.data() as Map<String, dynamic>;
      final currentVideos = List<Map<String, dynamic>>.from(lessonData['videoItems'] ?? []);

      // Add new video
      currentVideos.add(video.toMap());

      // Update lesson with new video
      await _firestore.collection('lessons').doc(lessonId).update({
        'videoItems': currentVideos,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Thêm video thành công');
    } catch (e) {
      print('Lỗi khi thêm video: $e');
      rethrow;
    }
  }

  // Remove video from lesson
  Future<void> removeVideoFromLesson(String lessonId, int videoIndex) async {
    try {
      print('Bắt đầu xóa video khỏi lesson: $lessonId');
      print('Video index: $videoIndex');

      // Get current lesson
      final lessonDoc = await _firestore.collection('lessons').doc(lessonId).get();
      if (!lessonDoc.exists) {
        throw Exception('Lesson không tồn tại');
      }

      final lessonData = lessonDoc.data() as Map<String, dynamic>;
      final currentVideos = List<Map<String, dynamic>>.from(lessonData['videoItems'] ?? []);

      if (videoIndex >= 0 && videoIndex < currentVideos.length) {
        currentVideos.removeAt(videoIndex);

        // Update lesson with remaining videos
        await _firestore.collection('lessons').doc(lessonId).update({
          'videoItems': currentVideos,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('Xóa video thành công');
      } else {
        throw Exception('Video index không hợp lệ');
      }
    } catch (e) {
      print('Lỗi khi xóa video: $e');
      rethrow;
    }
  }
} 