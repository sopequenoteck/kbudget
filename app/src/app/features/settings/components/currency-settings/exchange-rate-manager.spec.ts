import { TestBed } from '@angular/core/testing';
import { of, throwError } from 'rxjs';

import { ExchangeRateManager } from './exchange-rate-manager';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { ExchangeRate } from '../../../../core/models/exchange-rate.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

const makeRate = (overrides: Partial<ExchangeRate> = {}): ExchangeRate => ({
  id: 'rate-1',
  baseCurrency: 'EUR',
  targetCurrency: 'USD',
  rate: 1.1,
  updatedAt: '2026-01-01T00:00:00Z',
  ...overrides,
});

function createExchangeRateServiceMock() {
  return {
    upsert: vi.fn().mockReturnValue(of(makeRate())),
    delete: vi.fn().mockReturnValue(of(undefined)),
  };
}

describe('ExchangeRateManager', () => {
  let rateServiceMock: ReturnType<typeof createExchangeRateServiceMock>;

  beforeEach(() => {
    rateServiceMock = createExchangeRateServiceMock();
    TestBed.configureTestingModule({
      imports: [ExchangeRateManager],
      providers: [
        ...provideTranslocoTesting(),
        { provide: ExchangeRateService, useValue: rateServiceMock },
      ],
    });
  });

  const createFixture = (
    primaryCurrency = 'EUR',
    rates: ExchangeRate[] = [],
    loading = false,
  ) => {
    const fixture = TestBed.createComponent(ExchangeRateManager);
    fixture.componentRef.setInput('primaryCurrency', primaryCurrency);
    fixture.componentRef.setInput('rates', rates);
    fixture.componentRef.setInput('loading', loading);
    fixture.detectChanges();
    return fixture;
  };

  it('should_create_the_component', () => {
    const fixture = createFixture();
    expect(fixture.componentInstance).toBeTruthy();
  });

  // ---------------------------------------------------------------------
  // Rendu — textes traduits
  // ---------------------------------------------------------------------

  it('should_render_french_section_title_and_reference', () => {
    const fixture = createFixture('EUR');
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.settings-section__title')?.textContent).toBe('Taux de conversion');
    expect(el.querySelector('.rate-row__label')?.textContent).toBe('Référence');
  });

  it('should_render_french_loading_label', () => {
    const fixture = createFixture('EUR', [], true);
    const el: HTMLElement = fixture.nativeElement;
    const labels = Array.from(el.querySelectorAll('.rate-row__label')).map((n) => n.textContent);

    expect(labels).toContain('Chargement...');
  });

  it('should_render_french_empty_label_when_no_rates_configured', () => {
    const fixture = createFixture('EUR', [], false);
    const el: HTMLElement = fixture.nativeElement;
    const labels = Array.from(el.querySelectorAll('.rate-row__label')).map((n) => n.textContent);

    expect(labels).toContain('Aucun taux configuré');
  });

  it('should_not_render_empty_label_when_form_is_open', () => {
    const fixture = createFixture('EUR', [], false);
    fixture.componentInstance.openForm();
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;
    const labels = Array.from(el.querySelectorAll('.rate-row__label')).map((n) => n.textContent);

    expect(labels).not.toContain('Aucun taux configuré');
  });

  it('should_render_french_edit_aria_labels_for_each_rate', () => {
    const fixture = createFixture('EUR', [makeRate()]);
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.btn-action')?.getAttribute('aria-label')).toBe('Modifier');
    expect(el.querySelector('.btn-action--danger')?.getAttribute('aria-label')).toBe('Supprimer');
  });

  it('should_render_french_add_rate_title_when_opening_the_form', () => {
    const fixture = createFixture('EUR');
    fixture.componentInstance.openForm();
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('h3.settings-section__title')?.textContent?.trim()).toBe(
      'Ajouter un taux',
    );
  });

  it('should_render_french_edit_rate_title_when_editing', () => {
    const rate = makeRate();
    const fixture = createFixture('EUR', [rate]);
    fixture.componentInstance.startEdit(rate);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('h3.settings-section__title')?.textContent?.trim()).toBe(
      'Modifier le taux',
    );
  });

  it('should_render_french_form_field_labels', () => {
    const fixture = createFixture('EUR');
    fixture.componentInstance.openForm();
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;
    const labels = Array.from(el.querySelectorAll('.form-label')).map((n) => n.textContent);

    expect(labels).toEqual(['Devise de base', 'Devise cible', 'Taux']);
  });

  it('should_render_french_target_currency_placeholder_option', () => {
    const fixture = createFixture('EUR');
    fixture.componentInstance.openForm();
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('option[disabled]')?.textContent).toBe('Choisir une devise');
  });

  it('should_render_french_saving_label_while_saving', () => {
    const fixture = createFixture('EUR');
    fixture.componentInstance.openForm();
    fixture.componentInstance.isSaving.set(true);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.btn--primary')?.textContent?.trim()).toBe('Enregistrement...');
  });

  it('should_render_french_delete_confirmation_dialog_with_currency_pair', () => {
    const rate = makeRate({ baseCurrency: 'EUR', targetCurrency: 'USD' });
    const fixture = createFixture('EUR', [rate]);
    fixture.componentInstance.confirmDelete(rate);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.dialog__message')?.innerHTML).toContain('<strong>EUR → USD</strong>');
    expect(el.querySelector('.dialog__message')?.textContent?.trim()).toBe(
      'Supprimer le taux EUR → USD ?',
    );
  });

  it('should_escape_a_currency_code_injected_in_the_delete_confirmation_message', () => {
    const rate = makeRate({ baseCurrency: '<img src=x>', targetCurrency: 'USD' });
    const fixture = createFixture('EUR', [rate]);
    fixture.componentInstance.confirmDelete(rate);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.dialog__message img')).toBeNull();
    expect(el.querySelector('.dialog__message')?.textContent?.trim()).toBe(
      'Supprimer le taux <img src=x> → USD ?',
    );
  });

  it('should_render_french_deleting_label_while_deleting', () => {
    const rate = makeRate();
    const fixture = createFixture('EUR', [rate]);
    fixture.componentInstance.confirmDelete(rate);
    fixture.componentInstance.isDeleting.set(true);
    fixture.detectChanges();
    const el: HTMLElement = fixture.nativeElement;

    expect(el.querySelector('.dialog__actions .btn--danger')?.textContent?.trim()).toBe(
      'Suppression...',
    );
  });

  // ---------------------------------------------------------------------
  // openForm / startEdit / cancelForm
  // ---------------------------------------------------------------------

  it('should_reset_form_state_when_opening', () => {
    const fixture = createFixture('EUR');
    const component = fixture.componentInstance;
    component.formTargetCurrency.set('USD');
    component.formRate.set(1.2);

    component.openForm();

    expect(component.editingRate()).toBeNull();
    expect(component.formTargetCurrency()).toBe('');
    expect(component.formRate()).toBeNull();
    expect(component.showForm()).toBe(true);
  });

  it('should_populate_form_state_when_starting_edit', () => {
    const rate = makeRate({ targetCurrency: 'USD', rate: 1.15 });
    const fixture = createFixture('EUR', [rate]);
    const component = fixture.componentInstance;

    component.startEdit(rate);

    expect(component.editingRate()).toEqual(rate);
    expect(component.formTargetCurrency()).toBe('USD');
    expect(component.formRate()).toBe(1.15);
    expect(component.showForm()).toBe(true);
  });

  it('should_reset_form_state_when_cancelling', () => {
    const fixture = createFixture('EUR');
    const component = fixture.componentInstance;
    component.openForm();
    component.formTargetCurrency.set('USD');

    component.cancelForm();

    expect(component.showForm()).toBe(false);
    expect(component.editingRate()).toBeNull();
    expect(component.formTargetCurrency()).toBe('');
    expect(component.formRate()).toBeNull();
  });

  it('should_apply_fixed_parity_rate_when_known_pair_selected', () => {
    const fixture = createFixture('EUR');
    const component = fixture.componentInstance;

    component.onTargetCurrencyChange('XOF');

    expect(component.formTargetCurrency()).toBe('XOF');
    expect(component.formRate()).toBe(655.957);
  });

  it('should_not_change_rate_when_pair_has_no_fixed_parity', () => {
    const fixture = createFixture('EUR');
    const component = fixture.componentInstance;
    component.formRate.set(42);

    component.onTargetCurrencyChange('GBP');

    expect(component.formRate()).toBe(42);
  });

  it('should_compute_available_target_currencies_excluding_primary_and_existing', () => {
    const fixture = createFixture('EUR', [makeRate({ targetCurrency: 'USD' })]);

    expect(fixture.componentInstance.availableTargetCurrencies()).toEqual([
      'XOF',
      'GBP',
      'CHF',
      'CAD',
      'MAD',
    ]);
  });

  // ---------------------------------------------------------------------
  // saveRate — validation et erreurs traduites
  // ---------------------------------------------------------------------

  it('should_set_french_error_when_target_currency_is_missing', async () => {
    const fixture = createFixture('EUR');
    fixture.componentInstance.openForm();

    await fixture.componentInstance.saveRate();

    expect(fixture.componentInstance.formError()).toBe('Veuillez sélectionner une devise cible.');
    expect(rateServiceMock.upsert).not.toHaveBeenCalled();
  });

  it('should_set_french_error_when_rate_is_invalid', async () => {
    const fixture = createFixture('EUR');
    fixture.componentInstance.openForm();
    fixture.componentInstance.formTargetCurrency.set('USD');
    fixture.componentInstance.formRate.set(0);

    await fixture.componentInstance.saveRate();

    expect(fixture.componentInstance.formError()).toBe('Veuillez saisir un taux valide (> 0).');
    expect(rateServiceMock.upsert).not.toHaveBeenCalled();
  });

  it('should_save_rate_and_emit_rateSaved_on_success', async () => {
    const fixture = createFixture('EUR');
    const emitted: void[] = [];
    fixture.componentInstance.rateSaved.subscribe(() => emitted.push(undefined));
    fixture.componentInstance.openForm();
    fixture.componentInstance.formTargetCurrency.set('USD');
    fixture.componentInstance.formRate.set(1.1);

    await fixture.componentInstance.saveRate();

    expect(rateServiceMock.upsert).toHaveBeenCalledWith('EUR', 'USD', 1.1);
    expect(emitted.length).toBe(1);
    expect(fixture.componentInstance.showForm()).toBe(false);
  });

  it('should_set_french_error_when_save_fails', async () => {
    rateServiceMock.upsert.mockReturnValue(throwError(() => new Error('boom')));
    const fixture = createFixture('EUR');
    fixture.componentInstance.openForm();
    fixture.componentInstance.formTargetCurrency.set('USD');
    fixture.componentInstance.formRate.set(1.1);

    await fixture.componentInstance.saveRate();

    expect(fixture.componentInstance.formError()).toBe("Erreur lors de l'enregistrement du taux.");
    expect(fixture.componentInstance.isSaving()).toBe(false);
  });

  // ---------------------------------------------------------------------
  // confirmDelete / cancelDelete / deleteRate
  // ---------------------------------------------------------------------

  it('should_set_rate_to_delete_on_confirmDelete', () => {
    const rate = makeRate();
    const fixture = createFixture('EUR', [rate]);

    fixture.componentInstance.confirmDelete(rate);

    expect(fixture.componentInstance.rateToDelete()).toEqual(rate);
  });

  it('should_clear_rate_to_delete_on_cancelDelete', () => {
    const rate = makeRate();
    const fixture = createFixture('EUR', [rate]);
    fixture.componentInstance.confirmDelete(rate);

    fixture.componentInstance.cancelDelete();

    expect(fixture.componentInstance.rateToDelete()).toBeNull();
  });

  it('should_do_nothing_when_deleting_without_a_pending_rate', async () => {
    const fixture = createFixture('EUR');

    await fixture.componentInstance.deleteRate();

    expect(rateServiceMock.delete).not.toHaveBeenCalled();
  });

  it('should_delete_rate_and_emit_rateDeleted_on_success', async () => {
    const rate = makeRate();
    const fixture = createFixture('EUR', [rate]);
    const emitted: void[] = [];
    fixture.componentInstance.rateDeleted.subscribe(() => emitted.push(undefined));
    fixture.componentInstance.confirmDelete(rate);

    await fixture.componentInstance.deleteRate();

    expect(rateServiceMock.delete).toHaveBeenCalledWith('EUR', 'USD');
    expect(emitted.length).toBe(1);
    expect(fixture.componentInstance.rateToDelete()).toBeNull();
  });

  it('should_clear_rate_to_delete_when_delete_fails', async () => {
    rateServiceMock.delete.mockReturnValue(throwError(() => new Error('boom')));
    const rate = makeRate();
    const fixture = createFixture('EUR', [rate]);
    fixture.componentInstance.confirmDelete(rate);

    await fixture.componentInstance.deleteRate();

    expect(fixture.componentInstance.rateToDelete()).toBeNull();
    expect(fixture.componentInstance.isDeleting()).toBe(false);
  });
});
