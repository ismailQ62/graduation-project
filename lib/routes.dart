import 'package:flutter/material.dart';
import 'package:lorescue/views/splash_screen.dart';
import 'package:lorescue/views/login_screen.dart';
import 'package:lorescue/views/register_screen.dart';
import 'package:lorescue/views/map_screen.dart';
import 'package:lorescue/views/home_screen.dart';
import 'package:lorescue/views/chat_screen.dart';
import 'package:lorescue/views/profile_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String register = '/register';
  static const String map = '/map';
  static const String chat = "/chat";
  static const String profile = "/profile";

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case map:
        return MaterialPageRoute(builder: (_) => const MapScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }
}
