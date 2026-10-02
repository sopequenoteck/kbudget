/** Soit une clé de traduction (avec parametres ICU), soit une date deja
 * formatee pour la locale d'affichage (au-dela de 30 jours). */
export interface RelativeDateInfo {
  readonly key?: string;
  readonly params?: { count: number };
  readonly formatted?: string;
}

/**
 * Cles de traduction propres a un domaine (debts, subscriptions, recurring)
 * pour exprimer l'ecart entre une date cible et aujourd'hui. `yesterday` et
 * `daysOverdue` sont optionnelles : un domaine dont la date cible ne peut
 * jamais etre passee (abonnements) n'en a pas besoin.
 */
export interface RelativeDueDateKeys {
  readonly today: string;
  readonly tomorrow: string;
  readonly daysUntil: string;
  readonly yesterday?: string;
  readonly daysOverdue?: string;
}

/**
 * Calcule l'ecart entre `targetDate` et `today` et retourne soit une cle de
 * traduction (avec ses parametres ICU), soit une date deja formatee pour la
 * locale d'affichage (au-dela de 30 jours dans un sens ou dans l'autre).
 * Fonction pure, partagee par les listes debts/subscriptions/recurring pour
 * eviter trois copies quasi identiques (KKS-378).
 */
export function getRelativeDueDateInfo(
  targetDate: Date,
  today: Date,
  locale: string,
  keys: RelativeDueDateKeys,
  dayFormat: 'numeric' | '2-digit' = 'numeric',
): RelativeDateInfo {
  const normalizedToday = new Date(today);
  normalizedToday.setHours(0, 0, 0, 0);
  const normalizedTarget = new Date(targetDate);
  normalizedTarget.setHours(0, 0, 0, 0);

  const diffDays = Math.round(
    (normalizedTarget.getTime() - normalizedToday.getTime()) / (1000 * 60 * 60 * 24),
  );

  if (diffDays < 0) {
    const absDays = Math.abs(diffDays);
    if (absDays === 1 && keys.yesterday) return { key: keys.yesterday };
    if (keys.daysOverdue) return { key: keys.daysOverdue, params: { count: absDays } };
  } else if (diffDays === 0) {
    return { key: keys.today };
  } else if (diffDays === 1) {
    return { key: keys.tomorrow };
  } else if (diffDays <= 30) {
    return { key: keys.daysUntil, params: { count: diffDays } };
  }

  return {
    formatted: new Intl.DateTimeFormat(locale, { day: dayFormat, month: 'short' }).format(normalizedTarget),
  };
}
