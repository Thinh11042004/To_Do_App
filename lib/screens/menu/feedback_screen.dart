import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phản hồi')),
      body: Center(
        child: Text('Gửi phản hồi tới support@todoapp.vn.'),
      ),
    );
  }
}
