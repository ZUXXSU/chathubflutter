import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/features/auth/screens/login_screen.dart';
import 'package:flutter_app/features/auth/screens/register_screen.dart';
import 'package:flutter_app/features/home/screens/home_screen.dart';
import 'package:flutter_app/global_bindings.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// The root widget of the application.
///
/// Sets up [GetMaterialApp] for navigation, theming, and
/// global dependency injection via [GlobalBindings].
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ChatHub',
      theme: darkTheme, // Apply the custom dark theme
      debugShowCheckedModeBanner: false,

      // Set up global dependencies for GetX
      initialBinding: GlobalBindings(),

      // The initial screen is the AuthWrapper, which decides
      // whether to show the LoginScreen or HomeScreen.
      home: const AuthWrapper(),

      // Define all named routes for GetX navigation
      getPages: [
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegisterScreen()),
        GetPage(name: '/home', page: () => HomeScreen()),
        // Add other main routes here
        // e.g., GetPage(name: '/chat/:chatId', page: () => ChatScreen()),
      ],
    );
  }
}

/// A wrapper widget that listens to the authentication state.
///
/// Uses [Provider] to watch [AuthService] and shows either the
/// [HomeScreen] or [LoginScreen] based on whether the user is authenticated.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the AuthService from Provider to get auth state changes
    final authService = context.watch<AuthService>();

    // The isAuthenticated getter in AuthService handles all the logic.
    if (authService.isAuthenticated) {
      // User is logged in
      return HomeScreen();
    } else {
      // User is logged out
      return LoginScreen();
    }
  }
}

