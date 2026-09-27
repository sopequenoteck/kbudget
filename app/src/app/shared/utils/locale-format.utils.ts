/**
 * Formatages localisés partagés entre les formulaires dépense/dette/
 * abonnement/budget, `repay-dialog` et les écrans liste abonnements/dettes/
 * transactions/budgets, qui en portaient chacun une copie quasi identique
 * (KKS-373). Regroupés dans un seul fichier pour n'exiger qu'une ligne
 * d'import par composant consommateur.
 */

/** Symbole monétaire seul (ex: "€", "$", "CFA"), sans montant. */
export function getCurrencySymbol(currency: string, locale: string): string {
  return (0)
    .toLocaleString(locale, { style: 'currency', currency, minimumFractionDigits: 0, maximumFractionDigits: 0 })
    .replace('0', '')
    .trim();
}

/** Montant formaté en devise localisée (ex: "12,50 €"). */
export function formatCurrencyAmount(amount: number, currency: string, locale: string): string {
  return amount.toLocaleString(locale, { style: 'currency', currency });
}

/**
 * Insère un élément dans une liste triée par `nom` selon la locale.
 */
export function insertSortedByNom<T extends { nom: string }>(
  items: T[],
  item: T,
  locale: string,
): T[] {
  return [...items, item].sort((a, b) => a.nom.localeCompare(b.nom, locale));
}

/** Libellé "mois année" localisé (ex: "mars 2026"). */
export function formatMonthYearLabel(date: Date, locale: string): string {
  return date.toLocaleDateString(locale, { month: 'long', year: 'numeric' });
}

/**
 * Libellé "jour mois année" localisé (ex: "1 octobre 2026") d'une date ISO
 * `AAAA-MM-JJ` (KKS-397). Le suffixe `T00:00:00` évite qu'un fuseau négatif
 * fasse reculer la date affichée d'un jour.
 */
export function formatFullDateLabel(isoDate: string, locale: string): string {
  return new Date(`${isoDate}T00:00:00`).toLocaleDateString(locale, {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
}

/**
 * Pourcentage signé localisé (ex: "+64,4 %" en fr-FR, "+64.4%" en en-GB).
 * `percent` est une valeur en points (64.4, pas 0.644) ; le signe s'affiche
 * toujours, y compris pour zéro (comportement conservé de l'ancien pipe
 * `number` en dur).
 */
export function formatSignedPercent(percent: number, locale: string): string {
  return new Intl.NumberFormat(locale, {
    style: 'percent',
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
    signDisplay: 'always',
  }).format(percent / 100);
}
