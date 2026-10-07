// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/page_header.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
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
}
