import 'package:base_flutter_framework/screens/classroom/classroom_list_screen.dart';
import 'package:base_flutter_framework/screens/classroom/create_edit_classroom_screen.dart';
import 'package:base_flutter_framework/screens/folder/create_edit_folder_screen.dart';
import 'package:base_flutter_framework/screens/home/tabs/ai_chat_tab.dart';
import 'package:base_flutter_framework/screens/home/tabs/classrooms_tab.dart';
import 'package:base_flutter_framework/screens/home/tabs/folders_tab.dart';
import 'package:flutter/material.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/profile_tab.dart';
import '../flashcards/create_edit_flashcard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Chuyển đổi giữa selected index và actual index
  int get _currentIndex {
    if (_selectedIndex < 2) return _selectedIndex;
    return _selectedIndex - 1; // Bỏ qua tab "+" ở giữa
  }

  final List<Widget> _tabs = [
    DashboardTab(),
    FoldersTab(),
    AIChatTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Index của nút "+"
      _showAddMenu();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showAddMenu() {
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
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.style, color: Colors.blue),
                ),
                title: const Text('Tạo bộ flashcard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateEditFlashcardScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.class_, color: Colors.green),
                ),
                title: const Text('Tạo lớp học'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateEditClassroomScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.folder, color: Colors.orange),
                ),
                title: const Text('Tạo thư mục'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateEditFolderScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Thư mục',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'AI Chat',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
