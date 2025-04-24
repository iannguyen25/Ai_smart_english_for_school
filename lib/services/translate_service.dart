import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslateService {
  // Singleton pattern
  static final TranslateService _instance = TranslateService._internal();
  factory TranslateService() => _instance;
  TranslateService._internal();

  // API key - sẽ được thay thế sau
  final String _apiKey = '';
  final String _baseUrl = 'https://libretranslate.com/translate';

  // Tìm kiếm từ và trả về danh sách gợi ý
  Future<List<Map<String, dynamic>>> searchWord(String query) async {
    // Giả lập API - thay thế bằng API thực tế sau này
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Tạo danh sách từ gợi ý giả lập
    final results = [
      {
        'word': query,
        'pronunciation': '/təˈmɑːtoʊ/',
        'type': 'noun',
        'meaning': 'A red or yellowish fruit with a lot of seeds',
        'example': 'I like to eat tomatoes in salads.',
        'relatedWords': ['vegetable', 'fruit', 'red', 'salad', 'garden']
      },
      {
        'word': '${query}s',
        'pronunciation': '/təˈmɑːtoʊz/',
        'type': 'noun',
        'meaning': 'Plural form of ${query}',
        'example': 'There are many ${query}s in the garden.',
        'relatedWords': ['multiple', 'many', 'plural']
      },
      {
        'word': '${query} sauce',
        'pronunciation': '/təˈmɑːtoʊ sɔːs/',
        'type': 'noun',
        'meaning': 'A sauce made from ${query}es',
        'example': 'The pasta has ${query} sauce on it.',
        'relatedWords': ['pasta', 'sauce', 'Italian', 'cooking']
      },
      {
        'word': '${query} plant',
        'pronunciation': '/təˈmɑːtoʊ plænt/',
        'type': 'noun',
        'meaning': 'A plant that produces ${query}es',
        'example': 'I am growing ${query} plants in my garden.',
        'relatedWords': ['garden', 'grow', 'plant', 'vegetable']
      },
      {
        'word': 'cherry ${query}',
        'pronunciation': '/ˈtʃɛri təˈmɑːtoʊ/',
        'type': 'noun',
        'meaning': 'A small, often sweet variety of ${query}',
        'example': 'Cherry ${query}es are perfect for salads.',
        'relatedWords': ['small', 'cherry', 'sweet', 'variety']
      },
    ];
    
    return results;
    
    // Khi tích hợp API thực, phần code dưới đây sẽ được sử dụng
    /*
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?q=$query'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results']);
      } else {
        throw Exception('Failed to search word: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching word: $e');
    }
    */
  }

  // Lấy chi tiết một từ
  Future<Map<String, dynamic>> getWordDetails(String word) async {
    // Giả lập API - thay thế bằng API thực tế sau này
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Tạo chi tiết từ giả lập
    return {
      'word': word,
      'pronunciation': '/təˈmɑːtoʊ/',
      'type': 'noun',
      'meaning': 'A red or yellowish fruit with a lot of seeds',
      'example': 'I like to eat tomatoes in salads.',
      'relatedWords': ['vegetable', 'fruit', 'red', 'salad', 'garden'],
      'definitions': [
        {
          'definition': 'A red or yellowish fruit with a lot of seeds',
          'example': 'I like to eat tomatoes in salads.'
        },
        {
          'definition': 'The plant that produces tomatoes',
          'example': 'He grows tomatoes in his garden.'
        }
      ],
      'synonyms': ['cherry tomato', 'plum tomato', 'beefsteak tomato'],
      'antonyms': []
    };
    
    // Khi tích hợp API thực, phần code dưới đây sẽ được sử dụng
    /*
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/word/$word'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Failed to get word details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting word details: $e');
    }
    */
  }

  // Tìm kiếm từ đồng nghĩa
  Future<List<String>> getSynonyms(String word) async {
    // Giả lập API - thay thế bằng API thực tế sau này
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Tạo danh sách từ đồng nghĩa giả lập
    return ['cherry tomato', 'plum tomato', 'beefsteak tomato'];
    
    // Khi tích hợp API thực, phần code dưới đây sẽ được sử dụng
    /*
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/synonyms/$word'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['synonyms']);
      } else {
        throw Exception('Failed to get synonyms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting synonyms: $e');
    }
    */
  }

  // Tìm kiếm từ đối nghĩa
  Future<List<String>> getAntonyms(String word) async {
    // Giả lập API - thay thế bằng API thực tế sau này
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Tạo danh sách từ đối nghĩa giả lập
    return [];
    
    // Khi tích hợp API thực, phần code dưới đây sẽ được sử dụng
    /*
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/antonyms/$word'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['antonyms']);
      } else {
        throw Exception('Failed to get antonyms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting antonyms: $e');
    }
    */
  }
} 