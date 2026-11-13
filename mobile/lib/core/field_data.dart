import 'dart:convert';

import 'package:uuid/uuid.dart';

final _uuid = const Uuid();

Map<String, dynamic> newDraft(String deviceId) => {
      'uuid': _uuid.v4(),
      'nombre': '',
      'rif': '',
      'codigo_registro': '',
      'parroquia_id': null,
      'sector': '',
      'direccion': '',
      'lat': null,
      'lng': null,
      'precision_gps_m': null,
      'altitud_m': null,
      'fecha_constitucion': null,
      'num_familias': 0,
      'num_hombres': 0,
      'num_mujeres': 0,
      'num_jovenes': 0,
      'superficie_ha': null,
      'tenencia_tierra': '',
      'fuente_agua': '',
      'tiene_riego': false,
      'rubro_ids': <int>[],
      'necesidades': '',
      'observaciones': '',
      'dispositivo_id': deviceId,
      'fecha_captura': DateTime.now().toIso8601String(),
      'voceros': <Map<String, dynamic>>[],
    };

Map<String, dynamic> syncPayloadFromDraft(Map<String, dynamic> draft) {
  final area = draft['superficie_ha'];
  final voceros = (draft['voceros'] as List? ?? const [])
      .whereType<Map>()
      .map(
        (vocero) => {
          'nombre': vocero['nombre'] ?? '',
          'cedula': vocero['cedula'] ?? '',
          'telefono': vocero['telefono'] ?? '',
          'cargo': vocero['cargo'] ?? '',
          'es_principal': vocero['es_principal'] == true,
        },
      )
      .toList();

  return {
    'uuid': draft['uuid'],
    'nombre': draft['nombre'] ?? '',
    'rif': draft['rif'] ?? '',
    'codigo_registro': draft['codigo_registro'] ?? '',
    'parroquia_id': draft['parroquia_id'],
    'sector': draft['sector'] ?? '',
    'direccion': draft['direccion'] ?? '',
    'lat': _asDouble(draft['lat']),
    'lng': _asDouble(draft['lng']),
    'precision_gps_m': _asDouble(draft['precision_gps_m']),
    'altitud_m': _asDouble(draft['altitud_m']),
    'fecha_constitucion': draft['fecha_constitucion'],
    'num_familias': _asInt(draft['num_familias']),
    'num_hombres': _asInt(draft['num_hombres']),
    'num_mujeres': _asInt(draft['num_mujeres']),
    'num_jovenes': _asInt(draft['num_jovenes']),
    'superficie_ha': _asDouble(area),
    'tenencia_tierra': draft['tenencia_tierra'] ?? '',
    'fuente_agua': draft['fuente_agua'] ?? '',
    'tiene_riego': draft['tiene_riego'] == true,
    'rubro_ids': (draft['rubro_ids'] as List? ?? const []).map(_asInt).toList(),
    'necesidades': draft['necesidades'] ?? '',
    'observaciones': draft['observaciones'] ?? '',
    'dispositivo_id': draft['dispositivo_id'] ?? '',
    'fecha_captura': draft['fecha_captura'],
    'voceros': voceros,
  };
}

String encodeDraft(Map<String, dynamic> draft) => jsonEncode(draft);

Map<String, dynamic> decodeDraft(String value) =>
    (jsonDecode(value) as Map).cast<String, dynamic>();

double? _asDouble(dynamic value) {
  if (value == null || value == '') return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class SyncResultUpdate {
  const SyncResultUpdate({
    required this.uuid,
    required this.status,
    this.serverId,
    this.error,
  });

  final String uuid;
  final String status;
  final int? serverId;
  final String? error;

  bool get succeeded => status == 'created' || status == 'updated';
}

List<SyncResultUpdate> mapSyncResults(List<dynamic> resultados) {
  return resultados.whereType<Map>().map((raw) {
    final item = raw.cast<String, dynamic>();
    final status = item['status']?.toString() ?? 'error';
    final rawError = item['errores'];
    return SyncResultUpdate(
      uuid: item['uuid']?.toString() ?? '',
      status: status,
      serverId: item['id'] is num ? (item['id'] as num).toInt() : null,
      error: rawError == null ? null : _errorMessage(rawError),
    );
  }).toList();
}

String _errorMessage(dynamic error) {
  if (error is Map) {
    return error.entries
        .map((entry) => '${entry.key}: ${_errorMessage(entry.value)}')
        .join(' · ');
  }
  if (error is List) return error.map(_errorMessage).join(', ');
  return error.toString();
}
