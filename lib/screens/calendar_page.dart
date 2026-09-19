import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../database/database.dart';
import '../main.dart' show CuteColors;
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
              eventLoader: (day) => hasEntry(day) ? const [1] : const [],
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _showEntryPreview(selectedDay);
              },
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
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(color: CuteColors.textMain),
                weekendTextStyle: const TextStyle(color: CuteColors.textMain),
                todayDecoration: BoxDecoration(
                  color: CuteColors.accent.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(color: CuteColors.textMain),
                selectedDecoration: const BoxDecoration(
                  color: CuteColors.accent,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: CuteColors.moodGood,
                  shape: BoxShape.circle,
                ),
                markersAlignment: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openEditor(DateTime day) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TodayDiaryPage(date: day)),
    );
  }

  Future<void> _showEntryPreview(DateTime day) async {
    final db = ref.read(databaseProvider);
    final dateLabel =
        '${day.year}.${day.month.toString().padLeft(2, '0')}.${day.day.toString().padLeft(2, '0')}';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: CuteColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return FutureBuilder<EntryWithMedia?>(
          future: db.entryForDate(day),
          builder: (context, snapshot) {
            final content = Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: _buildSheetBody(
                sheetContext: sheetContext,
                day: day,
                dateLabel: dateLabel,
                snapshot: snapshot,
              ),
            );
            return content;
          },
        );
      },
    );
  }

  Widget _buildSheetBody({
    required BuildContext sheetContext,
    required DateTime day,
    required String dateLabel,
    required AsyncSnapshot<EntryWithMedia?> snapshot,
  }) {
    if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
      return SizedBox(
        height: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateLabel, style: Theme.of(sheetContext).textTheme.titleMedium),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    final entry = snapshot.data;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(dateLabel, style: Theme.of(sheetContext).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (entry == null)
          const Text('아직 작성한 글이 없습니다')
        else ...[
          if (entry.entry.content.isNotEmpty)
            Text(
              entry.entry.content,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in entry.tags)
                  Chip(
                    label: Text('#$tag'),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
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
                    borderRadius: BorderRadius.circular(16),
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
                            color: CuteColors.accent.withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.videocam,
                              size: 32,
                              color: CuteColors.accent,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              _openEditor(day);
            },
            icon: Icon(entry == null ? Icons.add : Icons.edit),
            label: Text(entry == null ? '추가' : '수정'),
          ),
        ),
      ],
    );
  }
}
