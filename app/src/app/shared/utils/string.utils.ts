/**
 * Normalise une chaîne pour la comparaison insensible à la casse et aux accents.
 * Applique : lowercase → NFD (décomposition unicode) → suppression des diacritiques.
 *
 * Partagé entre `Autocomplete` et `CategorySelect` (KKS-231, RES-001).
 */
export function normalize(s: string): string {
  return s
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '');
}
