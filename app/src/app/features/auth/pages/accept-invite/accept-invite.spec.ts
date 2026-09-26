import { TestBed, ComponentFixture } from '@angular/core/testing';
import { provideZonelessChangeDetection } from '@angular/core';
import { Router } from '@angular/router';
import { TranslocoService } from '@jsverse/transloco';
import { of, throwError } from 'rxjs';

import { AcceptInvite } from './accept-invite';
import { AuthService } from '../../../../core/services/auth';
import { InvitationService } from '../../../../core/services/invitation.service';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

describe('AcceptInvite', () => {
  let component: AcceptInvite;
  let fixture: ComponentFixture<AcceptInvite>;
  let invitationServiceMock: { lookup: ReturnType<typeof vi.fn>; accept: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    invitationServiceMock = { lookup: vi.fn(), accept: vi.fn() };

    TestBed.configureTestingModule({
      providers: [
        provideZonelessChangeDetection(),
        provideTranslocoTesting(),
        { provide: AuthService, useValue: { saveAuthResponse: vi.fn() } },
        { provide: InvitationService, useValue: invitationServiceMock },
        { provide: Router, useValue: { navigate: vi.fn() } },
      ],
    });

    fixture = TestBed.createComponent(AcceptInvite);
    fixture.componentRef.setInput('token', 'un-token');
    component = fixture.componentInstance;
  });

  function fillValidForm(): void {
    component.form.setValue({
      password: 'motDePasse12',
      displayName: 'Alice',
      currency: 'EUR',
      timezone: 'Europe/Paris',
    });
  }

  it('should_reject_password_one_char_below_minimum', () => {
    // 11 caracteres : la limite exacte. Avant KKS-351 ce parcours acceptait
    // 8 caracteres, la ou la premiere connexion en exigeait 12 — deux regles
    // pour le meme geste, choisir son mot de passe.
    component.form.controls.password.setValue('onzeCarac12');

    expect(component.form.controls.password.hasError('minlength')).toBe(true);
  });

  it('should_accept_password_at_exact_minimum', () => {
    component.form.controls.password.setValue('motDePasse12');

    expect(component.form.controls.password.hasError('minlength')).toBe(false);
  });

  it('should_announce_the_same_minimum_as_the_validator', () => {
    // Le texte affiche et le validateur viennent de la meme constante : c'est
    // leur divergence qui produisait une 400 en anglais apres une saisie
    // pourtant validee cote client. La constante alimente desormais les
    // parametres ICU des cles de traduction plutot qu'un texte fige.
    const transloco = TestBed.inject(TranslocoService);
    component.form.controls.password.setValue('onzeCarac12');

    expect(component.form.controls.password.hasError('minlength')).toBe(true);
    expect(
      transloco.translate('auth.form.passwordMinLength', { min: component.passwordMinLength }),
    ).toBe('12 caractères minimum');
    expect(
      transloco.translate('auth.form.passwordPlaceholder', { min: component.passwordMinLength }),
    ).toBe('Au moins 12 caractères');
  });

  it('should_translate_the_invalid_link_error_when_the_invitation_lookup_fails', async () => {
    invitationServiceMock.lookup.mockReturnValue(throwError(() => new Error('not found')));

    await component.ngOnInit();

    expect(component.error()).toBe('Lien invalide, expiré, déjà utilisé ou révoqué.');
    expect(component.loading()).toBe(false);
  });

  it('should_translate_the_invalid_link_error_when_accept_returns_a_404', async () => {
    fillValidForm();
    invitationServiceMock.accept.mockReturnValue(
      throwError(() => ({ status: 404, error: { message: 'not found' } })),
    );

    await component.onSubmit();

    expect(component.error()).toBe('Lien invalide, expiré, déjà utilisé ou révoqué.');
  });

  it('should_translate_the_invalid_form_data_error_when_accept_returns_a_400', async () => {
    fillValidForm();
    invitationServiceMock.accept.mockReturnValue(
      throwError(() => ({ status: 400, error: { message: 'bad request' } })),
    );

    await component.onSubmit();

    expect(component.error()).toBe('Données invalides. Vérifiez le formulaire.');
  });

  it('should_translate_the_generic_error_when_accept_fails_with_an_unhandled_status', async () => {
    fillValidForm();
    invitationServiceMock.accept.mockReturnValue(
      throwError(() => ({ status: 500, error: { message: 'boom' } })),
    );

    await component.onSubmit();

    expect(component.error()).toBe('Une erreur est survenue. Veuillez réessayer.');
  });

  // ---------------------------------------------------------------------
  // Selecteur de devise — symbole + nom traduit (KKS-393)
  // ---------------------------------------------------------------------

  it('should_render_currency_options_with_symbol_and_translated_french_name', async () => {
    invitationServiceMock.lookup.mockReturnValue(of({ email: 'alice@example.com' }));

    await component.ngOnInit();
    fixture.detectChanges();

    const options = Array.from(
      fixture.nativeElement.querySelectorAll('#accept-currency option'),
    ).map((o) => (o as HTMLOptionElement).textContent);

    // "Dollar américain" devient "Dollar US", changement assume par KKS-393.
    expect(options).toEqual([
      '€ - Euro',
      '$ - Dollar US',
      'CFA - Franc CFA (BCEAO)',
      '£ - Livre sterling',
      'CHF - Franc suisse',
      'CA$ - Dollar canadien',
      'MAD - Dirham marocain',
    ]);
  });
});
