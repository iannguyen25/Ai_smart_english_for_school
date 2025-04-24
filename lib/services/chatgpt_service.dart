import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'vietnamese_encoding_maps.dart';

class ChatGPTService {
  final String _baseUrl = 'https://api.cohere.ai/v1/chat';
  final _secureStorage = const FlutterSecureStorage();
  bool _hasShownQuotaError = false;
  
  ChatGPTService();
  
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
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'accept': 'application/json',
        },
        body: jsonEncode({
          'model': 'command-r-plus', // Cohere model
          'message': 'Please fix any OCR text errors in this text and format it properly:\n$text',
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? text;
      } else {
        _handleApiError(response.statusCode, response.body);
        return text; // Return original text if API call fails
      }
    } catch (e) {
      print('Error in Cohere processing: $e');
      return text; // Return original text if there's an error
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
          'model': 'command-r-plus', // Cohere model
          'message': '''Tạo thẻ học từ văn bản trang từ điển này. 
          Đầu vào là văn bản quét OCR của một trang từ điển Anh-Việt với định dạng:
          - Từ tiếng Anh (thường ở đầu dòng)
          - Phiên âm (giữa các ký tự / /)
          - Loại từ [n] (danh từ), [v] (động từ), v.v.
          - Nghĩa/định nghĩa tiếng Việt
          
          Trích xuất chúng thành thẻ học với từ tiếng Anh là câu hỏi và nghĩa tiếng Việt là câu trả lời.
          Định dạng phản hồi như một mảng JSON, trong đó mỗi mục có các trường "question" (từ tiếng Anh) và "answer" (nghĩa tiếng Việt).
          Ví dụ: [{"question": "hello", "answer": "xin chào"}, {"question": "book", "answer": "quyển sách"}]
          
          Đây là văn bản:
          $text''',
          'temperature': 0.2,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['text'] ?? '[]';
        
        // Debug: In ra nội dung response để kiểm tra lỗi font
        print('API Response content: $content');
        
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
          
          List<dynamic> rawCards = jsonDecode(jsonStr);
          print('Parsed cards: $rawCards');
          
          // Xử lý lỗi encoding cho tiếng Việt
          var cards = rawCards.map((card) {
            // Lấy văn bản tiếng Việt từ response
            String answer = card['answer'] as String? ?? '';
            
            // Sửa lỗi encoding (nếu có)
            answer = _fixVietnameseEncoding(answer);
            
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
          
          flashcards.add({
            'question': word,
            'answer': meaning,
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
            flashcards.add({
              'question': word,
              'answer': nextLine,
            });
          }
        }
      }
    }
    
    return flashcards;
  }
  
  // Bước này sẽ tiếp tục sử dụng class VietnameseEncodingMaps mới
  String _fixVietnameseEncoding(String text) {
    if (text.isEmpty) return text;
    
    // Sử dụng phương thức từ class VietnameseEncodingMaps
    return VietnameseEncodingMaps.fixVietnameseEncoding(text);
  }
}