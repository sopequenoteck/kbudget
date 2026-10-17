// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/confirm_dialog_custom.dart';
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
      // The notifier outlives the screen: drop the error of a previous visit.
      ref.read(dataSettingsNotifierProvider.notifier).clearError();
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
              title: l10n.settingsPageServerTitle,
              onBack: () => context.pop(),
              icon: const PhosphorIcon(
                PhosphorIconsRegular.hardDrives,
                size: 16,
              ),
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
                hintText: 'https://budget.example.com/api',
                prefixIcon: const PhosphorIcon(PhosphorIconsRegular.link, size: 20),
                errorText: state.error,
                errorMaxLines: 3,
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

  Future<void> _onSaveUrl() async {
    final notifier = ref.read(dataSettingsNotifierProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final url = _urlController.text.trim();
    final validationError = notifier.validateUrl(url);
    if (validationError != null) {
      messenger.showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }
    final currentUrl = ref.read(dataSettingsNotifierProvider).serverUrl;
    // A trailing slash is not another server: no need to sign out.
    if (currentUrl != null &&
        _withoutTrailingSlash(url) == _withoutTrailingSlash(currentUrl)) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsFeedbackServerUrlSaved)),
      );
      return;
    }
    final confirmed = await ConfirmDialogCustom.show(
      context: context,
      icon: PhosphorIconsRegular.warning,
      title: l10n.settingsDialogChangeServerTitle,
      message: l10n.settingsDialogChangeServerMessage,
      confirmLabel: l10n.commonActionConfirm,
    );
    if (confirmed != true) {
      return;
    }
    // On success the router redirects to sign-in; on failure the error shows
    // under the field.
    await notifier.changeServerUrl(url);
  }
}

String _withoutTrailingSlash(String url) =>
    url.endsWith('/') ? url.substring(0, url.length - 1) : url;
