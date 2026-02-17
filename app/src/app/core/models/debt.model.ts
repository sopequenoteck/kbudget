import { Category } from './category.model';

export enum DebtType {
  EMPRUNT = 'EMPRUNT',
  PRET = 'PRET',
}

export interface Debt {
  id: string;
  personne: string;
  montant: number;
  sens: DebtType;
  date: string;
  rembourse: boolean;
  category: Category | null;
  currency: string;
}

export interface DebtRequest {
  personne: string;
  montant: number;
  sens: DebtType;
  date: string;
  rembourse?: boolean;
  categoryId?: string;
  currency?: string;
}
