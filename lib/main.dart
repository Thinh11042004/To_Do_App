import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/pro_manager.dart';
import 'screens/task_list_screen.dart';
import 'screens/task_templates_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform-aware init + guard to avoid duplicate-app
  if (Firebase.apps.isEmpty) {
    if (kIsWeb || Platform.isIOS || Platform.isMacOS) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      // Android: use default resources (google-services.json) – no options
      await Firebase.initializeApp();
    }
  } else {
    Firebase.app();
  }

  await ProManager.instance.init();
  runApp(const ToDoApp());
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});
  @override
  Widget build(BuildContext context) {
    const seed = Colors.deepPurple;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seed,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F3FF),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
      ),
      routes: {
        '/': (_) =>
            TaskListScreen(tasks: const [], onAdd: (_) {}, onUpdate: (_) {}),
        '/templates': (_) => const TaskTemplatesScreen(),
      },
    );
  }
}
