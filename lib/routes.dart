import 'package:flutter/material.dart';
import 'package:lorescue/views/Responder/upload_verification_screen.dart';
import 'package:lorescue/views/admin/blocked_users_screen';
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
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String verification = '/verification';
  static const String manageChannel = '/manageChannel';
  static const String channels = '/channels';
  static const String homeAdmin = '/homeAdmin';
  static const String homeResponder = '/homeResponder';
  static const String sosChat = '/sosChat';
  static const String manageUsers = '/manageUsers';
  static const String uploadVerification = '/uploadVerification';
  static const blockedUsers = '/blockedUsers';

  /// Slide transition builder
  static PageRouteBuilder _customPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _customPageRoute(const SplashScreen());
      case login:
        return _customPageRoute(const LoginScreen());
      case register:
        return _customPageRoute(const RegisterScreen());
      case map:
        return _customPageRoute(const MapScreen());
      case home:
        return _customPageRoute(const HomeScreen());
      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null ||
            !args.containsKey('channel') ||
            !args.containsKey('zone')) {
          return _customPageRoute(
            const Scaffold(body: Center(child: Text("Missing chat arguments"))),
          );
        }
        final channel = args['channel'] as Channel;
        final zone = args['zone'] as Zone;
        return _customPageRoute(ChatScreen(channel: channel, zone: zone));
      case profile:
        return _customPageRoute(const ProfileScreen());
      case manageChannel:
        return _customPageRoute(const ManageChannelsScreen());
      case channels:
        final zone = settings.arguments as Zone?;
        if (zone == null) {
          return _customPageRoute(
            const Scaffold(
              body: Center(child: Text("Missing zone for channel screen")),
            ),
          );
        }
        return _customPageRoute(ChannelsScreen(zone: zone));
      case verification:
        return _customPageRoute(const VerificationScreen());
      case homeResponder:
        return _customPageRoute(const HomeResponderScreen());
      case sosChat:
        return _customPageRoute(const SosChatScreen());
      case homeAdmin:
        return _customPageRoute(const HomeAdminScreen());
      case manageUsers:
        return _customPageRoute(const ManageUsersScreen());
      case uploadVerification:
        return _customPageRoute(const UploadVerificationScreen());
      case blockedUsers:
        return _customPageRoute(const BlockedUsersScreen());
      default:
        return _customPageRoute(
          const Scaffold(body: Center(child: Text("🚫 Page Not Found"))),
        );
    }
  }
}
