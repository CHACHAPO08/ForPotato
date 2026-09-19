import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../main.dart' show CuteColors;
import '../providers/database_provider.dart';
import '../widgets/entry_preview_dialog.dart';
import 'entry_edit_page.dart';

final _entriesForDateProvider = StreamProvider.family<
    List<EntryWithMedia>, DateTime>((ref, date) {
  final db = ref.watch(databaseProvider);
  return db.watchEntriesForDate(date);
});

/// Lists every entry written on a given day (title + a small photo preview
/// only) — a day can now hold several posts. Tapping one opens a centered
/// preview popup; the "+" FAB always opens a blank composer for this date.
class TodayDiaryPage extends ConsumerWidget {
  const TodayDiaryPage({super.key, this.date});

  /// The day this page lists entries for. Defaults to today when not
  /// provided (the bottom-nav "Today" tab); explicit when pushed from
  /// Calendar for another day.
  final DateTime? date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final targetDate = DateTime(
      (date ?? now).year,
      (date ?? now).month,
      (date ?? now).day,
    );
    final isToday = date == null;
    final title = isToday ? 'Today' : DateFormat('yyyy.MM.dd').format(targetDate);

    final entriesAsync = ref.watch(_entriesForDateProvider(targetDate));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류: $error')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('아직 작성한 글이 없습니다'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  color: CuteColors.textSecondary.withValues(alpha: 0.15),
                ),
                itemBuilder: (context, index) {
                  final item = entries[index];
                  final firstMedia = item.media.isNotEmpty
                      ? item.media.first
                      : null;
                  return InkWell(
                    onTap: () => showEntryPreviewDialog(context, ref, item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.entry.title.isNotEmpty
                                ? item.entry.title
                                : '(제목 없음)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (firstMedia != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: firstMedia.type == MediaType.photo
                                  ? Image.memory(
                                      firstMedia.data,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 72,
                                      height: 72,
                                      color: CuteColors.accent.withValues(
                                        alpha: 0.12,
                                      ),
                                      child: const Icon(
                                        Icons.videocam,
                                        size: 28,
                                        color: CuteColors.accent,
                                      ),
                                    ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EntryEditPage(date: targetDate),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
