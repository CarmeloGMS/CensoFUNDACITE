import 'package:material_ui/material_ui.dart';

const brandGreen = Color(0xFF065F46);
const darkGreen = Color(0xFF022C22);
const midGreen = Color(0xFF047857);
const mintGreen = Color(0xFF10B981);
const amber = Color(0xFFD97706);
const stone = Color(0xFFFAFAF9);
const mutedText = Color(0xFF66716B);
const chipSurface = Color(0xFFF5F5F4);
const chipSelectedSurface = Color(0xFFD1FAE5);
const chipText = Color(0xFF1C1917);
const chipBorder = Color(0xFFD6D3D1);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: brandGreen,
    brightness: Brightness.light,
  ).copyWith(
    primary: brandGreen,
    secondary: amber,
    surface: Colors.white,
    error: const Color(0xFFE11D48),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: stone,
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -1.1),
      headlineMedium: TextStyle(
          fontSize: 25, fontWeight: FontWeight.w700, letterSpacing: -0.6),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontSize: 15, height: 1.45),
      bodyMedium: TextStyle(fontSize: 13, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: stone,
      foregroundColor: darkGreen,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: darkGreen,
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0.7,
      shadowColor: darkGreen.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF4F6F4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFF9AA39D), fontSize: 14),
      labelStyle: const TextStyle(color: mutedText, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: midGreen, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE11D48)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: mintGreen.withValues(alpha: 0.13),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: chipSurface,
      selectedColor: chipSelectedSurface,
      secondarySelectedColor: chipSelectedSurface,
      side: const BorderSide(color: chipBorder),
      showCheckmark: true,
      checkmarkColor: brandGreen,
      labelStyle: const TextStyle(fontSize: 13, color: chipText),
      secondaryLabelStyle: const TextStyle(fontSize: 13, color: brandGreen),
    ),
  );
}
