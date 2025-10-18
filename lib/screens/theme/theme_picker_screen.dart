import 'package:flutter/material.dart';

import '../../services/theme_manager.dart';

class ThemePickerScreen extends StatelessWidget {
  const ThemePickerScreen({Key? key}) : super(key: key);

  static const _seedOptions = <Color>[
    Color(0xFF5260FF),
    Color(0xFF6750A4),
    Color(0xFF006874),
    Color(0xFF386A20),
    Color(0xFF0061A4),
    Color(0xFF8E24AA),
    Color(0xFFB3261E),
    Color(0xFF795548),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chủ đề')),
      body: AnimatedBuilder(
        animation: ThemeManager.instance,
        builder: (context, _) {
          final themeSettings = ThemeManager.instance.settings;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            children: [
              Text(
                'Chế độ giao diện',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...ThemeMode.values.map(
                (mode) => RadioListTile<ThemeMode>(
                  value: mode,
                  groupValue: themeSettings.mode,
                  title: Text(_modeLabel(mode)),
                  subtitle: Text(_modeDescription(mode)),
                  onChanged: (value) {
                    if (value != null) {
                      ThemeManager.instance.setThemeMode(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Màu nhấn',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final color in _seedOptions)
                    _ThemeColorOption(
                      color: color,
                      selected: color.value == themeSettings.seedColor.value,
                      onTap: () => ThemeManager.instance.setSeedColor(color),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Xem trước',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tối ưu trải nghiệm',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Màu nhấn sẽ áp dụng cho các nút chính, chip và thanh điều hướng của bạn.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: const [
                          Chip(label: Text('Tác vụ hôm nay')),
                          Chip(label: Text('Việc quan trọng')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add_task),
                              onPressed: () {},
                              label: const Text('Thêm nhiệm vụ'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_month_outlined),
                              onPressed: () {},
                              label: const Text('Lịch biểu'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _modeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Theo hệ thống';
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
    }
  }

  static String _modeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Tự động đồng bộ theo cài đặt của thiết bị.';
      case ThemeMode.light:
        return 'Giao diện sáng, phù hợp môi trường nhiều ánh sáng.';
      case ThemeMode.dark:
        return 'Giao diện tối để giảm chói mắt và tiết kiệm pin.';
    }
  }
}

class _ThemeColorOption extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? Theme.of(context).colorScheme.onPrimary : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: selected ? 4 : 2),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: selected
            ? const Icon(
                Icons.check,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}