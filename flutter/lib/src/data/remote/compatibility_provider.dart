// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/remote/compatibility_service.dart';
import 'package:k_budget/src/domain/models/server_meta.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/utils/env_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Verdict de compatibilite du serveur configure, memorise pour la session
/// (KKS-314).
///
/// Le routeur consulte cet etat a chaque redirection : refaire l'appel reseau a
/// chaque navigation ajouterait une latence sur chaque transition, pour une
/// information qui ne change pas tant que l'application n'est pas relancee.
class CompatibilityNotifier extends Notifier<CompatibilityStatus?> {
  @override
  CompatibilityStatus? build() => null;

  /// Verifie une fois par session. Les appels suivants renvoient le verdict
  /// connu.
  Future<CompatibilityStatus> ensureChecked() async {
    final known = state;
    if (known != null) {
      return known;
    }

    final serverUrl =
        await ref.read(appConfigRepositoryProvider).getServerUrl() ??
        EnvConfig.apiBaseUrl;
    final info = await PackageInfo.fromPlatform();

    final status = await ref
        .read(compatibilityServiceProvider)
        .check(baseUrl: serverUrl, clientVersion: info.version);

    state = status;
    return status;
  }

  /// Efface le verdict — apres un changement d'URL de serveur, il ne
  /// vaut plus.
  void reset() => state = null;
}

/// Verdict de compatibilite du serveur, memorise pour la session.
final compatibilityNotifierProvider =
    NotifierProvider<CompatibilityNotifier, CompatibilityStatus?>(
      CompatibilityNotifier.new,
    );
