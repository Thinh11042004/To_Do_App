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
  String _selectedMethod = 'card';
  String _selectedPlan = 'yearly';

  static const _validCodes = {'PROFREE', 'PRODEMO'};

  @override
  void dispose() {
    _codeCtl.dispose();
    super.dispose();
  }

  Future<void> _simulatePaid() async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      // giả lập chờ xác nhận thanh toán
      await Future.delayed(const Duration(seconds: 1));
      await ProManager.instance.upgrade();

      if (!mounted) return;
      setState(() => _processing = false);

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Nâng cấp thành công'),
          content: const Text('Demo: tài khoản đã được kích hoạt Pro.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context, true); // trả về true cho màn trước biết đã nâng cấp
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi khi nâng cấp (demo): $e')),
      );
    }
  }

  Future<void> _activateByCode() async {
    if (_processing) return;
    final raw = _codeCtl.text.trim().toUpperCase();

    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã kích hoạt.')),
      );
      return;
    }
    if (!_validCodes.contains(raw)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã không hợp lệ. Hãy dùng PROFREE hoặc PRODEMO.')),
      );
      return;
    }

    setState(() => _processing = true);
    try {
      await Future.delayed(const Duration(milliseconds: 400)); // mô phỏng
      await ProManager.instance.upgrade();

      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã kích hoạt Pro bằng mã: $raw')),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kích hoạt mã thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nâng cấp Pro (Demo)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // QR minh hoạ (không dùng để kiểm tra thanh toán)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=DEMO-TODO-PRO',
                      width: 240, height: 240, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2, size: 120),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Quét QR (minh hoạ) hoặc dùng mã kích hoạt để trải nghiệm Pro.',
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text('Chọn gói dịch vụ', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ToggleButtons(
            borderRadius: BorderRadius.circular(16),
            isSelected: ['monthly', 'yearly'].map((plan) => plan == _selectedPlan).toList(),
            onPressed: (index) => setState(() => _selectedPlan = index == 0 ? 'monthly' : 'yearly'),
            selectedColor: s.onPrimary,
            fillColor: s.primary,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Text('Theo tháng'),
                    SizedBox(height: 4),
                    Text('39.000 đ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Text('Theo năm'),
                    SizedBox(height: 4),
                    Text('294.000 đ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text('Phương thức thanh toán', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          _methodTile(
            context,
            id: 'card',
            icon: Icons.credit_card,
            title: 'Thẻ tín dụng/ghi nợ',
            subtitle: 'Visa, MasterCard, JCB',
          ),
          _methodTile(
            context,
            id: 'momo',
            icon: Icons.mobile_friendly,
            title: 'Ví MoMo',
            subtitle: 'Thanh toán nhanh qua ứng dụng MoMo',
          ),
          _methodTile(
            context,
            id: 'bank',
            icon: Icons.account_balance,
            title: 'Chuyển khoản ngân hàng',
            subtitle: 'Vietcombank, Techcombank, BIDV...',
          ),
          _methodTile(
            context,
            id: 'apple',
            icon: Icons.phone_iphone,
            title: 'Apple Pay / Google Pay',
            subtitle: 'Sử dụng ví đã liên kết trên thiết bị',
          ),
          const SizedBox(height: 8),

          FilledButton.icon(
            onPressed: _processing ? null : _simulatePaid,
            icon: _processing
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified),
            label: Text(
              _processing
                  ? 'Đang xử lý...'
                  : 'Xác nhận ${_planLabel()} bằng ${_methodLabel()}',
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          Text('Hoặc kích hoạt bằng mã: PROFREE / PRODEMO', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtl,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _activateByCode(),
                  decoration: const InputDecoration(
                    hintText: 'Nhập mã demo (ví dụ PROFREE)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _processing ? null : _activateByCode,
                child: const Text('Kích hoạt'),
              ),
            ],
          ),

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _processing
                ? null
                : () async {
                    try {
                      await ProManager.instance.downgrade();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã gỡ Pro (chỉ test)')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Không thể gỡ Pro: $e')),
                      );
                    }
                  },
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
              'Nút “Xác nhận …” chỉ đổi cờ Pro ở máy bạn.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTile(
    BuildContext context, {
    required String id,
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    final selected = _selectedMethod == id;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: selected ? scheme.primary : scheme.secondaryContainer,
          child: Icon(
            icon,
            color: selected ? scheme.onPrimary : scheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? scheme.primary : null,
          ),
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: selected
            ? Icon(Icons.check_circle, color: scheme.primary)
            : Icon(Icons.circle_outlined, color: scheme.outline),
        onTap: () => setState(() => _selectedMethod = id),
      ),
    );
  }

  String _planLabel() => _selectedPlan == 'monthly' ? 'gói tháng' : 'gói năm';

  String _methodLabel() {
    switch (_selectedMethod) {
      case 'card':
        return 'thẻ';
      case 'momo':
        return 'MoMo';
      case 'bank':
        return 'chuyển khoản';
      case 'apple':
        return 'ví di động';
      default:
        return 'phương thức đã chọn';
    }
  }
}
