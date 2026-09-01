import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { signal } from '@angular/core';

import { Incompatible } from './incompatible';
import { CompatibilityService } from '../../core/services/compatibility';
import { type CompatibilityStatus } from '../../core/models/meta.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

function render(status: CompatibilityStatus) {
  TestBed.configureTestingModule({
    imports: [Incompatible],
    providers: [
      {
        provide: CompatibilityService,
        useValue: { status: signal<CompatibilityStatus | null>(status) },
      },
    ],
  });

  const fixture = TestBed.createComponent(Incompatible);
  fixture.detectChanges();
  return fixture;
}

describe('Incompatible', () => {
  afterEach(() => {
    TestBed.resetTestingModule();
  });

  it('should_show_client_update_message_when_client_too_old', () => {
    const fixture = render({
      kind: 'clientTooOld',
      clientVersion: '5.0.0',
      requiredVersion: '6.1.0',
    });
    const text = (fixture.nativeElement as HTMLElement).textContent ?? '';

    expect(text).toContain('Application à mettre à jour');
    expect(text).toContain('6.1.0');
    expect(text).toContain('5.0.0');
  });

  it('should_show_server_update_message_when_server_too_old', () => {
    const fixture = render({
      kind: 'serverTooOld',
      serverVersion: '5.4.0',
      requiredVersion: '6.1.0',
    });
    const text = (fixture.nativeElement as HTMLElement).textContent ?? '';

    expect(text).toContain('Serveur à mettre à jour');
    expect(text).toContain('5.4.0');
    expect(text).toContain('6.1.0');
  });

  it('should_explain_absence_of_version_when_server_predates_meta', () => {
    // serverVersion null : le serveur est anterieur a /api/meta, il ne sait pas
    // annoncer sa version. Le message ne doit pas afficher un trou.
    const fixture = render({
      kind: 'serverTooOld',
      serverVersion: null,
      requiredVersion: '6.1.0',
    });
    const text = (fixture.nativeElement as HTMLElement).textContent ?? '';

    expect(text).toContain('trop ancien pour indiquer sa version');
    expect(text).not.toContain('null');
  });

  it('should_never_expose_a_technical_error_message', () => {
    // La raison d'etre de cet ecran : remplacer l'erreur de deserialisation
    // incomprehensible par un message actionnable.
    const fixture = render({
      kind: 'serverTooOld',
      serverVersion: '5.4.0',
      requiredVersion: '6.1.0',
    });
    const text = ((fixture.nativeElement as HTMLElement).textContent ?? '').toLowerCase();

    for (const forbidden of ['json', 'http', 'undefined', 'exception', '404']) {
      expect(text).not.toContain(forbidden);
    }
  });

  it('should_offer_a_retry_action', () => {
    const fixture = render({
      kind: 'serverTooOld',
      serverVersion: '5.4.0',
      requiredVersion: '6.1.0',
    });
    const button = (fixture.nativeElement as HTMLElement).querySelector('button');

    expect(button).not.toBeNull();
    expect(button?.textContent).toContain('Réessayer');
  });
});
