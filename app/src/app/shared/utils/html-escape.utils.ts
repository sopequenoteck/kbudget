/**
 * Echappe les caracteres HTML speciaux d'une chaine avant interpolation dans
 * un `[innerHTML]` (KKS-376) : MessageFormat n'echappe pas ses parametres, et
 * le sanitizer d'Angular laisse passer du balisage autorise (`<a>`, `<img>`,
 * etc.). Necessaire uniquement pour les parametres qui portent une donnee
 * utilisateur — un numero de version (KKS-379) n'y est pas expose.
 */
export function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}
