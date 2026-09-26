import { describe, it, expect, beforeEach } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';

import { CategoryNamePipe } from './category-name.pipe';
import { PreferenceService } from '../../core/services/preference';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

describe('CategoryNamePipe', () => {
  let pipe: CategoryNamePipe;

  beforeEach(() => {
    // KKS-395 (D8, precedent amount.pipe) : le pipe injecte LanguageService
    // (impur, suit la langue active) — TestBed remplace `new`.
    TestBed.configureTestingModule({
      providers: [provideTranslocoTesting()],
    });
    pipe = TestBed.runInInjectionContext(() => new CategoryNamePipe());
  });

  it('should_translate_the_system_category_name_in_french_when_system_key_is_known', () => {
    // Assert — KKS-395 : la traduction remplace le `nom` brut cote serveur,
    // ici volontairement different pour prouver que l'affichage ne depend
    // plus de `nom`.
    expect(pipe.transform('Abonnement-legacy', 'SUBSCRIPTION')).toBe('Abonnement');
    expect(pipe.transform('Dette-legacy', 'DEBT')).toBe('Dette');
    expect(pipe.transform('Virement-legacy', 'TRANSFER')).toBe('Virement');
    expect(pipe.transform('Ajustement-legacy', 'ADJUSTMENT')).toBe('Ajustement');
  });

  it('should_translate_the_system_category_name_in_english_when_active_language_switches', async () => {
    // `activeLanguage` ne bascule qu'apres chargement du catalogue anglais
    // (KKS-380) : `TestBed.tick()` flushe l'effet de `LanguageService` avant
    // de laisser la promesse se resoudre.
    const preferenceService = TestBed.inject(PreferenceService);
    TestBed.inject(TranslocoService).load('en').subscribe();
    preferenceService.language.set('en');
    TestBed.tick();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(pipe.transform('Abonnement-legacy', 'SUBSCRIPTION')).toBe('Subscription');
  });

  it('should_return_the_raw_name_when_category_is_a_user_category', () => {
    expect(pipe.transform('Courses', null)).toBe('Courses');
    expect(pipe.transform('Courses', undefined)).toBe('Courses');
  });

  it('should_return_the_raw_name_when_system_key_is_unknown_to_this_client', () => {
    // Un serveur plus recent peut envoyer une clef que ce client ne connait pas.
    expect(pipe.transform('Nouvelle categorie systeme', 'SOMETHING_NEW')).toBe(
      'Nouvelle categorie systeme',
    );
  });

  it('should_return_empty_string_when_name_is_null_or_undefined_and_no_system_key', () => {
    expect(pipe.transform(null)).toBe('');
    expect(pipe.transform(undefined)).toBe('');
  });
});
