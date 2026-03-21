export interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  number: number;
  size: number;
}

export interface ImportDraftLine {
  id: string;
  lineNumber: number;
  rawLabel: string;
  cleanLabel: string;
  amount: number;
  date: string;
  transactionType: string;
  status: 'READY' | 'NEEDS_REVIEW' | 'DUPLICATE' | 'SKIPPED';
  statusMessage: string | null;
  categoryId: string | null;
  categoryName: string | null;
  duplicateTransactionId: string | null;
  suggestRule?: boolean;
}

export interface CategoryRule {
  id: string;
  pattern: string;
  categoryId: string;
  categoryName: string;
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
  profileName: string | null;
  profileSource: string | null;
  createdAt: string;
  expiresAt: string;
  lines: ImportDraftLine[];
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

export interface ImportConfirmResult {
  importedCount: number;
  skippedCount: number;
  historyId: string;
}

export interface ImportLineUpdate {
  categoryId?: string;
  status?: string;
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
