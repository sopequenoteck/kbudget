import { Category } from './category.model';
import { AccountSummary } from './account.model';

export enum Frequency {
  HEBDOMADAIRE = 'HEBDOMADAIRE',
  MENSUEL = 'MENSUEL',
  ANNUEL = 'ANNUEL',
}

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
