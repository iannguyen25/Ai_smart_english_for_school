import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../models/search_history.dart';
import '../../services/auth_service.dart';
import '../../services/translate_service.dart';
import 'search_history_screen.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({Key? key}) : super(key: key);

  @override
  _TranslateScreenState createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final TranslateService _translateService = TranslateService();
  
  List<Map<String, dynamic>> _suggestedWords = [];
  Map<String, dynamic>? _selectedWord;
  bool _isLoading = false;
  bool _showDetails = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _suggestedWords = [];
        _showDetails = false;
      });
      return;
    }
    
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchWord(_searchController.text);
    });
  }

  Future<void> _searchWord(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Demo data với nhiều case đa dạng
      List<Map<String, dynamic>> results = [];
      
      // Case 1: Từ đơn giản
      if (query.toLowerCase() == 'hello') {
        results = [
          {
            'word': 'Hello',
            'type': 'n.',
            'pronunciation': '/həˈləʊ/',
            'meaning': 'Xin chào, lời chào hỏi',
            'example': 'Hello, how are you today?',
            'definitions': [
              {
                'definition': 'Lời chào khi gặp ai đó',
                'example': 'She said hello to everyone in the room'
              },
              {
                'definition': 'Lời chào qua điện thoại',
                'example': 'Hello, this is John speaking'
              }
            ],
            'relatedWords': ['Hi', 'Greeting', 'Salutation'],
            'synonyms': ['Hi', 'Hey', 'Greetings']
          }
        ];
      }
      // Case 2: Từ phức tạp với nhiều nghĩa
      else if (query.toLowerCase() == 'run') {
        results = [
          {
            'word': 'Run',
            'type': 'v.',
            'pronunciation': '/rʌn/',
            'meaning': 'Chạy, vận hành, quản lý',
            'example': 'He runs a successful business',
            'definitions': [
              {
                'definition': 'Di chuyển nhanh bằng chân',
                'example': 'She runs every morning to stay fit'
              },
              {
                'definition': 'Vận hành hoặc quản lý',
                'example': 'He runs a small cafe downtown'
              },
              {
                'definition': 'Chảy hoặc trôi',
                'example': 'Tears ran down her face'
              }
            ],
            'relatedWords': ['Jog', 'Operate', 'Manage', 'Flow'],
            'synonyms': ['Sprint', 'Operate', 'Manage', 'Flow']
          }
        ];
      }
      // Case 3: Từ chuyên ngành
      else if (query.toLowerCase() == 'algorithm') {
        results = [
          {
            'word': 'Algorithm',
            'type': 'n.',
            'pronunciation': '/ˈælɡərɪðəm/',
            'meaning': 'Thuật toán, quy trình giải quyết vấn đề',
            'example': 'The search algorithm efficiently finds the best results',
            'definitions': [
              {
                'definition': 'Một tập hợp các bước để giải quyết vấn đề',
                'example': 'The encryption algorithm ensures data security'
              },
              {
                'definition': 'Quy trình tính toán trong khoa học máy tính',
                'example': 'The sorting algorithm organizes data efficiently'
              }
            ],
            'relatedWords': ['Computation', 'Process', 'Method', 'Procedure'],
            'synonyms': ['Procedure', 'Method', 'Process', 'Technique']
          }
        ];
      }
      // Case 4: Thành ngữ
      else if (query.toLowerCase() == 'break a leg') {
        results = [
          {
            'word': 'Break a leg',
            'type': 'idiom',
            'pronunciation': '/breɪk ə leɡ/',
            'meaning': 'Chúc may mắn (thường dùng trong biểu diễn)',
            'example': 'Break a leg on your performance tonight!',
            'definitions': [
              {
                'definition': 'Lời chúc may mắn trước khi biểu diễn',
                'example': 'The cast wished each other to break a leg before the show'
              }
            ],
            'relatedWords': ['Good luck', 'Best wishes', 'Success'],
            'synonyms': ['Good luck', 'Best wishes']
          }
        ];
      }
      // Case 5: Từ có nhiều từ đồng nghĩa
      else if (query.toLowerCase() == 'beautiful') {
        results = [
          {
            'word': 'Beautiful',
            'type': 'adj.',
            'pronunciation': '/ˈbjuːtɪfəl/',
            'meaning': 'Đẹp, xinh đẹp, tuyệt vời',
            'example': 'The sunset was absolutely beautiful',
            'definitions': [
              {
                'definition': 'Có vẻ đẹp tự nhiên',
                'example': 'She has a beautiful smile'
              },
              {
                'definition': 'Gây ấn tượng mạnh mẽ',
                'example': 'The music was beautiful and moving'
              }
            ],
            'relatedWords': ['Attractive', 'Lovely', 'Gorgeous', 'Stunning'],
            'synonyms': ['Gorgeous', 'Stunning', 'Lovely', 'Attractive', 'Pretty', 'Elegant', 'Graceful', 'Radiant']
          }
        ];
      }
      // Case 6: Từ có ví dụ phức tạp
      else if (query.toLowerCase() == 'sustainability') {
        results = [
          {
            'word': 'Sustainability',
            'type': 'n.',
            'pronunciation': '/səˌsteɪnəˈbɪləti/',
            'meaning': 'Tính bền vững, khả năng duy trì',
            'example': 'The company focuses on environmental sustainability in all its operations',
            'definitions': [
              {
                'definition': 'Khả năng duy trì hoặc tiếp tục trong thời gian dài',
                'example': 'Sustainable development aims to meet present needs without compromising future generations'
              },
              {
                'definition': 'Sự cân bằng giữa phát triển và bảo vệ môi trường',
                'example': 'The city implemented sustainability measures to reduce carbon emissions'
              }
            ],
            'relatedWords': ['Ecology', 'Environment', 'Conservation', 'Renewable'],
            'synonyms': ['Durability', 'Endurance', 'Permanence', 'Continuity']
          }
        ];
      }
      // Case 7: Từ vựng thể thao
      else if (query.toLowerCase() == 'goal') {
        results = [
          {
            'word': 'Goal',
            'type': 'n.',
            'pronunciation': '/ɡəʊl/',
            'meaning': 'Bàn thắng, mục tiêu',
            'example': 'He scored a spectacular goal in the final minute',
            'definitions': [
              {
                'definition': 'Điểm ghi được trong các môn thể thao',
                'example': 'The team celebrated after scoring the winning goal'
              },
              {
                'definition': 'Mục tiêu hoặc đích đến',
                'example': 'Her goal is to become a professional athlete'
              }
            ],
            'relatedWords': ['Score', 'Target', 'Objective', 'Aim'],
            'synonyms': ['Objective', 'Target', 'Aim', 'Purpose']
          }
        ];
      }
      // Case 8: Từ vựng công nghệ
      else if (query.toLowerCase() == 'blockchain') {
        results = [
          {
            'word': 'Blockchain',
            'type': 'n.',
            'pronunciation': '/ˈblɒktʃeɪn/',
            'meaning': 'Chuỗi khối, công nghệ sổ cái phân tán',
            'example': 'Blockchain technology is revolutionizing financial transactions',
            'definitions': [
              {
                'definition': 'Hệ thống cơ sở dữ liệu phân tán',
                'example': 'The blockchain ensures secure and transparent transactions'
              },
              {
                'definition': 'Công nghệ đằng sau tiền điện tử',
                'example': 'Bitcoin operates on a blockchain network'
              }
            ],
            'relatedWords': ['Cryptocurrency', 'Decentralization', 'Ledger', 'Bitcoin'],
            'synonyms': ['Distributed Ledger', 'Digital Ledger', 'Crypto Ledger']
          }
        ];
      }
      // Case 9: Từ vựng y tế
      else if (query.toLowerCase() == 'diagnosis') {
        results = [
          {
            'word': 'Diagnosis',
            'type': 'n.',
            'pronunciation': '/ˌdaɪəɡˈnəʊsɪs/',
            'meaning': 'Chẩn đoán, kết luận y khoa',
            'example': 'The doctor made a quick diagnosis of the patient\'s condition',
            'definitions': [
              {
                'definition': 'Quá trình xác định bệnh hoặc tình trạng',
                'example': 'Early diagnosis is crucial for effective treatment'
              },
              {
                'definition': 'Kết luận về tình trạng sức khỏe',
                'example': 'The diagnosis revealed a rare genetic condition'
              }
            ],
            'relatedWords': ['Prognosis', 'Treatment', 'Symptoms', 'Examination'],
            'synonyms': ['Assessment', 'Evaluation', 'Analysis', 'Conclusion']
          }
        ];
      }
      // Case 10: Từ vựng kinh doanh
      else if (query.toLowerCase() == 'entrepreneur') {
        results = [
          {
            'word': 'Entrepreneur',
            'type': 'n.',
            'pronunciation': '/ˌɒntrəprəˈnɜː(r)/',
            'meaning': 'Doanh nhân, người khởi nghiệp',
            'example': 'She is a successful entrepreneur who started her own company',
            'definitions': [
              {
                'definition': 'Người bắt đầu và điều hành doanh nghiệp',
                'example': 'The entrepreneur launched a new tech startup'
              },
              {
                'definition': 'Người chấp nhận rủi ro để tạo ra giá trị',
                'example': 'Entrepreneurs drive innovation in the economy'
              }
            ],
            'relatedWords': ['Business', 'Startup', 'Innovation', 'Venture'],
            'synonyms': ['Businessperson', 'Self-starter', 'Innovator', 'Founder']
          }
        ];
      }
      // Case 11: Từ vựng học thuật
      else if (query.toLowerCase() == 'hypothesis') {
        results = [
          {
            'word': 'Hypothesis',
            'type': 'n.',
            'pronunciation': '/haɪˈpɒθəsɪs/',
            'meaning': 'Giả thuyết, giả định khoa học',
            'example': 'The scientist tested her hypothesis through experiments',
            'definitions': [
              {
                'definition': 'Giả định có thể kiểm chứng',
                'example': 'The research team formulated a new hypothesis'
              },
              {
                'definition': 'Cơ sở cho nghiên cứu khoa học',
                'example': 'The hypothesis guided the experimental design'
              }
            ],
            'relatedWords': ['Theory', 'Assumption', 'Prediction', 'Research'],
            'synonyms': ['Theory', 'Proposition', 'Supposition', 'Postulate']
          }
        ];
      }
      // Case 12: Từ vựng giao tiếp
      else if (query.toLowerCase() == 'negotiate') {
        results = [
          {
            'word': 'Negotiate',
            'type': 'v.',
            'pronunciation': '/nɪˈɡəʊʃieɪt/',
            'meaning': 'Thương lượng, đàm phán',
            'example': 'They negotiated a fair price for the house',
            'definitions': [
              {
                'definition': 'Thảo luận để đạt được thỏa thuận',
                'example': 'The union negotiated better working conditions'
              },
              {
                'definition': 'Vượt qua hoặc xử lý tình huống khó khăn',
                'example': 'She negotiated the difficult terrain carefully'
              }
            ],
            'relatedWords': ['Bargain', 'Discuss', 'Mediate', 'Arrange'],
            'synonyms': ['Bargain', 'Discuss', 'Mediate', 'Arrange']
          }
        ];
      }
      // Case 13: Từ vựng theo cấp độ A1
      else if (query.toLowerCase() == 'book') {
        results = [
          {
            'word': 'Book',
            'type': 'n.',
            'pronunciation': '/bʊk/',
            'meaning': 'Sách, cuốn sách',
            'example': 'I love reading books in my free time',
            'definitions': [
              {
                'definition': 'Tập hợp các trang giấy có chữ hoặc hình ảnh',
                'example': 'She bought a new book at the bookstore'
              }
            ],
            'relatedWords': ['Reading', 'Library', 'Page', 'Story'],
            'synonyms': ['Volume', 'Publication', 'Text', 'Work']
          }
        ];
      }
      // Case 14: Từ vựng theo cấp độ C2
      else if (query.toLowerCase() == 'ubiquitous') {
        results = [
          {
            'word': 'Ubiquitous',
            'type': 'adj.',
            'pronunciation': '/juːˈbɪkwɪtəs/',
            'meaning': 'Có mặt ở khắp nơi, phổ biến',
            'example': 'Smartphones have become ubiquitous in modern society',
            'definitions': [
              {
                'definition': 'Hiện diện ở mọi nơi',
                'example': 'The ubiquitous presence of social media affects daily life'
              }
            ],
            'relatedWords': ['Omnipresent', 'Pervasive', 'Universal', 'Everywhere'],
            'synonyms': ['Omnipresent', 'Pervasive', 'Universal', 'Everywhere']
          }
        ];
      }
      // Case 15: Từ vựng theo nguồn gốc Latin
      else if (query.toLowerCase() == 'et cetera') {
        results = [
          {
            'word': 'Et cetera',
            'type': 'adv.',
            'pronunciation': '/ˌet ˈsetərə/',
            'meaning': 'Vân vân, và những thứ khác',
            'example': 'The store sells fruits, vegetables, et cetera',
            'definitions': [
              {
                'definition': 'Dùng để chỉ những thứ tương tự còn lại',
                'example': 'The list includes books, pens, notebooks, et cetera'
              }
            ],
            'relatedWords': ['And so on', 'And so forth', 'And the rest'],
            'synonyms': ['And so on', 'And so forth', 'And the rest']
          }
        ];
      }
      // Case 16: Từ vựng hiếm gặp
      else if (query.toLowerCase() == 'serendipity') {
        results = [
          {
            'word': 'Serendipity',
            'type': 'n.',
            'pronunciation': '/ˌserənˈdɪpəti/',
            'meaning': 'Sự tình cờ may mắn, phát hiện tình cờ',
            'example': 'Their meeting was pure serendipity',
            'definitions': [
              {
                'definition': 'Khám phá tình cờ có giá trị',
                'example': 'The discovery was a result of serendipity'
              }
            ],
            'relatedWords': ['Fortuity', 'Chance', 'Luck', 'Discovery'],
            'synonyms': ['Fortuity', 'Chance', 'Luck', 'Discovery']
          }
        ];
      }
      // Case 17: Từ vựng nghệ thuật
      else if (query.toLowerCase() == 'masterpiece') {
        results = [
          {
            'word': 'Masterpiece',
            'type': 'n.',
            'pronunciation': '/ˈmɑːstəpiːs/',
            'meaning': 'Kiệt tác, tác phẩm xuất sắc',
            'example': 'The Mona Lisa is considered a masterpiece of Renaissance art',
            'definitions': [
              {
                'definition': 'Tác phẩm nghệ thuật xuất sắc nhất',
                'example': 'The artist spent years creating this masterpiece'
              },
              {
                'definition': 'Thành tựu đáng chú ý trong bất kỳ lĩnh vực nào',
                'example': 'The novel is a literary masterpiece'
              }
            ],
            'relatedWords': ['Artwork', 'Creation', 'Work', 'Achievement'],
            'synonyms': ['Masterwork', 'Magnum opus', 'Tour de force', 'Chef-d\'oeuvre']
          }
        ];
      }
      // Case 18: Từ vựng âm nhạc
      else if (query.toLowerCase() == 'symphony') {
        results = [
          {
            'word': 'Symphony',
            'type': 'n.',
            'pronunciation': '/ˈsɪmfəni/',
            'meaning': 'Bản giao hưởng, sự hài hòa',
            'example': 'Beethoven\'s Ninth Symphony is a masterpiece of classical music',
            'definitions': [
              {
                'definition': 'Tác phẩm âm nhạc cổ điển cho dàn nhạc',
                'example': 'The orchestra performed a beautiful symphony'
              },
              {
                'definition': 'Sự kết hợp hài hòa của các yếu tố',
                'example': 'The garden was a symphony of colors'
              }
            ],
            'relatedWords': ['Orchestra', 'Composition', 'Harmony', 'Melody'],
            'synonyms': ['Concerto', 'Orchestration', 'Harmony', 'Composition']
          }
        ];
      }
      // Case 19: Từ vựng du lịch
      else if (query.toLowerCase() == 'itinerary') {
        results = [
          {
            'word': 'Itinerary',
            'type': 'n.',
            'pronunciation': '/aɪˈtɪnərəri/',
            'meaning': 'Lịch trình, hành trình',
            'example': 'The travel agent prepared a detailed itinerary for our trip',
            'definitions': [
              {
                'definition': 'Kế hoạch chi tiết cho một chuyến đi',
                'example': 'Our itinerary includes visits to three cities'
              },
              {
                'definition': 'Tài liệu ghi lại lộ trình',
                'example': 'The itinerary shows all our flight details'
              }
            ],
            'relatedWords': ['Schedule', 'Route', 'Plan', 'Journey'],
            'synonyms': ['Schedule', 'Route', 'Plan', 'Journey']
          }
        ];
      }
      // Case 20: Từ vựng chính trị
      else if (query.toLowerCase() == 'democracy') {
        results = [
          {
            'word': 'Democracy',
            'type': 'n.',
            'pronunciation': '/dɪˈmɒkrəsi/',
            'meaning': 'Dân chủ, chế độ dân chủ',
            'example': 'The country transitioned to democracy after years of dictatorship',
            'definitions': [
              {
                'definition': 'Hệ thống chính phủ do dân bầu',
                'example': 'Democracy allows citizens to participate in decision-making'
              },
              {
                'definition': 'Nguyên tắc bình đẳng và tự do',
                'example': 'The organization promotes democratic values'
              }
            ],
            'relatedWords': ['Government', 'Freedom', 'Election', 'Republic'],
            'synonyms': ['Republic', 'Self-government', 'Popular sovereignty']
          }
        ];
      }
      // Case 21: Từ vựng pháp luật
      else if (query.toLowerCase() == 'jurisdiction') {
        results = [
          {
            'word': 'Jurisdiction',
            'type': 'n.',
            'pronunciation': '/ˌdʒʊərɪsˈdɪkʃn/',
            'meaning': 'Thẩm quyền, phạm vi quyền hạn',
            'example': 'The case falls under federal jurisdiction',
            'definitions': [
              {
                'definition': 'Quyền hạn pháp lý của tòa án',
                'example': 'The court has jurisdiction over this matter'
              },
              {
                'definition': 'Phạm vi kiểm soát hoặc quyền lực',
                'example': 'The police have jurisdiction in this area'
              }
            ],
            'relatedWords': ['Authority', 'Control', 'Power', 'Territory'],
            'synonyms': ['Authority', 'Control', 'Power', 'Territory']
          }
        ];
      }
      // Case 22: Từ vựng văn hóa
      else if (query.toLowerCase() == 'tradition') {
        results = [
          {
            'word': 'Tradition',
            'type': 'n.',
            'pronunciation': '/trəˈdɪʃn/',
            'meaning': 'Truyền thống, phong tục',
            'example': 'The festival is an important cultural tradition',
            'definitions': [
              {
                'definition': 'Tập quán được truyền qua nhiều thế hệ',
                'example': 'The family maintains many old traditions'
              },
              {
                'definition': 'Phương thức hành động đã được thiết lập',
                'example': 'It\'s a tradition to exchange gifts at Christmas'
              }
            ],
            'relatedWords': ['Custom', 'Heritage', 'Culture', 'Practice'],
            'synonyms': ['Custom', 'Heritage', 'Culture', 'Practice']
          }
        ];
      }
      // Case 23: Từ vựng giới từ
      else if (query.toLowerCase() == 'throughout') {
        results = [
          {
            'word': 'Throughout',
            'type': 'prep.',
            'pronunciation': '/θruːˈaʊt/',
            'meaning': 'Xuyên suốt, trong suốt',
            'example': 'The theme runs throughout the novel',
            'definitions': [
              {
                'definition': 'Trong toàn bộ thời gian hoặc không gian',
                'example': 'The disease spread throughout the country'
              }
            ],
            'relatedWords': ['During', 'Across', 'All over', 'Everywhere'],
            'synonyms': ['During', 'Across', 'All over', 'Everywhere']
          }
        ];
      }
      // Case 24: Từ vựng liên từ
      else if (query.toLowerCase() == 'nevertheless') {
        results = [
          {
            'word': 'Nevertheless',
            'type': 'conj.',
            'pronunciation': '/ˌnevəðəˈles/',
            'meaning': 'Tuy nhiên, dù sao đi nữa',
            'example': 'It was raining; nevertheless, we went for a walk',
            'definitions': [
              {
                'definition': 'Bất chấp điều gì đó',
                'example': 'The task was difficult; nevertheless, we completed it'
              }
            ],
            'relatedWords': ['However', 'Nonetheless', 'Still', 'Yet'],
            'synonyms': ['However', 'Nonetheless', 'Still', 'Yet']
          }
        ];
      }
      // Case 25: Từ vựng nguồn gốc Hy Lạp
      else if (query.toLowerCase() == 'philosophy') {
        results = [
          {
            'word': 'Philosophy',
            'type': 'n.',
            'pronunciation': '/fɪˈlɒsəfi/',
            'meaning': 'Triết học, triết lý',
            'example': 'He studied philosophy at university',
            'definitions': [
              {
                'definition': 'Nghiên cứu về bản chất của kiến thức và tồn tại',
                'example': 'Ancient Greek philosophy influenced Western thought'
              },
              {
                'definition': 'Hệ thống niềm tin hoặc thái độ',
                'example': 'Her philosophy of life is to enjoy every moment'
              }
            ],
            'relatedWords': ['Thought', 'Theory', 'Wisdom', 'Knowledge'],
            'synonyms': ['Thought', 'Theory', 'Wisdom', 'Knowledge']
          }
        ];
      }
      // Case 26: Từ vựng nguồn gốc Đức
      else if (query.toLowerCase() == 'zeitgeist') {
        results = [
          {
            'word': 'Zeitgeist',
            'type': 'n.',
            'pronunciation': '/ˈzaɪtɡaɪst/',
            'meaning': 'Tinh thần thời đại',
            'example': 'The novel captures the zeitgeist of the 1960s',
            'definitions': [
              {
                'definition': 'Tinh thần hoặc tâm trạng của một thời đại',
                'example': 'The art exhibition reflects the current zeitgeist'
              }
            ],
            'relatedWords': ['Spirit', 'Mood', 'Era', 'Period'],
            'synonyms': ['Spirit of the age', 'Mood of the time']
          }
        ];
      }
      // Case 27: Từ vựng phổ biến trung bình
      else if (query.toLowerCase() == 'perspective') {
        results = [
          {
            'word': 'Perspective',
            'type': 'n.',
            'pronunciation': '/pəˈspektɪv/',
            'meaning': 'Góc nhìn, quan điểm',
            'example': 'The story is told from multiple perspectives',
            'definitions': [
              {
                'definition': 'Cách nhìn hoặc hiểu về một vấn đề',
                'example': 'The article offers a new perspective on the issue'
              },
              {
                'definition': 'Kỹ thuật vẽ tạo cảm giác chiều sâu',
                'example': 'The artist used perspective to create depth'
              }
            ],
            'relatedWords': ['Viewpoint', 'Outlook', 'Aspect', 'Angle'],
            'synonyms': ['Viewpoint', 'Outlook', 'Aspect', 'Angle']
          }
        ];
      }
      // Case 28: Từ vựng phổ biến
      else if (query.toLowerCase() == 'essential') {
        results = [
          {
            'word': 'Essential',
            'type': 'adj.',
            'pronunciation': '/ɪˈsenʃl/',
            'meaning': 'Cần thiết, thiết yếu',
            'example': 'Water is essential for life',
            'definitions': [
              {
                'definition': 'Tuyệt đối cần thiết',
                'example': 'Good communication is essential in a relationship'
              },
              {
                'definition': 'Cơ bản hoặc quan trọng nhất',
                'example': 'The essential ingredients for the recipe are flour and eggs'
              }
            ],
            'relatedWords': ['Necessary', 'Important', 'Vital', 'Crucial'],
            'synonyms': ['Necessary', 'Important', 'Vital', 'Crucial']
          }
        ];
      }
      // Case 29: Từ vựng khoa học
      else if (query.toLowerCase() == 'hypothesis') {
        results = [
          {
            'word': 'Hypothesis',
            'type': 'n.',
            'pronunciation': '/haɪˈpɒθəsɪs/',
            'meaning': 'Giả thuyết, giả định khoa học',
            'example': 'The scientist tested her hypothesis through experiments',
            'definitions': [
              {
                'definition': 'Giả định có thể kiểm chứng',
                'example': 'The research team formulated a new hypothesis'
              },
              {
                'definition': 'Cơ sở cho nghiên cứu khoa học',
                'example': 'The hypothesis guided the experimental design'
              }
            ],
            'relatedWords': ['Theory', 'Assumption', 'Prediction', 'Research'],
            'synonyms': ['Theory', 'Proposition', 'Supposition', 'Postulate']
          }
        ];
      }
      // Case 30: Từ vựng tâm lý
      else if (query.toLowerCase() == 'cognitive') {
        results = [
          {
            'word': 'Cognitive',
            'type': 'adj.',
            'pronunciation': '/ˈkɒɡnətɪv/',
            'meaning': 'Thuộc về nhận thức, tư duy',
            'example': 'Cognitive development is crucial in early childhood',
            'definitions': [
              {
                'definition': 'Liên quan đến quá trình tư duy',
                'example': 'The study focused on cognitive abilities'
              },
              {
                'definition': 'Thuộc về nhận thức và hiểu biết',
                'example': 'Cognitive therapy helps change thought patterns'
              }
            ],
            'relatedWords': ['Mental', 'Intellectual', 'Psychological', 'Thinking'],
            'synonyms': ['Mental', 'Intellectual', 'Psychological', 'Thinking']
          }
        ];
      }
      // Case 31: Từ vựng xã hội
      else if (query.toLowerCase() == 'community') {
        results = [
          {
            'word': 'Community',
            'type': 'n.',
            'pronunciation': '/kəˈmjuːnəti/',
            'meaning': 'Cộng đồng, xã hội',
            'example': 'The local community organized a charity event',
            'definitions': [
              {
                'definition': 'Nhóm người sống cùng một khu vực',
                'example': 'The community center serves local residents'
              },
              {
                'definition': 'Nhóm người có chung đặc điểm',
                'example': 'The scientific community welcomed the discovery'
              }
            ],
            'relatedWords': ['Society', 'Group', 'Population', 'Neighborhood'],
            'synonyms': ['Society', 'Group', 'Population', 'Neighborhood']
          }
        ];
      }
      // Case 32: Từ vựng cấp độ A2
      else if (query.toLowerCase() == 'weather') {
        results = [
          {
            'word': 'Weather',
            'type': 'n.',
            'pronunciation': '/ˈweðə(r)/',
            'meaning': 'Thời tiết',
            'example': 'The weather is beautiful today',
            'definitions': [
              {
                'definition': 'Tình trạng khí quyển tại một thời điểm',
                'example': 'The weather forecast predicts rain tomorrow'
              }
            ],
            'relatedWords': ['Climate', 'Temperature', 'Rain', 'Sun'],
            'synonyms': ['Climate', 'Conditions', 'Atmosphere']
          }
        ];
      }
      // Case 33: Từ vựng cấp độ B1
      else if (query.toLowerCase() == 'environment') {
        results = [
          {
            'word': 'Environment',
            'type': 'n.',
            'pronunciation': '/ɪnˈvaɪrənmənt/',
            'meaning': 'Môi trường, hoàn cảnh',
            'example': 'We need to protect the environment',
            'definitions': [
              {
                'definition': 'Môi trường tự nhiên xung quanh',
                'example': 'The environment is affected by pollution'
              },
              {
                'definition': 'Điều kiện hoặc hoàn cảnh xung quanh',
                'example': 'The work environment is very friendly'
              }
            ],
            'relatedWords': ['Surroundings', 'Ecology', 'Nature', 'Setting'],
            'synonyms': ['Surroundings', 'Ecology', 'Nature', 'Setting']
          }
        ];
      }
      // Case 34: Từ vựng học thuật
      else if (query.toLowerCase() == 'methodology') {
        results = [
          {
            'word': 'Methodology',
            'type': 'n.',
            'pronunciation': '/ˌmeθəˈdɒlədʒi/',
            'meaning': 'Phương pháp luận',
            'example': 'The research methodology was carefully designed',
            'definitions': [
              {
                'definition': 'Hệ thống các phương pháp nghiên cứu',
                'example': 'The study used a qualitative methodology'
              },
              {
                'definition': 'Cách tiếp cận có hệ thống',
                'example': 'The methodology ensures reliable results'
              }
            ],
            'relatedWords': ['Approach', 'Technique', 'Procedure', 'System'],
            'synonyms': ['Approach', 'Technique', 'Procedure', 'System']
          }
        ];
      }
      // Case 35: Từ vựng chuyên ngành
      else if (query.toLowerCase() == 'paradigm') {
        results = [
          {
            'word': 'Paradigm',
            'type': 'n.',
            'pronunciation': '/ˈpærədaɪm/',
            'meaning': 'Mô hình, khuôn mẫu',
            'example': 'The new theory represents a paradigm shift',
            'definitions': [
              {
                'definition': 'Mô hình hoặc mẫu mực',
                'example': 'The research follows a new paradigm'
              },
              {
                'definition': 'Cách nhìn hoặc hiểu về một vấn đề',
                'example': 'The paradigm influences scientific thinking'
              }
            ],
            'relatedWords': ['Model', 'Pattern', 'Framework', 'Example'],
            'synonyms': ['Model', 'Pattern', 'Framework', 'Example']
          }
        ];
      }
      // Case 36: Từ vựng động từ
      else if (query.toLowerCase() == 'accomplish') {
        results = [
          {
            'word': 'Accomplish',
            'type': 'v.',
            'pronunciation': '/əˈkʌmplɪʃ/',
            'meaning': 'Hoàn thành, đạt được',
            'example': 'She accomplished all her goals',
            'definitions': [
              {
                'definition': 'Hoàn thành thành công',
                'example': 'The team accomplished the project on time'
              },
              {
                'definition': 'Đạt được mục tiêu',
                'example': 'He accomplished great things in his career'
              }
            ],
            'relatedWords': ['Achieve', 'Complete', 'Finish', 'Succeed'],
            'synonyms': ['Achieve', 'Complete', 'Finish', 'Succeed']
          }
        ];
      }
      // Case 37: Từ vựng danh từ
      else if (query.toLowerCase() == 'achievement') {
        results = [
          {
            'word': 'Achievement',
            'type': 'n.',
            'pronunciation': '/əˈtʃiːvmənt/',
            'meaning': 'Thành tựu, thành tích',
            'example': 'Winning the award was a great achievement',
            'definitions': [
              {
                'definition': 'Kết quả đạt được',
                'example': 'The project was a significant achievement'
              },
              {
                'definition': 'Thành công đáng kể',
                'example': 'Her academic achievements are impressive'
              }
            ],
            'relatedWords': ['Success', 'Accomplishment', 'Victory', 'Triumph'],
            'synonyms': ['Success', 'Accomplishment', 'Victory', 'Triumph']
          }
        ];
      }
      // Case 38: Từ vựng tính từ
      else if (query.toLowerCase() == 'remarkable') {
        results = [
          {
            'word': 'Remarkable',
            'type': 'adj.',
            'pronunciation': '/rɪˈmɑːkəbl/',
            'meaning': 'Đáng chú ý, nổi bật',
            'example': 'She made remarkable progress',
            'definitions': [
              {
                'definition': 'Đáng chú ý hoặc đặc biệt',
                'example': 'The results were remarkable'
              },
              {
                'definition': 'Khác thường hoặc nổi bật',
                'example': 'He has remarkable talent'
              }
            ],
            'relatedWords': ['Notable', 'Extraordinary', 'Outstanding', 'Exceptional'],
            'synonyms': ['Notable', 'Extraordinary', 'Outstanding', 'Exceptional']
          }
        ];
      }
      // Case 39: Từ vựng nguồn gốc Pháp
      else if (query.toLowerCase() == 'rendezvous') {
        results = [
          {
            'word': 'Rendezvous',
            'type': 'n.',
            'pronunciation': '/ˈrɒndeɪvuː/',
            'meaning': 'Cuộc hẹn, điểm hẹn',
            'example': 'Let\'s meet at our usual rendezvous',
            'definitions': [
              {
                'definition': 'Địa điểm hẹn gặp',
                'example': 'The cafe was their favorite rendezvous'
              },
              {
                'definition': 'Cuộc gặp gỡ đã hẹn trước',
                'example': 'They arranged a secret rendezvous'
              }
            ],
            'relatedWords': ['Meeting', 'Appointment', 'Date', 'Gathering'],
            'synonyms': ['Meeting', 'Appointment', 'Date', 'Gathering']
          }
        ];
      }
      // Case 40: Từ vựng nguồn gốc Latin
      else if (query.toLowerCase() == 'status quo') {
        results = [
          {
            'word': 'Status quo',
            'type': 'n.',
            'pronunciation': '/ˌsteɪtəs ˈkwəʊ/',
            'meaning': 'Hiện trạng, tình trạng hiện tại',
            'example': 'They want to maintain the status quo',
            'definitions': [
              {
                'definition': 'Tình trạng hiện tại của sự việc',
                'example': 'The policy preserves the status quo'
              }
            ],
            'relatedWords': ['Current state', 'Present situation', 'Existing condition'],
            'synonyms': ['Current state', 'Present situation', 'Existing condition']
          }
        ];
      }
      // Case 41: Từ vựng ít phổ biến
      else if (query.toLowerCase() == 'serendipity') {
        results = [
          {
            'word': 'Serendipity',
            'type': 'n.',
            'pronunciation': '/ˌserənˈdɪpəti/',
            'meaning': 'Sự tình cờ may mắn',
            'example': 'Finding the book was pure serendipity',
            'definitions': [
              {
                'definition': 'Khám phá tình cờ có giá trị',
                'example': 'The discovery was a result of serendipity'
              }
            ],
            'relatedWords': ['Fortuity', 'Chance', 'Luck', 'Discovery'],
            'synonyms': ['Fortuity', 'Chance', 'Luck', 'Discovery']
          }
        ];
      }
      // Case 42: Từ vựng hiếm gặp
      else if (query.toLowerCase() == 'defenestration') {
        results = [
          {
            'word': 'Defenestration',
            'type': 'n.',
            'pronunciation': '/ˌdiːfenɪˈstreɪʃn/',
            'meaning': 'Hành động ném ai đó ra khỏi cửa sổ',
            'example': 'The historical event involved the defenestration of officials',
            'definitions': [
              {
                'definition': 'Hành động ném người hoặc vật ra khỏi cửa sổ',
                'example': 'The defenestration was a dramatic political act'
              }
            ],
            'relatedWords': ['Ejection', 'Removal', 'Expulsion', 'Throwing'],
            'synonyms': ['Ejection', 'Removal', 'Expulsion', 'Throwing']
          }
        ];
      }
      // Case 43: Từ vựng kinh tế
      else if (query.toLowerCase() == 'inflation') {
        results = [
          {
            'word': 'Inflation',
            'type': 'n.',
            'pronunciation': '/ɪnˈfleɪʃn/',
            'meaning': 'Lạm phát',
            'example': 'The government is trying to control inflation',
            'definitions': [
              {
                'definition': 'Sự tăng giá chung của hàng hóa và dịch vụ',
                'example': 'Inflation affects purchasing power'
              },
              {
                'definition': 'Sự giảm giá trị của tiền tệ',
                'example': 'High inflation reduces savings value'
              }
            ],
            'relatedWords': ['Prices', 'Economy', 'Currency', 'Value'],
            'synonyms': ['Price rise', 'Cost increase', 'Economic growth']
          }
        ];
      }
      // Case 44: Từ vựng giáo dục
      else if (query.toLowerCase() == 'curriculum') {
        results = [
          {
            'word': 'Curriculum',
            'type': 'n.',
            'pronunciation': '/kəˈrɪkjələm/',
            'meaning': 'Chương trình giảng dạy',
            'example': 'The school updated its curriculum',
            'definitions': [
              {
                'definition': 'Kế hoạch học tập của một khóa học',
                'example': 'The curriculum includes various subjects'
              },
              {
                'definition': 'Nội dung giảng dạy được tổ chức',
                'example': 'The new curriculum emphasizes practical skills'
              }
            ],
            'relatedWords': ['Syllabus', 'Program', 'Course', 'Education'],
            'synonyms': ['Syllabus', 'Program', 'Course', 'Education']
          }
        ];
      }
      // Case 45: Từ vựng y học
      else if (query.toLowerCase() == 'diagnosis') {
        results = [
          {
            'word': 'Diagnosis',
            'type': 'n.',
            'pronunciation': '/ˌdaɪəɡˈnəʊsɪs/',
            'meaning': 'Chẩn đoán',
            'example': 'The doctor made a quick diagnosis',
            'definitions': [
              {
                'definition': 'Quá trình xác định bệnh',
                'example': 'Early diagnosis is important'
              },
              {
                'definition': 'Kết luận về tình trạng sức khỏe',
                'example': 'The diagnosis was confirmed by tests'
              }
            ],
            'relatedWords': ['Assessment', 'Evaluation', 'Analysis', 'Conclusion'],
            'synonyms': ['Assessment', 'Evaluation', 'Analysis', 'Conclusion']
          }
        ];
      }
      // Case 46: Từ vựng công nghệ
      else if (query.toLowerCase() == 'algorithm') {
        results = [
          {
            'word': 'Algorithm',
            'type': 'n.',
            'pronunciation': '/ˈælɡərɪðəm/',
            'meaning': 'Thuật toán',
            'example': 'The search algorithm is efficient',
            'definitions': [
              {
                'definition': 'Tập hợp các bước để giải quyết vấn đề',
                'example': 'The algorithm processes data quickly'
              },
              {
                'definition': 'Quy trình tính toán',
                'example': 'The sorting algorithm organizes information'
              }
            ],
            'relatedWords': ['Process', 'Method', 'Procedure', 'Computation'],
            'synonyms': ['Process', 'Method', 'Procedure', 'Computation']
          }
        ];
      }
      // Case 47: Từ vựng môi trường
      else if (query.toLowerCase() == 'sustainability') {
        results = [
          {
            'word': 'Sustainability',
            'type': 'n.',
            'pronunciation': '/səˌsteɪnəˈbɪləti/',
            'meaning': 'Tính bền vững',
            'example': 'The company focuses on sustainability',
            'definitions': [
              {
                'definition': 'Khả năng duy trì lâu dài',
                'example': 'Environmental sustainability is crucial'
              },
              {
                'definition': 'Sự cân bằng giữa phát triển và bảo vệ',
                'example': 'The project promotes sustainability'
              }
            ],
            'relatedWords': ['Ecology', 'Environment', 'Conservation', 'Renewable'],
            'synonyms': ['Durability', 'Endurance', 'Permanence', 'Continuity']
          }
        ];
      }
      // Case 48: Từ vựng nghệ thuật
      else if (query.toLowerCase() == 'aesthetic') {
        results = [
          {
            'word': 'Aesthetic',
            'type': 'adj.',
            'pronunciation': '/iːsˈθetɪk/',
            'meaning': 'Thẩm mỹ, nghệ thuật',
            'example': 'The design has aesthetic appeal',
            'definitions': [
              {
                'definition': 'Liên quan đến cái đẹp',
                'example': 'The painting has aesthetic value'
              },
              {
                'definition': 'Thuộc về thẩm mỹ',
                'example': 'The room has an aesthetic design'
              }
            ],
            'relatedWords': ['Beautiful', 'Artistic', 'Stylish', 'Elegant'],
            'synonyms': ['Beautiful', 'Artistic', 'Stylish', 'Elegant']
          }
        ];
      }
      // Case 49: Từ vựng âm nhạc
      else if (query.toLowerCase() == 'harmony') {
        results = [
          {
            'word': 'Harmony',
            'type': 'n.',
            'pronunciation': '/ˈhɑːməni/',
            'meaning': 'Hòa âm, sự hài hòa',
            'example': 'The choir sang in perfect harmony',
            'definitions': [
              {
                'definition': 'Sự kết hợp âm thanh hài hòa',
                'example': 'The music has beautiful harmony'
              },
              {
                'definition': 'Sự hòa hợp, cân bằng',
                'example': 'The colors create visual harmony'
              }
            ],
            'relatedWords': ['Melody', 'Balance', 'Unity', 'Agreement'],
            'synonyms': ['Melody', 'Balance', 'Unity', 'Agreement']
          }
        ];
      }
      // Case 50: Từ vựng du lịch
      else if (query.toLowerCase() == 'destination') {
        results = [
          {
            'word': 'Destination',
            'type': 'n.',
            'pronunciation': '/ˌdestɪˈneɪʃn/',
            'meaning': 'Điểm đến',
            'example': 'Paris is a popular tourist destination',
            'definitions': [
              {
                'definition': 'Nơi đến cuối cùng',
                'example': 'The train\'s destination is London'
              },
              {
                'definition': 'Địa điểm du lịch',
                'example': 'The island is a dream destination'
              }
            ],
            'relatedWords': ['Location', 'Place', 'Spot', 'Terminus'],
            'synonyms': ['Location', 'Place', 'Spot', 'Terminus']
          }
        ];
      }
      // Case 51: Từ vựng thể thao
      else if (query.toLowerCase() == 'championship') {
        results = [
          {
            'word': 'Championship',
            'type': 'n.',
            'pronunciation': '/ˈtʃæmpiənʃɪp/',
            'meaning': 'Giải vô địch',
            'example': 'The team won the championship',
            'definitions': [
              {
                'definition': 'Cuộc thi để xác định nhà vô địch',
                'example': 'The championship was very competitive'
              },
              {
                'definition': 'Danh hiệu vô địch',
                'example': 'He holds three championships'
              }
            ],
            'relatedWords': ['Tournament', 'Competition', 'Title', 'Victory'],
            'synonyms': ['Tournament', 'Competition', 'Title', 'Victory']
          }
        ];
      }
      // Case 52: Từ vựng ẩm thực
      else if (query.toLowerCase() == 'cuisine') {
        results = [
          {
            'word': 'Cuisine',
            'type': 'n.',
            'pronunciation': '/kwɪˈziːn/',
            'meaning': 'Ẩm thực, phong cách nấu ăn',
            'example': 'French cuisine is famous worldwide',
            'definitions': [
              {
                'definition': 'Phong cách nấu ăn đặc trưng',
                'example': 'The restaurant serves Italian cuisine'
              },
              {
                'definition': 'Nghệ thuật nấu ăn',
                'example': 'She studied gourmet cuisine'
              }
            ],
            'relatedWords': ['Food', 'Cooking', 'Dishes', 'Recipes'],
            'synonyms': ['Food', 'Cooking', 'Dishes', 'Recipes']
          }
        ];
      }
      // Case 53: Từ vựng thời trang
      else if (query.toLowerCase() == 'trend') {
        results = [
          {
            'word': 'Trend',
            'type': 'n.',
            'pronunciation': '/trend/',
            'meaning': 'Xu hướng, trào lưu',
            'example': 'This color is the latest trend',
            'definitions': [
              {
                'definition': 'Hướng phát triển chung',
                'example': 'The trend shows increasing sales'
              },
              {
                'definition': 'Phong cách thịnh hành',
                'example': 'The fashion trend changes quickly'
              }
            ],
            'relatedWords': ['Style', 'Fashion', 'Tendency', 'Direction'],
            'synonyms': ['Style', 'Fashion', 'Tendency', 'Direction']
          }
        ];
      }
      // Case mặc định
      else {
        results = [
          {
            'word': query,
            'type': 'n.',
            'pronunciation': '/ˈprɒnʌnsɪˈeɪʃən/',
            'meaning': 'Nghĩa của từ',
            'example': 'This is an example sentence',
            'definitions': [
              {
                'definition': 'Định nghĩa 1',
                'example': 'Example 1'
              }
            ],
            'relatedWords': ['Related 1', 'Related 2'],
            'synonyms': ['Synonym 1', 'Synonym 2']
          }
        ];
      }
      
      setState(() {
        _suggestedWords = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Lỗi',
        'Không thể tìm kiếm từ: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _showWordDetails(Map<String, dynamic> word) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Lấy thông tin chi tiết từ API
      final details = await _translateService.getWordDetails(word['word']);
      
      setState(() {
        _selectedWord = details;
        _showDetails = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Lỗi',
        'Không thể tải chi tiết từ: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _saveToSearchHistory(Map<String, dynamic> word) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      await SearchHistory.saveSearchHistory(
        userId: userId,
        word: word['word'],
        meaning: word['meaning'],
      );
      
      Get.snackbar(
        'Thông báo',
        'Đã lưu "${word['word']}" vào lịch sử tìm kiếm',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error saving to search history: $e');
    }
  }

  void _addToFlashcard(Map<String, dynamic> word) {
    Get.dialog(
      AlertDialog(
        title: const Text('Thêm vào bộ thẻ ghi nhớ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Từ: ${word['word']}'),
            const SizedBox(height: 16),
            const Text('Chọn hành động:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _showSelectExistingFlashcardDialog(word);
            },
            child: const Text('Thêm vào bộ thẻ hiện có'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _showCreateNewFlashcardDialog(word);
            },
            child: const Text('Tạo bộ thẻ mới'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showSelectExistingFlashcardDialog(Map<String, dynamic> word) {
    // Giả lập danh sách flashcard hiện có
    final flashcards = [
      {'id': '1', 'title': 'Từ vựng tiếng Anh cơ bản'},
      {'id': '2', 'title': 'Từ vựng chuyên ngành'},
      {'id': '3', 'title': 'Từ vựng IELTS'},
      {'id': '4', 'title': 'Từ vựng TOEIC'},
    ];

    Get.dialog(
      AlertDialog(
        title: const Text('Chọn bộ thẻ'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: flashcards.length,
            itemBuilder: (context, index) {
              final flashcard = flashcards[index];
              return ListTile(
                title: Text(flashcard['title'] as String),
                onTap: () {
                  Get.back();
                  // Giả lập thêm vào flashcard
                  Get.snackbar(
                    'Thành công',
                    'Đã thêm "${word['word']}" vào bộ thẻ "${flashcard['title']}"',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _showCreateNewFlashcardDialog(Map<String, dynamic> word) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Tạo bộ thẻ mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Từ đầu tiên: ${word['word']}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tên bộ thẻ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isEmpty) {
                Get.snackbar(
                  'Lỗi',
                  'Vui lòng nhập tên bộ thẻ',
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }
              
              Get.back();
              // Giả lập tạo flashcard mới
              Get.snackbar(
                'Thành công',
                'Đã tạo bộ thẻ "${titleController.text}" với từ "${word['word']}"',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra từ điển'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Get.to(() => const SearchHistoryScreen()),
            tooltip: 'Lịch sử tìm kiếm',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Nhập từ cần tra...',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _suggestedWords = [];
                                _showDetails = false;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: _searchWord,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhập từ cần tra để xem nghĩa và thêm vào bộ thẻ ghi nhớ',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showDetails && _selectedWord != null
                    ? _buildWordDetailsView(_selectedWord!)
                    : _buildSuggestedWordsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedWordsView() {
    if (_suggestedWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Nhập từ cần tra để bắt đầu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suggestedWords.length,
      itemBuilder: (context, index) {
        final word = _suggestedWords[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              word['word'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${word['type'] as String} ${word['pronunciation'] as String}',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  word['meaning'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showWordDetails(word),
          ),
        );
      },
    );
  }

  Widget _buildWordDetailsView(Map<String, dynamic> word) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showDetails = false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  word['word'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  // Phát âm từ (cần tích hợp với text-to-speech)
                  Get.snackbar(
                    'Thông báo',
                    'Đang phát âm: ${word['word']}',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${word['type'] as String} ${word['pronunciation'] as String}',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nghĩa:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            word['meaning'] as String,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ví dụ:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              word['example'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (word['definitions'] != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Định nghĩa:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...List<Widget>.from((word['definitions'] as List<dynamic>).map(
              (definition) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ${definition['definition']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (definition['example'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '   "${definition['example']}"',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )),
          ],
          const SizedBox(height: 24),
          const Text(
            'Từ liên quan:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (word['relatedWords'] as List<dynamic>).map((relatedWord) {
              return Chip(
                label: Text(relatedWord as String),
                backgroundColor: Colors.grey.shade200,
              );
            }).toList(),
          ),
          if (word['synonyms'] != null && (word['synonyms'] as List).isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Từ đồng nghĩa:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (word['synonyms'] as List<dynamic>).map((synonym) {
                return Chip(
                  label: Text(synonym as String),
                  backgroundColor: Colors.green.shade100,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Thêm vào bộ thẻ ghi nhớ'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _addToFlashcard(word),
            ),
          ),
          const SizedBox(height: 16),
          // Thêm nút lưu vào lịch sử tìm kiếm
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Lưu vào lịch sử tìm kiếm'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _saveToSearchHistory(word),
            ),
          ),
        ],
      ),
    );
  }
}