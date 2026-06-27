import 'package:flutter/material.dart';
import 'package:focusboard/app/controller/analytics_controller.dart';
import 'package:focusboard/app/model/eisenhower_config.dart';
import 'package:focusboard/app/model/task_model.dart';
import 'package:focusboard/helpers/theme/app_theme.dart';
import 'package:focusboard/helpers/widgets/my_container.dart';
import 'package:focusboard/helpers/widgets/my_text.dart';
import 'package:get/get.dart';

/// Analytics dashboard.
///
/// All metrics are derived live from the Kanban and Eisenhower controllers.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AnalyticsController controller =
        Get.find<AnalyticsController>();

    return Scaffold(
      backgroundColor: AppTheme.theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        child: Obx(
          () => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _OverviewRow(
                  total: controller.totalKanban,
                  completed: controller.totalCompleted,
                  highPriority: controller.totalHighPriority,
                  completionPercent: controller.completionPercent,
                ),
                const SizedBox(height: 16),
                _SectionTitle('Kanban Distribution'),
                const SizedBox(height: 8),
                _KanbanBarChart(
                  counts: controller.kanbanCounts,
                ),
                const SizedBox(height: 24),
                _SectionTitle('Eisenhower Matrix'),
                const SizedBox(height: 8),
                _QuadrantBreakdown(
                  counts: controller.quadrantCounts,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return MyText.titleMedium(text, fontWeight: 700);
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.total,
    required this.completed,
    required this.highPriority,
    required this.completionPercent,
  });

  final int total;
  final int completed;
  final int highPriority;
  final int completionPercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _MetricCard(
            label: 'Total',
            value: total.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'Completed',
            value: completed.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'High Priority',
            value: highPriority.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'Completion',
            value: '$completionPercent%',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MyContainer(
      padding: const EdgeInsets.all(12),
      borderRadiusAll: 12,
      color: AppTheme.theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          MyText.bodySmall(label, color: AppTheme.theme.hintColor),
          const SizedBox(height: 6),
          MyText.headlineSmall(value, fontWeight: 700),
        ],
      ),
    );
  }
}

class _KanbanBarChart extends StatelessWidget {
  const _KanbanBarChart({required this.counts});

  final Map<KanbanColumn, int> counts;

  @override
  Widget build(BuildContext context) {
    final int maxValue = counts.values.fold<int>(
        0, (int p, int c) => c > p ? c : p);

    return MyContainer(
      padding: const EdgeInsets.all(12),
      borderRadiusAll: 12,
      color: AppTheme.theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final KanbanColumn col in KanbanColumn.values)
            _Bar(
              label: col.label,
              value: counts[col] ?? 0,
              maxValue: maxValue,
              color: AppTheme.primaryColor,
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double pct = maxValue == 0 ? 0 : value / maxValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: MyText.bodySmall(label)),
              MyText.bodySmall(value.toString(), fontWeight: 600),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppTheme.theme.dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuadrantBreakdown extends StatelessWidget {
  const _QuadrantBreakdown({required this.counts});

  final Map<EisenhowerQuadrant, int> counts;

  @override
  Widget build(BuildContext context) {
    return MyContainer(
      padding: const EdgeInsets.all(12),
      borderRadiusAll: 12,
      color: AppTheme.theme.cardColor,
      child: Column(
        children: <Widget>[
          for (final EisenhowerQuadrant q in EisenhowerQuadrant.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(EisenhowerConfig.quadrantColors[q] ??
                          0xFF9E9E9E),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MyText.bodyMedium(
                      EisenhowerConfig.getQuadrantName(q),
                    ),
                  ),
                  MyText.bodyMedium(
                    (counts[q] ?? 0).toString(),
                    fontWeight: 600,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
