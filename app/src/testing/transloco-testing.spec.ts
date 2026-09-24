import { TestBed } from '@angular/core/testing';
import { TranslocoService } from '@jsverse/transloco';

import { provideTranslocoTesting } from './transloco-testing';

// Preuve d'usage de l'utilitaire de test (D10, FR-033, SC-012) : un spec qui
// l'importe et ne fait rien d'autre resout deja une cle reelle du catalogue
// francais, sans mock de traduction ni configuration additionnelle.
describe('provideTranslocoTesting', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [provideTranslocoTesting()],
    });
  });

  it('should_resolve_a_real_french_key_with_no_extra_configuration', () => {
    // Act
    const transloco = TestBed.inject(TranslocoService);

    // Assert
    expect(transloco.getActiveLang()).toBe('fr');
    expect(transloco.translate('errors.client.generic')).toBe('Une erreur est survenue');
  });

  it('should_resolve_a_real_english_key_when_active_lang_is_switched', () => {
    // Arrange
    const transloco = TestBed.inject(TranslocoService);
    transloco.setActiveLang('en');
    transloco.load('en').subscribe();

    // Act & Assert
    expect(transloco.translate('errors.client.generic')).toBe('An error occurred');
  });

  // Regle `interpolation: ['{', '}']`, Transloco interpolait avant
  // MessageFormat et vidait le bloc de pluriel : « 0 paiement pour Bob » devenait
  // «  pour Bob ». Le pluriel francais couvre 0 et 1 (categorie `one`).
  it('should_render_icu_plural_and_simple_param_when_both_are_in_one_string', () => {
    // Arrange
    const transloco = TestBed.inject(TranslocoService);
    transloco.setTranslation(
      {
        probe: {
          list: { count: '{count, plural, one {# paiement} other {# paiements}} pour {name}' },
        },
      },
      'fr',
      { merge: true },
    );

    // Act
    const rendered = [0, 1, 5].map((count) =>
      transloco.translate('probe.list.count', { count, name: 'Bob' }),
    );

    // Assert
    expect(rendered).toEqual([
      '0 paiement pour Bob',
      '1 paiement pour Bob',
      '5 paiements pour Bob',
    ]);
  });
});
