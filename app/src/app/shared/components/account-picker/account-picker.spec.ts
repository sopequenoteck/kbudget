import { getTestBed, TestBed, ComponentFixture } from '@angular/core/testing';
import {
  BrowserTestingModule,
  platformBrowserTesting,
} from '@angular/platform-browser/testing';

import { AccountPicker } from './account-picker';
import { Account, AccountType } from '../../../core/models/account.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockAccounts: Account[] = [
  {
    id: 'acc-1',
    nom: 'Courant',
    type: AccountType.COURANT,
    soldeInitial: 1000,
    solde: 1500,
    icone: '🏦',
    couleur: '#3b82f6',
    isDefault: true,
    actif: true,
  },
  {
    id: 'acc-2',
    nom: 'Épargne',
    type: AccountType.EPARGNE,
    soldeInitial: 5000,
    solde: 5000,
    icone: '💰',
    couleur: '#10b981',
    isDefault: false,
    actif: true,
  },
];

describe('AccountPicker', () => {
  let fixture: ComponentFixture<AccountPicker>;
  let component: AccountPicker;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [AccountPicker],
    });

    fixture = TestBed.createComponent(AccountPicker);
    component = fixture.componentInstance;
  });

  it('should_create_the_component', () => {
    expect(component).toBeTruthy();
  });

  it('should_display_accounts_when_provided', () => {
    fixture.componentRef.setInput('accounts', mockAccounts);
    fixture.detectChanges();

    const items = fixture.nativeElement.querySelectorAll('.account-picker__item');
    expect(items.length).toBe(2);
  });

  it('should_display_aucun_option_when_not_required', () => {
    fixture.componentRef.setInput('accounts', mockAccounts);
    fixture.componentRef.setInput('required', false);
    fixture.detectChanges();

    const items = fixture.nativeElement.querySelectorAll('.account-picker__item');
    expect(items.length).toBe(3); // "Aucun" + 2 accounts
  });

  it('should_not_display_aucun_option_when_required', () => {
    fixture.componentRef.setInput('accounts', mockAccounts);
    fixture.componentRef.setInput('required', true);
    fixture.detectChanges();

    const names = fixture.nativeElement.querySelectorAll('.account-picker__name');
    const texts = Array.from(names).map((el: unknown) => (el as HTMLElement).textContent?.trim());
    expect(texts).not.toContain('Aucun');
  });

  it('should_emit_accountSelected_when_account_clicked', () => {
    fixture.componentRef.setInput('accounts', mockAccounts);
    fixture.detectChanges();

    let emittedId: string | null = null;
    component.accountSelected.subscribe((id) => {
      emittedId = id;
    });

    const items = fixture.nativeElement.querySelectorAll('.account-picker__item');
    items[0].click();

    expect(emittedId).toBe('acc-1');
  });

  it('should_emit_null_when_aucun_clicked', () => {
    fixture.componentRef.setInput('accounts', mockAccounts);
    fixture.componentRef.setInput('required', false);
    fixture.detectChanges();

    let emittedId: string | null = 'initial';
    component.accountSelected.subscribe((id) => {
      emittedId = id;
    });

    const items = fixture.nativeElement.querySelectorAll('.account-picker__item');
    items[0].click(); // "Aucun" is first

    expect(emittedId).toBeNull();
  });

  it('should_mark_selected_account_as_active', () => {
    fixture.componentRef.setInput('accounts', mockAccounts);
    fixture.componentRef.setInput('selectedAccountId', 'acc-1');
    fixture.detectChanges();

    const activeItems = fixture.nativeElement.querySelectorAll('.account-picker__item.active');
    expect(activeItems.length).toBe(1);
  });

  it('should_show_empty_message_when_no_accounts', () => {
    fixture.componentRef.setInput('accounts', []);
    fixture.detectChanges();

    const emptyMsg = fixture.nativeElement.querySelector('.account-picker__empty');
    expect(emptyMsg).toBeTruthy();
  });
});
