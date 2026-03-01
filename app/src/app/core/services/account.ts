import { Injectable, inject, signal } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api';
import {
  Account,
  AccountRequest,
  TransferRequest,
  TransferResponse,
} from '../models/account.model';

@Injectable({
  providedIn: 'root',
})
export class AccountService {
  private readonly api = inject(ApiService);

  readonly refreshTrigger = signal(0);

  private refresh(): void {
    this.refreshTrigger.update((v) => v + 1);
  }

  getAll(includeInactive?: boolean): Observable<Account[]> {
    const path = includeInactive ? '/accounts?includeInactive=true' : '/accounts';
    return this.api.get<Account[]>(path);
  }

  getById(id: string): Observable<Account> {
    return this.api.get<Account>(`/accounts/${id}`);
  }

  create(request: AccountRequest): Observable<Account> {
    return this.api.post<Account>('/accounts', request).pipe(tap(() => this.refresh()));
  }

  update(id: string, request: AccountRequest): Observable<Account> {
    return this.api.put<Account>(`/accounts/${id}`, request).pipe(tap(() => this.refresh()));
  }

  delete(id: string): Observable<void> {
    return this.api.delete<void>(`/accounts/${id}`).pipe(tap(() => this.refresh()));
  }

  setDefault(id: string): Observable<Account> {
    return this.api.put<Account>(`/accounts/${id}/default`, {}).pipe(tap(() => this.refresh()));
  }

  transfer(request: TransferRequest): Observable<TransferResponse> {
    return this.api
      .post<TransferResponse>('/accounts/transfer', request)
      .pipe(tap(() => this.refresh()));
  }

  adjustBalance(id: string, newBalance: number): Observable<Account> {
    return this.api
      .post<Account>(`/accounts/${id}/adjust-balance`, { newBalance })
      .pipe(tap(() => this.refresh()));
  }
}
