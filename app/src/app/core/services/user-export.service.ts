import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpResponse } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class UserExportService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = environment.apiUrl;

  exportJson(): Observable<void> {
    return this.http
      .get(`${this.baseUrl}/users/me/export?format=json`, {
        responseType: 'blob',
        observe: 'response',
      })
      .pipe(
        map((response: HttpResponse<Blob>) => {
          const blob = response.body!;
          const filename = this.extractFilename(
            response.headers.get('Content-Disposition'),
            `kbudget-export-${this.todayStr()}.json`,
          );
          this.triggerDownload(blob, filename);
        }),
      );
  }

  exportCsv(): Observable<void> {
    return this.http
      .get(`${this.baseUrl}/users/me/export?format=csv`, {
        responseType: 'blob',
        observe: 'response',
      })
      .pipe(
        map((response: HttpResponse<Blob>) => {
          const blob = response.body!;
          const filename = this.extractFilename(
            response.headers.get('Content-Disposition'),
            `kbudget-transactions-${this.todayStr()}.csv`,
          );
          this.triggerDownload(blob, filename);
        }),
      );
  }

  private extractFilename(contentDisposition: string | null, fallback: string): string {
    if (!contentDisposition) return fallback;
    const match = contentDisposition.match(/filename="([^"]+)"/);
    return match ? match[1] : fallback;
  }

  private triggerDownload(blob: Blob, filename: string): void {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  }

  private todayStr(): string {
    return new Date().toISOString().slice(0, 10).replace(/-/g, '');
  }
}
