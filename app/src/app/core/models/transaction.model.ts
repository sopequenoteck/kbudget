import { Category } from './category.model';

export enum TransactionType {
  DEPENSE = 'DEPENSE',
  RECETTE = 'RECETTE',
}

export interface Transaction {
  id: string;
  montant: number;
  libelle: string;
  type: TransactionType;
  date: string;
  category: Category | null;
  note: string | null;
}

export interface TransactionRequest {
  montant: number;
  libelle: string;
  type: TransactionType;
  date: string;
  categoryId?: string;
  note?: string;
}

export interface MonthlySummary {
  month: number;
  year: number;
  totalRecettes: number;
  totalDepenses: number;
  solde: number;
}
