import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatGptException implements Exception {
  final String message;
  ChatGptException(this.message);

  @override
  String toString() => message;
}

class ChatGptService {
  ChatGptService._();

  static final ChatGptService instance = ChatGptService._();
  final http.Client _client = http.Client();

  Future<String> ask(String prompt) async {
    final apiKey = _resolveApiKey();
    if (apiKey.isEmpty) {
      throw ChatGptException('ChatGPT chưa được cấu hình.');
    }

    final response = await _client.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an assistant that helps Vietnamese to-do app users with productivity tips and feature guidance.'
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 600,
      }),
    );

    if (response.statusCode >= 400) {
      String description = 'Không thể kết nối đến ChatGPT (mã lỗi ${response.statusCode}).';
      try {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final error = data['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.isNotEmpty) {
            description = message;
          }
        }
      } catch (_) {}
      throw ChatGptException(description);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final message = choices.first['message'];
      if (message is Map && message['content'] is String) {
        return (message['content'] as String).trim();
      }
    }

    throw ChatGptException('ChatGPT không trả về kết quả phù hợp.');
  }
}

String _resolveApiKey() {
  final envKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  if (envKey.trim().isNotEmpty) {
    return envKey.trim();
  }

  const buildTimeKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

  return buildTimeKey.trim();
}