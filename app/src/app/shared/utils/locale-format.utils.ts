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

/**
 * Libellé du nombre de jours restants avant une échéance à venir (abonnements,
 * dettes). Au-delà de 30 jours, bascule sur une date courte localisée.
 */
export function formatUpcomingDays(diffDays: number, date: Date, locale: string): string {
  if (diffDays === 0) return "aujourd'hui";
  if (diffDays === 1) return 'demain';
  if (diffDays <= 30) return `dans ${diffDays} j.`;
  return new Intl.DateTimeFormat(locale, { day: 'numeric', month: 'short' }).format(date);
}

/** Libellé "mois année" localisé (ex: "mars 2026"). */
export function formatMonthYearLabel(date: Date, locale: string): string {
  return date.toLocaleDateString(locale, { month: 'long', year: 'numeric' });
}
