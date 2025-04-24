import 'package:flutter/material.dart';
import '../services/vietnamese_encoding_maps.dart';
import '../services/unicode_utils.dart';

/// Lớp xử lý văn bản cho các tính năng của ứng dụng
class TextProcessor {
  /// Xử lý văn bản từ OCR để tạo flashcard
  static String processOCRText(String text) {
    if (text.isEmpty) return text;
    
    // Bước 1: Sửa lỗi encoding tiếng Việt
    String result = VietnameseEncodingMaps.fixVietnameseEncoding(text);
    
    // Bước 2: Chuẩn hóa dấu câu
    result = _normalizePunctuation(result);
    
    // Bước 3: Loại bỏ khoảng trắng thừa
    result = _normalizeWhitespace(result);
    
    return result;
  }
  
  /// Xử lý văn bản cho từ điển Anh-Việt
  static String processDictionaryText(String text) {
    if (text.isEmpty) return text;
    
    // Bước 1: Sửa lỗi encoding tiếng Việt
    String result = VietnameseEncodingMaps.fixVietnameseEncoding(text);
    
    // Bước 2: Chuẩn hóa dấu câu
    result = _normalizePunctuation(result);
    
    // Bước 3: Loại bỏ khoảng trắng thừa
    result = _normalizeWhitespace(result);
    
    // Bước 4: Chuẩn hóa các ký hiệu từ điển [n], [v], etc.
    result = _normalizeDictionarySymbols(result);
    
    return result;
  }
  
  /// Chuẩn hóa dấu câu
  static String _normalizePunctuation(String text) {
    if (text.isEmpty) return text;
    
    String result = text;
    
    // Chuẩn hóa dấu chấm
    result = result.replaceAll('..', '.');
    result = result.replaceAll('…', '...');
    
    // Chuẩn hóa dấu phẩy
    result = result.replaceAll(' ,', ',');
    
    // Chuẩn hóa dấu chấm than và dấu hỏi
    result = result.replaceAll(' !', '!');
    result = result.replaceAll(' ?', '?');
    
    // Chuẩn hóa dấu ngoặc
    result = result.replaceAll('( ', '(');
    result = result.replaceAll(' )', ')');
    
    // Chuẩn hóa dấu hai chấm và dấu chấm phẩy
    result = result.replaceAll(' :', ':');
    result = result.replaceAll(' ;', ';');
    
    return result;
  }
  
  /// Chuẩn hóa khoảng trắng
  static String _normalizeWhitespace(String text) {
    if (text.isEmpty) return text;
    
    String result = text;
    
    // Loại bỏ khoảng trắng đầu và cuối
    result = result.trim();
    
    // Thay thế nhiều khoảng trắng liên tiếp bằng một khoảng trắng
    result = result.replaceAll(RegExp(r'\s+'), ' ');
    
    // Loại bỏ khoảng trắng trước dấu câu
    result = result.replaceAll(' .', '.');
    
    return result;
  }
  
  /// Chuẩn hóa các ký hiệu từ điển
  static String _normalizeDictionarySymbols(String text) {
    if (text.isEmpty) return text;
    
    String result = text;
    
    // Chuẩn hóa ký hiệu loại từ
    result = result.replaceAll('[n.]', '[n]');
    result = result.replaceAll('[v.]', '[v]');
    result = result.replaceAll('[adj.]', '[adj]');
    result = result.replaceAll('[adv.]', '[adv]');
    
    // Thêm khoảng trắng sau ký hiệu loại từ nếu chưa có
    result = result.replaceAll('[n]]', '[n] ');
    result = result.replaceAll('[v]]', '[v] ');
    result = result.replaceAll('[adj]]', '[adj] ');
    result = result.replaceAll('[adv]]', '[adv] ');
    
    return result;
  }
  
  /// Chuẩn hóa từ tiếng Anh
  static String formatEnglishWord(String word) {
    if (word.isEmpty) return word;
    
    // Loại bỏ khoảng trắng đầu và cuối
    String result = word.trim();
    
    // Chuyển thành chữ thường
    result = result.toLowerCase();
    
    // Viết hoa chữ cái đầu tiên
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }
    
    return result;
  }
  
  /// Format lại câu tiếng Việt
  static String formatVietnameseSentence(String sentence) {
    if (sentence.isEmpty) return sentence;
    
    // Sửa lỗi encoding
    String result = VietnameseEncodingMaps.fixVietnameseEncoding(sentence);
    
    // Loại bỏ khoảng trắng đầu và cuối
    result = result.trim();
    
    // Viết hoa chữ cái đầu tiên
    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }
    
    // Đảm bảo có dấu chấm ở cuối câu nếu cần
    if (result.isNotEmpty && 
        !result.endsWith('.') && 
        !result.endsWith('!') && 
        !result.endsWith('?')) {
      result += '.';
    }
    
    return result;
  }
} 