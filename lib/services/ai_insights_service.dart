import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/task.dart';

class AiInsightsSummary {
  final String headline;
  final String description;
  final List<String> quickWins;
  final List<AiSuggestion> suggestions;
  final List<AiScheduleSlot> agenda;

  const AiInsightsSummary({
    required this.headline,
    required this.description,
    required this.quickWins,
    required this.suggestions,
    required this.agenda,
  });

  bool get hasData => quickWins.isNotEmpty || suggestions.isNotEmpty || agenda.isNotEmpty;
}

class AiSuggestion {
  final String title;
  final String detail;
  final IconData icon;
  final AiSuggestionTone tone;

  const AiSuggestion({
    required this.title,
    required this.detail,
    required this.icon,
    this.tone = AiSuggestionTone.neutral,
  });
}

enum AiSuggestionTone { positive, warning, neutral }

class AiScheduleSlot {
  final String windowLabel;
  final String focus;
  final String? detail;
  final IconData icon;

  const AiScheduleSlot({
    required this.windowLabel,
    required this.focus,
    this.detail,
    this.icon = Icons.timelapse,
  });
}

class AiInsightsService {
  static AiInsightsSummary generate(List<Task> tasks, {DateTime? now}) {
    final DateTime today = _asDate(now ?? DateTime.now());
    final pending = tasks.where((t) => !t.done).toList();
    final completed = tasks.where((t) => t.done).length;

    final overdue = pending
        .where((t) => t.dueDate != null && _asDate(t.dueDate!).isBefore(today))
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final dueSoon = pending
        .where((t) {
          if (t.dueDate == null) return false;
          final d = _asDate(t.dueDate!);
          final delta = d.difference(today).inDays;
          return delta >= 0 && delta <= 2;
        })
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final noDueDate = pending.where((t) => t.dueDate == null).toList();
    final personalBalance = pending.where((t) => t.category == TaskCategory.personal).length;
    final workBalance = pending.where((t) => t.category == TaskCategory.work).length;

    final quickWins = <String>[];
    for (final task in dueSoon.take(3)) {
      final due = task.dueDate!;
      final label = '${task.title} · ${_formatDate(due)}';
      quickWins.add(label);
    }
    if (quickWins.isEmpty && overdue.isNotEmpty) {
      quickWins.add('${overdue.first.title} · quá hạn ${_formatDate(overdue.first.dueDate!)}');
    }

    if (quickWins.isEmpty && pending.isNotEmpty) {
      final focus = pending.reduce((a, b) {
        final ad = a.dueDate ?? today.add(const Duration(days: 7));
        final bd = b.dueDate ?? today.add(const Duration(days: 7));
        return ad.isBefore(bd) ? a : b;
      });
      quickWins.add('${focus.title} · ${focus.dueDate != null ? _formatDate(focus.dueDate!) : 'Chưa có hạn'}');
    }

    final suggestions = <AiSuggestion>[];

    if (overdue.isNotEmpty) {
      suggestions.add(
        AiSuggestion(
          title: 'Ưu tiên nhiệm vụ quá hạn',
          detail:
              'Bạn có ${overdue.length} nhiệm vụ đã quá hạn. Bắt đầu với "${overdue.first.title}" để lấy lại nhịp độ.',
          icon: Icons.warning_rounded,
          tone: AiSuggestionTone.warning,
        ),
      );
    }

    if (dueSoon.isNotEmpty) {
      suggestions.add(
        AiSuggestion(
          title: 'Lên kế hoạch cho ${dueSoon.length} nhiệm vụ sắp tới',
          detail:
              'Các nhiệm vụ đến hạn trong 48 giờ: ${dueSoon.map((t) => '"${t.title}"').take(3).join(', ')}.',
          icon: Icons.schedule_rounded,
          tone: AiSuggestionTone.positive,
        ),
      );
    }

    if (noDueDate.length >= math.max(1, (pending.length * .3).round())) {
      suggestions.add(
        AiSuggestion(
          title: 'Thêm hạn cho nhiệm vụ quan trọng',
          detail:
              '${noDueDate.length} nhiệm vụ chưa có ngày đến hạn. Hãy đặt lịch để AI tiếp tục ưu tiên chính xác hơn.',
          icon: Icons.calendar_month,
        ),
      );
    }

    if (pending.isNotEmpty && completed > pending.length) {
      suggestions.add(
        AiSuggestion(
          title: 'Tiếp tục phong độ hiện tại',
          detail:
              'Bạn đã hoàn thành $completed nhiệm vụ! Hãy chọn một việc ngắn để giữ mạch làm việc.',
          icon: Icons.celebration,
          tone: AiSuggestionTone.positive,
        ),
      );
    }

    if (pending.isNotEmpty && (workBalance - personalBalance).abs() >= 3) {
      final isWorkHeavy = workBalance > personalBalance;
      suggestions.add(
        AiSuggestion(
          title: isWorkHeavy ? 'Cân bằng với nhiệm vụ cá nhân' : 'Dành thêm thời gian cho công việc',
          detail: isWorkHeavy
              ? 'Danh sách công việc đang nghiêng về công việc (${workBalance} vs ${personalBalance}). Hãy thêm một nhiệm vụ cá nhân để cân bằng.'
              : 'Bạn đang có nhiều mục cá nhân hơn (${personalBalance}). Ưu tiên một nhiệm vụ công việc để giữ tiến độ.',
          icon: Icons.auto_graph,
        ),
      );
    }

    final headline = _buildHeadline(pending.length, overdue.length, completed);
    final description = _buildDescription(pending.length, dueSoon.length, overdue.length);

    final agenda = _buildAgenda(today, overdue, dueSoon, pending);

    return AiInsightsSummary(
      headline: headline,
      description: description,
      quickWins: quickWins,
      suggestions: suggestions,
      agenda: agenda,
    );
  }

