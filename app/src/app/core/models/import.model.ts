export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

/** Transaction existante decrite par le brouillon : rapprochement, candidat ou suspect (KKS-385, KKS-386). */
export interface ImportMatchedTransaction {
  id: string;
  /** Date metier `AAAA-MM-JJ`. */
  date: string;
  libelle: string;
  montant: number;
  type: string;
}

export type ImportLineStatus = 'READY' | 'NEEDS_REVIEW' | 'DUPLICATE' | 'SKIPPED';

export interface ImportDraftLine {
  id: string;
  lineNumber: number;
  rawLabel: string;
  cleanLabel: string;
  amount: number;
  date: string;
  transactionType: string;
  status: ImportLineStatus;
  statusMessage: string | null;
  categoryId: string | null;
  categoryName: string | null;
  /** Clef de la categorie systeme (KKS-395), `null` pour une categorie utilisateur. */
  categorySystemKey?: string | null;
  duplicateTransactionId: string | null;
  suggestRule?: boolean;
  /** KKS-382 : 'ALREADY_IMPORTED' si l'import a ecarte la ligne lui-meme. */
  skipReason?: string | null;
  /** KKS-383 : origine de la categorie ('RULE', 'HISTORY', 'USER'). */
  categorySource?: string | null;
  /** KKS-385 : date d'achat lue dans le libelle brut, `null` sinon (`date` reste la date comptable). */
  purchaseDate: string | null;
  /** KKS-385 : transaction existante a laquelle la ligne est rapprochee, rien ne sera cree pour elle. */
  matchedTransactionId: string | null;
  /** KKS-385 : candidats d'un rapprochement ambigu (statut `DUPLICATE`), vide sinon. */
  matchCandidateIds: string[];
  subscriptionId: string | null;
  /** KKS-386 : detail de `matchedTransactionId`, `null` sans rapprochement ou si la transaction a disparu. */
  matchedTransaction: ImportMatchedTransaction | null;
  /** KKS-386 : detail de `matchCandidateIds`, dans le meme ordre, un candidat disparu en est absent. */
  matchCandidates: ImportMatchedTransaction[];
  /** KKS-386 : cle commercant sur laquelle l'API propage une correction de categorie. */
  merchantKey: string;
  /**
   * KKS-441 : code de l'erreur de lecture d'une ligne illisible (`INVALID_DATE`, `INVALID_AMOUNT`,
   * `UNREADABLE_LINE`), `null` pour une ligne lue ou un brouillon anterieur. Une valeur inconnue
   * (serveur plus recent) se replie sur `statusMessage`.
   */
  readError: string | null;
  /** KKS-441 : valeur brute de la cellule fautive (date ou montant), `null` si rien de pertinent. */
  readErrorValue: string | null;
}

export interface CategoryRule {
  id: string;
  pattern: string;
  categoryId: string;
  categoryName: string;
  /** Clef de la categorie systeme (KKS-395), `null` pour une categorie utilisateur. */
  categorySystemKey?: string | null;
  categoryIcon: string;
  createdAt: string;
}

export interface CategoryRuleRequest {
  pattern: string;
  categoryId: string;
}

export interface ImportDraft {
  id: string;
  accountId: string;
  accountName: string;
  status: 'PENDING' | 'COMPLETED' | 'EXPIRED';
  fileName: string | null;
  totalLines: number;
  readyCount: number;
  reviewCount: number;
  duplicateCount: number;
  skippedCount: number;
  /** KKS-382 : sous-ensemble de `skippedCount`, lignes d'un releve precedent. */
  alreadyImportedCount: number;
  /** KKS-385 : sous-ensemble de `readyCount`, lignes rapprochees d'une transaction existante. */
  matchedCount: number;
  profileName: string | null;
  profileSource: string | null;
  createdAt: string;
  expiresAt: string;
  lines: ImportDraftLine[];
  /** KKS-384 : 4 derniers chiffres du compte lus dans l'en-tete du releve. */
  statementAccountSuffix: string | null;
  /** KKS-384 : solde donne par la banque a `statementBalanceDate`. */
  statementBalance: number | null;
  statementBalanceDate: string | null;
  /** KKS-384 : solde de l'application a cette date si le brouillon est confirme tel quel. */
  projectedBalance: number | null;
  /** KKS-384 : premier import du compte seulement, `soldeInitial` qui aligne l'application sur la banque. */
  proposedOpeningBalance: number | null;
}

export interface ImportDraftSummary {
  id: string;
  accountId: string;
  accountName: string;
  status: string;
  fileName: string | null;
  totalLines: number;
  readyCount: number;
  reviewCount: number;
  duplicateCount: number;
  skippedCount: number;
  createdAt: string;
  expiresAt: string;
}

/** KKS-384 : comparaison du solde de l'application et de celui de la banque apres confirmation. */
export interface ImportBalanceCheck {
  bankBalance: number;
  balanceDate: string;
  computedBalance: number;
  /** `computedBalance` moins `bankBalance`, `0` quand ils concordent. */
  difference: number;
  /** Transactions de la periode absentes du releve : doublons probables. */
  suspects: ImportMatchedTransaction[];
}

export interface ImportConfirmResult {
  importedCount: number;
  skippedCount: number;
  historyId: string;
  alreadyImportedCount: number;
  matchedCount: number;
  /** `null` quand le releve ne donne pas de solde. */
  balanceCheck: ImportBalanceCheck | null;
}

/** KKS-440 : profil reconnu pour un fichier, avant toute creation de brouillon. */
export interface ImportDetection {
  recognized: boolean;
  profileSource: ImportProfile['source'] | null;
  bankCode: string | null;
  profileName: string | null;
  accountSuffix: string | null;
  /** Compte de l'utilisateur deja importe avec ce profil et ce suffixe, `null` si zero ou plusieurs. */
  suggestedAccountId: string | null;
}

export interface ImportLineUpdate {
  categoryId?: string;
  status?: string;
  /** KKS-385 : rapproche la ligne de cette transaction existante. */
  matchedTransactionId?: string;
  /** KKS-385 : defait le rapprochement, une transaction sera creee. */
  clearMatch?: boolean;
}

export interface ImportLineBatchUpdate {
  lineIds: string[];
  categoryId?: string;
  status?: string;
}

export interface ImportHistoryEntry {
  id: string;
  accountId: string;
  accountName: string;
  transactionCount: number;
  fileName: string | null;
  importedAt: string;
}

export interface CsvPreview {
  headers: string[];
  rows: string[][];
  detectedSeparator: string;
  detectedEncoding: string;
  detectedSkipHeaderLines: number;
  totalRows: number;
}

export interface CsvMapping {
  separator: string;
  dateFormat: string;
  dateColumn: string;
  amountColumn: string | null;
  debitColumn: string | null;
  creditColumn: string | null;
  labelColumn: string;
  encoding: string;
  decimalSeparator: string;
  skipHeaderLines: number;
  saveAsProfile: boolean;
  profileName: string | null;
}

export interface ImportProfile {
  id: string | null;
  bankCode: string | null;
  name: string;
  source: 'REGISTRY' | 'CUSTOM';
  editable: boolean;
}

/** Cles de traduction de l'origine d'un profil d'import (KKS-376). */
export const IMPORT_PROFILE_SOURCE_LABEL_KEYS: Record<ImportProfile['source'], string> = {
  REGISTRY: 'imports.value.registry',
  CUSTOM: 'imports.value.custom',
};
