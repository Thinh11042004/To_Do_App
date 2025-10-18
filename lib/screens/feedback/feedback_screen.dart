import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Phản hồi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chúng tôi luôn lắng nghe bạn',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                'Chia sẻ góp ý hoặc báo lỗi để TodoApp cải thiện trải nghiệm của bạn.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tên của bạn',
                  hintText: 'Ví dụ: Nguyễn Văn A',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email liên hệ',
                  hintText: 'ban@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Vui lòng nhập email của bạn';
                  }
                  if (!text.contains('@') || !text.contains('.')) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                textInputAction: TextInputAction.newline,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Nội dung phản hồi',
                  alignLabelWithHint: true,
                  hintText: 'Mô tả chi tiết vấn đề hoặc góp ý của bạn...',
                  prefixIcon: Icon(Icons.feedback_outlined),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Vui lòng nhập nội dung phản hồi';
                  }
                  if (text.length < 10) {
                    return 'Hãy mô tả chi tiết hơn (tối thiểu 10 ký tự).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendFeedback,
                      icon: _isSending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(_isSending ? 'Đang gửi...' : 'Gửi phản hồi'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Hoặc liên hệ trực tiếp: support@todoapp.vn',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    final uri = Uri(
      scheme: 'mailto',
      path: 'support@todoapp.vn',
      queryParameters: {
        'subject': 'Phản hồi ứng dụng TodoApp',
        'body': _buildMailBody(),
      },
    );

    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng email.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã mở ứng dụng email để bạn hoàn tất gửi phản hồi.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi phản hồi thất bại: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _buildMailBody() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final content = _contentController.text.trim();

    final buffer = StringBuffer()
      ..writeln('Tên: ${name.isEmpty ? '(ẩn danh)' : name}')
      ..writeln('Email: $email')
      ..writeln('---')
      ..writeln(content);

    return buffer.toString();
  }
}