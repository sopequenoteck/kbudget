import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';

import { HistoryCleanupService } from './history-cleanup';
import {
  AdjustmentProposals,
  ApplyCategoryResult,
  CleanupMergeResult,
  DuplicateProposals,
  UncategorizedProposals,
} from '../models/history-cleanup.model';

describe('HistoryCleanupService', () => {
  let service: HistoryCleanupService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [HistoryCleanupService, provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(HistoryCleanupService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should_get_the_duplicate_proposals', () => {
    const body: DuplicateProposals = { importedDuplicates: [], subscriptionDuplicates: [] };
    let result: DuplicateProposals | undefined;

    service.getDuplicates().subscribe((value) => (result = value));
    const req = httpMock.expectOne('/api/v1/history-cleanup/duplicates');
    req.flush(body);

    expect(req.request.method).toBe('GET');
    expect(result).toEqual(body);
  });

  it('should_post_the_imported_and_kept_ids_to_merge_an_imported_duplicate', () => {
    const body = { kept: {}, removedIds: ['tx-imp'] } as unknown as CleanupMergeResult;
    let result: CleanupMergeResult | undefined;

    service
      .mergeImported({ importedTransactionId: 'tx-imp', keptTransactionId: 'tx-kept' })
      .subscribe((value) => (result = value));
    const req = httpMock.expectOne('/api/v1/history-cleanup/duplicates/merge');
    req.flush(body);

    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({
      importedTransactionId: 'tx-imp',
      keptTransactionId: 'tx-kept',
    });
    expect(result?.removedIds).toEqual(['tx-imp']);
  });

  it('should_post_the_kept_and_removed_ids_to_merge_subscription_payments', () => {
    let result: CleanupMergeResult | undefined;

    service
      .mergeSubscriptionPayments({
        keptTransactionId: 'tx-1',
        removedTransactionIds: ['tx-2', 'tx-3'],
      })
      .subscribe((value) => (result = value));
    const req = httpMock.expectOne('/api/v1/history-cleanup/subscription-duplicates/merge');
    req.flush({ kept: {}, removedIds: ['tx-2', 'tx-3'] });

    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({
      keptTransactionId: 'tx-1',
      removedTransactionIds: ['tx-2', 'tx-3'],
    });
    expect(result?.removedIds).toEqual(['tx-2', 'tx-3']);
  });

  it('should_get_the_uncategorized_groups', () => {
    const body: UncategorizedProposals = { groups: [] };
    let result: UncategorizedProposals | undefined;

    service.getUncategorized().subscribe((value) => (result = value));
    const req = httpMock.expectOne('/api/v1/history-cleanup/uncategorized');
    req.flush(body);

    expect(req.request.method).toBe('GET');
    expect(result).toEqual(body);
  });

  it('should_post_the_category_the_transactions_and_the_rule_flag_to_apply_a_category', () => {
    let result: ApplyCategoryResult | undefined;

    service
      .applyCategory({ categoryId: 'cat-1', transactionIds: ['tx-1', 'tx-2'], createRule: false })
      .subscribe((value) => (result = value));
    const req = httpMock.expectOne('/api/v1/history-cleanup/uncategorized/apply');
    req.flush({ categorizedCount: 2, skippedCount: 0 });

    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual({
      categoryId: 'cat-1',
      transactionIds: ['tx-1', 'tx-2'],
      createRule: false,
    });
    expect(result).toEqual({ categorizedCount: 2, skippedCount: 0 });
  });

  it('should_get_the_adjustment_proposals', () => {
    const body: AdjustmentProposals = { accounts: [] };
    let result: AdjustmentProposals | undefined;

    service.getAdjustments().subscribe((value) => (result = value));
    const req = httpMock.expectOne('/api/v1/history-cleanup/adjustments');
    req.flush(body);

    expect(req.request.method).toBe('GET');
    expect(result).toEqual(body);
  });
});
