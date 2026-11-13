import 'package:censo_campesino/core/app_theme.dart';
import 'package:censo_campesino/core/field_data.dart';
import 'package:censo_campesino/core/gps_accuracy.dart';
import 'package:censo_campesino/core/sync_service.dart';
import 'package:censo_campesino/data/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('app theme chips', () {
    test('uses readable colors for selected and unselected states', () {
      final chipTheme = buildAppTheme().chipTheme;

      expect(chipTheme.backgroundColor, const Color(0xFFF5F5F4));
      expect(chipTheme.labelStyle?.color, const Color(0xFF1C1917));
      expect(chipTheme.side?.color, const Color(0xFFD6D3D1));
      expect(chipTheme.selectedColor, const Color(0xFFD1FAE5));
      expect(chipTheme.secondarySelectedColor, const Color(0xFFD1FAE5));
      expect(chipTheme.secondaryLabelStyle?.color, brandGreen);
      expect(chipTheme.checkmarkColor, brandGreen);
      expect(chipTheme.showCheckmark, isTrue);
    });
  });

  group('syncPayloadFromDraft', () {
    test('maps a council draft to the exact write field names', () {
      final payload = syncPayloadFromDraft({
        'uuid': 'b3338ab5-fb0e-4e90-9707-467cdf5b1cd9',
        'nombre': 'Consejo Campesino El Guayabo',
        'rif': 'J-12345678-9',
        'codigo_registro': 'LG-101',
        'parroquia_id': 5,
        'sector': 'El Guayabo',
        'direccion': 'Vía principal',
        'lat': 10.57,
        'lng': -66.93,
        'precision_gps_m': 8.4,
        'altitud_m': 120,
        'fecha_constitucion': '2019-03-12',
        'num_familias': 18,
        'num_hombres': '20',
        'num_mujeres': 22.0,
        'num_jovenes': 9,
        'superficie_ha': '3,75',
        'tenencia_tierra': 'comunal',
        'fuente_agua': 'rio_quebrada',
        'tiene_riego': true,
        'rubro_ids': [2, '4'],
        'enfermedades': ['hongos'],
        'plagas': ['insectos', 'acaros'],
        'destino_produccion': ['consumo_familiar'],
        'tipos_cultivo': ['asociado'],
        'produccion_animal': ['avicola', 'apicultura'],
        'requerimientos': 'Abono orgánico',
        'necesidades': 'Semillas',
        'observaciones': 'Acceso por la quebrada',
        'dispositivo_id': 'google-pixel',
        'fecha_captura': '2025-02-03T12:15:00.000',
        'voceros': [
          {
            'nombre': 'María Pérez',
            'cedula': 'V-12.345.678',
            'telefono': '0414-1234567',
            'cargo': 'Productora',
            'es_principal': true,
            'local_id': 'not-sent',
          },
        ],
        'parroquia_nombre': 'La Guaira',
        'location_adjusted': true,
        'estado': 'enviado',
      });

      expect(payload.keys.toSet(), {
        'uuid',
        'nombre',
        'rif',
        'codigo_registro',
        'parroquia_id',
        'sector',
        'direccion',
        'lat',
        'lng',
        'precision_gps_m',
        'altitud_m',
        'fecha_constitucion',
        'num_familias',
        'num_hombres',
        'num_mujeres',
        'num_jovenes',
        'superficie_ha',
        'tenencia_tierra',
        'fuente_agua',
        'tiene_riego',
        'rubro_ids',
        'enfermedades',
        'plagas',
        'destino_produccion',
        'tipos_cultivo',
        'produccion_animal',
        'requerimientos',
        'necesidades',
        'observaciones',
        'dispositivo_id',
        'fecha_captura',
        'voceros',
      });
      expect(payload, {
        'uuid': 'b3338ab5-fb0e-4e90-9707-467cdf5b1cd9',
        'nombre': 'Consejo Campesino El Guayabo',
        'rif': 'J-12345678-9',
        'codigo_registro': 'LG-101',
        'parroquia_id': 5,
        'sector': 'El Guayabo',
        'direccion': 'Vía principal',
        'lat': 10.57,
        'lng': -66.93,
        'precision_gps_m': 8.4,
        'altitud_m': 120.0,
        'fecha_constitucion': '2019-03-12',
        'num_familias': 18,
        'num_hombres': 20,
        'num_mujeres': 22,
        'num_jovenes': 9,
        'superficie_ha': 3.75,
        'tenencia_tierra': 'comunal',
        'fuente_agua': 'rio_quebrada',
        'tiene_riego': true,
        'rubro_ids': [2, 4],
        'enfermedades': ['hongos'],
        'plagas': ['insectos', 'acaros'],
        'destino_produccion': ['consumo_familiar'],
        'tipos_cultivo': ['asociado'],
        'produccion_animal': ['avicola', 'apicultura'],
        'requerimientos': 'Abono orgánico',
        'necesidades': 'Semillas',
        'observaciones': 'Acceso por la quebrada',
        'dispositivo_id': 'google-pixel',
        'fecha_captura': '2025-02-03T12:15:00.000',
        'voceros': [
          {
            'nombre': 'María Pérez',
            'cedula': 'V-12.345.678',
            'telefono': '0414-1234567',
            'cargo': 'Productora',
            'es_principal': true,
          },
        ],
      });
    });
  });

  group('applySyncResults', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('stores created, updated, and per-record error outcomes locally',
        () async {
      final drafts = [
        ('created-uuid', 'created'),
        ('updated-uuid', 'updated'),
        ('error-uuid', 'error'),
      ];
      for (final (uuid, _) in drafts) {
        await database.saveLocalDraft(
          uuid,
          {'uuid': uuid, 'nombre': uuid},
          syncState: 'pending',
        );
      }
      final records = await database.allRecords();

      await SyncService.applySyncResults(database, records, [
        {'uuid': 'created-uuid', 'id': 101, 'status': 'created'},
        {'uuid': 'updated-uuid', 'id': 102, 'status': 'updated'},
        {
          'uuid': 'error-uuid',
          'id': null,
          'status': 'error',
          'errores': {
            'nombre': ['Este campo es requerido.']
          },
        },
      ]);

      final created = await database.getRecord('created-uuid');
      final updated = await database.getRecord('updated-uuid');
      final error = await database.getRecord('error-uuid');
      expect(created?.syncState, 'synced');
      expect(created?.serverId, 101);
      expect(decodeDraft(created!.payload)['estado'], 'enviado');
      expect(updated?.syncState, 'synced');
      expect(updated?.serverId, 102);
      expect(error?.syncState, 'error');
      expect(error?.serverId, isNull);
      expect(error?.error, contains('Este campo es requerido.'));
      expect(decodeDraft(error!.payload)['nombre'], 'error-uuid');
    });
  });

  group('classifyGpsAccuracy', () {
    test('classifies the requested accuracy bands', () {
      expect(classifyGpsAccuracy(0), GpsAccuracyClass.precise);
      expect(classifyGpsAccuracy(10), GpsAccuracyClass.precise);
      expect(classifyGpsAccuracy(10.1), GpsAccuracyClass.fair);
      expect(classifyGpsAccuracy(30), GpsAccuracyClass.fair);
      expect(classifyGpsAccuracy(30.1), GpsAccuracyClass.poor);
      expect(classifyGpsAccuracy(null), GpsAccuracyClass.poor);
      expect(classifyGpsAccuracy(double.nan), GpsAccuracyClass.poor);
    });
  });
}
