import { TestBed } from '@angular/core/testing';
import { signal } from '@angular/core';
import { provideRouter, Router } from '@angular/router';
import { of, throwError } from 'rxjs';

import { Categories } from './categories';
import { CategoryService } from '../../../../core/services/category';
import { ModalService } from '../../../../core/services/modal.service';
import { DevLogger } from '../../../../core/services/dev-logger';
import { Category } from '../../../../core/models/category.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

const makeCategory = (overrides: Partial<Category> = {}): Category => ({
  id: 'cat-1',
  nom: 'Courses',
  icone: '🛒',
  couleur: '#123456',
  isSystem: false,
  ...overrides,
});

function createCategoryServiceMock() {
  return {
    getAll: vi.fn().mockReturnValue(of<Category[]>([])),
    delete: vi.fn().mockReturnValue(of(undefined)),
    refreshTrigger: signal(0),
  };
}

function createModalServiceMock() {
  return { openModal: vi.fn() };
}

function createDevLoggerMock() {
  return { log: vi.fn(), warn: vi.fn(), error: vi.fn() };
}

describe('Categories', () => {
  let categoryServiceMock: ReturnType<typeof createCategoryServiceMock>;
  let modalServiceMock: ReturnType<typeof createModalServiceMock>;
  let devLoggerMock: ReturnType<typeof createDevLoggerMock>;

  beforeEach(() => {
    categoryServiceMock = createCategoryServiceMock();
    modalServiceMock = createModalServiceMock();
    devLoggerMock = createDevLoggerMock();
  });

  const setupTestBed = () => {
    TestBed.configureTestingModule({
      imports: [Categories],
      providers: [
        ...provideTranslocoTesting(),
        provideRouter([]),
        { provide: CategoryService, useValue: categoryServiceMock },
        { provide: ModalService, useValue: modalServiceMock },
        { provide: DevLogger, useValue: devLoggerMock },
      ],
    });
    vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
  };

  const flushAsyncLoad = async (fixture: { detectChanges: () => void }) => {
    await Promise.resolve();
    await Promise.resolve();
    fixture.detectChanges();
  };

  const createFixture = async (categories: Category[] = []) => {
    categoryServiceMock.getAll.mockReturnValue(of(categories));
    setupTestBed();
    const fixture = TestBed.createComponent(Categories);
    fixture.detectChanges();
    await flushAsyncLoad(fixture);
    return fixture;
  };

  it('should_create_the_component', async () => {
    const fixture = await createFixture();

    expect(fixture.componentInstance).toBeTruthy();
  });

  // ---------------------------------------------------------------------
  // Chargement — succes / erreur
  // ---------------------------------------------------------------------

  it('should_load_categories_on_init', async () => {
    const category = makeCategory();
    const fixture = await createFixture([category]);

    expect(fixture.componentInstance.categories()).toEqual([category]);
    expect(fixture.componentInstance.loading()).toBe(false);
    expect(fixture.componentInstance.error()).toBe(false);
  });

  it('should_set_error_state_when_load_fails', async () => {
    categoryServiceMock.getAll.mockReturnValue(throwError(() => new Error('network down')));
    setupTestBed();
    const fixture = TestBed.createComponent(Categories);
    fixture.detectChanges();
    await flushAsyncLoad(fixture);

    expect(fixture.componentInstance.error()).toBe(true);
    expect(fixture.componentInstance.loading()).toBe(false);
    expect(devLoggerMock.error).toHaveBeenCalled();
  });

  it('should_reload_on_refreshTrigger_change', async () => {
    const fixture = await createFixture([]);
    categoryServiceMock.getAll.mockClear();
    categoryServiceMock.getAll.mockReturnValue(of([]));

    categoryServiceMock.refreshTrigger.update((v: number) => v + 1);
    await flushAsyncLoad(fixture);

    expect(categoryServiceMock.getAll).toHaveBeenCalled();
  });

  it('should_filter_out_system_categories', async () => {
    const userCategory = makeCategory({ id: 'user-1', isSystem: false });
    const systemCategory = makeCategory({ id: 'system-1', isSystem: true });
    const fixture = await createFixture([userCategory, systemCategory]);

    expect(fixture.componentInstance.userCategories()).toEqual([userCategory]);
  });

  // ---------------------------------------------------------------------
  // Rendu — textes traduits
  // ---------------------------------------------------------------------

  it('should_render_french_page_title', async () => {
    const fixture = await createFixture([]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.page-header__title')?.textContent?.trim()).toBe('Catégories');
  });

  it('should_render_french_error_state_labels_when_load_fails', async () => {
    categoryServiceMock.getAll.mockReturnValue(throwError(() => new Error('network down')));
    setupTestBed();
    const fixture = TestBed.createComponent(Categories);
    fixture.detectChanges();
    await flushAsyncLoad(fixture);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.empty-state__message')?.textContent).toBe('Erreur de chargement');
    expect(el.querySelector('.empty-state__cta')?.textContent).toBe('Réessayer');
  });

  it('should_render_french_empty_state_when_no_categories', async () => {
    const fixture = await createFixture([]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.empty-state__message')?.textContent).toBe('Aucune catégorie');
    expect(el.querySelector('.empty-state__cta')?.textContent).toBe('Créer une catégorie');
  });

  it('should_call_create_category_when_empty_state_cta_is_clicked', async () => {
    const fixture = await createFixture([]);
    const cta = (fixture.nativeElement as HTMLElement).querySelector<HTMLButtonElement>(
      '.empty-state__cta',
    );
    cta?.click();

    expect(modalServiceMock.openModal).toHaveBeenCalledWith('category');
  });

  it('should_render_french_section_count_with_plural', async () => {
    const fixture = await createFixture([makeCategory({ id: 'c1' })]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.cat-section__label')?.textContent?.trim()).toBe('1 catégorie');
  });

  it('should_render_french_section_count_plural_for_multiple_categories', async () => {
    const fixture = await createFixture([
      makeCategory({ id: 'c1' }),
      makeCategory({ id: 'c2' }),
    ]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.cat-section__label')?.textContent?.trim()).toBe('2 catégories');
  });

  // ---------------------------------------------------------------------
  // Actions — creation, edition, suppression
  // ---------------------------------------------------------------------

  it('should_open_modal_to_create_category', async () => {
    const fixture = await createFixture([]);

    fixture.componentInstance.createCategory();

    expect(modalServiceMock.openModal).toHaveBeenCalledWith('category');
  });

  it('should_open_modal_to_edit_category', async () => {
    const category = makeCategory();
    const fixture = await createFixture([category]);

    fixture.componentInstance.editCategory(category);

    expect(modalServiceMock.openModal).toHaveBeenCalledWith('category', category);
  });

  it('should_show_inline_delete_confirmation_in_french', async () => {
    const category = makeCategory();
    const fixture = await createFixture([category]);

    fixture.componentInstance.requestDelete(category.id);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.cat-row__confirm p')?.textContent).toBe(
      'Cette catégorie sera dissociée de tous les items liés.',
    );
    expect(el.querySelector('.btn-cancel')?.textContent).toBe('Annuler');
    expect(el.querySelector('.btn-delete')?.textContent).toBe('Supprimer');
  });

  it('should_cancel_delete_confirmation', async () => {
    const category = makeCategory();
    const fixture = await createFixture([category]);

    fixture.componentInstance.requestDelete(category.id);
    fixture.componentInstance.cancelDelete();

    expect(fixture.componentInstance.confirmDeleteId()).toBeNull();
  });

  it('should_delete_category_when_confirmed', async () => {
    const category = makeCategory();
    const fixture = await createFixture([category]);

    fixture.componentInstance.requestDelete(category.id);
    await fixture.componentInstance.confirmDelete();

    expect(categoryServiceMock.delete).toHaveBeenCalledWith(category.id);
    expect(fixture.componentInstance.confirmDeleteId()).toBeNull();
  });

  it('should_do_nothing_when_confirming_delete_without_a_pending_id', async () => {
    const fixture = await createFixture([]);

    await fixture.componentInstance.confirmDelete();

    expect(categoryServiceMock.delete).not.toHaveBeenCalled();
  });

  it('should_log_error_when_delete_fails', async () => {
    categoryServiceMock.delete.mockReturnValue(throwError(() => new Error('boom')));
    const category = makeCategory();
    const fixture = await createFixture([category]);

    fixture.componentInstance.requestDelete(category.id);
    await fixture.componentInstance.confirmDelete();

    expect(devLoggerMock.error).toHaveBeenCalled();
  });
});
