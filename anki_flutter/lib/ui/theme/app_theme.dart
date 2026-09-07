import 'package:flutter/material.dart';

/// A quiet, editorial palette for a tool that is used for long study sessions.
///
/// The interface intentionally avoids bright gradients, oversized rounding and
/// decorative shadows. Hierarchy comes from typography, spacing and thin rules;
/// colour is reserved for actions and scheduling meaning.
class AppColors {
  const AppColors._();

  static const accent = Color(0xFF256653);
  static const accentStrong = Color(0xFF174A3C);
  static const accentSoft = Color(0xFFE2EEE8);

  static const again = Color(0xFFB84B4A);
  static const hard = Color(0xFFA66B24);
  static const good = Color(0xFF28735A);
  static const easy = Color(0xFF356FA3);

  static const lightBg = Color(0xFFF4F2ED);
  static const lightSurface = Color(0xFFFFFEFB);
  static const lightSurfaceAlt = Color(0xFFEDEAE3);
  static const lightBorder = Color(0xFFD9D5CC);
  static const lightText = Color(0xFF20231F);
  static const lightMuted = Color(0xFF6F746C);

  static const darkBg = Color(0xFF181B18);
  static const darkSurface = Color(0xFF212520);
  static const darkSurfaceAlt = Color(0xFF292E29);
  static const darkBorder = Color(0xFF393F39);
  static const darkText = Color(0xFFF1F1EB);
  static const darkMuted = Color(0xFFA5ABA3);
}

class AppSpacing {
  const AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

const double kAppRadius = 14.0;
const double kAppRadiusSmall = 9.0;

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt = isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final interactiveAccent = isDark ? const Color(0xFF75B8A2) : AppColors.accent;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
      primary: interactiveAccent,
      surface: surface,
      error: AppColors.again,
    ).copyWith(
      onPrimary: Colors.white,
      onSurface: text,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceAlt,
      outline: border,
      outlineVariant: border,
    );

    final textTheme = TextTheme(
      headlineSmall: TextStyle(
        fontSize: 29,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.65,
        height: 1.18,
        color: text,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.28,
        color: text,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.08,
        color: text,
      ),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text),
      bodyLarge: TextStyle(fontSize: 16, height: 1.52, color: text),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: text),
      bodySmall: TextStyle(fontSize: 12.5, height: 1.42, color: muted),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.02),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: muted),
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: AppColors.accent.withValues(alpha: 0.045),
      focusColor: AppColors.accent.withValues(alpha: 0.08),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: text,
        centerTitle: false,
        toolbarHeight: 68,
        titleSpacing: AppSpacing.lg,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: muted, size: 21),
        actionsIconTheme: IconThemeData(color: muted, size: 21),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kAppRadius),
          side: BorderSide(color: border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: text,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 15),
        hintStyle: TextStyle(color: muted.withValues(alpha: 0.82)),
        labelStyle: TextStyle(color: muted),
        floatingLabelStyle: TextStyle(color: interactiveAccent, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kAppRadiusSmall),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kAppRadiusSmall),
          borderSide: BorderSide(color: interactiveAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kAppRadiusSmall),
          borderSide: const BorderSide(color: AppColors.again),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: interactiveAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.35),
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          backgroundColor: surface,
          side: BorderSide(color: border),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: interactiveAccent,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          shape: buttonShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: muted,
          hoverColor: AppColors.accentSoft,
          highlightColor: AppColors.accentSoft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: interactiveAccent,
        foregroundColor: Colors.white,
        elevation: 1,
        focusElevation: 1,
        hoverElevation: 2,
        highlightElevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kAppRadiusSmall),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadius)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: TextStyle(color: bg),
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: buttonShape,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: interactiveAccent),
      extensions: [
        AppSemanticColors(
          border: border,
          muted: muted,
          surface: surface,
          surfaceAlt: surfaceAlt,
          bg: bg,
          text: text,
        ),
      ],
    );
  }
}

class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.border,
    required this.muted,
    required this.surface,
    required this.surfaceAlt,
    required this.bg,
    required this.text,
  });

  final Color border;
  final Color muted;
  final Color surface;
  final Color surfaceAlt;
  final Color bg;
  final Color text;

  @override
  AppSemanticColors copyWith({
    Color? border,
    Color? muted,
    Color? surface,
    Color? surfaceAlt,
    Color? bg,
    Color? text,
  }) =>
      AppSemanticColors(
        border: border ?? this.border,
        muted: muted ?? this.muted,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        bg: bg ?? this.bg,
        text: text ?? this.text,
      );

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      text: Color.lerp(text, other.text, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get appColors => Theme.of(this).extension<AppSemanticColors>()!;
}
