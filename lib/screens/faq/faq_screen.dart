import 'package:flutter/material.dart';

import '../../services/chat_gpt_service.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = <_ChatMessage>[
    _ChatMessage(
      text: 'Xin chào! Tôi là trợ lý TodoApp. Bạn muốn tìm hiểu điều gì?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];
  bool _isSending = false;

  final List<String> _suggestions = const <String>[
    'Làm thế nào để tạo nhiệm vụ mới?',
    'Tôi có thể đặt nhắc nhở ra sao?',
    'Ứng dụng có đồng bộ lên đám mây không?',
    'Gợi ý cách lập kế hoạch cho tuần này',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hỏi Đáp')), 
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.info_outline),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Trợ lý ChatGPT đã được kích hoạt sẵn để hỗ trợ bạn giải đáp thắc mắc.',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),
          if (_suggestions.isNotEmpty) _SuggestionStrip(onSelect: _handleSuggestion, suggestions: _suggestions),
          const Divider(height: 1),
          _buildComposer(context),
        ],
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !_isSending,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Đặt câu hỏi cho trợ lý TodoApp...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                minLines: 1,
                maxLines: 4,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isSending ? null : _sendMessage,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(14),
              ),
              child: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                      ),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSuggestion(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final reply = await ChatGptService.instance.ask(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
      });
    } on ChatGptException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: e.message, isUser: false, timestamp: DateTime.now(), isError: true));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: 'Không thể kết nối đến ChatGPT: $e', isUser: false, timestamp: DateTime.now(), isError: true));
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = message.isUser
        ? colorScheme.primary
        : (message.isError ? colorScheme.errorContainer : colorScheme.surfaceVariant);
    final textColor = message.isUser
        ? colorScheme.onPrimary
        : (message.isError ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant);

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 6),
            bottomRight: Radius.circular(message.isUser ? 6 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textColor),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(message.timestamp, context),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: textColor.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime time, BuildContext context) {
    final format = MaterialLocalizations.of(context);
    return format.formatTimeOfDay(TimeOfDay.fromDateTime(time));
  }
}

class _SuggestionStrip extends StatelessWidget {
  final void Function(String) onSelect;
  final List<String> suggestions;

  const _SuggestionStrip({required this.onSelect, required this.suggestions});

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final suggestion in suggestions)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(suggestion),
                  onPressed: () => onSelect(suggestion),
                ),
              ),
          ],
        ),
      ),
    );
  }
}