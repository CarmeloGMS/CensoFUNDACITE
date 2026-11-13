import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../core/sync_service.dart';
import '../core/token_store.dart';
import '../data/app_database.dart';
import 'app_controller.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(tokenStoreProvider)),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) =>
      SyncService(ref.watch(databaseProvider), ref.watch(apiClientProvider)),
);

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  final controller = AppController(
    api: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStoreProvider),
    database: ref.watch(databaseProvider),
    syncService: ref.watch(syncServiceProvider),
  );
  controller.restore();
  return controller;
});

final recordsProvider = StreamProvider((ref) {
  return ref.watch(databaseProvider).watchRecords();
});
