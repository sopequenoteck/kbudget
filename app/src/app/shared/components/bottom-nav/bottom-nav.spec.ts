import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';

import { BottomNav } from './bottom-nav';

const items = [
  { label: 'Accueil', route: '/dashboard', icon: 'phosphorHouse', filledIcon: 'phosphorHouseFill' },
  { label: 'Transactions', route: '/transactions', icon: 'phosphorCurrencyDollar', filledIcon: 'phosphorCurrencyDollarFill' },
  { label: 'Abonnements', route: '/subscriptions', icon: 'phosphorArrowsClockwise', filledIcon: 'phosphorArrowsClockwiseFill' },
];

describe('BottomNav', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [BottomNav],
      providers: [provideRouter([])],
    });
  });

  it('should_render_all_items_with_icon_and_label', () => {
    const fixture = TestBed.createComponent(BottomNav);
    fixture.componentRef.setInput('items', items);
    fixture.componentRef.setInput('activeRoute', '/dashboard');
    fixture.detectChanges();

    const navItems = fixture.nativeElement.querySelectorAll('.bottom-nav-item');
    expect(navItems.length).toBe(3);

    expect(navItems[0].querySelector('.bottom-nav-icon ng-icon')).toBeTruthy();
    expect(navItems[0].querySelector('.bottom-nav-label').textContent).toBe('Accueil');

    expect(navItems[1].querySelector('.bottom-nav-icon ng-icon')).toBeTruthy();
    expect(navItems[1].querySelector('.bottom-nav-label').textContent).toBe('Transactions');

    expect(navItems[2].querySelector('.bottom-nav-icon ng-icon')).toBeTruthy();
    expect(navItems[2].querySelector('.bottom-nav-label').textContent).toBe('Abonnements');
  });

  it('should_apply_active_class_when_activeRoute_starts_with_item_route', () => {
    const fixture = TestBed.createComponent(BottomNav);
    fixture.componentRef.setInput('items', items);
    fixture.componentRef.setInput('activeRoute', '/transactions');
    fixture.detectChanges();

    const navItems = fixture.nativeElement.querySelectorAll('.bottom-nav-item');
    const transactionsItem = navItems[1];
    expect(transactionsItem.classList.contains('active')).toBe(true);
  });

  it('should_not_apply_active_to_non_matching_items', () => {
    const fixture = TestBed.createComponent(BottomNav);
    fixture.componentRef.setInput('items', items);
    fixture.componentRef.setInput('activeRoute', '/transactions');
    fixture.detectChanges();

    const navItems = fixture.nativeElement.querySelectorAll('.bottom-nav-item');
    const dashboardItem = navItems[0];
    expect(dashboardItem.classList.contains('active')).toBe(false);
  });

  it('should_render_0_items_when_empty_array', () => {
    const fixture = TestBed.createComponent(BottomNav);
    fixture.componentRef.setInput('items', []);
    fixture.componentRef.setInput('activeRoute', '/dashboard');
    fixture.detectChanges();

    const navItems = fixture.nativeElement.querySelectorAll('.bottom-nav-item');
    expect(navItems.length).toBe(0);
  });

  it('should_not_apply_active_when_activeRoute_is_settings', () => {
    const fixture = TestBed.createComponent(BottomNav);
    fixture.componentRef.setInput('items', items);
    fixture.componentRef.setInput('activeRoute', '/settings');
    fixture.detectChanges();

    const navItems = fixture.nativeElement.querySelectorAll('.bottom-nav-item');
    const activeItems = Array.from(navItems).filter((el) =>
      (el as Element).classList.contains('active'),
    );
    expect(activeItems.length).toBe(0);
  });
});
