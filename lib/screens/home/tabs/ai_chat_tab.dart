import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../services/ai_service.dart';

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
  final AIService _aiService = AIService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

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

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    
    _scrollToBottom();

    try {
      // In a real app, this would call the AI service
      // For now, we'll simulate a response
      final userId = _authService.currentUser?.id ?? 'anonymous';
      
      // Uncomment this in a real implementation
      // final interaction = await _aiService.generateResponse(
      //   userId: userId,
      //   prompt: text,
      // );
      // final response = interaction.response;
      
      // Simulated response for demo
      await Future.delayed(const Duration(seconds: 1));
      final response = _getSimulatedResponse(text);

      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error: ${e.toString()}',
          isUser: false,
        ));
        _isLoading = false;
      });
      
      _scrollToBottom();
    }
  }

  String _getSimulatedResponse(String text) {
    final lowercaseText = text.toLowerCase();
    
    if (lowercaseText.contains('hello') || 
        lowercaseText.contains('hi') || 
        lowercaseText.contains('hey')) {
      return 'Hello! How are you doing today? Would you like to practice conversation, vocabulary, or grammar?';
    } else if (lowercaseText.contains('vocabulary')) {
      return 'Great! Let\'s practice some vocabulary. Here are some words related to technology:\n\n- Artificial Intelligence: The simulation of human intelligence in machines\n- Machine Learning: A subset of AI that enables systems to learn from data\n- Algorithm: A step-by-step procedure for solving a problem\n\nCan you use one of these words in a sentence?';
    } else if (lowercaseText.contains('grammar')) {
      return 'Let\'s work on grammar! One common mistake is confusing "its" and "it\'s". Remember:\n\n- "its" is possessive (The dog wagged its tail)\n- "it\'s" is a contraction of "it is" (It\'s raining today)\n\nCan you create a sentence using both correctly?';
    } else if (lowercaseText.contains('translate')) {
      return 'I can help with translations. For example, "Hello" in Spanish is "Hola", in French it\'s "Bonjour", and in German it\'s "Hallo". What would you like to translate?';
    } else {
      return 'That\'s interesting! Would you like to practice speaking about this topic? I can help with vocabulary, grammar, or pronunciation. Just let me know what you\'d like to focus on.';
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
                hintText: 'Type a message...',
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