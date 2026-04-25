import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:plane_mobile/core/di/injection.dart';
import 'package:plane_mobile/core/storage/local_storage.dart';
import 'package:plane_mobile/presentation/blocs/settings/settings_bloc.dart';
import 'package:plane_mobile/presentation/widgets/settings/server_config_form.dart';

class ServerConfigPage extends StatelessWidget {
  const ServerConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsBloc(
        localStorage: sl<LocalStorage>(),
        dioClient: sl(),
      )..add(LoadSettings()),
      child: const ServerConfigView(),
    );
  }
}

class ServerConfigView extends StatelessWidget {
  const ServerConfigView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final brightness = Theme.of(context).brightness;
              final newMode = brightness == Brightness.dark ? 'light' : 'dark';
              context.read<SettingsBloc>().add(ChangeTheme(themeMode: newMode));
            },
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsConfigured) {
            context.go('/workspaces');
          }
        },
        builder: (context, state) {
          return switch (state) {
            SettingsLoading() => const Center(child: CircularProgressIndicator()),
            SettingsUnconfigured() => ServerConfigForm(
                initialUrl: state.lastUrl,
              ),
            SettingsConfigured() => const Center(child: CircularProgressIndicator()),
            SettingsConnectionSuccess(:final url, :final apiToken) => _buildConnectedView(context, state.userName),
            SettingsConnectionFailure(:final url, :final apiToken, :final error) => ServerConfigForm(
                initialUrl: url,
                initialToken: apiToken,
                initialError: error,
              ),
            SettingsTestingConnection() => const Center(child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Testing connection...'),
                ],
              )),
            SettingsError(:final message) => ServerConfigForm(
                initialError: message,
              ),
            _ => ServerConfigForm(),
          };
        },
      ),
    );
  }

  Widget _buildConnectedView(BuildContext context, String userName) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'Connected as $userName',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/workspaces'),
            child: const Text('Continue'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(ResetSettings());
            },
            child: const Text('Change server'),
          ),
        ],
      ),
    );
  }
}