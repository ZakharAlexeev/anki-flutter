import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A restrained, reading-first visual system tuned for a phone screen.
///
/// The palette is deliberately closer to paper, ink and iOS system blue than
/// to the saturated purple/gradient language common in generated interfaces.
/// Study outcomes keep their own semantic colours for instant recognition.
class AppColors {
  const AppColors._();

  static const accent = Color(0xFF245A9B);
  static const accentStrong = Color(0xFF173E6F);
  static const accentSoft = Color(0xFFE8F0F8);

  static const again = Color(0xFFB84E4E);
  static const hard = Color(0xFFA06B1F);
  static const good = Color(0xFF367A56);
  static const easy = Color(0xFF356DAD);

  static const lightBg = Color(0xFFF4F2ED);
  static const lightSurface = Color(0xFFFEFDFB);
  static const lightBorder = Color(0xFFDDD9D1);
  static const lightText = Color(0xFF202326);
  static const lightMuted = Color(0xFF6C716F);

  static const darkBg = Color(0xFF161817);
  static const darkSurface = Color(0xFF202321);
  static const darkBorder = Color(0xFF343835);
  static const darkText = Color(0xFFF1F0EC);
  static const darkMuted = Color(0xFFA5AAA6);
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

const double kAppRadius = 16.0;
const double kAppRadiusSmall = 12.0;

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
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.55,
        height: 1.18,
        color: text,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: text,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: text,
      ),
      bodyLarge: TextStyle(fontSize: 17, height: 1.48, color: text),
      bodyMedium: TextStyle(fontSize: 15, height: 1.45, color: text),
      bodySmall: TextStyle(fontSize: 13, height: 1.38, color: muted),
      labelLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.05,
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
        centerTitle: true,
        toolbarHeight: 56,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: muted, size: 21),
        actionsIconTheme: IconThemeData(color: muted, size: 21),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
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
          minimumSize: const Size(0, 50),
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
          minimumSize: const Size(0, 50),
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
          elevation: 1,
          focusElevation: 1,
          hoverElevation: 2,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
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
