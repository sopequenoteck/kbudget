import { TestBed } from '@angular/core/testing';

import { BudgetSummary } from './budget-summary';
import { type BudgetOverview } from '../../../../core/models/budget.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

function makeOverview(overrides: Partial<BudgetOverview> = {}): BudgetOverview {
  return {
    month: '2026-03',
    totalBudget: 300,
    totalSpent: 150,
    percentage: 50,
    currency: 'EUR',
    items: [],
    unbudgetedItems: [],
    unbudgetedTotal: 0,
    ...overrides,
  };
}

function render(overview: BudgetOverview | null) {
  TestBed.configureTestingModule({
    imports: [BudgetSummary],
    providers: [provideTranslocoTesting()],
  });

  const fixture = TestBed.createComponent(BudgetSummary);
  fixture.componentRef.setInput('items', []);
  fixture.componentRef.setInput('overview', overview);
  fixture.detectChanges();
  return fixture;
}

describe('BudgetSummary', () => {
  it('should_render_monthly_subtitle_in_french_with_the_overview_currency', () => {
    const fixture = render(makeOverview({ currency: 'EUR' }));
    const subtitle = fixture.nativeElement.querySelector('.budget-summary__subtitle span');

    expect(subtitle?.textContent?.trim()).toBe('Mensuel · en EUR');
  });

  it('should_interpolate_a_different_currency_in_the_subtitle', () => {
    const fixture = render(makeOverview({ currency: 'USD' }));
    const subtitle = fixture.nativeElement.querySelector('.budget-summary__subtitle span');

    expect(subtitle?.textContent?.trim()).toBe('Mensuel · en USD');
  });

  it('should_not_render_the_subtitle_when_overview_is_absent', () => {
    const fixture = render(null);
    const subtitle = fixture.nativeElement.querySelector('.budget-summary__subtitle');

    expect(subtitle).toBeNull();
  });
});
