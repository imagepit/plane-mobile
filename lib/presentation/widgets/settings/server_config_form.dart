import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plane_mobile/presentation/blocs/settings/settings_bloc.dart';

class ServerConfigForm extends StatefulWidget {
  final String? initialUrl;
  final String? initialSlug;
  final String? initialToken;
  final String? initialError;

  const ServerConfigForm({
    super.key,
    this.initialUrl,
    this.initialSlug,
    this.initialToken,
    this.initialError,
  });

  @override
  State<ServerConfigForm> createState() => _ServerConfigFormState();
}

class _ServerConfigFormState extends State<ServerConfigForm> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _slugController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
    }
    if (widget.initialSlug != null) {
      _slugController.text = widget.initialSlug!;
    }
    if (widget.initialToken != null) {
      _tokenController.text = widget.initialToken!;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _slugController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.flight_takeoff,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Plane Mobile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to your Plane self-hosted instance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://your-plane-instance.com',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your server URL';
                }
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'URL must start with http:// or https://';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(
                labelText: 'Workspace Slug',
                hintText: 'e.g. my-workspace',
                prefixIcon: Icon(Icons.workspaces_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your workspace slug';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tokenController,
              obscureText: _obscureToken,
              decoration: InputDecoration(
                labelText: 'API Token',
                hintText: 'Your Plane API token',
                prefixIcon: const Icon(Icons.key),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureToken ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureToken = !_obscureToken),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your API token';
                }
                return null;
              },
              autovalidateMode: AutovalidateMode.onUserInteraction,
            ),
            const SizedBox(height: 16),
            if (widget.initialError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  widget.initialError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton.icon(
              onPressed: _testConnection,
              icon: const Icon(Icons.wifi_find),
              label: const Text('Test Connection'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _saveAndContinue,
              icon: const Icon(Icons.login),
              label: const Text('Save & Connect'),
            ),
          ],
        ),
      ),
    );
  }

  void _testConnection() {
    if (_formKey.currentState!.validate()) {
      context.read<SettingsBloc>().add(TestConnection(
            url: _urlController.text.trim(),
            workspaceSlug: _slugController.text.trim(),
            apiToken: _tokenController.text.trim(),
          ));
    }
  }

  void _saveAndContinue() {
    if (_formKey.currentState!.validate()) {
      context.read<SettingsBloc>().add(SaveSettings(
            url: _urlController.text.trim(),
            workspaceSlug: _slugController.text.trim(),
            apiToken: _tokenController.text.trim(),
          ));
    }
  }
}