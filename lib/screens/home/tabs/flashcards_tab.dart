import 'package:base_flutter_framework/models/flashcard_item.dart';
import 'package:base_flutter_framework/screens/flashcards/create_edit_flashcard_screen.dart';
import 'package:base_flutter_framework/screens/flashcards/flashcard_detail_screen.dart';
import 'package:base_flutter_framework/screens/flashcards/search_flashcards_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/flashcard.dart';
import '../../../services/auth_service.dart';
import '../../../services/flashcard_service.dart';

class FlashcardsTab extends StatefulWidget {
  const FlashcardsTab({Key? key}) : super(key: key);

  @override
  _FlashcardsTabState createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<FlashcardsTab> {
  final AuthService _authService = AuthService();
  final FlashcardService _flashcardService = FlashcardService();

  List<Flashcard> _userFlashcards = [];
  List<Flashcard> _publicFlashcards = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser!.id!;

      // Load user's flashcards
      final userCards = await _flashcardService.getUserFlashcards(userId);

      // Load public flashcards from other users
      final publicCards = await _flashcardService.getPublicFlashcards();
      final otherPublicCards =
          publicCards.where((card) => card.userId != userId).toList();

      setState(() {
        _userFlashcards = userCards;
        _publicFlashcards = otherPublicCards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải danh sách bộ thẻ: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFlashcard(Flashcard flashcard) async {
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

    if (confirm != true) return;

    try {
      await _flashcardService.deleteFlashcard(flashcard.id!);
      _loadFlashcards();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Get.to(() => const SearchFlashcardsScreen());
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Get.to(() => const CreateEditFlashcardScreen());
          if (result == true) {
            _loadFlashcards();
          }
        },
        child: const Icon(Icons.add),
      ),
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
              onPressed: _loadFlashcards,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_userFlashcards.isEmpty && _publicFlashcards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Chưa có bộ thẻ nào',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Get.to(() => const CreateEditFlashcardScreen());
              },
              child: const Text('Tạo bộ thẻ mới'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFlashcards,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_userFlashcards.isNotEmpty) ...[
            Text(
              'Bộ thẻ của bạn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._userFlashcards.map((flashcard) {
              return _buildFlashcardCard(flashcard, isOwner: true);
            }).toList(),
            const SizedBox(height: 32),
          ],
          if (_publicFlashcards.isNotEmpty) ...[
            Text(
              'Bộ thẻ công khai',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._publicFlashcards.map((flashcard) {
              return _buildFlashcardCard(flashcard, isOwner: false);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildFlashcardCard(Flashcard flashcard, {required bool isOwner}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final result = await Get.to(() => FlashcardDetailScreen(
                flashcardId: flashcard.id!,
              ));
          if (result == true) {
            _loadFlashcards();
          }
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
                  Expanded(
                    child: Text(
                      flashcard.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'visibility',
                          child: Row(
                            children: [
                              Icon(flashcard.isPublic
                                  ? Icons.lock
                                  : Icons.public),
                              SizedBox(width: 8),
                              Text(flashcard.isPublic
                                  ? 'Đặt riêng tư'
                                  : 'Đặt công khai'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xóa', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        switch (value) {
                          case 'edit':
                            final result =
                                await Get.to(() => CreateEditFlashcardScreen(
                                      flashcard: flashcard,
                                    ));
                            if (result == true) {
                              _loadFlashcards();
                            }
                            break;
                          case 'visibility':
                            try {
                              await _flashcardService
                                  .toggleFlashcardVisibility(flashcard.id!);
                              _loadFlashcards();
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
                            break;
                          case 'delete':
                            await _deleteFlashcard(flashcard);
                            break;
                        }
                      },
                    ),
                ],
              ),
              if (flashcard.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  flashcard.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  FutureBuilder<String>(
                    future: _getUserName(flashcard.userId),
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
                    _formatDate(flashcard.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (flashcard.isPublic) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.public, size: 16, color: Colors.grey),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
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
