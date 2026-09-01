/**
 * Comparaison de versions semver, limitee a `MAJOR.MINOR.PATCH` (KKS-314).
 *
 * Les suffixes de pre-release et de build (`-rc.1`, `+build`) sont ignores : le
 * projet ne publie que des versions stables, et les prendre en charge
 * ajouterait des regles d'ordre que rien ne viendrait exercer.
 *
 * @returns un nombre negatif si `a < b`, zero si egales, positif si `a > b`
 */
export function compareVersions(a: string, b: string): number {
  const parse = (v: string): number[] =>
    v
      .split('+')[0]
      .split('-')[0]
      .split('.')
      .map((part) => Number.parseInt(part, 10) || 0);

  const left = parse(a);
  const right = parse(b);

  for (let i = 0; i < 3; i++) {
    const diff = (left[i] ?? 0) - (right[i] ?? 0);
    if (diff !== 0) {
      return diff;
    }
  }
  return 0;
}

/** `true` si `version` est strictement anterieure a `minimum`. */
export function isOlderThan(version: string, minimum: string): boolean {
  return compareVersions(version, minimum) < 0;
}
