import 'package:base_flutter_framework/screens/classroom/join_by_code_screen.dart';
import 'package:base_flutter_framework/screens/classroom/search_classrooms_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClassroomsTab extends StatefulWidget {
  const ClassroomsTab({Key? key}) : super(key: key);

  @override
  _ClassroomsTabState createState() => _ClassroomsTabState();
}

class _ClassroomsTabState extends State<ClassroomsTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lớp học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Get.to(() => const SearchClassroomsScreen());
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: () async {
              final result = await Get.to(() => const JoinByCodeScreen());
              if (result == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tham gia lớp học thành công')),
                );
                _loadClassrooms(); // Reload danh sách lớp sau khi tham gia
              }
            },
          ),
        ],
      ),
      body: Container(),
    );
  }

  void _loadClassrooms() {
    // Implementation of _loadClassrooms method
  }
}
