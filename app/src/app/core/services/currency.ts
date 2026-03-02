import { computed, Injectable, inject, signal } from '@angular/core';
import { Observable, tap } from 'rxjs';
import { ApiService } from './api';
import { CurrencyInfo } from '../models/currency.model';
import { SelectPickerItem } from '../../shared/components/select-picker/select-picker.model';

@Injectable({
  providedIn: 'root',
})
export class CurrencyService {
  private readonly api = inject(ApiService);

  private readonly _currencies = signal<CurrencyInfo[]>([]);
  readonly currencies = this._currencies.asReadonly();

  readonly currencyItems = computed<SelectPickerItem[]>(() =>
    this._currencies().map((c) => ({
      id: c.code,
      label: `${c.code} - ${c.symbol}`,
      secondaryText: c.name,
      icon: null,
      color: null,
    })),
  );

  getAll(): Observable<CurrencyInfo[]> {
    return this.api
      .get<CurrencyInfo[]>('/currencies')
      .pipe(tap((currencies) => this._currencies.set(currencies)));
  }

  loadIfEmpty(): void {
    if (this._currencies().length === 0) {
      this.getAll().subscribe();
    }
  }
}
