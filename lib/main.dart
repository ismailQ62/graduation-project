import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:lorescue/services/WebSocketService.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationController.initialize();

  // Connect globally once app starts
  WebSocketService().connect('ws://192.168.4.1:81');

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

// ✅ Function to delete the old database (run once)
/* import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lorescue/routes.dart';
import 'package:lorescue/controllers/notification_controller.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ TEMP: Delete existing database ONCE to reset schema
  await _deleteOldDatabase();

  // ✅ Initialize local notifications
  await NotificationController.initialize();

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


Future<void> _deleteOldDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'lorescue.db');
  await deleteDatabase(path);
  print('✅ Database deleted: $path');
} */
