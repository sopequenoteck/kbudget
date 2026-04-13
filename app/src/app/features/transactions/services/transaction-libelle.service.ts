import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, catchError, of } from 'rxjs';
import { environment } from '../../../../environments/environment';

@Injectable({ providedIn: 'root' })
export class TransactionLibelleService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = environment.apiUrl;

  search(q: string, limit = 20): Observable<string[]> {
    let params = new HttpParams().set('limit', limit.toString());
    if (q) {
      params = params.set('q', q);
    }
    return this.http
      .get<string[]>(`${this.baseUrl}/transactions/libelles`, { params })
      .pipe(catchError(() => of([])));
  }
}
