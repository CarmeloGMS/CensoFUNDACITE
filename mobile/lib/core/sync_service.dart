import 'package:dio/dio.dart';

import 'api_client.dart';
import '../data/app_database.dart';
import 'field_data.dart';

class SyncService {
  const SyncService(this.database, this.api);

  final AppDatabase database;
  final ApiClient api;

  Future<int> syncAll() async {
    final pending = await database.pendingRecords();
    var synced = 0;
    for (var offset = 0; offset < pending.length; offset += 20) {
      final batch = pending.skip(offset).take(20).toList();
      try {
        final results = await api.syncConsejos(
          batch
              .map(
                  (record) => syncPayloadFromDraft(decodeDraft(record.payload)))
              .toList(),
        );
        await applySyncResults(database, batch, results);
        synced +=
            mapSyncResults(results).where((result) => result.succeeded).length;
      } catch (error) {
        final message = _message(error);
        for (final record in batch) {
          await database.markError(record.uuid, message);
        }
      }
    }
    await _uploadPendingPhotos();
    return synced;
  }

  Future<void> _uploadPendingPhotos() async {
    final photos = await database.pendingPhotosForSyncedRecords();
    for (final photo in photos) {
      final record = await database.getRecord(photo.consejoUuid);
      if (record?.serverId == null) continue;
      try {
        await api.uploadPhoto(photo, record!.serverId!);
        await database.markPhotoUploaded(photo.uuid);
      } catch (error) {
        await database.markPhotoError(photo.uuid, _message(error));
      }
    }
  }

  static Future<void> applySyncResults(
    AppDatabase database,
    List<ConsejoLocal> batch,
    List<dynamic> rawResults,
  ) async {
    final results = {
      for (final result in mapSyncResults(rawResults)) result.uuid: result,
    };
    for (final record in batch) {
      final result = results[record.uuid];
      if (result == null) {
        await database.markError(record.uuid,
            'El servidor no devolvió resultado para este registro.');
      } else if (result.succeeded && result.serverId != null) {
        await database.markSynced(record.uuid, result.serverId!);
        final current = await database.getRecord(record.uuid);
        if (current != null) {
          final payload = decodeDraft(current.payload)..['estado'] = 'enviado';
          await database.updateServerState(record.uuid, payload);
        }
      } else {
        await database.markError(
          record.uuid,
          result.error?.isNotEmpty == true
              ? result.error!
              : 'No se pudo sincronizar este registro.',
        );
      }
    }
  }

  static String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        return mapSyncResults([
              {'uuid': '', 'status': 'error', 'errores': data}
            ]).first.error ??
            error.message ??
            'Error de conexión';
      }
      return error.message ?? 'Error de conexión';
    }
    return error.toString();
  }
}
