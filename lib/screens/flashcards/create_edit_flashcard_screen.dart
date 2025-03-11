import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';
import '../../services/auth_service.dart';
import '../../services/flashcard_service.dart';

class CreateEditFlashcardScreen extends StatefulWidget {
  final Flashcard? flashcard;

  const CreateEditFlashcardScreen({Key? key, this.flashcard}) : super(key: key);

  @override
  _CreateEditFlashcardScreenState createState() =>
      _CreateEditFlashcardScreenState();
}

class _CreateEditFlashcardScreenState extends State<CreateEditFlashcardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  final FlashcardService _flashcardService = FlashcardService();
  bool _isPublic = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<FlashcardItem> _items = [];
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.flashcard != null;

    if (_isEditMode) {
      _titleController.text = widget.flashcard!.title;
      _descriptionController.text = widget.flashcard!.description;
      _isPublic = widget.flashcard!.isPublic;
      _loadFlashcardItems();
    } else {
      // Thêm một thẻ trống khi tạo mới
      _items.add(FlashcardItem(
        flashcardId: '',
        question: '',
        answer: '',
      ));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFlashcardItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items =
          await _flashcardService.getFlashcardItems(widget.flashcard!.id!);

      setState(() {
        _items = items;
        if (_items.isEmpty) {
          // Thêm một thẻ trống nếu không có thẻ nào
          _items.add(FlashcardItem(
            flashcardId: widget.flashcard!.id!,
            question: '',
            answer: '',
          ));
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải thẻ: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFlashcard() async {
    if (!_formKey.currentState!.validate()) return;

    // Kiểm tra xem có ít nhất một thẻ hợp lệ không
    bool hasValidItems = false;
    for (var item in _items) {
      if (item.question.isNotEmpty && item.answer.isNotEmpty) {
        hasValidItems = true;
        break;
      }
    }

    if (!hasValidItems) {
      setState(() {
        _errorMessage =
            'Vui lòng thêm ít nhất một thẻ với câu hỏi và câu trả lời';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser!.id!;

      if (_isEditMode) {
        // Cập nhật bộ thẻ hiện có
        final updatedFlashcard = widget.flashcard!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          isPublic: _isPublic,
          updatedAt: Timestamp.now().toDate(),
        );

        await _flashcardService.updateFlashcard(updatedFlashcard);

        // Cập nhật hoặc tạo các thẻ
        for (var item in _items) {
          if (item.question.isEmpty && item.answer.isEmpty) continue;

          if (item.id != null) {
            // Cập nhật thẻ hiện có
            await _flashcardService.updateFlashcardItem(item);
          } else {
            // Tạo thẻ mới
            final newItem = item.copyWith(flashcardId: widget.flashcard!.id!);
            await _flashcardService.createFlashcardItem(newItem);
          }
        }
      } else {
        // Tạo bộ thẻ mới
        final newFlashcard = Flashcard(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          userId: userId,
          isPublic: _isPublic,
        );

        final flashcardId =
            await _flashcardService.createFlashcard(newFlashcard);

        // Tạo các thẻ
        for (var item in _items) {
          if (item.question.isEmpty && item.answer.isEmpty) continue;

          final newItem = item.copyWith(flashcardId: flashcardId);
          await _flashcardService.createFlashcardItem(newItem);
        }
      }

      Get.back(result: true);
      Get.snackbar(
        'Thành công',
        _isEditMode ? 'Bộ thẻ đã được cập nhật' : 'Bộ thẻ đã được tạo',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể lưu bộ thẻ: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _addNewItem() {
    setState(() {
      _items.add(FlashcardItem(
        flashcardId: _isEditMode ? widget.flashcard!.id! : '',
        question: '',
        answer: '',
      ));
    });
  }

  void _removeItem(int index) {
    final item = _items[index];

    setState(() {
      _items.removeAt(index);
    });

    // Nếu thẻ đã tồn tại trong cơ sở dữ liệu, xóa nó
    if (item.id != null) {
      _flashcardService.deleteFlashcardItem(item.id!).catchError((e) {
        print('Error deleting flashcard item: $e');
      });
    }

    // Đảm bảo luôn có ít nhất một thẻ
    if (_items.isEmpty) {
      _items.add(FlashcardItem(
        flashcardId: _isEditMode ? widget.flashcard!.id! : '',
        question: '',
        answer: '',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Chỉnh sửa bộ thẻ' : 'Tạo bộ thẻ mới'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveFlashcard,
            child: Text(
              'Lưu',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading && _isEditMode
          ? const Center(child: CircularProgressIndicator())
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),

                  // Thông tin bộ thẻ
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề',
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
                      labelText: 'Mô tả',
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
                  SwitchListTile(
                    title: const Text('Công khai'),
                    subtitle: const Text('Cho phép người khác xem bộ thẻ này'),
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                  const Divider(height: 32),

                  // Danh sách thẻ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Thẻ (${_items.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      ElevatedButton.icon(
                        onPressed: _addNewItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm thẻ'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Danh sách các thẻ
                  ..._items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return _buildFlashcardItemCard(item, index);
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardItemCard(FlashcardItem item, int index) {
    final questionController = TextEditingController(text: item.question);
    final answerController = TextEditingController(text: item.answer);

    // Cập nhật giá trị khi người dùng thay đổi
    questionController.addListener(() {
      _items[index] = _items[index].copyWith(question: questionController.text);
    });

    answerController.addListener(() {
      _items[index] = _items[index].copyWith(answer: answerController.text);
    });

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
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: questionController,
              decoration: const InputDecoration(
                labelText: 'Câu hỏi',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: answerController,
              decoration: const InputDecoration(
                labelText: 'Câu trả lời',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            // Có thể thêm chức năng tải lên hình ảnh ở đây
          ],
        ),
      ),
    );
  }
}
