/* import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/routes.dart';

void main() {
  const String route = String.fromEnvironment(
    'ROUTE',
    defaultValue: AppRoutes.splash,
  );
  runApp(MainApp(initialRoute: route));
}

class MainApp extends StatelessWidget {
  final String initialRoute;

  const MainApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
 */

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/controllers/notification_controller.dart'; // ✅ Notification controller

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize local notifications
  await NotificationController.initialize();

  const String route = String.fromEnvironment(
    'ROUTE',
    defaultValue:
        AppRoutes
            .splash, // ✅ Set this back to splash or your desired default route
  );

  runApp(MainApp(initialRoute: route));
}

class MainApp extends StatelessWidget {
  final String initialRoute;

  const MainApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: initialRoute,
          onGenerateRoute:
              AppRoutes.generateRoute, // ✅ Route to your existing app structure
        );
      },
    );
  }
}
