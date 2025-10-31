import 'package:flutter_app/core/api/socket_service.dart';
import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/core/services/notification_service.dart';
import 'package:flutter_app/features/home/screens/chat_list_tab.dart';
import 'package:flutter_app/features/home/screens/groups_list_tab.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const ChatListTab(),
    const GroupsListTab(),
    const ProfilePlaceholderTab(), // Placeholder for profile
  ];

  @override
  void initState() {
    super.initState();
    _connectServices();
  }

  /// Connects to Socket.io and updates the FCM token
  void _connectServices() async {
    // Use context.read inside initState as it's a one-time call
    final authService = context.read<AuthService>();
    final socketService = context.read<SocketService>();

    // Get auth token
    final token = await authService.getUserToken();
    
    // Get FCM token
    final fcmToken = await NotificationService().getFcmToken();

    if (token != null && fcmToken != null) {
      // Connect to socket
      socketService.connect(token, fcmToken);

      // TODO: You might want to update the FCM token on the server
      // using ApiService here as well, if it has changed.
      // context.read<ApiService>().updateFcmToken(fcmToken);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Chats' : _selectedIndex == 1 ? 'Groups' : 'Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to Search Screen
              // Get.toNamed('/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Navigate to Notifications Screen
              // Get.toNamed('/notifications');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () {
                // TODO: Navigate to create new chat/group screen
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// A placeholder widget for the Profile tab.
class ProfilePlaceholderTab extends StatelessWidget {
  const ProfilePlaceholderTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final socketService = context.watch<SocketService>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Profile Tab',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to the full profile screen
              // Get.toNamed('/profile');
            },
            child: const Text('View Full Profile'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Disconnect socket and log out
              socketService.disconnect();
              authService.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
