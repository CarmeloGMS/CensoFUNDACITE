import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../core/app_theme.dart';
import '../core/field_data.dart';
import '../core/gps_accuracy.dart';
import '../data/app_database.dart';
import '../state/providers.dart';

const _stepTitles = [
  'Identificación',
  'Ubicación GPS',
  'Población',
  'Producción',
  'Sanidad y destino',
  'Voceros',
  'Fotos y notas',
  'Resumen',
];

class RecordEditor extends ConsumerStatefulWidget {
  const RecordEditor({super.key, this.uuid});
  final String? uuid;

  @override
  ConsumerState<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends ConsumerState<RecordEditor> {
  final _uuid = const Uuid();
  final _picker = ImagePicker();
  final _mapController = MapController();
  final _mapKey = GlobalKey();
  final _controllers = <String, TextEditingController>{};
  final _photoDescriptionControllers = <String, TextEditingController>{};
  final _photos = <FotoLocal>[];
  Map<String, dynamic> _draft = {};
  Map<String, List<Map<String, dynamic>>> _catalogos = {};
  bool _loading = true;
  bool _saving = false;
  bool _locating = false;
  bool _takingPhoto = false;
  int _step = 0;
  String _syncState = 'draft';
  Timer? _autosave;

  AppDatabase get _database => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      _catalogos = await ref.read(appControllerProvider).getCatalogos();
      if (widget.uuid != null) {
        final record = await _database.getRecord(widget.uuid!);
        if (record != null) {
          _draft = decodeDraft(record.payload);
          _syncState = record.syncState;
          _photos.addAll(await _database.photosFor(widget.uuid!));
        } else {
          _draft = newDraft(
              await ref.read(appControllerProvider).deviceIdentifier());
        }
      } else {
        _draft =
            newDraft(await ref.read(appControllerProvider).deviceIdentifier());
      }
      await _persistDraft();
    } catch (_) {
      _draft = newDraft('');
      await _persistDraft();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _autosave?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final controller in _photoDescriptionControllers.values) {
      controller.dispose();
    }
    _mapController.dispose();
    super.dispose();
  }

  TextEditingController _controller(String key, {String? initial}) =>
      _controllers.putIfAbsent(
          key,
          () => TextEditingController(
              text: initial ?? _draft[key]?.toString() ?? ''));

  void _change(String key, dynamic value) {
    setState(() {
      _draft[key] = value;
      if (_syncState == 'synced' || _syncState == 'error') {
        _syncState = 'pending';
      }
    });
    _autosave?.cancel();
    _autosave = Timer(
        const Duration(milliseconds: 400), () => unawaited(_persistDraft()));
  }

  Future<void> _persistDraft({String? state}) async {
    if (_draft['uuid'] == null) return;
    try {
      await _database.saveLocalDraft(
        _draft['uuid'].toString(),
        _draft,
        syncState: state ?? _syncState,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No se pudo guardar el borrador en este dispositivo.')),
        );
      }
    }
  }

  Future<void> _next() async {
    if (_step == 0) {
      if ((_draft['nombre'] as String? ?? '').trim().isEmpty) {
        _toast('Ingrese el nombre del consejo campesino.');
        return;
      }
      if (_draft['parroquia_id'] == null) {
        _toast('Seleccione una parroquia.');
        return;
      }
    }
    if (_step == 1 && (_draft['lat'] == null || _draft['lng'] == null)) {
      _toast('Capture o ajuste la ubicación GPS para continuar.');
      return;
    }
    if (_step == _stepTitles.length - 1) {
      await _save();
      return;
    }
    await _persistDraft();
    setState(() => _step += 1);
  }

  Future<void> _save() async {
    if ((_draft['nombre'] as String? ?? '').trim().isEmpty ||
        _draft['parroquia_id'] == null ||
        _draft['lat'] == null ||
        _draft['lng'] == null) {
      _toast('Complete nombre, parroquia y ubicación GPS.');
      setState(() => _step = _draft['nombre'] == ''
          ? 0
          : _draft['parroquia_id'] == null
              ? 0
              : 1);
      return;
    }
    setState(() => _saving = true);
    try {
      _syncState = 'pending';
      await _persistDraft(state: 'pending');
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro guardado para sincronizar.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _captureLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _toast('Active la ubicación del teléfono para capturar las coordenadas.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _toast('Se necesita permiso de ubicación para registrar el consejo.');
      return;
    }

    setState(() => _locating = true);
    Position? best;
    final stopwatch = Stopwatch()..start();
    try {
      while (stopwatch.elapsed < const Duration(seconds: 9)) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: AndroidSettings(
              accuracy: LocationAccuracy.best,
              timeLimit: Duration(seconds: 4),
              forceLocationManager: true,
            ),
          );
          if (best == null || position.accuracy < best.accuracy) {
            best = position;
            _setLocation(
              position.latitude,
              position.longitude,
              position.accuracy,
              position.altitude,
              centerMap: true,
            );
          }
        } catch (_) {
          if (best == null) rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }
      if (best == null) {
        throw Exception('No se obtuvo una lectura GPS. Intente de nuevo.');
      }
      _toast(
          'Ubicación capturada con precisión de ${best.accuracy.toStringAsFixed(1)} m.');
    } catch (error) {
      _toast(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _setLocation(
    double latitude,
    double longitude,
    double? accuracy,
    double? altitude, {
    bool centerMap = false,
  }) {
    _draft['lat'] = latitude;
    _draft['lng'] = longitude;
    _draft['precision_gps_m'] = accuracy;
    _draft['altitud_m'] = altitude;
    _autosave?.cancel();
    _autosave = Timer(
        const Duration(milliseconds: 250), () => unawaited(_persistDraft()));
    if (centerMap) {
      try {
        _mapController.move(LatLng(latitude, longitude), 15);
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  void _adjustLocation(TapPosition _, LatLng point) {
    _draft['location_adjusted'] = true;
    _setLocation(
        point.latitude, point.longitude, null, _draft['altitud_m'] as double?);
    _toast('Ubicación ajustada en el mapa.');
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      setState(() => _takingPhoto = true);
      final selected = await _picker.pickImage(
          source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 82);
      if (selected == null) return;
      final directory = await getApplicationDocumentsDirectory();
      final photoDirectory = Directory('${directory.path}/fotos');
      await photoDirectory.create(recursive: true);
      final photoId = _uuid.v4();
      final destination = '${photoDirectory.path}/$photoId.jpg';
      await File(selected.path).copy(destination);
      final recordUuid = _draft['uuid'].toString();
      await _database.addPhoto(
        uuid: photoId,
        consejoUuid: recordUuid,
        path: destination,
      );
      final photo = (await _database.photosFor(recordUuid))
          .firstWhere((item) => item.uuid == photoId);
      if (mounted) setState(() => _photos.add(photo));
      await _persistDraft();
    } catch (error) {
      _toast('No se pudo guardar la fotografía: $error');
    } finally {
      if (mounted) setState(() => _takingPhoto = false);
    }
  }

  Future<void> _removePhoto(FotoLocal photo) async {
    await _database.removePhoto(photo.uuid);
    _photoDescriptionControllers.remove(photo.uuid)?.dispose();
    try {
      await File(photo.path).delete();
    } catch (_) {}
    if (mounted) {
      setState(() => _photos.removeWhere((item) => item.uuid == photo.uuid));
    }
  }

  Future<void> _editVocero([int? index]) async {
    final current = index == null
        ? <String, dynamic>{
            'nombre': '',
            'cedula': '',
            'telefono': '',
            'cargo': '',
            'es_principal': false
          }
        : Map<String, dynamic>.from((_draft['voceros'] as List)[index] as Map);
    final saved = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _VoceroEditorDialog(
        initial: current,
        isEditing: index != null,
      ),
    );
    if (saved == null || !mounted) return;
    final speakers = List<Map<String, dynamic>>.from(
      (_draft['voceros'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map)),
    );
    if (saved['es_principal'] == true) {
      for (final speaker in speakers) {
        speaker['es_principal'] = false;
      }
    }
    if (index == null) {
      speakers.add(saved);
    } else {
      speakers[index] = saved;
    }
    _change('voceros', speakers);
  }

  Future<void> _removeVocero(int index) async {
    final speakers = List<Map<String, dynamic>>.from(
      (_draft['voceros'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map)),
    )..removeAt(index);
    _change('voceros', speakers);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo registro'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            unawaited(_persistDraft());
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Guardar borrador',
            onPressed: () async {
              await _persistDraft();
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _ProgressHeader(step: _step, title: _stepTitles[_step]),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _identificationStep(),
                _locationStep(),
                _populationStep(),
                _productionStep(),
                _healthStep(),
                _speakersStep(),
                _photosStep(),
                _summaryStep(),
              ],
            ),
          ),
          _StepActions(
            index: _step,
            count: _stepTitles.length,
            saving: _saving,
            onBack: _step == 0 ? null : () => setState(() => _step -= 1),
            onNext: _next,
          ),
        ],
      ),
    );
  }

  Widget _identificationStep() {
    final parroquias = _catalogos['parroquias'] ?? [];
    return _StepBody(
      children: [
        const _StepIntro(
            title: '¿A quién estamos registrando?',
            subtitle: 'Complete los datos básicos del consejo campesino.'),
        _textField('nombre', 'Nombre del consejo *',
            hint: 'Ej. Consejo Campesino La Esperanza'),
        _textField('rif', 'RIF', hint: 'J-12345678-9'),
        _textField('codigo_registro', 'Código de registro'),
        DropdownButtonFormField<int>(
          initialValue: _draft['parroquia_id'] as int?,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'Parroquia *',
              prefixIcon: Icon(Icons.location_city_outlined)),
          items: parroquias.map((item) {
            final id = (item['id'] as num).toInt();
            return DropdownMenuItem(
                value: id, child: Text(item['nombre'].toString()));
          }).toList(),
          onChanged: (id) {
            _change('parroquia_id', id);
            _change('parroquia_nombre',
                parroquias.firstWhere((item) => item['id'] == id)['nombre']);
          },
        ),
        _textField('sector', 'Sector', hint: 'Nombre del sector o caserío'),
        _textField('direccion', 'Dirección / referencia', lines: 2),
        _dateField(),
      ],
    );
  }

  Widget _locationStep() {
    final latitude = (_draft['lat'] as num?)?.toDouble();
    final longitude = (_draft['lng'] as num?)?.toDouble();
    final point = latitude != null && longitude != null
        ? LatLng(latitude, longitude)
        : const LatLng(10.6, -66.93);
    final accuracy = (_draft['precision_gps_m'] as num?)?.toDouble();
    final accuracyClass = classifyGpsAccuracy(accuracy);
    final (color, label) = switch (accuracyClass) {
      GpsAccuracyClass.precise => (const Color(0xFF059669), 'Buena precisión'),
      GpsAccuracyClass.fair => (amber, 'Precisión aceptable'),
      GpsAccuracyClass.poor => (const Color(0xFFE11D48), 'Precisión baja'),
    };
    return _StepBody(
      children: [
        const _StepIntro(
            title: 'Ubicación del consejo',
            subtitle:
                'Capture el punto exacto o ajústelo manualmente en el mapa.'),
        SizedBox(
          height: 53,
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('capture_gps_button'),
            onPressed: _locating ? null : _captureLocation,
            icon: _locating
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.my_location_rounded),
            label: Text(
              _locating
                  ? 'Buscando mejor señal GPS…'
                  : latitude == null
                      ? 'Capturar ubicación GPS'
                      : 'Mejorar precisión',
            ),
          ),
        ),
        if (_locating)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
                'Mantenga el teléfono descubierto mientras se obtiene la mejor lectura.',
                style: TextStyle(color: mutedText, fontSize: 12)),
          ),
        if (latitude != null && longitude != null) ...[
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.gps_fixed_rounded, color: color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(label,
                              style: TextStyle(
                                  color: color, fontWeight: FontWeight.w700))),
                      if (accuracy != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('±${accuracy.toStringAsFixed(1)} m',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        )
                      else
                        const Text('Manual',
                            style: TextStyle(
                                color: amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(
                          child: _Coordinate(
                              label: 'Latitud',
                              value: latitude.toStringAsFixed(6))),
                      Expanded(
                          child: _Coordinate(
                              label: 'Longitud',
                              value: longitude.toStringAsFixed(6))),
                      Expanded(
                          child: _Coordinate(
                              label: 'Altitud',
                              value:
                                  '${(_draft['altitud_m'] ?? 0).toStringAsFixed(0)} m')),
                    ],
                  ),
                  if (accuracy != null && accuracy > 30) ...[
                    const SizedBox(height: 10),
                    const Text(
                        'Acérquese a un espacio abierto y vuelva a capturar para mejorar la precisión.',
                        style:
                            TextStyle(color: Color(0xFFE11D48), fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 13),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            key: _mapKey,
            height: 270,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: point,
                initialZoom: latitude == null ? 10 : 15,
                onTap: _adjustLocation,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 've.laguaira.censocampesino',
                ),
                if (latitude != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 42,
                        height: 48,
                        child: Draggable<String>(
                          data: 'map-pin',
                          feedback: const Icon(Icons.location_on_rounded,
                              color: Color(0xFFE11D48), size: 48),
                          onDragEnd: (details) {
                            final renderObject =
                                _mapKey.currentContext?.findRenderObject();
                            if (renderObject is! RenderBox) return;
                            final localPosition =
                                renderObject.globalToLocal(details.offset);
                            if (!Rect.fromLTWH(0, 0, renderObject.size.width,
                                    renderObject.size.height)
                                .contains(localPosition)) {
                              return;
                            }
                            final adjusted = _mapController.camera
                                .screenOffsetToLatLng(localPosition);
                            _draft['location_adjusted'] = true;
                            _setLocation(
                                adjusted.latitude,
                                adjusted.longitude,
                                null,
                                (_draft['altitud_m'] as num?)?.toDouble());
                          },
                          child: const Icon(Icons.location_on_rounded,
                              color: Color(0xFFE11D48), size: 42),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
              'Toque el mapa para ajustar el punto. El ajuste manual se guarda con precisión GPS vacía.',
              style: TextStyle(color: mutedText, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _populationStep() => _StepBody(
        children: [
          const _StepIntro(
              title: '¿Cuántas personas participan?',
              subtitle:
                  'Ingrese las cantidades conocidas; puede actualizarlas más adelante.'),
          for (final (key, label, icon) in [
            ('num_familias', 'Familias', Icons.home_work_outlined),
            ('num_hombres', 'Hombres', Icons.man_rounded),
            ('num_mujeres', 'Mujeres', Icons.woman_rounded),
            ('num_jovenes', 'Jóvenes', Icons.groups_2_outlined),
          ])
            _CountField(
              key: ValueKey(key),
              label: label,
              icon: icon,
              value: (_draft[key] as num?)?.toInt() ?? 0,
              onChanged: (value) => _change(key, value),
            ),
        ],
      );

  Widget _productionStep() {
    final tenencias = _catalogos['tenencia_tierra'] ?? [];
    final fuentes = _catalogos['fuente_agua'] ?? [];
    final rubros = _catalogos['rubros'] ?? [];
    final selectedRubros = (_draft['rubro_ids'] as List? ?? const [])
        .map((id) => (id as num).toInt())
        .toSet();
    return _StepBody(
      children: [
        const _StepIntro(
            title: 'Producción y recursos',
            subtitle:
                'Describa la actividad agrícola y los recursos disponibles.'),
        _textField('superficie_ha', 'Superficie (hectáreas)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            hint: '0,00'),
        _catalogDropdown('tenencia_tierra', 'Tenencia de la tierra', tenencias),
        _catalogDropdown('fuente_agua', 'Fuente de agua', fuentes),
        Card(
          child: SwitchListTile(
            value: _draft['tiene_riego'] == true,
            title: const Text('Cuenta con sistema de riego',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Indique si tienen riego instalado',
                style: TextStyle(color: mutedText, fontSize: 12)),
            onChanged: (value) => _change('tiene_riego', value),
            secondary: const Icon(Icons.water_drop_outlined, color: brandGreen),
          ),
        ),
        const SizedBox(height: 7),
        _multiChips('tipos_cultivo', 'Tipo de cultivo'),
        const Text('Rubros que producen',
            style: TextStyle(color: darkGreen, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Wrap(
          spacing: 7,
          runSpacing: 1,
          children: rubros.map((rubro) {
            final id = (rubro['id'] as num).toInt();
            final selected = selectedRubros.contains(id);
            return FilterChip(
              label: Text(rubro['nombre'].toString()),
              selected: selected,
              onSelected: (value) {
                final ids = Set<int>.from(selectedRubros);
                value ? ids.add(id) : ids.remove(id);
                _change('rubro_ids', ids.toList());
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _multiOptions(String field) {
    final cached = _catalogos[field];
    return cached == null || cached.isEmpty
        ? defaultMultiOptions[field] ?? const []
        : cached;
  }

  Widget _multiChips(String field, String title) {
    final selected =
        (_draft[field] as List? ?? const []).map((v) => v.toString()).toSet();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: darkGreen, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Wrap(
            spacing: 7,
            runSpacing: 1,
            children: _multiOptions(field).map((option) {
              final value = option['value'].toString();
              return FilterChip(
                label: Text(option['label'].toString()),
                selected: selected.contains(value),
                onSelected: (on) {
                  final values = Set<String>.from(selected);
                  on ? values.add(value) : values.remove(value);
                  _change(field, values.toList());
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _healthStep() => _StepBody(
        children: [
          const _StepIntro(
              title: 'Sanidad, destino y animales',
              subtitle:
                  'Marque las enfermedades y plagas presentes, a dónde va la producción y la cría de animales.'),
          _multiChips('enfermedades', 'Enfermedades en la cosecha'),
          _multiChips('plagas', 'Plagas'),
          _multiChips('destino_produccion', 'Destino de la producción'),
          _multiChips('produccion_animal', 'Producción animal'),
        ],
      );

  Widget _speakersStep() {
    final speakers = (_draft['voceros'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    return _StepBody(
      children: [
        _StepIntro(
            title: 'Voceros del consejo',
            subtitle:
                '${speakers.length} vocero${speakers.length == 1 ? '' : 's'} agregado${speakers.length == 1 ? '' : 's'}'),
        for (var index = 0; index < speakers.length; index++)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: mintGreen.withValues(alpha: 0.13),
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: brandGreen, fontWeight: FontWeight.w700)),
              ),
              title: Text(speakers[index]['nombre']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                [
                  speakers[index]['cargo'],
                  speakers[index]['cedula'],
                  speakers[index]['telefono'],
                  if (speakers[index]['es_principal'] == true) 'Principal',
                ]
                    .where(
                        (value) => value != null && value.toString().isNotEmpty)
                    .join(' · '),
                maxLines: 2,
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') _editVocero(index);
                  if (action == 'remove') _removeVocero(index);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'remove', child: Text('Eliminar')),
                ],
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _editVocero(),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Agregar vocero'),
          style:
              OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
      ],
    );
  }

  Widget _photosStep() => _StepBody(
        children: [
          const _StepIntro(
              title: 'Fotos y notas',
              subtitle:
                  'Agregue evidencias y anote las necesidades del consejo.'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _takingPhoto ? null : () => _addPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Cámara'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _takingPhoto
                      ? null
                      : () => _addPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                ),
              ),
            ],
          ),
          if (_takingPhoto) const LinearProgressIndicator(),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final photo in _photos)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(photo.path),
                            width: 76, height: 76, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          key: ValueKey(photo.uuid),
                          controller: _photoDescriptionControllers.putIfAbsent(
                            photo.uuid,
                            () =>
                                TextEditingController(text: photo.descripcion),
                          ),
                          onChanged: (value) => unawaited(_database
                              .updatePhotoDescription(photo.uuid, value)),
                          decoration:
                              const InputDecoration(hintText: 'Descripción'),
                        ),
                      ),
                      IconButton(
                          onPressed: () => _removePhoto(photo),
                          icon: const Icon(Icons.delete_outline,
                              color: Color(0xFFE11D48))),
                    ],
                  ),
                ),
              ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Center(
                  child: Text('Todavía no hay fotografías',
                      style: TextStyle(color: mutedText, fontSize: 13))),
            ),
          _textField('requerimientos', 'Requerimientos - otros',
              lines: 3, hint: 'Insumos, maquinaria, financiamiento…'),
          _textField('necesidades', 'Necesidades principales',
              lines: 3, hint: 'Agua, herramientas, semillas…'),
          _textField('observaciones', 'Observaciones', lines: 3),
        ],
      );

  String _labelsFor(String field) {
    final values =
        (_draft[field] as List? ?? const []).map((v) => v.toString());
    final labels = _multiOptions(field)
        .where((o) => values.contains(o['value']))
        .map((o) => o['label'].toString())
        .join(', ');
    return labels.isEmpty ? 'Ninguno' : labels;
  }

  Widget _summaryStep() {
    final selectedParroquia = (_catalogos['parroquias'] ?? [])
        .where((item) => item['id'] == _draft['parroquia_id'])
        .toList();
    final parroquia = _draft['parroquia_nombre']?.toString() ??
        (selectedParroquia.isEmpty
            ? '—'
            : selectedParroquia.first['nombre'].toString());
    final speakers = (_draft['voceros'] as List? ?? const []).length;
    final rubroNames = (_catalogos['rubros'] ?? [])
        .where((item) =>
            (_draft['rubro_ids'] as List? ?? const []).contains(item['id']))
        .map((item) => item['nombre'].toString())
        .join(', ');
    return _StepBody(
      children: [
        const _StepIntro(
            title: 'Todo listo para guardar',
            subtitle:
                'Revise el resumen. El registro quedará guardado en este teléfono.'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryGroup(
                  icon: Icons.agriculture_outlined,
                  title: 'Identificación',
                  values: {
                    'Consejo': _draft['nombre']?.toString() ?? '',
                    'Parroquia': parroquia,
                    if ((_draft['sector'] as String? ?? '').isNotEmpty)
                      'Sector': _draft['sector'].toString(),
                    if ((_draft['rif'] as String? ?? '').isNotEmpty)
                      'RIF': _draft['rif'].toString(),
                  },
                ),
                _SummaryGroup(
                  icon: Icons.location_on_outlined,
                  title: 'Ubicación',
                  values: {
                    'Coordenadas':
                        '${_draft['lat'] ?? '—'}, ${_draft['lng'] ?? '—'}',
                    'Precisión': _draft['precision_gps_m'] == null
                        ? 'Ajuste manual'
                        : '${(_draft['precision_gps_m'] as num).toStringAsFixed(1)} m',
                  },
                ),
                _SummaryGroup(
                  icon: Icons.groups_outlined,
                  title: 'Población y producción',
                  values: {
                    'Familias': '${_draft['num_familias'] ?? 0}',
                    'Voceros': '$speakers',
                    'Rubros':
                        rubroNames.isEmpty ? 'Sin seleccionar' : rubroNames,
                  },
                ),
                _SummaryGroup(
                  icon: Icons.bug_report_outlined,
                  title: 'Sanidad y destino',
                  values: {
                    'Enfermedades': _labelsFor('enfermedades'),
                    'Plagas': _labelsFor('plagas'),
                    'Destino': _labelsFor('destino_produccion'),
                    'Cultivo': _labelsFor('tipos_cultivo'),
                    'Animales': _labelsFor('produccion_animal'),
                    'Requerimientos':
                        (_draft['requerimientos'] as String? ?? '')
                                .trim()
                                .isEmpty
                            ? 'Sin indicar'
                            : (_draft['requerimientos'] as String).trim(),
                  },
                ),
                _SummaryGroup(
                  icon: Icons.photo_camera_back_outlined,
                  title: 'Evidencias',
                  values: {'Fotografías': '${_photos.length}'},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: mintGreen.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16)),
          child: const Row(
            children: [
              Icon(Icons.offline_pin_rounded, color: brandGreen),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                      'Puede cerrar la aplicación; sus datos quedarán guardados y se enviarán cuando haya conexión.',
                      style: TextStyle(
                          color: darkGreen, fontSize: 13, height: 1.4))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _textField(
    String key,
    String label, {
    String? hint,
    int lines = 1,
    TextInputType? keyboardType,
  }) {
    final controller = _controller(key);
    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      keyboardType: keyboardType ??
          (lines > 1 ? TextInputType.multiline : TextInputType.text),
      textCapitalization: TextCapitalization.sentences,
      onChanged: (value) => _change(key, value),
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _catalogDropdown(
      String field, String label, List<Map<String, dynamic>> items) {
    final current = _draft[field]?.toString();
    final valid = items.any((item) => item['value'] == current);
    return DropdownButtonFormField<String>(
      initialValue: valid ? current : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item['value'].toString(),
                child: Text(item['label'].toString()),
              ))
          .toList(),
      onChanged: (value) => _change(field, value ?? ''),
    );
  }

  Widget _dateField() {
    final value = _draft['fecha_constitucion']?.toString();
    return InkWell(
      onTap: () async {
        final initial = value == null
            ? DateTime.now()
            : DateTime.tryParse(value) ?? DateTime.now();
        final selected = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          locale: const Locale('es', 'VE'),
        );
        if (selected != null) {
          _change('fecha_constitucion',
              '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}');
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
            labelText: 'Fecha de constitución',
            prefixIcon: Icon(Icons.event_outlined)),
        child: Text(value ?? 'Seleccionar fecha',
            style: TextStyle(color: value == null ? mutedText : darkGreen)),
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final child in children) ...[
              child,
              if (child is! _StepIntro) const SizedBox(height: 13),
            ],
          ],
        ),
      );
}

class _StepIntro extends StatelessWidget {
  const _StepIntro({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: darkGreen)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(color: mutedText, fontSize: 13)),
          ],
        ),
      );
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step, required this.title});
  final int step;
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('PASO ${step + 1} DE ${_stepTitles.length}',
                        style: const TextStyle(
                            color: mutedText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2))),
                Text('${((step + 1) / _stepTitles.length * 100).round()}%',
                    style: const TextStyle(
                        color: brandGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: (step + 1) / _stepTitles.length,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFE4E9E5)),
            ),
            const SizedBox(height: 5),
            Text(title,
                style: const TextStyle(
                    color: brandGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      );
}

class _StepActions extends StatelessWidget {
  const _StepActions(
      {required this.index,
      required this.count,
      required this.saving,
      required this.onBack,
      required this.onNext});
  final int index;
  final int count;
  final bool saving;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 11, 20, 12),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE9ECE9)))),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              if (onBack != null)
                OutlinedButton(
                  onPressed: onBack,
                  style:
                      OutlinedButton.styleFrom(minimumSize: const Size(52, 49)),
                  child: const Icon(Icons.arrow_back_rounded),
                )
              else
                const SizedBox(width: 52),
              const SizedBox(width: 11),
              Expanded(
                child: FilledButton(
                  onPressed: saving ? null : onNext,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                  child: saving
                      ? const SizedBox(
                          height: 21,
                          width: 21,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(index == count - 1
                                ? 'Guardar registro'
                                : 'Continuar'),
                            const SizedBox(width: 8),
                            Icon(
                                index == count - 1
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 19),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _CountField extends StatelessWidget {
  const _CountField(
      {super.key,
      required this.label,
      required this.icon,
      required this.value,
      required this.onChanged});
  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: brandGreen),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              IconButton.filledTonal(
                onPressed: value <= 0 ? null : () => onChanged(value - 1),
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 48,
                child: Text('$value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              IconButton.filledTonal(
                  onPressed: () => onChanged(value + 1),
                  icon: const Icon(Icons.add_rounded)),
            ],
          ),
        ),
      );
}

