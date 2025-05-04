import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../models/search_history.dart';
import '../../services/auth_service.dart';
import '../../services/translate_service.dart';
import '../../services/flashcard_service.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';
import 'search_history_screen.dart';
import '../../models/content_approval.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({Key? key}) : super(key: key);

  @override
  _TranslateScreenState createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final TranslateService _translateService = TranslateService();
  
  List<String> _suggestedWords = [];
  Map<String, dynamic>? _selectedWord;
  bool _isLoading = false;
  bool _showDetails = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _suggestedWords = [];
        _showDetails = false;
      });
      return;
    }
    
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchWord(_searchController.text);
    });
  }

  Future<void> _searchWord(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Sử dụng local search cho live search
      final results = await _translateService.searchWords(query);
      
      setState(() {
        _suggestedWords = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Lỗi',
        'Không thể tìm kiếm từ: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _showWordDetails(String word) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Gọi API Cohere để lấy chi tiết từ
      final details = await _translateService.getWordDetails(word);
      
      setState(() {
        _selectedWord = details;
        _showDetails = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Lỗi',
        'Không thể tải chi tiết từ: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _saveToSearchHistory(Map<String, dynamic> word) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      await SearchHistory.saveSearchHistory(
        userId: userId,
        word: word['word'],
        meaning: word['meaning'],
      );
      
      Get.snackbar(
        'Thông báo',
        'Đã lưu "${word['word']}" vào lịch sử tìm kiếm',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error saving to search history: $e');
    }
  }

  void _addToFlashcard(Map<String, dynamic> word) async {
    // Kiểm tra role của user hiện tại
    final currentUser = _authService.currentUser;
    // if (currentUser == null || currentUser.roleId != 'teacher') {
    //   Get.snackbar(
    //     'Thông báo',
    //     'Chỉ giáo viên mới có quyền thêm từ vào bộ thẻ ghi nhớ',
    //     snackPosition: SnackPosition.BOTTOM,
    //   );
    //   return;
    // }

    try {
      // Lấy danh sách flashcard của user
      final flashcards = await FlashcardService().getUserFlashcards(currentUser?.id ?? '');

      Get.dialog(
        AlertDialog(
          title: const Text('Chọn bộ thẻ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
      
                SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: flashcards.length,
                    itemBuilder: (context, index) {
                      final flashcard = flashcards[index];
                      return ListTile(
                        title: Text(flashcard.title),
                        subtitle: Text(
                          '${flashcard.items?.length ?? 0} thẻ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        onTap: () async {
                          try {
                            Get.back();
                            
                            // Tạo FlashcardItem mới (luôn dạng text-text)
                            final item = FlashcardItem(
                              flashcardId: flashcard.id!,
                              question: word['word'],
                              answer: word['meaning'],
                              type: FlashcardItemType.textToText,
                            );
                            
                            await FlashcardService().createFlashcardItem(item);
                            
                            Get.snackbar(
                              'Thành công',
                              'Đã thêm "${word['word']}" vào bộ thẻ "${flashcard.title}"',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } catch (e) {
                            print('Error adding word to flashcard: $e');
                            Get.snackbar(
                              'Lỗi',
                              'Không thể thêm từ vào bộ thẻ. Vui lòng thử lại sau.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
          actions: [
            if (flashcards.isEmpty)
              TextButton(
                onPressed: () {
                  Get.back();
                  _showCreateNewFlashcardDialog(word);
                },
                child: const Text('Tạo mới'),
              ),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Hủy'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error loading flashcards: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách bộ thẻ. Vui lòng thử lại sau.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showCreateNewFlashcardDialog(Map<String, dynamic> word) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Tạo bộ thẻ mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Từ đầu tiên: ${word['word']}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tên bộ thẻ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập tên bộ thẻ',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              try {
                Get.back();
                
                // Tạo flashcard mới
                final flashcard = Flashcard(
                  userId: currentUser.id!,
                  title: titleController.text,
                  description: descriptionController.text,
                  isPublic: false,
                  approvalStatus: ApprovalStatus.pending,
                );
                
                final flashcardId = await FlashcardService().createFlashcard(flashcard);
                
                // Tạo FlashcardItem đầu tiên (luôn dạng text-text)
                final item = FlashcardItem(
                  flashcardId: flashcardId,
                  question: word['word'],
                  answer: word['meaning'],
                  type: FlashcardItemType.textToText,
                );
                
                await FlashcardService().createFlashcardItem(item);
                
                Get.snackbar(
                  'Thành công',
                  'Đã tạo bộ thẻ "${titleController.text}" với từ "${word['word']}"',
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                print('Error creating flashcard: $e');
                Get.snackbar(
                  'Lỗi',
                  'Không thể tạo bộ thẻ. Vui lòng thử lại sau.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra từ điển'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Get.to(() => const SearchHistoryScreen()),
            tooltip: 'Lịch sử tìm kiếm',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nhập từ cần tra...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _suggestedWords = [];
                                _showDetails = false;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: _searchWord,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhập từ cần tra để xem nghĩa và thêm vào bộ thẻ ghi nhớ',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showDetails && _selectedWord != null
                    ? _buildWordDetailsView(_selectedWord!)
                    : _buildSuggestedWordsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedWordsView() {
    if (_suggestedWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nhập từ cần tra để bắt đầu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestedWords.length,
      itemBuilder: (context, index) {
        final word = _suggestedWords[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              word,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showWordDetails(word),
          ),
        );
      },
    );
  }

  Widget _buildWordDetailsView(Map<String, dynamic> word) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showDetails = false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  word['word'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  // Phát âm từ (cần tích hợp với text-to-speech)
                  Get.snackbar(
                    'Thông báo',
                    'Đang phát âm: ${word['word']}',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${word['type'] as String} ${word['pronunciation'] as String}',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nghĩa:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            word['meaning'] as String,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ví dụ:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              word['example'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (word['definitions'] != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Định nghĩa:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...List<Widget>.from((word['definitions'] as List<dynamic>).map(
              (definition) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ${definition['definition']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (definition['example'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '   "${definition['example']}"',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )),
          ],
          const SizedBox(height: 24),
          const Text(
            'Từ liên quan:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (word['relatedWords'] as List<dynamic>).map((relatedWord) {
              return Chip(
                label: Text(relatedWord as String),
                backgroundColor: Colors.grey.shade200,
              );
            }).toList(),
          ),
          if (word['synonyms'] != null && (word['synonyms'] as List).isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Từ đồng nghĩa:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (word['synonyms'] as List<dynamic>).map((synonym) {
                return Chip(
                  label: Text(synonym as String),
                  backgroundColor: Colors.green.shade100,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Thêm vào bộ thẻ ghi nhớ'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _addToFlashcard(word),
            ),
          ),
          const SizedBox(height: 16),
          // Thêm nút lưu vào lịch sử tìm kiếm
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Lưu vào lịch sử tìm kiếm'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _saveToSearchHistory(word),
            ),
          ),
        ],
      ),
    );
  }
}