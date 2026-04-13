import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';

import { Autocomplete } from './autocomplete';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Simule la saisie d'une valeur dans le champ input du composant. */
function simulateInput(fixture: ReturnType<typeof TestBed.createComponent<Autocomplete>>, value: string): void {
  const input = fixture.nativeElement.querySelector('input') as HTMLInputElement;
  input.value = value;
  input.dispatchEvent(new Event('input', { bubbles: true }));
}

// ---------------------------------------------------------------------------
// Suite
// ---------------------------------------------------------------------------

describe('Autocomplete', () => {
  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [Autocomplete],
    });
  });

  // ===== Création =====

  it('should_create_component', () => {
    const fixture = TestBed.createComponent(Autocomplete);
    expect(fixture.componentInstance).toBeTruthy();
  });

  // ===== FR-015 — Seuil minChars =====

  describe('FR-015 — seuil minChars', () => {
    it('should_not_emit_queryChange_when_below_minChars', () => {
      vi.useFakeTimers();

      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('minChars', 2);
      fixture.detectChanges();

      const emitted: string[] = [];
      // eslint-disable-next-line @typescript-eslint/no-explicit-any -- Angular OutputRef subscribe
      const sub = (fixture.componentInstance.queryChange as any).subscribe((v: string) => emitted.push(v));

      // Un seul caractère — en dessous du seuil
      simulateInput(fixture, 'c');
      vi.advanceTimersByTime(300);

      expect(emitted).toHaveLength(0);

      sub?.unsubscribe?.();
      vi.useRealTimers();
    });

    it('should_not_open_list_when_below_minChars', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('minChars', 2);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino']);
      fixture.detectChanges();

      simulateInput(fixture, 'c');

      expect(fixture.componentInstance.isOpen()).toBe(false);
    });
  });

  // ===== FR-011 — Debounce 200ms =====

  describe('FR-011 — debounce 200ms', () => {
    it('should_emit_queryChange_debounced_200ms', () => {
      vi.useFakeTimers();

      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('minChars', 2);
      fixture.detectChanges();

      const emitted: string[] = [];
      // eslint-disable-next-line @typescript-eslint/no-explicit-any -- Angular OutputRef subscribe
      const sub = (fixture.componentInstance.queryChange as any).subscribe((v: string) => emitted.push(v));

      simulateInput(fixture, 'ca');

      // Avant 200ms — pas encore émis
      vi.advanceTimersByTime(199);
      expect(emitted).toHaveLength(0);

      // À 200ms — émission attendue
      vi.advanceTimersByTime(1);
      expect(emitted).toHaveLength(1);
      expect(emitted[0]).toBe('ca');

      sub?.unsubscribe?.();
      vi.useRealTimers();
    });

    it('should_not_emit_duplicate_query_when_value_unchanged', () => {
      vi.useFakeTimers();

      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('minChars', 2);
      fixture.detectChanges();

      const emitted: string[] = [];
      // eslint-disable-next-line @typescript-eslint/no-explicit-any -- Angular OutputRef subscribe
      const sub = (fixture.componentInstance.queryChange as any).subscribe((v: string) => emitted.push(v));

      simulateInput(fixture, 'ca');
      vi.advanceTimersByTime(200);
      expect(emitted).toHaveLength(1);

      // Même valeur → distinctUntilChanged doit bloquer
      simulateInput(fixture, 'ca');
      vi.advanceTimersByTime(200);
      expect(emitted).toHaveLength(1);

      sub?.unsubscribe?.();
      vi.useRealTimers();
    });
  });

  // ===== FR-012 — Filtrage local accent-insensible =====

  describe('FR-012 — filtrage local accent/casse insensible', () => {
    it('should_filter_suggestions_locally_accent_insensitive', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Café du coin', 'Carrefour']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.componentRef.setInput('maxDisplay', 10);
      fixture.detectChanges();

      // Définit la valeur directement via le model signal
      fixture.componentInstance.value.set('cafe');
      fixture.detectChanges();

      const visible = fixture.componentInstance.visibleSuggestions();
      expect(visible).toContain('Café du coin');
      expect(visible).not.toContain('Carrefour');
    });

    it('should_filter_suggestions_locally_case_insensitive', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino', 'Monoprix']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.componentRef.setInput('maxDisplay', 10);
      fixture.detectChanges();

      fixture.componentInstance.value.set('CARRE');
      fixture.detectChanges();

      const visible = fixture.componentInstance.visibleSuggestions();
      expect(visible).toContain('Carrefour');
      expect(visible).not.toContain('Casino');
      expect(visible).not.toContain('Monoprix');
    });

    it('should_include_all_suggestions_when_value_below_minChars', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino', 'Monoprix']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.componentRef.setInput('maxDisplay', 10);
      fixture.detectChanges();

      // Un seul caractère → retourne toutes les suggestions (non filtrées)
      fixture.componentInstance.value.set('c');
      fixture.detectChanges();

      const visible = fixture.componentInstance.visibleSuggestions();
      expect(visible).toHaveLength(3);
    });
  });

  // ===== FR-016 — Troncature maxDisplay =====

  describe('FR-016 — troncature maxDisplay', () => {
    it('should_limit_display_to_maxDisplay', () => {
      const suggestions = ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'];
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', suggestions);
      fixture.componentRef.setInput('maxDisplay', 5);
      fixture.componentRef.setInput('minChars', 2);
      fixture.detectChanges();

      // Valeur vide → tronque sur toutes les suggestions
      fixture.componentInstance.value.set('');
      fixture.detectChanges();

      expect(fixture.componentInstance.visibleSuggestions()).toHaveLength(5);
    });

    it('should_limit_filtered_results_to_maxDisplay', () => {
      // 6 suggestions qui contiennent toutes "market"
      const suggestions = ['Market A', 'Market B', 'Market C', 'Market D', 'Market E', 'Market F'];
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', suggestions);
      fixture.componentRef.setInput('maxDisplay', 5);
      fixture.componentRef.setInput('minChars', 2);
      fixture.detectChanges();

      fixture.componentInstance.value.set('market');
      fixture.detectChanges();

      expect(fixture.componentInstance.visibleSuggestions()).toHaveLength(5);
    });
  });

  // ===== FR-010 — Navigation clavier =====

  describe('FR-010 — navigation clavier', () => {
    it('should_navigate_with_arrow_down_and_up', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino', 'Monoprix']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.componentRef.setInput('maxDisplay', 10);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      // Ouvrir la liste manuellement
      component.isOpen.set(true);
      fixture.detectChanges();

      expect(component.activeIndex()).toBe(-1);

      component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
      expect(component.activeIndex()).toBe(0);

      component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
      expect(component.activeIndex()).toBe(1);

      component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowUp' }));
      expect(component.activeIndex()).toBe(0);
    });

    it('should_wrap_around_on_arrow_down_at_last_item', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.componentRef.setInput('maxDisplay', 10);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.isOpen.set(true);
      fixture.detectChanges();

      // Depuis -1 : ArrowDown×1 → 0, ArrowDown×2 → 1 (dernier), ArrowDown×3 → wrap à 0
      component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
      component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
      component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
      expect(component.activeIndex()).toBe(0);
    });

    it('should_select_active_option_on_enter', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino', 'Monoprix']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.componentRef.setInput('maxDisplay', 10);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.isOpen.set(true);
      fixture.detectChanges();

      const selected: string[] = [];
      // eslint-disable-next-line @typescript-eslint/no-explicit-any -- Angular OutputRef subscribe
      const sub = (component.selected as any).subscribe((v: string) => selected.push(v));

      component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
      component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
      // activeIndex = 1 → 'Casino'
      component.onKeydown(new KeyboardEvent('keydown', { key: 'Enter' }));

      expect(selected).toHaveLength(1);
      expect(selected[0]).toBe('Casino');
      expect(component.value()).toBe('Casino');
      expect(component.isOpen()).toBe(false);

      sub?.unsubscribe?.();
    });

    it('should_not_emit_selected_when_enter_with_no_active_option', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.isOpen.set(true);
      // activeIndex reste à -1

      const selected: string[] = [];
      // eslint-disable-next-line @typescript-eslint/no-explicit-any -- Angular OutputRef subscribe
      const sub = (component.selected as any).subscribe((v: string) => selected.push(v));

      component.onKeydown(new KeyboardEvent('keydown', { key: 'Enter' }));

      expect(selected).toHaveLength(0);

      sub?.unsubscribe?.();
    });
  });

  // ===== FR-009 / FR-010 — Escape =====

  describe('FR-009 / FR-010 — Escape', () => {
    it('should_close_on_escape_without_changing_value', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      const initialValue = 'ca';
      component.value.set(initialValue);
      component.isOpen.set(true);
      fixture.detectChanges();

      expect(component.isOpen()).toBe(true);

      component.onKeydown(new KeyboardEvent('keydown', { key: 'Escape' }));

      expect(component.isOpen()).toBe(false);
      // La valeur doit rester inchangée
      expect(component.value()).toBe(initialValue);
    });

    it('should_reset_active_index_on_escape', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.isOpen.set(true);
      component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
      expect(component.activeIndex()).toBe(0);

      component.onKeydown(new KeyboardEvent('keydown', { key: 'Escape' }));

      expect(component.activeIndex()).toBe(-1);
    });
  });

  // ===== NFR-005 — Attributs ARIA =====

  describe('NFR-005 — attributs ARIA', () => {
    it('should_expose_aria_attributes', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.componentRef.setInput('ariaLabel', 'Libellé de la transaction');
      fixture.detectChanges();

      const input = fixture.nativeElement.querySelector('input') as HTMLInputElement;

      // Input doit avoir role="combobox" et aria-autocomplete="list"
      expect(input.getAttribute('role')).toBe('combobox');
      expect(input.getAttribute('aria-autocomplete')).toBe('list');
    });

    it('should_set_aria_expanded_false_when_closed', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.isOpen.set(false);
      fixture.detectChanges();

      const input = fixture.nativeElement.querySelector('input') as HTMLInputElement;
      expect(input.getAttribute('aria-expanded')).toBe('false');
    });

    it('should_set_aria_expanded_true_when_open', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.isOpen.set(true);
      fixture.detectChanges();

      const input = fixture.nativeElement.querySelector('input') as HTMLInputElement;
      expect(input.getAttribute('aria-expanded')).toBe('true');
    });

    it('should_render_listbox_and_options_with_correct_roles_when_open', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.isOpen.set(true);
      fixture.detectChanges();

      const listbox = fixture.nativeElement.querySelector('[role="listbox"]') as HTMLElement;
      expect(listbox).toBeTruthy();

      const options = fixture.nativeElement.querySelectorAll('[role="option"]') as NodeList;
      expect(options.length).toBeGreaterThan(0);
    });

    it('should_set_aria_activedescendant_when_option_is_active', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.isOpen.set(true);
      fixture.detectChanges();

      component.onKeydown(new KeyboardEvent('keydown', { key: 'ArrowDown' }));
      fixture.detectChanges();

      const input = fixture.nativeElement.querySelector('input') as HTMLInputElement;
      const activedescendant = input.getAttribute('aria-activedescendant');
      expect(activedescendant).toBeTruthy();
      expect(activedescendant).toContain('option-0');
    });
  });

  // ===== Sélection par clic =====

  describe('Sélection par clic', () => {
    it('should_select_suggestion_on_click_and_close_list', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.componentRef.setInput('suggestions', ['Carrefour', 'Casino']);
      fixture.componentRef.setInput('minChars', 2);
      fixture.componentRef.setInput('maxDisplay', 10);
      fixture.detectChanges();

      const component = fixture.componentInstance;
      component.isOpen.set(true);
      fixture.detectChanges();

      const selected: string[] = [];
      // eslint-disable-next-line @typescript-eslint/no-explicit-any -- Angular OutputRef subscribe
      const sub = (component.selected as any).subscribe((v: string) => selected.push(v));

      component.onSuggestionClick(0);

      expect(selected).toHaveLength(1);
      expect(selected[0]).toBe('Carrefour');
      expect(component.isOpen()).toBe(false);

      sub?.unsubscribe?.();
    });
  });

  // ===== Nettoyage ngOnDestroy =====

  describe('Cycle de vie', () => {
    it('should_destroy_without_error', () => {
      const fixture = TestBed.createComponent(Autocomplete);
      fixture.detectChanges();
      expect(() => fixture.destroy()).not.toThrow();
    });
  });
});
