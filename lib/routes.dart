import 'package:flutter/material.dart';
import 'package:lorescue/views/Responder/upload_verification_screen.dart';
import 'package:lorescue/views/admin/home_admin_screen.dart';
import 'package:lorescue/views/admin/manage_users_screen.dart';
import 'package:lorescue/views/admin/mange_channel_screen.dart';
import 'package:lorescue/views/admin/verification_screen.dart';
import 'package:lorescue/views/splash_screen.dart';
import 'package:lorescue/views/login_screen.dart';
import 'package:lorescue/views/register_screen.dart';
import 'package:lorescue/views/map_screen.dart';
import 'package:lorescue/views/home_screen.dart';
import 'package:lorescue/views/chat_screen.dart';
import 'package:lorescue/views/profile_screen.dart';
import 'package:lorescue/views/Responder/home_Responder_screen.dart';
import 'package:lorescue/views/sos_chat_screen.dart';
import 'package:lorescue/models/channel_model.dart';
import 'package:lorescue/views/channels_screen.dart';
import 'package:lorescue/models/zone_model.dart';

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
  static const String homeAdmin = "/homeAdmin";
  static const String homeResponder = "/homeResponder";
  static const String sosChat = "/sosChat";
  static const String manageUsers = '/manageUsers';
  static const String uploadVerification = '/uploadVerification';
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
        final args = settings.arguments as Map<String, dynamic>;
        final channel = args['channel'] as Channel;
        final zone = args['zone'] as Zone;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(channel: channel, zone: zone),
        );

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case manageChannel:
        return MaterialPageRoute(builder: (_) => const ManageChannelsScreen());
      case channels:
        final zone = settings.arguments as Zone;
        return MaterialPageRoute(
          builder: (context) => ChannelsScreen(zone: zone),
        );
      case verification:
        return MaterialPageRoute(builder: (_) => const VerificationScreen());
      case homeResponder:
        return MaterialPageRoute(builder: (_) => const HomeResponderScreen());
      case sosChat:
        return MaterialPageRoute(builder: (_) => const SosChatScreen());
      case homeAdmin:
        return MaterialPageRoute(builder: (_) => const HomeAdminScreen());
      case manageUsers:
        return MaterialPageRoute(builder: (_) => const ManageUsersScreen());
      case uploadVerification:
        return MaterialPageRoute(
          builder: (_) => const UploadVerificationScreen(),
        );

      default:
        return MaterialPageRoute(
          builder:
              (_) =>
                  const Scaffold(body: Center(child: Text("Page Not Found"))),
        );
    }
  }
}
