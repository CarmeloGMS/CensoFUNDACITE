import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../core/field_data.dart';
import '../data/app_database.dart';
import '../state/providers.dart';
import '../widgets/brand_mark.dart';
import '../widgets/record_badge.dart';
import 'record_editor.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _tab = 0;

  void _newRecord([String? uuid]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RecordEditor(uuid: uuid)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
          onNewRecord: _newRecord,
          onShowRecords: () => setState(() => _tab = 1)),
      RecordsScreen(onOpen: (uuid) => _openRecord(uuid)),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Mis registros'),
          NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Ajustes'),
        ],
      ),
    );
  }

  void _openRecord(String uuid) async {
    final record = await ref.read(databaseProvider).getRecord(uuid);
    if (!mounted || record == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecordDetailScreen(
          record: record,
          onEdit: () => _newRecord(uuid),
        ),
      ),
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen(
      {super.key, required this.onNewRecord, required this.onShowRecords});

  final ValueChanged<String?> onNewRecord;
  final VoidCallback onShowRecords;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final recordsState = ref.watch(recordsProvider);
    final records = recordsState.valueOrNull ?? const <ConsejoLocal>[];
    final pending =
        records.where((record) => record.syncState == 'pending').length;
    final errors =
        records.where((record) => record.syncState == 'error').length;
    final synced =
        records.where((record) => record.syncState == 'synced').length;
    final recent = records.take(4).toList();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 18
            ? 'Buenas tardes'
            : 'Buenas noches';

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DashboardHeader(
              greeting: greeting,
              name: app.displayName.split(' ').first,
              online: app.online,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _MetricCard(
                            value: '$pending',
                            label: 'Pendientes',
                            color: amber,
                            icon: Icons.cloud_upload_outlined)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _MetricCard(
                            value: '$synced',
                            label: 'Enviados',
                            color: midGreen,
                            icon: Icons.cloud_done_outlined)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _MetricCard(
                            value: '$errors',
                            label: 'Con error',
                            color: const Color(0xFFE11D48),
                            icon: Icons.error_outline_rounded)),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    key: const ValueKey('new_record_button'),
                    onPressed: () => onNewRecord(null),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Nuevo registro',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: brandGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17)),
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  height: 51,
                  child: OutlinedButton.icon(
                    key: const ValueKey('sync_now_button'),
                    onPressed: app.syncing ? null : app.syncNow,
                    icon: app.syncing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync_rounded),
                    label: Text(
                        app.syncing ? 'Sincronizando…' : 'Sincronizar ahora'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: brandGreen,
                      side:
                          BorderSide(color: brandGreen.withValues(alpha: 0.24)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: mutedText.withValues(alpha: 0.8)),
                    const SizedBox(width: 7),
                    Text(
                      app.lastSync == null
                          ? 'Aún no ha sincronizado'
                          : 'Última sincronización · ${DateFormat('d MMM, HH:mm', 'es').format(app.lastSync!)}',
                      style: const TextStyle(color: mutedText, fontSize: 12),
                    ),
                  ],
                ),
                if (app.syncError != null) ...[
                  const SizedBox(height: 9),
                  Text(app.syncError!,
                      style: const TextStyle(
                          color: Color(0xFFE11D48), fontSize: 12)),
                ],
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text('Registros recientes',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    TextButton(
                        onPressed: onShowRecords,
                        child: const Text('Ver todos')),
                  ],
                ),
                const SizedBox(height: 5),
                if (recordsState.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (recent.isEmpty)
                  const _EmptyCard(
                    icon: Icons.agriculture_outlined,
                    title: 'Su jornada empieza aquí',
                    message:
                        'Cree un registro para comenzar el censo de su comunidad.',
                  )
                else
                  ...recent.map((record) => _RecordTile(
                        record: record,
                        onTap: () => onNewRecord(record.uuid),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader(
      {required this.greeting, required this.name, required this.online});

  final String greeting;
  final String name;
  final bool online;

  @override
  Widget build(BuildContext context) => Container(
        height: 218,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [darkGreen, brandGreen, midGreen],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              top: -74,
              right: -34,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      mintGreen.withValues(alpha: 0.24),
                      mintGreen.withValues(alpha: 0)
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 17, 22, 21),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const BrandMark(size: 42, light: true),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'CENSO CAMPESINO',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.3),
                          ),
                        ),
                        _ConnectivityPill(online: online),
                      ],
                    ),
                    const Spacer(),
                    Text(greeting,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 29,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Estado La Guaira · Municipio Vargas',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.77),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _ConnectivityPill extends StatelessWidget {
  const _ConnectivityPill({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(Icons.circle,
                size: 8,
                color:
                    online ? const Color(0xFF6EE7B7) : const Color(0xFFFCD34D)),
            const SizedBox(width: 7),
            Text(online ? 'En línea' : 'Sin conexión',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.value,
      required this.label,
      required this.color,
      required this.icon});
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 14, 10, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(height: 11),
              Text(value,
                  style: TextStyle(
                      color: darkGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: mutedText, fontSize: 10.5)),
            ],
          ),
        ),
      );
}

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key, required this.onOpen});
  final ValueChanged<String> onOpen;

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  final _search = TextEditingController();
  String _filter = 'Todos';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordsProvider);
    final records = state.valueOrNull ?? const <ConsejoLocal>[];
    final query = _search.text.trim().toLowerCase();
    final visible = records.where((record) {
      if (query.isNotEmpty &&
          !decodeDraft(record.payload)['nombre']
              .toString()
              .toLowerCase()
              .contains(query)) {
        return false;
      }
      return switch (_filter) {
        'Pendientes' => record.syncState == 'pending',
        'Enviados' => record.syncState == 'synced',
        'Errores' => record.syncState == 'error',
        _ => true,
      };
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 17, 20, 7),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mis registros',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 3),
                      const Text('Todos sus levantamientos de campo',
                          style: TextStyle(color: mutedText, fontSize: 13)),
                    ],
                  ),
                ),
                Text(
                  '${records.length} total',
                  style: const TextStyle(
                      color: mutedText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close_rounded)),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final filter in [
                  'Todos',
                  'Pendientes',
                  'Enviados',
                  'Errores'
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                    ? const _EmptyCard(
                        icon: Icons.search_off_rounded,
                        title: 'No hay registros',
                        message: 'Los registros que capture aparecerán aquí.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 9, 20, 24),
                        itemCount: visible.length,
                        itemBuilder: (context, index) => _RecordTile(
                          record: visible[index],
                          onTap: () => widget.onOpen(visible[index].uuid),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _server;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _server =
        TextEditingController(text: ref.read(appControllerProvider).serverUrl);
  }

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final app = ref.read(appControllerProvider);
    if (await app.hasUnsyncedRecords() && mounted) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hay registros sin enviar'),
          content: const Text(
              'Los datos permanecen en este teléfono, pero deberá iniciar sesión de nuevo para sincronizarlos. ¿Desea continuar?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cerrar sesión')),
          ],
        ),
      );
      if (leave != true) return;
    }
    await app.logout();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 17, 20, 26),
        children: [
          Text('Ajustes y perfil',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          const Text('Su cuenta y configuración de campo',
              style: TextStyle(color: mutedText, fontSize: 13)),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(17),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                        color: mintGreen.withValues(alpha: 0.13),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded,
                        color: brandGreen, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.displayName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: darkGreen)),
                        const SizedBox(height: 4),
                        Text(
                            '@${app.user?['username'] ?? ''} · ${app.user?['rol'] ?? 'encuestador'}',
                            style: const TextStyle(
                                color: mutedText, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_user_outlined,
                      color: brandGreen, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _SectionLabel(title: 'Servidor'),
          const SizedBox(height: 9),
          TextField(
              controller: _server,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: 'URL del servidor',
                  prefixIcon: Icon(Icons.dns_outlined))),
          const SizedBox(height: 9),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () async {
                      setState(() => _saving = true);
                      try {
                        await app.setServerUrl(_server.text);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Servidor guardado')));
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())));
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar servidor'),
            ),
          ),
          const SizedBox(height: 22),
          _SectionLabel(title: 'Datos sin conexión'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.menu_book_outlined, color: brandGreen),
                  title: const Text('Catálogos'),
                  subtitle: Text(app.online
                      ? 'Actualizar parroquias y rubros'
                      : 'Usando los catálogos guardados'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: app.online
                      ? () async {
                          try {
                            await app.refreshCatalogos();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Catálogos actualizados')));
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'No se pudieron actualizar los catálogos')));
                            }
                          }
                        }
                      : null,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.history_rounded, color: brandGreen),
                  title: const Text('Última sincronización'),
                  subtitle: Text(app.lastSync == null
                      ? 'Todavía no se ha sincronizado'
                      : DateFormat('d MMMM yyyy, HH:mm', 'es')
                          .format(app.lastSync!)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SectionLabel(title: 'Sesión'),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE11D48),
                  side: const BorderSide(color: Color(0x33E11D48))),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
              child: Text('CENSO CAMPESINO · LA GUAIRA',
                  style: TextStyle(
                      color: mutedText, fontSize: 10, letterSpacing: 1))),
        ],
      ),
    );
  }
}

