import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';

import { LanguageService, provideLanguageBootstrap } from './language';
import { PreferenceService } from './preference';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

describe('LanguageService', () => {
  let service: LanguageService;
  let preferenceService: PreferenceService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideTranslocoTesting()],
    });
    service = TestBed.inject(LanguageService);
    preferenceService = TestBed.inject(PreferenceService);
  });

  it('should_use_french_when_preference_is_null', () => {
    // Assert — preference.language vaut null par defaut (aucun choix, D2).
    expect(service.activeLanguage()).toBe('fr');
    expect(service.displayLocale()).toBe('fr-FR');
  });

  it('should_use_british_locale_when_preference_is_english', () => {
    // Act
    preferenceService.language.set('en');

    // Assert
    expect(service.activeLanguage()).toBe('en');
    expect(service.displayLocale()).toBe('en-GB');
  });

  it('should_fall_back_to_french_when_preference_is_an_unsupported_regional_code', () => {
    // Arrange — motif BCP 47 valide (D1), mais aucun catalogue ne sert `pt`.
    preferenceService.language.set('pt-BR');

    // Act & Assert — ne doit jamais produire de locale invalide.
    expect(service.activeLanguage()).toBe('fr');
    expect(service.displayLocale()).toBe('fr-FR');
  });

  it('should_fall_back_to_french_when_preference_is_an_unknown_code', () => {
    // Arrange
    preferenceService.language.set('xx');

    // Act & Assert
    expect(service.activeLanguage()).toBe('fr');
    expect(service.displayLocale()).toBe('fr-FR');
  });

  it('should_keep_transloco_active_lang_in_sync_with_the_derived_language', () => {
    // Arrange
    const transloco = TestBed.inject(TranslocoService);

    // Act
    preferenceService.language.set('en');
    TestBed.tick();

    // Assert
    expect(transloco.getActiveLang()).toBe('en');
  });
});

describe('provideLanguageBootstrap', () => {
  it('should_sync_transloco_active_lang_when_preference_changes_without_injecting_language_service', () => {
    // Arrange — aucun consommateur n'injecte LanguageService (pas de pipe,
    // pas de composant) : seul provideLanguageBootstrap() la met en route,
    // exactement comme dans app.config.ts (KKS-373, defect de la passe
    // precedente).
    TestBed.configureTestingModule({
      providers: [provideTranslocoTesting(), provideLanguageBootstrap()],
    });

    // Act — force la creation de l'injecteur d'environnement (et donc des
    // ENVIRONMENT_INITIALIZER) sans jamais demander LanguageService.
    const preferenceService = TestBed.inject(PreferenceService);
    const transloco = TestBed.inject(TranslocoService);
    preferenceService.language.set('en');
    TestBed.tick();

    // Assert
    expect(transloco.getActiveLang()).toBe('en');
  });
});