class _Coordinate extends StatelessWidget {
  const _Coordinate({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: mutedText, fontSize: 10)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: darkGreen, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      );
}

class _SummaryGroup extends StatelessWidget {
  const _SummaryGroup(
      {required this.icon, required this.title, required this.values});
  final IconData icon;
  final String title;
  final Map<String, String> values;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: brandGreen, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        color: brandGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 7),
            for (final entry in values.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 105,
                        child: Text(entry.key,
                            style: const TextStyle(
                                color: mutedText, fontSize: 11))),
                    Expanded(
                        child: Text(entry.value,
                            style: const TextStyle(
                                color: darkGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            const Divider(height: 18),
          ],
        ),
      );
}

class _VoceroEditorDialog extends StatefulWidget {
  const _VoceroEditorDialog({
    required this.initial,
    required this.isEditing,
  });

  final Map<String, dynamic> initial;
  final bool isEditing;

  @override
  State<_VoceroEditorDialog> createState() => _VoceroEditorDialogState();
}

class _VoceroEditorDialogState extends State<_VoceroEditorDialog> {
  late final Map<String, TextEditingController> _controllers;
  late bool _principal;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final key in ['nombre', 'cedula', 'telefono', 'cargo'])
        key: TextEditingController(text: widget.initial[key]?.toString() ?? ''),
    };
    _principal = widget.initial['es_principal'] == true;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.isEditing ? 'Editar vocero' : 'Agregar vocero'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in [
                ('nombre', 'Nombre y apellido'),
                ('cedula', 'Cédula'),
                ('telefono', 'Teléfono'),
                ('cargo', 'Cargo'),
              ]) ...[
                TextField(
                  controller: _controllers[entry.$1],
                  decoration: InputDecoration(labelText: entry.$2),
                ),
                const SizedBox(height: 10),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vocero principal'),
                value: _principal,
                onChanged: (value) => setState(() => _principal = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (_controllers['nombre']!.text.trim().isEmpty) return;
              Navigator.pop<Map<String, dynamic>>(context, {
                for (final key in _controllers.keys)
                  key: _controllers[key]!.text.trim(),
                'es_principal': _principal,
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      );
}
