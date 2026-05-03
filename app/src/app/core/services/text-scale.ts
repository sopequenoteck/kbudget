import { Injectable, computed, effect, inject, signal } from '@angular/core';

import { PreferenceService } from './preference';
import { DevLogger } from './dev-logger';

export type TextScale = 'small' | 'medium' | 'large';

export const SCALE_FACTORS: Record<TextScale, number> = {
  small: 0.85,
  medium: 1.0,
  large: 1.3,
};

const STORAGE_KEY = 'budget_text_scale';
const VALID_SCALES: TextScale[] = ['small', 'medium', 'large'];

const API_TO_LOCAL: Record<string, TextScale> = {
  SMALL: 'small',
  MEDIUM: 'medium',
  LARGE: 'large',
};

const LOCAL_TO_API: Record<TextScale, string> = {
  small: 'SMALL',
  medium: 'MEDIUM',
  large: 'LARGE',
};

@Injectable({
  providedIn: 'root',
})
export class TextScaleService {
  private readonly preferenceService = inject(PreferenceService);
  private readonly logger = inject(DevLogger);

  readonly currentTextScale = signal<TextScale>('medium');

  readonly scaleFactor = computed(() => SCALE_FACTORS[this.currentTextScale()]);

  constructor() {
    // 1. Restore from localStorage (instant, no flash)
    this.restoreTextScale();

    // 2. Bridge: sync from PreferenceService (API source of truth)
    effect(() => {
      const apiScale = this.preferenceService.textScale();
      const localScale = API_TO_LOCAL[apiScale];
      if (localScale && localScale !== this.currentTextScale()) {
        this.currentTextScale.set(localScale);
        this.cacheToLocalStorage(localScale);
      }
    });

    // 3. Apply CSS effect
    effect(() => {
      document.documentElement.style.fontSize =
        SCALE_FACTORS[this.currentTextScale()] * 100 + '%';
    });
  }

  setTextScale(scale: TextScale): void {
    this.currentTextScale.set(scale);
    this.cacheToLocalStorage(scale);
    this.preferenceService.updateTextScale(LOCAL_TO_API[scale]);
  }

  private restoreTextScale(): void {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored && VALID_SCALES.includes(stored as TextScale)) {
        this.currentTextScale.set(stored as TextScale);
      }
    } catch {
      this.logger.error('localStorage indisponible');
    }
  }

  private cacheToLocalStorage(scale: TextScale): void {
    try {
      localStorage.setItem(STORAGE_KEY, scale);
    } catch {
      this.logger.error('localStorage indisponible');
    }
  }
}
