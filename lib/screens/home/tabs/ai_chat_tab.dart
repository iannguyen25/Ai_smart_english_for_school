import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';
import '../../../services/auth_service.dart';
import '../../../services/chatgpt_service.dart';

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
  final AuthService _authService = AuthService();
  final ChatGPTService _chatGPTService = ChatGPTService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // Chủ đề hiện tại và lựa chọn
  String _currentTopic = '';
  String _currentSubTopic = '';
  bool _waitingForUserInput = false;

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
    final user = _authService.currentUser;
    String greeting = user != null 
      ? 'Chào ${user.firstName}, rất vui được gặp bạn.' 
      : 'Chào bạn, rất vui được gặp bạn.';
      
    setState(() {
      _messages.add(
        ChatMessage(
          text: '$greeting\n\nHôm nay bạn muốn trò chuyện về vấn đề gì:\n\n1. Từ vựng\n2. Ngữ pháp\n3. Dịch thuật\n4. Đọc một câu chuyện/bài báo tiếng Anh\n5. Tư vấn khóa học\n6. Hỗ trợ trung tâm',
          isUser: false,
        ),
      );
    });
  }

  void _processUserChoice(String text) {
    // Chuẩn hóa text input một lần
    final normalizedText = removeDiacritics(text.toLowerCase());
    
    // Xử lý lựa chọn chủ đề chính
    if (_currentTopic.isEmpty) {
      if (text.contains('1') || 
          normalizedText.contains('tu vung') ||
          normalizedText.contains('vocabulary')) {
        _setMainTopic('vocabulary');
      } else if (text.contains('2') || 
                normalizedText.contains('ngu phap') ||
                normalizedText.contains('grammar')) {
        _setMainTopic('grammar');
      } else if (text.contains('3') || 
                normalizedText.contains('dich thuat') ||
                normalizedText.contains('translate')) {
        _setMainTopic('translation');
      } else if (text.contains('4') || 
                normalizedText.contains('doc') ||
                normalizedText.contains('chuyen') ||
                normalizedText.contains('bao') ||
                normalizedText.contains('reading')) {
        _setMainTopic('reading');
      } else if (text.contains('5') || 
                normalizedText.contains('tu van') ||
                normalizedText.contains('khoa hoc')) {
        _setMainTopic('course-advice');
      } else if (text.contains('6') || 
                normalizedText.contains('ho tro') ||
                normalizedText.contains('trung tam')) {
        _setMainTopic('center-support');
      } else {
        _sendBotMessage('Xin lỗi, tôi không hiểu lựa chọn của bạn. Vui lòng chọn một chủ đề:\n\n1. Từ vựng\n2. Ngữ pháp\n3. Dịch thuật\n4. Đọc một câu chuyện/bài báo tiếng Anh\n5. Tư vấn khóa học\n6. Hỗ trợ trung tâm');
      }
      return;
    }
    
    // Xử lý lựa chọn chủ đề phụ
    if (_currentSubTopic.isEmpty && !_waitingForUserInput) {
      _processSubTopicChoice(text);
      return;
    }
    
    // Xử lý đầu vào của người dùng khi đang chờ
    if (_waitingForUserInput) {
      _processUserInput(text);
      return;
    }
    
    // Reset về menu chính nếu người dùng yêu cầu
    if (text.toLowerCase().contains('quay lại') || 
        text.toLowerCase().contains('menu') || 
        text.toLowerCase().contains('trở về')) {
      _resetTopics();
      _sendBotMessage('Hôm nay bạn muốn trò chuyện về vấn đề gì:\n\n1. Từ vựng\n2. Ngữ pháp\n3. Dịch thuật\n4. Đọc một câu chuyện/bài báo tiếng Anh\n5. Tư vấn khóa học\n6. Hỗ trợ trung tâm');
      return;
    }
    
    // Mặc định gửi API nếu không phải lựa chọn
    _callChatGPTAPI(text);
  }
  
  void _setMainTopic(String topic) {
    setState(() {
      _currentTopic = topic;
      _currentSubTopic = '';
    });
    
    switch (topic) {
      case 'vocabulary':
        _sendBotMessage('Bạn muốn học từ vựng về chủ đề nào:\n\n1. Gia đình\n2. Sức khỏe\n3. Tình yêu\n4. Công việc\n5. Du lịch\n6. Ẩm thực');
        break;
      case 'grammar':
        _sendBotMessage('Bạn muốn học ngữ pháp về phần nào:\n\n1. Thì (Tenses)\n2. Mạo từ (Articles)\n3. Giới từ (Prepositions)\n4. Mệnh đề quan hệ (Relative Clauses)\n5. Câu điều kiện (Conditionals)');
        break;
      case 'translation':
        _sendBotMessage('Vui lòng nhập từ hoặc cụm từ bạn muốn dịch:');
        setState(() {
          _waitingForUserInput = true;
        });
        break;
      case 'reading':
        _sendBotMessage('Bạn muốn đọc bài về chủ đề nào:\n\n1. Văn hóa\n2. Công nghệ\n3. Thể thao\n4. Giáo dục\n5. Môi trường\n6. Khoa học');
        break;
      case 'course-advice':
        _sendBotMessage('''Thông tin về Trường Anh ngữ quốc tế PoPoDoo Định Công (PoPoDoo Smart English):

📍 Thông tin cơ bản:
- Địa chỉ: Số 85, Đường Trần Nguyên Đán, Phường Định Công, Quận Hoàng Mai, Hà Nội
- Độ tuổi tuyển sinh: Từ 3-15 tuổi
- Học phí: Từ 1.650.000 VNĐ/tháng

🎯 Chương trình đào tạo:
1. Tiếng Anh mầm non (3-5 tuổi)
2. Tiếng Anh tiểu học (6-10 tuổi)
3. Tiếng Anh thiếu niên (11-15 tuổi)

🌟 Điểm nổi bật:
- Hơn 10 năm kinh nghiệm giảng dạy tiếng Anh cho trẻ em
- Chương trình theo tiêu chuẩn Cambridge
- Môi trường học tập đa phương tiện "Hear, Say, See, Do"
- Đội ngũ giáo viên Việt Nam và nước ngoài đạt chuẩn sư phạm
- Cơ sở vật chất hiện đại, phù hợp với trẻ em

Bạn muốn tìm hiểu thêm về khóa học nào? Hoặc bạn có thể cho tôi biết:
- Độ tuổi của học viên
- Mục tiêu học tập
- Thời gian học mong muốn
để tôi có thể tư vấn khóa học phù hợp.''');
        setState(() {
          _waitingForUserInput = true;
        });
        break;
      case 'center-support':
        _sendBotMessage('''Thông tin liên hệ và hỗ trợ:

1. Thông tin chung
2. Lịch học và học phí
3. Đăng ký học thử
4. Tư vấn lộ trình học
5. Liên hệ trực tiếp

📍 Thông tin liên hệ:
- Địa chỉ: Số 85, Đường Trần Nguyên Đán, Phường Định Công, Quận Hoàng Mai, Hà Nội
- Học phí: Từ 1.650.000 VNĐ/tháng
- Độ tuổi: 3-15 tuổi
- Chương trình: Theo tiêu chuẩn Cambridge

Vui lòng chọn mục bạn cần hỗ trợ hoặc nhập câu hỏi cụ thể.''');
        setState(() {
          _waitingForUserInput = true;
        });
        break;
    }
  }
  
  void _processSubTopicChoice(String text) {
    // Chuẩn hóa text input một lần
    final normalizedText = removeDiacritics(text.toLowerCase());
    
    if (_currentTopic == 'vocabulary') {
      if (text.contains('1') || 
          normalizedText.contains('gia dinh') ||
          normalizedText.contains('family')) {
        _setSubTopic('family');
      } else if (text.contains('2') || 
                normalizedText.contains('suc khoe') ||
                normalizedText.contains('health')) {
        _setSubTopic('health');
      } else if (text.contains('3') || 
                normalizedText.contains('tinh yeu') ||
                normalizedText.contains('love')) {
        _setSubTopic('love');
      } else if (text.contains('4') || 
                normalizedText.contains('cong viec') ||
                normalizedText.contains('work')) {
        _setSubTopic('work');
      } else if (text.contains('5') || 
                normalizedText.contains('du lich') ||
                normalizedText.contains('travel')) {
        _setSubTopic('travel');
      } else if (text.contains('6') || 
                normalizedText.contains('am thuc') ||
                normalizedText.contains('food')) {
        _setSubTopic('food');
      } else {
        _sendBotMessage('Xin lỗi, tôi không hiểu lựa chọn của bạn. Vui lòng chọn một chủ đề từ vựng hợp lệ (1-6).');
      }
    } else if (_currentTopic == 'grammar') {
      if (text.contains('1') || 
          normalizedText.contains('thi') ||
          normalizedText.contains('tenses')) {
        _setSubTopic('tenses');
      } else if (text.contains('2') || 
                normalizedText.contains('mao tu') ||
                normalizedText.contains('articles')) {
        _setSubTopic('articles');
      } else if (text.contains('3') || 
                normalizedText.contains('gioi tu') ||
                normalizedText.contains('prepositions')) {
        _setSubTopic('prepositions');
      } else if (text.contains('4') || 
                normalizedText.contains('menh de quan he') ||
                normalizedText.contains('relative')) {
        _setSubTopic('relative-clauses');
      } else if (text.contains('5') || 
                normalizedText.contains('cau dieu kien') ||
                normalizedText.contains('conditionals')) {
        _setSubTopic('conditionals');
      } else {
        _sendBotMessage('Xin lỗi, tôi không hiểu lựa chọn của bạn. Vui lòng chọn một chủ đề ngữ pháp hợp lệ (1-5).');
      }
    } else if (_currentTopic == 'reading') {
      if (text.contains('1') || 
          normalizedText.contains('van hoa') ||
          normalizedText.contains('culture')) {
        _setSubTopic('culture');
      } else if (text.contains('2') || 
                normalizedText.contains('cong nghe') ||
                normalizedText.contains('technology')) {
        _setSubTopic('technology');
      } else if (text.contains('3') || 
                normalizedText.contains('the thao') ||
                normalizedText.contains('sports')) {
        _setSubTopic('sports');
      } else if (text.contains('4') || 
                normalizedText.contains('giao duc') ||
                normalizedText.contains('education')) {
        _setSubTopic('education');
      } else if (text.contains('5') || 
                normalizedText.contains('moi truong') ||
                normalizedText.contains('environment')) {
        _setSubTopic('environment');
      } else if (text.contains('6') || 
                normalizedText.contains('khoa hoc') ||
                normalizedText.contains('science')) {
        _setSubTopic('science');
      } else {
        _sendBotMessage('Xin lỗi, tôi không hiểu lựa chọn của bạn. Vui lòng chọn một chủ đề đọc hợp lệ (1-6).');
      }
    }
  }
  
  void _setSubTopic(String subTopic) {
    setState(() {
      _currentSubTopic = subTopic;
    });
    
    _callChatGPTWithTopic();
  }
  
  void _processUserInput(String text) {
    // Chỉ reset waiting state cho các chủ đề không phải tư vấn/hỗ trợ
    if (_currentTopic != 'course-advice' && _currentTopic != 'center-support') {
      setState(() {
        _waitingForUserInput = false;
      });
    }
    
    if (_currentTopic == 'translation') {
      _getTranslation(text);
    } else if (_currentTopic == 'course-advice') {
      _getCourseAdvice(text);
    } else if (_currentTopic == 'center-support') {
      _getCenterSupport(text);
    } else {
      _callChatGPTAPI(text);
    }
  }
  
  void _getTranslation(String text) {
    _callChatGPTAPI("Dịch từ sau sang tiếng Việt, cho biết loại từ (N, V, ADJ...) và 2 ví dụ sử dụng khác nhau: \"$text\"");
  }
  
  void _getCourseAdvice(String text) {
    String prompt = '''Bạn là nhân viên tư vấn khóa học của Trường Anh ngữ quốc tế PoPoDoo Định Công. 
    Dựa trên thông tin sau:
    - Địa chỉ: Số 85, Đường Trần Nguyên Đán, Phường Định Công, Quận Hoàng Mai, Hà Nội
    - Học phí: Từ 1.650.000 VNĐ/tháng
    - Độ tuổi: 3-15 tuổi
    
    Chương trình đào tạo:
    1. Tiếng Anh mầm non (3-5 tuổi)
    2. Tiếng Anh tiểu học (6-10 tuổi)
    3. Tiếng Anh thiếu niên (11-15 tuổi)
    
    Điểm nổi bật:
    - Hơn 10 năm kinh nghiệm
    - Chương trình Cambridge
    - Môi trường học tập đa phương tiện
    - Giáo viên Việt Nam và nước ngoài
    - Cơ sở vật chất hiện đại
    
    Hãy tư vấn khóa học phù hợp dựa trên yêu cầu của học viên: "$text"
    Trả lời ngắn gọn, tập trung vào khóa học phù hợp nhất và lý do chọn khóa học đó.''';
    
    _callChatGPTAPI(prompt);
  }

  void _getCenterSupport(String text) {
    String prompt = '''Bạn là nhân viên hỗ trợ của Trường Anh ngữ quốc tế PoPoDoo Định Công.
    Dựa trên thông tin sau:
    - Địa chỉ: Số 85, Đường Trần Nguyên Đán, Phường Định Công, Quận Hoàng Mai, Hà Nội
    - Học phí: Từ 1.650.000 VNĐ/tháng
    - Độ tuổi: 3-15 tuổi
    - Chương trình: Theo tiêu chuẩn Cambridge
    - Điểm nổi bật: Hơn 10 năm kinh nghiệm, giáo viên đạt chuẩn, cơ sở vật chất hiện đại
    
    Hãy trả lời câu hỏi của học viên: "$text"
    Trả lời ngắn gọn, chính xác và hữu ích.''';
    
    _callChatGPTAPI(prompt);
  }
  
  void _callChatGPTWithTopic() {
    String prompt = '';
    
    if (_currentTopic == 'vocabulary') {
      String topicName = _getTopicDisplayName(_currentSubTopic);
      prompt = "Cho tôi 15 từ vựng tiếng Anh thông dụng về chủ đề $topicName. Hiển thị dưới dạng danh sách với định dạng: từ tiếng Anh (loại từ) - nghĩa tiếng Việt. Chỉ liệt kê các từ, không cần giải thích thêm.";
    } else if (_currentTopic == 'grammar') {
      String topicName = _getTopicDisplayName(_currentSubTopic);
      prompt = "Giải thích ngữ pháp tiếng Anh về $topicName. Bao gồm: định nghĩa, cách sử dụng, các quy tắc quan trọng và 3-5 ví dụ cụ thể với nghĩa tiếng Việt. Trả lời bằng tiếng Việt.";
    } else if (_currentTopic == 'reading') {
      String topicName = _getTopicDisplayName(_currentSubTopic);
      prompt = "Viết một đoạn văn tiếng Anh khoảng 100-150 từ về chủ đề $topicName. Sau đó dịch sang tiếng Việt. Định dạng: đoạn văn tiếng Anh trước, sau đó là dịch nghĩa tiếng Việt.";
    }
    
    _callChatGPTAPI(prompt);
  }
  
  String _getTopicDisplayName(String topic) {
    switch (topic) {
      case 'family': return 'gia đình';
      case 'health': return 'sức khỏe';
      case 'love': return 'tình yêu';
      case 'work': return 'công việc';
      case 'travel': return 'du lịch';
      case 'food': return 'ẩm thực';
      case 'tenses': return 'thì (tenses)';
      case 'articles': return 'mạo từ (articles)';
      case 'prepositions': return 'giới từ (prepositions)';
      case 'relative-clauses': return 'mệnh đề quan hệ (relative clauses)';
      case 'conditionals': return 'câu điều kiện (conditionals)';
      case 'culture': return 'văn hóa';
      case 'technology': return 'công nghệ';
      case 'sports': return 'thể thao';
      case 'education': return 'giáo dục';
      case 'environment': return 'môi trường';
      case 'science': return 'khoa học';
      default: return topic;
    }
  }
  
  void _resetTopics() {
    setState(() {
      _currentTopic = '';
      _currentSubTopic = '';
      _waitingForUserInput = false;
    });
  }

  Future<void> _callChatGPTAPI(String text) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Tạo prompt với hướng dẫn ngôn ngữ
      String finalPrompt = "Bạn là trợ lý học tiếng Anh. Trả lời bằng tiếng Việt. Chỉ hỗ trợ các chủ đề liên quan đến việc học tiếng Anh, từ chối các câu hỏi về chủ đề khác. Luôn trả lời đơn giản, dễ hiểu và đúng trọng tâm. Dưới đây là yêu cầu của tôi:\n\n$text";
      
      // Gọi API Cohere thông qua ChatGPT Service
      String response = await _chatGPTService.fixText(finalPrompt);
      
      // Hiển thị kết quả
      _sendBotMessage(response);
      
      // Set waiting state based on current topic
      setState(() {
        _waitingForUserInput = _currentTopic == 'course-advice' || _currentTopic == 'center-support';
      });
    } catch (e) {
      print("Error calling ChatGPT API: $e");
      _sendBotMessage("Xin lỗi, tôi đang gặp sự cố kết nối. Vui lòng thử lại sau.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _sendBotMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(text: message, isUser: false));
    });
    _scrollToBottom();
  }
  
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });

    _scrollToBottom();
    _processUserChoice(text);
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
                  _resetTopics();
                  _addInitialMessage();
                });
              } else if (value == 'menu') {
                _resetTopics();
                _sendBotMessage('Hôm nay bạn muốn trò chuyện về vấn đề gì:\n\n1. Từ vựng\n2. Ngữ pháp\n3. Dịch thuật\n4. Đọc một câu chuyện/bài báo tiếng Anh\n5. Tư vấn khóa học\n6. Hỗ trợ trung tâm');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Xóa cuộc trò chuyện'),
              ),
              const PopupMenuItem(
                value: 'menu',
                child: Text('Quay lại menu chính'),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Nhập câu hỏi hoặc lựa chọn...',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _isLoading ? null : _handleSubmitted,
            ),
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