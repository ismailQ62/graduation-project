import 'package:flutter/material.dart';
import 'package:lorescue/views/admin/mange_channel_screen.dart';
import 'package:lorescue/views/admin/verification_screen.dart';
import 'package:lorescue/views/splash_screen.dart';
import 'package:lorescue/views/login_screen.dart';
import 'package:lorescue/views/register_screen.dart';
import 'package:lorescue/views/map_screen.dart';
import 'package:lorescue/views/home_screen.dart';
import 'package:lorescue/views/chat_screen.dart';
import 'package:lorescue/views/profile_screen.dart';

import 'package:lorescue/views/channels_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String register = '/register';
  static const String map = '/map';
  static const String chat = "/chat";
  static const String profile = "/profile";
  static const String verification = "/verification";
  static const String manageChannel = "/manageChannel";
  static const String channels = "/channels";

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
      /*   case manageChannel:
        return MaterialPageRoute(builder: (_) => const ManageChannelsScreen()); */
      case channels:
        return MaterialPageRoute(builder: (_) => const ChannelsScreen());
      case verification:
        return MaterialPageRoute(builder: (_) => const VerificationScreen());
      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text("Page Not Found"))),
        );
    }
  }
}
