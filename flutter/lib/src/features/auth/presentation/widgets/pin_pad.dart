// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:k_budget/src/constants/app_durations.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/constants/pin_pad_sizes.dart';
import 'package:k_budget/src/features/auth/application/app_lock_notifier.dart';
import 'package:k_budget/src/features/auth/application/biometric_authenticator.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Progress dots of a PIN being typed: outline when empty, filled with the
/// primary color when typed. They announce how many digits were typed, never
/// which ones.
class PinDots extends StatelessWidget {
  /// Creates the dots, [filled] of them typed.
  const PinDots({required this.filled, super.key});

  /// Number of digits typed so far.
  final int filled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final duration = AppDurations.resolve(AppDurations.fast, context);
    return Semantics(
      label: AppLocalizations.of(context)!.authFormPinProgressAria(filled),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < pinLength; i++) ...[
            if (i > 0) const SizedBox(width: pinDotGap),
            AnimatedContainer(
              duration: duration,
              width: pinDotSize,
              height: pinDotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? colors.primary : Colors.transparent,
                border: Border.all(
                  color: i < filled ? colors.primary : colors.onSurfaceVariant,
                  width: pinDotOutline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('filled', filled));
  }
}

/// The 3 x 4 numeric pad: digits 1 to 9, then the biometric key (an empty
/// slot when [onBiometric] is `null`), 0 and delete.
class PinPad extends StatelessWidget {
  /// Creates the pad.
  const PinPad({
    required this.onDigit,
    required this.onDelete,
    this.onBiometric,
    this.biometricKind = BiometricKind.fingerprint,
    super.key,
  });

  /// Called with the digit (`'0'` to `'9'`) of the tapped key.
  final ValueChanged<String> onDigit;

  /// Called when the delete key is tapped.
  final VoidCallback onDelete;

  /// Called when the biometric key is tapped. `null` hides the key.
  final VoidCallback? onBiometric;

  /// The kind of biometric, to pick the icon of the biometric key.
  final BiometricKind biometricKind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ]) ...[
          _PinRow(
            children: [for (final digit in row) _digitKey(context, digit)],
          ),
          const SizedBox(height: pinKeyGap),
        ],
        _PinRow(
          children: [
            if (onBiometric == null)
              const SizedBox(width: pinKeySize, height: pinKeySize)
            else
              _PinKey(
                label: l10n.authActionBiometricAria,
                onTap: onBiometric,
                child: PhosphorIcon(
                  biometricKind == BiometricKind.face
                      ? PhosphorIconsRegular.scanSmiley
                      : PhosphorIconsRegular.fingerprint,
                  size: pinKeyIconSize,
                  color: colors.primary,
                ),
              ),
            _digitKey(context, '0'),
            _PinKey(
              label: l10n.authActionPinDeleteAria,
              onTap: onDelete,
              child: PhosphorIcon(
                PhosphorIconsRegular.backspace,
                size: pinKeyIconSize,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _digitKey(BuildContext context, String digit) => _PinKey(
    label: digit,
    onTap: () => onDigit(digit),
    child: Text(digit, style: Theme.of(context).textTheme.titleLarge),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<ValueChanged<String>>.has('onDigit', onDigit))
      ..add(ObjectFlagProperty<VoidCallback>.has('onDelete', onDelete))
      ..add(ObjectFlagProperty<VoidCallback>.has('onBiometric', onBiometric))
      ..add(EnumProperty<BiometricKind>('biometricKind', biometricKind));
  }
}

class _PinRow extends StatelessWidget {
  const _PinRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: pinKeyGap),
        children[i],
      ],
    ],
  );
}

class _PinKey extends StatelessWidget {
  const _PinKey({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback? onTap;
  final Widget child;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background =
        theme.extension<AppThemeExtension>()?.iconCircleBg ??
        theme.colorScheme.surfaceContainerHighest;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: SizedBox(
        width: pinKeySize,
        height: pinKeySize,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// A PIN typed on the pad: dots, an optional message and the pad.
///
/// The digits live in this widget only. At the [pinLength]th digit,
/// [onCompleted] is called with the PIN, then the dots are emptied; input is
/// ignored while it runs. [onCompleted] must report its own failures.
class PinEntry extends StatefulWidget {
  /// Creates the entry.
  const PinEntry({
    required this.onCompleted,
    this.message,
    this.onBiometric,
    this.biometricKind = BiometricKind.fingerprint,
    super.key,
  });

  /// Called with the PIN once it is complete.
  final Future<void> Function(String pin) onCompleted;

  /// A message in the error color between the dots and the pad, such as the
  /// attempts left.
  final String? message;

  /// Called when the biometric key is tapped. `null` hides the key.
  final VoidCallback? onBiometric;

  /// The kind of biometric, to pick the icon of the biometric key.
  final BiometricKind biometricKind;

  @override
  State<PinEntry> createState() => _PinEntryState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<Future<void> Function(String)>.has(
          'onCompleted',
          onCompleted,
        ),
      )
      ..add(StringProperty('message', message))
      ..add(ObjectFlagProperty<VoidCallback>.has('onBiometric', onBiometric))
      ..add(EnumProperty<BiometricKind>('biometricKind', biometricKind));
  }
}

class _PinEntryState extends State<PinEntry> {
  var _pin = '';
  var _busy = false;

  void _onDigit(String digit) {
    if (_busy || _pin.length >= pinLength) {
      return;
    }
    setState(() => _pin += digit);
    if (_pin.length == pinLength) {
      unawaited(_complete());
    }
  }

  void _onDelete() {
    if (_busy || _pin.isEmpty) {
      return;
    }
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _complete() async {
    final pin = _pin;
    _busy = true;
    try {
      await widget.onCompleted(pin);
    } finally {
      if (mounted) {
        setState(() {
          _pin = '';
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor =
        theme.extension<AppThemeExtension>()?.expenseColor ??
        theme.colorScheme.error;
    final message = widget.message;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PinDots(filled: _pin.length),
        const SizedBox(height: AppSpacing.space3),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: pinMessageMinHeight),
          child: message == null
              ? null
              : Semantics(
                  liveRegion: true,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: errorColor,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.space3),
        PinPad(
          onDigit: _onDigit,
          onDelete: _onDelete,
          onBiometric: widget.onBiometric,
          biometricKind: widget.biometricKind,
        ),
      ],
    );
  }
}
