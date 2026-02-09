import { Injectable, inject, signal } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api';
import {
  Transaction,
  TransactionRequest,
  MonthlySummary,
} from '../models/transaction.model';

@Injectable({
  providedIn: 'root',
})
export class TransactionService {
  private readonly api = inject(ApiService);

  readonly refreshTrigger = signal(0);

  private refresh(): void {
    this.refreshTrigger.update((v) => v + 1);
  }

  getAll(): Observable<Transaction[]> {
    return this.api.get<Transaction[]>('/transactions');
  }

  getById(id: string): Observable<Transaction> {
    return this.api.get<Transaction>(`/transactions/${id}`);
  }

  create(request: TransactionRequest): Observable<Transaction> {
    return this.api
      .post<Transaction>('/transactions', request)
      .pipe(tap(() => this.refresh()));
  }

  update(id: string, request: TransactionRequest): Observable<Transaction> {
    return this.api
      .put<Transaction>(`/transactions/${id}`, request)
      .pipe(tap(() => this.refresh()));
  }

  delete(id: string): Observable<void> {
    return this.api
      .delete<void>(`/transactions/${id}`)
      .pipe(tap(() => this.refresh()));
  }

  getSummary(month?: number, year?: number): Observable<MonthlySummary> {
    const params: string[] = [];
    if (month !== undefined) params.push(`month=${month}`);
    if (year !== undefined) params.push(`year=${year}`);
    const query = params.length > 0 ? `?${params.join('&')}` : '';
    return this.api.get<MonthlySummary>(`/transactions/summary${query}`);
  }
}
