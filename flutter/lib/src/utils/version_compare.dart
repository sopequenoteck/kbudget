/// Comparaison de versions semver, limitee a `MAJOR.MINOR.PATCH` (KKS-314).
///
/// Les suffixes de pre-release et de build (`-rc.1`, `+1`) sont ignores. Le `+1`
/// de `pubspec.yaml` est un build number destine aux stores, sans rapport avec
/// la compatibilite du contrat d'API.
///
/// Retourne un nombre negatif si [a] < [b], zero si egales, positif si [a] > [b].
int compareVersions(String a, String b) {
  List<int> parse(String v) => v
      .split('+')
      .first
      .split('-')
      .first
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList();

  final left = parse(a);
  final right = parse(b);

  for (var i = 0; i < 3; i++) {
    final diff = (i < left.length ? left[i] : 0) - (i < right.length ? right[i] : 0);
    if (diff != 0) return diff;
  }
  return 0;
}

/// `true` si [version] est strictement anterieure a [minimum].
bool isOlderThan(String version, String minimum) => compareVersions(version, minimum) < 0;
