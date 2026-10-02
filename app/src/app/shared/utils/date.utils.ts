const DATE_ONLY = /^\d{4}-\d{2}-\d{2}$/;

/**
 * Lit une date metier envoyee par l'API. Une date seule `AAAA-MM-JJ`
 * (LocalDate) est lue a minuit local : `new Date` la lirait a minuit UTC,
 * soit la veille dans un fuseau en retard sur UTC (Ameriques). Toute autre
 * valeur (horodatage, deja invalide) passe a `new Date` inchangee.
 */
export function parseLocalDate(value: string): Date {
  return new Date(DATE_ONLY.test(value) ? `${value}T00:00:00` : value);
}

/**
 * Formate `date` en `AAAA-MM-JJ` local, pour la comparer a une date metier
 * seule (LocalDate) envoyee par l'API. `toISOString` donne la date UTC :
 * a Paris entre 0 h et 2 h, c'est encore la veille en UTC ; a Los Angeles
 * en soiree, c'est deja le lendemain en UTC.
 */
export function toLocalIsoDate(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}
