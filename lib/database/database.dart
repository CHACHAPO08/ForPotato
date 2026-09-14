import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class DiaryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get content => text()();
  TextColumn get mood => text().nullable()();
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
  EntryWithMedia({required this.entry, required this.media});

  final DiaryEntry entry;
  final List<MediaData> media;
}

@DriftDatabase(tables: [DiaryEntries, Tags, EntryTags, Media])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

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
        result.add(EntryWithMedia(entry: entry, media: entryMedia));
      }
      return result;
    });
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
