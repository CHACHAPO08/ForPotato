import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/database_provider.dart';
import 'today_diary_page.dart';

final _entryDatesProvider = StreamProvider<Set<DateTime>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchEntryDates();
});

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final entryDates = ref.watch(_entryDatesProvider).value ?? {};

    bool hasEntry(DateTime day) =>
        entryDates.contains(DateTime(day.year, day.month, day.day));

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => hasEntry(day) ? const [1] : const [],
        onDaySelected: (selectedDay, focusedDay) async {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TodayDiaryPage(date: selectedDay),
            ),
          );
        },
      ),
    );
  }
}
