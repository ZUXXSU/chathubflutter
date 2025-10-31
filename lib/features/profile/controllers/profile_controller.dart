import 'package:flutter_app/core/api/api_service.dart';
import 'package:flutter_app/core/models/FriendRequestNotification.dart';
import 'package:flutter_app/core/models/user.dart'; // <-- ADDED THIS IMPORT
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter_app/features/profile/screens/notifications_screen.dart';
import 'package:flutter_app/features/profile/screens/search_screen.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

/// Manages the state for the main Profile screen using GetX.
///
/// This controller is responsible for:
/// - Fetching the user's main profile ([UserProfile]).
/// - Fetching the user's friend list ([PopulatedUser]).
/// - Fetching the user's pending friend requests ([Notification]).
/// - Handling acceptance/rejection of friend requests.
/// - Providing navigation to Search and Notifications screens.
class ProfileController extends GetxController {
  // Find services injected by GlobalBindings
  final ApiService _apiService = Get.find<ApiService>();

  // --- State Observables ---

  /// Holds the main user profile data.
  var userProfile = Rx<UserProfile?>(null);

  /// Holds the list of the user's friends.
  var friendList = Rx<List<PopulatedUser>>([]);

  /// Holds the list of pending friend requests.
  var notificationList = Rx<List<Notification>>([]);

  /// General loading state for the whole screen.
  var isLoading = false.obs;

  /// Loading state specifically for the friend request list.
  var isNotificationLoading = false.obs;

  // --- Initialization ---

  @override
  void onInit() {
    super.onInit();
    // Fetch all initial data when the controller is first created
    _fetchAllData();
  }

  // --- Private Data Fetching Methods ---

  /// Fetches all data required for the profile screen.
  Future<void> _fetchAllData() async {
    isLoading(true);
    await Future.wait([
      _fetchUserProfile(),
      _fetchFriends(),
      _fetchNotifications(),
    ]);
    isLoading(false);
  }

  /// Fetches the main user profile.
  Future<void> _fetchUserProfile() async {
    try {
      final data = await _apiService.getMyProfile();
      userProfile.value = UserProfile.fromJson(data['user']);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load profile: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Fetches the user's friend list.
  Future<void> _fetchFriends() async {
    try {
      final data = await _apiService.getMyFriends();
      friendList.value = (data as List)
          .map((item) => PopulatedUser.fromJson(item))
          .toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load friends: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Fetches pending friend requests.
  Future<void> _fetchNotifications() async {
    try {
      isNotificationLoading(true); // Use specific loader
      final data = await _apiService.getMyNotifications();
      notificationList.value = (data as List)
          .map((item) => Notification.fromJson(item))
          .toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load notifications: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isNotificationLoading(false);
    }
  }

  // --- Public Methods (Called from UI) ---

  /// Handles the logic for accepting or rejecting a friend request.
  Future<void> handleFriendRequest(String requestId, bool accept) async {
    try {
      final message = accept ? 'Friend request accepted' : 'Friend request rejected';
      
      await _apiService.acceptFriendRequest(
        requestId: requestId,
        accept: accept,
      );

      // Show success message
      Helpers.showSuccessSnackbar('Success ${message}');

      // Optimistically remove the request from the list
      notificationList.removeWhere((req) => req.id == requestId);

      // If we accepted, refresh the friend list
      if (accept) {
        _fetchFriends();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to handle request: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Refreshes all profile data.
  Future<void> refreshData() async {
    await _fetchAllData();
  }

  /// Refreshes just the notification list.
  Future<void> refreshNotifications() async {
    await _fetchNotifications();
  }
  
  // --- Navigation ---

  /// Navigates to the [NotificationsScreen].
  void goToNotifications() {
    Get.to(() => NotificationsScreen());
  }

  /// Navigates to the [SearchScreen].
  void goToSearch() {
    Get.to(() => SearchScreen());
  }

  /// Logs the user out.
  void logout() {
    // We can access AuthService via GetX as well
    final authService = Get.find<AuthService>();
    authService.logout();
    // The AuthWrapper in app.dart will handle navigation
  }
}

