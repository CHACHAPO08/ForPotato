import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart' show CuteColors;

/// A single day's sample state for the monthly heatmap: either no entry was
/// written, or an entry was written with some mood color.
class _HeatmapDay {
  const _HeatmapDay({this.moodColor});

  /// Null means "no diary entry that day".
  final Color? moodColor;
}

class _SampleTag {
  const _SampleTag(this.name, this.count);

  final String name;
  final int count;
}

/// Insights page.
///
/// This is a design/visual pass: everything below is rendered from
/// **hard-coded sample data** so the cute-themed charts/heatmap/word-cloud
/// have something to show. Wiring these up to real aggregation queries over
/// `AppDatabase` is a separate follow-up task.
class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  // ---- Sample data -------------------------------------------------------

  static const _streakDays = 7;

  static const _moodLabels = ['최고', '좋음', '보통', '별로', '힘듦'];
  static const _moodColors = [
    CuteColors.moodBest,
    CuteColors.moodGood,
    CuteColors.moodOkay,
    CuteColors.moodMeh,
    CuteColors.moodBad,
  ];
  // Number of days this month that landed in each mood bucket.
  static const _moodCounts = <double>[6, 9, 5, 3, 2];

  static const _sampleTags = [
    _SampleTag('여행', 12),
    _SampleTag('맛집', 9),
    _SampleTag('운동', 7),
    _SampleTag('친구', 6),
    _SampleTag('공부', 5),
    _SampleTag('영화', 4),
    _SampleTag('산책', 4),
    _SampleTag('독서', 3),
    _SampleTag('반려동물', 3),
    _SampleTag('카페', 2),
    _SampleTag('회고', 2),
    _SampleTag('음악', 1),
  ];

  /// 5 weeks x 7 days of sample heatmap data, deterministically generated
  /// (no randomness) so the page renders the same way every time.
  static List<_HeatmapDay> get _sampleHeatmap {
    return List.generate(35, (i) {
      // A simple repeating pattern that leaves some days blank, like a real
      // "did I write today" heatmap would.
      final bucket = (i * 7 + 3) % 11;
      if (bucket >= 8) return const _HeatmapDay();
      final moodIndex = bucket % _moodColors.length;
      return _HeatmapDay(moodColor: _moodColors[moodIndex]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _StreakCard(streakDays: _streakDays),
          const SizedBox(height: 20),
          _SectionCard(
            title: '📅  이번 달 기록 히트맵',
            child: _HeatmapGrid(days: _sampleHeatmap),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: '📊  월별 감정 분포',
            child: _MoodBarChart(
              labels: _moodLabels,
              colors: _moodColors,
              counts: _moodCounts,
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: '🏷️  자주 쓰는 태그',
            child: _TagCloud(tags: _sampleTags),
          ),
        ],
      ),
    );
  }
}

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
            Text(
              title,
              style: GoogleFonts.gaegu(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: CuteColors.textMain,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CuteColors.accent, CuteColors.moodBest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CuteColors.accent.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays일 연속 작성 중!',
                  style: GoogleFonts.gaegu(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '이 기세를 계속 이어가 봐요 ✨',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.days});

  final List<_HeatmapDay> days;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            return AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: day.moodColor ?? CuteColors.textSecondary.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (var i = 0; i < InsightsPage._moodLabels.length; i++)
              _LegendDot(
                color: InsightsPage._moodColors[i],
                label: InsightsPage._moodLabels[i],
              ),
            _LegendDot(
              color: CuteColors.textSecondary.withValues(alpha: 0.12),
              label: '기록 없음',
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.gowunDodum(
            fontSize: 11,
            color: CuteColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MoodBarChart extends StatelessWidget {
  const _MoodBarChart({
    required this.labels,
    required this.colors,
    required this.counts,
  });

  final List<String> labels;
  final List<Color> colors;
  final List<double> counts;

  @override
  Widget build(BuildContext context) {
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxCount + 2,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => CuteColors.textMain,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${labels[group.x]}\n${rod.toY.round()}일',
                  GoogleFonts.gowunDodum(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[index],
                      style: GoogleFonts.gowunDodum(
                        fontSize: 12,
                        color: CuteColors.textMain,
                      ),
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
                    toY: counts[i],
                    color: colors[i],
                    width: 24,
                    borderRadius: BorderRadius.circular(999),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxCount + 2,
                      color: colors[i].withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TagCloud extends StatelessWidget {
  const _TagCloud({required this.tags});

  final List<_SampleTag> tags;

  @override
  Widget build(BuildContext context) {
    final maxCount = tags.map((t) => t.count).reduce((a, b) => a > b ? a : b);
    final minCount = tags.map((t) => t.count).reduce((a, b) => a < b ? a : b);
    final palette = InsightsPage._moodColors;

    double fontSizeFor(int count) {
      if (maxCount == minCount) return 16;
      final t = (count - minCount) / (maxCount - minCount);
      return 13 + t * 15; // 13 - 28
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < tags.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: palette[i % palette.length].withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '#${tags[i].name}',
              style: GoogleFonts.gaegu(
                fontWeight: FontWeight.bold,
                fontSize: fontSizeFor(tags[i].count),
                color: CuteColors.textMain,
              ),
            ),
          ),
      ],
    );
  }
}
