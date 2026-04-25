import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/core/router/app_router.dart';
import 'package:plane_mobile/core/theme/app_theme.dart';
import 'package:plane_mobile/core/storage/local_storage.dart';
import 'package:plane_mobile/presentation/blocs/settings/settings_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsBloc>()..add(LoadSettings()),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          ThemeMode themeMode = ThemeMode.system;
          if (state is SettingsConfigured) {
            final mode = sl<LocalStorage>().themeMode;
            themeMode = switch (mode) {
              'dark' => ThemeMode.dark,
              'light' => ThemeMode.light,
              _ => ThemeMode.system,
            };
          }

          return MaterialApp.router(
            title: 'Plane',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}