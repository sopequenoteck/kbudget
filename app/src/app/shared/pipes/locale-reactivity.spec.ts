import { ChangeDetectionStrategy, Component } from '@angular/core';
import { TestBed } from '@angular/core/testing';

import { AmountPipe } from './amount.pipe';
import { RelativeDatePipe } from './relative-date.pipe';
import { ShortDatePipe } from './short-date.pipe';
import { PreferenceService } from '../../core/services/preference';
import { provideTranslocoTesting } from '../../../testing/transloco-testing';

function isoDate(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function daysAgo(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return isoDate(d);
}

function daysFromNow(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return isoDate(d);
}

// > 30 jours : RelativeDatePipe bascule sur son `longDateFormatter` (module-
// level, mis en cache par locale). > 1 jour : ShortDatePipe bascule sur
// `toLocaleDateString` plutot que sur "demain"/"hier".
const FAR_PAST_ISO = daysAgo(45);
const NEAR_FUTURE_ISO = daysFromNow(5);

@Component({
  standalone: true,
  imports: [AmountPipe, RelativeDatePipe, ShortDatePipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <span class="amount">{{ amount | amount }}</span>
    <span class="relative">{{ farPast | relativeDate }}</span>
    <span class="short">{{ nearFuture | shortDate }}</span>
  `,
})
class LocaleReactivityHost {
  readonly amount = 1234.5;
  readonly farPast = FAR_PAST_ISO;
  readonly nearFuture = NEAR_FUTURE_ISO;
}

describe('Reactivite locale des pipes de formatage (KKS-373, SC-005)', () => {
  it('should_update_rendered_amount_and_dates_when_language_switches_to_en_without_recreating_fixture', async () => {
    // Arrange
    TestBed.configureTestingModule({
      providers: [provideTranslocoTesting()],
    });

    const fixture = TestBed.createComponent(LocaleReactivityHost);
    fixture.detectChanges();

    const preferenceService = TestBed.inject(PreferenceService);

    const amountEl: HTMLElement = fixture.nativeElement.querySelector('.amount');
    const relativeEl: HTMLElement = fixture.nativeElement.querySelector('.relative');
    const shortEl: HTMLElement = fixture.nativeElement.querySelector('.short');

    const expectedAmountFr = new Intl.NumberFormat('fr-FR', {
      style: 'currency',
      currency: 'EUR',
      signDisplay: 'never',
    }).format(1234.5);
    const expectedRelativeFr = new Intl.DateTimeFormat('fr-FR', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    }).format(new Date(FAR_PAST_ISO));
    const expectedShortFr = new Date(`${NEAR_FUTURE_ISO}T00:00:00`).toLocaleDateString('fr-FR', {
      day: 'numeric',
      month: 'short',
    });

    // Assert — rendu initial en francais (D2 : langue par defaut, aucun changement visible)
    expect(amountEl.textContent?.trim()).toBe(expectedAmountFr);
    expect(relativeEl.textContent?.trim()).toBe(expectedRelativeFr);
    expect(shortEl.textContent?.trim()).toBe(expectedShortFr);

    // Act — bascule de langue sans jamais recreer le fixture ni le composant.
    // `activeLanguage` ne bascule qu'apres chargement du catalogue anglais
    // (KKS-380) : il faut laisser la promesse de `LanguageService` se
    // resoudre avant de relire le rendu.
    preferenceService.language.set('en');
    fixture.detectChanges();
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
    fixture.detectChanges();

    const expectedAmountEn = new Intl.NumberFormat('en-GB', {
      style: 'currency',
      currency: 'EUR',
      signDisplay: 'never',
    }).format(1234.5);
    const expectedRelativeEn = new Intl.DateTimeFormat('en-GB', {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    }).format(new Date(FAR_PAST_ISO));
    const expectedShortEn = new Date(`${NEAR_FUTURE_ISO}T00:00:00`).toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'short',
    });

    // Assert — la meme vue reflete desormais en-GB : la cache de formatters
    // (amount, relativeDate) suit la locale plutot que de la figer, et le
    // pipe impur (shortDate) est bien reevalue par Angular.
    expect(amountEl.textContent?.trim()).toBe(expectedAmountEn);
    expect(relativeEl.textContent?.trim()).toBe(expectedRelativeEn);
    expect(shortEl.textContent?.trim()).toBe(expectedShortEn);

    // Sanity — le changement de langue a bien produit un rendu different,
    // sinon les assertions ci-dessus seraient vraies par coincidence.
    expect(expectedAmountFr).not.toBe(expectedAmountEn);
    expect(expectedRelativeFr).not.toBe(expectedRelativeEn);
  });
});
