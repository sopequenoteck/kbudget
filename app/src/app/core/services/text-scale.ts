import { Injectable, computed, effect, isDevMode, signal } from '@angular/core';

export type TextScale = 'small' | 'medium' | 'large';

export const SCALE_FACTORS: Record<TextScale, number> = {
  small: 0.85,
  medium: 1.0,
  large: 1.3,
};

const STORAGE_KEY = 'budget_text_scale';
const VALID_SCALES: TextScale[] = ['small', 'medium', 'large'];

@Injectable({
  providedIn: 'root',
})
export class TextScaleService {
  readonly currentTextScale = signal<TextScale>('medium');

  readonly scaleFactor = computed(() => SCALE_FACTORS[this.currentTextScale()]);

  constructor() {
    this.restoreTextScale();

    effect(() => {
      document.documentElement.style.fontSize =
        SCALE_FACTORS[this.currentTextScale()] * 100 + '%';
    });
  }

  setTextScale(scale: TextScale): void {
    this.currentTextScale.set(scale);
    try {
      localStorage.setItem(STORAGE_KEY, scale);
    } catch {
      if (isDevMode()) console.error('localStorage indisponible');
    }
  }

  private restoreTextScale(): void {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored && VALID_SCALES.includes(stored as TextScale)) {
        this.currentTextScale.set(stored as TextScale);
      }
    } catch {
      if (isDevMode()) console.error('localStorage indisponible');
    }
  }
}
