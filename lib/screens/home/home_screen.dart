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
import '../materials/student_materials_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    // const FoldersTab(),
     AIChatTab(),
    // const StudentMaterialsScreen(),
    const ProfileTab(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Trang chủ',
    ),
    // const BottomNavigationBarItem(
    //   icon: Icon(Icons.folder_outlined),
    //   activeIcon: Icon(Icons.folder),
    //   label: 'Thư mục',
    // ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.chat_outlined),
      activeIcon: Icon(Icons.chat),
      label: 'AI Chat',
    ),
    // const BottomNavigationBarItem(
    //   icon: Icon(Icons.menu_book_outlined),
    //   activeIcon: Icon(Icons.menu_book),
    //   label: 'Tài liệu',
    // ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Hồ sơ',
    ),
  ];

  void _onItemTapped(int index) {
    // if (index == 2) {
    //   // Index của nút "+"
    //   _showAddMenu();
    // } else {
      setState(() {
        _currentIndex = index;
      });
    
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
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: _bottomNavItems,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
