import 'package:flutter/material.dart';

class TodayDiaryPage extends StatelessWidget {
  const TodayDiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: const Center(child: Text('오늘의 다이어리 작성')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
