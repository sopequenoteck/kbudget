import { TestBed } from '@angular/core/testing';
import { provideZonelessChangeDetection } from '@angular/core';
import { Router } from '@angular/router';

import { AcceptInvite } from './accept-invite';
import { AuthService } from '../../../../core/services/auth';
import { InvitationService } from '../../../../core/services/invitation.service';

describe('AcceptInvite', () => {
  let component: AcceptInvite;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideZonelessChangeDetection(),
        { provide: AuthService, useValue: { acceptInvite: vi.fn() } },
        { provide: InvitationService, useValue: { lookup: vi.fn() } },
        { provide: Router, useValue: { navigateByUrl: vi.fn() } },
      ],
    });

    const fixture = TestBed.createComponent(AcceptInvite);
    fixture.componentRef.setInput('token', 'un-token');
    component = fixture.componentInstance;
  });

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
    // pourtant validee cote client.
    component.form.controls.password.setValue('onzeCarac12');

    expect(component.form.controls.password.hasError('minlength')).toBe(true);
    expect(component.passwordMinLengthMessage).toBe('12 caractères minimum');
    expect(component.passwordPlaceholder).toBe('Au moins 12 caractères');
  });
});
