import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';

import { SelectPicker } from './select-picker';
import { SelectPickerItem } from './select-picker.model';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

const mockItems: SelectPickerItem[] = [
  { id: 'acc-1', label: 'Compte courant', icon: '🏦', secondaryText: '150.00 €', color: '#3b82f6' },
  { id: 'acc-2', label: 'Livret A', icon: '💰', secondaryText: '2000.00 €', color: '#10b981' },
  { id: 'acc-3', label: 'Especes', icon: '💵', secondaryText: '50.00 €', color: null },
];

describe('SelectPicker', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [SelectPicker],
    });
  });

  it('should create the component', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should write value via CVA', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.writeValue('acc-2');

    expect(component.selectedId()).toBe('acc-2');
    expect(component.selectedItem()?.label).toBe('Livret A');
  });

  it('should emit onChange when selecting an item', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let emittedValue = '';
    component.registerOnChange((value: string) => {
      emittedValue = value;
    });

    component.selectItem(mockItems[0]);

    expect(emittedValue).toBe('acc-1');
    expect(component.selectedId()).toBe('acc-1');
  });

  it('should call onTouched when closing', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    const touchedSpy = vi.fn();
    component.registerOnTouched(touchedSpy);

    component.open();
    component.close();

    expect(touchedSpy).toHaveBeenCalled();
  });

  it('should set disabled state via CVA', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.setDisabledState(true);

    expect(component.disabled()).toBe(true);
  });

  it('should not open when disabled', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.setDisabledState(true);
    component.toggle();

    expect(component.isOpen()).toBe(false);
  });

  it('should toggle open and close', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.toggle();
    expect(component.isOpen()).toBe(true);

    component.toggle();
    expect(component.isOpen()).toBe(false);
  });

  it('should clear selection and emit empty string', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let emittedValue = 'initial';
    component.registerOnChange((value: string) => {
      emittedValue = value;
    });

    component.selectItem(mockItems[1]);
    expect(component.selectedId()).toBe('acc-2');

    const event = new MouseEvent('click');
    component.clearSelection(event);

    expect(emittedValue).toBe('');
    expect(component.selectedId()).toBe('');
  });

  it('should filter items by search term', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.searchTerm.set('livret');

    expect(component.filteredItems()).toHaveLength(1);
    expect(component.filteredItems()[0].id).toBe('acc-2');
  });

  it('should show search when items >= threshold', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.componentRef.setInput('searchThreshold', 3);
    fixture.detectChanges();

    expect(fixture.componentInstance.showSearch()).toBe(true);
  });

  it('should hide search when items < threshold', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.componentRef.setInput('searchThreshold', 10);
    fixture.detectChanges();

    expect(fixture.componentInstance.showSearch()).toBe(false);
  });

  it('should override search with searchable input', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.componentRef.setInput('searchable', true);
    fixture.componentRef.setInput('searchThreshold', 100);
    fixture.detectChanges();

    expect(fixture.componentInstance.showSearch()).toBe(true);
  });

  it('should navigate down with ArrowDown', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.open();

    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    expect(component.highlightedIndex()).toBe(0);

    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    expect(component.highlightedIndex()).toBe(1);

    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    expect(component.highlightedIndex()).toBe(2);

    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    expect(component.highlightedIndex()).toBe(0);
  });

  it('should navigate up with ArrowUp', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.open();

    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowUp' }));
    expect(component.highlightedIndex()).toBe(2);

    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowUp' }));
    expect(component.highlightedIndex()).toBe(1);
  });

  it('should select highlighted item with Enter', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let emittedValue = '';
    component.registerOnChange((v: string) => {
      emittedValue = v;
    });

    component.open();
    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    component.onKeydown(new KeyboardEvent('keydown', { key: 'Enter' }));

    expect(emittedValue).toBe('acc-2');
    expect(component.isOpen()).toBe(false);
  });

  it('should close on Escape', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    component.open();
    expect(component.isOpen()).toBe(true);

    component.onKeydown(new KeyboardEvent('keydown', { key: 'Escape' }));
    expect(component.isOpen()).toBe(false);
  });

  it('should show empty message when no items', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', []);
    fixture.detectChanges();

    expect(fixture.componentInstance.filteredItems()).toHaveLength(0);
  });

  it('should clear selection when selected item removed from items', () => {
    const fixture = TestBed.createComponent(SelectPicker);
    fixture.componentRef.setInput('items', mockItems);
    fixture.detectChanges();

    const component = fixture.componentInstance;
    let emittedValue = 'initial';
    component.registerOnChange((v: string) => {
      emittedValue = v;
    });

    component.writeValue('acc-2');
    expect(component.selectedId()).toBe('acc-2');

    fixture.componentRef.setInput('items', [mockItems[0], mockItems[2]]);
    fixture.detectChanges();

    expect(component.selectedId()).toBe('');
    expect(emittedValue).toBe('');
  });
});
