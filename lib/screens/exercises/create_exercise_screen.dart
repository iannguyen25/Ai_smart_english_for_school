import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class CreateExerciseScreen extends StatefulWidget {
  final String? initialTitle;
  final String? initialDescription;
  final String? lessonId;
  final String? classroomId;

  const CreateExerciseScreen({
    Key? key,
    this.initialTitle,
    this.initialDescription,
    this.lessonId,
    this.classroomId,
  }) : super(key: key);
  @override
  _CreateExerciseScreenState createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '15'); // Default 15 minutes
  
  bool _isLoading = false;
  
  // Questions list
  List<Map<String, dynamic>> _questions = [
    {
      'questionText': '',
      'options': ['', '', '', ''],
      'correctOptionIndex': 0,
      'explanation': '',
    }
  ];
  
  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _descriptionController.text = widget.initialDescription ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        'questionText': '',
        'options': ['', '', '', ''],
        'correctOptionIndex': 0,
        'explanation': '',
      });
    });
  }
  
  void _removeQuestion(int index) {
    if (_questions.length > 1) {
      setState(() {
        _questions.removeAt(index);
      });
    } else {
      Get.snackbar(
        'Thông báo',
        'Bài tập phải có ít nhất một câu hỏi',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  void _updateQuestionText(int questionIndex, String value) {
    setState(() {
      _questions[questionIndex]['questionText'] = value;
    });
  }
  
  void _updateOption(int questionIndex, int optionIndex, String value) {
    setState(() {
      _questions[questionIndex]['options'][optionIndex] = value;
    });
  }
  
  void _updateCorrectOption(int questionIndex, int optionIndex) {
    setState(() {
      _questions[questionIndex]['correctOptionIndex'] = optionIndex;
    });
  }
  
  void _updateExplanation(int questionIndex, String value) {
    setState(() {
      _questions[questionIndex]['explanation'] = value;
    });
  }
  
  void _addOption(int questionIndex) {
    final options = _questions[questionIndex]['options'] as List<dynamic>;
    if (options.length < 6) {  // Limit to 6 options
      setState(() {
        options.add('');
      });
    } else {
      Get.snackbar(
        'Thông báo',
        'Tối đa 6 lựa chọn cho mỗi câu hỏi',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  void _removeOption(int questionIndex) {
    final options = _questions[questionIndex]['options'] as List<dynamic>;
    final correctOptionIndex = _questions[questionIndex]['correctOptionIndex'] as int;
    
    if (options.length > 2) {  // Minimum 2 options
      setState(() {
        if (correctOptionIndex == options.length - 1) {
          // If the correct option is the last one, update it
          _questions[questionIndex]['correctOptionIndex'] = correctOptionIndex - 1;
        }
        options.removeLast();
      });
    } else {
      Get.snackbar(
        'Thông báo',
        'Mỗi câu hỏi phải có ít nhất 2 lựa chọn',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validate questions
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final questionText = question['questionText'] as String;
      final options = question['options'] as List<dynamic>;
      
      if (questionText.trim().isEmpty) {
        Get.snackbar(
          'Lỗi',
          'Câu hỏi ${i + 1} không được để trống',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      for (int j = 0; j < options.length; j++) {
        if (options[j].toString().trim().isEmpty) {
          Get.snackbar(
            'Lỗi',
            'Lựa chọn ${j + 1} của câu hỏi ${i + 1} không được để trống',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'Bạn chưa đăng nhập';
      }
      
      final int duration = int.tryParse(_durationController.text) ?? 15;

      // Tạo bài tập mới
      final exerciseRef = await FirebaseFirestore.instance.collection('exercises').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'authorId': currentUser.uid,
        'lessonId': widget.lessonId,
        'classroomId': widget.classroomId,
        'questionCount': _questions.length,
        'duration': duration, // Duration in minutes
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Thêm các câu hỏi
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        await FirebaseFirestore.instance.collection('exercise_questions').add({
          'exerciseId': exerciseRef.id,
          'questionText': question['questionText'],
          'options': question['options'],
          'correctOptionIndex': question['correctOptionIndex'],
          'explanation': question['explanation'] ?? '',
          'orderIndex': i,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Cập nhật bài học nếu có
      if (widget.lessonId != null) {
        final lessonDoc = await FirebaseFirestore.instance
            .collection('lessons')
            .doc(widget.lessonId)
            .get();
        
        if (lessonDoc.exists) {
          final List<dynamic> exerciseIds = lessonDoc.data()?['exerciseIds'] ?? [];
          exerciseIds.add(exerciseRef.id);
          
          await FirebaseFirestore.instance
              .collection('lessons')
              .doc(widget.lessonId)
              .update({
            'exerciseIds': exerciseIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      Get.back();
      Get.snackbar(
        'Thành công',
        'Đã tạo bài tập mới',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tạo bài tập: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bài tập'),
        backgroundColor: Colors.green.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveExercise,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic information
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thông tin bài tập',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Tiêu đề bài tập',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập tiêu đề bài tập';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Mô tả bài tập',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _durationController,
                              decoration: const InputDecoration(
                                labelText: 'Thời gian làm bài (phút)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập thời gian làm bài';
                                }
                                final duration = int.tryParse(value);
                                if (duration == null || duration <= 0) {
                                  return 'Thời gian phải là số dương';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Questions section
                    const Text(
                      'Danh sách câu hỏi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // List of questions
                    ...List.generate(_questions.length, (index) {
                      return _buildQuestionCard(index);
                    }),
                    
                    // Add question button
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _addQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm câu hỏi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildQuestionCard(int questionIndex) {
    final question = _questions[questionIndex];
    final options = question['options'] as List<dynamic>;
    final correctOptionIndex = question['correctOptionIndex'] as int;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header with number and remove button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Câu hỏi ${questionIndex + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeQuestion(questionIndex),
                  tooltip: 'Xóa câu hỏi',
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Question text
            TextFormField(
              initialValue: question['questionText'],
              decoration: const InputDecoration(
                labelText: 'Nội dung câu hỏi',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => _updateQuestionText(questionIndex, value),
            ),
            const SizedBox(height: 16),
            
            // Options
            const Text(
              'Các lựa chọn:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            ...List.generate(options.length, (optionIndex) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: optionIndex,
                      groupValue: correctOptionIndex,
                      onChanged: (value) {
                        if (value != null) {
                          _updateCorrectOption(questionIndex, value);
                        }
                      },
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: options[optionIndex].toString(),
                        decoration: InputDecoration(
                          labelText: 'Lựa chọn ${optionIndex + 1}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => _updateOption(questionIndex, optionIndex, value),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            // Add/remove option buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _addOption(questionIndex),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm lựa chọn'),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _removeOption(questionIndex),
                  icon: const Icon(Icons.remove),
                  label: const Text('Bớt lựa chọn'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
            
            // Explanation
            const SizedBox(height: 16),
            TextFormField(
              initialValue: question['explanation'] ?? '',
              decoration: const InputDecoration(
                labelText: 'Giải thích đáp án (tùy chọn)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (value) => _updateExplanation(questionIndex, value),
            ),
          ],
        ),
      ),
    );
  }
}
