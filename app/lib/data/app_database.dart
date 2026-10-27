import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Every answer ever given; the history behind accuracy and streak stats.
class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionId => text()();
  TextColumn get topic => text()();
  IntColumn get choice => integer()();
  BoolColumn get correct => boolean()();
  DateTimeColumn get answeredAt => dateTime()();
}

/// Current spaced-repetition state, one row per question answered at least once.
class Cards extends Table {
  TextColumn get questionId => text()();
  TextColumn get topic => text()();
  IntColumn get intervalDays => integer()();
  DateTimeColumn get dueAt => dateTime()();
  IntColumn get reps => integer()();
  IntColumn get lapses => integer()();

  @override
  Set<Column> get primaryKey => {questionId};
}

@DriftDatabase(tables: [Attempts, Cards])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-device database, opened on a background isolate.
  factory AppDatabase.open() => AppDatabase(
        LazyDatabase(() async {
          final dir = await getApplicationSupportDirectory();
          return NativeDatabase.createInBackground(File(p.join(dir.path, 'cseasy.sqlite')));
        }),
      );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX attempts_topic ON attempts (topic)');
          await customStatement('CREATE INDEX attempts_answered_at ON attempts (answered_at)');
        },
      );
}
