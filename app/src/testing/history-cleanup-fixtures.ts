import { AccountSummary } from '../app/core/models/account.model';
import { Category } from '../app/core/models/category.model';
import {
  AccountAdjustments,
  CleanupAdjustment,
  CleanupTransaction,
  ImportedDuplicateProposal,
  SubscriptionDuplicateProposal,
  UncategorizedGroup,
} from '../app/core/models/history-cleanup.model';
import { TransactionType } from '../app/core/models/transaction.model';

let sequence = 0;

export function accountSummary(overrides: Partial<AccountSummary> = {}): AccountSummary {
  return {
    id: 'acc-1',
    nom: 'Courant',
    icone: '🏦',
    couleur: '#000000',
    currency: 'EUR',
    bankLogoUrl: null,
    bankCustomLogo: null,
    ...overrides,
  };
}

export function cleanupCategory(overrides: Partial<Category> = {}): Category {
  return {
    id: 'cat-1',
    nom: 'Courses',
    icone: '🛒',
    couleur: '#f59e0b',
    isSystem: false,
    ...overrides,
  };
}

/** Transaction manuelle de depense sans categorie : on surcharge ce que le test exerce. */
export function cleanupTransaction(
  overrides: Partial<CleanupTransaction> = {},
): CleanupTransaction {
  sequence += 1;
  return {
    id: `tx-${sequence}`,
    date: '2026-09-16',
    libelle: 'Pain',
    montant: 3.2,
    type: TransactionType.DEPENSE,
    category: null,
    account: accountSummary(),
    imported: false,
    debtId: null,
    subscriptionId: null,
    ...overrides,
  };
}

export function importedProposal(
  overrides: Partial<ImportedDuplicateProposal> = {},
): ImportedDuplicateProposal {
  return {
    imported: cleanupTransaction({ id: 'imp-1', libelle: 'CARTE BOULANGERIE', imported: true }),
    candidates: [
      cleanupTransaction({ id: 'cand-1', libelle: 'Pain', category: cleanupCategory() }),
      cleanupTransaction({ id: 'cand-2', libelle: 'Baguette', date: '2026-09-17' }),
    ],
    ...overrides,
  };
}

export function subscriptionProposal(
  overrides: Partial<SubscriptionDuplicateProposal> = {},
): SubscriptionDuplicateProposal {
  return {
    subscriptionId: 'sub-1',
    subscriptionName: 'Netflix',
    periodStart: '2026-09-10',
    periodEnd: '2026-10-09',
    suggestedKeepTransactionId: 'pay-1',
    transactions: [
      cleanupTransaction({
        id: 'pay-1',
        libelle: 'Netflix',
        montant: 13.49,
        subscriptionId: 'sub-1',
      }),
      cleanupTransaction({
        id: 'pay-2',
        libelle: 'Netflix bis',
        montant: 13.49,
        subscriptionId: 'sub-1',
      }),
    ],
    ...overrides,
  };
}

export function uncategorizedGroup(
  overrides: Partial<UncategorizedGroup> = {},
): UncategorizedGroup {
  return {
    merchantKey: 'BOULANGERIE TEST',
    type: TransactionType.DEPENSE,
    amount: null,
    count: 2,
    totalAmount: 7.3,
    suggestion: null,
    transactions: [cleanupTransaction({ id: 'unc-1' }), cleanupTransaction({ id: 'unc-2' })],
    ...overrides,
  };
}

export function cleanupAdjustment(overrides: Partial<CleanupAdjustment> = {}): CleanupAdjustment {
  sequence += 1;
  return {
    id: `adj-${sequence}`,
    date: '2026-09-12',
    libelle: 'Ajustement de solde',
    montant: 5,
    probablyUnnecessary: true,
    ...overrides,
  };
}

export function accountAdjustments(
  overrides: Partial<AccountAdjustments> = {},
): AccountAdjustments {
  return {
    account: accountSummary(),
    bankBalance: 80,
    bankBalanceDate: '2026-09-30',
    computedBalance: 85,
    adjustments: [cleanupAdjustment()],
    ...overrides,
  };
}
