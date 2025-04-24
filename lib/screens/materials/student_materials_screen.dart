import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/learning_material.dart' as lm;
import '../../services/auth_service.dart';
import '../../services/material_service.dart';
import 'material_details_screen.dart';

class StudentMaterialsScreen extends StatefulWidget {
  const StudentMaterialsScreen({Key? key}) : super(key: key);

  @override
  _StudentMaterialsScreenState createState() => _StudentMaterialsScreenState();
}

class _StudentMaterialsScreenState extends State<StudentMaterialsScreen> with SingleTickerProviderStateMixin {
  final MaterialService _materialService = MaterialService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  String _searchQuery = '';
  
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  List<lm.LearningMaterial> _myMaterials = [];
  List<lm.LearningMaterial> _publicMaterials = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMaterials();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      // Load public materials
      _materialService.getPublicMaterials().listen((materials) {
        if (mounted) {
          setState(() {
            _publicMaterials = materials;
            _isLoading = false;
          });
        }
      }, onError: (e) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Không thể tải danh sách tài liệu: ${e.toString()}';
            _isLoading = false;
          });
        }
      });
      
      // Load user downloads (placeholder - would normally track downloads by user)
      // In a real app, you would get downloads filtered by the current user
      _materialService.getUserMaterials().listen((materials) {
        if (mounted) {
          setState(() {
            _myMaterials = materials;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Không thể tải danh sách tài liệu: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
  }
  
  List<lm.LearningMaterial> get _filteredMyMaterials {
    if (_searchQuery.isEmpty) return _myMaterials;
    
    return _myMaterials.where((material) {
      return material.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             material.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             material.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }
  
  List<lm.LearningMaterial> get _filteredPublicMaterials {
    if (_searchQuery.isEmpty) return _publicMaterials;
    
    return _publicMaterials.where((material) {
      return material.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             material.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             material.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài liệu học tập'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đã tải xuống'),
            Tab(text: 'Thư viện'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _MaterialSearchDelegate(
                  allMaterials: [..._myMaterials, ..._publicMaterials],
                  onResultTap: (material) {
                    Get.to(() => MaterialDetailsScreen(material: material as lm.LearningMaterial));
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMaterials,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Đã tải xuống
          _buildMaterialsList(
            _filteredMyMaterials,
            _isLoading,
            _hasError,
            _errorMessage,
            'Bạn chưa tải xuống tài liệu nào',
          ),
          
          // Tab 2: Thư viện
          _buildMaterialsList(
            _filteredPublicMaterials,
            _isLoading,
            _hasError,
            _errorMessage,
            'Không có tài liệu công khai nào',
          ),
        ],
      ),
    );
  }
  
  Widget _buildMaterialsList(
    List<lm.LearningMaterial> materials,
    bool isLoading, 
    bool hasError,
    String errorMessage,
    String emptyMessage,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMaterials,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    
    if (materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadMaterials,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: materials.length,
        itemBuilder: (context, index) {
          final material = materials[index];
          return _buildMaterialCard(material);
        },
      ),
    );
  }
  
  Widget _buildMaterialCard(lm.LearningMaterial material) {
    // Xác định icon và màu cho loại tài liệu
    IconData typeIcon;
    Color typeColor;
    
    switch (material.type) {
      case lm.MaterialType.document:
        typeIcon = Icons.description;
        typeColor = Colors.blue;
        break;
      case lm.MaterialType.video:
        typeIcon = Icons.video_library;
        typeColor = Colors.red;
        break;
      case lm.MaterialType.audio:
        typeIcon = Icons.audiotrack;
        typeColor = Colors.purple;
        break;
      case lm.MaterialType.image:
        typeIcon = Icons.image;
        typeColor = Colors.green;
        break;
      case lm.MaterialType.link:
        typeIcon = Icons.link;
        typeColor = Colors.orange;
        break;
      default:
        typeIcon = Icons.folder;
        typeColor = Colors.grey;
    }
    
    // Format ngày tạo
    final dateFormat = DateFormat('dd/MM/yyyy');
    final createdDate = material.createdAt != null 
        ? dateFormat.format(material.createdAt!.toDate())
        : 'N/A';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Get.to(() => MaterialDetailsScreen(material: material));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(typeIcon, color: typeColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      material.typeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                  ),
                  Text(
                    createdDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    material.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Tags
                  if (material.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: material.tags.map((tag) => Chip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        label: Text(
                          tag,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.grey.shade200,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      )).toList(),
                    ),
                  ],
                  
                  // Stats
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            material.authorName ?? 'Không có tên',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.download_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${material.downloads} lượt tải',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      if (material.fileSize != null)
                        Row(
                          children: [
                            const Icon(Icons.storage_outlined, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              material.fileSizeFormatted ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialSearchDelegate extends SearchDelegate<lm.LearningMaterial?> {
  final List<lm.LearningMaterial> allMaterials;
  final Function(lm.LearningMaterial) onResultTap;
  
  _MaterialSearchDelegate({
    required this.allMaterials,
    required this.onResultTap,
  });
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }
  
  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nhập từ khóa để tìm kiếm tài liệu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }
    
    final results = allMaterials.where((material) {
      return material.title.toLowerCase().contains(query.toLowerCase()) ||
             material.description.toLowerCase().contains(query.toLowerCase()) ||
             material.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
    }).toList();
    
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy tài liệu phù hợp',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final material = results[index];
        
        // Xác định icon và màu cho loại tài liệu
        IconData typeIcon;
        Color typeColor;
        
        switch (material.type) {
          case lm.MaterialType.document:
            typeIcon = Icons.description;
            typeColor = Colors.blue;
            break;
          case lm.MaterialType.video:
            typeIcon = Icons.video_library;
            typeColor = Colors.red;
            break;
          case lm.MaterialType.audio:
            typeIcon = Icons.audiotrack;
            typeColor = Colors.purple;
            break;
          case lm.MaterialType.image:
            typeIcon = Icons.image;
            typeColor = Colors.green;
            break;
          case lm.MaterialType.link:
            typeIcon = Icons.link;
            typeColor = Colors.orange;
            break;
          default:
            typeIcon = Icons.folder;
            typeColor = Colors.grey;
        }
        
        return ListTile(
          leading: Icon(typeIcon, color: typeColor),
          title: Text(
            material.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            material.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            close(context, material);
            onResultTap(material);
          },
        );
      },
    );
  }
} 