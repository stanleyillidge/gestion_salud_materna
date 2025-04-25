import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff00538f),
      surfaceTint: Color(0xff0061a5),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff036cb7),
      onPrimaryContainer: Color(0xffdfebff),
      secondary: Color(0xff48607e),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffc3dcff),
      onSecondaryContainer: Color(0xff48617f),
      tertiary: Color(0xff72378c),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff8d50a6),
      onTertiaryContainer: Color(0xfffbe2ff),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff8f9ff),
      onSurface: Color(0xff181c21),
      onSurfaceVariant: Color(0xff414751),
      outline: Color(0xff717782),
      outlineVariant: Color(0xffc0c7d3),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d3136),
      inversePrimary: Color(0xffa0caff),
      primaryFixed: Color(0xffd2e4ff),
      onPrimaryFixed: Color(0xff001c37),
      primaryFixedDim: Color(0xffa0caff),
      onPrimaryFixedVariant: Color(0xff00497e),
      secondaryFixed: Color(0xffd2e4ff),
      onSecondaryFixed: Color(0xff001c37),
      secondaryFixedDim: Color(0xffafc8eb),
      onSecondaryFixedVariant: Color(0xff304865),
      tertiaryFixed: Color(0xfff8d8ff),
      onTertiaryFixed: Color(0xff320047),
      tertiaryFixedDim: Color(0xffebb2ff),
      onTertiaryFixedVariant: Color(0xff672c80),
      surfaceDim: Color(0xffd8dae1),
      surfaceBright: Color(0xfff8f9ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff2f3fa),
      surfaceContainer: Color(0xffeceef4),
      surfaceContainerHigh: Color(0xffe6e8ef),
      surfaceContainerHighest: Color(0xffe0e2e9),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff003863),
      surfaceTint: Color(0xff0061a5),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff036cb7),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff1e3854),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff566f8e),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff54186e),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff8d50a6),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff8f9ff),
      onSurface: Color(0xff0e1116),
      onSurfaceVariant: Color(0xff303740),
      outline: Color(0xff4c535d),
      outlineVariant: Color(0xff676d78),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d3136),
      inversePrimary: Color(0xffa0caff),
      primaryFixed: Color(0xff1070bb),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff005795),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff566f8e),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff3e5674),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff9154aa),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff773b90),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc4c6cd),
      surfaceBright: Color(0xfff8f9ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff2f3fa),
      surfaceContainer: Color(0xffe6e8ef),
      surfaceContainerHigh: Color(0xffdbdde3),
      surfaceContainerHighest: Color(0xffcfd1d8),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff002d52),
      surfaceTint: Color(0xff0061a5),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff004b82),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff122d49),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff324b68),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff490963),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff6a2e83),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff8f9ff),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff262d36),
      outlineVariant: Color(0xff434a53),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d3136),
      inversePrimary: Color(0xffa0caff),
      primaryFixed: Color(0xff004b82),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff00345d),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff324b68),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff1a3450),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff6a2e83),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff51136a),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb6b9bf),
      surfaceBright: Color(0xfff8f9ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeff0f7),
      surfaceContainer: Color(0xffe0e2e9),
      surfaceContainerHigh: Color(0xffd2d4db),
      surfaceContainerHighest: Color(0xffc4c6cd),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffa0caff),
      surfaceTint: Color(0xffa0caff),
      onPrimary: Color(0xff003259),
      primaryContainer: Color(0xff036cb7),
      onPrimaryContainer: Color(0xffdfebff),
      secondary: Color(0xffafc8eb),
      onSecondary: Color(0xff18324e),
      secondaryContainer: Color(0xff324b68),
      onSecondaryContainer: Color(0xffa1badd),
      tertiary: Color(0xffebb2ff),
      onTertiary: Color(0xff4e1068),
      tertiaryContainer: Color(0xff8d50a6),
      onTertiaryContainer: Color(0xfffbe2ff),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff101418),
      onSurface: Color(0xffe0e2e9),
      onSurfaceVariant: Color(0xffc0c7d3),
      outline: Color(0xff8b919c),
      outlineVariant: Color(0xff414751),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e2e9),
      inversePrimary: Color(0xff0061a5),
      primaryFixed: Color(0xffd2e4ff),
      onPrimaryFixed: Color(0xff001c37),
      primaryFixedDim: Color(0xffa0caff),
      onPrimaryFixedVariant: Color(0xff00497e),
      secondaryFixed: Color(0xffd2e4ff),
      onSecondaryFixed: Color(0xff001c37),
      secondaryFixedDim: Color(0xffafc8eb),
      onSecondaryFixedVariant: Color(0xff304865),
      tertiaryFixed: Color(0xfff8d8ff),
      onTertiaryFixed: Color(0xff320047),
      tertiaryFixedDim: Color(0xffebb2ff),
      onTertiaryFixedVariant: Color(0xff672c80),
      surfaceDim: Color(0xff101418),
      surfaceBright: Color(0xff36393f),
      surfaceContainerLowest: Color(0xff0b0e13),
      surfaceContainerLow: Color(0xff181c21),
      surfaceContainer: Color(0xff1d2025),
      surfaceContainerHigh: Color(0xff272a2f),
      surfaceContainerHighest: Color(0xff32353a),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffc7deff),
      surfaceTint: Color(0xffa0caff),
      onPrimary: Color(0xff002747),
      primaryContainer: Color(0xff4894e2),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffc7deff),
      onSecondary: Color(0xff0a2742),
      secondaryContainer: Color(0xff7a93b3),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfff5d0ff),
      onTertiary: Color(0xff41005b),
      tertiaryContainer: Color(0xffb878d1),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff101418),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd6dde9),
      outline: Color(0xffacb2be),
      outlineVariant: Color(0xff8a919c),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e2e9),
      inversePrimary: Color(0xff004a80),
      primaryFixed: Color(0xffd2e4ff),
      onPrimaryFixed: Color(0xff001225),
      primaryFixedDim: Color(0xffa0caff),
      onPrimaryFixedVariant: Color(0xff003863),
      secondaryFixed: Color(0xffd2e4ff),
      onSecondaryFixed: Color(0xff001225),
      secondaryFixedDim: Color(0xffafc8eb),
      onSecondaryFixedVariant: Color(0xff1e3854),
      tertiaryFixed: Color(0xfff8d8ff),
      onTertiaryFixed: Color(0xff220031),
      tertiaryFixedDim: Color(0xffebb2ff),
      onTertiaryFixedVariant: Color(0xff54186e),
      surfaceDim: Color(0xff101418),
      surfaceBright: Color(0xff41454a),
      surfaceContainerLowest: Color(0xff05080c),
      surfaceContainerLow: Color(0xff1a1e23),
      surfaceContainer: Color(0xff25282d),
      surfaceContainerHigh: Color(0xff303338),
      surfaceContainerHighest: Color(0xff3b3e43),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffe9f0ff),
      surfaceTint: Color(0xffa0caff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xff98c6ff),
      onPrimaryContainer: Color(0xff000c1c),
      secondary: Color(0xffe9f0ff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffabc5e7),
      onSecondaryContainer: Color(0xff000c1c),
      tertiary: Color(0xfffeeaff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffe9acff),
      onTertiaryContainer: Color(0xff190025),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff101418),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffeaf0fd),
      outlineVariant: Color(0xffbdc3cf),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e2e9),
      inversePrimary: Color(0xff004a80),
      primaryFixed: Color(0xffd2e4ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffa0caff),
      onPrimaryFixedVariant: Color(0xff001225),
      secondaryFixed: Color(0xffd2e4ff),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffafc8eb),
      onSecondaryFixedVariant: Color(0xff001225),
      tertiaryFixed: Color(0xfff8d8ff),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffebb2ff),
      onTertiaryFixedVariant: Color(0xff220031),
      surfaceDim: Color(0xff101418),
      surfaceBright: Color(0xff4d5056),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1d2025),
      surfaceContainer: Color(0xff2d3136),
      surfaceContainerHigh: Color(0xff383c41),
      surfaceContainerHighest: Color(0xff44474c),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
  );

  List<ExtendedColor> get extendedColors => [];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
