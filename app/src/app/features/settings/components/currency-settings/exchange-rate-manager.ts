import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  input,
  output,
  signal,
} from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorPencilSimple,
  phosphorTrash,
  phosphorPlus,
  phosphorArrowRight,
  phosphorX,
  phosphorFloppyDisk,
} from '@ng-icons/phosphor-icons/regular';
import { firstValueFrom } from 'rxjs';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';

import { ExchangeRate } from '../../../../core/models/exchange-rate.model';
import { SUPPORTED_CURRENCIES } from '../../../../core/models/currency.model';
import { ExchangeRateService } from '../../../../core/services/exchange-rate';
import { escapeHtml } from '../../../../shared/utils/html-escape.utils';

const FIXED_PARITY_RATES: Record<string, number> = {
  EUR_XOF: 655.957,
};

@Component({
  selector: 'app-exchange-rate-manager',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [DecimalPipe, FormsModule, NgIcon, TranslocoPipe],
  viewProviders: [
    provideIcons({
      phosphorPencilSimple,
      phosphorTrash,
      phosphorPlus,
      phosphorArrowRight,
      phosphorX,
      phosphorFloppyDisk,
    }),
  ],
  template: `
    <!-- Section : Taux de conversion -->
    <div class="settings-section">
      <div class="settings-section__header">
        <span class="settings-section__title">{{ 'exchangeRates.page.ratesTitle' | transloco }}</span>
        @if (!showForm()) {
          <button class="add-btn" (click)="openForm()">
            <ng-icon name="phosphorPlus" size="16" />
          </button>
        }
      </div>
      <div class="section-content">
        <div class="rate-row rate-row--info">
          <span class="rate-row__label">{{ 'exchangeRates.list.reference' | transloco }}</span>
          <span class="rate-row__value">{{ primaryCurrency() }}</span>
        </div>

        @if (loading()) {
          <div class="rate-row rate-row--info">
            <span class="rate-row__label">{{ 'common.feedback.loading' | transloco }}</span>
          </div>
        }

        @if (!loading() && rates().length === 0 && !showForm()) {
          <div class="rate-row rate-row--info">
            <span class="rate-row__label">{{ 'exchangeRates.empty.title' | transloco }}</span>
          </div>
        }

        @for (rate of rates(); track rate.id) {
          <div class="rate-row">
            <span class="rate-row__pair">
              {{ rate.baseCurrency }}
              <ng-icon name="phosphorArrowRight" size="14" />
              {{ rate.targetCurrency }}
            </span>
            <span class="rate-row__value">{{ rate.rate | number: '1.0-6' }}</span>
            <button class="btn-action" (click)="startEdit(rate)" [attr.aria-label]="'common.action.edit' | transloco">
              <ng-icon name="phosphorPencilSimple" size="16" />
            </button>
            <button class="btn-action btn-action--danger" (click)="confirmDelete(rate)" [attr.aria-label]="'common.action.delete' | transloco">
              <ng-icon name="phosphorTrash" size="16" />
            </button>
          </div>
        }
      </div>
    </div>

    <!-- Formulaire upsert -->
    @if (showForm()) {
      <div class="settings-section">
        <h3 class="settings-section__title">
          {{ (editingRate() ? 'exchangeRates.dialog.editRateTitle' : 'exchangeRates.dialog.addRateTitle') | transloco }}
        </h3>
        <div class="section-content section-content--padded">
          <div class="form-grid">
            <div class="form-field">
              <span class="form-label">{{ 'exchangeRates.form.baseCurrency' | transloco }}</span>
              <div class="form-readonly">{{ primaryCurrency() }}</div>
            </div>

            <div class="form-field">
              <label class="form-label" for="targetCurrency">{{ 'exchangeRates.form.targetCurrency' | transloco }}</label>
              @if (editingRate()) {
                <div class="form-readonly">{{ formTargetCurrency() }}</div>
              } @else {
                <select
                  id="targetCurrency"
                  class="form-select"
                  [ngModel]="formTargetCurrency()"
                  (ngModelChange)="onTargetCurrencyChange($event)"
                >
                  <option value="" disabled>{{ 'exchangeRates.form.targetCurrencyPlaceholder' | transloco }}</option>
                  @for (currency of availableTargetCurrencies(); track currency) {
                    <option [value]="currency">{{ currency }}</option>
                  }
                </select>
              }
            </div>

            <div class="form-field form-field--full">
              <label class="form-label" for="rateInput">{{ 'exchangeRates.form.rate' | transloco }}</label>
              <input
                id="rateInput"
                type="number"
                class="form-input"
                [ngModel]="formRate()"
                (ngModelChange)="formRate.set($event)"
                min="0.000001"
                step="0.000001"
                [placeholder]="'exchangeRates.form.ratePlaceholder' | transloco"
              />
            </div>
          </div>

          @if (formError()) {
            <p class="form-error">{{ formError() }}</p>
          }

          <div class="form-actions">
            <button class="btn btn--ghost" (click)="cancelForm()">
              <ng-icon name="phosphorX" size="16" />
              {{ 'common.action.cancel' | transloco }}
            </button>
            <button
              class="btn btn--primary"
              [disabled]="isSaving()"
              (click)="saveRate()"
            >
              <ng-icon name="phosphorFloppyDisk" size="16" />
              {{ (isSaving() ? 'common.feedback.saving' : 'common.action.save') | transloco }}
            </button>
          </div>
        </div>
      </div>
    }

    <!-- Dialog de confirmation de suppression -->
    @if (rateToDelete()) {
      <!-- eslint-disable-next-line @angular-eslint/template/click-events-have-key-events,@angular-eslint/template/interactive-supports-focus -->
      <div class="dialog-overlay" (click)="cancelDelete()">
        <!-- eslint-disable-next-line @angular-eslint/template/click-events-have-key-events,@angular-eslint/template/interactive-supports-focus -->
        <div
          class="dialog"
          (click)="$event.stopPropagation()"
        >
          <p
            class="dialog__message"
            [innerHTML]="'exchangeRates.dialog.deleteRateMessage' | transloco: deleteRateMessageParams()!"
          ></p>
          <div class="dialog__actions">
            <button class="btn btn--ghost" (click)="cancelDelete()">{{ 'common.action.cancel' | transloco }}</button>
            <button class="btn btn--danger" [disabled]="isDeleting()" (click)="deleteRate()">
              {{ (isDeleting() ? 'common.feedback.deleting' : 'common.action.delete') | transloco }}
            </button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [
    `
      .settings-section__header {
        display: flex; align-items: center; justify-content: space-between;
        padding: 0 var(--space-4); margin-bottom: var(--space-2);
      }

      .settings-section__title {
        font-size: var(--font-size-xs); font-weight: var(--font-weight-semibold);
        text-transform: uppercase; letter-spacing: 0.5px; color: var(--text-tertiary);
      }

      .add-btn {
        display: flex; align-items: center; justify-content: center;
        width: 28px; height: 28px; padding: 0;
        border: 1px solid var(--border-default); border-radius: var(--radius-round);
        background: transparent; color: var(--text-tertiary); cursor: pointer;
        &:active { color: var(--text-primary); background-color: var(--hover-bg); }
      }

      .section-content {
        background: var(--surface-default); border-radius: var(--radius-xl); overflow: hidden;
        &--padded { padding: var(--space-4); }
      }

      .rate-row {
        display: flex; align-items: center; gap: var(--space-3);
        padding: var(--space-3) var(--space-4);
        border-bottom: 1px solid var(--border-default);
        &:last-child { border-bottom: none; }

        &--info { color: var(--text-tertiary); font-size: var(--font-size-xs); }

        &__label { font-size: var(--font-size-sm); color: var(--text-tertiary); }
        &__pair {
          display: flex; align-items: center; gap: var(--space-1);
          font-size: var(--font-size-sm); font-weight: var(--font-weight-medium);
          color: var(--text-secondary); flex: 1;
        }
        &__value {
          font-size: var(--font-size-sm); font-weight: var(--font-weight-semibold);
          color: var(--text-secondary); font-variant-numeric: tabular-nums; margin-left: auto;
        }
      }

      .btn-action {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 32px;
        height: 32px;
        border: none;
        border-radius: var(--radius-round);
        background: transparent;
        color: var(--text-tertiary);
        cursor: pointer;
        transition: background-color var(--duration-fast) var(--easing-default),
          color var(--duration-fast) var(--easing-default);

        &:hover {
          background-color: var(--hover-bg);
          color: var(--text-primary);
        }

        &--danger {
          color: var(--color-expense);

          &:hover {
            background-color: var(--bg-error);
          }
        }
      }

      .form-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: var(--space-3);
        margin-bottom: var(--space-3);
      }

      .form-field {
        display: flex;
        flex-direction: column;
        gap: var(--space-2);

        &--full {
          grid-column: 1 / -1;
        }
      }

      .form-label {
        font-size: var(--font-size-sm);
        font-weight: var(--font-weight-medium);
        color: var(--text-secondary);
      }

      .form-readonly {
        padding: var(--space-2) var(--space-3);
        background: transparent;
        border: 1px solid var(--border-default);
        border-radius: var(--radius-md);
        font-size: var(--font-size-sm);
        color: var(--text-primary);
        font-weight: var(--font-weight-semibold);
      }

      .form-select {
        padding: var(--space-2) var(--space-3);
        border: 1px solid var(--border-default);
        border-radius: var(--radius-md);
        background: var(--surface-default);
        color: var(--text-primary);
        font-size: var(--font-size-sm);
        cursor: pointer;
        appearance: auto;

        &:focus {
          outline: 2px solid var(--color-primary);
          outline-offset: 2px;
        }
      }

      .form-input {
        padding: var(--space-2) var(--space-3);
        border: 1px solid var(--border-default);
        border-radius: var(--radius-md);
        background: var(--surface-default);
        color: var(--text-primary);
        font-size: var(--font-size-sm);
        width: 100%;
        box-sizing: border-box;

        &:focus {
          outline: 2px solid var(--color-primary);
          outline-offset: 2px;
        }

        &::placeholder {
          color: var(--text-tertiary, var(--text-secondary));
        }
      }

      .form-error {
        font-size: var(--font-size-sm);
        color: var(--color-expense);
        margin-bottom: var(--space-3);
      }

      .form-actions {
        display: flex;
        justify-content: flex-end;
        gap: var(--space-2);
      }

      .btn {
        display: inline-flex;
        align-items: center;
        gap: var(--space-2);
        padding: var(--space-1) var(--space-3);
        border-radius: var(--radius-round);
        font-size: var(--font-size-sm);
        font-weight: var(--font-weight-medium);
        cursor: pointer;
        transition: opacity var(--duration-fast) var(--easing-default),
          background-color var(--duration-fast) var(--easing-default);
        border: none;

        &:disabled {
          opacity: 0.5;
          cursor: not-allowed;
        }

        &--primary {
          background-color: var(--color-primary);
          color: var(--text-inverse);

          &:hover:not(:disabled) {
            opacity: 0.85;
          }
        }

        &--ghost {
          background: transparent;
          border: 1px solid var(--border-default);
          color: var(--text-secondary);

          &:hover:not(:disabled) {
            background-color: var(--hover-bg);
            color: var(--text-primary);
          }
        }

        &--danger {
          background-color: var(--color-expense);
          color: white;

          &:hover:not(:disabled) {
            opacity: 0.85;
          }
        }
      }

      .dialog-overlay {
        position: fixed;
        inset: 0;
        background: var(--surface-overlay);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
        padding: var(--space-4);
      }

      .dialog {
        background: var(--surface-default);
        border-radius: var(--radius-xl);
        padding: var(--space-6);
        max-width: 400px;
        width: 100%;
        box-shadow: var(--shadow-xl);

        &__message {
          font-size: var(--font-size-sm);
          color: var(--text-primary);
          margin-bottom: var(--space-5);
          line-height: 1.5;
        }

        &__actions {
          display: flex;
          justify-content: flex-end;
          gap: var(--space-2);
        }
      }
    `,
  ],
})
export class ExchangeRateManager {
  private readonly rateService = inject(ExchangeRateService);
  private readonly transloco = inject(TranslocoService);

  readonly primaryCurrency = input.required<string>();
  readonly rates = input.required<ExchangeRate[]>();
  readonly loading = input.required<boolean>();

  readonly rateSaved = output<void>();
  readonly rateDeleted = output<void>();

  readonly FIXED_PARITY_RATES = FIXED_PARITY_RATES;
  readonly SUPPORTED_CURRENCIES = SUPPORTED_CURRENCIES;

  readonly showForm = signal(false);
  readonly editingRate = signal<ExchangeRate | null>(null);
  readonly formTargetCurrency = signal('');
  readonly formRate = signal<number | null>(null);
  readonly formError = signal<string | null>(null);
  readonly isSaving = signal(false);
  readonly rateToDelete = signal<ExchangeRate | null>(null);
  readonly isDeleting = signal(false);

  readonly availableTargetCurrencies = computed(() => {
    const primary = this.primaryCurrency();
    const existingTargets = new Set(this.rates().map((r) => r.targetCurrency));
    return SUPPORTED_CURRENCIES.filter(
      (c) => c !== primary && !existingTargets.has(c),
    );
  });

  /**
   * Parametres du dialogue de suppression, echappes avant interpolation dans
   * le `[innerHTML]` du template : les devises viennent d'un taux enregistre,
   * pas d'une liste fermee cote client — MessageFormat ne les echappe pas.
   */
  readonly deleteRateMessageParams = computed(() => {
    const rate = this.rateToDelete();
    if (!rate) return null;
    return {
      baseCurrency: escapeHtml(rate.baseCurrency),
      targetCurrency: escapeHtml(rate.targetCurrency),
    };
  });

  openForm(): void {
    this.editingRate.set(null);
    this.formTargetCurrency.set('');
    this.formRate.set(null);
    this.formError.set(null);
    this.showForm.set(true);
  }

  startEdit(rate: ExchangeRate): void {
    this.editingRate.set(rate);
    this.formTargetCurrency.set(rate.targetCurrency);
    this.formRate.set(rate.rate);
    this.formError.set(null);
    this.showForm.set(true);
  }

  cancelForm(): void {
    this.showForm.set(false);
    this.editingRate.set(null);
    this.formTargetCurrency.set('');
    this.formRate.set(null);
    this.formError.set(null);
  }

  onTargetCurrencyChange(currency: string): void {
    this.formTargetCurrency.set(currency);
    const key = `${this.primaryCurrency()}_${currency}`;
    const fixed = FIXED_PARITY_RATES[key];
    if (fixed !== undefined) {
      this.formRate.set(fixed);
    }
  }

  async saveRate(): Promise<void> {
    const target = this.formTargetCurrency();
    const rate = this.formRate();

    if (!target) {
      this.formError.set(this.transloco.translate('exchangeRates.form.targetRequired'));
      return;
    }
    if (!rate || rate <= 0) {
      this.formError.set(this.transloco.translate('exchangeRates.form.rateInvalid'));
      return;
    }

    this.formError.set(null);
    this.isSaving.set(true);
    try {
      await firstValueFrom(
        this.rateService.upsert(this.primaryCurrency(), target, rate),
      );
      this.cancelForm();
      this.rateSaved.emit();
    } catch {
      this.formError.set(this.transloco.translate('exchangeRates.feedback.saveError'));
    } finally {
      this.isSaving.set(false);
    }
  }

  confirmDelete(rate: ExchangeRate): void {
    this.rateToDelete.set(rate);
  }

  cancelDelete(): void {
    this.rateToDelete.set(null);
  }

  async deleteRate(): Promise<void> {
    const rate = this.rateToDelete();
    if (!rate) return;

    this.isDeleting.set(true);
    try {
      await firstValueFrom(
        this.rateService.delete(rate.baseCurrency, rate.targetCurrency),
      );
      this.rateToDelete.set(null);
      this.rateDeleted.emit();
    } catch {
      this.rateToDelete.set(null);
    } finally {
      this.isDeleting.set(false);
    }
  }
}
