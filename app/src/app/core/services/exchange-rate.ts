import { Injectable, inject, signal } from '@angular/core';
import { Observable, firstValueFrom } from 'rxjs';
import { ApiService } from './api';
import { ExchangeRate } from '../models/exchange-rate.model';
import { DevLogger } from './dev-logger';

@Injectable({
  providedIn: 'root',
})
export class ExchangeRateService {
  private readonly api = inject(ApiService);
  private readonly logger = inject(DevLogger);

  private readonly _rates = signal<ExchangeRate[]>([]);
  private readonly _loading = signal(false);
  private readonly _error = signal<string | null>(null);

  readonly rates = this._rates.asReadonly();
  readonly loading = this._loading.asReadonly();
  readonly error = this._error.asReadonly();

  async loadRates(): Promise<void> {
    this._loading.set(true);
    try {
      const rates = await firstValueFrom(this.api.get<ExchangeRate[]>('/exchange-rates'));
      this._rates.set(rates);
      this._error.set(null);
    } catch (e) {
      this.logger.error('Failed to load exchange rates:', e);
      this._error.set('Impossible de charger les taux de change');
    } finally {
      this._loading.set(false);
    }
  }

  upsert(baseCurrency: string, targetCurrency: string, rate: number): Observable<ExchangeRate> {
    return this.api.put<ExchangeRate>('/exchange-rates', { baseCurrency, targetCurrency, rate });
  }

  delete(baseCurrency: string, targetCurrency: string): Observable<void> {
    return this.api.delete<void>(`/exchange-rates/${baseCurrency}/${targetCurrency}`);
  }
}
