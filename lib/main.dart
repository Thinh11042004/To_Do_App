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
    const seed = Color(0xFF5260FF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo Demo',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF8F7FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(.96),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: seed.withOpacity(.14),
          selectedColor: seed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: StadiumBorder(),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white.withOpacity(.95),
          indicatorColor: seed.withOpacity(.16),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF282347),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: seed,
          foregroundColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF322D57),
          indicatorColor: seed.withOpacity(.24),
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
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
