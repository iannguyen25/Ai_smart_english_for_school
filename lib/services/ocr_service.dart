import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'vietnamese_encoding_maps.dart';

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _imagePicker = ImagePicker();

  Future<String?> pickAndProcessImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return null;

      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      print('Error in OCR processing: $e');
      return null;
    }
  }

  Future<String?> processImageFile(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      print('Error in OCR processing: $e');
      return null;
    }
  }

  Future<List<Map<String, String>>> extractFlashcards(String text) async {
    // Phân tích văn bản theo định dạng từ điển
    List<Map<String, String>> flashcards = [];
    
    // Sửa lỗi encoding tiếng Việt trước khi xử lý
    text = VietnameseEncodingMaps.fixVietnameseEncoding(text);
    
    // Tách các dòng văn bản
    final lines = text.split('\n');
    
    // Xử lý từng dòng
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Tìm từ tiếng Anh - thường nằm ở đầu dòng
      final englishWord = line.split('/').first.trim();
      if (englishWord.isEmpty) continue;
      
      // Tìm nghĩa tiếng Việt, thường nằm ở cuối dòng sau ký tự [n] hoặc [v]
      String vietnameseMeaning = "";
      if (line.contains('[n]') || line.contains('[v]')) {
        final parts = line.split(RegExp(r'\[n\]|\[v\]'));
        if (parts.length > 1) {
          vietnameseMeaning = parts.last.trim();
        }
      }
      
      // Nếu không tìm thấy nghĩa trong dòng hiện tại, kiểm tra dòng tiếp theo
      if (vietnameseMeaning.isEmpty && i + 1 < lines.length) {
        vietnameseMeaning = lines[i + 1].trim();
      }
      
      // Thêm vào danh sách flashcard nếu có cả từ và nghĩa
      if (englishWord.isNotEmpty && vietnameseMeaning.isNotEmpty) {
        flashcards.add({
          'question': englishWord,
          'answer': vietnameseMeaning,
        });
      }
    }
    
    return flashcards;
  }
} 