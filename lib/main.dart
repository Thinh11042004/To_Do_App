import 'dart:convert';                     
import 'package:http/http.dart' as http;   
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/pro_manager.dart';
import 'services/settings_service.dart';
import 'services/theme_manager.dart';
import 'screens/task/task_list_screen.dart';
import 'screens/task/task_templates_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initEnv();

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
    debugPrint('Firebase init warning: $e');
    try { Firebase.app(); } catch (_) {}
  }

  // App services
  await ProManager.instance.init();
  await NotificationService.instance.init();
  await SettingsService.instance.init();
  await ThemeManager.instance.init();

_askOpenRouter('Xin chào trợ lý! Hãy trả lời một câu ngắn.');


  runApp(const ToDoApp());
}

Future<void> _initEnv() async {
  if (dotenv.isInitialized) return;
  try {
    await dotenv.load(fileName: '.env');
  } catch (err) {
    debugPrint('dotenv load warning: $err');
  }
}

/// —— GỌI OPENROUTER CHAT COMPLETIONS ——
/// Trả về nội dung message đầu tiên; log lỗi rõ ràng nếu có.
Future<void> _askOpenRouter(String userMessage) async {
  try {
    final apiUrl  = dotenv.env['OPENROUTER_API_URL']!;
    final model   = dotenv.env['OPENROUTER_MODEL']!;
    final uri = Uri.parse(apiUrl);

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': 'You are a helpful assistant for a ToDo app.'},
        {'role': 'user', 'content': userMessage},
      ],
    });

    final res = await http.post(uri, headers: _headers(), body: body);

    if (res.statusCode != 200) {
      debugPrint('OpenRouter error ${res.statusCode}: ${res.body}');
      return;
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final content = (data['choices'] as List).first['message']['content'];
    debugPrint('GPT reply: $content');
  } catch (e, st) {
    debugPrint('OpenRouter call failed: $e\n$st');
  }
}

Map<String, String> _headers() {
  final apiKey  = dotenv.env['OPENROUTER_API_KEY']!;
  final referer = dotenv.env['OPENROUTER_REFERER']!;
  final title   = dotenv.env['OPENROUTER_TITLE'] ?? 'FlutterApp';
  return {
    'Authorization': 'Bearer $apiKey',
    'HTTP-Referer' : referer,    // BẮT BUỘC theo yêu cầu OpenRouter
    'X-Title'      : title,      // Khuyến nghị
    'Content-Type' : 'application/json',
  };
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeManager.instance,
      builder: (_, __) {
        final settings = ThemeManager.instance.settings;
        final seed = settings.seedColor;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ToDo Demo',
          themeMode: settings.mode,
          theme: _buildTheme(seed, Brightness.light),
          darkTheme: _buildTheme(seed, Brightness.dark),
          routes: {
            '/': (_) => TaskListScreen(
                  tasks: const [],
                  onAdd: (_) {},
                  onUpdate: (_) {},
                ),
            '/templates': (_) => const TaskTemplatesScreen(),
          },
        );
      },
    );
  }
}

ThemeData _buildTheme(Color seed, Brightness brightness) {
  final isLight = brightness == Brightness.light;
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        isLight ? const Color(0xFFF8F7FF) : const Color(0xFF282347),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: isLight ? Colors.black87 : Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: isLight ? Colors.white.withOpacity(.96) : const Color(0xFF322D57),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: scheme.primary.withOpacity(isLight ? .14 : .26),
      selectedColor: scheme.primary,
      labelStyle: TextStyle(color: isLight ? scheme.primary : scheme.onPrimary),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: isLight ? 6 : 0,
      shape: const StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isLight ? Colors.white.withOpacity(.95) : const Color(0xFF322D57),
      indicatorColor: scheme.primary.withOpacity(isLight ? .16 : .24),
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
  );
}