class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen(
      {super.key, required this.record, required this.onEdit});
  final ConsejoLocal record;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final payload = decodeDraft(record.payload);
    final locked = payload['estado'] == 'validado';
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del registro')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(payload['nombre']?.toString() ?? 'Sin nombre',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          RecordBadge(record: record),
          if (record.syncState == 'error' && record.error != null) ...[
            const SizedBox(height: 12),
            Text(record.error!,
                style: const TextStyle(color: Color(0xFFE11D48))),
          ],
          const SizedBox(height: 20),
          _DetailCard(
            rows: {
              'Parroquia': payload['parroquia_nombre']?.toString() ?? '—',
              'Sector': payload['sector']?.toString().isNotEmpty == true
                  ? payload['sector'].toString()
                  : '—',
              'Coordenadas': payload['lat'] == null
                  ? '—'
                  : '${payload['lat']}, ${payload['lng']}',
              'Familias': '${payload['num_familias'] ?? 0}',
              'Voceros': '${(payload['voceros'] as List? ?? []).length}',
              'Fecha': DateFormat('d MMM yyyy', 'es')
                  .format(DateTime.parse(payload['fecha_captura'].toString())),
            },
          ),
          const SizedBox(height: 20),
          if (!locked)
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar registro'),
              ),
            )
          else
            const Text('Los registros validados no se pueden editar.',
                style: TextStyle(color: mutedText)),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.onTap});
  final ConsejoLocal record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final payload = decodeDraft(record.payload);
    final name = payload['nombre']?.toString().trim().isNotEmpty == true
        ? payload['nombre'].toString()
        : 'Registro sin nombre';
    final date = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                    color: mintGreen.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.agriculture_outlined,
                    color: brandGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: darkGreen)),
                    const SizedBox(height: 4),
                    Text(
                      '${payload['parroquia_nombre'] ?? 'Parroquia sin seleccionar'} · ${DateFormat('d MMM, HH:mm', 'es').format(date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: mutedText, fontSize: 11),
                    ),
                    const SizedBox(height: 7),
                    RecordBadge(record: record),
                    if (record.syncState == 'error' &&
                        record.error != null) ...[
                      const SizedBox(height: 4),
                      Text(record.error!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFFE11D48), fontSize: 10)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.chevron_right_rounded,
                  color: mutedText.withValues(alpha: 0.65)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard(
      {required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            children: [
              Icon(icon, size: 33, color: mintGreen),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: darkGreen)),
              const SizedBox(height: 5),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: mutedText, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title.toUpperCase(),
      style: const TextStyle(
          color: mutedText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1));
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.rows});
  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            children: rows.entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(entry.key,
                                  style: const TextStyle(
                                      color: mutedText, fontSize: 13))),
                          Flexible(
                              child: Text(entry.value,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      color: darkGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13))),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      );
}
