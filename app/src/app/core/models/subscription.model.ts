import { Category } from './category.model';
import { AccountSummary } from './account.model';

export enum Frequency {
  HEBDOMADAIRE = 'HEBDOMADAIRE',
  MENSUEL = 'MENSUEL',
  ANNUEL = 'ANNUEL',
}

/** Cle de traduction du libelle complet d'une frequence d'abonnement
 * (subscriptions.value.*), partagee par la liste, le detail et le
 * formulaire pour eviter trois copies. */
export const SUBSCRIPTION_FREQUENCY_LABEL_KEYS: Record<Frequency, string> = {
  [Frequency.HEBDOMADAIRE]: 'subscriptions.value.weekly',
  [Frequency.MENSUEL]: 'subscriptions.value.monthly',
  [Frequency.ANNUEL]: 'subscriptions.value.yearly',
};

/** Cle de traduction de la forme courte d'une frequence d'abonnement
 * (subscriptions.value.per*), partagee de la meme facon. */
export const SUBSCRIPTION_FREQUENCY_SHORT_LABEL_KEYS: Record<Frequency, string> = {
  [Frequency.HEBDOMADAIRE]: 'subscriptions.value.perWeek',
  [Frequency.MENSUEL]: 'subscriptions.value.perMonth',
  [Frequency.ANNUEL]: 'subscriptions.value.perYear',
};

export interface Subscription {
  id: string;
  nom: string;
  montant: number;
  frequence: Frequency;
  dateDebut: string;
  actif: boolean;
  category: Category | null;
  account: AccountSummary | null;
  currency: string;
}

export interface SubscriptionRequest {
  nom: string;
  montant: number;
  frequence: Frequency;
  dateDebut: string;
  actif?: boolean;
  categoryId?: string;
  accountId?: string;
  currency?: string;
}
