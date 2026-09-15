import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../database/database.dart';
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

          if (hasEntry(selectedDay)) {
            await _showEntryPreview(selectedDay);
          } else if (mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TodayDiaryPage(date: selectedDay),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _showEntryPreview(DateTime day) async {
    final db = ref.read(databaseProvider);
    final entry = await db.entryForDate(day);
    if (!mounted || entry == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.year}.${day.month.toString().padLeft(2, '0')}.${day.day.toString().padLeft(2, '0')}',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (entry.entry.content.isNotEmpty)
                Text(
                  entry.entry.content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              if (entry.media.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: entry.media.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final media = entry.media[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: media.type == MediaType.photo
                            ? Image.memory(
                                media.data,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.black12,
                                child: const Icon(Icons.videocam, size: 32),
                              ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TodayDiaryPage(date: day),
                      ),
                    );
                  },
                  child: const Text('수정'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
