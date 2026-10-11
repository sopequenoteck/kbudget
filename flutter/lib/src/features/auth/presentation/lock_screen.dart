// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/common_widgets/confirm_dialog_custom.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/pin_pad_sizes.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/biometric_authenticator.dart';
import 'package:k_budget/src/features/auth/presentation/widgets/pin_pad.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The screen that covers the app while it is locked (see `AppLockBarrier`).
///
/// A 4-digit PIN on a numeric pad, checked at the last digit. Biometric
/// unlock, when turned on, is offered when the screen shows and on the key at
/// the bottom left of the pad.
class LockScreen extends ConsumerStatefulWidget {
  /// Creates the lock screen.
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String Function(AppLocalizations l10n)? _message;
  var _biometricRunning = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(appLockNotifierProvider).biometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_unlockWithBiometrics()),
      );
    }
  }

  Future<void> _unlockWithBiometrics() async {
    if (_biometricRunning || !mounted) {
      return;
    }
    _biometricRunning = true;
    var unlocked = false;
    try {
      unlocked = await ref
          .read(appLockNotifierProvider.notifier)
          .unlockWithBiometrics();
    } finally {
      _biometricRunning = false;
    }
    if (!unlocked && mounted) {
      setState(() => _message = (l10n) => l10n.authFeedbackBiometricError);
    }
  }

  Future<void> _unlockWithPin(String pin) async {
    try {
      final result =
          await ref.read(appLockNotifierProvider.notifier).unlockWithPin(pin);
      if (result.isValid || !mounted) {
        return;
      }
      unawaited(HapticFeedback.heavyImpact());
      setState(
        () => _message =
            (l10n) => l10n.authFeedbackPinIncorrect(result.attemptsLeft),
      );
    } on Exception {
      // The attempt could not be recorded: the app stays locked.
      if (mounted) {
        setState(() => _message = (l10n) => l10n.commonFeedbackSaveError);
      }
    }
  }

  Future<void> _confirmForgotPin() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmDialogCustom.show(
      context: context,
      icon: PhosphorIconsRegular.signOut,
      title: l10n.authDialogForgotPinTitle,
      message: l10n.authDialogForgotPinMessage,
      confirmLabel: l10n.commonActionLogout,
      cancelLabel: l10n.commonActionCancel,
      variant: ConfirmVariant.danger,
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      // Resets the lock too, once the tokens are erased.
      await ref.read(authNotifierProvider.notifier).logout();
    } on Exception {
      if (mounted) {
        setState(() => _message = (l10n) => l10n.errorsClientGeneric);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final biometricEnabled = ref.watch(
      appLockNotifierProvider.select((state) => state.biometricEnabled),
    );
    final biometricKind = ref.watch(biometricKindProvider).valueOrNull ??
        BiometricKind.fingerprint;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: lockContentMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.lock,
                    size: lockIconSize,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text('K-Budget', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    l10n.authPageLockSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.space6),
                  PinEntry(
                    onCompleted: _unlockWithPin,
                    message: _message?.call(l10n),
                    onBiometric: biometricEnabled
                        ? () => unawaited(_unlockWithBiometrics())
                        : null,
                    biometricKind: biometricKind,
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize:
                          const Size(minTouchTarget, minTouchTarget),
                    ),
                    onPressed: () => unawaited(_confirmForgotPin()),
                    child: Text(l10n.authDialogForgotPinTitle),
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
