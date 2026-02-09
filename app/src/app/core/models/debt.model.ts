import { Category } from './category.model';

export enum DebtType {
  JE_DOIS = 'JE_DOIS',
  ON_ME_DOIT = 'ON_ME_DOIT',
}

export interface Debt {
  id: string;
  personne: string;
  montant: number;
  sens: DebtType;
  date: string;
  rembourse: boolean;
  category: Category | null;
}

export interface DebtRequest {
  personne: string;
  montant: number;
  sens: DebtType;
  date: string;
  rembourse?: boolean;
  categoryId?: string;
}
