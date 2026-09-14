import 'package:flutter/material.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('캘린더 히트맵'),
          SizedBox(height: 24),
          Text('연속 작성일(스트릭)'),
          SizedBox(height: 24),
          Text('월별 감정 분포'),
          SizedBox(height: 24),
          Text('자주 쓰는 태그/키워드'),
        ],
      ),
    );
  }
}
