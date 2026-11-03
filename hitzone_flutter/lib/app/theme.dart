import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/booking.dart';

/// Design tokens copied from the web app's CSS variables
/// (`--blue`, `--bl`, `--bd`, `--bg`, `--card`, `--tx`, ...).
@immutable
class HzColors extends ThemeExtension<HzColors> {
  const HzColors({
    required this.blue,
    required this.blueLight,
    required this.blueDark,
    required this.blueMid,
    required this.bg,
    required this.card,
    required this.tx,
    required this.tx2,
    required this.tx3,
    required this.border,
    required this.red,
    required this.green,
    required this.yellow,
    required this.purple,
  });

  final Color blue;
  final Color blueLight;
  final Color blueDark;
  final Color blueMid;
  final Color bg;
  final Color card;
  final Color tx;
  final Color tx2;
  final Color tx3;
  final Color border;
  final Color red;
  final Color green;
  final Color yellow;
  final Color purple;

  static const light = HzColors(
    blue: Color(0xFF0EA5E9),
    blueLight: Color(0xFFE0F2FE),
    blueDark: Color(0xFF0369A1),
    blueMid: Color(0xFF38BDF8),
    bg: Color(0xFFF0F9FF),
    card: Colors.white,
    tx: Color(0xFF0F172A),
    tx2: Color(0xFF475569),
    tx3: Color(0xFF94A3B8),
    border: Color(0xFFBAE6FD),
    red: Color(0xFFEF4444),
    green: Color(0xFF22C55E),
    yellow: Color(0xFFF59E0B),
    purple: Color(0xFF8B5CF6),
  );

  static const dark = HzColors(
    blue: Color(0xFF0EA5E9),
    blueLight: Color(0xFF12385C),
    blueDark: Color(0xFF7DD3FC),
    blueMid: Color(0xFF38BDF8),
    bg: Color(0xFF0A1628),
    card: Color(0xFF0F2035),
    tx: Color(0xFFE0F2FE),
    tx2: Color(0xFF7DD3FC),
    tx3: Color(0xFF5B87B5),
    border: Color(0xFF1E3A5F),
    red: Color(0xFFF87171),
    green: Color(0xFF4ADE80),
    yellow: Color(0xFFFBBF24),
    purple: Color(0xFFA78BFA),
  );

  @override
  HzColors copyWith() => this;

  @override
  HzColors lerp(ThemeExtension<HzColors>? other, double t) =>
      t < 0.5 ? this : (other as HzColors? ?? this);

  /// Foreground / background pair for a booking status badge.
  (Color fg, Color bg) statusColors(BookingStatus s) {
    final base = switch (s) {
      BookingStatus.confirmed => green,
      BookingStatus.pending => yellow,
      BookingStatus.completed => blue,
      BookingStatus.cancelled => red,
    };
    return (base, base.withValues(alpha: 0.15));
  }
}

extension HzThemeContext on BuildContext {
  HzColors get hz => Theme.of(this).extension<HzColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

class AppTheme {
  const AppTheme._();

  /// Tests turn this off so no font is downloaded.
  static bool useGoogleFonts = true;

  static const double radius = 10;
  static const double radiusLarge = 14;

  static TextStyle heading(
    BuildContext context, {
    double size = 20,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color ?? context.hz.tx,
    );
    return useGoogleFonts ? GoogleFonts.spaceGrotesk(textStyle: style) : style;
  }

  static ThemeData build(Brightness brightness) {
    final c = brightness == Brightness.light ? HzColors.light : HzColors.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.blue,
          brightness: brightness,
        ).copyWith(
          primary: c.blue,
          onPrimary: Colors.white,
          primaryContainer: c.blueLight,
          onPrimaryContainer: c.blueDark,
          secondary: c.blueMid,
          surface: c.card,
          onSurface: c.tx,
          onSurfaceVariant: c.tx2,
          surfaceContainerLowest: c.bg,
          surfaceContainerLow: c.bg,
          surfaceContainer: c.card,
          surfaceContainerHigh: c.card,
          surfaceContainerHighest: c.blueLight,
          error: c.red,
          outline: c.border,
          outlineVariant: c.border,
        );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: scheme,
    );
    final textTheme =
        (useGoogleFonts
                ? GoogleFonts.outfitTextTheme(base.textTheme)
                : base.textTheme)
            .apply(bodyColor: c.tx, displayColor: c.tx);

    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      extensions: [c],
      scaffoldBackgroundColor: c.bg,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.card,
        foregroundColor: c.tx,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
          statusBarBrightness: brightness,
          systemNavigationBarColor: c.card,
          systemNavigationBarIconBrightness: brightness == Brightness.light
              ? Brightness.dark
              : Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: c.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFF8FAFC)
            : c.bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: border(c.border),
        enabledBorder: border(c.border),
        focusedBorder: border(c.blue, 2),
        errorBorder: border(c.red),
        focusedErrorBorder: border(c.red, 2),
        labelStyle: TextStyle(color: c.tx2),
        floatingLabelStyle: TextStyle(
          color: c.blue,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: c.tx3),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.blueDark,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: c.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.blue),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.card,
        selectedColor: c.blue,
        side: BorderSide(color: c.border, width: 1.5),
        labelStyle: TextStyle(color: c.tx2, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.blueLight,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.tx2),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? c.blueDark : c.tx2,
          ),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : c.tx3,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.blue : c.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.blue),
    );
  }
}
