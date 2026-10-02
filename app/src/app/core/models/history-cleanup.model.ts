import { AccountSummary } from './account.model';
import { Category } from './category.model';
import { TransactionType } from './transaction.model';

/** Transaction telle que le rattrapage de l'historique la propose (KKS-387). */
export interface CleanupTransaction {
  id: string;
  date: string;
  libelle: string;
  montant: number;
  type: TransactionType;
  category: Category | null;
  account: AccountSummary;
  /** Importee d'un releve : l'API refuse de la supprimer dans une fusion de paiements d'abonnement. */
  imported: boolean;
  debtId: string | null;
  subscriptionId: string | null;
}

/** Une transaction importee et les transactions saisies a la main qui lui ressemblent. */
export interface ImportedDuplicateProposal {
  imported: CleanupTransaction;
  candidates: CleanupTransaction[];
}

/** Plusieurs paiements d'un meme abonnement dans une meme echeance. */
export interface SubscriptionDuplicateProposal {
  subscriptionId: string;
  subscriptionName: string;
  periodStart: string;
  periodEnd: string;
  suggestedKeepTransactionId: string;
  transactions: CleanupTransaction[];
}

export interface DuplicateProposals {
  importedDuplicates: ImportedDuplicateProposal[];
  subscriptionDuplicates: SubscriptionDuplicateProposal[];
}

export interface CleanupMergeRequest {
  importedTransactionId: string;
  keptTransactionId: string;
}

export interface SubscriptionMergeRequest {
  keptTransactionId: string;
  removedTransactionIds: string[];
}

export interface CleanupMergeResult {
  kept: CleanupTransaction;
  removedIds: string[];
}

export type CategorySuggestionSource = 'RULE' | 'HISTORY_AMOUNT' | 'HISTORY_MERCHANT';

export interface CategorySuggestion {
  category: Category;
  source: CategorySuggestionSource;
}

/** Transactions sans categorie d'un meme commercant et d'un meme sens. */
export interface UncategorizedGroup {
  /** Vide quand le libelle n'a pas de commercant reconnaissable : jamais propose. */
  merchantKey: string;
  type: TransactionType;
  /** Renseigne quand le commercant est decoupe par montant : pas de regle a creer. */
  amount: number | null;
  count: number;
  totalAmount: number;
  suggestion: CategorySuggestion | null;
  transactions: CleanupTransaction[];
}

export interface UncategorizedProposals {
  groups: UncategorizedGroup[];
}

export interface ApplyCategoryRequest {
  categoryId: string;
  transactionIds: string[];
  createRule: boolean;
}

export interface ApplyCategoryResult {
  categorizedCount: number;
  skippedCount: number;
}

export interface CleanupAdjustment {
  id: string;
  date: string;
  libelle: string;
  /** Signe : positif si l'ajustement a augmente le solde. */
  montant: number;
  probablyUnnecessary: boolean;
}

/** Ajustements d'un compte, avec le dernier solde bancaire connu (`null` sans releve). */
export interface AccountAdjustments {
  account: AccountSummary;
  bankBalance: number | null;
  bankBalanceDate: string | null;
  computedBalance: number | null;
  adjustments: CleanupAdjustment[];
}

export interface AdjustmentProposals {
  accounts: AccountAdjustments[];
}
