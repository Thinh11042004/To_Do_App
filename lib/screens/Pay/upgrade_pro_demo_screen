import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pro_manager.dart';

class UpgradeProDemoScreen extends StatefulWidget {
  const UpgradeProDemoScreen({super.key});

  @override
  State<UpgradeProDemoScreen> createState() => _UpgradeProDemoScreenState();
}

class _UpgradeProDemoScreenState extends State<UpgradeProDemoScreen> {
  bool _processing = false;
  final _codeCtl = TextEditingController();

  @override
  void dispose() {
    _codeCtl.dispose();
    super.dispose();
  }

  Future<void> _simulatePaid() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 1)); // giả lập chờ xác nhận
    await ProManager.instance.upgrade();
    if (!mounted) return;
    setState(() => _processing = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nâng cấp thành công'),
        content: const Text('Demo: tài khoản đã được kích hoạt Pro.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    ).then((_) => Navigator.pop(context, true));
  }

  Future<void> _activateByCode() async {
    final code = _codeCtl.text.trim().toUpperCase();
    if (code == 'PROFREE' || code == 'PRODEMO') {
      await ProManager.instance.upgrade();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kích hoạt Pro thành công')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã không hợp lệ (PROFREE / PRODEMO)')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nâng cấp Pro (Demo)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // QR minh hoạ thôi (không dùng để kiểm tra thanh toán)
                  Image.network(
                    'https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=DEMO-TODO-PRO',
                    width: 240, height: 240, fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text('Quét QR (minh hoạ) hoặc dùng mã kích hoạt để trải nghiệm Pro.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Gói dùng thử (Demo)'),
            subtitle: const Text('294.000 đ / năm — Chỉ là ví dụ hiển thị'),
            trailing: const Icon(Icons.workspace_premium, color: Colors.amber),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _processing ? null : _simulatePaid,
            icon: _processing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.verified),
            label: Text(_processing ? 'Đang xử lý...' : 'Giả lập: Tôi đã thanh toán'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text('Hoặc kích hoạt bằng mã: PROFREE / PRODEMO',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtl,
                  decoration: const InputDecoration(
                    hintText: 'Nhập mã demo (ví dụ PROFREE)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _activateByCode,
                child: const Text('Kích hoạt'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: ProManager.instance.downgrade,
            icon: const Icon(Icons.restore),
            label: const Text('Gỡ Pro (chỉ để test)'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: s.primaryContainer.withOpacity(.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Đây là DEMO offline: không thực hiện thanh toán thật. '
              'Nút “Giả lập: Tôi đã thanh toán” chỉ đổi cờ Pro ở máy bạn.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
