import 'package:flutter/material.dart';
import 'package:plane_mobile/core/theme/color_scheme.dart' as app_colors;
import 'package:plane_mobile/core/theme/typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: app_colors.AppColorScheme.lightColorScheme,
        textTheme: AppTypography.light,
        brightness: Brightness.light,
        scaffoldBackgroundColor: app_colors.AppColorScheme.lightBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: app_colors.AppColorScheme.lightSurface,
          foregroundColor: app_colors.AppColorScheme.lightOnSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: AppTypography.light.titleLarge?.copyWith(
            color: app_colors.AppColorScheme.lightOnSurface,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: app_colors.AppColorScheme.lightSurface,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: app_colors.AppColorScheme.lightPrimary,
          foregroundColor: app_colors.AppColorScheme.lightOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: app_colors.AppColorScheme.lightSurfaceVariant.withAlpha(50),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: app_colors.AppColorScheme.lightOutline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: app_colors.AppColorScheme.lightOutline.withAlpha(100),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: app_colors.AppColorScheme.lightPrimary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: app_colors.AppColorScheme.lightError,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: app_colors.AppColorScheme.lightPrimaryContainer,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: app_colors.AppColorScheme.darkColorScheme,
        textTheme: AppTypography.dark,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: app_colors.AppColorScheme.darkBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: app_colors.AppColorScheme.darkSurface,
          foregroundColor: app_colors.AppColorScheme.darkOnSurface,
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
          titleTextStyle: AppTypography.dark.titleLarge?.copyWith(
            color: app_colors.AppColorScheme.darkOnSurface,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: app_colors.AppColorScheme.darkSurfaceVariant.withAlpha(80),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: app_colors.AppColorScheme.darkPrimary,
          foregroundColor: app_colors.AppColorScheme.darkOnPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: app_colors.AppColorScheme.darkSurfaceVariant.withAlpha(50),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: app_colors.AppColorScheme.darkOutline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: app_colors.AppColorScheme.darkOutline.withAlpha(100),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: app_colors.AppColorScheme.darkPrimary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: app_colors.AppColorScheme.darkError,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: app_colors.AppColorScheme.darkPrimaryContainer,
        ),
      );
}