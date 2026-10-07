// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/routing/route_names.dart';
import 'package:local_auth/local_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pinController = TextEditingController();
  final _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _attemptBiometric();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _attemptBiometric() async {
    final config = await ref
        .read(onboardingNotifierProvider.notifier)
        .getConfig();

    if (config.lockMethod != LockMethod.biometric) return;
    if (!mounted) {
      return;
    }

    // Recupere apres le premier await : lu depuis initState(), l'appeler
    // plus tot leverait "dependOnInheritedWidgetOfExactType() ... called
    // before initState() completed" (le widget n'est pas encore monte).
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: l10n.authActionUnlockBiometricReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated && mounted) {
        context.go(RouteNames.dashboard);
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          _error = l10n.authFeedbackBiometricError;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  Future<void> _validatePin() async {
    final l10n = AppLocalizations.of(context)!;
    if (_pinController.text.length < 4) {
      setState(() => _error = l10n.authFormPinMinLength);
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    final config = await ref
        .read(onboardingNotifierProvider.notifier)
        .getConfig();

    final hashedInput =
        sha256.convert(utf8.encode(_pinController.text)).toString();

    if (hashedInput == config.hashedPin) {
      if (mounted) {
        context.go(RouteNames.dashboard);
      }
    } else {
      if (mounted) {
        setState(() {
          _error = l10n.authFeedbackPinIncorrect;
          _isAuthenticating = false;
        });
        _pinController.clear();
      }
    }
  }

  Future<void> _handleForgotPin() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.authDialogForgotPinTitle),
        content: Text(l10n.authDialogForgotPinServerMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonActionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.commonActionLogout),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) {
        context.go(RouteNames.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.lock,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(
                    'K-Budget',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    l10n.authPagePinTagline,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.space8),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: '****',
                      counterText: '',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                    onSubmitted: (_) => _validatePin(),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  if (_error != null)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.space4),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  FilledButton(
                    onPressed: _isAuthenticating ? null : _validatePin,
                    child: _isAuthenticating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.authActionUnlock),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed:
                            _isAuthenticating ? null : _handleForgotPin,
                        child: Text(l10n.authDialogForgotPinTitle),
                      ),
                      TextButton.icon(
                        onPressed:
                            _isAuthenticating ? null : _attemptBiometric,
                        icon: const PhosphorIcon(PhosphorIconsRegular.fingerprint, size: 20),
                        label: Text(l10n.authActionBiometric),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
