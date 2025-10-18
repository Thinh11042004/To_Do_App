import 'package:flutter/material.dart';
import '../../models/task.dart';

class TaskTemplatesScreen extends StatelessWidget {
  const TaskTemplatesScreen({super.key});

  Task _build(String title, {TimeOfDay? time}) => Task(
    id: 'tpl-$title',
    title: title,
    category: TaskCategory.work,
    repeat: RepeatRule.daily,
    timeOfDay: time ?? const TimeOfDay(hour: 7, minute: 0),
  );

  @override
  Widget build(BuildContext context) {
    final health = [
      _build('Uống nước, giữ gìn sức khoẻ', time: const TimeOfDay(hour: 9, minute: 0)),
      _build('Đi ngủ sớm', time: const TimeOfDay(hour: 22, minute: 30)),
      _build('Dậy sớm', time: const TimeOfDay(hour: 6, minute: 0)),
      _build('Nhắc nhở về thuốc', time: const TimeOfDay(hour: 14, minute: 0)),
      _build('Nghỉ ngơi một lát', time: const TimeOfDay(hour: 15, minute: 0)),
      _build('Ăn trái cây', time: const TimeOfDay(hour: 14, minute: 30)),
    ];
    final life = [
      _build('Dọn dẹp nhà cửa'),
      _build('Chăm sóc da', time: const TimeOfDay(hour: 21, minute: 0)),
      _build('Đi mua sắm'),
    ];

    List<Widget> buildSection(String title, List<Task> items) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ...items.map((t) => Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(t.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pop(context, t),
              ),
            )),
      ];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mẫu nhiệm vụ')),
      body: ListView(
        children: [
          ...buildSection('Sức khoẻ', health),
          ...buildSection('Cuộc sống', life),
        ],
      ),
    );
  }
}