  static DateTime _asDate(DateTime date) => DateTime(date.year, date.month, date.day);

  static String _formatDate(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  static String _buildHeadline(int pendingCount, int overdueCount, int completedCount) {
    if (pendingCount == 0) {
      return 'Bạn đang rảnh tay 🎉';
    }
    if (overdueCount > 0) {
      return 'Cùng xử lý các nhiệm vụ tồn đọng';
    }
    if (completedCount >= pendingCount) {
      return 'Tiến độ rất tốt!';
    }
    return 'AI đã sắp xếp các ưu tiên cho bạn';
  }

  static String _buildDescription(int pendingCount, int dueSoonCount, int overdueCount) {
    if (pendingCount == 0) {
      return 'Không còn nhiệm vụ nào được giao. Hãy nghỉ ngơi hoặc tạo mục tiêu mới!';
    }
    final buffer = StringBuffer();
    buffer.write('Bạn có $pendingCount nhiệm vụ đang mở.');
    if (dueSoonCount > 0) {
      buffer.write(' $dueSoonCount nhiệm vụ sẽ đến hạn trong 2 ngày tới.');
    }
    if (overdueCount > 0) {
      buffer.write(' $overdueCount nhiệm vụ đã quá hạn, hãy ưu tiên xử lý ngay.');
    }
    return buffer.toString();
  }

  static List<AiScheduleSlot> _buildAgenda(
    DateTime today,
    List<Task> overdue,
    List<Task> dueSoon,
    List<Task> pending,
  ) {
    if (pending.isEmpty) return const [];

    final prioritized = <Task>[
      ...overdue,
      ...dueSoon.where((t) => !overdue.contains(t)),
      ...pending
          .where((t) => !overdue.contains(t) && !dueSoon.contains(t))
          .toList()
        ..sort((a, b) {
          final ad = a.dueDate ?? today.add(const Duration(days: 7));
          final bd = b.dueDate ?? today.add(const Duration(days: 7));
          return ad.compareTo(bd);
        }),
    ];

    String describe(Task task) {
      if (task.dueDate == null) return task.title;
      final label = _formatDate(task.dueDate!);
      if (task.timeOfDay != null) {
        final hh = task.timeOfDay!.hour.toString().padLeft(2, '0');
        final mm = task.timeOfDay!.minute.toString().padLeft(2, '0');
        return '${task.title} · $hh:$mm · $label';
      }
      return '${task.title} · $label';
    }

    final slots = <AiScheduleSlot>[];
    final buckets = <String, List<Task>>{
      'Buổi sáng': prioritized.take(2).toList(),
      'Buổi chiều': prioritized.skip(2).take(2).toList(),
      'Buổi tối': prioritized.skip(4).take(2).toList(),
    };

    buckets.forEach((label, tasks) {
      if (tasks.isEmpty) return;
      final focus = describe(tasks.first);
      final detail = tasks.length > 1
          ? 'Sau đó: ${tasks.skip(1).map((t) => t.title).join(', ')}'
          : null;
      final icon = label == 'Buổi sáng'
          ? Icons.wb_twilight
          : label == 'Buổi chiều'
              ? Icons.wb_sunny
              : Icons.bedtime;
      slots.add(AiScheduleSlot(windowLabel: label, focus: focus, detail: detail, icon: icon));
    });

    return slots;
  }
}