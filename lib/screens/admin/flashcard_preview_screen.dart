import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/flashcard_service.dart';
import '../../models/flashcard.dart';
import '../../models/flashcard_item.dart';

class FlashcardPreviewScreen extends StatefulWidget {
  final String flashcardId;

  const FlashcardPreviewScreen({
    Key? key,
    required this.flashcardId,
  }) : super(key: key);

  @override
  _FlashcardPreviewScreenState createState() => _FlashcardPreviewScreenState();
}

class _FlashcardPreviewScreenState extends State<FlashcardPreviewScreen> {
  final FlashcardService _flashcardService = FlashcardService();
  bool _isLoading = true;
  Flashcard? _flashcard;
  List<FlashcardItem> _items = [];
  int _currentIndex = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _loadFlashcardData();
  }

  Future<void> _loadFlashcardData() async {
    try {
      final flashcard = await _flashcardService.getFlashcardById(widget.flashcardId);
      if (flashcard != null) {
        final items = await _flashcardService.getFlashcardItems(widget.flashcardId);
        setState(() {
          _flashcard = flashcard;
          _items = items;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading flashcard data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _nextCard() {
    if (_currentIndex < _items.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    }
  }

  void _previousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showAnswer = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xem trước Flashcard'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _flashcard == null
              ? Center(
                  child: Text(
                    'Không tìm thấy flashcard',
                    style: TextStyle(color: Colors.black87),
                  ),
                )
              : Column(
                  children: [
                    // Thông tin flashcard
                    Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _flashcard!.title,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (_flashcard!.userId != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_flashcard!.userId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                                  return Text(
                                    'Tác giả: ${userData['firstName']} ${userData['lastName']}',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  );
                                }
                                return SizedBox();
                              },
                            ),
                        ],
                      ),
                    ),

                    // Nội dung flashcard
                    Expanded(
                      child: _items.isEmpty
                          ? Center(
                              child: Text(
                                'Không có thẻ nào',
                                style: TextStyle(color: Colors.black87),
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showAnswer = !_showAnswer;
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.all(16),
                                      padding: EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          _showAnswer
                                              ? _items[_currentIndex].answer
                                              : _items[_currentIndex].question,
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 20,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: _currentIndex > 0 ? _previousCard : null,
                                        icon: Icon(Icons.arrow_back),
                                        label: Text('Thẻ trước'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: _currentIndex > 0
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        '${_currentIndex + 1}/${_items.length}',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 16,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _currentIndex < _items.length - 1
                                            ? _nextCard
                                            : null,
                                        icon: Icon(Icons.arrow_forward),
                                        label: Text('Thẻ sau'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: _currentIndex < _items.length - 1
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ),
                                    ],
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