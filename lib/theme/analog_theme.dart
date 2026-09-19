import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "따뜻한 아날로그 감성" (warm analog / emotional diary) palette and shared
/// widgets used across the app.
class AnalogColors {
  AnalogColors._();

  /// Kraft-paper background.
  static const background = Color(0xFFF4ECDD);

  /// Card / paper surface, slightly lighter than the background.
  static const cardBackground = Color(0xFFFBF6EC);

  /// Dashed/solid border color used on paper cards.
  static const cardBorder = Color(0xFFD8C9AE);

  /// Main ink color.
  static const textPrimary = Color(0xFF3B2E22);

  /// Secondary, muted ink color.
  static const textSecondary = Color(0xFF8C7A63);

  /// Terracotta accent used for buttons, chip outlines, highlights.
  static const accent = Color(0xFFC1694A);

  /// Mood palette, ordered best -> worst.
  static const moodBest = Color(0xFFD1A24A); // 최고
  static const moodGood = Color(0xFF8B9574); // 좋음
  static const moodOkay = Color(0xFFA6957C); // 보통
  static const moodMeh = Color(0xFF7C93A8); // 별로
  static const moodBad = Color(0xFFC17A78); // 힘듦
}

/// One entry of the 5-point mood palette, best -> worst.
class MoodOption {
  const MoodOption(this.label, this.color);

  final String label;
  final Color color;
}

const List<MoodOption> kMoodOptions = [
  MoodOption('최고', AnalogColors.moodBest),
  MoodOption('좋음', AnalogColors.moodGood),
  MoodOption('보통', AnalogColors.moodOkay),
  MoodOption('별로', AnalogColors.moodMeh),
  MoodOption('힘듦', AnalogColors.moodBad),
];

/// Builds the app-wide analog/warm ThemeData.
ThemeData buildAnalogTheme() {
  final headingTextTheme = GoogleFonts.nanumMyeongjoTextTheme();
  final bodyTextTheme = GoogleFonts.gowunBatangTextTheme();

  final textTheme = bodyTextTheme
      .copyWith(
        displayLarge: headingTextTheme.displayLarge,
        displayMedium: headingTextTheme.displayMedium,
        displaySmall: headingTextTheme.displaySmall,
        headlineLarge: headingTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: headingTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: headingTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        titleLarge: headingTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        titleMedium: headingTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        titleSmall: headingTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      )
      .apply(
        bodyColor: AnalogColors.textPrimary,
        displayColor: AnalogColors.textPrimary,
      );

  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AnalogColors.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: AnalogColors.accent,
        onPrimary: Colors.white,
        secondary: AnalogColors.textSecondary,
        surface: AnalogColors.cardBackground,
        onSurface: AnalogColors.textPrimary,
      );

  const paperShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(4)),
    side: BorderSide(color: AnalogColors.cardBorder),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AnalogColors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AnalogColors.background,
      foregroundColor: AnalogColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.nanumMyeongjo(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: AnalogColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AnalogColors.textPrimary),
    ),
    cardTheme: const CardThemeData(
      color: AnalogColors.cardBackground,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: paperShape,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.transparent,
      selectedColor: AnalogColors.accent.withValues(alpha: 0.15),
      disabledColor: Colors.transparent,
      side: const BorderSide(color: AnalogColors.accent),
      shape: const StadiumBorder(),
      labelStyle: GoogleFonts.gowunBatang(color: AnalogColors.accent),
      secondaryLabelStyle: GoogleFonts.gowunBatang(color: AnalogColors.accent),
      deleteIconColor: AnalogColors.accent,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AnalogColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AnalogColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AnalogColors.accent,
        side: const BorderSide(color: AnalogColors.accent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AnalogColors.accent),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AnalogColors.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AnalogColors.cardBackground,
      hintStyle: GoogleFonts.gowunBatang(color: AnalogColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AnalogColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AnalogColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: AnalogColors.accent, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AnalogColors.cardBorder),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AnalogColors.cardBackground,
      indicatorColor: AnalogColors.accent.withValues(alpha: 0.18),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.gowunBatang(color: AnalogColors.textPrimary, fontSize: 12),
      ),
      iconTheme: const WidgetStatePropertyAll(
        IconThemeData(color: AnalogColors.textPrimary),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AnalogColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    iconTheme: const IconThemeData(color: AnalogColors.textPrimary),
  );
}

/// Rotation angles (in radians) used to give polaroid-style thumbnails an
/// alternating, slightly hand-placed tilt.
double polaroidAngleForIndex(int index) {
  const anglesDeg = [-4.0, 5.0, -3.0, 6.0, -5.0, 3.0];
  return anglesDeg[index % anglesDeg.length] * math.pi / 180;
}

/// Wraps a media thumbnail with a white polaroid-style frame and a small
/// alternating tilt, for the "analog diary" photo feel.
class PolaroidThumbnail extends StatelessWidget {
  const PolaroidThumbnail({
    super.key,
    required this.child,
    required this.size,
    required this.index,
  });

  /// The thumbnail content (usually an [Image.memory] or a video placeholder).
  final Widget child;

  /// Width/height of the inner photo area.
  final double size;

  /// Used to alternate the tilt direction/magnitude between thumbnails.
  final int index;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: polaroidAngleForIndex(index),
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AnalogColors.cardBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 4,
              offset: Offset(1, 2),
            ),
          ],
        ),
        child: SizedBox(width: size, height: size, child: child),
      ),
    );
  }
}

/// A small paper-card container matching the analog theme, for surfaces that
/// aren't full [Card] widgets (e.g. bottom sheet content).
class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AnalogColors.cardBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AnalogColors.cardBorder),
      ),
      child: child,
    );
  }
}
