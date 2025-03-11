import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/flashcard.dart';
import '../../services/flashcard_service.dart';
import '../../services/auth_service.dart';
import 'flashcard_detail_screen.dart';

class SearchFlashcardsScreen extends StatefulWidget {
  const SearchFlashcardsScreen({Key? key}) : super(key: key);

  @override
  _SearchFlashcardsScreenState createState() => _SearchFlashcardsScreenState();
}

class _SearchFlashcardsScreenState extends State<SearchFlashcardsScreen> {
  final FlashcardService _flashcardService = FlashcardService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<Flashcard> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser?.id;
      final results = await _flashcardService.searchFlashcards(
        query: query,
        userId: userId,
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tìm kiếm: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm bộ thẻ...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: Colors.black),
          autofocus: true,
        ),
      ),
      body: _buildBody(),
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
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nhập từ khóa để tìm kiếm',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy kết quả cho "${_searchController.text}"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final flashcard = _searchResults[index];
        return _buildFlashcardCard(flashcard);
      },
    );
  }

  Widget _buildFlashcardCard(Flashcard flashcard) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Get.to(() => FlashcardDetailScreen(flashcardId: flashcard.id!));
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
                  Icon(
                    flashcard.isPublic ? Icons.public : Icons.lock,
                    color: Colors.grey,
                    size: 20,
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
                    _formatDate(flashcard.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
      final user = await _authService.getUserById(userId);
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
