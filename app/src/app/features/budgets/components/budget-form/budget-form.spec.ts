import { signal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { HttpErrorResponse } from '@angular/common/http';
import { of, throwError } from 'rxjs';

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

function category(id: string, systemKey: string | null = null): Category {
  return { id, nom: id, icone: '🏷', couleur: '#000000', isSystem: !!systemKey, systemKey } as Category;
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
  let budgetServiceMock: {
    getAll: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
    create: ReturnType<typeof vi.fn>;
    update: ReturnType<typeof vi.fn>;
  };
  let confirmServiceMock: { confirmDelete: ReturnType<typeof vi.fn> };
  let modalServiceMock: { editingEntity: typeof editingEntity; closeModal: ReturnType<typeof vi.fn> };
  let apiErrorServiceMock: { label: ReturnType<typeof vi.fn> };

  const setup = (): BudgetForm => {
    budgetServiceMock = {
      getAll: vi.fn().mockReturnValue(of([])),
      delete: vi.fn().mockReturnValue(of(undefined)),
      create: vi.fn().mockReturnValue(of({} as Budget)),
      update: vi.fn().mockReturnValue(of({} as Budget)),
    };
    confirmServiceMock = { confirmDelete: vi.fn().mockResolvedValue(true) };
    modalServiceMock = { editingEntity, closeModal: vi.fn() };
    apiErrorServiceMock = { label: vi.fn().mockReturnValue('Erreur API') };

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
        { provide: ApiErrorService, useValue: apiErrorServiceMock },
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

    expect(confirmServiceMock.confirmDelete).toHaveBeenCalled();
    expect(budgetServiceMock.delete).toHaveBeenCalledWith('b1');
    expect(modalServiceMock.closeModal).toHaveBeenCalled();
  });

  it('should_not_delete_budget_when_not_confirmed', async () => {
    editingEntity.set(budgetOn('b1', 'courses'));
    const form = setup();
    confirmServiceMock.confirmDelete.mockResolvedValue(false);

    await form.onDelete();

    expect(budgetServiceMock.delete).not.toHaveBeenCalled();
  });

  it('should_resolve_the_translation_key_of_the_default_monthly_frequency', () => {
    const form = setup();

    expect(form.frequencyLabelKey()).toBe('budgets.value.monthly');
  });

  it('should_resolve_the_translation_key_of_the_weekly_frequency', () => {
    // `frequencyLabelKey` lit `form.get(...).value`, pas un signal : la
    // valeur doit etre posee avant la premiere lecture, sinon le calcul
    // memorise (sans dependance suivie) ne serait plus jamais reevalue.
    const form = setup();
    form.form.patchValue({ frequence: 'HEBDOMADAIRE' });

    expect(form.frequencyLabelKey()).toBe('budgets.value.weekly');
  });

  it('should_resolve_the_translation_key_of_the_yearly_frequency', () => {
    const form = setup();
    form.form.patchValue({ frequence: 'ANNUEL' });

    expect(form.frequencyLabelKey()).toBe('budgets.value.yearly');
  });

  it('should_show_the_translated_name_when_the_selected_category_is_a_system_category', () => {
    // Assert — `nom` volontairement different de la traduction pour prouver
    // que l'affichage ne depend plus du `nom` brut cote serveur (KKS-395).
    const form = setup();
    form.categories.update((cats) => [...cats, category('sys-1', 'SUBSCRIPTION')]);
    form.form.patchValue({ categoryId: 'sys-1' });

    expect(form.selectedCategoryName()).toBe('🏷 Abonnement');
  });

  it('should_create_budget_and_close_modal_on_submit', async () => {
    const form = setup();
    form.form.patchValue({ categoryId: 'transport', montant: '25' });

    await form.onSubmit();

    expect(budgetServiceMock.create).toHaveBeenCalled();
    expect(modalServiceMock.closeModal).toHaveBeenCalled();
  });

  it('should_update_budget_when_editing_entity_exists', async () => {
    editingEntity.set(budgetOn('b1', 'courses'));
    const form = setup();
    // L'effet du constructeur qui recopie l'entite editee dans le formulaire
    // n'est pas garanti flush hors d'un fixture Angular : on pose nous-memes
    // des valeurs valides plutot que d'attendre son execution.
    form.form.patchValue({ categoryId: 'courses', montant: '100' });

    await form.onSubmit();

    expect(budgetServiceMock.update).toHaveBeenCalledWith('b1', expect.any(Object));
  });

  it('should_show_invalid_amount_message_when_disabled_amount_escapes_validation', async () => {
    const form = setup();
    form.form.patchValue({ categoryId: 'transport' });
    // Un montant desactive echappe a decimalMin (exclu de form.invalid) mais
    // reste present dans getRawValue(), ce qui declenche la verification manuelle.
    form.form.get('montant')!.disable();
    form.form.get('montant')!.setValue('abc');

    await form.onSubmit();

    expect(form.errorMessage()).toBe('Montant invalide');
    expect(budgetServiceMock.create).not.toHaveBeenCalled();
  });

  it('should_use_api_error_label_when_submit_fails_with_http_error_response', async () => {
    const form = setup();
    budgetServiceMock.create.mockReturnValue(throwError(() => new HttpErrorResponse({ status: 400 })));
    form.form.patchValue({ categoryId: 'transport', montant: '25' });

    await form.onSubmit();

    expect(apiErrorServiceMock.label).toHaveBeenCalledWith(expect.any(HttpErrorResponse), 'Erreur serveur');
    expect(form.errorMessage()).toBe('Erreur API');
  });

  it('should_show_native_error_message_when_submit_throws_an_error', async () => {
    const form = setup();
    budgetServiceMock.create.mockReturnValue(throwError(() => new Error('Panne reseau')));
    form.form.patchValue({ categoryId: 'transport', montant: '25' });

    await form.onSubmit();

    expect(form.errorMessage()).toBe('Panne reseau');
  });

  it('should_fallback_to_translated_save_error_when_thrown_value_is_not_an_error', async () => {
    const form = setup();
    budgetServiceMock.create.mockReturnValue(throwError(() => 'boom'));
    form.form.patchValue({ categoryId: 'transport', montant: '25' });

    await form.onSubmit();

    expect(form.errorMessage()).toBe('Erreur lors de la sauvegarde');
  });

  it('should_fallback_to_translated_delete_error_when_thrown_value_is_not_an_error', async () => {
    editingEntity.set(budgetOn('b1', 'courses'));
    const form = setup();
    budgetServiceMock.delete.mockReturnValue(throwError(() => 'boom'));

    await form.onDelete();

    expect(form.errorMessage()).toBe('Erreur lors de la suppression');
  });
});
