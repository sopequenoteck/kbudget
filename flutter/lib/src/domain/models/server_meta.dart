/// Description que le serveur donne de lui-meme, via `GET /api/meta` (KKS-314).
class ServerMeta {
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
        capabilities:
            (json['capabilities'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
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
  const CompatibilityOk(this.meta);
  final ServerMeta meta;
}

/// Serveur injoignable — verdict inconnu, jamais une incompatibilite.
class CompatibilityOffline extends CompatibilityStatus {
  const CompatibilityOffline();
}

/// Le serveur est trop ancien pour cette version du client.
class CompatibilityServerTooOld extends CompatibilityStatus {
  const CompatibilityServerTooOld({this.serverVersion, required this.requiredVersion});

  /// `null` quand le serveur est trop ancien pour exposer `/api/meta`.
  final String? serverVersion;
  final String requiredVersion;
}

/// Le client est plus ancien que le minimum exige par le serveur.
class CompatibilityClientTooOld extends CompatibilityStatus {
  const CompatibilityClientTooOld({
    required this.clientVersion,
    required this.requiredVersion,
  });

  final String clientVersion;
  final String requiredVersion;
}
