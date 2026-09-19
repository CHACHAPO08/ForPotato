import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database.dart';
import '../providers/database_provider.dart';
import '../theme/analog_theme.dart';

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
              decoration: const InputDecoration(
                hintText: '키워드 검색',
                prefixIcon: Icon(Icons.search),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(item.entry.date),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AnalogColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      if (item.entry.content.isNotEmpty)
                        Text(item.entry.content),
                      if (item.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final tag in item.tags)
                              Chip(
                                label: Text('#$tag'),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ],
                      if (item.media.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 104,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: item.media.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, mediaIndex) {
                              final media = item.media[mediaIndex];
                              return PolaroidThumbnail(
                                size: 90,
                                index: mediaIndex,
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
                                        color: Colors.black12,
                                        child: const Icon(
                                          Icons.videocam,
                                          size: 32,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
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
