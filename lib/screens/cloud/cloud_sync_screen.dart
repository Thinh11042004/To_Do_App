import 'package:flutter/material.dart';

class CloudSyncScreen extends StatelessWidget {
  const CloudSyncScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đồng bộ đám mây Firebase')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // TODO: Implement actual sync logic
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đồng bộ với Firebase thành công!')),
            );
          },
          child: const Text('Đồng bộ ngay'),
        ),
      ),
    );
  }
}
