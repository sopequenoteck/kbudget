import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { signal } from '@angular/core';

import { BankSelect } from './bank-select';
import { BankService } from '../../../core/services/bank';
import { BankResponse } from '../../../core/models/bank.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const MOCK_BANKS: BankResponse[] = [
  { code: 'SG', name: 'Société Générale', country: 'FR', brandColor: '#e2001a', logoUrl: '/api/bank-logos/sg.svg' },
  { code: 'ECOBANK', name: 'Ecobank', country: 'TG', brandColor: '#003b7c', logoUrl: '/api/bank-logos/ecobank.svg' },
  { code: 'WISE', name: 'Wise', country: null, brandColor: '#9fe870', logoUrl: '/api/bank-logos/wise.svg' },
  { code: 'OTHER', name: 'Autre', country: null, brandColor: null, logoUrl: null },
];

const mockBanks = signal(MOCK_BANKS);
const mockBankService = {
  banks: mockBanks,
  error: signal(null),
  loadBanks: vi.fn(),
  getBankByCode: vi.fn((code: string) => MOCK_BANKS.find((b) => b.code === code)),
  getBankLogoUrl: vi.fn((code: string) => MOCK_BANKS.find((b) => b.code === code)?.logoUrl ?? null),
};

describe('BankSelect', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [BankSelect],
      providers: [{ provide: BankService, useValue: mockBankService }],
    });
  });

  it('should create the component', () => {
    const fixture = TestBed.createComponent(BankSelect);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_group_banks_by_region', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const groups = component.groupedBanks();

    expect(groups).toHaveLength(3);
    expect(groups[0].label).toBe('France');
    expect(groups[0].banks).toHaveLength(1);
    expect(groups[0].banks[0].code).toBe('SG');

    expect(groups[1].label).toBe("Afrique de l'Ouest");
    expect(groups[1].banks).toHaveLength(1);
    expect(groups[1].banks[0].code).toBe('ECOBANK');

    expect(groups[2].label).toBe('International');
    expect(groups[2].banks).toHaveLength(1);
    expect(groups[2].banks[0].code).toBe('WISE');
  });

  it('should_show_other_last', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const groups = component.groupedBanks();

    const allGroupedCodes = groups.flatMap((g) => g.banks.map((b) => b.code));
    expect(allGroupedCodes).not.toContain('OTHER');

    const lastGroup = groups[groups.length - 1];
    expect(lastGroup.label).not.toBe('Autre');
  });

  it('should_filter_by_search_query', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.searchQuery.set('société');

    const filtered = component.filteredGroups();

    expect(filtered).toHaveLength(1);
    expect(filtered[0].label).toBe('France');
    expect(filtered[0].banks).toHaveLength(1);
    expect(filtered[0].banks[0].code).toBe('SG');
  });

  it('should_keep_other_visible_during_filter', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.searchQuery.set('xyz_no_match');

    const filtered = component.filteredGroups();

    const allGroupedCodes = filtered.flatMap((g) => g.banks.map((b) => b.code));
    expect(allGroupedCodes).not.toContain('OTHER');

    expect(filtered).toHaveLength(0);
  });

  it('should_emit_selected_bank_code', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let emittedValue = '';
    component.registerOnChange((value: string) => {
      emittedValue = value;
    });

    component.openDropdown();
    component.selectBank('SG');

    expect(emittedValue).toBe('SG');
    expect(component.selectedCode()).toBe('SG');
    expect(component.isOpen()).toBe(false);
  });

  it('should call loadBanks on construction', () => {
    TestBed.createComponent(BankSelect);
    expect(mockBankService.loadBanks).toHaveBeenCalled();
  });

  it('should default selectedCode to OTHER', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    expect(fixture.componentInstance.selectedCode()).toBe('OTHER');
  });

  it('should write value via CVA', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.writeValue('ECOBANK');

    expect(component.selectedCode()).toBe('ECOBANK');
  });

  it('should write OTHER when value is empty string', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.writeValue('SG');
    component.writeValue('');

    expect(component.selectedCode()).toBe('OTHER');
  });

  it('should not open when disabled', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.setDisabledState(true);
    component.toggleDropdown();

    expect(component.isOpen()).toBe(false);
  });

  it('should close dropdown and call onTouched', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const touchedSpy = vi.fn();
    component.registerOnTouched(touchedSpy);

    component.openDropdown();
    expect(component.isOpen()).toBe(true);

    component.closeDropdown();
    expect(component.isOpen()).toBe(false);
    expect(touchedSpy).toHaveBeenCalled();
  });

  it('should reset searchQuery when closing dropdown', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.openDropdown();
    component.searchQuery.set('eco');
    component.closeDropdown();

    expect(component.searchQuery()).toBe('');
  });

  it('should set isKnownBank to false when OTHER is selected', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    expect(fixture.componentInstance.isKnownBank()).toBe(false);
  });

  it('should set isKnownBank to true when a real bank is selected', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.writeValue('SG');

    expect(component.isKnownBank()).toBe(true);
  });

  it('should return null for selectedBank when OTHER is selected', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    expect(fixture.componentInstance.selectedBank()).toBeNull();
  });

  it('should return the bank for selectedBank when a known code is selected', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.writeValue('WISE');

    const bank = component.selectedBank();
    expect(bank).not.toBeNull();
    expect(bank?.code).toBe('WISE');
    expect(bank?.name).toBe('Wise');
  });

  it('should return empty filteredGroups when no banks match search', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.searchQuery.set('zzznomatch');

    expect(component.filteredGroups()).toHaveLength(0);
  });

  it('should return all groups when searchQuery is empty', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.searchQuery.set('');

    expect(component.filteredGroups()).toEqual(component.groupedBanks());
  });

  it('should emit OTHER when selectBank is called with OTHER', () => {
    const fixture = TestBed.createComponent(BankSelect);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let emittedValue = 'SG';
    component.registerOnChange((value: string) => {
      emittedValue = value;
    });

    component.writeValue('SG');
    component.openDropdown();
    component.selectBank('OTHER');

    expect(emittedValue).toBe('OTHER');
    expect(component.selectedCode()).toBe('OTHER');
  });
});
