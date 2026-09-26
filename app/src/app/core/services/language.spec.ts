import { inject } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Subject, of, throwError } from 'rxjs';
import { TRANSLOCO_LOADER, TranslocoService } from '@jsverse/transloco';

import {
  BROWSER_LANGUAGES,
  LANGUAGE_STORAGE,
  LanguageService,
  LanguageStorageLike,
  provideLanguageBootstrap,
  resolveBootstrapLanguage,
} from './language';
import { PreferenceService } from './preference';
import { DevLogger } from './dev-logger';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

function createMemoryStorage(initial?: Record<string, string>): LanguageStorageLike {
  const memory = new Map<string, string>(Object.entries(initial ?? {}));
  return {
    getItem: (key: string) => memory.get(key) ?? null,
    setItem: (key: string, value: string) => {
      memory.set(key, value);
    },
  };
}

async function flushMicrotasks(): Promise<void> {
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
}

describe('LanguageService', () => {
  let service: LanguageService;
  let preferenceService: PreferenceService;

  const setup = (
    providers: ReturnType<typeof provideTranslocoTesting> | unknown[] = [],
  ) => {
    TestBed.configureTestingModule({
      providers: [provideTranslocoTesting(), ...(providers as never[])],
    });
    service = TestBed.inject(LanguageService);
    preferenceService = TestBed.inject(PreferenceService);
  };

  describe('detection navigateur (avant chargement des preferences)', () => {
    it('should_resolve_french_when_browser_language_is_a_french_regional_code', () => {
      // Arrange — `fr-CA` doit se ramener a `fr` (D1, base du code BCP 47).
      setup([{ provide: BROWSER_LANGUAGES, useValue: ['fr-CA'] }]);

      // Assert
      expect(service.activeLanguage()).toBe('fr');
      expect(service.displayLocale()).toBe('fr-FR');
    });

    it('should_resolve_english_when_browser_language_is_unsupported', () => {
      // Arrange — `de` n'a pas de catalogue : repli sur l'anglais (D1).
      setup([{ provide: BROWSER_LANGUAGES, useValue: ['de'] }]);

      // Assert
      expect(service.activeLanguage()).toBe('en');
    });

    it('should_resolve_english_when_the_browser_language_list_is_empty', () => {
      // Arrange
      setup([{ provide: BROWSER_LANGUAGES, useValue: [] }]);

      // Assert
      expect(service.activeLanguage()).toBe('en');
    });
  });

  describe('stockage local (avant chargement des preferences)', () => {
    it('should_use_the_stored_language_when_valid', () => {
      // Arrange — navigateur anglais, mais l'appareil a deja tourne en francais.
      setup([
        { provide: BROWSER_LANGUAGES, useValue: ['en'] },
        { provide: LANGUAGE_STORAGE, useValue: createMemoryStorage({ 'kbudget.language': 'fr' }) },
      ]);

      // Assert
      expect(service.activeLanguage()).toBe('fr');
    });

    it('should_fall_back_to_the_browser_when_the_stored_value_is_invalid', () => {
      // Arrange
      setup([
        { provide: BROWSER_LANGUAGES, useValue: ['fr'] },
        { provide: LANGUAGE_STORAGE, useValue: createMemoryStorage({ 'kbudget.language': 'xx' }) },
      ]);

      // Assert
      expect(service.activeLanguage()).toBe('fr');
    });

    it('should_fall_back_to_the_browser_when_reading_storage_throws', () => {
      // Arrange
      const storage: LanguageStorageLike = {
        getItem: () => {
          throw new Error('denied');
        },
        setItem: () => {
          throw new Error('denied');
        },
      };
      setup([
        { provide: BROWSER_LANGUAGES, useValue: ['fr'] },
        { provide: LANGUAGE_STORAGE, useValue: storage },
      ]);

      // Assert — ne leve jamais, retombe sur le navigateur.
      expect(service.activeLanguage()).toBe('fr');
    });
  });

  describe('preference (une fois connue)', () => {
    it('should_let_a_non_null_preference_win_over_a_different_stored_language', async () => {
      // Arrange — stockage francais, mais l'utilisateur a choisi l'anglais.
      setup([
        { provide: BROWSER_LANGUAGES, useValue: ['fr'] },
        { provide: LANGUAGE_STORAGE, useValue: createMemoryStorage({ 'kbudget.language': 'fr' }) },
      ]);

      // Act
      preferenceService.language.set('en');
      TestBed.tick();
      await flushMicrotasks();

      // Assert
      expect(service.activeLanguage()).toBe('en');
      expect(service.displayLocale()).toBe('en-GB');
    });

    it('should_fall_back_to_the_browser_when_preferences_are_loaded_and_the_preference_is_null', async () => {
      // Arrange — le stockage pointe vers l'anglais, mais une fois les
      // preferences chargees, une preference nulle confirmee ignore le
      // stockage au profit du navigateur (D3).
      setup([
        { provide: BROWSER_LANGUAGES, useValue: ['fr'] },
        { provide: LANGUAGE_STORAGE, useValue: createMemoryStorage({ 'kbudget.language': 'en' }) },
      ]);

      // Act
      preferenceService.loaded.set(true);
      TestBed.tick();
      await flushMicrotasks();

      // Assert
      expect(service.activeLanguage()).toBe('fr');
    });

    it('should_fall_back_to_english_when_the_preference_is_an_unsupported_regional_code', async () => {
      // Arrange — motif BCP 47 valide (D1), mais aucun catalogue ne sert `pt`
      // : une preference non nulle l'emporte toujours, meme non supportee —
      // le navigateur francais n'intervient pas ici (D2, repli anglais).
      setup([{ provide: BROWSER_LANGUAGES, useValue: ['fr'] }]);

      // Act
      preferenceService.language.set('pt-BR');
      TestBed.tick();
      await flushMicrotasks();

      // Assert — ne doit jamais produire de locale invalide.
      expect(service.activeLanguage()).toBe('en');
      expect(service.displayLocale()).toBe('en-GB');
    });

    it('should_keep_transloco_active_lang_in_sync_with_the_preference', async () => {
      // Arrange
      setup([{ provide: BROWSER_LANGUAGES, useValue: ['fr'] }]);
      const transloco = TestBed.inject(TranslocoService);

      // Act
      preferenceService.language.set('en');
      TestBed.tick();
      await flushMicrotasks();

      // Assert
      expect(transloco.getActiveLang()).toBe('en');
    });
  });

  describe('bascule asynchrone (D4)', () => {
    it('should_only_change_the_applied_language_after_its_catalogue_has_loaded', async () => {
      // Arrange — le chargement de l'anglais reste en suspens.
      const en$ = new Subject<Record<string, string>>();
      const loader = {
        getTranslation: (lang: string) => (lang === 'en' ? en$.asObservable() : of({})),
      };
      setup([
        { provide: BROWSER_LANGUAGES, useValue: ['fr'] },
        { provide: TRANSLOCO_LOADER, useValue: loader },
      ]);
      await flushMicrotasks();
      expect(service.activeLanguage()).toBe('fr');

      // Act — demande l'anglais, dont le catalogue ne repond pas encore.
      preferenceService.language.set('en');
      TestBed.tick();
      await flushMicrotasks();

      // Assert — toujours l'ancienne langue, jamais de rendu intermediaire.
      expect(service.activeLanguage()).toBe('fr');

      // Act — le catalogue finit par charger.
      en$.next({});
      en$.complete();
      await flushMicrotasks();

      // Assert
      expect(service.activeLanguage()).toBe('en');
    });

    it('should_keep_the_previous_applied_language_when_loading_the_catalogue_fails', async () => {
      // Arrange
      const loader = {
        getTranslation: (lang: string) =>
          lang === 'en' ? throwError(() => new Error('network down')) : of({}),
      };
      setup([
        { provide: BROWSER_LANGUAGES, useValue: ['fr'] },
        { provide: TRANSLOCO_LOADER, useValue: loader },
      ]);
      await flushMicrotasks();
      const logger = TestBed.inject(DevLogger);
      const errorSpy = vi.spyOn(logger, 'error');

      // Act
      preferenceService.language.set('en');
      TestBed.tick();
      await flushMicrotasks();

      // Assert — garde le francais et journalise via DevLogger, ne leve pas.
      expect(service.activeLanguage()).toBe('fr');
      expect(errorSpy).toHaveBeenCalled();
    });

    it('should_apply_the_most_recently_requested_language_when_an_older_load_resolves_last', async () => {
      // Arrange — chaque appel a `getTranslation` pour une langue donnee
      // pousse un nouveau `Subject` controlable, pour resoudre les
      // chargements dans un ordre choisi independamment de l'ordre de
      // demande (KKS-380, correctif course).
      const pending: Record<string, Subject<Record<string, string>>[]> = { en: [], fr: [] };
      const loader = {
        getTranslation: (lang: string) => {
          const subject = new Subject<Record<string, string>>();
          pending[lang].push(subject);
          return subject.asObservable();
        },
      };
      setup([
        { provide: BROWSER_LANGUAGES, useValue: ['fr'] },
        { provide: TRANSLOCO_LOADER, useValue: loader },
      ]);
      const transloco = TestBed.inject(TranslocoService);

      // Resout le chargement initial (francais, depuis le navigateur).
      await flushMicrotasks();
      pending['fr'][0].next({});
      pending['fr'][0].complete();
      await flushMicrotasks();
      expect(service.activeLanguage()).toBe('fr');

      // Act — demande l'anglais, puis revient au francais avant que
      // l'anglais ait fini de charger.
      preferenceService.loaded.set(true);
      preferenceService.language.set('en');
      TestBed.tick();
      await flushMicrotasks();
      preferenceService.language.set(null);
      TestBed.tick();
      await flushMicrotasks();

      // Resout le francais (la demande la plus recente), puis l'anglais en
      // dernier — l'ordre inverse de la demande.
      pending['fr'][1].next({});
      pending['fr'][1].complete();
      await flushMicrotasks();
      pending['en'][0].next({});
      pending['en'][0].complete();
      await flushMicrotasks();

      // Assert — la resolution tardive de l'anglais ne doit pas ecraser le
      // francais, seule langue demandee restante.
      expect(service.activeLanguage()).toBe('fr');
      expect(transloco.getActiveLang()).toBe('fr');
    });

    it('should_log_but_not_throw_when_persisting_the_applied_language_fails', async () => {
      // Arrange
      const storage: LanguageStorageLike = {
        getItem: () => null,
        setItem: () => {
          throw new Error('quota exceeded');
        },
      };
      setup([
        { provide: BROWSER_LANGUAGES, useValue: ['fr'] },
        { provide: LANGUAGE_STORAGE, useValue: storage },
      ]);
      await flushMicrotasks();
      const errorSpy = vi.spyOn(TestBed.inject(DevLogger), 'error');

      // Act
      preferenceService.language.set('en');
      TestBed.tick();
      await flushMicrotasks();

      // Assert — la langue est bien appliquee, l'echec de persistance ne la
      // bloque pas et ne leve jamais.
      expect(service.activeLanguage()).toBe('en');
      expect(errorSpy).toHaveBeenCalled();
    });

    it('should_persist_the_applied_language_once_loaded', async () => {
      // Arrange
      const storage = createMemoryStorage();
      setup([
        { provide: BROWSER_LANGUAGES, useValue: ['fr'] },
        { provide: LANGUAGE_STORAGE, useValue: storage },
      ]);
      await flushMicrotasks();

      // Act
      preferenceService.language.set('en');
      TestBed.tick();
      await flushMicrotasks();

      // Assert
      expect(service.activeLanguage()).toBe('en');
      expect(storage.getItem('kbudget.language')).toBe('en');
    });
  });

  describe('detectedBrowserLanguage', () => {
    it('should_expose_the_browser_language_independently_of_the_preference', async () => {
      // Arrange
      setup([{ provide: BROWSER_LANGUAGES, useValue: ['fr'] }]);

      // Act — la preference change, la detection navigateur reste stable.
      preferenceService.language.set('en');
      TestBed.tick();
      await flushMicrotasks();

      // Assert
      expect(service.detectedBrowserLanguage).toBe('fr');
    });
  });
});

