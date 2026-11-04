import 'package:flutter/material.dart';

import 'colors.dart';

const frizerajFont = 'packages/frizeraj_ui/FrizerajSans';

ThemeData frizerajTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: FrizerajColors.navy).copyWith(
    primary: FrizerajColors.navy,
    secondary: FrizerajColors.navy,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: FrizerajColors.charcoal,
    onSurfaceVariant: FrizerajColors.muted,
    outlineVariant: FrizerajColors.line,
    secondaryContainer: FrizerajColors.navyTint,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: frizerajFont,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
  );
  return base.copyWith(
    scaffoldBackgroundColor: FrizerajColors.cream,
    textTheme: base.textTheme
        .apply(
          fontFamily: frizerajFont,
          bodyColor: FrizerajColors.charcoal,
          displayColor: FrizerajColors.navy,
        )
        .copyWith(
          headlineLarge: base.textTheme.headlineLarge!.copyWith(
            fontSize: 34,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: FrizerajColors.navy,
          ),
          headlineMedium: base.textTheme.headlineMedium!.copyWith(
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
            color: FrizerajColors.navy,
          ),
          headlineSmall: base.textTheme.headlineSmall!.copyWith(
            fontSize: 23,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
            color: FrizerajColors.navy,
          ),
          titleLarge: base.textTheme.titleLarge!.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
            color: FrizerajColors.navy,
          ),
          titleMedium: base.textTheme.titleMedium!.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: FrizerajColors.navy,
          ),
          bodyMedium: base.textTheme.bodyMedium!.copyWith(
            fontSize: 14,
            height: 1.5,
            color: FrizerajColors.charcoal,
          ),
          bodySmall: base.textTheme.bodySmall!.copyWith(
            fontSize: 12,
            height: 1.4,
            color: FrizerajColors.muted,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FrizerajColors.cream,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: frizerajFont,
        color: FrizerajColors.navy,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -.7,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: FrizerajColors.line),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: FrizerajColors.line,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FrizerajColors.neutral,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: FrizerajColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: FrizerajColors.navy, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: rounded,
            textStyle: const TextStyle(
              fontFamily: frizerajFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? const BorderSide(color: FrizerajColors.coral, width: 3)
                  : BorderSide.none,
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: rounded,
        side: const BorderSide(color: FrizerajColors.line),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      selectedColor: FrizerajColors.navy,
      selectedTileColor: FrizerajColors.navyTint,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      height: 76,
      indicatorColor: FrizerajColors.navyTint,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: frizerajFont,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? FrizerajColors.navy
              : FrizerajColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? FrizerajColors.navy
              : FrizerajColors.muted,
        ),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: const WidgetStatePropertyAll(FrizerajColors.neutral),
      headingTextStyle: const TextStyle(
        fontFamily: frizerajFont,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: .7,
        color: FrizerajColors.muted,
      ),
      dataTextStyle: const TextStyle(
        fontFamily: frizerajFont,
        fontSize: 13,
        color: FrizerajColors.charcoal,
      ),
      dividerThickness: .6,
      horizontalMargin: 20,
      columnSpacing: 24,
      headingRowHeight: 48,
      dataRowMinHeight: 72,
      dataRowMaxHeight: 72,
      dataRowColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? FrizerajColors.navyTint
            : states.contains(WidgetState.hovered)
            ? FrizerajColors.neutral
            : Colors.white,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      shape: rounded,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    focusColor: FrizerajColors.navyTint,
  );
}
