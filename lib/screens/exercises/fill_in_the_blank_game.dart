import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';

class FillInTheBlankGame extends StatefulWidget {
  final List<FlashcardItem> items;
  final int maxItems;

  const FillInTheBlankGame({
    Key? key,
    required this.items,
    this.maxItems = 10, // Mặc định 10 câu hỏi
  }) : super(key: key);

  @override
  _FillInTheBlankGameState createState() => _FillInTheBlankGameState();
}

class _FillInTheBlankGameState extends State<FillInTheBlankGame> {
  int _currentIndex = 0;
  String _userAnswer = '';
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  List<bool> _answered = [];
  List<FlashcardItem> _selectedItems = [];
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  List<FlashcardItem> _getRandomItems(List<FlashcardItem> items) {
    // Lọc bỏ các item không hợp lệ
    final validItems = items.where((item) => 
      item.type == FlashcardItemType.textToText || 
      item.type == FlashcardItemType.imageToText
    ).toList();

    // Nếu số lượng item hợp lệ ít hơn hoặc bằng maxItems, trả về tất cả
    if (validItems.length <= widget.maxItems) {
      return List.from(validItems);
    }

    // Tạo một bản sao của danh sách để tránh ảnh hưởng đến dữ liệu gốc
    final shuffledItems = List<FlashcardItem>.from(validItems);
    shuffledItems.shuffle();

    // Lấy ngẫu nhiên maxItems thẻ
    return shuffledItems.take(widget.maxItems).toList();
  }

  void _initializeGame() {
    // Lấy ngẫu nhiên các thẻ
    _selectedItems = _getRandomItems(widget.items);
    
    // Trộn ngẫu nhiên
    _selectedItems.shuffle();
    
    // Khởi tạo trạng thái đã trả lời
    _answered = List.filled(_selectedItems.length, false);
    
    _currentIndex = 0;
    _score = 0;
    _userAnswer = '';
    _showResult = false;
    _answerController.clear(); // Clear input khi khởi tạo lại game
  }

  void _checkAnswer() {
    if (_userAnswer.trim().isEmpty) return;

    setState(() {
      _showResult = true;
      _isCorrect = _userAnswer.trim().toLowerCase() == 
          _selectedItems[_currentIndex].answer.toLowerCase();
      
      if (_isCorrect && !_answered[_currentIndex]) {
        _score += 10;
        _answered[_currentIndex] = true;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _selectedItems.length - 1) {
      setState(() {
        _currentIndex++;
        _userAnswer = '';
        _showResult = false;
        _answerController.clear(); // Clear input khi chuyển câu
      });
    } else {
      _showFinalScore();
    }
  }

  void _showFinalScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Kết thúc trò chơi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 48,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Điểm số: $_score',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã trả lời đúng ${_answered.where((a) => a).length}/${_selectedItems.length} câu',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Kết thúc'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeGame();
            },
            child: const Text('Chơi lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Điền từ'),
        ),
        body: const Center(
          child: Text('Không có từ vựng phù hợp cho trò chơi này'),
        ),
      );
    }

    final currentItem = _selectedItems[_currentIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điền từ'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Điểm: $_score',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _selectedItems.length,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),
            
            // Question counter
            Text(
              'Câu ${_currentIndex + 1}/${_selectedItems.length}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            
            // Question card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (currentItem.type == FlashcardItemType.textToText) ...[
                      Text(
                        currentItem.question,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else if (currentItem.questionImage != null) ...[
                      Container(
                        constraints: const BoxConstraints(
                          minHeight: 120,
                          maxHeight: 200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            currentItem.questionImage!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.error_outline, color: Colors.red),
                              );
                            },
                          ),
                        ),
                      ),
                      if (currentItem.questionCaption != null && 
                          currentItem.questionCaption!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          currentItem.questionCaption!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Answer input
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                labelText: 'Nhập câu trả lời',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _checkAnswer,
                ),
              ),
              onChanged: (value) => _userAnswer = value,
              onSubmitted: (_) => _checkAnswer(),
            ),
            
            if (_showResult) ...[
              const SizedBox(height: 16),
              Card(
                color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        _isCorrect ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect ? Colors.green : Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isCorrect ? 'Chính xác!' : 'Sai rồi!',
                        style: TextStyle(
                          color: _isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đáp án: ${currentItem.answer}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _nextQuestion,
                child: const Text('Câu tiếp theo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 