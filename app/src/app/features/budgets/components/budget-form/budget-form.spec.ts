import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { BudgetForm } from './budget-form';
import { CategoryService } from '../../../../core/services/category';
import { BudgetService } from '../../../../core/services/budget';
import { PreferenceService } from '../../../../core/services/preference';
import { ModalService } from '../../../../core/services/modal.service';
import { ConfirmService } from '../../../../core/services/confirm.service';
import { ApiErrorService } from '../../../../core/services/api-error';
import { Budget } from '../../../../core/models/budget.model';
import { Category } from '../../../../core/models/category.model';

function category(id: string): Category {
  return { id, nom: id, icone: '🏷', couleur: '#000000' } as Category;
}

function budgetOn(id: string, categoryId: string): Budget {
  return {
    id,
    montant: 100,
    currency: 'EUR',
    frequence: 'MENSUEL',
    seuilNotification: 80,
    actif: true,
    category: { id: categoryId, nom: categoryId, icone: '🏷', couleur: '#000000' },
    spent: 0,
    updatedAt: '2026-03-01T00:00:00',
  };
}

describe('BudgetForm', () => {
  const editingEntity = signal<Budget | null>(null);

  const setup = (): BudgetForm => {
    TestBed.configureTestingModule({
      providers: [
        { provide: CategoryService, useValue: { getAll: vi.fn().mockReturnValue(of([])) } },
        { provide: BudgetService, useValue: { getAll: vi.fn().mockReturnValue(of([])) } },
        { provide: PreferenceService, useValue: { currencies: signal(['EUR']) } },
        { provide: ModalService, useValue: { editingEntity } },
        { provide: ConfirmService, useValue: {} },
        { provide: ApiErrorService, useValue: {} },
      ],
    });
    const form = TestBed.runInInjectionContext(() => new BudgetForm());
    form.categories.set([category('courses'), category('loisirs'), category('transport')]);
    form.existingBudgets.set([budgetOn('b1', 'courses'), budgetOn('b2', 'loisirs')]);
    return form;
  };

  afterEach(() => {
    editingEntity.set(null);
    vi.restoreAllMocks();
  });

  it('should_offer_only_categories_without_budget_when_creating', () => {
    const form = setup();

    expect(form.availableCategories().map((c) => c.id)).toEqual(['transport']);
  });

  it('should_keep_edited_budget_category_available_when_editing', () => {
    editingEntity.set(budgetOn('b1', 'courses'));
    const form = setup();

    expect(form.availableCategories().map((c) => c.id)).toEqual(['courses', 'transport']);
  });
});
