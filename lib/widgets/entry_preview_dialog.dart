import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../main.dart' show CuteColors;
import '../providers/database_provider.dart';
import '../screens/entry_edit_page.dart';

/// Centered preview popup for one diary entry: title, photo(s), content,
/// tags (in that order), then 수정/삭제 actions. Used from both the
/// Today/Calendar entry list and (eventually) anywhere else an entry needs
/// a quick look.
Future<void> showEntryPreviewDialog(
  BuildContext context,
  WidgetRef ref,
  EntryWithMedia entry,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: CuteColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.entry.title.isNotEmpty
                        ? entry.entry.title
                        : '(제목 없음)',
                    style: Theme.of(dialogContext).textTheme.titleLarge,
                  ),
                  if (entry.media.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final media in entry.media)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: media.type == MediaType.photo
                                ? Image.memory(
                                    media.data,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 100,
                                    height: 100,
                                    color: CuteColors.accent.withValues(
                                      alpha: 0.12,
                                    ),
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
                  if (entry.entry.content.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(entry.entry.content),
                  ],
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in entry.tags)
                          Chip(label: Text('#$tag')),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _confirmDelete(dialogContext, ref, entry),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('삭제'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EntryEditPage(
                                date: entry.entry.date,
                                existing: entry,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('수정'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _confirmDelete(
  BuildContext dialogContext,
  WidgetRef ref,
  EntryWithMedia entry,
) async {
  final confirmed = await showDialog<bool>(
    context: dialogContext,
    builder: (context) => AlertDialog(
      title: const Text('삭제하시겠습니까?'),
      content: const Text('삭제한 글은 되돌릴 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  await ref.read(databaseProvider).deleteEntry(entry.entry.id);
  if (dialogContext.mounted) {
    Navigator.of(dialogContext).pop();
  }
}
