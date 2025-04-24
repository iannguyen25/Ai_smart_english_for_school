import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/search_history.dart';
import '../../services/auth_service.dart';
import 'translate_screen.dart';

class SearchHistoryScreen extends StatefulWidget {
  const SearchHistoryScreen({Key? key}) : super(key: key);

  @override
  _SearchHistoryScreenState createState() => _SearchHistoryScreenState();
}

class _SearchHistoryScreenState extends State<SearchHistoryScreen> {
  final AuthService _authService = AuthService();
  
  List<SearchHistory> _searchHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        setState(() {
          _errorMessage = 'Không tìm thấy thông tin người dùng';
          _isLoading = false;
        });
        return;
      }

      final history = await SearchHistory.getUserSearchHistory(userId);
      setState(() {
        _searchHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải lịch sử tìm kiếm: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllHistory() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả lịch sử tìm kiếm?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userId = _authService.currentUser?.id;
        if (userId == null) {
          setState(() {
            _errorMessage = 'Không tìm thấy thông tin người dùng';
            _isLoading = false;
          });
          return;
        }

        await SearchHistory.clearUserSearchHistory(userId);
        
        setState(() {
          _searchHistory = [];
          _isLoading = false;
        });
        
        Get.snackbar(
          'Thành công',
          'Đã xóa tất cả lịch sử tìm kiếm',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Không thể xóa lịch sử: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteHistoryItem(SearchHistory history) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (history.id == null) {
        throw Exception('ID không hợp lệ');
      }
      
      final success = await SearchHistory.deleteSearchHistory(history.id!);
      
      if (success) {
        setState(() {
          _searchHistory.removeWhere((item) => item.id == history.id);
          _isLoading = false;
        });
        
        Get.snackbar(
          'Thành công',
          'Đã xóa từ khỏi lịch sử tìm kiếm',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Không thể xóa mục lịch sử');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      Get.snackbar(
        'Lỗi',
        'Không thể xóa lịch sử: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử tìm kiếm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _searchHistory.isEmpty ? null : _clearAllHistory,
            tooltip: 'Xóa tất cả lịch sử',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, 
                          size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSearchHistory,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _searchHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, 
                              size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có lịch sử tìm kiếm nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => Get.to(() => const TranslateScreen()),
                            icon: const Icon(Icons.search),
                            label: const Text('Bắt đầu tìm kiếm từ'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSearchHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _searchHistory.length,
                        itemBuilder: (context, index) {
                          final history = _searchHistory[index];
                          return _buildHistoryCard(history);
                        },
                      ),
                    ),
    );
  }

  Widget _buildHistoryCard(SearchHistory history) {
    // Format thời gian để hiển thị
    final searchDate = history.searchedAt?.toDate() ?? DateTime.now();
    final now = DateTime.now();
    String formattedDate;

    if (searchDate.day == now.day && 
        searchDate.month == now.month && 
        searchDate.year == now.year) {
      // Nếu là hôm nay
      final hour = searchDate.hour.toString().padLeft(2, '0');
      final minute = searchDate.minute.toString().padLeft(2, '0');
      formattedDate = 'Hôm nay, $hour:$minute';
    } else if (searchDate.day == now.day - 1 && 
               searchDate.month == now.month && 
               searchDate.year == now.year) {
      // Nếu là hôm qua
      final hour = searchDate.hour.toString().padLeft(2, '0');
      final minute = searchDate.minute.toString().padLeft(2, '0');
      formattedDate = 'Hôm qua, $hour:$minute';
    } else {
      // Các ngày khác
      final day = searchDate.day.toString().padLeft(2, '0');
      final month = searchDate.month.toString().padLeft(2, '0');
      final hour = searchDate.hour.toString().padLeft(2, '0');
      final minute = searchDate.minute.toString().padLeft(2, '0');
      formattedDate = '$day/$month/${searchDate.year}, $hour:$minute';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Dismissible(
        key: Key(history.id ?? ''),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (direction) {
          _deleteHistoryItem(history);
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            history.word,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (history.meaning != null)
                Text(
                  history.meaning!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Get.to(() => TranslateScreen());
            },
          ),
          onTap: () {
            Get.to(() => TranslateScreen());
          },
        ),
      ),
    );
  }
} 