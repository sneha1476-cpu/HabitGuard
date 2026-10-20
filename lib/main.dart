
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final NotificationService notificationService =
      NotificationService();

  await notificationService.initialize();

  runApp(const HabitGuardApp());
}

class HabitGuardApp extends StatelessWidget {
  const HabitGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HabitGuard',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const LoginScreen(),
    );
  }
}