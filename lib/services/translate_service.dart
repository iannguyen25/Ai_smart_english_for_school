import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:diacritic/diacritic.dart';
import 'chatgpt_service.dart';
import 'unicode_utils.dart';

class TranslateService {
  // Singleton pattern
  static final TranslateService _instance = TranslateService._internal();
  factory TranslateService() => _instance;
  TranslateService._internal();

  final ChatGPTService _chatGPTService = ChatGPTService();
  final String _cohereBaseUrl = 'https://api.cohere.ai/v1/chat';
  final String _dictionaryBaseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';
  final _secureStorage = const FlutterSecureStorage();
  
  // Hardcode API key cho demo
  String _getApiKey() {
    return 'Jgk0MhL2B1rtGmTejEGiMJkEcJSJ6d2agAPfeT3c';
  }

  // Tìm kiếm từ với Free Dictionary API
  Future<List<String>> searchWords(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$_dictionaryBaseUrl/$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Lấy danh sách các từ liên quan
        Set<String> relatedWords = {};
        
        for (var entry in data) {
          // Thêm từ chính
          relatedWords.add(entry['word'] as String);
          
          // Thêm các từ đồng nghĩa
          for (var meaning in entry['meanings'] ?? []) {
            for (var definition in meaning['definitions'] ?? []) {
              // Thêm từ đồng nghĩa
              relatedWords.addAll(
                (definition['synonyms'] as List<dynamic>? ?? [])
                    .map((e) => e.toString())
              );
            }
          }
        }
        
        // Lọc và sắp xếp kết quả
        return relatedWords
            .where((word) => word.isNotEmpty && word.length > 2)
            .take(10)
            .toList()
          ..sort((a, b) => a.length.compareTo(b.length));
      }
      
