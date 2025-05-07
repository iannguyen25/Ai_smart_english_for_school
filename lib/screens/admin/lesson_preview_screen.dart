import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/lesson_service.dart';
import '../../models/lesson.dart';

class LessonPreviewScreen extends StatefulWidget {
  final String lessonId;

  const LessonPreviewScreen({
    Key? key,
    required this.lessonId,
  }) : super(key: key);

  @override
  _LessonPreviewScreenState createState() => _LessonPreviewScreenState();
}

class _LessonPreviewScreenState extends State<LessonPreviewScreen> {
  final LessonService _lessonService = LessonService();
  bool _isLoading = true;
  Lesson? _lesson;

  @override
  void initState() {
    super.initState();
    _loadLessonData();
  }

  Future<void> _loadLessonData() async {
    try {
      final lesson = await _lessonService.getLessonById(widget.lessonId);
      setState(() {
        _lesson = lesson;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading lesson data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xem trước bài học'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _lesson == null
              ? Center(
                  child: Text(
                    'Không tìm thấy bài học',
                    style: TextStyle(color: Colors.black87),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề
                      Text(
                        _lesson!.title,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Thông tin tác giả
                      if (_lesson!.classroomId != null) ...[
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('classrooms')
                              .doc(_lesson!.classroomId)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final classroomData = snapshot.data!.data() as Map<String, dynamic>;
                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(classroomData['teacherId'])
                                    .get(),
                                builder: (context, teacherSnapshot) {
                                  if (teacherSnapshot.hasData && teacherSnapshot.data!.exists) {
                                    final teacherData = teacherSnapshot.data!.data() as Map<String, dynamic>;
                                    return Text(
                                      'Tác giả: ${teacherData['firstName']} ${teacherData['lastName']}',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 16,
                                      ),
                                    );
                                  }
                                  return SizedBox();
                                },
                              );
                            }
                            return SizedBox();
                          },
                        ),
                        SizedBox(height: 16),
                      ],

                      // Mô tả
                      if (_lesson!.description.isNotEmpty) ...[
                        Text(
                          'Mô tả:',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _lesson!.description,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 24),
                      ],

                      // Nội dung bài học
                      Text(
                        'Nội dung:',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          _lesson!.description,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
} 