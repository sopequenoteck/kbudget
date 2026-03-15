import { Category } from './category.model';
import { AccountSummary } from './account.model';
import { TransactionType } from './transaction.model';
import { Frequency } from './subscription.model';

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
