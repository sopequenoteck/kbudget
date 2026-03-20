import { Injectable, inject, signal } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api';
import {
  ImportDraft,
  ImportDraftLine,
  ImportConfirmResult,
  ImportLineUpdate,
  ImportLineBatchUpdate,
  ImportDraftSummary,
  ImportHistoryEntry,
  PageResponse,
  CsvPreview,
  CsvMapping,
  ImportProfile,
} from '../models/import.model';

@Injectable({
  providedIn: 'root',
})
export class ImportService {
  private readonly api = inject(ApiService);

  readonly refreshTrigger = signal(0);

  private refresh(): void {
    this.refreshTrigger.update((v) => v + 1);
  }

  upload(file: File, accountId: string): Observable<ImportDraft> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('accountId', accountId);
    return this.api
      .postFormData<ImportDraft>('/imports/upload', formData)
      .pipe(tap(() => this.refresh()));
  }

  getDraft(draftId: string): Observable<ImportDraft> {
    return this.api.get<ImportDraft>(`/imports/drafts/${draftId}`);
  }

  updateLine(
    draftId: string,
    lineId: string,
    update: ImportLineUpdate,
  ): Observable<ImportDraftLine> {
    return this.api
      .put<ImportDraftLine>(`/imports/drafts/${draftId}/lines/${lineId}`, update)
      .pipe(tap(() => this.refresh()));
  }

  batchUpdateLines(draftId: string, request: ImportLineBatchUpdate): Observable<ImportDraftLine[]> {
    return this.api
      .put<ImportDraftLine[]>(`/imports/drafts/${draftId}/lines/batch`, request)
      .pipe(tap(() => this.refresh()));
  }

  confirm(draftId: string): Observable<ImportConfirmResult> {
    return this.api
      .post<ImportConfirmResult>(`/imports/drafts/${draftId}/confirm`, {})
      .pipe(tap(() => this.refresh()));
  }

  deleteDraft(draftId: string): Observable<void> {
    return this.api
      .delete<void>(`/imports/drafts/${draftId}`)
      .pipe(tap(() => this.refresh()));
  }

  listDrafts(): Observable<ImportDraftSummary[]> {
    return this.api.get<ImportDraftSummary[]>('/imports/drafts');
  }

  listHistory(page: number, size: number): Observable<PageResponse<ImportHistoryEntry>> {
    return this.api.get<PageResponse<ImportHistoryEntry>>(`/imports/history?page=${page}&size=${size}`);
  }

  preview(
    file: File,
    separator?: string,
    encoding?: string,
    skipHeaderLines?: number,
  ): Observable<CsvPreview> {
    const formData = new FormData();
    formData.append('file', file);
    if (separator != null) formData.append('separator', separator);
    if (encoding != null) formData.append('encoding', encoding);
    if (skipHeaderLines != null) formData.append('skipHeaderLines', String(skipHeaderLines));
    return this.api.postFormData<CsvPreview>('/imports/preview', formData);
  }

  uploadWithMapping(file: File, accountId: string, mapping: CsvMapping): Observable<ImportDraft> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('accountId', accountId);
    formData.append('mapping', JSON.stringify(mapping));
    return this.api
      .postFormData<ImportDraft>('/imports/upload-with-mapping', formData)
      .pipe(tap(() => this.refresh()));
  }

  getProfiles(): Observable<ImportProfile[]> {
    return this.api.get<ImportProfile[]>('/imports/profiles');
  }

  deleteProfile(profileId: string): Observable<void> {
    return this.api
      .delete<void>(`/imports/profiles/${profileId}`)
      .pipe(tap(() => this.refresh()));
  }
}
