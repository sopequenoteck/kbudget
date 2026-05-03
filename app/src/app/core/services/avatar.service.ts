import { HttpClient } from '@angular/common/http';
import { Injectable, inject, signal } from '@angular/core';
import { Observable, of } from 'rxjs';
import { catchError, map, switchMap, tap } from 'rxjs/operators';

import { environment } from '../../../environments/environment';
import { AvatarMetadata } from '../models/avatar-metadata.model';
import { ApiService } from './api';

/**
 * Avatars served by `GET /api/users/me/avatar` are protected by JWT.
 * The browser doesn't send the `Authorization` header on `<img src>`,
 * so we fetch the binary via `HttpClient` (which goes through the JWT
 * interceptor), then expose it as a blob URL safe to bind to `<img src>`.
 */
@Injectable({
  providedIn: 'root',
})
export class AvatarService {
  private readonly api = inject(ApiService);
  private readonly http = inject(HttpClient);

  readonly avatarUrl = signal<string | null>(null);
  readonly etag = signal<string | null>(null);

  private currentBlobUrl: string | null = null;

  loadAvatarBlob(): Observable<void> {
    return this.http
      .get(`${environment.apiUrl}/users/me/avatar`, { responseType: 'blob' })
      .pipe(
        tap((blob) => this.setBlobUrl(blob)),
        map(() => undefined),
        catchError(() => {
          // No avatar (404) or unreachable — fallback to initials
          this.clearBlobUrl();
          return of(undefined);
        }),
      );
  }

  upload(file: File): Observable<AvatarMetadata> {
    const formData = new FormData();
    formData.append('file', file);
    return this.api.postFormData<AvatarMetadata>('/users/me/avatar', formData).pipe(
      tap((meta) => this.etag.set(meta.etag)),
      // Re-fetch the binary so the new blob URL is bound to <img src>
      switchMap((meta) => this.loadAvatarBlob().pipe(map(() => meta))),
    );
  }

  delete(): Observable<void> {
    return this.api.delete<void>('/users/me/avatar').pipe(
      tap(() => this.clearBlobUrl()),
    );
  }

  getUrl(): string | null {
    return this.avatarUrl();
  }

  private setBlobUrl(blob: Blob): void {
    if (this.currentBlobUrl) {
      URL.revokeObjectURL(this.currentBlobUrl);
    }
    this.currentBlobUrl = URL.createObjectURL(blob);
    this.avatarUrl.set(this.currentBlobUrl);
  }

  private clearBlobUrl(): void {
    if (this.currentBlobUrl) {
      URL.revokeObjectURL(this.currentBlobUrl);
      this.currentBlobUrl = null;
    }
    this.avatarUrl.set(null);
    this.etag.set(null);
  }
}
