import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { Fab } from './fab';
import { AccountService } from '../../../core/services/account';
import { PreferenceService } from '../../../core/services/preference';
import { type Account, AccountType } from '../../../core/models/account.model';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';

const activeAccount = (id: string): Account => ({
  id,
  nom: `Compte ${id}`,
  type: AccountType.COURANT,
  soldeInitial: 0,
  solde: 0,
  icone: '🏦',
  couleur: '#4f46e5',
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
});

describe('Fab', () => {
  let accountServiceMock: { getAll: ReturnType<typeof vi.fn> };
  let preferenceServiceMock: { isEnabled: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    accountServiceMock = {
      getAll: vi.fn().mockReturnValue(of([activeAccount('1'), activeAccount('2')])),
    };
    preferenceServiceMock = {
      isEnabled: vi.fn().mockReturnValue(true),
    };

    TestBed.configureTestingModule({
      imports: [Fab],
      providers: [
        ...provideTranslocoTesting(),
        { provide: AccountService, useValue: accountServiceMock },
        { provide: PreferenceService, useValue: preferenceServiceMock },
      ],
    });
  });

  function createFixture(currentRoute = '/dashboard') {
    const fixture = TestBed.createComponent(Fab);
    fixture.componentRef.setInput('isOpen', false);
    fixture.componentRef.setInput('currentRoute', currentRoute);
    fixture.detectChanges();
    return fixture;
  }

  it('should_create_the_component', () => {
    const fixture = createFixture();
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_expose_label_keys_for_base_actions_when_all_features_enabled', () => {
    const fixture = createFixture();

    const labelKeys = fixture.componentInstance.actions().map((a) => a.labelKey);

    expect(labelKeys).toEqual([
      'transactions.action.create',
      'subscriptions.action.create',
      'debts.action.create',
      'transactions.action.transfer',
    ]);
  });

  it('should_render_french_labels_in_the_dom_when_menu_open', () => {
    const fixture = createFixture();
    fixture.componentRef.setInput('isOpen', true);
    fixture.detectChanges();

    const labels = Array.from(
      fixture.nativeElement.querySelectorAll('.speed-dial-label') as NodeListOf<HTMLElement>,
    ).map((el) => el.textContent?.trim());

    expect(labels).toEqual(['Transaction', 'Abonnement', 'Dette', 'Virement']);
  });

  it('should_exclude_subscription_action_when_feature_disabled', () => {
    preferenceServiceMock.isEnabled.mockImplementation((f: string) => f !== 'SUBSCRIPTIONS');
    const fixture = createFixture();

    const labelKeys = fixture.componentInstance.actions().map((a) => a.labelKey);

    expect(labelKeys).not.toContain('subscriptions.action.create');
  });

  it('should_exclude_debt_action_when_feature_disabled', () => {
    preferenceServiceMock.isEnabled.mockImplementation((f: string) => f !== 'DEBTS');
    const fixture = createFixture();

    const labelKeys = fixture.componentInstance.actions().map((a) => a.labelKey);

    expect(labelKeys).not.toContain('debts.action.create');
  });

  it('should_exclude_transfer_action_when_not_on_dashboard', () => {
    const fixture = createFixture('/settings');

    const labelKeys = fixture.componentInstance.actions().map((a) => a.labelKey);

    expect(labelKeys).not.toContain('transactions.action.transfer');
  });

  it('should_show_only_budget_action_when_on_budgets_route_and_feature_enabled', () => {
    const fixture = createFixture('/budgets');

    const labelKeys = fixture.componentInstance.actions().map((a) => a.labelKey);

    expect(labelKeys).toEqual(['budgets.dialog.createTitle']);
  });

  it('should_render_french_quick_actions_aria_label', () => {
    const fixture = createFixture();

    const fabButton: HTMLButtonElement = fixture.nativeElement.querySelector('.fab-button');

    expect(fabButton.getAttribute('aria-label')).toBe('Actions rapides');
  });
});
