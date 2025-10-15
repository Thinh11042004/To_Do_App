import 'package:flutter/material.dart';

import '../services/ai_insights_service.dart';

class AiInsightCard extends StatelessWidget {
  final AiInsightsSummary summary;
  final VoidCallback? onRefresh;
  const AiInsightCard({super.key, required this.summary, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withOpacity(.85),
              scheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withOpacity(.12),
                    ),
                    child: Icon(Icons.auto_awesome, color: scheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.headline,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summary.description,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (onRefresh != null)
                    IconButton(
                      tooltip: 'Làm mới gợi ý',
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),
              if (summary.quickWins.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Gợi ý hành động nhanh',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: summary.quickWins
                      .map(
                        (item) => Chip(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          backgroundColor: scheme.primary.withOpacity(.12),
                          label: Text(item),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (summary.agenda.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Kế hoạch linh hoạt cho bạn',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...summary.agenda.map((slot) => _AgendaTile(slot: slot)),
              ],
              if (summary.suggestions.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...summary.suggestions.map((s) => _SuggestionTile(suggestion: s)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final AiSuggestion suggestion;
  const _SuggestionTile({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Color toneColor;
    switch (suggestion.tone) {
      case AiSuggestionTone.positive:
        toneColor = scheme.secondary;
        break;
      case AiSuggestionTone.warning:
        toneColor = scheme.error;
        break;
      case AiSuggestionTone.neutral:
        toneColor = scheme.primary;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(suggestion.icon, color: toneColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(suggestion.detail, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  final AiScheduleSlot slot;
  const _AgendaTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withOpacity(.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.secondary.withOpacity(.2),
            ),
            child: Icon(slot.icon, color: scheme.secondary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.windowLabel,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  slot.focus,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (slot.detail != null) ...[
                  const SizedBox(height: 4),
                  Text(slot.detail!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}