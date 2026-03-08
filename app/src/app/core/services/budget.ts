import { Injectable, inject, signal } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api';
import {
  Budget,
  BudgetRequest,
  BudgetOverview,
  BudgetHistory,
} from '../models/budget.model';

@Injectable({
  providedIn: 'root',
})
export class BudgetService {
  private readonly api = inject(ApiService);

  readonly refreshTrigger = signal(0);

  refresh(): void {
    this.refreshTrigger.update((v) => v + 1);
  }

  getAll(includeInactive?: boolean): Observable<Budget[]> {
    const path = includeInactive ? '/budgets?includeInactive=true' : '/budgets';
    return this.api.get<Budget[]>(path);
  }

  getById(id: string): Observable<Budget> {
    return this.api.get<Budget>(`/budgets/${id}`);
  }

  getOverview(): Observable<BudgetOverview> {
    return this.api.get<BudgetOverview>('/budgets/overview');
  }

  getHistory(month: string): Observable<BudgetHistory> {
    return this.api.get<BudgetHistory>(`/budgets/history?month=${month}`);
  }

  create(request: BudgetRequest): Observable<Budget> {
    return this.api.post<Budget>('/budgets', request).pipe(tap(() => this.refresh()));
  }

  update(id: string, request: BudgetRequest): Observable<Budget> {
    return this.api.put<Budget>(`/budgets/${id}`, request).pipe(tap(() => this.refresh()));
  }

  delete(id: string): Observable<void> {
    return this.api.delete<void>(`/budgets/${id}`).pipe(tap(() => this.refresh()));
  }
}
