import { Injectable, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { ApiService } from './api';
import { BankResponse } from '../models/bank.model';
import { DevLogger } from './dev-logger';

@Injectable({ providedIn: 'root' })
export class BankService {
  private readonly apiService = inject(ApiService);
  private readonly logger = inject(DevLogger);

  readonly banks = signal<BankResponse[]>([]);
  readonly error = signal<string | null>(null);

  private loaded = false;

  async loadBanks(): Promise<void> {
    if (this.loaded) return;

    try {
      const data = await firstValueFrom(this.apiService.get<BankResponse[]>('/banks'));
      this.banks.set(data);
      this.error.set(null);
      this.loaded = true;
    } catch (e) {
      this.logger.error('BankService.loadBanks error', e);
      this.error.set('Impossible de charger les banques');
    }
  }

  getBankByCode(code: string): BankResponse | undefined {
    return this.banks().find((b) => b.code === code);
  }

  getBankLogoUrl(code: string): string | null {
    return this.getBankByCode(code)?.logoUrl ?? null;
  }
}
