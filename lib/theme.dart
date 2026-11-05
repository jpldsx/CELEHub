import 'package:flutter/material.dart';

// the CELEHub website theme (css/style.css), as colors the app can use
class C {
  static const Color bg = Color(0xFFF4F6FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surface2 = Color(0xFFF1F3FA);
  static const Color border = Color(0xFFE4E8F2);
  static const Color text = Color(0xFF1B2033);
  static const Color muted = Color(0xFF566079);
  static const Color accent = Color(0xFF4F46E5);
  static const Color accent2 = Color(0xFF06B6D4);
  static const Color accentSoft = Color(0x1A4F46E5);
  static const Color danger = Color(0xFFDC2626);
  static const double radius = 16;

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF6D3BE0), Color(0xFF1D4ED8)],
  );
  static const LinearGradient logo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accent2],
  );

  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x0F1B2033), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x2E4F46E5), blurRadius: 28, offset: Offset(0, 10)),
  ];
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: C.accent, brightness: Brightness.light).copyWith(
    primary: C.accent,
    onPrimary: Colors.white,
    secondary: C.accent2,
    surface: C.surface,
    onSurface: C.text,
    outline: C.border,
    outlineVariant: C.border,
    error: C.danger,
  );
  final shape14 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xF2FFFFFF),
      foregroundColor: C.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: C.accentSoft,
      elevation: 3,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        shape: shape14,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.accent,
        minimumSize: const Size(0, 48),
        shape: shape14,
        side: const BorderSide(color: C.border),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: C.accent)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.accent, width: 1.6)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.text,
      shape: shape14,
    ),
  );
}
