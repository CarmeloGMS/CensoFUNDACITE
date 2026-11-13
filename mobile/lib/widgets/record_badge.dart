import 'package:material_ui/material_ui.dart';

import '../core/app_theme.dart';
import '../core/field_data.dart';
import '../data/app_database.dart';

class RecordBadge extends StatelessWidget {
  const RecordBadge({super.key, required this.record});

  final ConsejoLocal record;

  @override
  Widget build(BuildContext context) {
    final payload = decodeDraft(record.payload);
    final serverState = payload['estado']?.toString();
    final (label, color, icon) = switch (record.syncState) {
      'draft' => ('Borrador', const Color(0xFF64748B), Icons.edit_note_rounded),
      'pending' => ('Pendiente de envío', amber, Icons.cloud_upload_outlined),
      'error' => (
          'Error de sincronización',
          const Color(0xFFE11D48),
          Icons.error_outline_rounded
        ),
      _ when serverState == 'validado' => (
          'Validado',
          const Color(0xFF059669),
          Icons.verified_rounded
        ),
      _ when serverState == 'rechazado' => (
          'Rechazado',
          const Color(0xFFE11D48),
          Icons.cancel_outlined
        ),
      _ => (
          'Sincronizado · Enviado',
          const Color(0xFF059669),
          Icons.cloud_done_rounded
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
