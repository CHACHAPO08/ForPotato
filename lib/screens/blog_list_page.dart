import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../main.dart' show CuteColors;
import '../providers/database_provider.dart';
import '../widgets/entry_preview_dialog.dart';

final _entriesProvider = StreamProvider<List<EntryWithMedia>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchEntriesWithMedia();
});

class BlogListPage extends ConsumerWidget {
  const BlogListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(_entriesProvider);
    final dateFormat = DateFormat('yyyy.MM.dd (E)');

    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 글'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '키워드 검색',
                prefixIcon: const Icon(
                  Icons.search,
                  color: CuteColors.accent,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: CuteColors.accent.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류: $error')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('아직 작성한 글이 없습니다'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final item = entries[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => showEntryPreviewDialog(context, ref, item),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(item.entry.date),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: CuteColors.textSecondary),
                        ),
                        if (item.media.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final media in item.media)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: media.type == MediaType.photo
                                      ? Image.memory(
                                          media.data,
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 90,
                                          height: 90,
                                          color: CuteColors.accent
                                              .withValues(alpha: 0.12),
                                          child: const Icon(
                                            Icons.videocam,
                                            size: 32,
                                            color: CuteColors.accent,
                                          ),
                                        ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
