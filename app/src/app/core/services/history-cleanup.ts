import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { ApiService } from './api';
import {
  AdjustmentProposals,
  ApplyCategoryRequest,
  ApplyCategoryResult,
  CleanupMergeRequest,
  CleanupMergeResult,
  DuplicateProposals,
  SubscriptionMergeRequest,
  UncategorizedProposals,
} from '../models/history-cleanup.model';

/**
 * Rattrapage de l'historique (KKS-387) : les `GET` proposent sans rien
 * modifier, chaque `POST` applique une proposition validee par l'utilisateur.
 */
@Injectable({
  providedIn: 'root',
})
export class HistoryCleanupService {
  private readonly api = inject(ApiService);

  getDuplicates(): Observable<DuplicateProposals> {
    return this.api.get<DuplicateProposals>('/history-cleanup/duplicates');
  }

  mergeImported(request: CleanupMergeRequest): Observable<CleanupMergeResult> {
    return this.api.post<CleanupMergeResult>('/history-cleanup/duplicates/merge', request);
  }

  mergeSubscriptionPayments(request: SubscriptionMergeRequest): Observable<CleanupMergeResult> {
    return this.api.post<CleanupMergeResult>(
      '/history-cleanup/subscription-duplicates/merge',
      request,
    );
  }

  getUncategorized(): Observable<UncategorizedProposals> {
    return this.api.get<UncategorizedProposals>('/history-cleanup/uncategorized');
  }

  applyCategory(request: ApplyCategoryRequest): Observable<ApplyCategoryResult> {
    return this.api.post<ApplyCategoryResult>('/history-cleanup/uncategorized/apply', request);
  }

  getAdjustments(): Observable<AdjustmentProposals> {
    return this.api.get<AdjustmentProposals>('/history-cleanup/adjustments');
  }
}
