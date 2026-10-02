// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/confirm_dialog_custom.dart';
import 'package:k_budget/src/common_widgets/page_header.dart';
import 'package:k_budget/src/common_widgets/restart_widget.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/settings/application/data_settings_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            PageHeader(
              title: l10n.settingsPageDataTitle,
              onBack: () => context.pop(),
              icon: const PhosphorIcon(PhosphorIconsRegular.database, size: 16),
            ),

            // Source active
            Text(
              l10n.settingsFormDataSource.toUpperCase(),
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.medium,
                letterSpacing: AppTypography.labelLetterSpacingForSize12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<DataMode>(
                segments: [
                  ButtonSegment(
                    value: DataMode.local,
                    label: Text(l10n.settingsValueDataSourceLocal),
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.deviceMobile,
                      size: 20,
                    ),
                  ),
                  ButtonSegment(
                    value: DataMode.server,
                    label: Text(l10n.settingsValueDataSourceServer),
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.cloud,
                      size: 20,
                    ),
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
              l10n.settingsFormServerUrl.toUpperCase(),
              style: TextStyle(
                fontSize: AppTypography.sizeXs,
                fontWeight: AppTypography.medium,
                letterSpacing: AppTypography.labelLetterSpacingForSize12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://budget.kksdev.fr/api',
                prefixIcon: const PhosphorIcon(PhosphorIconsRegular.link, size: 20),
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
              icon: const PhosphorIcon(PhosphorIconsRegular.floppyDisk, size: 20),
              label: Text(l10n.commonActionSave),
            ),

            if (state.isLoading) ...[
              const SizedBox(height: AppSpacing.space4),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
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
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.settingsFeedbackServerUrlSaved,
        ),
      ),
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

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmDialogCustom.show(
      context: context,
      icon: PhosphorIconsRegular.arrowsLeftRight,
      title: l10n.settingsDialogChangeDataSourceTitle,
      message: l10n.settingsDialogChangeDataSourceMessage,
      confirmLabel: l10n.commonActionConfirm,
      variant: ConfirmVariant.primary,
    ) ?? false;

    if (!confirmed || !mounted) return;

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
