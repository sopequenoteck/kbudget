import { TestBed } from '@angular/core/testing';

import { ThemeService } from './theme';

const DARK_SURFACE = '#1e1e1e';
const LIGHT_SURFACE = '#f5f5f5';

/** jsdom n'a pas les feuilles SCSS : un jeu de tokens minimal les remplace. */
function installThemeTokens(): HTMLStyleElement {
  const style = document.createElement('style');
  style.textContent = `
    :root, .theme-light { --surface-raised: ${LIGHT_SURFACE}; }
    .theme-dark { --surface-raised: ${DARK_SURFACE}; }
  `;
  document.head.appendChild(style);
  return style;
}

function installThemeColorMeta(): HTMLMetaElement {
  const meta = document.createElement('meta');
  meta.name = 'theme-color';
  meta.content = DARK_SURFACE;
  document.head.appendChild(meta);
  return meta;
}

function themeColor(meta: HTMLMetaElement): string {
  return meta.getAttribute('content') ?? '';
}

describe('ThemeService — theme-color', () => {
  let tokens: HTMLStyleElement;
  let meta: HTMLMetaElement;
  let systemDark: boolean;
  let systemListener: ((event: { matches: boolean }) => void) | null;

  const createService = (): ThemeService => {
    const service = TestBed.inject(ThemeService);
    TestBed.tick();
    return service;
  };

  beforeEach(() => {
    localStorage.clear();
    tokens = installThemeTokens();
    meta = installThemeColorMeta();
    systemDark = false;
    systemListener = null;
    vi.stubGlobal('matchMedia', () => ({
      get matches() {
        return systemDark;
      },
      addEventListener: (_type: string, listener: (event: { matches: boolean }) => void) => {
        systemListener = listener;
      },
    }));
  });

  afterEach(() => {
    tokens.remove();
    meta.remove();
    document.documentElement.classList.remove('theme-light', 'theme-dark');
    vi.unstubAllGlobals();
  });

  it('should_set_theme_color_to_the_dark_header_surface_when_theme_is_dark', () => {
    const service = createService();

    service.setTheme('dark');
    TestBed.tick();

    expect(themeColor(meta)).toBe(DARK_SURFACE);
  });

  it('should_set_theme_color_to_the_light_header_surface_when_theme_is_light', () => {
    const service = createService();

    service.setTheme('light');
    TestBed.tick();

    expect(themeColor(meta)).toBe(LIGHT_SURFACE);
  });

  it('should_follow_the_system_theme_when_theme_is_auto', () => {
    systemDark = false;
    const service = createService();

    service.setTheme('auto');
    TestBed.tick();

    expect(themeColor(meta)).toBe(LIGHT_SURFACE);
  });

  it('should_update_theme_color_when_the_system_theme_flips_in_auto_mode', () => {
    const service = createService();
    service.setTheme('auto');
    TestBed.tick();

    systemListener?.({ matches: true });
    TestBed.tick();

    expect(themeColor(meta)).toBe(DARK_SURFACE);
  });

  it('should_restore_theme_color_from_the_stored_theme_when_the_service_starts', () => {
    localStorage.setItem('budget_theme', 'light');

    createService();

    expect(themeColor(meta)).toBe(LIGHT_SURFACE);
  });

  it('should_keep_theme_color_untouched_when_the_token_is_not_resolved', () => {
    tokens.remove();
    const service = createService();

    service.setTheme('dark');
    TestBed.tick();

    expect(themeColor(meta)).toBe(DARK_SURFACE);
  });

  it('should_not_fail_when_the_theme_color_meta_is_missing', () => {
    meta.remove();
    const service = createService();

    expect(() => {
      service.setTheme('light');
      TestBed.tick();
    }).not.toThrow();
  });
});
