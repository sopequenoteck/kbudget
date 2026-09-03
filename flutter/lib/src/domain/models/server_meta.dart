// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

/// Description que le serveur donne de lui-meme, via `GET /api/meta` (KKS-314).
class ServerMeta {
  /// Construit la description renvoyee par `GET /api/meta`.
  const ServerMeta({
    required this.serverVersion,
    required this.apiVersion,
    required this.minClientVersion,
    required this.capabilities,
  });

  final String serverVersion;
  final String apiVersion;
  final String minClientVersion;

  /// Noms bruts des fonctionnalites connues du serveur (`SUBSCRIPTIONS`, ...).
  ///
  /// Volontairement des `String` et non des `Feature` : un serveur plus recent
  /// peut annoncer une fonctionnalite que cette version du client ignore, et un
  /// parsing strict echouerait la ou il suffit de ne pas la connaitre.
  final List<String> capabilities;

  factory ServerMeta.fromJson(Map<String, dynamic> json) => ServerMeta(
    serverVersion: json['serverVersion'] as String? ?? '',
    apiVersion: json['apiVersion'] as String? ?? '',
    minClientVersion: json['minClientVersion'] as String? ?? '0.0.0',
    capabilities: (json['capabilities'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList(),
  );
}

/// Verdict de compatibilite entre ce client et le serveur configure (KKS-314).
///
/// [CompatibilityOffline] est distinct de [CompatibilityServerTooOld] : un
/// serveur injoignable n'est pas un serveur incompatible. Les confondre
/// afficherait « mettez votre serveur a jour » a un utilisateur simplement
/// coupe du reseau, alors que la constitution (principe IV) impose de degrader
/// proprement dans ce cas.
sealed class CompatibilityStatus {
  const CompatibilityStatus();
}

/// Client et serveur peuvent fonctionner ensemble.
class CompatibilityOk extends CompatibilityStatus {
  /// [meta] est la description renvoyee par le serveur.
  const CompatibilityOk(this.meta);
  final ServerMeta meta;
}

/// Serveur injoignable — verdict inconnu, jamais une incompatibilite.
class CompatibilityOffline extends CompatibilityStatus {
  const CompatibilityOffline();
}

/// Le serveur est trop ancien pour cette version du client.
class CompatibilityServerTooOld extends CompatibilityStatus {
  /// [serverVersion] est nul si le serveur ne sait pas exposer sa version.
  const CompatibilityServerTooOld({
    required this.requiredVersion,
    this.serverVersion,
  });

  /// `null` quand le serveur est trop ancien pour exposer `/api/meta`.
  final String? serverVersion;
  final String requiredVersion;
}

/// Le client est plus ancien que le minimum exige par le serveur.
class CompatibilityClientTooOld extends CompatibilityStatus {
  /// [requiredVersion] est le minimum exige par le serveur.
  const CompatibilityClientTooOld({
    required this.clientVersion,
    required this.requiredVersion,
  });

  final String clientVersion;
  final String requiredVersion;
}

/// Formulations destinees a l'utilisateur, portees par le verdict lui-meme.
///
/// Elles vivaient en double — dans l'ecran de configuration serveur et dans
/// l'ecran de blocage — avec des phrases voisines mais divergentes. Une
/// formulation modifiee d'un cote laissait l'autre en arriere. Les regrouper
/// ici garantit qu'un utilisateur lit la meme chose quel que soit l'endroit ou
/// l'incompatibilite se manifeste.
extension CompatibilityMessage on CompatibilityStatus {
  /// Message a afficher, ou `null` quand tout va bien.
  ///
  /// [verbose] ajoute la version du client, pertinente sur un ecran de blocage
  /// mais bruyante sous un champ de saisie d'URL.
  String? userMessage({bool verbose = false}) => switch (this) {
    CompatibilityOk() => null,
    CompatibilityOffline() =>
      "Serveur injoignable. Verifiez l'URL et votre connexion.",
    CompatibilityServerTooOld(:final serverVersion, :final requiredVersion) =>
      serverVersion == null
          ? 'Ce serveur est trop ancien pour indiquer sa version. Cette '
                'application requiert au minimum la version $requiredVersion. '
                "Mettez votre instance a jour, puis relancez l'application."
          : 'Ce serveur est en version $serverVersion. Cette application '
                'requiert au minimum la version $requiredVersion. '
                "Mettez votre instance a jour, puis relancez l'application.",
    CompatibilityClientTooOld(:final clientVersion, :final requiredVersion) =>
      'Ce serveur exige au minimum la version $requiredVersion de '
          "l'application. "
          "${verbose ? 'Vous utilisez la version $clientVersion. ' : ''}"
          'Mettez a jour K-Budget depuis votre magasin.',
  };
}
