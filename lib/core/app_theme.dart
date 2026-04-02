import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const primary = Color(0xFF0F766E);
    const accent = Color(0xFFEF4444);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      surface: const Color(0xFFF6F8FC),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F8FC),
      fontFamily: 'Alexandria',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.black.withAlpha(15),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 6,
        indicatorColor: primary.withAlpha(30),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontSize: 12,
            fontWeight:
                states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF0F766E)
                : const Color(0xFF64748B),
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
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
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF0F172A),
        displayColor: const Color(0xFF0F172A),
      ),
      extensions: const [
        _BrandColors(
          primaryGradientA: primary,
          primaryGradientB: Color(0xFF14B8A6),
          dangerGradientA: Color(0xFFF97316),
          dangerGradientB: accent,
        ),
      ],
    );
  }
}

@immutable
class _BrandColors extends ThemeExtension<_BrandColors> {
  const _BrandColors({
    required this.primaryGradientA,
    required this.primaryGradientB,
    required this.dangerGradientA,
    required this.dangerGradientB,
  });

  final Color primaryGradientA;
  final Color primaryGradientB;
  final Color dangerGradientA;
  final Color dangerGradientB;

  @override
  ThemeExtension<_BrandColors> copyWith({
    Color? primaryGradientA,
    Color? primaryGradientB,
    Color? dangerGradientA,
    Color? dangerGradientB,
  }) {
    return _BrandColors(
      primaryGradientA: primaryGradientA ?? this.primaryGradientA,
      primaryGradientB: primaryGradientB ?? this.primaryGradientB,
      dangerGradientA: dangerGradientA ?? this.dangerGradientA,
      dangerGradientB: dangerGradientB ?? this.dangerGradientB,
    );
  }

  @override
  ThemeExtension<_BrandColors> lerp(
    covariant ThemeExtension<_BrandColors>? other,
    double t,
  ) {
    if (other is! _BrandColors) return this;
    return _BrandColors(
      primaryGradientA:
          Color.lerp(primaryGradientA, other.primaryGradientA, t) ?? primaryGradientA,
      primaryGradientB:
          Color.lerp(primaryGradientB, other.primaryGradientB, t) ?? primaryGradientB,
      dangerGradientA:
          Color.lerp(dangerGradientA, other.dangerGradientA, t) ?? dangerGradientA,
      dangerGradientB:
          Color.lerp(dangerGradientB, other.dangerGradientB, t) ?? dangerGradientB,
    );
  }
}
