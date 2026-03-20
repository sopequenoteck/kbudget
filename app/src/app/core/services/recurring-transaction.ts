import { Injectable, inject, signal } from '@angular/core';
import { Observable, firstValueFrom } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api';
import {
  RecurringTransactionRequest,
  RecurringTransactionResponse,
} from '../models/recurring-transaction.model';
import { Transaction } from '../models/transaction.model';

@Injectable({
  providedIn: 'root',
})
export class RecurringTransactionService {
  private readonly api = inject(ApiService);

  readonly recurringTransactions = signal<RecurringTransactionResponse[]>([]);
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);

  async loadActive(): Promise<void> {
    this.loading.set(true);
    this.error.set(null);
    try {
      const data = await firstValueFrom(
        this.api.get<RecurringTransactionResponse[]>('/transactions/recurring'),
      );
      this.recurringTransactions.set(data);
    } catch {
      this.error.set('Impossible de charger les transactions récurrentes');
    } finally {
      this.loading.set(false);
    }
  }

  create(request: RecurringTransactionRequest): Observable<RecurringTransactionResponse> {
    return this.api
      .post<RecurringTransactionResponse>('/transactions/recurring', request)
      .pipe(tap(() => this.loadActive()));
  }

  validate(id: string): Observable<Transaction> {
    return this.api
      .post<Transaction>(`/transactions/recurring/${id}/validate`, {})
      .pipe(tap(() => this.loadActive()));
  }

  skip(id: string): Observable<RecurringTransactionResponse> {
    return this.api
      .patch<RecurringTransactionResponse>(`/transactions/recurring/${id}/skip`, {})
      .pipe(tap(() => this.loadActive()));
  }

  deactivate(id: string): Observable<RecurringTransactionResponse> {
    return this.api
      .patch<RecurringTransactionResponse>(`/transactions/recurring/${id}/deactivate`, {})
      .pipe(tap(() => this.loadActive()));
  }
}
