import 'vietnamese_encoding_maps.dart';

/// Lớp tiện ích xử lý vấn đề về Unicode tiếng Việt
class UnicodeUtils {
  /// Kiểm tra một chuỗi có phải là tiếng Việt không
  static bool isVietnameseText(String text) {
    final RegExp vietnamesePattern = RegExp(
      r'[àáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵđ]',
      caseSensitive: false,
      unicode: true,
    );
    return vietnamesePattern.hasMatch(text);
  }

  /// Kiểm tra một chuỗi có vấn đề về encoding không
  static bool hasEncodingIssues(String text) {
    return VietnameseEncodingMaps.hasEncodingIssues(text);
  }

  /// Sửa lỗi encoding cho chuỗi tiếng Việt
  static String fixVietnameseEncoding(String text) {
    return VietnameseEncodingMaps.fixVietnameseEncoding(text);
  }

  /// Chuẩn hóa dấu tiếng Việt (chuyển từ Unicode tổ hợp sang Unicode kết hợp)
  static String normalizeVietnameseMarks(String text) {
    // Chuẩn hóa dạng D của Unicode
    text = text.replaceAll('\u0065\u0309', '\u1EBB'); // ẻ
    text = text.replaceAll('\u0065\u0301', '\u00E9'); // é
    text = text.replaceAll('\u0065\u0300', '\u00E8'); // è
    text = text.replaceAll('\u0065\u0303', '\u1EBD'); // ẽ
    text = text.replaceAll('\u0065\u0323', '\u1EB9'); // ẹ
    text = text.replaceAll('\u00EA\u0309', '\u1EC3'); // ể
    text = text.replaceAll('\u00EA\u0301', '\u1EBF'); // ế
    text = text.replaceAll('\u00EA\u0300', '\u1EC1'); // ề
    text = text.replaceAll('\u00EA\u0303', '\u1EC5'); // ễ
    text = text.replaceAll('\u00EA\u0323', '\u1EC7'); // ệ
    text = text.replaceAll('\u0061\u0309', '\u1EA3'); // ả
    text = text.replaceAll('\u0061\u0301', '\u00E1'); // á
    text = text.replaceAll('\u0061\u0300', '\u00E0'); // à
    text = text.replaceAll('\u0061\u0303', '\u00E3'); // ã
    text = text.replaceAll('\u0061\u0323', '\u1EA1'); // ạ
    text = text.replaceAll('\u0103\u0309', '\u1EB3'); // ẳ
    text = text.replaceAll('\u0103\u0301', '\u1EAF'); // ắ
    text = text.replaceAll('\u0103\u0300', '\u1EB1'); // ằ
    text = text.replaceAll('\u0103\u0303', '\u1EB5'); // ẵ
    text = text.replaceAll('\u0103\u0323', '\u1EB7'); // ặ
    text = text.replaceAll('\u00E2\u0309', '\u1EA9'); // ẩ
    text = text.replaceAll('\u00E2\u0301', '\u1EA5'); // ấ
    text = text.replaceAll('\u00E2\u0300', '\u1EA7'); // ầ
    text = text.replaceAll('\u00E2\u0303', '\u1EAB'); // ẫ
    text = text.replaceAll('\u00E2\u0323', '\u1EAD'); // ậ
    text = text.replaceAll('\u0069\u0309', '\u1EC9'); // ỉ
    text = text.replaceAll('\u0069\u0301', '\u00ED'); // í
    text = text.replaceAll('\u0069\u0300', '\u00EC'); // ì
    text = text.replaceAll('\u0069\u0303', '\u0129'); // ĩ
    text = text.replaceAll('\u0069\u0323', '\u1ECB'); // ị
    text = text.replaceAll('\u006F\u0309', '\u1ECF'); // ỏ
    text = text.replaceAll('\u006F\u0301', '\u00F3'); // ó
    text = text.replaceAll('\u006F\u0300', '\u00F2'); // ò
    text = text.replaceAll('\u006F\u0303', '\u00F5'); // õ
    text = text.replaceAll('\u006F\u0323', '\u1ECD'); // ọ
    text = text.replaceAll('\u00F4\u0309', '\u1ED5'); // ổ
    text = text.replaceAll('\u00F4\u0301', '\u1ED1'); // ố
    text = text.replaceAll('\u00F4\u0300', '\u1ED3'); // ồ
    text = text.replaceAll('\u00F4\u0303', '\u1ED7'); // ỗ
    text = text.replaceAll('\u00F4\u0323', '\u1ED9'); // ộ
    text = text.replaceAll('\u01A1\u0309', '\u1EDF'); // ở
    text = text.replaceAll('\u01A1\u0301', '\u1EDB'); // ớ
    text = text.replaceAll('\u01A1\u0300', '\u1EDD'); // ờ
    text = text.replaceAll('\u01A1\u0303', '\u1EE1'); // ỡ
    text = text.replaceAll('\u01A1\u0323', '\u1EE3'); // ợ
    text = text.replaceAll('\u0075\u0309', '\u1EE7'); // ủ
    text = text.replaceAll('\u0075\u0301', '\u00FA'); // ú
    text = text.replaceAll('\u0075\u0300', '\u00F9'); // ù
    text = text.replaceAll('\u0075\u0303', '\u0169'); // ũ
    text = text.replaceAll('\u0075\u0323', '\u1EE5'); // ụ
    text = text.replaceAll('\u01B0\u0309', '\u1EED'); // ử
    text = text.replaceAll('\u01B0\u0301', '\u1EE9'); // ứ
    text = text.replaceAll('\u01B0\u0300', '\u1EEB'); // ừ
    text = text.replaceAll('\u01B0\u0303', '\u1EEF'); // ữ
    text = text.replaceAll('\u01B0\u0323', '\u1EF1'); // ự
    text = text.replaceAll('\u0079\u0309', '\u1EF7'); // ỷ
    text = text.replaceAll('\u0079\u0301', '\u00FD'); // ý
    text = text.replaceAll('\u0079\u0300', '\u1EF3'); // ỳ
    text = text.replaceAll('\u0079\u0303', '\u1EF9'); // ỹ
    text = text.replaceAll('\u0079\u0323', '\u1EF5'); // ỵ
    return text;
  }

