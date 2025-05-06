import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';

class MatchingGame extends StatefulWidget {
  final List<FlashcardItem> items;
  final int maxItems;

  const MatchingGame({
    Key? key,
    required this.items,
    this.maxItems = 10, // Mặc định 12 thẻ, có thể điều chỉnh từ 10-15
  }) : super(key: key);

  @override
  _MatchingGameState createState() => _MatchingGameState();
}

class _MatchingGameState extends State<MatchingGame> with SingleTickerProviderStateMixin {
  List<FlashcardItem> _questions = [];
  List<FlashcardItem> _answers = [];
  FlashcardItem? _selectedQuestion;
  FlashcardItem? _selectedAnswer;
  int _score = 0;
  int _matches = 0;
  List<bool> _matchedQuestions = [];
  List<bool> _matchedAnswers = [];
  Map<int, bool> _wrongQuestions = {};
  Map<int, bool> _wrongAnswers = {};
  Map<int, double> _questionOpacity = {};
  Map<int, double> _answerOpacity = {};
  Map<int, double> _questionHeight = {};
  Map<int, double> _answerHeight = {};

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  List<FlashcardItem> _getRandomItems(List<FlashcardItem> items) {
    // Lọc bỏ các item không hợp lệ
    final validItems = items.where((item) {
      switch (item.type) {
        case FlashcardItemType.textToText:
          return item.question.isNotEmpty && item.answer.isNotEmpty;
        case FlashcardItemType.imageToText:
          return item.questionImage != null && 
                 item.questionImage!.isNotEmpty && 
                 item.answer.isNotEmpty;
        case FlashcardItemType.imageToImage:
          return item.questionImage != null && 
                 item.questionImage!.isNotEmpty && 
                 item.answerImage != null && 
                 item.answerImage!.isNotEmpty;
        default:
          return false;
      }
    }).toList();

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
    final selectedItems = _getRandomItems(widget.items);
    
    // Tạo bản sao của items để không ảnh hưởng đến dữ liệu gốc
    _questions = List.from(selectedItems);
    _answers = List.from(selectedItems);
    
    // Trộn ngẫu nhiên
    _questions.shuffle();
    _answers.shuffle();
    
    // Khởi tạo trạng thái đã ghép
    _matchedQuestions = List.filled(_questions.length, false);
    _matchedAnswers = List.filled(_answers.length, false);
    
    // Khởi tạo opacity và height cho tất cả các thẻ
    for (int i = 0; i < _questions.length; i++) {
      _questionOpacity[i] = 1.0;
      _answerOpacity[i] = 1.0;
      _questionHeight[i] = 1.0;
      _answerHeight[i] = 1.0;
    }
    
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
      final questionIndex = _questions.indexOf(_selectedQuestion!);
      final answerIndex = _answers.indexOf(_selectedAnswer!);
      final isMatch = _selectedQuestion!.id == _selectedAnswer!.id;
      
      if (isMatch) {
        setState(() {
          _matchedQuestions[questionIndex] = true;
          _matchedAnswers[answerIndex] = true;
          _wrongQuestions.remove(questionIndex);
          _wrongAnswers.remove(answerIndex);
          _matches++;
          _score += 10;
        });

        // Thêm hiệu ứng fade out và thu nhỏ sau 1 giây
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _questionOpacity[questionIndex] = 0.0;
              _answerOpacity[answerIndex] = 0.0;
              _questionHeight[questionIndex] = 0.0;
              _answerHeight[answerIndex] = 0.0;
            });
          }
        });
        
        // Kiểm tra nếu đã ghép hết
        if (_matches == _questions.length) {
          _showFinalScore();
        }
      } else {
        setState(() {
          _wrongQuestions[questionIndex] = true;
          _wrongAnswers[answerIndex] = true;
          if (_score > 0) _score -= 2;
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _wrongQuestions.remove(questionIndex);
              _wrongAnswers.remove(answerIndex);
            });
          }
        });
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
        return Text(
          item.question,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        );
      
      case FlashcardItemType.imageToText:
      case FlashcardItemType.imageToImage:
        if (item.questionImage != null && item.questionImage!.isNotEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxWidth * 0.6, // Tỷ lệ 5:3
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
                  ),
                  if (item.questionCaption != null && item.questionCaption!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        item.questionCaption!,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            }
          );
        }
        return Text(
          item.question,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        );
      
      default:
        return Text(
          item.question,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        );
    }
  }

  Widget _buildAnswerContent(FlashcardItem item) {
    switch (item.type) {
      case FlashcardItemType.textToText:
      case FlashcardItemType.imageToText:
        return Text(
          item.answer,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        );
      
      case FlashcardItemType.imageToImage:
        if (item.answerImage != null && item.answerImage!.isNotEmpty) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxWidth * 0.6, // Tỷ lệ 5:3
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
                  ),
                  if (item.answerCaption != null && item.answerCaption!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        item.answerCaption!,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            }
          );
        }
        return Text(
          item.answer,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        );
      
      default:
        return Text(
          item.answer,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        );
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
                      final isWrong = _wrongQuestions[index] == true;
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: (_questionHeight[index] ?? 1.0) * (item.type == FlashcardItemType.imageToImage ? 180 : 100),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: _questionOpacity[index] ?? 1.0,
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: isMatched
                                ? Colors.green.shade50
                                : isWrong
                                    ? Colors.red.shade50
                                : isSelected
                                    ? Colors.blue.shade50
                                    : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: InkWell(
                                onTap: isMatched ? null : () => _selectQuestion(item, index),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildQuestionContent(item),
                                    if (isMatched)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Icon(Icons.check_circle, color: Colors.green.shade700),
                                      )
                                    else if (isWrong)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Icon(Icons.cancel, color: Colors.red.shade700),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
                      final isWrong = _wrongAnswers[index] == true;
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: (_answerHeight[index] ?? 1.0) * (item.type == FlashcardItemType.imageToImage ? 180 : 100),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: _answerOpacity[index] ?? 1.0,
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: isMatched
                                ? Colors.green.shade50
                                : isWrong
                                    ? Colors.red.shade50
                                : isSelected
                                    ? Colors.blue.shade50
                                    : null,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: InkWell(
                                onTap: isMatched ? null : () => _selectAnswer(item, index),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildAnswerContent(item),
                                    if (isMatched)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Icon(Icons.check_circle, color: Colors.green.shade700),
                                      )
                                    else if (isWrong)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Icon(Icons.cancel, color: Colors.red.shade700),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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