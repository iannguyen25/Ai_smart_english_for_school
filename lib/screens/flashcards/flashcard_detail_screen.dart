import 'package:base_flutter_framework/screens/flashcards/flashcard_practice_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';
import '../../services/auth_service.dart';
import '../../services/flashcard_service.dart';
import 'create_edit_flashcard_screen.dart';

class FlashcardDetailScreen extends StatefulWidget {
  final String flashcardId;

  const FlashcardDetailScreen({Key? key, required this.flashcardId}) : super(key: key);

  @override
  _FlashcardDetailScreenState createState() => _FlashcardDetailScreenState();
}

class _FlashcardDetailScreenState extends State<FlashcardDetailScreen> {
  final AuthService _authService = AuthService();
  final FlashcardService _flashcardService = FlashcardService();
  bool _isLoading = true;
  String? _errorMessage;
  Flashcard? _flashcard;
  List<FlashcardItem> _items = [];
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadFlashcardData();
  }

  Future<void> _loadFlashcardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Tải thông tin bộ thẻ
      final flashcard = await _flashcardService.getFlashcardById(widget.flashcardId);

      if (flashcard == null) {
        setState(() {
          _errorMessage = 'Không tìm thấy bộ thẻ';
          _isLoading = false;
        });
        return;
      }

      // Kiểm tra quyền sở hữu
      final currentUser = _authService.currentUser;
      final isOwner = currentUser != null && currentUser.id == flashcard.userId;

      // Tải các thẻ
      final items = await _flashcardService.getFlashcardItems(widget.flashcardId);

      setState(() {
        _flashcard = flashcard;
        _items = items;
        _isOwner = isOwner;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải dữ liệu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_flashcard?.title ?? 'Chi tiết bộ thẻ'),
        actions: [
          if (_isOwner && _flashcard != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Get.to(() => CreateEditFlashcardScreen(flashcard: _flashcard));
                if (result == true) {
                  _loadFlashcardData();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _flashcard == null ? null : () => _showOptions(),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                Get.to(() => FlashcardPracticeScreen(
                  flashcard: _flashcard!,
                  items: _items,
                ));
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Luyện tập'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFlashcardData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_flashcard == null) {
      return const Center(
        child: Text('Không tìm thấy bộ thẻ'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin bộ thẻ
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _flashcard!.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Icon(
                        _flashcard!.isPublic ? Icons.public : Icons.lock,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _flashcard!.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      FutureBuilder<String>(
                        future: _getUserName(_flashcard!.userId),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Người dùng',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(_flashcard!.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Danh sách thẻ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thẻ (${_items.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_isOwner)
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Get.to(() => CreateEditFlashcardScreen(flashcard: _flashcard));
                    if (result == true) {
                      _loadFlashcardData();
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Chỉnh sửa'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_items.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.note_alt_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có thẻ nào trong bộ này',
                    style: TextStyle(fontSize: 16),
                  ),
                  if (_isOwner)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Get.to(() => CreateEditFlashcardScreen(flashcard: _flashcard));
                          if (result == true) {
                            _loadFlashcardData();
                          }
                        },
                        child: const Text('Thêm thẻ'),
                      ),
                    ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildFlashcardItemCard(item, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFlashcardItemCard(FlashcardItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _showFlashcardItemDetail(item);
        },
        borderRadius: BorderRadius.circular(12),
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
                  if (_isOwner)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () async {
                        final result = await Get.to(() => CreateEditFlashcardScreen(flashcard: _flashcard));
                        if (result == true) {
                          _loadFlashcardData();
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Câu hỏi:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.question,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Câu trả lời:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.answer,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item.image != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Image.network(
                    item.image!,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFlashcardItemDetail(FlashcardItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Câu hỏi:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.question,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Câu trả lời:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.answer,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (item.image != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Hình ảnh:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Image.network(
                      item.image!,
                      fit: BoxFit.cover,
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (_isOwner)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Get.to(() => CreateEditFlashcardScreen(flashcard: _flashcard));
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Chỉnh sửa'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _deleteFlashcardItem(item);
                          },
                          icon: const Icon(Icons.delete),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          label: const Text('Xóa'),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteFlashcardItem(FlashcardItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa thẻ'),
          content: const Text('Bạn có chắc chắn muốn xóa thẻ này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _flashcardService.deleteFlashcardItem(item.id!);

      // Tải lại dữ liệu
      _loadFlashcardData();

      Get.snackbar(
        'Thành công',
        'Đã xóa thẻ',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      Get.snackbar(
        'Lỗi',
        'Không thể xóa thẻ: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showOptions() {
    if (_flashcard == null) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Chỉnh sửa'),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Get.to(() => CreateEditFlashcardScreen(
                      flashcard: _flashcard,
                    ));
                    if (result == true) {
                      _loadFlashcardData();
                    }
                  },
                ),
                ListTile(
                  leading: Icon(_flashcard!.isPublic ? Icons.lock : Icons.public),
                  title: Text(_flashcard!.isPublic ? 'Đặt riêng tư' : 'Đặt công khai'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _flashcardService.toggleFlashcardVisibility(_flashcard!.id!);
                      _loadFlashcardData();
                      Get.snackbar(
                        'Thành công',
                        'Đã thay đổi trạng thái công khai',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } catch (e) {
                      Get.snackbar(
                        'Lỗi',
                        e.toString(),
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Xóa bộ thẻ'),
                          content: const Text('Bạn có chắc chắn muốn xóa bộ thẻ này không?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Xóa'),
                            ),
                          ],
                        );
                      },
                    );
                    
                    if (confirm == true) {
                      try {
                        await _flashcardService.deleteFlashcard(_flashcard!.id!);
                        Get.back(result: true);
                        Get.snackbar(
                          'Thành công',
                          'Đã xóa bộ thẻ',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } catch (e) {
                        Get.snackbar(
                          'Lỗi',
                          'Không thể xóa bộ thẻ: ${e.toString()}',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    }
                  },
                ),
              ],
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Chia sẻ'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                  Get.snackbar(
                    'Thông báo',
                    'Tính năng đang được phát triển',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _getUserName(String userId) async {
    try {
      final user = await _authService.getUserByIdCached(userId);
      if (user != null) {
        return '${user.firstName} ${user.lastName}'.trim();
      }
    } catch (e) {
      print('Error getting user name: $e');
    }
    return 'Người dùng';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}