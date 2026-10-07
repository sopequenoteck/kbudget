// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ServerSetupScreen extends ConsumerStatefulWidget {
  const ServerSetupScreen({super.key});

  @override
  ConsumerState<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends ConsumerState<ServerSetupScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingPageServerSetupTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.onboardingFormServerUrlHint,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.space6),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: l10n.onboardingFormServerUrl,
                  hintText: 'https://budget.example.com/api',
                  prefixIcon: const PhosphorIcon(
                    PhosphorIconsRegular.link,
                    size: 20,
                  ),
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.onboardingFormServerUrlRequired;
                  }
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                    return l10n.onboardingFormServerUrlInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.space4),
              if (state.isServerReachable)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsFill.checkCircle,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Text(
                        l10n.onboardingFeedbackConnected,
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              if (state.error != null && !state.isCheckingServer)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.warning,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.space6),
              OutlinedButton.icon(
                onPressed: state.isCheckingServer
                    ? null
                    : () => _checkConnection(),
                icon: state.isCheckingServer
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const PhosphorIcon(PhosphorIconsRegular.wifiHigh, size: 20),
                label: Text(
                  state.isCheckingServer
                      ? l10n.onboardingFeedbackConnecting
                      : l10n.onboardingActionCheckConnection,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: state.isServerReachable && !state.isSaving
                    ? _onConfirm
                    : null,
                child: state.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.commonActionConfirm),
              ),
              const SizedBox(height: AppSpacing.space4),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onConfirm() async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    await notifier.completeOnboarding();
    if (mounted && ref.read(onboardingNotifierProvider).isCompleted) {
      context.go(RouteNames.dashboard);
    }
  }

  Future<void> _checkConnection() async {
    if (!_formKey.currentState!.validate()) return;
    final url = _urlController.text.trim();
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    notifier.setServerUrl(url);
    await notifier.checkServerConnectivity(url);
  }
}
