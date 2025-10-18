import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: Center(
        child: Text('Cài đặt ứng dụng sẽ hiển thị ở đây.'),
      ),
    );
  }
}
