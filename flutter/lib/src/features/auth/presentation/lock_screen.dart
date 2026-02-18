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
import 'package:k_budget/src/routing/route_names.dart';
import 'package:local_auth/local_auth.dart';

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

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Deverrouillez K-Budget',
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
          _error = 'Erreur biometrique. Utilisez votre PIN.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  Future<void> _validatePin() async {
    if (_pinController.text.length < 4) {
      setState(() => _error = 'Le PIN doit contenir au moins 4 chiffres');
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
          _error = 'PIN incorrect';
          _isAuthenticating = false;
        });
        _pinController.clear();
      }
    }
  }

  Future<void> _handleForgotPin() async {
    final config = await ref
        .read(onboardingNotifierProvider.notifier)
        .getConfig();

    if (!mounted) return;

    if (config.dataMode == DataMode.server) {
      // Server mode: logout and re-login
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PIN oublie ?'),
          content: const Text(
            'Vous serez deconnecte et devrez vous reconnecter '
            'avec vos identifiants.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Se deconnecter'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await ref.read(authNotifierProvider.notifier).logout();
        if (mounted) context.go(RouteNames.login);
      }
    } else {
      // Local mode: reset data
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PIN oublie ?'),
          content: const Text(
            'En mode local, la reinitialisation du PIN effacera '
            'toutes vos donnees. Cette action est irreversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reinitialiser'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        // Reset lock settings
        final notifier = ref.read(onboardingNotifierProvider.notifier);
        await notifier.updateLockSettings(
          enabled: false,
          method: null,
          pin: null,
        );
        if (mounted) context.go(RouteNames.dashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Icon(
                    Icons.lock_outlined,
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
                    'Saisissez votre PIN pour continuer',
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
                        : const Text('Deverrouiller'),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed:
                            _isAuthenticating ? null : _handleForgotPin,
                        child: const Text('PIN oublie ?'),
                      ),
                      TextButton.icon(
                        onPressed:
                            _isAuthenticating ? null : _attemptBiometric,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Biometrie'),
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
