import { Injectable, inject, signal } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api';
import { Debt, DebtRequest } from '../models/debt.model';

@Injectable({
  providedIn: 'root',
})
export class DebtService {
  private readonly api = inject(ApiService);

  readonly refreshTrigger = signal(0);

  private refresh(): void {
    this.refreshTrigger.update((v) => v + 1);
  }

  getAll(rembourse?: boolean): Observable<Debt[]> {
    const path = rembourse !== undefined ? `/debts?rembourse=${rembourse}` : '/debts';
    return this.api.get<Debt[]>(path);
  }

  getById(id: string): Observable<Debt> {
    return this.api.get<Debt>(`/debts/${id}`);
  }

  create(request: DebtRequest): Observable<Debt> {
    return this.api.post<Debt>('/debts', request).pipe(tap(() => this.refresh()));
  }

  update(id: string, request: DebtRequest): Observable<Debt> {
    return this.api.put<Debt>(`/debts/${id}`, request).pipe(tap(() => this.refresh()));
  }

  delete(id: string): Observable<void> {
    return this.api.delete<void>(`/debts/${id}`).pipe(tap(() => this.refresh()));
  }
}
