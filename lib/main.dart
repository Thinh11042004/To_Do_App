import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/task.dart';
import 'screens/task_list_screen.dart';
import 'screens/task_templates_screen.dart';
import 'services/pro_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ProManager.instance.init();
  //  await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  runApp(const ToDoApp());
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = Colors.deepPurple;
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
