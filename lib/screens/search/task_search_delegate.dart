import 'package:flutter/material.dart';
import '../../models/task.dart';

class TaskSearchDelegate extends SearchDelegate {
  final List<Task> tasks;
  final void Function(Task) onTapTask;
  TaskSearchDelegate(this.tasks, {required this.onTapTask});

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.toLowerCase().trim();
    final list = tasks.where((t) => t.title.toLowerCase().contains(q)).toList();
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final t = list[i];
        return ListTile(
          leading: const Icon(Icons.task_alt_outlined),
          title: Text(t.title),
          onTap: () => onTapTask(t),
        );
      },
    );
  }
}
