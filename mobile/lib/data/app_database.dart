import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class CachedCatalogs extends Table {
  TextColumn get key => text()();
  TextColumn get type => text()();
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('ConsejoLocal')
class LocalConsejos extends Table {
  TextColumn get uuid => text()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get syncState => text().withDefault(const Constant('draft'))();
  TextColumn get payload => text()();
  TextColumn get error => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@DataClassName('FotoLocal')
class LocalFotos extends Table {
  TextColumn get uuid => text()();
  TextColumn get consejoUuid =>
      text().references(LocalConsejos, #uuid, onDelete: KeyAction.cascade)();
  TextColumn get path => text()();
  TextColumn get descripcion => text().withDefault(const Constant(''))();
  BoolColumn get uploaded => boolean().withDefault(const Constant(false))();
  TextColumn get error => text().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

@DriftDatabase(tables: [CachedCatalogs, LocalConsejos, LocalFotos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'censo_campesino'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Future<void> cacheCatalogos(Map<String, dynamic> catalogos) async {
    await transaction(() async {
      await delete(cachedCatalogs).go();
      for (final entry in catalogos.entries) {
        final items = entry.value;
        if (items is! List) continue;
        for (final item in items.whereType<Map>()) {
          final data = item.cast<String, dynamic>();
          final identifier = data['id'] ?? data['value'] ?? data['nombre'];
          await into(cachedCatalogs).insert(
            CachedCatalogsCompanion.insert(
              key: '${entry.key}:$identifier',
              type: entry.key,
              data: jsonEncode(data),
            ),
          );
        }
      }
    });
  }

  Future<Map<String, List<Map<String, dynamic>>>> readCatalogos() async {
    final rows = await (select(cachedCatalogs)
          ..orderBy([(row) => OrderingTerm.asc(row.key)]))
        .get();
    final result = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      result.putIfAbsent(row.type, () => []).add(
            (jsonDecode(row.data) as Map).cast<String, dynamic>(),
          );
    }
    return result;
  }

  Future<void> saveLocalDraft(
    String uuid,
    Map<String, dynamic> payload, {
    String syncState = 'draft',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await getRecord(uuid);
    await into(localConsejos).insertOnConflictUpdate(
      LocalConsejosCompanion.insert(
        uuid: uuid,
        payload: jsonEncode(payload),
        syncState: Value(syncState),
        serverId: Value(existing?.serverId),
        error: const Value(null),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<ConsejoLocal?> getRecord(String uuid) =>
      (select(localConsejos)..where((row) => row.uuid.equals(uuid)))
          .getSingleOrNull();

  Future<List<ConsejoLocal>> allRecords() => (select(localConsejos)
        ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
      .get();

  Stream<List<ConsejoLocal>> watchRecords() => (select(localConsejos)
        ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
      .watch();

  Future<List<ConsejoLocal>> pendingRecords() => (select(localConsejos)
        ..where((row) => row.syncState.isIn(['pending', 'error']))
        ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
      .get();

  Future<void> markSynced(String uuid, int serverId) =>
      (update(localConsejos)..where((row) => row.uuid.equals(uuid))).write(
        LocalConsejosCompanion(
          syncState: const Value('synced'),
          serverId: Value(serverId),
          error: const Value(null),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  Future<void> markError(String uuid, String message) =>
      (update(localConsejos)..where((row) => row.uuid.equals(uuid))).write(
        LocalConsejosCompanion(
          syncState: const Value('error'),
          error: Value(message),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  Future<void> updateServerState(String uuid, Map<String, dynamic> payload) =>
      (update(localConsejos)..where((row) => row.uuid.equals(uuid))).write(
        LocalConsejosCompanion(
          payload: Value(jsonEncode(payload)),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  Future<void> addPhoto({
    required String uuid,
    required String consejoUuid,
    required String path,
    String descripcion = '',
  }) =>
      into(localFotos).insert(
        LocalFotosCompanion.insert(
          uuid: uuid,
          consejoUuid: consejoUuid,
          path: path,
          descripcion: Value(descripcion),
        ),
      );

  Future<void> removePhoto(String uuid) =>
      (delete(localFotos)..where((photo) => photo.uuid.equals(uuid))).go();

  Future<void> updatePhotoDescription(String uuid, String description) =>
      (update(localFotos)..where((photo) => photo.uuid.equals(uuid))).write(
        LocalFotosCompanion(descripcion: Value(description)),
      );

  Future<List<FotoLocal>> photosFor(String consejoUuid) => (select(localFotos)
        ..where((photo) => photo.consejoUuid.equals(consejoUuid)))
      .get();

  Future<List<FotoLocal>> pendingPhotosForSyncedRecords() async {
    final query = select(localFotos).join([
      innerJoin(
        localConsejos,
        localConsejos.uuid.equalsExp(localFotos.consejoUuid),
      ),
    ])
      ..where(localFotos.uploaded.equals(false) &
          localConsejos.serverId.isNotNull());
    return (await query.get()).map((row) => row.readTable(localFotos)).toList();
  }

  Future<void> markPhotoUploaded(String uuid) =>
      (update(localFotos)..where((photo) => photo.uuid.equals(uuid))).write(
        const LocalFotosCompanion(uploaded: Value(true), error: Value(null)),
      );

  Future<void> markPhotoError(String uuid, String message) =>
      (update(localFotos)..where((photo) => photo.uuid.equals(uuid))).write(
        LocalFotosCompanion(error: Value(message)),
      );
}
