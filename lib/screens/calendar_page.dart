import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../main.dart' show CuteColors;
import '../providers/database_provider.dart';
import 'today_diary_page.dart';

final _dayMarkersProvider = StreamProvider<Map<DateTime, String?>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchDayMarkers();
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
    final dayMarkers = ref.watch(_dayMarkersProvider).value ?? {};

    Widget dayCell(DateTime day, {bool selected = false}) {
      final normalized = DateTime(day.year, day.month, day.day);
      final hasEntry = dayMarkers.containsKey(normalized);
      final emoji = hasEntry ? dayMarkers[normalized] : null;
      final numberColor = selected ? Colors.white : CuteColors.textMain;

      if (!hasEntry) {
        return Center(
          child: Text('${day.day}', style: TextStyle(color: numberColor)),
        );
      }

      return Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (emoji != null)
                Text(emoji, style: const TextStyle(fontSize: 24))
              else
                Icon(
                  Icons.circle,
                  size: 24,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.35)
                      : CuteColors.accent.withValues(alpha: 0.3),
                ),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: numberColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget highlighted(DateTime day, {required Color background}) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: dayCell(day, selected: true),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TodayDiaryPage(date: selectedDay),
                  ),
                );
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) => dayCell(day),
                todayBuilder: (context, day, focusedDay) => highlighted(
                  day,
                  background: CuteColors.accent.withValues(alpha: 0.35),
                ),
                selectedBuilder: (context, day, focusedDay) =>
                    highlighted(day, background: CuteColors.accent),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: CuteColors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: CuteColors.accent,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: CuteColors.accent,
                ),
              ),
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
