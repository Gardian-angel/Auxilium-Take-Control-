import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../data/models/models.dart';

/// Stats are computed on-device from the local mood log, so the screen
/// works offline and updates as soon as a check-in is saved.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ValueListenableBuilder<Box>(
        valueListenable: Hive.box('moodLogs').listenable(),
        builder: (context, box, _) {
          final entries = box.values
              .map((v) => MoodEntryModel.fromJson(Map<String, dynamic>.from(v as Map)))
              .toList();
          final stats = MoodStats.fromEntries(entries, DateTime.now());

          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Log your first check-in on the Dashboard to see your trends here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MetricCard(
                  label: 'Active days (last 7)',
                  value: '${stats.activeDays}',
                  icon: Icons.calendar_today),
              const SizedBox(height: 12),
              _MetricCard(
                  label: 'Avg satisfaction',
                  value: stats.avgSatisfaction == null
                      ? '–'
                      : '${(stats.avgSatisfaction! * 100).round()}%',
                  icon: Icons.sentiment_satisfied_alt),
              const SizedBox(height: 12),
              _MetricCard(
                  label: 'Top emotion',
                  value: stats.topEmotion == null ? '–' : _label(stats.topEmotion!),
                  icon: Icons.spa_rounded),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Satisfaction, last 7 days',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(height: 180, child: _TrendChart(stats: stats)),
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

String _label(EmotionType e) => e.name[0].toUpperCase() + e.name.substring(1);

class MoodStats {
  /// Days ending today, oldest first.
  final List<DateTime> days;

  /// Average satisfaction (0–1) per day in [days]; null when nothing was logged.
  final List<double?> dailySatisfaction;
  final int activeDays;
  final double? avgSatisfaction;
  final EmotionType? topEmotion;

  const MoodStats({
    required this.days,
    required this.dailySatisfaction,
    required this.activeDays,
    required this.avgSatisfaction,
    required this.topEmotion,
  });

  factory MoodStats.fromEntries(List<MoodEntryModel> entries, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final byDay = <DateTime, List<MoodEntryModel>>{};
    for (final e in entries) {
      final local = e.createdAt.toLocal();
      final d = DateTime(local.year, local.month, local.day);
      if (d.isBefore(days.first) || d.isAfter(today)) continue;
      byDay.putIfAbsent(d, () => []).add(e);
    }

    final daily = days.map((d) {
      final list = byDay[d];
      if (list == null || list.isEmpty) return null;
      return list.map((e) => e.satisfaction).reduce((a, b) => a + b) / list.length;
    }).toList();

    final week = byDay.values.expand((l) => l).toList();
    final counts = <EmotionType, int>{};
    for (final e in week) {
      counts[e.emotion] = (counts[e.emotion] ?? 0) + 1;
    }
    EmotionType? top;
    if (counts.isNotEmpty) {
      top = counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
    }

    return MoodStats(
      days: days,
      dailySatisfaction: daily,
      activeDays: byDay.length,
      avgSatisfaction: week.isEmpty
          ? null
          : week.map((e) => e.satisfaction).reduce((a, b) => a + b) / week.length,
      topEmotion: top,
    );
  }
}

class _TrendChart extends StatelessWidget {
  final MoodStats stats;
  const _TrendChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final spots = <FlSpot>[
      for (var i = 0; i < stats.days.length; i++)
        if (stats.dailySatisfaction[i] != null)
          FlSpot(i.toDouble(), stats.dailySatisfaction[i]!),
    ];
    final weekday = DateFormat.E();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 1,
        gridData: const FlGridData(drawVerticalLine: false, horizontalInterval: 0.5),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.5,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${(value * 100).round()}%',
                  style: const TextStyle(fontSize: 11)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(weekday.format(stats.days[value.toInt()]),
                    style: const TextStyle(fontSize: 11)),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MetricCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
