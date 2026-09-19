import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/blog_list_page.dart';
import 'screens/calendar_page.dart';
import 'screens/insights_page.dart';
import 'screens/today_diary_page.dart';

void main() {
  runApp(const ProviderScope(child: DiaryApp()));
}

/// "귀엽고 아기자기함" (cute/kawaii) visual theme palette for the whole app.
class CuteColors {
  const CuteColors._();

  static const background = Color(0xFFFFF7EE);
  static const cardBackground = Color(0xFFFFFFFF);
  static const textMain = Color(0xFF4A3428);
  static const textSecondary = Color(0xFF9C8677);
  static const accent = Color(0xFFFF9B7A);

  // Mood palette, best -> worst.
  static const moodBest = Color(0xFFFFC857); // 최고
  static const moodGood = Color(0xFF8FD9A8); // 좋음
  static const moodOkay = Color(0xFFC9B8E8); // 보통
  static const moodMeh = Color(0xFF8FB8E8); // 별로
  static const moodBad = Color(0xFFFF8A80); // 힘듦
}

/// Flutter Web draws every frame by repainting a canvas, so the default
/// slide/fade page-route animations (which redraw the whole screen on every
/// frame of the transition) tend to feel rougher on Safari than a browser's
/// native, GPU-composited CSS transitions. Cutting instantly instead of
/// animating removes that roughness entirely.
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

ThemeData _buildCuteTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: CuteColors.accent,
    brightness: Brightness.light,
    primary: CuteColors.accent,
    surface: CuteColors.cardBackground,
  );

  final baseTextTheme = GoogleFonts.gowunDodumTextTheme();
  final headingTextTheme = GoogleFonts.gaeguTextTheme();

  final textTheme = baseTextTheme
      .copyWith(
        displayLarge: headingTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: CuteColors.textMain,
        ),
        displayMedium: headingTextTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: CuteColors.textMain,
        ),
        displaySmall: headingTextTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: CuteColors.textMain,
        ),
        headlineLarge: headingTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: CuteColors.textMain,
        ),
        headlineMedium: headingTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: CuteColors.textMain,
        ),
        headlineSmall: headingTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: CuteColors.textMain,
        ),
        titleLarge: headingTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: CuteColors.textMain,
        ),
        titleMedium: headingTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: CuteColors.textMain,
        ),
        titleSmall: headingTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: CuteColors.textMain,
        ),
      )
      .apply(
        bodyColor: CuteColors.textMain,
        displayColor: CuteColors.textMain,
      )
      .copyWith(
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: CuteColors.textSecondary,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: CuteColors.textSecondary,
        ),
      );

  final pillShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(999),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: CuteColors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: CuteColors.background,
      foregroundColor: CuteColors.textMain,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.gaegu(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: CuteColors.textMain,
      ),
    ),
    cardTheme: CardThemeData(
      color: CuteColors.cardBackground,
      elevation: 4,
      shadowColor: CuteColors.textSecondary.withValues(alpha: 0.25),
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CuteColors.accent.withValues(alpha: 0.12),
      selectedColor: CuteColors.accent,
      disabledColor: CuteColors.textSecondary.withValues(alpha: 0.12),
      labelStyle: GoogleFonts.gowunDodum(color: CuteColors.textMain),
      secondaryLabelStyle: GoogleFonts.gowunDodum(color: Colors.white),
      side: BorderSide.none,
      shape: pillShape,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CuteColors.accent,
        foregroundColor: Colors.white,
        shape: pillShape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.gowunDodum(fontWeight: FontWeight.w600),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CuteColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: CuteColors.accent.withValues(alpha: 0.4),
        shape: pillShape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.gowunDodum(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CuteColors.accent,
        shape: pillShape,
        textStyle: GoogleFonts.gowunDodum(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CuteColors.accent,
        side: const BorderSide(color: CuteColors.accent),
        shape: pillShape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.gowunDodum(fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: CuteColors.accent,
      foregroundColor: Colors.white,
      shape: StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CuteColors.cardBackground,
      hintStyle: GoogleFonts.gowunDodum(color: CuteColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: CuteColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: CuteColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CuteColors.accent, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CuteColors.cardBackground,
      elevation: 0,
      indicatorColor: CuteColors.accent.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.gowunDodum(
          color: selected ? CuteColors.accent : CuteColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? CuteColors.accent : CuteColors.textSecondary,
        );
      }),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: CuteColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    iconTheme: const IconThemeData(color: CuteColors.textMain),
    dividerColor: CuteColors.textSecondary.withValues(alpha: 0.2),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _NoTransitionsBuilder(),
        TargetPlatform.iOS: _NoTransitionsBuilder(),
        TargetPlatform.linux: _NoTransitionsBuilder(),
        TargetPlatform.macOS: _NoTransitionsBuilder(),
        TargetPlatform.windows: _NoTransitionsBuilder(),
        TargetPlatform.fuchsia: _NoTransitionsBuilder(),
      },
    ),
  );
}

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary',
      theme: _buildCuteTheme(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _pages = [
    TodayDiaryPage(),
    CalendarPage(),
    BlogListPage(),
    InsightsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: CuteColors.cardBackground,
            boxShadow: [
              BoxShadow(
                color: CuteColors.textSecondary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.edit_note),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month),
                label: 'Calendar',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book),
                label: 'Blog',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights),
                label: 'Insights',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
