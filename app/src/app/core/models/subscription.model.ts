import { Category } from './category.model';

export enum Frequency {
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
}

export interface SubscriptionRequest {
  nom: string;
  montant: number;
  frequence: Frequency;
  dateDebut: string;
  actif?: boolean;
  categoryId?: string;
}
