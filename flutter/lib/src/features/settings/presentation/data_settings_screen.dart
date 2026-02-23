import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/restart_widget.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/settings/application/data_settings_notifier.dart';

class DataSettingsScreen extends ConsumerStatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  ConsumerState<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends ConsumerState<DataSettingsScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    // Pre-fill URL from state after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serverUrl = ref.read(dataSettingsNotifierProvider).serverUrl;
      if (serverUrl != null) {
        _urlController.text = serverUrl;
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dataSettingsNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Données')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          // Source active
          Text(
            'Source de données',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<DataMode>(
              segments: const [
                ButtonSegment(
                  value: DataMode.local,
                  label: Text('Local'),
                  icon: Icon(Icons.phone_android),
                ),
                ButtonSegment(
                  value: DataMode.server,
                  label: Text('Serveur'),
                  icon: Icon(Icons.cloud),
                ),
              ],
              selected: {state.dataMode},
              onSelectionChanged: (selection) {
                final newMode = selection.first;
                if (newMode == state.dataMode) return;
                _onModeChanged(newMode, state);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.space6),

          // URL serveur
          Text(
            'URL du serveur',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://budget.kksdev.fr/api',
              prefixIcon: const Icon(Icons.link),
              errorText: state.error,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            onChanged: (_) {
              if (state.error != null) ref.read(dataSettingsNotifierProvider.notifier).clearError();
            },
          ),
          const SizedBox(height: AppSpacing.space3),
          FilledButton.icon(
            onPressed: state.isLoading ? null : _onSaveUrl,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),

          if (state.isLoading) ...[
            const SizedBox(height: AppSpacing.space4),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  void _onSaveUrl() {
    final notifier = ref.read(dataSettingsNotifierProvider.notifier);
    final url = _urlController.text.trim();
    final validationError = notifier.validateUrl(url);
    if (validationError != null) {
      // Set error manually via state update
      ref.read(dataSettingsNotifierProvider.notifier).clearError();
      // Force rebuild with error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }
    notifier.saveServerUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL enregistrée')),
    );
  }

  Future<void> _onModeChanged(
    DataMode newMode,
    DataSettingsState state,
  ) async {
    // Validate URL if switching to server
    if (newMode == DataMode.server) {
      final url = _urlController.text.trim();
      final notifier = ref.read(dataSettingsNotifierProvider.notifier);
      final validationError = notifier.validateUrl(url);
      if (validationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationError)),
        );
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer de source ?'),
        content: const Text(
          'Les sources de données sont indépendantes. '
          'Les données de la source actuelle ne seront pas visibles '
          'après le changement.\n\n'
          "L'application va redémarrer pour appliquer la nouvelle source.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // If switching to server, check connectivity
    if (newMode == DataMode.server) {
      final url = _urlController.text.trim();
      final n = ref.read(dataSettingsNotifierProvider.notifier);
      await n.saveServerUrl(url);
      final isReachable = await n.checkConnectivity(url);
      if (!isReachable || !mounted) return;
    }

    await ref.read(dataSettingsNotifierProvider.notifier).switchDataMode(newMode);
    if (mounted) {
      RestartWidget.restartApp(context);
    }
  }
}
