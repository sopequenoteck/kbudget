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
}

export interface SubscriptionRequest {
  nom: string;
  montant: number;
  frequence: Frequency;
  dateDebut: string;
  actif?: boolean;
}
