import 'package:flutter/material.dart';
// import '../../../services/auth_service.dart';
// import '../../../services/ai_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIChatTab extends StatefulWidget {
  @override
  _AIChatTabState createState() => _AIChatTabState();
}

class _AIChatTabState extends State<AIChatTab> {
  // final AuthService _authService = AuthService();
  // final AIService _aiService = AIService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _currentTopic = '';
  int _conversationDepth = 0;
  List<String> _conversationHistory = [];
  static const int MAX_HISTORY = 5;

  @override
  void initState() {
    super.initState();
    _addInitialMessage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addInitialMessage() {
    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Hello! I\'m your AI language tutor. How can I help you practice English today?',
          isUser: false,
        ),
      );
    });
  }

  void _updateConversationState(String text, String response) {
    setState(() {
      _conversationHistory.add(text);
      if (_conversationHistory.length > MAX_HISTORY) {
        _conversationHistory.removeAt(0);
      }
      
      // Cập nhật chủ đề hiện tại
      if (text.toLowerCase().contains('tu vung') || 
          text.toLowerCase().contains('từ vựng') ||
          text.toLowerCase().contains('vocabulary')) {
        _currentTopic = 'vocabulary';
        _conversationDepth = 1;
      } else if (text.toLowerCase().contains('ngu phap') ||
                 text.toLowerCase().contains('ngữ pháp') ||
                 text.toLowerCase().contains('grammar')) {
        _currentTopic = 'grammar';
        _conversationDepth = 1;
      } else if (text.toLowerCase().contains('dich') ||
                 text.toLowerCase().contains('dịch') ||
                 text.toLowerCase().contains('translate')) {
        _currentTopic = 'translation';
        _conversationDepth = 1;
      } else if (text.toLowerCase().contains('luyen noi') ||
                 text.toLowerCase().contains('luyện nói') ||
                 text.toLowerCase().contains('speaking')) {
        _currentTopic = 'speaking';
        _conversationDepth = 1;
      } else if (text.toLowerCase().contains('luyen viet') ||
                 text.toLowerCase().contains('luyện viết') ||
                 text.toLowerCase().contains('writing')) {
        _currentTopic = 'writing';
        _conversationDepth = 1;
      } else if (text.toLowerCase().contains('phat am') ||
                 text.toLowerCase().contains('phát âm') ||
                 text.toLowerCase().contains('pronunciation')) {
        _currentTopic = 'pronunciation';
        _conversationDepth = 1;
      } else if (text.toLowerCase().contains('menu') ||
                 text.toLowerCase().contains('chính') ||
                 text.toLowerCase().contains('main')) {
        _currentTopic = '';
        _conversationDepth = 0;
      } else if (_currentTopic.isNotEmpty) {
        _conversationDepth++;
      }
    });
  }

  String _getContextualResponse(String text) {
    final lowercaseText = text.toLowerCase();
    
    // Xử lý yêu cầu quay lại menu chính
    if (lowercaseText.contains('menu') ||
        lowercaseText.contains('chính') ||
        lowercaseText.contains('main')) {
      _currentTopic = '';
      _conversationDepth = 0;
      return 'Bạn có thể hỏi tôi về:\n\n1. Từ vựng tiếng Anh\n2. Ngữ pháp\n3. Dịch thuật\n4. Luyện nói\n5. Luyện viết\n6. Phát âm\n\nBạn muốn học về chủ đề nào?';
    }

    // Xử lý theo ngữ cảnh hiện tại
    if (_currentTopic.isNotEmpty && _conversationDepth > 2) {
      switch (_currentTopic) {
        case 'vocabulary':
          return _getDetailedVocabularyResponse(text);
        case 'grammar':
          return _getDetailedGrammarResponse(text);
        case 'translation':
          return _getDetailedTranslationResponse(text);
        case 'speaking':
          return _getDetailedSpeakingResponse(text);
        case 'writing':
          return _getDetailedWritingResponse(text);
        case 'pronunciation':
          return _getDetailedPronunciationResponse(text);
      }
    }

    // Xử lý fall-back thông minh
    if (_currentTopic.isNotEmpty) {
      return _getSmartFallbackResponse(text);
    }

    return _getSimulatedResponse(text);
  }

  String _getDetailedVocabularyResponse(String text) {
    final lowercaseText = text.toLowerCase();
    
    // Xử lý các câu hỏi sâu về từ vựng
    if (lowercaseText.contains('vi du') || lowercaseText.contains('ví dụ')) {
      return 'Ví dụ chi tiết về cách sử dụng từ vựng:\n\n1. Trong câu đơn:\n   - "The beautiful sunset painted the sky in vibrant colors"\n   - "She gracefully danced across the stage"\n   - "The ancient castle stood majestically on the hill"\n\n2. Trong câu phức:\n   - "Although it was raining heavily, we decided to go for a walk"\n   - "The book, which was written by a famous author, became a bestseller"\n   - "When the sun sets, the city lights begin to glow"\n\n3. Trong thành ngữ:\n   - "Break a leg" (Chúc may mắn)\n   - "Piece of cake" (Dễ như ăn bánh)\n   - "Hit the books" (Học bài)\n\nBạn muốn:\n1. Xem thêm ví dụ\n2. Học về cách sử dụng từ vựng\n3. Quay lại menu chính';
    } else if (lowercaseText.contains('cach su dung') || lowercaseText.contains('cách sử dụng')) {
      return 'Cách sử dụng từ vựng hiệu quả:\n\n1. Học từ vựng theo ngữ cảnh:\n   - Đọc sách, báo, tạp chí\n   - Xem phim, nghe nhạc\n   - Giao tiếp với người bản ngữ\n\n2. Ghi nhớ từ vựng:\n   - Sử dụng flashcards\n   - Tạo mindmap\n   - Viết nhật ký\n\n3. Luyện tập:\n   - Viết câu với từ mới\n   - Nói chuyện sử dụng từ mới\n   - Làm bài tập từ vựng\n\nBạn muốn:\n1. Xem ví dụ cụ thể\n2. Học thêm phương pháp\n3. Quay lại menu chính';
    }
    
    return _getSimulatedResponse(text);
  }

  String _getDetailedGrammarResponse(String text) {
    final lowercaseText = text.toLowerCase();
    
    if (lowercaseText.contains('vi du') || lowercaseText.contains('ví dụ')) {
      return 'Ví dụ chi tiết về ngữ pháp:\n\n1. Thì hiện tại đơn:\n   - "I go to school every day"\n   - "She works in a hospital"\n   - "They live in London"\n\n2. Thì hiện tại tiếp diễn:\n   - "I am studying now"\n   - "She is working on a project"\n   - "They are playing football"\n\n3. Thì quá khứ đơn:\n   - "I went to school yesterday"\n   - "She worked late last night"\n   - "They lived in Paris"\n\nBạn muốn:\n1. Xem thêm ví dụ\n2. Học về cách sử dụng thì\n3. Quay lại menu chính';
    } else if (lowercaseText.contains('cach su dung') || lowercaseText.contains('cách sử dụng')) {
      return 'Cách sử dụng ngữ pháp hiệu quả:\n\n1. Hiểu rõ cấu trúc:\n   - Học công thức\n   - Nhận biết dấu hiệu\n   - Phân biệt các thì\n\n2. Luyện tập:\n   - Làm bài tập\n   - Viết câu\n   - Nói chuyện\n\n3. Ứng dụng:\n   - Đọc sách\n   - Xem phim\n   - Giao tiếp\n\nBạn muốn:\n1. Xem ví dụ cụ thể\n2. Học thêm phương pháp\n3. Quay lại menu chính';
    }
    
    return _getSimulatedResponse(text);
  }

  String _getDetailedTranslationResponse(String text) {
    final lowercaseText = text.toLowerCase();
    
    if (lowercaseText.contains('vi du') || lowercaseText.contains('ví dụ')) {
      return 'Ví dụ về dịch thuật:\n\n1. Dịch câu đơn:\n   - "Tôi đi học" → "I go to school"\n   - "Cô ấy đang làm việc" → "She is working"\n   - "Họ sống ở London" → "They live in London"\n\n2. Dịch câu phức:\n   - "Mặc dù trời mưa, chúng tôi vẫn đi dạo" → "Although it was raining, we still went for a walk"\n   - "Cuốn sách, được viết bởi một tác giả nổi tiếng, đã trở thành bestseller" → "The book, which was written by a famous author, became a bestseller"\n\n3. Dịch thành ngữ:\n   - "Chúc may mắn" → "Break a leg"\n   - "Dễ như ăn bánh" → "Piece of cake"\n   - "Học bài" → "Hit the books"\n\nBạn muốn:\n1. Xem thêm ví dụ\n2. Học về cách dịch\n3. Quay lại menu chính';
    } else if (lowercaseText.contains('cach dich') || lowercaseText.contains('cách dịch')) {
      return 'Cách dịch thuật hiệu quả:\n\n1. Hiểu ngữ cảnh:\n   - Đọc kỹ văn bản\n   - Xác định mục đích\n   - Nắm bắt ý chính\n\n2. Kỹ thuật dịch:\n   - Dịch từng câu\n   - Dịch theo đoạn\n   - Dịch theo ý\n\n3. Kiểm tra:\n   - So sánh với bản gốc\n   - Kiểm tra ngữ pháp\n   - Kiểm tra từ vựng\n\nBạn muốn:\n1. Xem ví dụ cụ thể\n2. Học thêm phương pháp\n3. Quay lại menu chính';
    }
    
    return _getSimulatedResponse(text);
  }

  String _getDetailedSpeakingResponse(String text) {
    final lowercaseText = text.toLowerCase();
    
    if (lowercaseText.contains('vi du') || lowercaseText.contains('ví dụ')) {
      return 'Ví dụ về luyện nói:\n\n1. Hội thoại hàng ngày:\n   - "How are you?" - "I\'m fine, thank you"\n   - "What do you do?" - "I\'m a student"\n   - "Where are you from?" - "I\'m from Vietnam"\n\n2. Thuyết trình:\n   - "Today, I will talk about..."\n   - "First, let me explain..."\n   - "In conclusion, I would like to..."\n\n3. Phỏng vấn:\n   - "Tell me about yourself"\n   - "What are your strengths?"\n   - "Where do you see yourself in 5 years?"\n\nBạn muốn:\n1. Xem thêm ví dụ\n2. Học về cách nói\n3. Quay lại menu chính';
    } else if (lowercaseText.contains('cach noi') || lowercaseText.contains('cách nói')) {
      return 'Cách luyện nói hiệu quả:\n\n1. Phát âm:\n   - Luyện âm\n   - Luyện ngữ điệu\n   - Luyện nhịp điệu\n\n2. Từ vựng:\n   - Học từ mới\n   - Sử dụng từ vựng\n   - Mở rộng vốn từ\n\n3. Ngữ pháp:\n   - Sử dụng đúng thì\n   - Sử dụng đúng cấu trúc\n   - Sử dụng đúng từ loại\n\nBạn muốn:\n1. Xem ví dụ cụ thể\n2. Học thêm phương pháp\n3. Quay lại menu chính';
    }
    
    return _getSimulatedResponse(text);
  }

  String _getDetailedWritingResponse(String text) {
    final lowercaseText = text.toLowerCase();
    
    if (lowercaseText.contains('vi du') || lowercaseText.contains('ví dụ')) {
      return 'Ví dụ về luyện viết:\n\n1. Email:\n   - "Dear Mr. Smith,"\n   - "I am writing to inform you..."\n   - "Best regards,"\n\n2. Bài luận:\n   - Introduction: Giới thiệu chủ đề\n   - Body: Phát triển ý\n   - Conclusion: Kết luận\n\n3. Báo cáo:\n   - Executive Summary\n   - Introduction\n   - Findings\n   - Conclusion\n\nBạn muốn:\n1. Xem thêm ví dụ\n2. Học về cách viết\n3. Quay lại menu chính';
    } else if (lowercaseText.contains('cach viet') || lowercaseText.contains('cách viết')) {
      return 'Cách luyện viết hiệu quả:\n\n1. Cấu trúc:\n   - Mở bài\n   - Thân bài\n   - Kết bài\n\n2. Nội dung:\n   - Ý tưởng\n   - Luận điểm\n   - Dẫn chứng\n\n3. Ngôn ngữ:\n   - Từ vựng\n   - Ngữ pháp\n   - Văn phong\n\nBạn muốn:\n1. Xem ví dụ cụ thể\n2. Học thêm phương pháp\n3. Quay lại menu chính';
    }
    
    return _getSimulatedResponse(text);
  }

  String _getDetailedPronunciationResponse(String text) {
    final lowercaseText = text.toLowerCase();
    
    if (lowercaseText.contains('vi du') || lowercaseText.contains('ví dụ')) {
      return 'Ví dụ về phát âm:\n\n1. Nguyên âm:\n   - /i:/ as in "see"\n   - /ɪ/ as in "sit"\n   - /e/ as in "bed"\n\n2. Phụ âm:\n   - /p/ as in "pen"\n   - /b/ as in "bed"\n   - /t/ as in "ten"\n\n3. Trọng âm:\n   - "REcord" (noun)\n   - "reCORD" (verb)\n   - "PHOtograph"\n\nBạn muốn:\n1. Xem thêm ví dụ\n2. Học về cách phát âm\n3. Quay lại menu chính';
    } else if (lowercaseText.contains('cach phat am') || lowercaseText.contains('cách phát âm')) {
      return 'Cách luyện phát âm hiệu quả:\n\n1. Nguyên âm:\n   - Mở miệng\n   - Đặt lưỡi\n   - Phát âm\n\n2. Phụ âm:\n   - Môi\n   - Lưỡi\n   - Hơi\n\n3. Trọng âm:\n   - Nhấn mạnh\n   - Lên giọng\n   - Xuống giọng\n\nBạn muốn:\n1. Xem ví dụ cụ thể\n2. Học thêm phương pháp\n3. Quay lại menu chính';
    }
    
    return _getSimulatedResponse(text);
  }

  String _getSmartFallbackResponse(String text) {
    // Phân tích câu hỏi và đưa ra câu trả lời liên quan đến chủ đề hiện tại
    final lowercaseText = text.toLowerCase();
    
    if (_currentTopic == 'vocabulary') {
      if (lowercaseText.contains('nghia') || lowercaseText.contains('nghĩa')) {
        return 'Bạn đang muốn tìm hiểu về nghĩa của từ. Tôi có thể giúp bạn:\n\n1. Giải thích nghĩa của từ\n2. Đưa ra ví dụ sử dụng\n3. Chỉ ra các từ đồng nghĩa/trái nghĩa\n\nBạn muốn tìm hiểu về từ nào?';
      } else if (lowercaseText.contains('cach hoc') || lowercaseText.contains('cách học')) {
        return 'Để học từ vựng hiệu quả, bạn có thể:\n\n1. Học theo chủ đề\n2. Sử dụng flashcards\n3. Luyện tập thường xuyên\n4. Áp dụng vào thực tế\n\nBạn muốn tìm hiểu thêm về phương pháp nào?';
      }
    }
    
    return 'Tôi hiểu bạn đang nói về chủ đề $_currentTopic. Bạn có thể:\n\n1. Hỏi cụ thể hơn về chủ đề này\n2. Chuyển sang chủ đề khác\n3. Quay lại menu chính\n\nBạn muốn làm gì tiếp theo?';
  }

  String _getSimulatedResponse(String text) {
    final lowercaseText = text.toLowerCase();

    // Xử lý các từ khóa tiếng Việt có dấu và không dấu
    if (lowercaseText.contains('xin chao') ||
        lowercaseText.contains('xin chào') ||
        lowercaseText.contains('chao') ||
        lowercaseText.contains('chào') ||
        lowercaseText.contains('hi')) {
      return 'Xin chào! Bạn có thể hỏi tôi về:\n- Từ vựng tiếng Anh\n- Ngữ pháp\n- Dịch thuật\n- Luyện nói\n- Luyện viết';
    } else if (lowercaseText.contains('tu vung') ||
        lowercaseText.contains('từ vựng') ||
        lowercaseText.contains('vocabulary')) {
      return 'Tôi có thể giúp bạn học từ vựng theo các chủ đề:\n\n1. Từ vựng cơ bản\n2. Từ vựng chuyên ngành\n3. Từ vựng theo cấp độ (A1-C2)\n4. Từ vựng theo chủ đề\n\nBạn muốn học từ vựng về chủ đề nào?';
    } else if (lowercaseText.contains('ngu phap') ||
        lowercaseText.contains('ngữ pháp') ||
        lowercaseText.contains('grammar')) {
      return 'Tôi có thể giúp bạn học ngữ pháp về:\n\n1. Các thì trong tiếng Anh\n2. Cấu trúc câu\n3. Mệnh đề quan hệ\n4. Câu điều kiện\n5. Câu bị động\n\nBạn muốn học phần ngữ pháp nào?';
    } else if (lowercaseText.contains('dich') ||
        lowercaseText.contains('dịch') ||
        lowercaseText.contains('translate')) {
      return 'Tôi có thể giúp bạn dịch:\n\n1. Từ tiếng Việt sang tiếng Anh\n2. Từ tiếng Anh sang tiếng Việt\n3. Đoạn văn\n4. Câu thành ngữ\n\nBạn muốn dịch gì?';
    } else if (lowercaseText.contains('luyen noi') ||
        lowercaseText.contains('luyện nói') ||
        lowercaseText.contains('speaking')) {
      return 'Tôi có thể giúp bạn luyện nói về:\n\n1. Giao tiếp hàng ngày\n2. Thuyết trình\n3. Phỏng vấn\n4. Thảo luận\n\nBạn muốn luyện nói về chủ đề nào?';
    } else if (lowercaseText.contains('luyen viet') ||
        lowercaseText.contains('luyện viết') ||
        lowercaseText.contains('writing')) {
      return 'Tôi có thể giúp bạn luyện viết:\n\n1. Email\n2. Bài luận\n3. Báo cáo\n4. CV\n\nBạn muốn luyện viết dạng nào?';
    } else if (lowercaseText.contains('phat am') ||
        lowercaseText.contains('phát âm') ||
        lowercaseText.contains('pronunciation')) {
      return 'Tôi có thể giúp bạn luyện phát âm:\n\n1. Nguyên âm (Vowels)\n2. Phụ âm (Consonants)\n3. Trọng âm (Stress)\n4. Ngữ điệu (Intonation)\n\nBạn muốn luyện phần phát âm nào?';
    } else if (lowercaseText.contains('cam on') ||
        lowercaseText.contains('cảm ơn') ||
        lowercaseText.contains('thank')) {
      return 'Không có gì! Tôi rất vui được giúp bạn. Bạn có thể hỏi tôi bất cứ điều gì về tiếng Anh.';
    } else if (lowercaseText.contains('tam biet') ||
        lowercaseText.contains('tạm biệt') ||
        lowercaseText.contains('goodbye')) {
      return 'Tạm biệt! Hẹn gặp lại bạn trong buổi học tiếp theo. Chúc bạn học tốt!';
    } else {
      return 'Tôi có thể giúp gì cho bạn? Bạn có thể hỏi tôi về:\n- Từ vựng\n- Ngữ pháp\n- Dịch thuật\n- Luyện nói\n- Luyện viết\n- Phát âm';
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final randomDelay = Duration(milliseconds: 1000 + (DateTime.now().millisecond % 2000));
      await Future.delayed(randomDelay);

      setState(() {
        _messages.add(ChatMessage(text: '...', isUser: false));
      });
      _scrollToBottom();
      
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _messages.removeLast();
      });

      final response = _getContextualResponse(text);
      _updateConversationState(text, response);

      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Xin lỗi, tôi gặp lỗi: ${e.toString()}',
          isUser: false,
        ));
        _isLoading = false;
      });

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Language Tutor'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                setState(() {
                  _messages.clear();
                  _addInitialMessage();
                });
              } else if (value == 'settings') {
                // Navigate to chat settings
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear conversation'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Chat settings'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: LinearProgressIndicator(),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
          if (!message.isUser) const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 12),
          if (message.isUser)
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              // Implement voice input
            },
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Nhập câu hỏi...',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _isLoading ? null : _handleSubmitted,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () {
              // Implement translation feature
            },
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isLoading
                ? null
                : () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }
}