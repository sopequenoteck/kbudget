import { ComponentFixture, getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { AccountBankIcon } from './account-bank-icon';
import { Account, AccountType } from '../../../core/models/account.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const makeAccount = (overrides: Partial<Account> = {}): Account => ({
  id: '1',
  nom: 'Test',
  type: 'COURANT' as AccountType,
  soldeInitial: 0,
  solde: 100,
  icone: '🏦',
  couleur: '#3b82f6',
  isDefault: false,
  actif: true,
  currency: 'EUR',
  bankCode: 'OTHER',
  bankName: null,
  bankCountry: null,
  bankBrandColor: null,
  bankLogoUrl: null,
  bankCustomName: null,
  bankCustomLogo: null,
  ...overrides,
});

@Component({
  template: `<app-account-bank-icon [account]="account()" />`,
  imports: [AccountBankIcon],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
class TestHost {
  readonly account = signal<Account>(makeAccount());
}

describe('AccountBankIcon', () => {
  let fixture: ComponentFixture<TestHost>;
  let host: TestHost;
  let element: HTMLElement;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [TestHost],
    }).compileComponents();

    fixture = TestBed.createComponent(TestHost);
    host = fixture.componentInstance;
    fixture.detectChanges();
    element = fixture.nativeElement.querySelector('app-account-bank-icon');
  });

  describe('should_display_svg_logo_when_known_bank', () => {
    it('should display img with correct src when bankCode is a known bank with a logo URL', () => {
      host.account.set(
        makeAccount({
          bankCode: 'SG',
          bankLogoUrl: '/api/bank-logos/sg.svg',
          bankName: 'Société Générale',
        }),
      );
      fixture.detectChanges();

      const img = element.querySelector('img.account-bank-icon__img') as HTMLImageElement;
      expect(img).toBeTruthy();
      expect(img.src).toContain('/api/bank-logos/sg.svg');
    });

    it('should not display emoji span when known bank logo is shown', () => {
      host.account.set(
        makeAccount({
          bankCode: 'SG',
          bankLogoUrl: '/api/bank-logos/sg.svg',
        }),
      );
      fixture.detectChanges();

      const emojiSpan = element.querySelector('.account-bank-icon__emoji');
      expect(emojiSpan).toBeNull();
    });
  });

  describe('should_display_custom_logo_when_other_with_logo', () => {
    it('should display img with base64 src when bankCode is OTHER and bankCustomLogo is set', () => {
      host.account.set(
        makeAccount({
          bankCode: 'OTHER',
          bankCustomLogo: 'data:image/jpeg;base64,abc',
        }),
      );
      fixture.detectChanges();

      const img = element.querySelector('img.account-bank-icon__img') as HTMLImageElement;
      expect(img).toBeTruthy();
      expect(img.src).toContain('data:image/jpeg;base64,abc');
    });

    it('should not display emoji span when custom logo is shown', () => {
      host.account.set(
        makeAccount({
          bankCode: 'OTHER',
          bankCustomLogo: 'data:image/jpeg;base64,abc',
        }),
      );
      fixture.detectChanges();

      const emojiSpan = element.querySelector('.account-bank-icon__emoji');
      expect(emojiSpan).toBeNull();
    });
  });

  describe('should_display_emoji_when_other_without_logo', () => {
    it('should display emoji span when bankCode is OTHER and no custom logo', () => {
      host.account.set(
        makeAccount({
          bankCode: 'OTHER',
          bankCustomLogo: null,
        }),
      );
      fixture.detectChanges();

      const emojiSpan = element.querySelector('.account-bank-icon__emoji');
      expect(emojiSpan).toBeTruthy();
      expect(emojiSpan?.textContent?.trim()).toBe('🏦');
    });

    it('should not display img when bankCode is OTHER and no custom logo', () => {
      host.account.set(
        makeAccount({
          bankCode: 'OTHER',
          bankCustomLogo: null,
        }),
      );
      fixture.detectChanges();

      const img = element.querySelector('img.account-bank-icon__img');
      expect(img).toBeNull();
    });
  });

  describe('should_fallback_to_emoji_on_img_error', () => {
    it('should hide img and show emoji fallback when img emits an error event', () => {
      host.account.set(
        makeAccount({
          bankCode: 'SG',
          bankLogoUrl: '/api/bank-logos/sg.svg',
        }),
      );
      fixture.detectChanges();

      const img = element.querySelector('img.account-bank-icon__img') as HTMLImageElement;
      expect(img).toBeTruthy();

      const fallback = element.querySelector(
        '.account-bank-icon__emoji-fallback',
      ) as HTMLElement;
      expect(fallback).toBeTruthy();
      expect(fallback.style.display).toBe('none');

      img.dispatchEvent(new Event('error', { bubbles: false }));

      expect(img.style.display).toBe('none');
      expect(fallback.style.display).toBe('inline');
    });

    it('should show account icone in fallback span after img error', () => {
      host.account.set(
        makeAccount({
          bankCode: 'SG',
          bankLogoUrl: '/api/bank-logos/sg.svg',
          icone: '🏦',
        }),
      );
      fixture.detectChanges();

      const img = element.querySelector('img.account-bank-icon__img') as HTMLImageElement;
      img.dispatchEvent(new Event('error', { bubbles: false }));

      const fallback = element.querySelector(
        '.account-bank-icon__emoji-fallback',
      ) as HTMLElement;
      expect(fallback.textContent?.trim()).toBe('🏦');
    });
  });
});