      // Nếu không tìm thấy từ, thử tìm kiếm với mock data
      return _searchWithMockData(query);
    } catch (e) {
      print('Error searching words: $e');
      return _searchWithMockData(query);
    }
  }

  // Fallback search với mock data
  List<String> _searchWithMockData(String query) {
    String normalizedQuery = removeDiacritics(query.toLowerCase());
    
    final mockDictionary = [
      'hello', 'help', 'health', 'heart', 'hear', 'heating',
      'world', 'work', 'word', 'worth', 'working', 'worker',
      'book', 'boot', 'boost', 'booth', 'booking', 'booklet',
      'apple', 'application', 'apply', 'appetite', 'appear',
      // ... thêm từ mock khác nếu cần
    ];
    
    var results = mockDictionary.where((word) {
      String normalizedWord = removeDiacritics(word.toLowerCase());
      return normalizedWord.startsWith(normalizedQuery) || 
             normalizedWord.contains(normalizedQuery);
    }).toList();
    
    results.sort((a, b) {
      bool aStarts = removeDiacritics(a.toLowerCase()).startsWith(normalizedQuery);
      bool bStarts = removeDiacritics(b.toLowerCase()).startsWith(normalizedQuery);
      
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return a.length.compareTo(b.length);
    });
    
    return results.take(10).toList();
  }

  // Lấy chi tiết từ với Free Dictionary API và dịch sang tiếng Việt
  Future<Map<String, dynamic>> getWordDetails(String word) async {
    try {
      // 1. Lấy thông tin từ Free Dictionary API
      final response = await http.get(
        Uri.parse('$_dictionaryBaseUrl/${word.toLowerCase()}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isEmpty) throw Exception('No data found');

        final entry = data[0];
        final meanings = entry['meanings'] as List<dynamic>;
        
        // 2. Chuẩn bị các định nghĩa để dịch
        List<String> textsToTranslate = [];
        
        // Thêm các định nghĩa vào danh sách cần dịch
        for (var meaning in meanings) {
          for (var definition in meaning['definitions'] as List<dynamic>) {
            textsToTranslate.add(definition['definition'] as String);
          }
        }
        
        // 3. Dịch tất cả các định nghĩa sang tiếng Việt
        List<String> translatedDefinitions = [];
        for (var text in textsToTranslate) {
          try {
            final prompt = '''Dịch câu sau sang tiếng Việt, giữ nguyên format và ý nghĩa chuyên ngành:
            "$text"
            Chỉ trả về bản dịch tiếng Việt, không cần giải thích thêm.''';
            
            final translation = await _chatGPTService.fixText(prompt);
            translatedDefinitions.add(translation.trim());
          } catch (e) {
            print('Error translating definition: $e');
            translatedDefinitions.add('$text (Chưa có bản dịch)');
          }
        }
        
        // 4. Tạo danh sách định nghĩa với cả tiếng Anh và tiếng Việt
        List<Map<String, String>> definitions = [];
        int translationIndex = 0;
        
        for (var meaning in meanings) {
          final partOfSpeech = meaning['partOfSpeech'];
          for (var definition in meaning['definitions'] as List<dynamic>) {
            definitions.add({
              'definition': translatedDefinitions[translationIndex],
              'example': definition['example'] ?? '',
              'type': partOfSpeech,
            });
            translationIndex++;
          }
        }
        
        // 5. Xây dựng nghĩa tổng quát bằng tiếng Việt
        String generalMeaning = definitions.map((def) {
          return '(${def['type']}) ${def['definition']}';
        }).join('\n');
        
        // 6. Trả về kết quả với định dạng chuẩn
        return {
          'word': entry['word'],
          'type': meanings.isNotEmpty ? meanings[0]['partOfSpeech'] : 'n/a',
          'pronunciation': entry['phonetic'] ?? 
              (entry['phonetics'] as List<dynamic>).firstWhere(
                (p) => p['text'] != null,
                orElse: () => {'text': '/n/a/'},
              )['text'],
          'meaning': generalMeaning,
          'example': _getFirstExample(meanings),
          'definitions': definitions,
          'relatedWords': _extractRelatedWords(meanings),
          'synonyms': _extractSynonyms(meanings),
          'antonyms': _extractAntonyms(meanings),
        };
      }
      
      throw Exception('Failed to get word details');
    } catch (e) {
      print('Error getting word details: $e');
      return _getFallbackWordDetails(word);
    }
  }

  Map<String, dynamic> _getFallbackWordDetails(String word) {
    return {
      "word": word,
      "type": "n/a",
      "pronunciation": "/n/a/",
      "meaning": "Không thể tải thông tin từ. Vui lòng thử lại sau.",
      "example": "Không có ví dụ",
      "definitions": [
        {
          "definition": "Không thể tải định nghĩa",
          "example": "Không có ví dụ",
          "type": "n/a"
        }
      ],
      "relatedWords": [],
      "synonyms": [],
      "antonyms": []
    };
  }

  String _getFirstExample(List<dynamic> meanings) {
    for (var meaning in meanings) {
      for (var definition in meaning['definitions'] as List<dynamic>) {
        if (definition['example'] != null) {
          return definition['example'];
        }
      }
    }
    return 'Không có ví dụ';
  }

  List<String> _extractRelatedWords(List<dynamic> meanings) {
    Set<String> words = {};
    
    for (var meaning in meanings) {
      for (var definition in meaning['definitions'] as List<dynamic>) {
        if (definition['example'] != null) {
          words.addAll(
            definition['example']
                .toString()
                .split(' ')
                .where((word) => word.length > 2)
                .map((word) => word.replaceAll(RegExp(r'[^\w\s]'), ''))
          );
        }
      }
    }
    
    return words.take(10).toList();
  }

  List<String> _extractSynonyms(List<dynamic> meanings) {
    Set<String> synonyms = {};
    
    for (var meaning in meanings) {
      for (var definition in meaning['definitions'] as List<dynamic>) {
        synonyms.addAll(
          (definition['synonyms'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
        );
      }
    }
    
    return synonyms.take(10).toList();
  }

  List<String> _extractAntonyms(List<dynamic> meanings) {
    Set<String> antonyms = {};
    
    for (var meaning in meanings) {
      for (var definition in meaning['definitions'] as List<dynamic>) {
        antonyms.addAll(
          (definition['antonyms'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
        );
      }
    }
    
    return antonyms.take(10).toList();
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