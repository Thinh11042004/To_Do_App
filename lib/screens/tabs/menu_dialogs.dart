import 'package:flutter/material.dart';

// Firebase Sync Dialog
dialogFirebaseSync(BuildContext context) => showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Đồng bộ đám mây'),
    content: const Text('Đồng bộ với Firebase (demo).'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ĐÓNG'))],
  ),
);

// Theme Picker Dialog
dialogThemePicker(BuildContext context) => showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Chủ đề'),
    content: const Text('Chọn chủ đề (demo).'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ĐÓNG'))],
  ),
);

// Utilities Dialog
dialogUtilities(BuildContext context) => showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Tiện ích'),
    content: const Text('Danh sách tiện ích (demo).'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ĐÓNG'))],
  ),
);

// Feedback Dialog
dialogFeedback(BuildContext context) => showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Phản hồi'),
    content: const Text('Gửi phản hồi tới support@todoapp.vn (demo).'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ĐÓNG'))],
  ),
);

// Settings Dialog
dialogSettings(BuildContext context) => showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('Cài đặt'),
    content: const Text('Cài đặt ứng dụng (demo).'),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ĐÓNG'))],
  ),
);
