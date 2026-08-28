import 'package:flutter/material.dart';

/// Shared visual tokens for the application.
///
/// The light theme deliberately uses a cool neutral canvas, clean white
/// surfaces and one vivid indigo accent. Semantic study colors stay separate
/// so the reviewer remains instantly scannable.
class AppColors {
  const AppColors._();

  static const accent = Color(0xFF5B5FEF);
  static const accentStrong = Color(0xFF4548C9);
  static const accentSoft = Color(0xFFEDEEFF);

  static const again = Color(0xFFD85C62);
  static const hard = Color(0xFFD49A36);
  static const good = Color(0xFF2E9D72);
  static const easy = Color(0xFF4384E6);

  static const lightBg = Color(0xFFF6F7FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE3E6EF);
  static const lightText = Color(0xFF202534);
  static const lightMuted = Color(0xFF737B8C);

  static const darkBg = Color(0xFF171821);
  static const darkSurface = Color(0xFF20222D);
  static const darkBorder = Color(0xFF303341);
  static const darkText = Color(0xFFF3F4F8);
  static const darkMuted = Color(0xFFA0A5B2);
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

const double kAppRadius = 20.0;
const double kAppRadiusSmall = 14.0;

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final text = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
      primary: AppColors.accent,
      surface: surface,
      error: AppColors.again,
    ).copyWith(
      onPrimary: Colors.white,
      onSurface: text,
    );

    final textTheme = TextTheme(
      headlineSmall: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        height: 1.15,
        color: text,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        color: text,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: text,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: text),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: text),
      bodySmall: TextStyle(fontSize: 12.5, height: 1.4, color: muted),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
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
        toolbarHeight: 72,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: muted, size: 21),
        actionsIconTheme: IconThemeData(color: muted, size: 21),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0xFF171C2F).withValues(alpha: isDark ? 0.28 : 0.07),
        elevation: isDark ? 0 : 1.2,
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
        hintStyle: TextStyle(color: muted.withValues(alpha: 0.8)),
        labelStyle: TextStyle(color: muted),
        floatingLabelStyle: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kAppRadiusSmall),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kAppRadiusSmall),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kAppRadiusSmall),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kAppRadiusSmall),
          borderSide: const BorderSide(color: AppColors.again),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.35),
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: muted,
          hoverColor: AppColors.accentSoft,
          highlightColor: AppColors.accentSoft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 4,
        hoverElevation: 6,
        highlightElevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kAppRadiusSmall),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: TextStyle(color: bg),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.accent),
      extensions: [
        AppSemanticColors(
          border: border,
          muted: muted,
          surface: surface,
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
    required this.bg,
    required this.text,
  });

  final Color border;
  final Color muted;
  final Color surface;
  final Color bg;
  final Color text;

  @override
  AppSemanticColors copyWith({
    Color? border,
    Color? muted,
    Color? surface,
    Color? bg,
    Color? text,
  }) =>
      AppSemanticColors(
        border: border ?? this.border,
        muted: muted ?? this.muted,
        surface: surface ?? this.surface,
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
      bg: Color.lerp(bg, other.bg, t)!,
      text: Color.lerp(text, other.text, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get appColors => Theme.of(this).extension<AppSemanticColors>()!;
}