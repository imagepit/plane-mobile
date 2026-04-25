import 'package:flutter/material.dart';

class AppColorScheme {
  AppColorScheme._();

  static const Color lightPrimary = Color(0xFF3B76E1);
  static const Color lightOnPrimary = Colors.white;
  static const Color lightPrimaryContainer = Color(0xFFD6E3FF);
  static const Color lightOnPrimaryContainer = Color(0xFF001B3E);
  static const Color lightSecondary = Color(0xFF535FC6);
  static const Color lightOnSecondary = Colors.white;
  static const Color lightSecondaryContainer = Color(0xFFE0E0FF);
  static const Color lightOnSecondaryContainer = Color(0xFF111476);
  static const Color lightTertiary = Color(0xFF6B5778);
  static const Color lightOnTertiary = Colors.white;
  static const Color lightTertiaryContainer = Color(0xFFF3DAFF);
  static const Color lightOnTertiaryContainer = Color(0xFF261430);
  static const Color lightError = Color(0xFFBA1A1A);
  static const Color lightOnError = Colors.white;
  static const Color lightBackground = Color(0xFFFAFCFF);
  static const Color lightOnBackground = Color(0xFF1A1C1E);
  static const Color lightSurface = Color(0xFFFAFCFF);
  static const Color lightOnSurface = Color(0xFF1A1C1E);
  static const Color lightSurfaceVariant = Color(0xFFE0E2EC);
  static const Color lightOnSurfaceVariant = Color(0xFF434750);
  static const Color lightOutline = Color(0xFF737784);
  static const Color lightOutlineVariant = Color(0xFFC3C6D0);

  static const Color darkPrimary = Color(0xFF6B9EFF);
  static const Color darkOnPrimary = Color(0xFF002E5E);
  static const Color darkPrimaryContainer = Color(0xFF004386);
  static const Color darkOnPrimaryContainer = Color(0xFFD6E3FF);
  static const Color darkSecondary = Color(0xFFBFC2FF);
  static const Color darkOnSecondary = Color(0xFF292F82);
  static const Color darkSecondaryContainer = Color(0xFF40459A);
  static const Color darkOnSecondaryContainer = Color(0xFFE0E0FF);
  static const Color darkTertiary = Color(0xFFD7BEE4);
  static const Color darkOnTertiary = Color(0xFF3C2D47);
  static const Color darkTertiaryContainer = Color(0xFF53435E);
  static const Color darkOnTertiaryContainer = Color(0xFFF3DAFF);
  static const Color darkError = Color(0xFFFFB4AB);
  static const Color darkOnError = Color(0xFF690005);
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkOnBackground = Color(0xFFE3E2E6);
  static const Color darkSurface = Color(0xFF0F0F1A);
  static const Color darkOnSurface = Color(0xFFE3E2E6);
  static const Color darkSurfaceVariant = Color(0xFF434750);
  static const Color darkOnSurfaceVariant = Color(0xFFC3C6D0);
  static const Color darkOutline = Color(0xFF8D9099);
  static const Color darkOutlineVariant = Color(0xFF434750);

  static final lightColorScheme = ColorScheme.light(
    primary: lightPrimary,
    onPrimary: lightOnPrimary,
    primaryContainer: lightPrimaryContainer,
    onPrimaryContainer: lightOnPrimaryContainer,
    secondary: lightSecondary,
    onSecondary: lightOnSecondary,
    secondaryContainer: lightSecondaryContainer,
    onSecondaryContainer: lightOnSecondaryContainer,
    tertiary: lightTertiary,
    onTertiary: lightOnTertiary,
    tertiaryContainer: lightTertiaryContainer,
    onTertiaryContainer: lightOnTertiaryContainer,
    error: lightError,
    onError: lightOnError,
    background: lightBackground,
    onBackground: lightOnBackground,
    surface: lightSurface,
    onSurface: lightOnSurface,
    surfaceVariant: lightSurfaceVariant,
    onSurfaceVariant: lightOnSurfaceVariant,
    outline: lightOutline,
    outlineVariant: lightOutlineVariant,
  );

  static final darkColorScheme = ColorScheme.dark(
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    primaryContainer: darkPrimaryContainer,
    onPrimaryContainer: darkOnPrimaryContainer,
    secondary: darkSecondary,
    onSecondary: darkOnSecondary,
    secondaryContainer: darkSecondaryContainer,
    onSecondaryContainer: darkOnSecondaryContainer,
    tertiary: darkTertiary,
    onTertiary: darkOnTertiary,
    tertiaryContainer: darkTertiaryContainer,
    onTertiaryContainer: darkOnTertiaryContainer,
    error: darkError,
    onError: darkOnError,
    background: darkBackground,
    onBackground: darkOnBackground,
    surface: darkSurface,
    onSurface: darkOnSurface,
    surfaceVariant: darkSurfaceVariant,
    onSurfaceVariant: darkOnSurfaceVariant,
    outline: darkOutline,
    outlineVariant: darkOutlineVariant,
  );
}