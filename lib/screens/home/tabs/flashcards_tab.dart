import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/flashcard.dart';
import '../../../services/auth_service.dart';

class FlashcardsTab extends StatefulWidget {
  @override
  _FlashcardsTabState createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<FlashcardsTab> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  List<Flashcard> _flashcards = [];

  @override
  void initState() {
    super.initState();
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Implement flashcard repository to load actual flashcards
    // For now, we'll use dummy data
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _flashcards = [
        Flashcard(
          id: '1',
          title: 'Basic English Vocabulary',
          description: 'Common words and phrases for beginners',
          userId: _authService.currentUser?.id ?? '',
          isPublic: true,
        ),
        Flashcard(
          id: '2',
          title: 'Intermediate Grammar',
          description: 'Grammar rules for intermediate learners',
          userId: _authService.currentUser?.id ?? '',
          isPublic: false,
        ),
        Flashcard(
          id: '3',
          title: 'Business English',
          description: 'Vocabulary and phrases for professional settings',
          userId: _authService.currentUser?.id ?? '',
          isPublic: true,
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implement filter functionality
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flashcards.isEmpty
              ? _buildEmptyState()
              : _buildFlashcardsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create flashcard screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Flashcards Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first flashcard set to start learning',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to create flashcard screen
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Flashcard Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _flashcards.length,
      itemBuilder: (context, index) {
        final flashcard = _flashcards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              // Navigate to flashcard detail screen
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          flashcard.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        flashcard.isPublic ? Icons.public : Icons.lock,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    flashcard.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // This would be the actual count from the database
                      Text(
                        '${index * 10 + 5} cards',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () {
                              // Navigate to edit flashcard screen
                            },
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_arrow, size: 20),
                            onPressed: () {
                              // Navigate to practice flashcard screen
                            },
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onPressed: () {
                              _showFlashcardOptions(flashcard);
                            },
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFlashcardOptions(Flashcard flashcard) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement share functionality
                },
              ),
              ListTile(
                leading: Icon(
                  flashcard.isPublic ? Icons.lock : Icons.public,
                ),
                title: Text(
                  flashcard.isPublic ? 'Make Private' : 'Make Public',
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Implement visibility toggle
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Duplicate'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement duplicate functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(flashcard);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(Flashcard flashcard) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Flashcard Set'),
          content: Text(
            'Are you sure you want to delete "${flashcard.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement delete functionality
                setState(() {
                  _flashcards.removeWhere((f) => f.id == flashcard.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${flashcard.title} deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        // Implement undo functionality
                        setState(() {
                          _flashcards.add(flashcard);
                          _flashcards.sort((a, b) => a.title.compareTo(b.title));
                        });
                      },
                    ),
                  ),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
} 