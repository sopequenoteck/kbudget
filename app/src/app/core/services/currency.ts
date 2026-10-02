import { computed, Injectable, inject, signal } from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';
import { Observable, tap } from 'rxjs';
import { ApiService } from './api';
import { LanguageService } from './language';
import { CurrencyInfo, currencyNameKey } from '../models/currency.model';
import { SelectPickerItem } from '../../shared/components/select-picker/select-picker.model';

@Injectable({
  providedIn: 'root',
})
export class CurrencyService {
  private readonly api = inject(ApiService);
  private readonly transloco = inject(TranslocoService);
  private readonly languageService = inject(LanguageService);

  private readonly _currencies = signal<CurrencyInfo[]>([]);
  readonly currencies = this._currencies.asReadonly();

  /**
   * Lit `activeLanguage()` avant de traduire pour se reevaluer au changement
   * de langue (precedent budget-list, KKS-379) : un code hors de la liste
   * fermee des devises retombe sur `c.name`, le nom fourni par l'API.
   */
  readonly currencyItems = computed<SelectPickerItem[]>(() => {
    this.languageService.activeLanguage();
    return this._currencies().map((c) => {
      const key = currencyNameKey(c.code);
      return {
        id: c.code,
        label: `${c.code} - ${c.symbol}`,
        secondaryText: key ? this.transloco.translate(key) : c.name,
        icon: null,
        color: null,
      };
    });
  });

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
