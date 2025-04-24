import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class CreateFlashcardScreen extends StatefulWidget {
  const CreateFlashcardScreen({Key? key}) : super(key: key);

  @override
  _CreateFlashcardScreenState createState() => _CreateFlashcardScreenState();
}

class _CreateFlashcardScreenState extends State<CreateFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _lessonId;
  String? _classroomId;
  bool _isLoading = false;
  List<Map<String, String>> _flashcardItems = [
    {'term': '', 'definition': ''}
  ];

  @override
  void initState() {
    super.initState();
    _parseArguments();
  }

  void _parseArguments() {
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _lessonId = args['lessonId'];
      _classroomId = args['classroomId'];
      
      if (args['name'] != null) {
        _nameController.text = args['name'];
      }
      
      if (args['description'] != null) {
        _descriptionController.text = args['description'];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addFlashcardItem() {
    setState(() {
      _flashcardItems.add({'term': '', 'definition': ''});
    });
  }

  void _removeFlashcardItem(int index) {
    if (_flashcardItems.length > 1) {
      setState(() {
        _flashcardItems.removeAt(index);
      });
    }
  }

  void _updateFlashcardItem(int index, String field, String value) {
    setState(() {
      _flashcardItems[index][field] = value;
    });
  }

  Future<void> _saveFlashcard() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Kiểm tra các thẻ flashcard
    for (int i = 0; i < _flashcardItems.length; i++) {
      if (_flashcardItems[i]['term']!.isEmpty || _flashcardItems[i]['definition']!.isEmpty) {
        Get.snackbar(
          'Lỗi',
          'Vui lòng điền đầy đủ thông tin cho thẻ ghi nhớ ${i + 1}',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw 'Bạn chưa đăng nhập';
      }

      // Tạo flashcard mới
      final flashcardRef = await FirebaseFirestore.instance.collection('flashcards').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'authorId': currentUser.uid,
        'lessonId': _lessonId,
        'classroomId': _classroomId,
        'isPublic': false,
        'itemCount': _flashcardItems.length,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Thêm các item của flashcard
      for (var item in _flashcardItems) {
        await FirebaseFirestore.instance.collection('flashcard_items').add({
          'flashcardId': flashcardRef.id,
          'term': item['term'],
          'definition': item['definition'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Cập nhật bài học nếu có
      if (_lessonId != null) {
        final lessonDoc = await FirebaseFirestore.instance
            .collection('lessons')
            .doc(_lessonId)
            .get();
        
        if (lessonDoc.exists) {
          final List<dynamic> flashcardIds = lessonDoc.data()?['flashcardIds'] ?? [];
          flashcardIds.add(flashcardRef.id);
          
          await FirebaseFirestore.instance
              .collection('lessons')
              .doc(_lessonId)
              .update({
            'flashcardIds': flashcardIds,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      Get.back();
      Get.snackbar(
        'Thành công',
        'Đã tạo bộ thẻ ghi nhớ mới',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tạo bộ thẻ ghi nhớ: ${e.toString()}',
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
        title: const Text('Tạo bộ thẻ ghi nhớ'),
        backgroundColor: Colors.orange.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveFlashcard,
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên bộ thẻ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên bộ thẻ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Từ ghi nhớ (${_flashcardItems.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addFlashcardItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm từ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _flashcardItems.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Thẻ ${index + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeFlashcardItem(index),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: _flashcardItems[index]['term'],
                                  decoration: const InputDecoration(
                                    labelText: 'Thuật ngữ',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => _updateFlashcardItem(index, 'term', value),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: _flashcardItems[index]['definition'],
                                  decoration: const InputDecoration(
                                    labelText: 'Định nghĩa',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                  onChanged: (value) => _updateFlashcardItem(index, 'definition', value),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveFlashcard,
        backgroundColor: Colors.orange.shade800,
        child: const Icon(Icons.save),
      ),
    );
  }
}
