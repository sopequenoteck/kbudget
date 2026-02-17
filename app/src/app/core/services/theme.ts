import { Injectable, computed, effect, isDevMode, signal } from '@angular/core';

export type Theme = 'light' | 'dark' | 'auto';

const STORAGE_KEY = 'budget_theme';
const VALID_THEMES: Theme[] = ['light', 'dark', 'auto'];

@Injectable({
  providedIn: 'root',
})
export class ThemeService {
  readonly currentTheme = signal<Theme>('light');

  readonly effectiveTheme = computed<'light' | 'dark'>(() => {
    const theme = this.currentTheme();
    if (theme === 'auto') {
      return this.systemPrefersDark() ? 'dark' : 'light';
    }
    return theme;
  });

  private readonly systemPrefersDark = signal(false);
  private mediaQuery: MediaQueryList | null = null;

  constructor() {
    this.initSystemPreference();
    this.restoreTheme();

    effect(() => {
      const effective = this.effectiveTheme();
      document.documentElement.classList.remove('theme-light', 'theme-dark');
      document.documentElement.classList.add(`theme-${effective}`);
      document.documentElement.style.colorScheme = effective;
    });
  }

  setTheme(theme: Theme): void {
    this.currentTheme.set(theme);
    try {
      localStorage.setItem(STORAGE_KEY, theme);
    } catch {
      if (isDevMode()) console.error('localStorage indisponible');
    }
  }

  private restoreTheme(): void {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored && VALID_THEMES.includes(stored as Theme)) {
        this.currentTheme.set(stored as Theme);
      }
    } catch {
      if (isDevMode()) console.error('localStorage indisponible');
    }
  }

  private initSystemPreference(): void {
    try {
      this.mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
      this.systemPrefersDark.set(this.mediaQuery.matches);
      this.mediaQuery.addEventListener('change', (e) => {
        this.systemPrefersDark.set(e.matches);
      });
    } catch {
      if (isDevMode()) console.error('matchMedia indisponible');
    }
  }
}
