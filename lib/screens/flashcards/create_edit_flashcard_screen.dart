import 'package:base_flutter_framework/models/content_approval.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';
import '../../services/auth_service.dart';
import '../../services/flashcard_service.dart';
import '../../services/ocr_service.dart';
import '../../services/chatgpt_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';
import 'dart:io';

class CreateEditFlashcardScreen extends StatefulWidget {
  final Flashcard? flashcard;
  final String? initialTitle;
  final String? initialDescription;
  final String? lessonId;
  final String? classroomId;

  const CreateEditFlashcardScreen({
    Key? key, 
    this.flashcard,
    this.initialTitle,
    this.initialDescription,
    this.lessonId,
    this.classroomId,
  }) : super(key: key);

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
  final OCRService _ocrService = OCRService();
  final ChatGPTService _chatGPTService = ChatGPTService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  bool _isPublic = false;
  bool _isLoading = false;
  String? _errorMessage;
  List<FlashcardItem> _items = [];
  bool _isEditMode = false;
  bool _isProcessingOCR = false;
  bool _isCourseClosed = false;

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
      // Khởi tạo với giá trị ban đầu nếu có
      _titleController.text = widget.initialTitle ?? '';
      _descriptionController.text = widget.initialDescription ?? '';
      // Thêm một thẻ trống khi tạo mới
      _items.add(FlashcardItem(
        flashcardId: '',  // ID sẽ được cập nhật sau khi tạo flashcard
        question: '',
        answer: '',
      ));
    }
    _checkCourseStatus();
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
    String? validationError;
    
    print('=== Validating Flashcard Items ===');
    for (var item in _items) {
      print('Item type: ${item.type}');
      print('Item data: ${item.toMap()}');
      
      switch (item.type) {
        case FlashcardItemType.textToText:
          if (item.question.isNotEmpty && item.answer.isNotEmpty) {
            hasValidItems = true;
          }
          break;
        case FlashcardItemType.imageToText:
          if (item.questionImage != null && item.questionImage!.isNotEmpty && item.answer.isNotEmpty) {
            hasValidItems = true;
          } else if (item.questionImage == null || item.questionImage!.isEmpty) {
            validationError = 'Vui lòng tải lên ảnh cho thẻ kiểu Ảnh - Chữ';
          }
          break;
        case FlashcardItemType.imageToImage:
          print('Checking imageToImage item:');
          print('Question image: ${item.questionImage}');
          print('Answer image: ${item.answerImage}');
          if (item.questionImage != null && item.questionImage!.isNotEmpty &&
              item.answerImage != null && item.answerImage!.isNotEmpty) {
            hasValidItems = true;
          } else {
            validationError = 'Vui lòng tải lên cả ảnh từ vựng và ảnh minh họa cho thẻ kiểu Ảnh - Ảnh';
          }
          break;
      }
      if (validationError != null) break;
    }

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    if (!hasValidItems) {
      setState(() {
        _errorMessage = 'Vui lòng thêm ít nhất một thẻ với đầy đủ thông tin';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser!.id!;

      if (_isEditMode && widget.flashcard?.id != null) {
        print('=== Updating Existing Flashcard ===');
        // Cập nhật bộ thẻ hiện có
        final updatedFlashcard = widget.flashcard!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          isPublic: _isPublic,
          updatedAt: DateTime.now(),
          approvalStatus: ApprovalStatus.pending,
        );

        await _flashcardService.updateFlashcard(updatedFlashcard);

        // Cập nhật hoặc tạo các thẻ
        for (var item in _items) {
          // Bỏ qua các thẻ trống
          if (item.type == FlashcardItemType.textToText && 
              item.question.isEmpty && item.answer.isEmpty) continue;
          if (item.type == FlashcardItemType.imageToText && 
              (item.questionImage == null || item.questionImage!.isEmpty || item.answer.isEmpty)) continue;
          if (item.type == FlashcardItemType.imageToImage && 
              (item.questionImage == null || item.questionImage!.isEmpty || 
               item.answerImage == null || item.answerImage!.isEmpty)) continue;

          if (item.id != null) {
            print('Updating existing item: ${item.id}');
            print('Item type: ${item.type}');
            print('Item data: ${item.toMap()}');
            // Cập nhật thẻ hiện có
            await _flashcardService.updateFlashcardItem(item);
          } else {
            print('Creating new item for existing flashcard');
            print('Item type: ${item.type}');
            print('Item data: ${item.toMap()}');
            // Tạo thẻ mới
            final newItem = item.copyWith(flashcardId: widget.flashcard!.id!);
            await _flashcardService.createFlashcardItem(newItem);
          }
        }
      } else {
        print('=== Creating New Flashcard ===');
        // Tạo bộ thẻ mới
        final newFlashcard = Flashcard(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          userId: userId,
          isPublic: _isPublic,
          lessonId: widget.lessonId,
          classroomId: widget.classroomId,
          approvalStatus: ApprovalStatus.pending,
        );

        // Tạo flashcard trước để lấy ID
        final flashcardId = await _flashcardService.createFlashcard(newFlashcard);
        print('Created flashcard with ID: $flashcardId');

        // Tạo các thẻ với flashcardId mới
        for (var item in _items) {
          // Bỏ qua các thẻ trống
          if (item.type == FlashcardItemType.textToText && 
              item.question.isEmpty && item.answer.isEmpty) continue;
          if (item.type == FlashcardItemType.imageToText && 
              (item.questionImage == null || item.questionImage!.isEmpty || item.answer.isEmpty)) continue;
          if (item.type == FlashcardItemType.imageToImage && 
              (item.questionImage == null || item.questionImage!.isEmpty || 
               item.answerImage == null || item.answerImage!.isEmpty)) continue;

          print('Creating new item for new flashcard');
          print('Item type: ${item.type}');
          print('Item data: ${item.toMap()}');
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
      print('Error saving flashcard: $e');
      setState(() {
        _errorMessage = 'Không thể lưu bộ thẻ: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _scanImage() async {
    setState(() {
      _isProcessingOCR = true;
      _errorMessage = null;
    });

    try {
      // Scan image and get text
      final text = await _ocrService.pickAndProcessImage();
      if (text == null) {
        setState(() {
          _isProcessingOCR = false;
        });
        return;
      }

      // Show OCR result dialog
      final bool? shouldContinue = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Kết quả OCR'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Văn bản được nhận dạng:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(text),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        setState(() {
          _isProcessingOCR = false;
        });
        return;
      }

      // Sử dụng ChatGPT để sửa lỗi OCR
      setState(() {
        _errorMessage = 'Đang xử lý văn bản...';
      });
      
      final fixedText = await _chatGPTService.fixText(text);
      
      // Sử dụng ChatGPT để tạo flashcard
      setState(() {
        _errorMessage = 'Đang tạo flashcard...';
      });
      
      final flashcards = await _chatGPTService.generateFlashcards(fixedText);
      
      if (flashcards.isEmpty) {
        Get.snackbar(
          'Thông báo',
          'Không thể tạo flashcard từ ảnh này. Vui lòng thử lại với ảnh khác hoặc tạo thẻ thủ công.',
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() {
          _isProcessingOCR = false;
          _errorMessage = null;
        });
        return;
      }

      // Hiển thị flashcard được tạo
      final bool? shouldSave = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Flashcard được tạo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đã tạo ${flashcards.length} flashcard:'),
                const SizedBox(height: 16),
                ...flashcards.asMap().entries.map((entry) {
                  final index = entry.key;
                  final card = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Từ ${index + 1}: ${card['question']}'),
                          const SizedBox(height: 4),
                          Text('Nghĩa: ${card['answer']}'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Hủy', style: TextStyle(color: Colors.red.withOpacity(0.6))),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Lưu', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );

      if (shouldSave == true) {
        // Update UI with new flashcards
        setState(() {
          _items = flashcards.map((card) => FlashcardItem(
            flashcardId: _isEditMode ? widget.flashcard!.id! : '',
            question: card['question'] ?? '',
            answer: card['answer'] ?? '',
          )).toList();

          // Add empty card if no flashcards were generated
          if (_items.isEmpty) {
            _items.add(FlashcardItem(
              flashcardId: _isEditMode ? widget.flashcard!.id! : '',
              question: '',
              answer: '',
            ));
          }

          _isProcessingOCR = false;
          _errorMessage = null;
        });

        Get.snackbar(
          'Thành công',
          'Đã tạo ${_items.length} thẻ từ ảnh',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        setState(() {
          _isProcessingOCR = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi xử lý ảnh: ${e.toString()}';
        _isProcessingOCR = false;
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.insert(0, FlashcardItem(
        flashcardId: _isEditMode ? widget.flashcard!.id! : '',
        question: '',
        answer: '',
        type: FlashcardItemType.textToText,
      ));
    });
  }

  void _removeItem(int index) async {
    final item = _items[index];

    // Xóa ảnh khỏi storage nếu có
    if (item.questionImage != null && item.questionImage!.isNotEmpty) {
      await _storageService.deleteFile(item.questionImage!);
    }
    if (item.answerImage != null && item.answerImage!.isNotEmpty) {
      await _storageService.deleteFile(item.answerImage!);
    }

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

  Future<void> _pickQuestionImage(int index) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        print('Uploading question image: ${image.path}');
        final String url = await _storageService.uploadFile(File(image.path), 'flashcard_images');
        print('Uploaded question image URL: $url');
        setState(() {
          _items[index] = _items[index].copyWith(
            questionImage: url,
            // Chỉ set type thành imageToText nếu type hiện tại là textToText
            type: _items[index].type == FlashcardItemType.textToText 
                ? FlashcardItemType.imageToText 
                : _items[index].type,
          );
        });
        print('Updated flashcard item: ${_items[index].toMap()}');
      }
    } catch (e) {
      print('Error picking/uploading question image: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải ảnh lên: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _pickAnswerImage(int index) async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        print('Uploading answer image: ${image.path}');
        final String url = await _storageService.uploadFile(File(image.path), 'flashcard_images');
        print('Uploaded answer image URL: $url');
        setState(() {
          _items[index] = _items[index].copyWith(
            answerImage: url,
            type: FlashcardItemType.imageToImage,
          );
        });
        print('Updated flashcard item: ${_items[index].toMap()}');
      }
    } catch (e) {
      print('Error picking/uploading answer image: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải ảnh lên: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _removeQuestionImage(int index) async {
    try {
      if (_items[index].questionImage != null) {
        await _storageService.deleteFile(_items[index].questionImage!);
        setState(() {
          _items[index] = _items[index].copyWith(
            questionImage: null,
            questionCaption: null,
          );
        });
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xóa ảnh: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _removeAnswerImage(int index) async {
    try {
      if (_items[index].answerImage != null) {
        await _storageService.deleteFile(_items[index].answerImage!);
        setState(() {
          _items[index] = _items[index].copyWith(
            answerImage: null,
            answerCaption: null,
          );
        });
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xóa ảnh: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _checkCourseStatus() async {
    if (widget.classroomId != null) {
      try {
        final courseDoc = await FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.classroomId)
            .get();
        
        if (courseDoc.exists) {
          final courseData = courseDoc.data();
          setState(() {
            _isCourseClosed = courseData?['isClosed'] ?? false;
          });
        }
      } catch (e) {
        print('Error checking course status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCourseClosed) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Không thể chỉnh sửa'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.orange.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Khóa học đã bị khóa',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Không thể thêm hoặc chỉnh sửa flashcard khi khóa học đã bị khóa.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Chỉnh sửa bộ thẻ' : 'Tạo bộ thẻ mới'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _isProcessingOCR ? null : _scanImage,
            tooltip: 'Quét ảnh để tạo thẻ',
          ),
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
              controller: _scrollController,
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
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_isProcessingOCR)
                    const LinearProgressIndicator(),

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
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm thẻ'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Danh sách các thẻ
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return _buildFlashcardItemCard(_items[index], index);
                    },
                  ),
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
                  'Thẻ ${_items.length - index}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Dropdown để chọn kiểu flashcard
            DropdownButtonFormField<FlashcardItemType>(
              value: _items[index].type,
              decoration: const InputDecoration(
                labelText: 'Kiểu thẻ',
                border: OutlineInputBorder(),
              ),
              items: [
                FlashcardItemType.textToText,
                FlashcardItemType.imageToText,
                FlashcardItemType.imageToImage,
              ].map((type) {
                String label;
                switch (type) {
                  case FlashcardItemType.textToText:
                    label = 'Chữ - Chữ';
                    break;
                  case FlashcardItemType.imageToText:
                    label = 'Ảnh - Chữ';
                    break;
                  case FlashcardItemType.imageToImage:
                    label = 'Ảnh - Ảnh';
                    break;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _items[index] = _items[index].copyWith(type: value);
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Question section
            if (_items[index].type == FlashcardItemType.textToText) ...[
              TextFormField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Câu hỏi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập câu hỏi';
                  }
                  return null;
                },
              ),
            ] else if (_items[index].type == FlashcardItemType.imageToText || 
                      _items[index].type == FlashcardItemType.imageToImage) ...[
              // Image question with caption
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ảnh từ vựng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _items[index].questionImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                _items[index].questionImage!,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeQuestionImage(index),
                                ),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: () => _pickQuestionImage(index),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.add_photo_alternate, size: 48),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _items[index].questionCaption,
                    decoration: const InputDecoration(
                      labelText: 'Chú thích ảnh từ vựng',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _items[index] = _items[index].copyWith(questionCaption: value);
                      });
                    },
                    validator: (value) {
                      if (_items[index].questionImage != null && (value == null || value.isEmpty)) {
                        return 'Vui lòng nhập chú thích cho ảnh';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Answer section
              if (_items[index].type == FlashcardItemType.textToText ||
                _items[index].type == FlashcardItemType.imageToText) ...[
            TextFormField(
              controller: answerController,
              decoration: const InputDecoration(
                  labelText: 'Câu trả lời',
                border: OutlineInputBorder(),
              ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập câu trả lời';
                  }
                  return null;
                },
              ),
            ] else if (_items[index].type == FlashcardItemType.imageToImage) ...[
              // Image answer with caption
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text('Ảnh nghĩa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _items[index].answerImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                _items[index].answerImage!,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeAnswerImage(index),
                                ),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: () => _pickAnswerImage(index),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Icon(Icons.add_photo_alternate, size: 48),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _items[index].answerCaption,
                    decoration: const InputDecoration(
                      labelText: 'Chú thích ảnh nghĩa',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                        setState(() {
                        _items[index] = _items[index].copyWith(answerCaption: value);
                        });
                      },
                    validator: (value) {
                      if (_items[index].answerImage != null && (value == null || value.isEmpty)) {
                        return 'Vui lòng nhập chú thích cho ảnh';
                      }
                      return null;
                      },
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageUpload(BuildContext context, String? imageUrl, Function(String) onImageUploaded) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Stack(
              children: [
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xóa ảnh'),
                          content: const Text('Bạn có chắc chắn muốn xóa ảnh này không?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await _storageService.deleteFile(imageUrl);
                        onImageUploaded('');
                      }
                    },
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: () async {
                final ImagePicker picker = ImagePicker();
                
                // Show dialog to choose image source
                final source = await showDialog<ImageSource>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Chọn nguồn ảnh'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Thư viện'),
                          onTap: () => Navigator.pop(context, ImageSource.gallery),
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Máy ảnh'),
                          onTap: () => Navigator.pop(context, ImageSource.camera),
                        ),
                      ],
                    ),
                  ),
                );

                if (source == null) return;

                try {
                  // Pick image
                  final XFile? image = await picker.pickImage(
                    source: source,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 80,
                  );

                  if (image == null) return;

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  final userId = _authService.currentUser!.id!;
                  final flashcardId = widget.flashcard?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
                  
                  // Upload image
                  final url = await _storageService.uploadFlashcardImage(
                    userId,
                    flashcardId,
                    File(image.path),
                  );

                  // Close loading dialog
                  Navigator.pop(context);

                  if (url == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không thể tải lên ảnh')),
                    );
                    return;
                  }

                  // Update state with new image URL
                  onImageUploaded(url);
                } catch (e) {
                  // Close loading dialog if open
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_photo_alternate, size: 48),
                  SizedBox(height: 8),
                  Text('Tải lên ảnh'),
                ],
              ),
            ),
    );
  }

  Widget _buildImagePreview(String imageUrl) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xóa ảnh'),
                    content: const Text('Bạn có chắc chắn muốn xóa ảnh này không?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _storageService.deleteFile(imageUrl);
                          setState(() {
                            // Cập nhật state sau khi xóa ảnh
                          });
                        },
                        child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
