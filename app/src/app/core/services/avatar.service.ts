import { Injectable, inject, signal } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

import { ApiService } from './api';
import { AvatarMetadata } from '../models/avatar-metadata.model';

@Injectable({
  providedIn: 'root',
})
export class AvatarService {
  private readonly api = inject(ApiService);

  readonly avatarUrl = signal<string | null>(null);
  readonly etag = signal<string | null>(null);

  upload(file: File): Observable<AvatarMetadata> {
    const formData = new FormData();
    formData.append('file', file);
    return this.api.postFormData<AvatarMetadata>('/users/me/avatar', formData).pipe(
      tap((meta) => {
        this.etag.set(meta.etag);
        this.avatarUrl.set(`/api/users/me/avatar?v=${Date.now()}`);
      }),
    );
  }

  delete(): Observable<void> {
    return this.api.delete<void>('/users/me/avatar').pipe(
      tap(() => {
        this.avatarUrl.set(null);
        this.etag.set(null);
      }),
    );
  }

  getUrl(): string | null {
    return this.avatarUrl();
  }
}
