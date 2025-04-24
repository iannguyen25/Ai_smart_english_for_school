import 'package:base_flutter_framework/models/quiz.dart';
import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import 'package:get/get.dart';
import '../../services/exercise_service.dart';

class EditQuestionScreen extends StatefulWidget {
  final Question question;
  final bool isNew;
  final Function(Question) onSaved;
  final String? exerciseId;

  const EditQuestionScreen({
    Key? key,
    required this.question,
    this.isNew = false,
    required this.onSaved,
    this.exerciseId,
  }) : super(key: key);

  @override
  _EditQuestionScreenState createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _explanationController = TextEditingController();
  final _pointsController = TextEditingController();
  
  List<Choice> _choices = [];
  int _correctChoiceIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  void _initializeData() {
    _contentController.text = widget.question.content;
    _explanationController.text = widget.question.explanation ?? '';
    _pointsController.text = widget.question.points.toString();
    
    _choices = widget.question.choices ?? [];
    
    // Tìm lựa chọn đúng đầu tiên
    final correctIndex = _choices.indexWhere((choice) => choice.isCorrect);
    if (correctIndex != -1) {
      _correctChoiceIndex = correctIndex;
    }
  }
  
  @override
  void dispose() {
    _contentController.dispose();
    _explanationController.dispose();
    _pointsController.dispose();
    super.dispose();
  }
  
