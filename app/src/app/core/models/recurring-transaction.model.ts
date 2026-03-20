import { Category } from './category.model';
import { AccountSummary } from './account.model';
import { TransactionType } from './transaction.model';
import { Frequency } from './subscription.model';

export interface RecurringTransactionRequest {
  montant: number;
  libelle: string;
  type: TransactionType;
  frequency: Frequency;
  nextOccurrence: string;
  categoryId?: string;
  accountId?: string;
  note?: string;
}

export interface RecurringTransactionResponse {
  id: string;
  montant: number;
  libelle: string;
  type: TransactionType;
  frequency: Frequency;
  nextOccurrence: string;
  recurringActive: boolean;
  category: Category;
  account: AccountSummary;
}
