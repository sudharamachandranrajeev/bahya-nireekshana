import 'package:brahma_core/brahma_core.dart';
import 'package:drift/drift.dart';

import 'tables.dart';

export 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [NirDays, NirApps, NirPlans, NirSpeedTests, NirThemes, Prefs, Outbox, SyncCursors, LocalSettings],
)
class AppDatabase extends _$AppDatabase with SyncedDatabase {
  AppDatabase(super.e);

  /// Opens Bahya Nireekshana's encrypted database (see [openEncryptedDatabase]).
  AppDatabase.open(String key) : this(openEncryptedDatabase('nireekshana', key));

  @override
  final syncedTables = const ['nir_days', 'nir_apps', 'nir_plans', 'nir_speed_tests', 'nir_themes', 'prefs'];

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      for (final sql in _indexes) {
        await customStatement(sql);
      }
    },
    onUpgrade: (m, from, to) async {
      // 2: daily usage per app.
      if (from < 2) {
        await m.createTable(nirApps);
        await customStatement(_appsIndex);
      }
    },
  );

  static const _indexes = [
    'CREATE INDEX nir_days_day ON nir_days (day)',
    'CREATE INDEX nir_speed_tests_at ON nir_speed_tests (at)',
    _appsIndex,
  ];

  static const _appsIndex = 'CREATE INDEX nir_apps_day ON nir_apps (day)';
}
