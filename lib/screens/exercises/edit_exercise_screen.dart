import 'package:base_flutter_framework/models/quiz.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../models/exercise.dart';
import '../../services/exercise_service.dart';
import 'edit_question_screen.dart';

class EditExerciseScreen extends StatefulWidget {
  final Exercise exercise;
  final Function? onSaved;

  const EditExerciseScreen({
    Key? key,
    required this.exercise,
    this.onSaved,
  }) : super(key: key);
  @override
  _EditExerciseScreenState createState() => _EditExerciseScreenState();
}

class _EditExerciseScreenState extends State<EditExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _attemptsController = TextEditingController();
  final ExerciseService _exerciseService = ExerciseService();
  
  bool _isLoading = false;
  bool _isShuffleEnabled = true;
  bool _isVisible = true;
  List<Question> _questions = [];
  Timestamp? _startTime;
  Timestamp? _endTime;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
    print('DEBUG: EditExerciseScreen initialized for exercise ID: ${widget.exercise.id}');
  }

  void _initializeData() {
    try {
      // Điền dữ liệu từ bài tập hiện có
      _titleController.text = widget.exercise.title;
      _descriptionController.text = widget.exercise.description ?? '';
      _durationController.text = widget.exercise.timeLimit.toString();
      _attemptsController.text = widget.exercise.attemptsAllowed.toString();
      _isShuffleEnabled = widget.exercise.shuffle;
      _isVisible = widget.exercise.visibility;
      _questions = List.from(widget.exercise.questions);
      _startTime = widget.exercise.startTime;
      _endTime = widget.exercise.endTime;
      print('DEBUG: Data initialized successfully');
      print('DEBUG: Questions loaded: ${_questions.length}');
      if (_questions.isNotEmpty) {
        print('DEBUG: First question - ${_questions[0].content} with ${_questions[0].choices?.length ?? 0} choices');
      }
    } catch (e) {
      print('ERROR in _initializeData: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _attemptsController.dispose();
    super.dispose();
  }
  
  void _editQuestion(int index) {
    try {
      print('DEBUG: Editing question at index $index');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditQuestionScreen(
            question: _questions[index],
            onSaved: (updatedQuestion) {
              print('DEBUG: Question updated, content length: ${updatedQuestion.content.length}');
              print('DEBUG: Updated question has ${updatedQuestion.choices?.length ?? 0} choices');
              setState(() {
                _questions[index] = updatedQuestion;
              });
            },
          ),
        ),
      );
    } catch (e) {
      print('ERROR in _editQuestion: $e');
    }
  }
  
  void _addNewQuestion() {
    try {
      // Tạo câu hỏi mới với ID tạm thời
      final newQuestion = Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '',
        type: QuestionType.multipleChoice,
        points: 1.0,
        choices: [
          Choice(id: '0', content: '', isCorrect: true),
          Choice(id: '1', content: '', isCorrect: false),
          Choice(id: '2', content: '', isCorrect: false),
          Choice(id: '3', content: '', isCorrect: false),
        ],
      );
      
      print('DEBUG: Adding new question with ID: ${newQuestion.id}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditQuestionScreen(
            question: newQuestion,
            isNew: true,
            onSaved: (updatedQuestion) {
              print('DEBUG: New question saved with content: ${updatedQuestion.content}');
              setState(() {
                _questions.add(updatedQuestion);
              });
              print('DEBUG: Questions count now: ${_questions.length}');
            },
          ),
        ),
      );
    } catch (e) {
      print('ERROR in _addNewQuestion: $e');
    }
  }
  
  void _removeQuestion(int index) {
    try {
      if (_questions.length > 1) {
        print('DEBUG: Removing question at index $index');
        setState(() {
          _questions.removeAt(index);
        });
        print('DEBUG: Questions count after removal: ${_questions.length}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa câu hỏi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bài tập phải có ít nhất một câu hỏi')),
        );
      }
    } catch (e) {
      print('ERROR in _removeQuestion: $e');
    }
  }

  Future<void> _updateExercise() async {
    print('DEBUG: Starting _updateExercise...');
    try {
      if (!_formKey.currentState!.validate()) {
        print('DEBUG: Form validation failed');
        return;
      }
      
      // Validate questions
      if (_questions.isEmpty) {
        print('DEBUG: No questions found');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bài tập phải có ít nhất một câu hỏi')),
        );
        return;
      }
      
      print('DEBUG: Validating ${_questions.length} questions');
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        print('DEBUG: Checking question $i: ${question.content}');
        
        if (question.content.trim().isEmpty) {
          print('DEBUG: Question $i has empty content');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tất cả câu hỏi phải có nội dung')),
          );
          return;
        }
        
        if (question.choices == null || question.choices!.isEmpty) {
          print('DEBUG: Question $i has no choices');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mỗi câu hỏi phải có ít nhất một lựa chọn')),
          );
          return;
        }
        
        print('DEBUG: Question $i has ${question.choices!.length} choices');
        for (int j = 0; j < question.choices!.length; j++) {
          final choice = question.choices![j];
          if (choice.content.trim().isEmpty) {
            print('DEBUG: Choice $j of question $i has empty content');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Các lựa chọn không được để trống')),
            );
            return;
          }
        }
        
        // Kiểm tra xem có ít nhất một lựa chọn đúng không
        bool hasCorrectChoice = false;
        for (final choice in question.choices!) {
          if (choice.isCorrect) {
            hasCorrectChoice = true;
            break;
          }
        }
        
        if (!hasCorrectChoice) {
          print('DEBUG: Question $i has no correct choice');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mỗi câu hỏi phải có ít nhất một lựa chọn đúng')),
          );
          return;
        }
      }
      
      setState(() => _isLoading = true);
      
      final timeLimit = int.parse(_durationController.text);
      final attemptsAllowed = int.parse(_attemptsController.text);
      
      await _exerciseService.updateExercise(
        widget.exercise.id!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        questions: _questions,
        timeLimit: timeLimit,
        attemptsAllowed: attemptsAllowed,
        shuffle: _isShuffleEnabled,
        visibility: _isVisible,
        startTime: _startTime,
        endTime: _endTime,
      );

      print('DEBUG: Exercise updated successfully');
      setState(() => _isLoading = false);
      
      // Thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật bài tập thành công')),
      );
      
      // Gọi callback onSaved nếu có
      print('DEBUG: Calling onSaved callback');
      widget.onSaved?.call();
      
      // Quay lại màn hình trước
      print('DEBUG: Navigating back');
      Navigator.pop(context);
    } catch (e, stackTrace) {
      print('ERROR updating exercise: $e');
      print('ERROR stack trace: $stackTrace');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu bài tập: $e'),
          duration: const Duration(seconds: 10), // Hiển thị lâu hơn để đọc lỗi
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa bài tập'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _updateExercise,
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            tooltip: 'Lưu thay đổi',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Thông tin cơ bản
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin cơ bản',
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
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập tiêu đề bài tập';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Mô tả (tùy chọn)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _durationController,
                                  decoration: const InputDecoration(
                                    labelText: 'Thời gian làm bài (phút)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập thời gian';
                                    }
                                    final duration = int.tryParse(value);
                                    if (duration == null || duration <= 0) {
                                      return 'Thời gian phải là số > 0';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _attemptsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Số lần làm tối đa',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập số lần';
                                    }
                                    final attempts = int.tryParse(value);
                                    if (attempts == null || attempts <= 0) {
                                      return 'Số lần phải là số > 0';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  title: const Text('Xáo trộn câu hỏi'),
                                  value: _isShuffleEnabled,
                                  onChanged: (value) {
                                    setState(() {
                                      _isShuffleEnabled = value;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: SwitchListTile(
                                  title: const Text('Hiển thị bài tập'),
                                  value: _isVisible,
                                  onChanged: (value) {
                                    setState(() {
                                      _isVisible = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Start date picker
                          ListTile(
                            title: const Text('Ngày bắt đầu'),
                            subtitle: Text(_startTime != null 
                              ? '${_startTime!.toDate().day}/${_startTime!.toDate().month}/${_startTime!.toDate().year} ${_startTime!.toDate().hour}:${_startTime!.toDate().minute.toString().padLeft(2, '0')}'
                              : 'Chọn ngày bắt đầu'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _startTime?.toDate() ?? DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(_startTime?.toDate() ?? DateTime.now()),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _startTime = Timestamp.fromDate(DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            time.hour,
                                            time.minute,
                                          ));
                                        });
                                      }
                                    }
                                  },
                                ),
                                if (_startTime != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _startTime = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                          // End date picker
                          ListTile(
                            title: const Text('Ngày kết thúc'),
                            subtitle: Text(_endTime != null 
                              ? '${_endTime!.toDate().day}/${_endTime!.toDate().month}/${_endTime!.toDate().year} ${_endTime!.toDate().hour}:${_endTime!.toDate().minute.toString().padLeft(2, '0')}'
                              : 'Chọn ngày kết thúc'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _endTime?.toDate() ?? (_startTime?.toDate() ?? DateTime.now()),
                                      firstDate: _startTime?.toDate() ?? DateTime.now(),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.fromDateTime(_endTime?.toDate() ?? DateTime.now()),
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _endTime = Timestamp.fromDate(DateTime(
                                            date.year,
                                            date.month,
                                            date.day,
                                            time.hour,
                                            time.minute,
                                          ));
                                        });
                                      }
                                    }
                                  },
                                ),
                                if (_endTime != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _endTime = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Danh sách câu hỏi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Danh sách câu hỏi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addNewQuestion,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm câu hỏi'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Danh sách câu hỏi
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            question.content.isNotEmpty 
                                ? question.content 
                                : 'Câu hỏi ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text('Số lựa chọn: ${question.choices?.length ?? 0}'),
                              Text('Điểm: ${question.points}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _editQuestion(index),
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                tooltip: 'Chỉnh sửa câu hỏi',
                              ),
                              IconButton(
                                onPressed: () => _removeQuestion(index),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Xóa câu hỏi',
                              ),
                            ],
                          ),
                          onTap: () => _editQuestion(index),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: _updateExercise,
              child: const Icon(Icons.save),
              tooltip: 'Lưu thay đổi',
            ),
    );
  }
} 