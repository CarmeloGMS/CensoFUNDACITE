import 'package:material_ui/material_ui.dart';

import '../core/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.light = false});

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: light ? Colors.white.withValues(alpha: 0.12) : brandGreen,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: light
              ? null
              : [
                  BoxShadow(
                    color: brandGreen.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Icon(
          Icons.spa_rounded,
          size: size * 0.55,
          color: light ? Colors.white : const Color(0xFFB7F7D8),
        ),
      );
}
