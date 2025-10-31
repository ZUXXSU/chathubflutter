import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/features/profile/controllers/profile_controller.dart';
import 'package:flutter_app/features/profile/widgets/notification_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A screen that displays the user's pending friend requests.
///
/// Uses [GetX] to observe the [ProfileController] and display the
/// list of notifications.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the already initialized ProfileController
    final ProfileController controller = Get.find<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Obx(
        () {
          if (controller.isLoadingNotifications.value &&
              controller.notificationsList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: ChatHubTheme.primary),
            );
          }

          if (controller.notificationsList.isEmpty) {
            return RefreshIndicator(
              color: ChatHubTheme.primary,
              backgroundColor: ChatHubTheme.surface,
              onRefresh: () => controller.fetchMyNotifications(),
              child: const Center(
                child: Text(
                  'You have no new notifications.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: ChatHubTheme.primary,
            backgroundColor: ChatHubTheme.surface,
            onRefresh: () => controller.fetchMyNotifications(),
            child: ListView.builder(
              itemCount: controller.notificationsList.length,
              itemBuilder: (context, index) {
                final request = controller.notificationsList[index];
                return NotificationListTile(request: request);
              },
            ),
          );
        },
      ),
    );
  }
}
