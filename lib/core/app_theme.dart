import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _pistachio = Color(0xFF94B884);
  static const _pistachioDark = Color(0xFF5F7A54);
  static const _pistachioContainer = Color(0xFFDCEBD4);
  static const _softPink = Color(0xFFE8A8BE);
  static const _softPinkDeep = Color(0xFFC9889E);
  static const _pinkContainer = Color(0xFFFBE8EF);
  static const _surface = Color(0xFFFFFAFB);
  static const _surfaceTint = Color(0xFFF5EDE8);

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _pistachio,
      onPrimary: Color(0xFF1A2E14),
      primaryContainer: _pistachioContainer,
      onPrimaryContainer: _pistachioDark,
      secondary: _softPink,
      onSecondary: Color(0xFF4A2835),
      secondaryContainer: _pinkContainer,
      onSecondaryContainer: Color(0xFF6B3D4F),
      tertiary: Color(0xFFF4C4D4),
      onTertiary: Color(0xFF4A2835),
      tertiaryContainer: Color(0xFFFFE8F0),
      onTertiaryContainer: Color(0xFF5C3344),
      error: Color(0xFFBA5568),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF5C1A24),
      surface: _surface,
      onSurface: Color(0xFF3A3436),
      onSurfaceVariant: Color(0xFF6B6366),
      outline: Color(0xFFD4C4C8),
      outlineVariant: Color(0xFFE8DCE0),
      shadow: Color(0x1A000000),
      scrim: Color(0x66000000),
      inverseSurface: Color(0xFF3A3436),
      onInverseSurface: Color(0xFFF5EFF1),
      inversePrimary: Color(0xFFB8D4AC),
      surfaceTint: _softPink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _surfaceTint,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: _pinkContainer,
        foregroundColor: _pistachioDark,
        iconTheme: IconThemeData(color: _pistachioDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _softPink.withValues(alpha: 0.35)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _pistachio,
          foregroundColor: const Color(0xFF1A2E14),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: _softPinkDeep),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _softPink.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _pistachio, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF6B6366)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _pinkContainer,
        selectedColor: _pistachioContainer,
        labelStyle: const TextStyle(color: Color(0xFF3A3436)),
        side: BorderSide(color: _softPink.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _pistachio;
          return null;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: _softPinkDeep),
      dividerTheme: DividerThemeData(color: _softPink.withValues(alpha: 0.25)),
    );
  }
}