describe('BROWSER_LANGUAGES (fabrique par defaut)', () => {
  const setup = () => {
    TestBed.configureTestingModule({});
    return TestBed.runInInjectionContext(() => inject(BROWSER_LANGUAGES));
  };

  it('should_read_navigator_languages_when_available', () => {
    // Act — aucune surcharge : exerce la vraie fabrique par defaut (jsdom).
    const languages = setup();

    // Assert — ne leve jamais, produit toujours un tableau.
    expect(Array.isArray(languages)).toBe(true);
  });

  it('should_return_an_empty_list_when_reading_navigator_languages_throws', () => {
    // Arrange
    const original = Object.getOwnPropertyDescriptor(Navigator.prototype, 'languages');
    Object.defineProperty(Navigator.prototype, 'languages', {
      configurable: true,
      get: () => {
        throw new Error('denied');
      },
    });

    try {
      // Act & Assert — ne leve jamais.
      expect(setup()).toEqual([]);
    } finally {
      if (original) {
        Object.defineProperty(Navigator.prototype, 'languages', original);
      }
    }
  });
});

describe('LANGUAGE_STORAGE (fabrique par defaut)', () => {
  const setup = () => {
    TestBed.configureTestingModule({});
    return TestBed.runInInjectionContext(() => inject(LANGUAGE_STORAGE));
  };

  it('should_use_the_real_local_storage_when_available', () => {
    // Act — aucune surcharge : exerce la vraie fabrique par defaut (jsdom).
    const storage = setup();
    storage.setItem('kbudget.language', 'en');

    // Assert
    expect(storage.getItem('kbudget.language')).toBe('en');
    localStorage.removeItem('kbudget.language');
  });

  it('should_fall_back_to_an_in_memory_store_when_local_storage_throws', () => {
    // Arrange
    const original = Storage.prototype.setItem;
    Storage.prototype.setItem = () => {
      throw new Error('quota exceeded');
    };

    try {
      // Act
      const storage = setup();
      storage.setItem('kbudget.language', 'en');

      // Assert — la valeur vit en memoire, jamais dans le `localStorage` reel.
      expect(storage.getItem('kbudget.language')).toBe('en');
    } finally {
      Storage.prototype.setItem = original;
    }
  });
});

