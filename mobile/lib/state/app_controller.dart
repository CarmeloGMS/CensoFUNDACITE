import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/sync_service.dart';
import '../core/token_store.dart';
import '../data/app_database.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.api,
    required this.tokens,
    required this.database,
    required this.syncService,
  });

  static const _userKey = 'cached_user';
  static const _serverKey = 'server_url';
  static const _lastSyncKey = 'last_sync_at';

  final ApiClient api;
  final TokenStore tokens;
  final AppDatabase database;
  final SyncService syncService;
  final Connectivity _connectivity = Connectivity();

  SharedPreferences? _preferences;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Map<String, dynamic>? user;
  String serverUrl = defaultServerUrl;
  DateTime? lastSync;
  String? syncError;
  bool ready = false;
  bool online = false;
  bool syncing = false;

  bool get authenticated => user != null;
  String get displayName {
    final fullName = [
      user?['first_name']?.toString() ?? '',
      user?['last_name']?.toString() ?? '',
    ].where((part) => part.isNotEmpty).join(' ');
    return fullName.isNotEmpty
        ? fullName
        : user?['username']?.toString() ?? 'Encuestador';
  }

  Future<void> restore() async {
    _preferences = await SharedPreferences.getInstance();
    serverUrl = _preferences?.getString(_serverKey) ?? defaultServerUrl;
    api.setServerUrl(serverUrl);
    final cachedUser = _preferences?.getString(_userKey);
    if (cachedUser != null) {
      user = (jsonDecode(cachedUser) as Map).cast<String, dynamic>();
    }
    final savedSync = _preferences?.getString(_lastSyncKey);
    lastSync = savedSync == null ? null : DateTime.tryParse(savedSync);

    final connectivity = await _connectivity.checkConnectivity();
    online = _isOnline(connectivity);
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = online;
      online = _isOnline(results);
      notifyListeners();
      if (online && !wasOnline && authenticated) unawaited(syncNow());
    });

    if (await tokens.access != null && online) {
      try {
        await _cacheUser(await api.me());
        await refreshCatalogos();
      } catch (_) {
        // Keep the cached account and catalogs available when the network is absent.
      }
    }
    ready = true;
    notifyListeners();
    if (online && authenticated) unawaited(syncNow());
  }

  Future<void> login({
    required String username,
    required String password,
    required String server,
  }) async {
    await setServerUrl(server);
    await api.login(username.trim(), password);
    final profile = await api.me();
    await _cacheUser(profile);
    try {
      await refreshCatalogos();
    } catch (_) {
      final cached = await database.readCatalogos();
      if (cached['parroquias']?.isNotEmpty != true ||
          cached['rubros']?.isNotEmpty != true) {
        throw Exception(
            'No se pudieron descargar los catálogos. Intente con conexión.');
      }
    }
    syncError = null;
    ready = true;
    notifyListeners();
  }

  Future<void> setServerUrl(String value) async {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (Uri.tryParse(normalized)?.hasScheme != true) {
      throw const FormatException(
          'Ingrese una dirección completa, por ejemplo http://10.0.2.2:8000.');
    }
    serverUrl = normalized;
    api.setServerUrl(normalized);
    await _preferences?.setString(_serverKey, normalized);
    notifyListeners();
  }

  Future<Map<String, List<Map<String, dynamic>>>> getCatalogos() =>
      database.readCatalogos();

  Future<void> refreshCatalogos() async {
    final data = await api.catalogos();
    await database.cacheCatalogos(data);
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (syncing || !authenticated) return;
    syncing = true;
    syncError = null;
    notifyListeners();
    try {
      await syncService.syncAll();
      lastSync = DateTime.now();
      await _preferences?.setString(_lastSyncKey, lastSync!.toIso8601String());
    } catch (error) {
      syncError = error.toString();
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<bool> hasUnsyncedRecords() async => (await database.allRecords())
      .any((record) => record.syncState != 'synced');

  Future<void> logout() async {
    await tokens.clear();
    await _preferences?.remove(_userKey);
    user = null;
    notifyListeners();
  }

  Future<void> _cacheUser(Map<String, dynamic> profile) async {
    user = profile;
    await _preferences?.setString(_userKey, jsonEncode(profile));
  }

  Future<String> deviceIdentifier() async {
    final device = await DeviceInfoPlugin().androidInfo;
    return '${device.manufacturer}-${device.model}-${device.id}';
  }

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