  /// Loại bỏ dấu trong tiếng Việt
  static String removeVietnameseMarks(String text) {
    final replacements = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a', 
      'ă': 'a', 'ắ': 'a', 'ằ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ấ': 'a', 'ầ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ế': 'e', 'ề': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ố': 'o', 'ồ': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ớ': 'o', 'ờ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ứ': 'u', 'ừ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
      'À': 'A', 'Á': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A',
      'Ă': 'A', 'Ắ': 'A', 'Ằ': 'A', 'Ẳ': 'A', 'Ẵ': 'A', 'Ặ': 'A',
      'Â': 'A', 'Ấ': 'A', 'Ầ': 'A', 'Ẩ': 'A', 'Ẫ': 'A', 'Ậ': 'A',
      'È': 'E', 'É': 'E', 'Ẻ': 'E', 'Ẽ': 'E', 'Ẹ': 'E',
      'Ê': 'E', 'Ế': 'E', 'Ề': 'E', 'Ể': 'E', 'Ễ': 'E', 'Ệ': 'E',
      'Ì': 'I', 'Í': 'I', 'Ỉ': 'I', 'Ĩ': 'I', 'Ị': 'I',
      'Ò': 'O', 'Ó': 'O', 'Ỏ': 'O', 'Õ': 'O', 'Ọ': 'O',
      'Ô': 'O', 'Ố': 'O', 'Ồ': 'O', 'Ổ': 'O', 'Ỗ': 'O', 'Ộ': 'O',
      'Ơ': 'O', 'Ớ': 'O', 'Ờ': 'O', 'Ở': 'O', 'Ỡ': 'O', 'Ợ': 'O',
      'Ù': 'U', 'Ú': 'U', 'Ủ': 'U', 'Ũ': 'U', 'Ụ': 'U',
      'Ư': 'U', 'Ứ': 'U', 'Ừ': 'U', 'Ử': 'U', 'Ữ': 'U', 'Ự': 'U',
      'Ỳ': 'Y', 'Ý': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y', 'Ỵ': 'Y',
      'Đ': 'D',
    };
    
    String result = text;
    replacements.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    
    return result;
  }
} 