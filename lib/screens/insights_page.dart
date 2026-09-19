import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../main.dart';

/// Insights page, currently backed by sample/fake data only. Wiring these
/// charts up to real DB aggregation queries is left for a later pass — see
/// the design task notes; this page is a visual/layout implementation.
class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _StreakCard(),
          SizedBox(height: 16),
          _SectionCard(title: '이번 달 기록 히트맵', child: _MonthlyHeatmap()),
          SizedBox(height: 16),
          _SectionCard(title: '감정 분포', child: _MoodDistributionChart()),
          SizedBox(height: 16),
          _SectionCard(title: '자주 쓰는 태그', child: _TagCloud()),
        ],
      ),
    );
  }
}

/// Shared flat, bordered card shell matching the minimal theme's CardTheme
/// (radius 14, 1px #EAEAE6 border, no shadow) plus a section title.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Plain stat card: "7일 연속 작성" — the numeral carries emphasis purely
/// through font weight/size, never color, per the minimal spec.
class _StreakCard extends StatelessWidget {
  const _StreakCard();

  static const _sampleStreak = 7;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Text(
              '$_sampleStreak',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '일',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '연속으로 일기를 작성하고 있어요',
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A day of sample data backing the heatmap and mood distribution below.
class _SampleDay {
  const _SampleDay({required this.day, required this.moodIndex});

  /// Day of month (1-based).
  final int day;

  /// Index into [_moodPalette]/[_moodLabels], or null when there's no entry
  /// for that day.
  final int? moodIndex;
}

const _moodPalette = [
  AppColors.moodBest,
  AppColors.moodGood,
  AppColors.moodNeutral,
  AppColors.moodMeh,
  AppColors.moodBad,
];

const _moodLabels = ['최고', '좋음', '보통', '별로', '힘듦'];

/// Deterministic fake data for one 30-day month: most days have an entry
/// with a mood, a handful are left blank to show the "no entry" state.
List<_SampleDay> _sampleMonth() {
  const skippedDays = {4, 9, 17, 23, 28};
  return [
    for (var day = 1; day <= 30; day++)
      _SampleDay(
        day: day,
        moodIndex: skippedDays.contains(day)
            ? null
            : (day * 7 + day ~/ 3) % _moodPalette.length,
      ),
  ];
}

class _MonthlyHeatmap extends StatelessWidget {
  const _MonthlyHeatmap();

  @override
  Widget build(BuildContext context) {
    final days = _sampleMonth();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final sampleDay = days[index];
            final moodIndex = sampleDay.moodIndex;
            final fillColor = moodIndex == null
                ? AppColors.background
                : _moodPalette[moodIndex].withValues(alpha: 0.55);
            return Tooltip(
              message: moodIndex == null
                  ? '${sampleDay.day}일 · 기록 없음'
                  : '${sampleDay.day}일 · ${_moodLabels[moodIndex]}',
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${sampleDay.day}',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _MoodLegend(),
      ],
    );
  }
}

class _MoodLegend extends StatelessWidget {
  const _MoodLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _moodPalette.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _moodPalette[i],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _moodLabels[i],
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
      ],
    );
  }
}

/// Emotion distribution as a flat, thin BarChart — one hue per mood, no
/// gradients, counts derived from the same sample month as the heatmap.
class _MoodDistributionChart extends StatelessWidget {
  const _MoodDistributionChart();

  @override
  Widget build(BuildContext context) {
    final days = _sampleMonth();
    final counts = List<int>.filled(_moodPalette.length, 0);
    for (final day in days) {
      if (day.moodIndex != null) counts[day.moodIndex!]++;
    }
    final maxCount = counts.reduce(math.max).toDouble();
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxCount + 1,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.accent,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${_moodLabels[group.x]}  ${rod.toY.round()}일',
                  TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= _moodLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _moodLabels[index],
                      style: textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < counts.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: counts[i].toDouble(),
                    color: _moodPalette[i],
                    width: 22,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SampleTag {
  const _SampleTag(this.label, this.count);

  final String label;
  final int count;
}

const _sampleTags = [
  _SampleTag('일상', 18),
  _SampleTag('운동', 13),
  _SampleTag('회고', 11),
  _SampleTag('friends', 9),
  _SampleTag('여행', 8),
  _SampleTag('독서', 7),
  _SampleTag('맛집', 6),
  _SampleTag('영화', 5),
  _SampleTag('업무', 5),
  _SampleTag('산책', 4),
  _SampleTag('카페', 3),
  _SampleTag('음악', 2),
];

/// Approximates a tag word cloud with a Wrap of chips: frequency drives
/// font weight (and a touch of size), never color — everything stays close
/// to ink navy / grayscale per the minimal spec.
class _TagCloud extends StatelessWidget {
  const _TagCloud();

  @override
  Widget build(BuildContext context) {
    final maxCount = _sampleTags
        .map((t) => t.count)
        .reduce(math.max)
        .toDouble();
    final minCount = _sampleTags
        .map((t) => t.count)
        .reduce(math.min)
        .toDouble();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in _sampleTags)
          _TagCloudChip(
            tag: tag,
            intensity: maxCount == minCount
                ? 1.0
                : (tag.count - minCount) / (maxCount - minCount),
          ),
      ],
    );
  }
}

class _TagCloudChip extends StatelessWidget {
  const _TagCloudChip({required this.tag, required this.intensity});

  final _SampleTag tag;

  /// 0.0 (least frequent) .. 1.0 (most frequent).
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final fontSize = 12 + intensity * 6; // 12..18
    final weight = intensity > 0.66
        ? FontWeight.w700
        : intensity > 0.33
        ? FontWeight.w600
        : FontWeight.w500;
    final color = Color.lerp(
      AppColors.textSecondary,
      AppColors.accent,
      intensity,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Text(
        '#${tag.label}',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: weight,
          color: color,
          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
        ),
      ),
    );
  }
}
