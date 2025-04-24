import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';

class FillInTheBlankGame extends StatefulWidget {
  final List<FlashcardItem> items;

  const FillInTheBlankGame({
    Key? key,
    required this.items,
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

  @override
  void initState() {
    super.initState();
    _answered = List.filled(widget.items.length, false);
    // Trộn ngẫu nhiên các câu hỏi
    widget.items.shuffle();
  }

  void _checkAnswer() {
    if (_userAnswer.trim().isEmpty) return;

    setState(() {
      _showResult = true;
      _isCorrect = _userAnswer.trim().toLowerCase() == 
          widget.items[_currentIndex].answer.toLowerCase();
      
      if (_isCorrect && !_answered[_currentIndex]) {
        _score += 10;
        _answered[_currentIndex] = true;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.items.length - 1) {
      setState(() {
        _currentIndex++;
        _userAnswer = '';
        _showResult = false;
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
              'Bạn đã trả lời đúng ${_answered.where((a) => a).length}/${widget.items.length} câu',
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
              setState(() {
                _currentIndex = 0;
                _score = 0;
                _answered = List.filled(widget.items.length, false);
                widget.items.shuffle();
              });
            },
            child: const Text('Chơi lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.items[_currentIndex];
    
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
              value: (_currentIndex + 1) / widget.items.length,
              backgroundColor: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),
            
            // Question counter
            Text(
              'Câu ${_currentIndex + 1}/${widget.items.length}',
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
                    Text(
                      currentItem.question,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (currentItem.questionImage != null) ...[
                      const SizedBox(height: 16),
                      Image.network(
                        currentItem.questionImage!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Answer input
            TextField(
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