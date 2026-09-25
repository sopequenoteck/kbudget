import { Category } from './category.model';
import { AccountSummary } from './account.model';

export enum DebtType {
  EMPRUNT = 'EMPRUNT',
  PRET = 'PRET',
}

/** Cle de traduction du sens d'une dette (debts.value.*), partagee par la
 * liste, le detail et le formulaire pour eviter trois copies. */
export const DEBT_TYPE_LABEL_KEYS: Record<DebtType, string> = {
  [DebtType.EMPRUNT]: 'debts.value.borrowed',
  [DebtType.PRET]: 'debts.value.lent',
};

export interface Debt {
  id: string;
  personne: string;
  montant: number;
  montantRestant: number;
  sens: DebtType;
  date: string;
  dueDate: string | null;
  rembourse: boolean;
  category: Category | null;
  currency: string;
  account: AccountSummary | null;
  includeInBalance: boolean;
  reminderDate: string | null;
  reminderTime: string | null;
}

export interface DebtRequest {
  personne: string;
  montant: number;
  sens: DebtType;
  date: string;
  dueDate?: string | null;
  rembourse?: boolean;
  categoryId?: string;
  currency?: string;
  accountId?: string | null;
  includeInBalance?: boolean;
  reminderDate?: string | null;
  reminderTime?: string | null;
}

export interface DebtRepayRequest {
  accountId: string;
  amount?: number;
}

export interface DebtPaymentResponse {
  id: string;
  amount: number;
  date: string;
  accountName: string;
}

export interface DebtSnoozeRequest {
  reminderDate: string;
  reminderTime: string;
}
