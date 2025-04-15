import 'package:flutter/material.dart';
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

/* import 'package:flutter/material.dart';
import 'package:lorescue/services/json/message_json.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: JsonTestScreen());
  }
}

class JsonTestScreen extends StatefulWidget {
  const JsonTestScreen({super.key});

  @override
  State<JsonTestScreen> createState() => _JsonTestScreenState();
}

class _JsonTestScreenState extends State<JsonTestScreen> {
  @override
  void initState() {
    super.initState();

    final jsonMessage = MessageJsonBuilder.build(
      senderId: "user-157489",
      receiverId: "user-152880",
      username: "Ismail Qwasmi",
      role: "Individual",
      channelId: "channel-01",
      channelName: "Zone 1 - Main",
      messageText: "Hello from Flutter console test!",
      timestamp: DateTime.now(),
      latitude: 32.3936,
      longitude: 35.9865,
    );

    print("✅ Raw JSON:\n$jsonMessage");

    final pretty = const JsonEncoder.withIndent(
      '  ',
    ).convert(jsonDecode(jsonMessage));
    print("📦 Pretty JSON:\n$pretty");
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("Check your console for JSON output 👍")),
    );
  }
} */