describe('resolveBootstrapLanguage', () => {
  it('should_prefer_the_stored_language_over_the_browser', () => {
    const storage = createMemoryStorage({ 'kbudget.language': 'fr' });
    expect(resolveBootstrapLanguage(storage, ['en'])).toBe('fr');
  });

  it('should_fall_back_to_the_browser_when_nothing_is_stored', () => {
    const storage = createMemoryStorage();
    expect(resolveBootstrapLanguage(storage, ['fr'])).toBe('fr');
  });
});

describe('provideLanguageBootstrap', () => {
  it('should_sync_transloco_active_lang_when_preference_changes_without_injecting_language_service', async () => {
    // Arrange — aucun consommateur n'injecte LanguageService (pas de pipe,
    // pas de composant) : seul provideLanguageBootstrap() la met en route,
    // exactement comme dans app.config.ts.
    TestBed.configureTestingModule({
      providers: [
        provideTranslocoTesting(),
        { provide: BROWSER_LANGUAGES, useValue: ['fr'] },
        provideLanguageBootstrap(),
      ],
    });

    // Act — force la creation de l'injecteur d'environnement (et donc des
    // ENVIRONMENT_INITIALIZER) sans jamais demander LanguageService.
    const preferenceService = TestBed.inject(PreferenceService);
    const transloco = TestBed.inject(TranslocoService);
    preferenceService.language.set('en');
    TestBed.tick();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    // Assert
    expect(transloco.getActiveLang()).toBe('en');
  });
});
