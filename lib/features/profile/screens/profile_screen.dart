import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/features/profile/controllers/profile_controller.dart';
import 'package:flutter_app/features/profile/screens/notifications_screen.dart';
import 'package:flutter_app/features/profile/screens/search_screen.dart';
import 'package:flutter_app/features/profile/widgets/friend_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// The main profile screen, designed to be a tab in the [HomeScreen].
///
/// Uses [GetX] to observe the [ProfileController] for user info and friends.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the ProfileController, which is initialized in HomeScreen's binding
    final ProfileController controller = Get.find<ProfileController>();
    // Find the AuthService for logging out
    final AuthService authService = Get.find<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          // Notifications Button
          IconButton(
            icon: Obx(() {
              // Show a badge if there are notifications
              final count = controller.notificationsList.length;
              return Badge(
                label: Text(count.toString()),
                isLabelVisible: count > 0,
                child: const Icon(Icons.notifications_outlined),
              );
            }),
            onPressed: () {
              Get.to(() => const NotificationsScreen());
            },
          ),
          // Search Button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Get.to(() => const SearchScreen());
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              Get.defaultDialog(
                title: 'Logout',
                titleStyle: const TextStyle(color: ChatHubTheme.textOnSurface),
                middleText: 'Are you sure you want to log out?',
                middleTextStyle: const TextStyle(color: ChatHubTheme.textOnSurface),
                backgroundColor: ChatHubTheme.surface,
                buttonColor: ChatHubTheme.primary,
                textConfirm: 'Logout',
                textCancel: 'Cancel',
                confirmTextColor: ChatHubTheme.textOnPrimary,
                cancelTextColor: ChatHubTheme.textOnSurface,
                onConfirm: () {
                  authService.logout();
                  Get.back(); // Close dialog
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: ChatHubTheme.primary,
        backgroundColor: ChatHubTheme.surface,
        onRefresh: () async {
          // Refresh all data
          controller.fetchAllData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Profile Header ---
              Obx(() {
                if (controller.isLoadingProfile.value &&
                    controller.userProfile.value == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: ChatHubTheme.primary),
                  );
                }
                final user = controller.userProfile.value;
                if (user == null) {
                  return const Center(child: Text('Could not load profile.'));
                }
                return _buildProfileHeader(user);
              }),
              const SizedBox(height: 24),
              
              // --- Friends List ---
              Text(
                'Friends',
                style: Get.textTheme.titleLarge?.copyWith(
                  color: ChatHubTheme.textOnSurface,
                ),
              ),
              const SizedBox(height: 10),
              Obx(() {
                if (controller.isLoadingFriends.value &&
                    controller.friendsList.isEmpty) {
                  return const Center(child: Text('Loading friends...'));
                }
                if (controller.friendsList.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'You have no friends yet. Use the search icon to find users!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }
                // Use ListView.separated for a non-scrolling column
                return ListView.separated(
                  shrinkWrap: true, // Important in a SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.friendsList.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: ChatHubTheme.backgroundLight,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final friend = controller.friendsList[index];
                    return FriendListTile(friend: friend);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the top section of the profile screen.
  Widget _buildProfileHeader(UserProfile user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(user.avatarUrl),
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: Get.textTheme.headlineSmall?.copyWith(
              color: ChatHubTheme.textOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${user.username}',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.bio,
            textAlign: TextAlign.center,
            style: Get.textTheme.bodyLarge?.copyWith(
              color: ChatHubTheme.textOnSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Joined: ${DateFormat.yMMMd().format(user.createdAt)}',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
