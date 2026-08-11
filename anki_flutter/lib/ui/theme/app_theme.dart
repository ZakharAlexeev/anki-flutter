import 'package:flutter/material.dart';

/// A restrained, editorial design language shared by every screen: flat
/// hairline borders instead of shadows, one accent color used sparingly, a
/// single consistent corner radius, and generous whitespace. No gradients,
/// no saturated fills - the four rating "colors" are the only deliberate
/// exception, and even those are muted tints rather than solid blocks.
class AppColors {
  const AppColors._();

  // Accent: a single restrained indigo, used only for primary actions and
  // the current selection - never as decoration.
  static const accent = Color(0xFF4A4E9B);

  // Rating tints (Again/Hard/Good/Easy) - muted, not saturated.
  static const again = Color(0xFFB3564B);
  static const hard = Color(0xFFB08A3E);
  static const good = Color(0xFF4C8B6B);
  static const easy = Color(0xFF3E7CB1);

  static const lightBg = Color(0xFFFAFAF8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE6E4DF);
  static const lightText = Color(0xFF201F1C);
  static const lightMuted = Color(0xFF7A7871);

  static const darkBg = Color(0xFF16161A);
  static const darkSurface = Color(0xFF1D1D22);
  static const darkBorder = Color(0xFF2C2C33);
  static const darkText = Color(0xFFEDEDEC);
  static const darkMuted = Color(0xFF97968F);
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
const double kAppRadiusSmall = 10.0;

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

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      error: AppColors.again,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
    );

    final textTheme = TextTheme(
      headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: text),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: text),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: text),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: text),
      bodySmall: TextStyle(fontSize: 12.5, color: muted),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: text,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: muted),
      ),
      cardTheme: CardThemeData(
        color: surface,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
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
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
        labelStyle: TextStyle(color: muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: muted,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: muted),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall), side: BorderSide(color: border)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall), side: BorderSide(color: border)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadius)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: TextStyle(color: bg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRadiusSmall)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.accent),
      extensions: [AppSemanticColors(border: border, muted: muted, surface: surface, bg: bg)],
    );
  }
}

/// Extra tokens not modeled by [ColorScheme] - fetched via
/// `Theme.of(context).extension<AppSemanticColors>()!`.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({required this.border, required this.muted, required this.surface, required this.bg});

  final Color border;
  final Color muted;
  final Color surface;
  final Color bg;

  @override
  AppSemanticColors copyWith({Color? border, Color? muted, Color? surface, Color? bg}) => AppSemanticColors(
        border: border ?? this.border,
        muted: muted ?? this.muted,
        surface: surface ?? this.surface,
        bg: bg ?? this.bg,
      );

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get appColors => Theme.of(this).extension<AppSemanticColors>()!;
}
