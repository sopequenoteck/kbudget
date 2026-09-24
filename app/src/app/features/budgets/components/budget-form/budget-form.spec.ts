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
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

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
  let budgetServiceMock: { getAll: ReturnType<typeof vi.fn>; delete: ReturnType<typeof vi.fn> };
  let confirmServiceMock: { confirm: ReturnType<typeof vi.fn> };
  let modalServiceMock: { editingEntity: typeof editingEntity; closeModal: ReturnType<typeof vi.fn> };

  const setup = (): BudgetForm => {
    budgetServiceMock = {
      getAll: vi.fn().mockReturnValue(of([])),
      delete: vi.fn().mockReturnValue(of(undefined)),
    };
    confirmServiceMock = { confirm: vi.fn().mockResolvedValue(true) };
    modalServiceMock = { editingEntity, closeModal: vi.fn() };

    TestBed.configureTestingModule({
      providers: [
        provideTranslocoTesting(),
        { provide: CategoryService, useValue: { getAll: vi.fn().mockReturnValue(of([])) } },
        { provide: BudgetService, useValue: budgetServiceMock },
        {
          provide: PreferenceService,
          useValue: { currencies: signal(['EUR']), language: signal(null) },
        },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: ConfirmService, useValue: confirmServiceMock },
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

  it('should_delete_budget_when_confirmed', async () => {
    editingEntity.set(budgetOn('b1', 'courses'));
    const form = setup();

    await form.onDelete();

    expect(confirmServiceMock.confirm).toHaveBeenCalled();
    expect(budgetServiceMock.delete).toHaveBeenCalledWith('b1');
    expect(modalServiceMock.closeModal).toHaveBeenCalled();
  });

  it('should_not_delete_budget_when_not_confirmed', async () => {
    editingEntity.set(budgetOn('b1', 'courses'));
    const form = setup();
    confirmServiceMock.confirm.mockResolvedValue(false);

    await form.onDelete();

    expect(budgetServiceMock.delete).not.toHaveBeenCalled();
  });
});
