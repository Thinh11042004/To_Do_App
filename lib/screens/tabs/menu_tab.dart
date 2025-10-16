import 'package:flutter/material.dart';

import '../../services/pro_manager.dart';


class MenuTab extends StatelessWidget {
  final VoidCallback onOpenCategories;
  final VoidCallback onUpgradePro; // vẫn giữ, nhưng sẽ không dùng khi đã Pro
  const MenuTab({super.key, required this.onOpenCategories, required this.onUpgradePro});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final header = Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      alignment: Alignment.bottomLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'To-Do List',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lên kế hoạch mỗi ngày của bạn',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: scheme.onPrimary.withOpacity(.85)),
          ),
        ],
      ),
    );

    ListTile item(IconData icon, String title, {VoidCallback? onTap, Widget? trailing}) {
      return ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(title),
        trailing: trailing,
        onTap: onTap ?? () => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Demo: $title'))),
      );
    }

    return Container(
      color: scheme.surface,
      child: ListView(
        children: [
          header,

          //  Ẩn nếu đã Pro
          ValueListenableBuilder<bool>(
            valueListenable: ProManager.instance.isPro,
            builder: (_, isPro, __) {
              if (isPro) return const SizedBox.shrink();
              return item(
                Icons.workspace_premium,
                'Nâng cấp lên Pro',
                onTap: onUpgradePro,
              );
            },
          ),

          item(Icons.star, 'Star Task'),
          item(Icons.cloud_sync, 'Đồng bộ đám mây Firebase',
              trailing: const Icon(Icons.verified, color: Colors.green)),
          item(Icons.widgets, 'Thể loại',
              trailing: const Icon(Icons.keyboard_arrow_down), onTap: onOpenCategories),
          const Divider(height: 24),
          item(Icons.brush, 'Chủ đề'),
          item(Icons.extension, 'Tiện ích'),
          item(Icons.favorite, 'Quyên góp'),
          item(Icons.apps, 'Ứng dụng Gia đình (AD)'),
          item(Icons.feedback_outlined, 'Phản hồi'),
          item(Icons.help_outline, 'Hỏi Đáp'),
          item(Icons.settings, 'Setting'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
