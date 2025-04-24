import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';

class MatchingGame extends StatefulWidget {
  final List<FlashcardItem> items;

  const MatchingGame({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  _MatchingGameState createState() => _MatchingGameState();
}

class _MatchingGameState extends State<MatchingGame> {
  List<FlashcardItem> _questions = [];
  List<FlashcardItem> _answers = [];
  FlashcardItem? _selectedQuestion;
  FlashcardItem? _selectedAnswer;
  int _score = 0;
  int _matches = 0;
  List<bool> _matchedQuestions = [];
  List<bool> _matchedAnswers = [];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Lọc bỏ các item chỉ có ảnh
    final validItems = widget.items.where((item) => item.type != FlashcardItemType.imageOnly).toList();
    
    // Tạo bản sao của items để không ảnh hưởng đến dữ liệu gốc
    _questions = List.from(validItems);
    _answers = List.from(validItems);
    
    // Trộn ngẫu nhiên
    _questions.shuffle();
    _answers.shuffle();
    
    // Khởi tạo trạng thái đã ghép
    _matchedQuestions = List.filled(_questions.length, false);
    _matchedAnswers = List.filled(_answers.length, false);
    
    _matches = 0;
    _score = 0;
    _selectedQuestion = null;
    _selectedAnswer = null;
  }

  void _selectQuestion(FlashcardItem item, int index) {
    if (_matchedQuestions[index]) return;
    
    setState(() {
      if (_selectedQuestion == item) {
        _selectedQuestion = null;
      } else {
        _selectedQuestion = item;
      }
      _checkMatch();
    });
  }

  void _selectAnswer(FlashcardItem item, int index) {
    if (_matchedAnswers[index]) return;
    
    setState(() {
      if (_selectedAnswer == item) {
        _selectedAnswer = null;
      } else {
        _selectedAnswer = item;
      }
      _checkMatch();
    });
  }

  void _checkMatch() {
    if (_selectedQuestion != null && _selectedAnswer != null) {
      final isMatch = _selectedQuestion!.id == _selectedAnswer!.id;
      
      if (isMatch) {
        final questionIndex = _questions.indexOf(_selectedQuestion!);
        final answerIndex = _answers.indexOf(_selectedAnswer!);
        
        setState(() {
          _matchedQuestions[questionIndex] = true;
          _matchedAnswers[answerIndex] = true;
          _matches++;
          _score += 10;
        });
        
        // Kiểm tra nếu đã ghép hết
        if (_matches == _questions.length) {
          _showFinalScore();
        }
      }
      
      setState(() {
        _selectedQuestion = null;
        _selectedAnswer = null;
      });
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
              'Bạn đã ghép đúng $_matches/${_questions.length} cặp',
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

  Widget _buildQuestionContent(FlashcardItem item) {
    switch (item.type) {
      case FlashcardItemType.textToText:
      case FlashcardItemType.textToImage:
        return Text(item.question);
      
      case FlashcardItemType.imageToText:
      case FlashcardItemType.imageToImage:
        if (item.questionImage != null && item.questionImage!.isNotEmpty) {
          return Container(
            height: 100,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.questionImage!,
                fit: BoxFit.cover,
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
          );
        }
        return Text(item.question);
      
      default:
        return Text(item.question);
    }
  }

  Widget _buildAnswerContent(FlashcardItem item) {
    switch (item.type) {
      case FlashcardItemType.textToText:
      case FlashcardItemType.imageToText:
        return Text(item.answer);
      
      case FlashcardItemType.textToImage:
      case FlashcardItemType.imageToImage:
        if (item.answerImage != null && item.answerImage!.isNotEmpty) {
          return Container(
            height: 100,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.answerImage!,
                fit: BoxFit.cover,
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
          );
        }
        return Text(item.answer);
      
      default:
        return Text(item.answer);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nối từ'),
        ),
        body: const Center(
          child: Text('Không có từ vựng phù hợp cho trò chơi này'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nối từ'),
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
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _matches / _questions.length,
            backgroundColor: Colors.grey.shade200,
          ),
          
          Expanded(
            child: Row(
              children: [
                // Questions column
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final item = _questions[index];
                      final isSelected = _selectedQuestion == item;
                      final isMatched = _matchedQuestions[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isMatched
                            ? Colors.green.shade50
                            : isSelected
                                ? Colors.blue.shade50
                                : null,
                        child: ListTile(
                          title: _buildQuestionContent(item),
                          onTap: () => _selectQuestion(item, index),
                          trailing: isMatched
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                
                // Answers column
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _answers.length,
                    itemBuilder: (context, index) {
                      final item = _answers[index];
                      final isSelected = _selectedAnswer == item;
                      final isMatched = _matchedAnswers[index];
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isMatched
                            ? Colors.green.shade50
                            : isSelected
                                ? Colors.blue.shade50
                                : null,
                        child: ListTile(
                          title: _buildAnswerContent(item),
                          onTap: () => _selectAnswer(item, index),
                          trailing: isMatched
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 