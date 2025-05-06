import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'unicode_utils.dart';

class ChatGPTService {
  // Singleton pattern
  static final ChatGPTService _instance = ChatGPTService._internal();
  factory ChatGPTService() => _instance;
  ChatGPTService._internal();

  final String _baseUrl = 'https://api.cohere.ai/v1/chat';
  final _secureStorage = const FlutterSecureStorage();
  bool _hasShownQuotaError = false;
  
  String _getApiKey() {
    // Hardcode API key trực tiếp cho Cohere
    return 'Jgk0MhL2B1rtGmTejEGiMJkEcJSJ6d2agAPfeT3c';
  }

  Future<String?> checkApiKey() async {
    return _getApiKey();
  }

  Future<String> fixText(String text) async {
    try {
      final apiKey = _getApiKey();
      
      print('Original text before processing: $text');
      
      // Chuẩn hóa text trước khi gửi API
      String normalizedText = UnicodeUtils.normalizeVietnameseMarks(text);
      print('After normalizeVietnameseMarks: $normalizedText');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'accept': 'application/json',
        },
        body: jsonEncode({
          'model': 'command-r-plus',
          'message': normalizedText,
          'temperature': 0.3,
        }),
      );

      print('API Response status code: ${response.statusCode}');
      print('Raw API Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Decode response body với UTF-8
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final result = data['text'] ?? text;
        print('Final processed text: $result');
        
        // Xử lý encoding cho kết quả trả về
        String processedResult = result;
        if (UnicodeUtils.hasEncodingIssues(processedResult)) {
          processedResult = UnicodeUtils.normalizeVietnameseMarks(processedResult);
        }
        
        return processedResult;
      } else {
        _handleApiError(response.statusCode, response.body);
        print('Error occurred, returning original text: $text');
        return text;
      }
    } catch (e) {
      print('Error in Cohere processing: $e');
      print('Error occurred, returning original text: $text');
      return text;
    }
  }

  Future<List<Map<String, String>>> generateFlashcards(String text) async {
    try {
      final apiKey = _getApiKey();
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'accept': 'application/json',
        },
        body: jsonEncode({
          'model': 'command-r-plus',
          'message': '''Tạo thẻ học từ văn bản này với định nghĩa ngắn gọn nhất (tối đa 50 ký tự).
          Chỉ lấy nghĩa chính, phổ biến nhất của từ.
          Định dạng phản hồi là mảng JSON với các trường "question" (từ tiếng Anh) và "answer" (nghĩa tiếng Việt).
          Ví dụ: [{"question": "hello", "answer": "xin chào"}, {"question": "book", "answer": "quyển sách"}]
          
          Đây là văn bản:
          $text''',
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        // Decode response body với UTF-8
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['text'] ?? '[]';
        
        // Debug: In ra nội dung response để kiểm tra lỗi font
        print('API Response content: ${utf8.decode(response.bodyBytes)}');
        
        try {
          // Tìm chuỗi JSON trong response
          final jsonRegex = RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true);
          final match = jsonRegex.firstMatch(content);
          
          String jsonStr;
          if (match != null) {
            jsonStr = match.group(0) ?? '[]';
          } else {
            // Thử tìm chuỗi JSON bắt đầu từ dấu [ đến ]
            final startIdx = content.indexOf('[');
            final endIdx = content.lastIndexOf(']');
            
            if (startIdx >= 0 && endIdx > startIdx) {
              jsonStr = content.substring(startIdx, endIdx + 1);
            } else {
              return _processOffline(text);
            }
          }
          
          print('JSON string to parse: $jsonStr');
          
          // Clean JSON string trước khi parse
          jsonStr = jsonStr.replaceAll('``', '"').replaceAll('`', '"');
          
          // Decode JSON string với UTF-8
          List<dynamic> rawCards = jsonDecode(jsonStr);
          print('Parsed cards: $rawCards');
          
          // Xử lý lỗi encoding cho tiếng Việt
          var cards = rawCards.map((card) {
            // Lấy văn bản tiếng Việt từ response
            String answer = card['answer'] as String? ?? '';
            
            // Sửa lỗi encoding (nếu có)
            if (UnicodeUtils.hasEncodingIssues(answer)) {
              answer = UnicodeUtils.normalizeVietnameseMarks(answer);
            }
            
            return {
              'question': card['question'] as String? ?? '',
              'answer': answer,
            };
          }).toList();
          
          // Debug: In ra một vài ví dụ về thẻ flashcard để kiểm tra font
          for (int i = 0; i < min(3, cards.length); i++) {
            print('Card $i - Question: ${cards[i]['question']}, Answer: ${cards[i]['answer']}');
          }
          
          return cards;
        } catch (jsonError) {
          print('JSON parsing error: $jsonError for content: $content');
          return _processOffline(text);
        }
      } else {
        _handleApiError(response.statusCode, response.body);
        // Fallback to offline processing if API call fails
        return _processOffline(text);
      }
    } catch (e) {
      print('Error in Cohere processing: $e');
      // Fallback to offline processing if there's an error
      return _processOffline(text);
    }
  }
  
  void _handleApiError(int statusCode, String responseBody) {
    print('Failed to call Cohere API: $statusCode - $responseBody');
    
    try {
      final errorData = jsonDecode(responseBody);
      final errorMessage = errorData['message'] ?? 'Unknown API error';
      
      // Chỉ hiển thị thông báo ngắn gọn rồi tự động chuyển sang xử lý offline
      if (statusCode == 429 && !_hasShownQuotaError) {
        _hasShownQuotaError = true;
        Get.snackbar(
          'Thông báo',
          'Đang xử lý offline do lỗi API',
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      } else if (statusCode == 401) {
        Get.snackbar(
          'Thông báo',
          'Đang xử lý offline do lỗi xác thực API',
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Error parsing API error: $e');
    }
  }
  
  List<Map<String, String>> _processOffline(String text) {
    print('Processing text offline without AI');
    return _fallbackExtraction(text);
  }
  
  List<Map<String, String>> _fallbackExtraction(String text) {
    // Extraction logic for when API calls fail
    final lines = text.split('\n');
    List<Map<String, String>> flashcards = [];
    
    // Cố gắng trích xuất từ và nghĩa từ văn bản từ điển
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Kiểm tra định dạng từ điển - tìm dòng có phiên âm và loại từ
      if (line.contains('/') && (line.contains('[n]') || line.contains('[v]'))) {
        // Trích xuất từ tiếng Anh ở đầu dòng
        String word = line.split('/').first.trim();
        
        // Trích xuất nghĩa tiếng Việt
        String meaning = "";
        
        // Cố gắng tìm nghĩa sau loại từ [n] hoặc [v]
        if (line.contains('[n]')) {
          final parts = line.split('[n]');
          if (parts.length > 1) {
            meaning = parts.last.trim();
          }
        } else if (line.contains('[v]')) {
          final parts = line.split('[v]');
          if (parts.length > 1) {
            meaning = parts.last.trim();
          }
        }
        
        // Nếu không tìm thấy trong dòng hiện tại, kiểm tra dòng tiếp theo
        if (meaning.isEmpty && i + 1 < lines.length) {
          meaning = lines[i + 1].trim();
        }
        
        // Thêm vào danh sách nếu có cả từ và nghĩa
        if (word.isNotEmpty && meaning.isNotEmpty) {
          // Chuẩn hóa từ - chuyển thành chữ thường và bỏ dấu cách thừa
          word = word.toLowerCase().trim();
          
          // Chuyển chữ cái đầu tiên thành chữ hoa
          if (word.isNotEmpty) {
            word = word[0].toUpperCase() + word.substring(1);
          }
          
          // Xử lý encoding cho nghĩa tiếng Việt
          String processedMeaning = meaning;
          if (UnicodeUtils.hasEncodingIssues(processedMeaning)) {
            processedMeaning = UnicodeUtils.normalizeVietnameseMarks(processedMeaning);
          }
          
          flashcards.add({
            'question': word,
            'answer': processedMeaning,
          });
        }
      }
    }
    
    // Nếu không tìm thấy flashcard nào, thử phương pháp khác
    if (flashcards.isEmpty) {
      // Tìm các từ dựa vào dạng thức khác - chỉ tìm các dòng bắt đầu bằng chữ cái
      RegExp englishWordRegex = RegExp(r'^[a-zA-Z]+');
      
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        final nextLine = lines[i + 1].trim();
        
        if (line.isEmpty) continue;
        
        // Kiểm tra xem dòng có bắt đầu bằng từ tiếng Anh không
        if (englishWordRegex.hasMatch(line)) {
          String word = englishWordRegex.stringMatch(line) ?? '';
          
          // Nếu dòng tiếp theo không phải là từ tiếng Anh, coi đó là nghĩa
          if (!englishWordRegex.hasMatch(nextLine)) {
            // Xử lý encoding cho nghĩa tiếng Việt
            String processedMeaning = nextLine;
            if (UnicodeUtils.hasEncodingIssues(processedMeaning)) {
              processedMeaning = UnicodeUtils.normalizeVietnameseMarks(processedMeaning);
            }
            
            flashcards.add({
              'question': word,
              'answer': processedMeaning,
            });
          }
        }
      }
    }
    
    return flashcards;
  }
}