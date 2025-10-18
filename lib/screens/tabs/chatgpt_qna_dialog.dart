import 'package:flutter/material.dart';

class ChatGptQnADialog extends StatefulWidget {
  const ChatGptQnADialog({super.key});
  @override
  State<ChatGptQnADialog> createState() => _ChatGptQnADialogState();
}

class _ChatGptQnADialogState extends State<ChatGptQnADialog> {
  final TextEditingController _ctl = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final q = _ctl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': q});
      _ctl.clear();
      _loading = true;
    });
    // Simulate ChatGPT answer
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _messages.add({'role': 'assistant', 'content': 'Đây là câu trả lời mẫu cho: "$q" (demo)'});
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hỏi Đáp'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: _messages
                    .map((m) => Align(
                          alignment: m['role'] == 'user'
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: m['role'] == 'user'
                                  ? Colors.blue[100]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(m['content'] ?? ''),
                          ),
                        ))
                    .toList(),
              ),
            ),
            if (_loading) const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctl,
                    decoration: const InputDecoration(hintText: 'Nhập câu hỏi...'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _loading ? null : _send,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ĐÓNG'))],
    );
  }
}
