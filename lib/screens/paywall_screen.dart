import 'package:flutter/material.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF2E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SizedBox(height: 8),
          Text('Giảm giá mùa tựu trường', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('40% OFF',
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.w900, color: Colors.orange)),
          const SizedBox(height: 12),
          _priceCard(context, '1 tháng', '46.000 đ'),
          _bestPriceCard(context, 'Dài hạn', 'TIẾT KIỆM 40%', '294.000 đ', '552.000 đ'),
          _priceCard(context, '12 Tháng', '158.000 đ', old: '273.000 đ'),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('TIẾP TỤC'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ĐIỀU KIỆN | CHÍNH SÁCH BẢO MẬT | KHÔI PHỤC',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _priceCard(BuildContext context, String title, String price, {String? old}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (old != null)
                  Text(old, style: const TextStyle(decoration: TextDecoration.lineThrough)),
                Text(price, style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bestPriceCard(
      BuildContext context, String title, String badge, String price, String old) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.orange),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
              child: Text(badge,
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(old, style: const TextStyle(decoration: TextDecoration.lineThrough)),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
