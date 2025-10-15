import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/pro_manager.dart';
import 'screens/task_list_screen.dart';
import 'screens/task_templates_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init (đơn giản và an toàn cho mọi nền tảng)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app(); // lấy instance hiện có
    }
  } catch (e) {
    // Nếu rơi vào case app đã khởi tạo ở hot-reload/hot-restart
    // vẫn đảm bảo có thể tiếp tục chạy
    debugPrint('Firebase init warning: $e');
    try {
      Firebase.app();
    } catch (_) {}
  }

  // App services
  await ProManager.instance.init();
  await NotificationService.instance.init();

  runApp(const ToDoApp());
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6750A4);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF4F0FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(.92),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: seed.withOpacity(.12),
          selectedColor: seed,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      routes: {
        '/': (_) => TaskListScreen(
              tasks: const [],
              onAdd: (_) {},
              onUpdate: (_) {},
            ),
        '/templates': (_) => const TaskTemplatesScreen(),
      },
    );
  }
}
