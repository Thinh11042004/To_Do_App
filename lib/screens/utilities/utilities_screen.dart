import 'package:flutter/material.dart';

import '../../services/settings_service.dart';

class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = SettingsService.instance;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tiện ích')),
      body: AnimatedBuilder(
        animation: service,
        builder: (context, _) {
          final state = service.state;
          final reminderLabel = MaterialLocalizations.of(context).formatTimeOfDay(state.reminderTime);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
            children: [
              Text(
                'Tối ưu hiệu suất làm việc',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: state.focusMode,
                onChanged: (value) => service.setFocusMode(value),
                title: const Text('Chế độ tập trung'),
                subtitle: const Text('Tạm tắt thông báo không quan trọng trong giờ làm việc.'),
                secondary: const Icon(Icons.do_not_disturb_on_total_silence),
              ),
              SwitchListTile.adaptive(
                value: state.autoArchiveCompleted,
                onChanged: (value) => service.setAutoArchiveCompleted(value),
                title: const Text('Tự động lưu trữ nhiệm vụ hoàn thành'),
                subtitle: const Text('Giúp danh sách luôn gọn gàng sau 24 giờ hoàn thành nhiệm vụ.'),
                secondary: const Icon(Icons.archive_outlined),
              ),
              SwitchListTile.adaptive(
                value: state.calendarSync,
                onChanged: (value) => service.setCalendarSync(value),
                title: const Text('Đồng bộ với lịch cá nhân'),
                subtitle: const Text('Xuất nhiệm vụ quan trọng sang ứng dụng lịch của bạn.'),
                secondary: const Icon(Icons.calendar_month),
              ),
              const Divider(height: 36),
              Text(
                'Nhắc nhở thông minh',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: state.notificationsEnabled,
                onChanged: (value) => service.setNotificationsEnabled(value),
                title: const Text('Bản tin tổng kết hằng ngày'),
                subtitle: const Text('Nhận thông báo tổng hợp các nhiệm vụ chưa hoàn thành.'),
                secondary: const Icon(Icons.notifications_active_outlined),
              ),
              ListTile(
                enabled: state.notificationsEnabled,
                leading: const Icon(Icons.schedule),
                title: const Text('Thời điểm gửi'),
                subtitle: Text(state.notificationsEnabled
                    ? 'Gửi vào $reminderLabel mỗi ngày'
                    : 'Bật bản tin để chọn thời gian'),
                trailing: const Icon(Icons.chevron_right),
                onTap: state.notificationsEnabled
                    ? () async {
                        final newTime = await showTimePicker(
                          context: context,
                          initialTime: state.reminderTime,
                        );
                        if (newTime != null) {
                          service.setReminderTime(newTime);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 24),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mẹo nhanh',
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const _UtilityTip(
                        icon: Icons.bolt,
                        title: 'Giữ nút + để tạo nhanh chuỗi nhiệm vụ',
                      ),
                      const _UtilityTip(
                        icon: Icons.swipe_vertical,
                        title: 'Vuốt sang phải để đánh dấu hoàn thành',
                      ),
                      const _UtilityTip(
                        icon: Icons.voice_chat_outlined,
                        title: 'Nhấn micro khi thêm nhiệm vụ để nhập giọng nói',
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
}

class _UtilityTip extends StatelessWidget {
  final IconData icon;
  final String title;

  const _UtilityTip({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}