// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:k_budget/src/common_widgets/page_header.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/pin_pad_sizes.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/presentation/widgets/pin_pad.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// What the PIN screen of the settings does with the PINs typed.
enum LockPinFlow {
  /// Choose a PIN, confirm it, then turn the lock on.
  enable,

  /// Ask for the current PIN, then choose and confirm a new one.
  change,

  /// Ask for the current PIN, then turn the lock off.
  disable,
}

enum _Step { current, choose, confirm }

/// Full-screen PIN entry of the lock settings, pushed as a route of its own.
///
/// It pops `true` once the flow is done. The current PIN is checked by the
/// same counter as on the lock screen: the settings cannot be used to guess
/// it, and the last wrong entry signs the user out.
class LockPinScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [flow].
  const LockPinScreen({required this.flow, super.key});

  /// What to do with the PINs typed.
  final LockPinFlow flow;

  @override
  ConsumerState<LockPinScreen> createState() => _LockPinScreenState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<LockPinFlow>('flow', flow));
  }
}

class _LockPinScreenState extends ConsumerState<LockPinScreen> {
  late _Step _step = widget.flow == LockPinFlow.enable
      ? _Step.choose
      : _Step.current;
  String? _currentPin;
  String? _chosenPin;
  String Function(AppLocalizations l10n)? _message;

  AppLockNotifier get _lock => ref.read(appLockNotifierProvider.notifier);

  Future<void> _onPin(String pin) async {
    try {
      switch (_step) {
        case _Step.current:
          await _onCurrentPin(pin);
        case _Step.choose:
          setState(() {
            _chosenPin = pin;
            _step = _Step.confirm;
            _message = null;
          });
        case _Step.confirm:
          await _onConfirmedPin(pin);
      }
    } on Exception {
      if (mounted) {
        setState(() => _message = (l10n) => l10n.commonFeedbackSaveError);
      }
    }
  }

  Future<void> _onCurrentPin(String pin) async {
    if (widget.flow == LockPinFlow.disable) {
      final result = await _lock.disable(pin);
      _finishOrReject(result);
      return;
    }
    final result = await _lock.verifyPin(pin);
    if (!result.isValid || !mounted) {
      _finishOrReject(result);
      return;
    }
    setState(() {
      _currentPin = pin;
      _step = _Step.choose;
      _message = null;
    });
  }

  Future<void> _onConfirmedPin(String pin) async {
    if (pin != _chosenPin) {
      setState(() {
        _chosenPin = null;
        _step = _Step.choose;
        _message = (l10n) => l10n.settingsFeedbackPinMismatch;
      });
      return;
    }
    if (widget.flow == LockPinFlow.enable) {
      await _lock.enable(pin);
      _done();
      return;
    }
    final result = await _lock.changePin(_currentPin!, pin);
    _finishOrReject(result);
  }

  void _finishOrReject(PinCheckResult result) {
    if (result.isValid) {
      _done();
    } else if (mounted) {
      setState(
        () =>
            _message = (l10n) =>
                l10n.authFeedbackPinIncorrect(result.attemptsLeft),
      );
    }
  }

  void _done() {
    _currentPin = null;
    _chosenPin = null;
    if (mounted) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prompt = switch (_step) {
      _Step.current => l10n.settingsFormPinCurrent,
      _Step.choose => l10n.settingsFormPinChoose,
      _Step.confirm => l10n.settingsFormPinConfirm,
    };
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            children: [
              PageHeader(
                title: l10n.settingsPageLockTitle,
                onBack: () => context.pop(),
                icon: const PhosphorIcon(PhosphorIconsRegular.lock, size: 16),
              ),
              const SizedBox(height: AppSpacing.space6),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: lockContentMaxWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        prompt,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.space6),
                      PinEntry(
                        key: ValueKey(_step),
                        onCompleted: _onPin,
                        message: _message?.call(l10n),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