  void _addChoice() {
    if (_choices.length < 6) { // Giới hạn 6 lựa chọn
      setState(() {
        _choices.add(Choice(
          id: _choices.length.toString(),
          content: '',
          isCorrect: false,
        ));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 6 lựa chọn cho mỗi câu hỏi')),
      );
    }
  }
  
  void _removeChoice(int index) {
    if (_choices.length > 2) { // Tối thiểu 2 lựa chọn
      setState(() {
        if (_correctChoiceIndex == index) {
          // Nếu xóa lựa chọn đúng, chọn lựa chọn đầu tiên làm đáp án đúng
          _correctChoiceIndex = 0;
          _choices[0] = Choice(
            id: _choices[0].id,
            content: _choices[0].content,
            isCorrect: true
          );
        } else if (_correctChoiceIndex > index) {
          // Cập nhật lại vị trí của lựa chọn đúng
          _correctChoiceIndex--;
        }
        
        _choices.removeAt(index);
        
        // Cập nhật lại IDs
        for (int i = 0; i < _choices.length; i++) {
          _choices[i] = Choice(
            id: i.toString(),
            content: _choices[i].content,
            isCorrect: _choices[i].isCorrect
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mỗi câu hỏi phải có ít nhất 2 lựa chọn')),
      );
    }
  }
  
  void _updateChoiceContent(int index, String content) {
    setState(() {
      _choices[index] = Choice(
        id: _choices[index].id,
        content: content,
        isCorrect: _choices[index].isCorrect
      );
    });
  }
  
  void _setCorrectChoice(int index) {
    setState(() {
      // Đặt tất cả lựa chọn thành không đúng
      for (int i = 0; i < _choices.length; i++) {
        _choices[i] = Choice(
          id: _choices[i].id,
          content: _choices[i].content,
          isCorrect: i == index
        );
      }
      _correctChoiceIndex = index;
    });
  }
  
  void saveQuestion() {
    print('Attempting to save question: ${_contentController.text}');
    if (_formKey.currentState!.validate() && _choices.isNotEmpty) {
      // Ensure we have at least one correct answer
      bool hasCorrectChoice = _choices.any((choice) => choice.isCorrect);
      if (!hasCorrectChoice) {
        Get.snackbar(
          'Lỗi',
          'Vui lòng chọn ít nhất một câu trả lời đúng',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        print('Error: No correct choice selected');
        return;
      }

      // Create updated question
      Question updatedQuestion = Question(
        id: widget.question.id,
        content: _contentController.text,
        type: QuestionType.multipleChoice,
        points: double.tryParse(_pointsController.text) ?? 1.0,
        explanation: _explanationController.text,
        choices: _choices,
      );

      print('Question to save: ${updatedQuestion.id}, ${updatedQuestion.content}, ${updatedQuestion.choices!.length} choices');
      
      // For debug - print all choices
      for (var i = 0; i < updatedQuestion.choices!.length; i++) {
        final choice = updatedQuestion.choices![i];
        print('Choice $i: ${choice.content}, isCorrect: ${choice.isCorrect}, id: ${choice.id}');
      }
      
      try {
        // If we're editing directly from exercise service
        if (widget.exerciseId != null) {
          print('Updating question in exercise ${widget.exerciseId}');
          
          // Show loading dialog
          Get.dialog(
            const Center(child: CircularProgressIndicator()),
            barrierDismissible: false,
          );
          
          // Update the question in the exercise
          ExerciseService().updateQuestionInExercise(widget.exerciseId!, updatedQuestion).then((_) {
            // Close loading dialog
            Get.back();
            
            print('Question successfully updated in exercise');
            
            // Call onSaved callback before navigation
            widget.onSaved(updatedQuestion);
            
            // Show success message
            Get.snackbar(
              'Thành công',
              'Câu hỏi đã được cập nhật',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            
            // Navigate back to previous screen
            print('Navigating back to previous screen with updated question');
            Navigator.of(context).pop(updatedQuestion);
            Navigator.of(context).pop();
          }).catchError((error) {
            // Close loading dialog
            Get.back();
            
            print('Error updating question: $error');
            Get.snackbar(
              'Lỗi',
              'Không thể cập nhật câu hỏi: $error',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          });
        } else {
          // Call onSaved callback first
          print('Calling onSaved callback with updated question');
          widget.onSaved(updatedQuestion);
          
          // Show success message
          Get.snackbar(
            'Thành công',
            'Câu hỏi đã được cập nhật',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          
          // Navigate back to previous screen directly using Navigator
          print('Navigating back to previous screen with updated question');
          Navigator.of(context).pop(updatedQuestion);
        }
      } catch (e) {
        print('Error in saveQuestion: $e');
        Get.snackbar(
          'Lỗi',
          'Không thể lưu câu hỏi: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      print('Validation failed or no choices added');
      Get.snackbar(
        'Lỗi',
        'Vui lòng nhập đầy đủ thông tin và thêm ít nhất một lựa chọn',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? 'Thêm câu hỏi mới' : 'Chỉnh sửa câu hỏi'),
        actions: [
          IconButton(
            onPressed: saveQuestion,
            icon: const Icon(Icons.save),
            tooltip: 'Lưu câu hỏi',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông tin câu hỏi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: 'Nội dung câu hỏi',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập nội dung câu hỏi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _explanationController,
                      decoration: const InputDecoration(
                        labelText: 'Giải thích (tùy chọn)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pointsController,
                      decoration: const InputDecoration(
                        labelText: 'Điểm cho câu hỏi',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập điểm';
                        }
                        final points = double.tryParse(value);
                        if (points == null || points <= 0) {
                          return 'Điểm phải là số > 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Các lựa chọn',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addChoice,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm lựa chọn'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn lựa chọn đúng bằng cách nhấn vào nút radio bên trái',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // Danh sách các lựa chọn
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _choices.length,
              itemBuilder: (context, index) {
                final choice = _choices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Radio<int>(
                      value: index,
                      groupValue: _correctChoiceIndex,
                      onChanged: (value) {
                        if (value != null) {
                          _setCorrectChoice(value);
                        }
                      },
                    ),
                    title: TextFormField(
                      initialValue: choice.content,
                      decoration: InputDecoration(
                        labelText: 'Lựa chọn ${index + 1}',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) => _updateChoiceContent(index, value),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeChoice(index),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: saveQuestion,
        child: const Icon(Icons.save),
        tooltip: 'Lưu câu hỏi',
      ),
    );
  }
} 