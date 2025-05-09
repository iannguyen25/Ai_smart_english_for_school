import 'package:base_flutter_framework/models/quiz.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/sample_content_service.dart';
import '../../services/course_service.dart';
import '../../models/lesson.dart';
import '../../models/video.dart';
import '../../models/course.dart';
import '../../screens/admin/sample_content_detail_screen.dart';

class SampleContentManagementScreen extends StatefulWidget {
  const SampleContentManagementScreen({Key? key}) : super(key: key);

  @override
  _SampleContentManagementScreenState createState() => _SampleContentManagementScreenState();
}

class _SampleContentManagementScreenState extends State<SampleContentManagementScreen> {
  final SampleContentService _sampleContentService = SampleContentService();
  final CourseService _courseService = CourseService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _courseIdController = TextEditingController();
  String _selectedCourseId = '';
  List<Course> _courses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _courseService.getAllCourses();
      setState(() => _courses = courses);
    } catch (e) {
      print('Error loading courses: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createSampleLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      print('Bắt đầu tạo bài học mẫu...');
      print('Tiêu đề: ${_titleController.text}');
      print('Mô tả: ${_descriptionController.text}');
      print('Course ID: $_selectedCourseId');

      if (_selectedCourseId.isEmpty) {
        throw Exception('Vui lòng chọn khóa học');
      }

      // Create a sample lesson with basic content
      final lessonId = await _sampleContentService.createSampleLesson(
        title: _titleController.text,
        description: _descriptionController.text,
        courseId: _selectedCourseId,
        folders: [
          LessonFolder(
            title: 'Tài liệu học tập',
            description: 'Các tài liệu cần thiết cho bài học',
            orderIndex: 0,
            items: [
              LessonItem(
                title: 'Tài liệu chính',
                type: LessonItemType.document,
                content: 'Nội dung tài liệu chính của bài học',
              ),
            ],
          ),
        ],
      );

      print('Kết quả tạo bài học mẫu:');
      print('Lesson ID: $lessonId');

      if (lessonId != null) {
        // Verify the lesson exists
        final lessonDoc = await FirebaseFirestore.instance
            .collection('lessons')
            .doc(lessonId)
            .get();
        
        if (!lessonDoc.exists) {
          throw Exception('Không thể tạo lesson trong Firestore');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo bài học mẫu thành công')),
        );
        _titleController.clear();
        _descriptionController.clear();
        _courseIdController.clear();
        setState(() => _selectedCourseId = '');
      } else {
        throw Exception('Không nhận được lessonId');
      }
    } catch (e) {
      print('Lỗi khi tạo bài học mẫu:');
      print(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý tài liệu mẫu'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Tiêu đề bài học',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập tiêu đề';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Mô tả bài học',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mô tả';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedCourseId.isEmpty ? null : _selectedCourseId,
                          decoration: const InputDecoration(
                            labelText: 'Chọn khóa học',
                            border: OutlineInputBorder(),
                          ),
                          items: _courses.map((course) {
                            return DropdownMenuItem<String>(
                              value: course.id,
                              child: Text(course.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCourseId = value ?? '');
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng chọn khóa học';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _createSampleLesson,
                          child: const Text('Tạo bài học mẫu'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Danh sách tài liệu mẫu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sample_content')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Lỗi: ${snapshot.error}');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          
                          return Card(
                            child: ListTile(
                              title: Text(data['title'] ?? 'Không có tiêu đề'),
                              subtitle: Text(data['description'] ?? ''),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SampleContentDetailScreen(
                                      lessonId: doc.id,
                                      courseId: data['courseId'] ?? '',
                                    ),
                                  ),
                                );
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  try {
                                    await _sampleContentService.deactivateSampleContent(doc.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã vô hiệu hóa tài liệu mẫu')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _courseIdController.dispose();
    super.dispose();
  }
} 