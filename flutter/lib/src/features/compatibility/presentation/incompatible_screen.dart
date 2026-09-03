// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/data/remote/compatibility_provider.dart';
import 'package:k_budget/src/domain/models/server_meta.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Ecran affiche quand cette application et le serveur configure ne peuvent pas
/// fonctionner ensemble (KKS-314).
///
/// Sa raison d'etre : sans lui, l'incompatibilite se manifeste par une erreur
/// de
/// deserialisation JSON, chez un utilisateur qui n'a aucun moyen de comprendre
/// que son serveur est en cause. Le message nomme donc le responsable et
/// l'action, jamais l'erreur technique.
///
/// N'est jamais affiche pour un serveur injoignable : hors ligne n'est pas une
/// incompatibilite.
class IncompatibleScreen extends ConsumerWidget {
  const IncompatibleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(compatibilityNotifierProvider);
    final theme = Theme.of(context);
    final isClientTooOld = status is CompatibilityClientTooOld;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.warning,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                isClientTooOld
                    ? 'Application a mettre a jour'
                    : 'Serveur a mettre a jour',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(_message(status), style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.space6),
              FilledButton(
                onPressed: () {
                  ref.read(compatibilityNotifierProvider.notifier).reset();
                },
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _message(CompatibilityStatus? status) =>
      status?.userMessage(verbose: true) ??
      'Cette application et votre serveur ne peuvent pas fonctionner ensemble.';
}
