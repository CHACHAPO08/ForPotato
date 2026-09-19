import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/analog_theme.dart';

/// A single sample data point for the tag "word cloud".
class _TagFrequency {
  const _TagFrequency(this.tag, this.count);
  final String tag;
  final int count;
}

/// Real charts, sample data only (no DB aggregation yet - see file header in
/// the design task). Every visual below reads consistently with the warm,
/// paper-and-ink "analog diary" theme.
class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  // ---- sample data -------------------------------------------------------

  static const int _streakDays = 7;

  /// Mood recorded for a handful of sample days this month (day-of-month ->
  /// mood). Days not present are treated as "no entry".
  static final Map<int, MoodOption> _sampleMoodByDay = {
    1: kMoodOptions[1],
    2: kMoodOptions[2],
    3: kMoodOptions[0],
    5: kMoodOptions[3],
    6: kMoodOptions[1],
    7: kMoodOptions[1],
    8: kMoodOptions[2],
    9: kMoodOptions[0],
    10: kMoodOptions[4],
    11: kMoodOptions[2],
    13: kMoodOptions[1],
    14: kMoodOptions[0],
    15: kMoodOptions[1],
    16: kMoodOptions[2],
    17: kMoodOptions[3],
    18: kMoodOptions[1],
    19: kMoodOptions[0],
  };

  static const Map<String, int> _sampleMoodCounts = {
    '최고': 6,
    '좋음': 9,
    '보통': 5,
    '별로': 3,
    '힘듦': 2,
  };

  static const List<_TagFrequency> _sampleTags = [
    _TagFrequency('여행', 8),
    _TagFrequency('가족', 6),
    _TagFrequency('회고', 5),
    _TagFrequency('운동', 4),
    _TagFrequency('음식', 4),
    _TagFrequency('영화', 3),
    _TagFrequency('친구', 3),
    _TagFrequency('공부', 2),
    _TagFrequency('휴식', 2),
    _TagFrequency('감사', 1),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StreakCard(streakDays: _streakDays),
          const SizedBox(height: 24),
          _SectionTitle('이번 달 기록 히트맵'),
          const SizedBox(height: 12),
          _HeatmapCard(month: now, moodByDay: _sampleMoodByDay),
          const SizedBox(height: 24),
          _SectionTitle('월별 감정 분포'),
          const SizedBox(height: 12),
          _MoodDistributionCard(counts: _sampleMoodCounts),
          const SizedBox(height: 24),
          _SectionTitle('자주 쓰는 태그'),
          const SizedBox(height: 12),
          _TagCloudCard(tags: _sampleTags),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: AnalogColors.textPrimary),
    );
  }
}

/// Paper-card styled streak stat, e.g. "7일째 기록 중".
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays});
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AnalogColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AnalogColors.accent),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: AnalogColors.accent,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streakDays일째 기록 중',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '꾸준히 하루하루를 남기고 있어요',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AnalogColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Manual calendar-grid heatmap: 7 columns of radius-4 paper squares colored
/// by the sample mood for that day. Every cell also carries the day number
/// so mood is never color-alone.
class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.month, required this.moodByDay});

  final DateTime month;
  final Map<int, MoodOption> moodByDay;

  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // DateTime.weekday: Mon=1..Sun=7. Convert to Sun=0..Sat=6 for the grid.
    final leadingBlanks = firstOfMonth.weekday % 7;
    final totalCells = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - (totalCells % 7)) % 7;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${month.year}.${month.month.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (final label in _weekdayLabels)
                  Center(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: AnalogColors.textSecondary),
                    ),
                  ),
                for (var i = 0; i < leadingBlanks; i++) const SizedBox.shrink(),
                for (var day = 1; day <= daysInMonth; day++)
                  _HeatmapCell(day: day, mood: moodByDay[day]),
                for (var i = 0; i < trailingBlanks; i++)
                  const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                for (final mood in kMoodOptions)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: mood.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        mood.label,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AnalogColors.textSecondary),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.day, required this.mood});

  final int day;
  final MoodOption? mood;

  @override
  Widget build(BuildContext context) {
    final hasEntry = mood != null;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasEntry
            ? mood!.color.withValues(alpha: 0.85)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasEntry ? mood!.color : AnalogColors.cardBorder,
        ),
      ),
      child: Text(
        '$day',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: hasEntry ? Colors.white : AnalogColors.textSecondary,
          fontWeight: hasEntry ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

/// Emotion distribution bar chart (fl_chart), one bar per mood in the fixed
/// mood palette order. Mood names are always direct-labeled on the axis, so
/// identity never depends on color alone.
class _MoodDistributionCard extends StatelessWidget {
  const _MoodDistributionCard({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final maxCount = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = ((maxCount + 1) ~/ 2 + 1) * 2.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: AnalogColors.cardBorder,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 2,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: AnalogColors.textSecondary,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= kMoodOptions.length) {
                        return const SizedBox.shrink();
                      }
                      final mood = kMoodOptions[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          mood.label,
                          style: const TextStyle(
                            color: AnalogColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AnalogColors.textPrimary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final mood = kMoodOptions[group.x.toInt()];
                    return BarTooltipItem(
                      '${mood.label}\n${rod.toY.toInt()}일',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              barGroups: [
                for (final (index, mood) in kMoodOptions.indexed)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (counts[mood.label] ?? 0).toDouble(),
                        color: mood.color,
                        width: 22,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tag "word cloud" approximated with a Wrap of outline-pill chips, sized by
/// frequency (bigger font = more frequent tag).
class _TagCloudCard extends StatelessWidget {
  const _TagCloudCard({required this.tags});

  final List<_TagFrequency> tags;

  @override
  Widget build(BuildContext context) {
    final maxCount = tags
        .map((t) => t.count)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tagFreq in tags)
              _TagCloudPill(tagFreq: tagFreq, maxCount: maxCount),
          ],
        ),
      ),
    );
  }
}

class _TagCloudPill extends StatelessWidget {
  const _TagCloudPill({required this.tagFreq, required this.maxCount});

  final _TagFrequency tagFreq;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final ratio = tagFreq.count / maxCount;
    final fontSize = 12 + ratio * 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: AnalogColors.accent),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '#${tagFreq.tag}',
        style: TextStyle(
          color: AnalogColors.accent,
          fontSize: fontSize,
          fontWeight: ratio > 0.6 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
