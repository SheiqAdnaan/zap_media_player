import 'package:flutter/material.dart';

/// Zap Media Player complete dark theme system.
/// Colors derived from the spec: #0B0E14 background, #141822 surface, #0088FF accent.
class ZmpTheme {
  ZmpTheme._();

  // ── Base Palette ──────────────────────────────────────────────────────
  static const Color windowBackground = Color(0xFF0B0E14);
  static const Color cardSurface = Color(0xFF141822);
  static const Color cardSurfaceHover = Color(0xFF1A2030);
  static const Color cardSurfaceActive = Color(0xFF202838);
  static const Color accentBlue = Color(0xFF0088FF);
  static const Color accentAmber = Color(0xFFFF9800);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A94A6);
  static const Color textMuted = Color(0xFF4A5568);
  static const Color overlayBlack = Color(0xCC000000);
  static const Color seekbarBg = Color(0xFF2A3040);
  static const Color seekbarBuffer = Color(0xFF3A4A60);
  static const Color progressGreen = Color(0xFF4CAF50);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color badgeNew = Color(0xFF22C55E);
  static const Color divider = Color(0xFF1E2433);

  // ── Typography ────────────────────────────────────────────────────────
  static const String fontFamily = 'Segoe UI';
  static const String monoFontFamily = 'JetBrainsMono';

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
  );

  static const TextStyle timecode = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle timecodeSmall = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  // ── Theme Data ────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: windowBackground,
        colorScheme: const ColorScheme.dark(
          surface: cardSurface,
          primary: accentBlue,
          secondary: accentAmber,
          error: dangerRed,
          onSurface: textPrimary,
          onPrimary: textPrimary,
        ),
        fontFamily: fontFamily,
        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: windowBackground,
          foregroundColor: textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: titleLarge,
        ),
        // Cards
        cardTheme: CardThemeData(
          color: cardSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        // Tab Bar
        tabBarTheme: TabBarThemeData(
          labelColor: accentBlue,
          unselectedLabelColor: textSecondary,
          indicatorColor: accentBlue,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        // Input / Search
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardSurface,
          hintStyle: bodyMedium,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        // Icon buttons
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) return textPrimary;
              return textSecondary;
            }),
          ),
        ),
        // Tooltips
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: cardSurfaceActive,
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: bodySmall.copyWith(color: textPrimary),
        ),
        // Popup menus / Context menu
        popupMenuTheme: PopupMenuThemeData(
          color: cardSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: divider),
          ),
          textStyle: bodyMedium.copyWith(color: textPrimary),
        ),
        // Slider
        sliderTheme: const SliderThemeData(
          activeTrackColor: accentBlue,
          inactiveTrackColor: seekbarBg,
          thumbColor: accentBlue,
          overlayColor: Color(0x220088FF),
          trackHeight: 4,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
        ),
        // Dividers
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 1,
          space: 1,
        ),
        // Scrollbar
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(textMuted.withValues(alpha: 0.4)),
          radius: const Radius.circular(4),
          thickness: WidgetStateProperty.all(6),
        ),
        // Dialogs
        dialogTheme: DialogThemeData(
          backgroundColor: cardSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  // ── Utility Methods ───────────────────────────────────────────────────

  /// Format badge decoration for resolution/format tags
  static BoxDecoration formatBadge({Color? color}) => BoxDecoration(
        color: (color ?? accentBlue).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (color ?? accentBlue).withValues(alpha: 0.3),
          width: 1,
        ),
      );

  /// Duration badge decoration (bottom-right of thumbnail)
  static BoxDecoration get durationBadge => BoxDecoration(
        color: overlayBlack,
        borderRadius: BorderRadius.circular(4),
      );

  /// New badge decoration (top-left of thumbnail)
  static BoxDecoration get newBadge => BoxDecoration(
        color: badgeNew,
        borderRadius: BorderRadius.circular(4),
      );
}
