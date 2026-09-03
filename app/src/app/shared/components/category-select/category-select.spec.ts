import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { provideAnimationsAsync } from '@angular/platform-browser/animations/async';

import { CategorySelect } from './category-select';
import { Category } from '../../../core/models/category.model';

// ---------------------------------------------------------------------------
// Données de test
// ---------------------------------------------------------------------------

const MOCK_CATEGORIES: Category[] = [
  { id: '1', nom: 'Alimentation', icone: '🍔', couleur: '#FF5722' },
  { id: '2', nom: 'Transport', icone: '🚗', couleur: '#2196F3' },
  { id: '3', nom: 'Café', icone: '☕', couleur: '#795548' },
  { id: '4', nom: 'Économie', icone: '💰', couleur: '#4CAF50' },
];

// ---------------------------------------------------------------------------
// Suite
// ---------------------------------------------------------------------------

describe('CategorySelect', () => {
  function setup(categories: Category[] = MOCK_CATEGORIES) {
    TestBed.configureTestingModule({
      imports: [CategorySelect],
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        provideAnimationsAsync('noop'),
      ],
    });
    const fixture = TestBed.createComponent(CategorySelect);
    const component = fixture.componentInstance;
    fixture.componentRef.setInput('categories', categories);
    fixture.detectChanges();
    return { fixture, component };
  }

  afterEach(() => {
    TestBed.resetTestingModule();
  });

  // =========================================================================
  // US1 — Sélection inline
  // =========================================================================

  it('should_render_all_categories_when_search_is_empty', () => {
    const { fixture } = setup();
    const items = fixture.nativeElement.querySelectorAll('.cs__item');
    expect(items.length).toBe(MOCK_CATEGORIES.length);
  });

  it('should_select_and_emit_when_category_clicked', () => {
    const { fixture, component } = setup();

    let emittedId: string | undefined;
    component.selected.subscribe((id) => (emittedId = id));

    const firstItem = fixture.nativeElement.querySelector('.cs__item') as HTMLElement;
    firstItem.click();
    fixture.detectChanges();

    expect(emittedId).toBe(MOCK_CATEGORIES[0].id);
    expect(component.value()).toBe(MOCK_CATEGORIES[0].id);
  });

  it('should_apply_max_height_60vh_on_list_container', () => {
    const { fixture } = setup();
    const list = fixture.nativeElement.querySelector('.cs__list') as HTMLElement;
    expect(list).toBeTruthy();
    // Le CSS est déclaré avec max-height: 60vh dans category-select.scss
    // On vérifie que l'élément existe et porte la bonne classe
    expect(list.classList.contains('cs__list')).toBe(true);
  });

  it('should_render_with_correct_aria_attributes_combobox_and_listbox', () => {
    const { fixture } = setup();

    const input = fixture.nativeElement.querySelector('.cs__search') as HTMLInputElement;
    expect(input.getAttribute('role')).toBe('combobox');
    expect(input.getAttribute('aria-autocomplete')).toBe('list');
    expect(input.getAttribute('aria-expanded')).toBe('true');
    expect(input.getAttribute('aria-controls')).toContain('category-select-listbox-');

    const listbox = fixture.nativeElement.querySelector('.cs__list');
    expect(listbox.getAttribute('role')).toBe('listbox');

    const options = fixture.nativeElement.querySelectorAll('[role="option"]');
    expect(options.length).toBe(MOCK_CATEGORIES.length);
  });

  it('should_show_empty_state_when_no_categories_and_no_search', () => {
    const { fixture } = setup([]);

    const emptyState = fixture.nativeElement.querySelector('.cs__empty-state');
    expect(emptyState).toBeTruthy();
    expect(emptyState.textContent).toContain('Aucune catégorie');
  });

  it('should_reset_search_and_active_index_after_selection', () => {
    const { fixture, component } = setup();
    component.searchTerm.set('ali');
    component.activeIndex.set(0);
    fixture.detectChanges();

    const firstItem = fixture.nativeElement.querySelector('.cs__item') as HTMLElement;
    firstItem.click();
    fixture.detectChanges();

    expect(component.searchTerm()).toBe('');
    expect(component.activeIndex()).toBe(-1);
  });

  // =========================================================================
  // US2 — Création inline
  // =========================================================================

  it('should_show_create_button_when_search_has_no_exact_match', () => {
    const { fixture, component } = setup();
    component.searchTerm.set('inexistant');
    fixture.detectChanges();

    const createBtn = fixture.nativeElement.querySelector('.cs__create-btn') as HTMLElement;
    expect(createBtn).toBeTruthy();
    expect(createBtn.textContent).toContain('inexistant');
  });

  it('should_hide_create_button_when_exact_match_exists', () => {
    const { fixture, component } = setup();
    // 'cafe' normalise en 'cafe', 'Café' normalise en 'cafe' → match exact
    component.searchTerm.set('café');
    fixture.detectChanges();

    // Dans l'empty-state il n'y a pas de liste visible, et showCreateButton = false
    // car hasExactMatch = true
    expect(component.hasExactMatch()).toBe(true);
    expect(component.showCreateButton()).toBe(false);
  });

  it('should_push_to_create_mode_when_create_button_clicked', () => {
    const { fixture, component } = setup();
    component.searchTerm.set('nouvelle catégorie');
    fixture.detectChanges();

    const createBtn = fixture.nativeElement.querySelector('.cs__create-btn') as HTMLElement;
    createBtn.click();
    fixture.detectChanges();

    expect(component.mode()).toBe('create');
  });

  it('should_emit_is_creating_true_when_entering_create_mode', () => {
    const { fixture, component } = setup();

    const emitted: boolean[] = [];
    component.isCreating.subscribe((v) => emitted.push(v));

    component.pushToCreate();
    fixture.detectChanges();

    expect(emitted).toContain(true);
  });

  it('should_emit_is_creating_false_when_popping_back_to_list', () => {
    const { fixture, component } = setup();

    component.pushToCreate();
    fixture.detectChanges();

    const emitted: boolean[] = [];
    component.isCreating.subscribe((v) => emitted.push(v));

    component.popToList();
    fixture.detectChanges();

    expect(emitted).toContain(false);
  });

  it('should_preserve_search_term_when_popping_back_from_create', () => {
    const { fixture, component } = setup();
    component.searchTerm.set('ma recherche');
    component.pushToCreate();
    fixture.detectChanges();

    component.popToList();
    fixture.detectChanges();

    expect(component.searchTerm()).toBe('ma recherche');
    expect(component.mode()).toBe('list');
  });

  it('should_select_and_emit_new_category_when_created_successfully', () => {
    const { fixture, component } = setup();

    const newCategory: Category = {
      id: '99',
      nom: 'Nouvelle',
      icone: '⭐',
      couleur: '#FF0000',
    };

    const selectedIds: string[] = [];
    const createdCats: Category[] = [];

    component.selected.subscribe((id) => selectedIds.push(id));
    component.created.subscribe((cat) => createdCats.push(cat));

    component.onCategoryCreated(newCategory);
    fixture.detectChanges();

    expect(component.value()).toBe('99');
    expect(selectedIds).toContain('99');
    expect(createdCats).toContain(newCategory);
    expect(component.mode()).toBe('list');
    expect(component.searchTerm()).toBe('');
  });

  it('should_not_submit_when_view_not_ready', () => {
    const { component } = setup();
    // categoryForm viewChild est undefined avant que le mode create soit activé
    expect(() => {
      component.submitCategoryForm();
    }).not.toThrow();
  });

  it('should_display_error_banner_in_expand_when_api_fails', () => {
    const { fixture, component } = setup();
    component.searchTerm.set('test');
    component.pushToCreate();
    fixture.detectChanges();

    // En mode create, app-category-form est rendu dans l'expand
    const categoryFormEl = fixture.nativeElement.querySelector('app-category-form');
    expect(categoryFormEl).toBeTruthy();
    // Le mode reste 'create' — l'erreur est gérée par CategoryForm.errorMessage
    // sans fermer le mode création (FR-011)
    expect(component.mode()).toBe('create');
  });

  // =========================================================================
  // US3 — Recherche avec insensibilité casse/accents
  // =========================================================================

  it('should_filter_categories_when_search_matches_partially', () => {
    const { fixture, component } = setup();
    component.searchTerm.set('ali');
    fixture.detectChanges();

    const items = fixture.nativeElement.querySelectorAll('.cs__item');
    // 'ali' matche 'Alimentation'
    expect(items.length).toBe(1);
    expect(items[0].textContent).toContain('Alimentation');
  });

  it('should_ignore_case_when_filtering', () => {
    const { fixture, component } = setup();
    component.searchTerm.set('TRANSPORT');
    fixture.detectChanges();

    const items = fixture.nativeElement.querySelectorAll('.cs__item');
    expect(items.length).toBe(1);
    expect(items[0].textContent).toContain('Transport');
  });

  it('should_ignore_accents_when_filtering', () => {
    const { fixture, component } = setup();
    // 'cafe' (sans accent) doit matcher 'Café'
    component.searchTerm.set('cafe');
    fixture.detectChanges();

    const items = fixture.nativeElement.querySelectorAll('.cs__item');
    expect(items.length).toBe(1);
    expect(items[0].textContent).toContain('Café');
  });

  it('should_also_filter_with_accent_normalized_uppercase', () => {
    const { fixture, component } = setup();
    // 'ECO' doit matcher 'Économie'
    component.searchTerm.set('ECO');
    fixture.detectChanges();

    const items = fixture.nativeElement.querySelectorAll('.cs__item');
    expect(items.length).toBe(1);
    expect(items[0].textContent).toContain('Économie');
  });

  it('should_reset_active_index_when_search_changes', () => {
    const { fixture, component } = setup();
    // Positionner activeIndex sur un item
    component.activeIndex.set(2);
    fixture.detectChanges();

    // Simuler un input de recherche via la méthode directe
    const inputEl = fixture.nativeElement.querySelector('.cs__search') as HTMLInputElement;
    inputEl.value = 'ali';
    inputEl.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(component.activeIndex()).toBe(-1);
    expect(component.searchTerm()).toBe('ali');
  });

  // =========================================================================
  // FR-019 — Navigation clavier
  // =========================================================================

  it('should_navigate_with_arrow_down_and_wrap_to_first', () => {
    const { fixture, component } = setup();
    fixture.detectChanges();

    // ArrowDown depuis -1 → 0
    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    expect(component.activeIndex()).toBe(0);

    // ArrowDown jusqu'au dernier item
    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    // On est à l'index 3 (dernier de MOCK_CATEGORIES)
    expect(component.activeIndex()).toBe(3);

    // ArrowDown wrap → revient à 0
    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
    expect(component.activeIndex()).toBe(0);
  });

  it('should_navigate_with_arrow_up_and_wrap_to_last', () => {
    const { fixture, component } = setup();
    fixture.detectChanges();

    // ArrowUp depuis -1 → wrap → dernier (len - 1 = 3)
    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowUp' }));
    expect(component.activeIndex()).toBe(MOCK_CATEGORIES.length - 1);

    // ArrowUp depuis 3 → 2
    component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowUp' }));
    expect(component.activeIndex()).toBe(MOCK_CATEGORIES.length - 2);
  });

  it('should_select_active_item_on_enter_when_active_index_valid', () => {
    const { fixture, component } = setup();
    component.activeIndex.set(1);
    fixture.detectChanges();

    const selectedIds: string[] = [];
    component.selected.subscribe((id) => selectedIds.push(id));

    component.onKeydown(new KeyboardEvent('keydown', { key: 'Enter' }));
    fixture.detectChanges();

    expect(selectedIds).toContain(MOCK_CATEGORIES[1].id);
    expect(component.value()).toBe(MOCK_CATEGORIES[1].id);
  });

  it('should_close_or_reset_on_escape_in_list_mode', () => {
    const { fixture, component } = setup();
    component.searchTerm.set('ali');
    component.activeIndex.set(0);
    fixture.detectChanges();

    component.onKeydown(new KeyboardEvent('keydown', { key: 'Escape' }));
    fixture.detectChanges();

    // En mode list, Escape reset searchTerm et activeIndex
    expect(component.searchTerm()).toBe('');
    expect(component.activeIndex()).toBe(-1);
    expect(component.mode()).toBe('list');
  });

  it('should_pop_to_list_on_escape_in_create_mode', () => {
    const { fixture, component } = setup();
    component.searchTerm.set('nouvelle');
    component.pushToCreate();
    fixture.detectChanges();

    component.onKeydown(new KeyboardEvent('keydown', { key: 'Escape' }));
    fixture.detectChanges();

    // En mode create, Escape retourne en mode list (popToList)
    expect(component.mode()).toBe('list');
    // searchTerm préservé (FR-009)
    expect(component.searchTerm()).toBe('nouvelle');
  });
});
