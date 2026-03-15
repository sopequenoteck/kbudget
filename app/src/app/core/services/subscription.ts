import { Injectable, inject, signal } from '@angular/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api';
import { Subscription, SubscriptionRequest } from '../models/subscription.model';
import { SubscriptionPaymentResponse } from '../models/subscription-payment.model';

@Injectable({
  providedIn: 'root',
})
export class SubscriptionService {
  private readonly api = inject(ApiService);

  readonly refreshTrigger = signal(0);

  private refresh(): void {
    this.refreshTrigger.update((v) => v + 1);
  }

  getAll(actif?: boolean): Observable<Subscription[]> {
    const path = actif !== undefined ? `/subscriptions?actif=${actif}` : '/subscriptions';
    return this.api.get<Subscription[]>(path);
  }

  getById(id: string): Observable<Subscription> {
    return this.api.get<Subscription>(`/subscriptions/${id}`);
  }

  create(request: SubscriptionRequest): Observable<Subscription> {
    return this.api.post<Subscription>('/subscriptions', request).pipe(tap(() => this.refresh()));
  }

  update(id: string, request: SubscriptionRequest): Observable<Subscription> {
    return this.api
      .put<Subscription>(`/subscriptions/${id}`, request)
      .pipe(tap(() => this.refresh()));
  }

  delete(id: string): Observable<void> {
    return this.api.delete<void>(`/subscriptions/${id}`).pipe(tap(() => this.refresh()));
  }

  pay(id: string): Observable<SubscriptionPaymentResponse> {
    return this.api.post<SubscriptionPaymentResponse>(`/subscriptions/${id}/pay`, {});
  }

  getPayments(id: string): Observable<SubscriptionPaymentResponse[]> {
    return this.api.get<SubscriptionPaymentResponse[]>(`/subscriptions/${id}/payments`);
  }

  getTotalPaid(id: string): Observable<{ total: number; count: number }> {
    return this.api.get<{ total: number; count: number }>(`/subscriptions/${id}/payments/total`);
  }
}
