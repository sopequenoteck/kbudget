import { Category } from './category.model';
import { AccountSummary } from './account.model';

export enum TransactionType {
  DEPENSE = 'DEPENSE',
  RECETTE = 'RECETTE',
  AJUSTEMENT = 'AJUSTEMENT',
}

export interface Transaction {
  id: string;
  montant: number;
  libelle: string;
  type: TransactionType;
  date: string;
  category: Category | null;
  note: string | null;
  account: AccountSummary | null;
  transferId: string | null;
}

export interface TransactionRequest {
  montant: number;
  libelle: string;
  type: TransactionType;
  date: string;
  categoryId?: string;
  note?: string;
  accountId?: string;
}

export interface MonthlySummary {
  month: number;
  year: number;
  totalRecettes: number;
  totalDepenses: number;
  solde: number;
  currency: string;
}
