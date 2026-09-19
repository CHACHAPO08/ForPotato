import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Emoji options selectable as an entry's calendar-day marker. `null` means
/// "not selected", in which case the calendar falls back to a plain circle.
const List<String> markerEmojiOptions = ['❤️', '⭐', '⚪'];

class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text()();
  TextColumn get mood => text().nullable()();
  TextColumn get emoji => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
}

class EntryTags extends Table {
  IntColumn get entryId =>
      integer().references(DiaryEntries, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {entryId, tagId};
}

enum MediaType { photo, video }

class Media extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get entryId =>
      integer().references(DiaryEntries, #id, onDelete: KeyAction.cascade)();
  BlobColumn get data => blob()();
  TextColumn get mimeType => text()();
  IntColumn get type => intEnum<MediaType>()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

class EntryWithMedia {
  EntryWithMedia({
    required this.entry,
    required this.media,
    this.tags = const [],
  });

  final DiaryEntry entry;
  final List<MediaData> media;
  final List<String> tags;
}

@DriftDatabase(tables: [DiaryEntries, Tags, EntryTags, Media])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Used by tests to inject an in-memory executor instead of opening a real
  /// database file / IndexedDB store.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  /// For each date that has at least one entry, the calendar marker to show:
  /// the most-recently-created entry's chosen emoji, or `null` to fall back
  /// to a plain circle. Dates with no entries are simply absent from the map.
  Stream<Map<DateTime, String?>> watchDayMarkers() {
    final query = select(diaryEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((entries) {
      final result = <DateTime, String?>{};
      for (final entry in entries) {
        final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
        result.putIfAbsent(day, () => entry.emoji);
      }
      return result;
    });
  }

  Future<List<String>> _tagsForEntry(int entryId) async {
    final query = select(entryTags).join([
      innerJoin(tags, tags.id.equalsExp(entryTags.tagId)),
    ])..where(entryTags.entryId.equals(entryId));
    final rows = await query.get();
    return rows.map((row) => row.readTable(tags).name).toList()..sort();
  }

  Future<EntryWithMedia> _attachDetails(DiaryEntry entry) async {
    final entryMedia =
        await (select(media)
              ..where((m) => m.entryId.equals(entry.id))
              ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
            .get();
    final entryTagNames = await _tagsForEntry(entry.id);
    return EntryWithMedia(
      entry: entry,
      media: entryMedia,
      tags: entryTagNames,
    );
  }

  /// A day can now hold multiple entries, so this watches all of them
  /// (newest first) instead of a single entry per date.
  Stream<List<EntryWithMedia>> watchEntriesForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = select(diaryEntries)
      ..where(
        (t) =>
            t.date.isBiggerOrEqualValue(start) &
            t.date.isSmallerThanValue(end),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    return query.watch().asyncMap(
      (entries) => Future.wait(entries.map(_attachDetails)),
    );
  }

  Future<EntryWithMedia?> entryById(int id) async {
    final entry = await (select(
      diaryEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (entry == null) return null;
    return _attachDetails(entry);
  }

  Future<int> _findOrCreateTag(String name) async {
    final existing = await (select(
      tags,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(tags).insert(TagsCompanion.insert(name: name));
  }

  Future<int> upsertEntry({
    required int? existingId,
    required DateTime date,
    required String title,
    required String content,
    required List<MediaCompanion> mediaRows,
    List<String> tagNames = const [],
    String? emoji,
  }) async {
    return transaction(() async {
      final int entryId;
      if (existingId != null) {
        await (update(
          diaryEntries,
        )..where((t) => t.id.equals(existingId))).write(
          DiaryEntriesCompanion(
            title: Value(title),
            content: Value(content),
            emoji: Value(emoji),
            updatedAt: Value(DateTime.now()),
          ),
        );
        await (delete(
          media,
        )..where((m) => m.entryId.equals(existingId))).go();
        await (delete(
          entryTags,
        )..where((t) => t.entryId.equals(existingId))).go();
        entryId = existingId;
      } else {
        entryId = await into(diaryEntries).insert(
          DiaryEntriesCompanion.insert(
            date: date,
            title: Value(title),
            content: content,
            emoji: Value(emoji),
          ),
        );
      }

      for (final row in mediaRows) {
        await into(
          media,
        ).insert(row.copyWith(entryId: Value(entryId)));
      }

      final seen = <String>{};
      for (final rawName in tagNames) {
        final name = rawName.trim();
        if (name.isEmpty || !seen.add(name)) continue;
        final tagId = await _findOrCreateTag(name);
        await into(entryTags).insert(
          EntryTagsCompanion.insert(entryId: entryId, tagId: tagId),
        );
      }

      return entryId;
    });
  }

  Future<void> deleteEntry(int id) async {
    await transaction(() async {
      await (delete(media)..where((m) => m.entryId.equals(id))).go();
      await (delete(entryTags)..where((t) => t.entryId.equals(id))).go();
      await (delete(diaryEntries)..where((t) => t.id.equals(id))).go();
    });
  }

  Stream<List<EntryWithMedia>> watchEntriesWithMedia() {
    final entriesQuery = select(diaryEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.date)]);

    return entriesQuery.watch().asyncMap((entries) async {
      final result = <EntryWithMedia>[];
      for (final entry in entries) {
        final entryMedia =
            await (select(media)
                  ..where((m) => m.entryId.equals(entry.id))
                  ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
                .get();
        final entryTagNames = await _tagsForEntry(entry.id);
        result.add(
          EntryWithMedia(entry: entry, media: entryMedia, tags: entryTagNames),
        );
      }
      return result;
    });
  }

  Stream<List<String>> watchAllTagNames() {
    final query = select(tags)..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch().map((rows) => rows.map((t) => t.name).toList());
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'diary_app',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.dart.js'),
    ),
  );
}
