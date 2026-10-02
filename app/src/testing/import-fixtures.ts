import {
  ImportConfirmResult,
  ImportDetection,
  ImportDraft,
  ImportDraftLine,
  ImportMatchedTransaction,
} from '../app/core/models/import.model';

let lineSequence = 0;

/** Ligne de brouillon `READY` sans categorie ni rapprochement : on surcharge ce que le test exerce. */
export function importLine(overrides: Partial<ImportDraftLine> = {}): ImportDraftLine {
  lineSequence += 1;
  return {
    id: `line-${lineSequence}`,
    lineNumber: lineSequence,
    rawLabel: 'CARTE X1596 SUPER U',
    cleanLabel: 'SUPER U',
    amount: 10,
    date: '2026-09-18',
    transactionType: 'DEPENSE',
    status: 'READY',
    statusMessage: null,
    categoryId: null,
    categoryName: null,
    categorySystemKey: null,
    duplicateTransactionId: null,
    suggestRule: false,
    skipReason: null,
    categorySource: null,
    purchaseDate: null,
    matchedTransactionId: null,
    matchCandidateIds: [],
    subscriptionId: null,
    matchedTransaction: null,
    matchCandidates: [],
    merchantKey: 'SUPER U',
    ...overrides,
  };
}

export function matchedTransaction(
  overrides: Partial<ImportMatchedTransaction> = {},
): ImportMatchedTransaction {
  return {
    id: 'tx-1',
    date: '2026-09-18',
    libelle: 'Tabac',
    montant: 10,
    type: 'DEPENSE',
    ...overrides,
  };
}

export function importDraft(
  lines: ImportDraftLine[] = [],
  overrides: Partial<ImportDraft> = {},
): ImportDraft {
  return {
    id: 'draft-1',
    accountId: 'acc-1',
    accountName: 'Courant',
    status: 'PENDING',
    fileName: 'releve.csv',
    totalLines: lines.length,
    readyCount: lines.filter((l) => l.status === 'READY').length,
    reviewCount: lines.filter((l) => l.status === 'NEEDS_REVIEW').length,
    duplicateCount: lines.filter((l) => l.status === 'DUPLICATE').length,
    skippedCount: lines.filter((l) => l.status === 'SKIPPED').length,
    alreadyImportedCount: lines.filter((l) => l.skipReason === 'ALREADY_IMPORTED').length,
    matchedCount: lines.filter((l) => l.matchedTransactionId).length,
    profileName: 'Societe Generale',
    profileSource: 'REGISTRY',
    createdAt: '2026-10-01T10:00:00',
    expiresAt: '2026-10-08T10:00:00',
    lines,
    statementAccountSuffix: null,
    statementBalance: null,
    statementBalanceDate: null,
    projectedBalance: null,
    proposedOpeningBalance: null,
    ...overrides,
  };
}

export function importDetection(overrides: Partial<ImportDetection> = {}): ImportDetection {
  return {
    recognized: true,
    profileSource: 'REGISTRY',
    bankCode: 'SG',
    profileName: 'Société Générale',
    accountSuffix: '1596',
    suggestedAccountId: null,
    ...overrides,
  };
}

export function confirmResult(overrides: Partial<ImportConfirmResult> = {}): ImportConfirmResult {
  return {
    importedCount: 3,
    skippedCount: 0,
    historyId: 'hist-1',
    alreadyImportedCount: 0,
    matchedCount: 0,
    balanceCheck: null,
    ...overrides,
  };
}
