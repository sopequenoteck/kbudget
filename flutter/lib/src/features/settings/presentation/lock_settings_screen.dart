// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/page_header.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/application/biometric_authenticator.dart';
import 'package:k_budget/src/features/settings/presentation/lock_pin_screen.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Settings of the app lock: turn it on or off, biometric unlock, change PIN.
///
/// Every PIN is typed on a full-screen page pushed as a route
/// (`LockPinScreen`), never in a dialog.
class LockSettingsScreen extends ConsumerWidget {
  /// Creates the screen.
  const LockSettingsScreen({super.key});

  Future<void> _openPinFlow(BuildContext context, LockPinFlow flow) async {
    await context.push<bool>(
      '${RouteNames.settings}/${RouteNames.settingsLock}/'
      '${RouteNames.settingsLockPin.replaceFirst(':flow', flow.name)}',
    );
  }

  // A refusal by the system leaves the switch off, without a message; a
  // storage failure is reported.
  Future<void> _setBiometric(
    BuildContext context,
    WidgetRef ref, {
    required bool enabled,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorText = AppLocalizations.of(context)!.commonFeedbackSaveError;
    try {
      await ref
          .read(appLockNotifierProvider.notifier)
          .setBiometricEnabled(enabled: enabled);
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(errorText)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lock = ref.watch(appLockNotifierProvider);
    final biometricKind = ref.watch(biometricKindProvider).valueOrNull;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            PageHeader(
              title: l10n.settingsPageLockTitle,
              onBack: () => context.pop(),
              icon: const PhosphorIcon(PhosphorIconsRegular.lock, size: 16),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.settingsFormLockEnabled),
              subtitle: Text(l10n.settingsFormLockEnabledHint),
              value: lock.enabled,
              onChanged: (value) => unawaited(
                _openPinFlow(
                  context,
                  value ? LockPinFlow.enable : LockPinFlow.disable,
                ),
              ),
            ),
            if (lock.enabled) ...[
              if (biometricKind != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsFormLockBiometric),
                  subtitle: Text(l10n.settingsFormLockBiometricHint),
                  value: lock.biometricEnabled,
                  onChanged: (value) => unawaited(
                    _setBiometric(context, ref, enabled: value),
                  ),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsActionChangePin),
                trailing: PhosphorIcon(
                  PhosphorIconsRegular.caretRight,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onTap: () =>
                    unawaited(_openPinFlow(context, LockPinFlow.change)),
              ),
            ],
            const SizedBox(height: AppSpacing.space4),
            Text(
              l10n.settingsFormLockForgotHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: AppTypography.sizeXs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
