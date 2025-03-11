import 'package:base_flutter_framework/screens/profile/delete_account_screen.dart';
import 'package:base_flutter_framework/screens/profile/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/app_user.dart';
import '../../../services/auth_service.dart';
import '../../auth/login_screen.dart';

class ProfileTab extends StatelessWidget {
  final AuthService _authService = AuthService();

  ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.currentUserStream,
      builder: (context, snapshot) {
        final user = snapshot.data ?? _authService.currentUser;

        if (user == null) {
          return const Center(
            child: Text('Vui lòng đăng nhập lại'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  // Navigate to settings
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Profile picture
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: user.avatar != null
                      ? null // In a real app, load the image here
                      : const Icon(Icons.person,
                          size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),

                // User name
                Text(
                  user.fullName ?? 'User',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),

                // User email
                Text(
                  user.email ?? 'email@example.com',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),

                // Stats section
                _buildStatsSection(context),
                const SizedBox(height: 32),

                // Options section
                _buildOptionsSection(),
                const SizedBox(height: 32),

                // Sign out button
                ElevatedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await _authService.signOut();
      Get.offAll(() => LoginScreen());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  Widget _buildStatsSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Stats',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Flashcards', '42', context),
                _buildStatItem('Quizzes', '15', context),
                _buildStatItem('Streak', '7 days', context),
              ],
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(
              value: 0.65,
              backgroundColor: Colors.grey,
              minHeight: 8,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            const SizedBox(height: 8),
            Text(
              'Level 5: Intermediate',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    final user = _authService.currentUser;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildOptionTile(
            'Edit Profile',
            Icons.edit,
            () {
              Get.to(() => EditProfileScreen(user: user ?? User()));
            },
          ),
          const Divider(height: 1),
          _buildOptionTile(
            'My Classes',
            Icons.class_,
            () {
              // Navigate to classes
            },
          ),
          const Divider(height: 1),
          _buildOptionTile(
            'Learning Reminders',
            Icons.notifications,
            () {
              // Navigate to reminders
            },
          ),
          const Divider(height: 1),
          _buildOptionTile(
            'Language Settings',
            Icons.language,
            () {
              // Navigate to language settings
            },
          ),
          const Divider(height: 1),
          _buildOptionTile(
            'Help & Support',
            Icons.help,
            () {
              // Navigate to help
            },
          ),
          _buildOptionTile(
            'Delete Account',
            Icons.delete,
            () {
              Get.to(() => DeleteAccountScreen());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
