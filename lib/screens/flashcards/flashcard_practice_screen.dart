import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';

class FlashcardPracticeScreen extends StatefulWidget {
  final Flashcard flashcard;
  final List<FlashcardItem> items;

  const FlashcardPracticeScreen({
    Key? key,
    required this.flashcard,
    required this.items,
  }) : super(key: key);

  @override
  _FlashcardPracticeScreenState createState() => _FlashcardPracticeScreenState();
}

class _FlashcardPracticeScreenState extends State<FlashcardPracticeScreen> {
  late PageController _pageController;
  FlutterTts? _flutterTts;
  bool _isTtsInitialized = false;
  int _currentIndex = 0;
  bool _showAnswer = false;
  List<bool> _knownCards = [];
  bool _showingFront = true;
  bool _isCompleted = false;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _knownCards = List.filled(widget.items.length, false);
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      _flutterTts = FlutterTts();
      
      if (_flutterTts == null) {
        print("TTS Init Error: FlutterTts is null");
        return;
      }

      var languages = await _flutterTts!.getLanguages;
      print("Available languages: $languages");

      var available = await _flutterTts!.isLanguageAvailable("en-US");
      print("Is en-US available: $available");
      
      if (available) {
        await _flutterTts!.setLanguage("en-US");
        await _flutterTts!.setSpeechRate(0.5);
        await _flutterTts!.setVolume(1.0);
        await _flutterTts!.setPitch(1.0);
        
        _flutterTts!.setCompletionHandler(() {
          if (mounted) {
            setState(() {
              _isSpeaking = false;
            });
          }
        });

        _flutterTts!.setErrorHandler((msg) {
          print("TTS Error Handler: $msg");
          if (mounted) {
            setState(() {
              _isSpeaking = false;
            });
          }
        });

        setState(() {
          _isTtsInitialized = true;
        });
        print("TTS initialized successfully");
      } else {
        print("Language en-US is not available");
      }
    } catch (e) {
      print("TTS Init Error: $e");
    }
  }

  Future<void> _speak(String text) async {
    if (!_isTtsInitialized || _flutterTts == null) {
      print("TTS not initialized yet");
      return;
    }

    try {
      if (_isSpeaking) {
        await _flutterTts!.stop();
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
      }
      
      var result = await _flutterTts!.speak(text);
      print("TTS speak result: $result");
      
      if (result != 1) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
          });
        }
      }
    } catch (e) {
      print("TTS Speak Error: $e");
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_flutterTts != null) {
      try {
        _flutterTts!.stop();
      } catch (e) {
        print("TTS Dispose Error: $e");
      }
    }
    _pageController.dispose();
    super.dispose();
  }

  void _nextCard() {
    if (_currentIndex < widget.items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  void _markCard(bool known) {
    print('Current index: $_currentIndex');
    print('Total items: ${widget.items.length}');
    print('Is last card: ${_currentIndex >= widget.items.length - 1}');
    
    setState(() {
      _knownCards[_currentIndex] = known;
      
      if (_currentIndex >= widget.items.length - 1) {
        print('Showing completion screen');
        _isCompleted = true;
        
        // Track completion
        final analyticsService = AnalyticsService();
        analyticsService.trackFlashcardActivity(
          userId: AuthService().currentUser?.id ?? '',
          lessonId: widget.flashcard.lessonId ?? '',
          classroomId: widget.flashcard.classroomId ?? '',
          flashcardId: widget.flashcard.id ?? '',
          flashcardTitle: widget.flashcard.title,
          action: 'completed',
          totalCards: widget.items.length,
          viewedCards: widget.items.length,
          timestamp: DateTime.now(),
        );
      } else {
        _nextCard();
      }
    });
  }

  void _restartPractice() {
    setState(() {
      _currentIndex = 0;
      _showAnswer = false;
      _knownCards = List.filled(widget.items.length, false);
      _isCompleted = false;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Building screen, isCompleted: $_isCompleted');
    
    if (_isCompleted) {
      print('Returning completion screen');
      return _buildCompletionScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.flashcard.title),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text(
              'Kết thúc',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.items.length,
            backgroundColor: Colors.grey.shade200,
          ),
          
          // Card counter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Thẻ ${_currentIndex + 1}/${widget.items.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 16),
                Text(
                  'Đã thuộc: ${_knownCards.where((known) => known).length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          // Flashcard content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: _isCompleted ? const NeverScrollableScrollPhysics() : null,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _showAnswer = false;
                });
              },
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return _buildFlashcard(item);
              },
            ),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _currentIndex > 0 ? _previousCard : null,
                ),
                ElevatedButton(
                  onPressed: _toggleAnswer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: Text(_showAnswer ? 'Ẩn câu trả lời' : 'Xem câu trả lời'),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _currentIndex < widget.items.length - 1
                      ? _nextCard
                      : null,
                ),
              ],
            ),
          ),
          
          // Rating buttons
          if (_showAnswer)
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 32,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _markCard(false),
                    icon: const Icon(Icons.close),
                    label: const Text('Chưa thuộc'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _markCard(true),
                    icon: const Icon(Icons.check),
                    label: const Text('Đã thuộc'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(FlashcardItem item) {
    return GestureDetector(
      onTap: _toggleAnswer,
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showAnswer ? 'Câu trả lời:' : 'Câu hỏi:',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            if ((item.type == FlashcardItemType.textToText) ||
                                (_showAnswer && item.type == FlashcardItemType.imageToText)) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () {
                                  _speak(_showAnswer ? item.answer : item.question);
                                },
                                icon: Icon(
                                  _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                                  color: _isSpeaking ? Colors.blue : Colors.grey,
                                ),
                                tooltip: 'Nghe phát âm',
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: _buildFlashcardContent(item, !_showAnswer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_knownCards[_currentIndex])
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Đã thuộc',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardContent(FlashcardItem item, bool isQuestion) {
    if (isQuestion) {
      switch (item.type) {
        case FlashcardItemType.textToText:
          return Center(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 200,
              ),
              child: Center(
                child: Text(
                  item.question,
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        case FlashcardItemType.imageToText:
        case FlashcardItemType.imageToImage:
          return Container(
            constraints: const BoxConstraints(minHeight: 200),
            child: Column(
              children: [
                if (item.questionImage != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(
                      item.questionImage!,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (item.questionCaption != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      item.questionCaption!,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
      }
    } else {
      switch (item.type) {
        case FlashcardItemType.textToText:
        case FlashcardItemType.imageToText:
          return Center(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 200,
              ),
              child: Center(
                child: Text(
                  item.answer,
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        case FlashcardItemType.imageToImage:
          return Container(
            constraints: const BoxConstraints(minHeight: 200),
            child: Column(
              children: [
                if (item.answerImage != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(
                      item.answerImage!,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (item.answerCaption != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      item.answerCaption!,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
      }
    }
    return const SizedBox.shrink();
  }

  Widget _buildCompletionScreen() {
    final int knownCount = _knownCards.where((known) => known).length;
    final int unknownCount = _knownCards.where((known) => !known).length;
    
    return WillPopScope(
      onWillPop: () async {
        Get.back();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.flashcard.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Hoàn thành!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.check, color: Colors.green),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Đã thuộc: $knownCount thẻ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close, color: Colors.red),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Chưa thuộc: $unknownCount thẻ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Quay lại'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _restartPractice,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Luyện tập lại'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 