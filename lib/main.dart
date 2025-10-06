import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'models/task.dart';
import 'screens/task_list_screen.dart';
import 'screens/task_templates_screen.dart';
import 'screens/splash/app_splash.dart';
import 'services/pro_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, 
  );
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
      title: 'To-Do Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seed,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F3FF),
      ),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: seed, brightness: Brightness.dark),
      routes: {
        '/': (_) => const AppSplash(),            // ✅ vào Splash trước
        '/home': (_) => const _HomeHost(),        // ✅ màn chính
        '/templates': (_) => const TaskTemplatesScreen(),
      },
    );
  }
}

/// Host giữ state danh sách task để TaskListScreen hoạt động đúng
class _HomeHost extends StatefulWidget {
  const _HomeHost();

  @override
  State<_HomeHost> createState() => _HomeHostState();
}

class _HomeHostState extends State<_HomeHost> {
  final List<Task> _tasks = [];

  void _add(Task t) => setState(() => _tasks.add(t));
  void _update(Task t) => setState(() { /* stateful list đã tham chiếu */ });

  @override
  Widget build(BuildContext context) {
    return TaskListScreen(tasks: _tasks, onAdd: _add, onUpdate: _update);
  }
}
