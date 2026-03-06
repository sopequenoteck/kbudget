import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
  computed,
  inject,
  signal,
} from '@angular/core';
import { DecimalPipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorCurrencyCircleDollar,
  phosphorPencilSimple,
  phosphorTrash,
  phosphorPlus,
  phosphorArrowRight,
  phosphorCalculator,
  phosphorX,
  phosphorFloppyDisk,
  phosphorDotsSixVertical,
} from '@ng-icons/phosphor-icons/regular';
import { CdkDropList, CdkDrag, CdkDragDrop, moveItemInArray } from '@angular/cdk/drag-drop';

import { ExchangeRateService } from '../../../core/services/exchange-rate';
import { PreferenceService } from '../../../core/services/preference';
import { AccountService } from '../../../core/services/account';
import { ExchangeRate } from '../../../core/models/exchange-rate.model';
import { Account } from '../../../core/models/account.model';
import { firstValueFrom } from 'rxjs';

const FIXED_PARITY_RATES: Record<string, number> = {
  EUR_XOF: 655.957,
};

const ALL_CURRENCIES = ['EUR', 'USD', 'XOF', 'GBP', 'CHF', 'CAD', 'MAD'];

@Component({
  selector: 'app-currency-settings',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [DecimalPipe, FormsModule, NgIcon, RouterLink, CdkDropList, CdkDrag],
  viewProviders: [
    provideIcons({
      phosphorCurrencyCircleDollar,
      phosphorPencilSimple,
      phosphorTrash,
      phosphorPlus,
      phosphorArrowRight,
      phosphorCalculator,
      phosphorX,
      phosphorFloppyDisk,
      phosphorDotsSixVertical,
    }),
  ],
  template: `
    <a class="section-back" routerLink="/settings">
      <span class="section-back__arrow">&#9664;</span>
      <span>Paramètres</span>
    </a>

    <h2 class="page-title">
      <ng-icon name="phosphorCurrencyCircleDollar" size="24" />
      Devises & Taux
    </h2>

    <!-- Section : Mes devises -->
    <div class="settings-section">
      <h3 class="settings-section__title">Mes devises</h3>
      <div class="currencies-list" cdkDropList (cdkDropListDropped)="onDrop($event)">
        @for (currency of currencies(); track currency; let i = $index) {
          <div class="currency-item" cdkDrag>
            <div class="currency-item__handle" cdkDragHandle>
              <ng-icon name="phosphorDotsSixVertical" size="20" />
            </div>
            <span class="currency-item__symbol">{{ CURRENCY_SYMBOLS[currency] || currency }}</span>
            <span class="currency-item__name">{{ CURRENCY_NAMES[currency] || currency }}</span>
            @if (i === 0) {
              <span class="currency-item__badge">Principale</span>
            }
            @if (i > 0) {
              <button class="currency-item__delete icon-btn icon-btn--danger" (click)="removeCurrency(currency)" aria-label="Supprimer cette devise">
                <ng-icon name="phosphorTrash" size="18" />
              </button>
            }
          </div>
        }
      </div>

      @if (availableCurrenciesToAdd().length > 0) {
        <div class="add-currency">
          <select class="add-currency__select form-select" #currencySelect>
            <option value="" disabled selected>Ajouter une devise...</option>
            @for (c of availableCurrenciesToAdd(); track c) {
              <option [value]="c">{{ CURRENCY_SYMBOLS[c] }} — {{ CURRENCY_NAMES[c] }}</option>
            }
          </select>
          <button class="btn btn--primary" (click)="addCurrency(currencySelect.value); currencySelect.value = ''">
            <ng-icon name="phosphorPlus" size="18" />
            Ajouter
          </button>
        </div>
      }
    </div>

    <!-- Warning : devise utilisée par des comptes -->
    @if (showRemoveWarning()) {
      <div class="dialog-overlay" (click)="showRemoveWarning.set(false)">
        <div class="dialog" (click)="$event.stopPropagation()">
          <p class="dialog__message">
            La devise <strong>{{ CURRENCY_NAMES[currencyToRemove()!] || currencyToRemove() }}</strong>
            est utilisée par des comptes existants. Retirer quand même ?
          </p>
          <div class="dialog__actions">
            <button class="btn btn--ghost" (click)="showRemoveWarning.set(false)">Annuler</button>
            <button class="btn btn--danger" (click)="doRemoveCurrency(currencyToRemove()!)">Retirer</button>
          </div>
        </div>
      </div>
    }

    <!-- Section : Taux de conversion -->
    <div class="settings-section">
      <h3 class="settings-section__title">Taux de conversion</h3>
      <p class="settings-section__desc">
        Devise de référence : <strong>{{ primaryCurrency() }}</strong>
      </p>

      @if (rateService.loading()) {
        <div class="loading-placeholder">Chargement des taux...</div>
      }

      @if (!rateService.loading() && rateService.rates().length === 0 && !showForm()) {
        <p class="empty-state">Aucun taux configuré.</p>
      }

      @if (rateService.rates().length > 0) {
        <ul class="rate-list">
          @for (rate of rateService.rates(); track rate.id) {
            <li class="rate-item">
              <span class="rate-item__label">
                {{ rate.baseCurrency }}
                <ng-icon name="phosphorArrowRight" size="14" />
                {{ rate.targetCurrency }}
              </span>
              <span class="rate-item__value">{{ rate.rate | number: '1.0-6' }}</span>
              <div class="rate-item__actions">
                <button
                  class="icon-btn"
                  title="Modifier"
                  (click)="startEdit(rate)"
                  aria-label="Modifier ce taux"
                >
                  <ng-icon name="phosphorPencilSimple" size="16" />
                </button>
                <button
                  class="icon-btn icon-btn--danger"
                  title="Supprimer"
                  (click)="confirmDelete(rate)"
                  aria-label="Supprimer ce taux"
                >
                  <ng-icon name="phosphorTrash" size="16" />
                </button>
              </div>
            </li>
          }
        </ul>
      }

      @if (!showForm()) {
        <button class="add-btn" (click)="openForm()">
          <ng-icon name="phosphorPlus" size="16" />
          Ajouter un taux
        </button>
      }
    </div>

    <!-- Formulaire upsert -->
    @if (showForm()) {
      <div class="settings-section settings-section--form">
        <h3 class="settings-section__title">
          {{ editingRate() ? 'Modifier le taux' : 'Ajouter un taux' }}
        </h3>

        <div class="form-grid">
          <div class="form-field">
            <label class="form-label">Devise de base</label>
            <div class="form-readonly">{{ primaryCurrency() }}</div>
          </div>

          <div class="form-field">
            <label class="form-label" for="targetCurrency">Devise cible</label>
            @if (editingRate()) {
              <div class="form-readonly">{{ formTargetCurrency() }}</div>
            } @else {
              <select
                id="targetCurrency"
                class="form-select"
                [ngModel]="formTargetCurrency()"
                (ngModelChange)="onTargetCurrencyChange($event)"
              >
                <option value="" disabled>Choisir une devise</option>
                @for (currency of availableTargetCurrencies(); track currency) {
                  <option [value]="currency">{{ currency }}</option>
                }
              </select>
            }
          </div>

          <div class="form-field form-field--full">
            <label class="form-label" for="rateInput">Taux</label>
            <input
              id="rateInput"
              type="number"
              class="form-input"
              [ngModel]="formRate()"
              (ngModelChange)="formRate.set($event)"
              min="0.000001"
              step="0.000001"
              placeholder="Ex: 655.957"
            />
          </div>
        </div>

        @if (formError()) {
          <p class="form-error">{{ formError() }}</p>
        }

        <div class="form-actions">
          <button class="btn btn--ghost" (click)="cancelForm()">
            <ng-icon name="phosphorX" size="16" />
            Annuler
          </button>
          <button
            class="btn btn--primary"
            [disabled]="isSaving()"
            (click)="saveRate()"
          >
            <ng-icon name="phosphorFloppyDisk" size="16" />
            {{ isSaving() ? 'Enregistrement...' : 'Enregistrer' }}
          </button>
        </div>
      </div>
    }

    <!-- Calculateur de taux -->
    <div class="settings-section">
      <h3 class="settings-section__title">
        <ng-icon name="phosphorCalculator" size="16" />
        Calculateur de taux
      </h3>
      <p class="settings-section__desc">Calculez un taux à partir d'un montant converti.</p>

      <div class="calculator">
        <div class="calculator__row">
          <label class="form-label">J'ai</label>
          <div class="calculator__input-group">
            <input
              type="number"
              class="form-input"
              [ngModel]="calcAmount1()"
              (ngModelChange)="calcAmount1.set($event)"
              min="0"
              step="any"
              placeholder="Montant"
            />
            <select
              class="form-select form-select--currency"
              [ngModel]="calcCurrency1()"
              (ngModelChange)="calcCurrency1.set($event)"
            >
              @for (c of allCurrencies; track c) {
                <option [value]="c">{{ c }}</option>
              }
            </select>
          </div>
        </div>

        <div class="calculator__equals">=</div>

        <div class="calculator__row">
          <label class="form-label">Équivaut à</label>
          <div class="calculator__input-group">
            <input
              type="number"
              class="form-input"
              [ngModel]="calcAmount2()"
              (ngModelChange)="calcAmount2.set($event)"
              min="0"
              step="any"
              placeholder="Montant"
            />
            <select
              class="form-select form-select--currency"
              [ngModel]="calcCurrency2()"
              (ngModelChange)="calcCurrency2.set($event)"
            >
              @for (c of allCurrencies; track c) {
                <option [value]="c">{{ c }}</option>
              }
            </select>
          </div>
        </div>

        @if (calculatedRate() !== null) {
          <div class="calculator__result">
            1 {{ calcCurrency1() }} = <strong>{{ calculatedRate() | number: '1.0-6' }}</strong> {{ calcCurrency2() }}
          </div>
        }
      </div>
    </div>

    <!-- Dialog de confirmation de suppression -->
    @if (rateToDelete()) {
      <div class="dialog-overlay" (click)="cancelDelete()">
        <div class="dialog" (click)="$event.stopPropagation()">
          <p class="dialog__message">
            Supprimer le taux
            <strong>{{ rateToDelete()!.baseCurrency }} → {{ rateToDelete()!.targetCurrency }}</strong> ?
          </p>
          <div class="dialog__actions">
            <button class="btn btn--ghost" (click)="cancelDelete()">Annuler</button>
            <button class="btn btn--danger" [disabled]="isDeleting()" (click)="deleteRate()">
              {{ isDeleting() ? 'Suppression...' : 'Supprimer' }}
            </button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [
    `
      :host {
        display: block;
        padding: var(--space-4);
      }

      .section-back {
        display: inline-flex;
        align-items: center;
        gap: var(--space-2);
        color: var(--text-secondary);
        text-decoration: none;
        font-size: var(--font-size-sm);
        margin-bottom: var(--space-6);

        &:hover {
          color: var(--text-primary);
        }

        &__arrow {
          font-size: var(--font-size-xs);
        }
      }

      .page-title {
        display: flex;
        align-items: center;
        gap: var(--space-2);
        font-size: var(--font-size-xl);
        font-weight: var(--font-weight-semibold);
        color: var(--text-primary);
        margin-bottom: var(--space-6);
      }

      .settings-section {
        background: var(--surface-default);
        border: 1px solid var(--border-default);
        border-radius: var(--radius-xl);
        padding: var(--space-5);
        margin-bottom: var(--space-4);

        &__title {
          display: flex;
          align-items: center;
          gap: var(--space-2);
          font-size: var(--font-size-sm);
          font-weight: var(--font-weight-semibold);
          color: var(--text-primary);
          margin-bottom: var(--space-2);
        }

        &__desc {
          font-size: var(--font-size-sm);
          color: var(--text-secondary);
          margin-bottom: var(--space-4);
        }

        &--form {
          border-color: var(--color-primary);
          border-width: 2px;
        }
      }

      .loading-placeholder {
        font-size: var(--font-size-sm);
        color: var(--text-secondary);
        padding: var(--space-3) 0;
      }

      .empty-state {
        font-size: var(--font-size-sm);
        color: var(--text-secondary);
        font-style: italic;
        margin-bottom: var(--space-3);
      }

      .rate-list {
        list-style: none;
        padding: 0;
        margin: 0 0 var(--space-4) 0;
        display: flex;
        flex-direction: column;
        gap: var(--space-2);
      }

      .rate-item {
        display: flex;
        align-items: center;
        gap: var(--space-3);
        padding: var(--space-3) var(--space-4);
        background: var(--surface-raised);
        border-radius: var(--radius-lg);
        border: 1px solid var(--border-subtle);

        &__label {
          display: flex;
          align-items: center;
          gap: var(--space-1);
          font-size: var(--font-size-sm);
          font-weight: var(--font-weight-medium);
          color: var(--text-primary);
          flex: 1;
        }

        &__value {
          font-size: var(--font-size-sm);
          font-weight: var(--font-weight-semibold);
          color: var(--color-primary);
          font-variant-numeric: tabular-nums;
        }

        &__actions {
          display: flex;
          gap: var(--space-1);
        }
      }

      .icon-btn {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        width: 32px;
        height: 32px;
        border: none;
        border-radius: var(--radius-md);
        background: transparent;
        color: var(--text-secondary);
        cursor: pointer;
        transition: background-color var(--duration-fast) var(--easing-default),
          color var(--duration-fast) var(--easing-default);

        &:hover {
          background-color: var(--hover-bg);
          color: var(--text-primary);
        }

        &--danger:hover {
          background-color: var(--color-error-light, rgba(239, 68, 68, 0.1));
          color: var(--color-error, #ef4444);
        }
      }

      .add-btn {
        display: inline-flex;
        align-items: center;
        gap: var(--space-2);
        padding: var(--space-2) var(--space-4);
        border: 1px dashed var(--border-default);
        border-radius: var(--radius-lg);
        background: transparent;
        color: var(--text-secondary);
        font-size: var(--font-size-sm);
        cursor: pointer;
        transition: border-color var(--duration-fast) var(--easing-default),
          color var(--duration-fast) var(--easing-default);

        &:hover {
          border-color: var(--color-primary);
          color: var(--color-primary);
        }
      }

      .form-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: var(--space-4);
        margin-bottom: var(--space-4);
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
        background: var(--surface-raised);
        border: 1px solid var(--border-subtle);
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

        &--currency {
          width: 80px;
          flex-shrink: 0;
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
        color: var(--color-error, #ef4444);
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
        padding: var(--space-2) var(--space-4);
        border-radius: var(--radius-lg);
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
          background-color: var(--color-error, #ef4444);
          color: white;

          &:hover:not(:disabled) {
            opacity: 0.85;
          }
        }
      }

      .calculator {
        display: flex;
        flex-direction: column;
        gap: var(--space-3);

        &__row {
          display: flex;
          flex-direction: column;
          gap: var(--space-2);
        }

        &__input-group {
          display: flex;
          gap: var(--space-2);
          align-items: center;
        }

        &__equals {
          font-size: var(--font-size-xl);
          font-weight: var(--font-weight-bold);
          color: var(--text-secondary);
          text-align: center;
        }

        &__result {
          padding: var(--space-3) var(--space-4);
          background: var(--surface-raised);
          border-radius: var(--radius-lg);
          border: 1px solid var(--border-subtle);
          font-size: var(--font-size-sm);
          color: var(--text-primary);
          text-align: center;
        }
      }

      .currencies-list {
        display: flex;
        flex-direction: column;
        gap: var(--space-1);
        margin-bottom: var(--space-3);
      }

      .currency-item {
        display: flex;
        align-items: center;
        gap: var(--space-3);
        padding: var(--space-3);
        background: var(--surface-raised);
        border-radius: var(--radius-lg);
        border: 1px solid var(--border-subtle);
        cursor: grab;

        &__handle {
          color: var(--text-secondary);
          cursor: grab;
          display: flex;
          align-items: center;
        }

        &__symbol {
          font-weight: var(--font-weight-semibold);
          min-width: 40px;
          color: var(--text-primary);
        }

        &__name {
          flex: 1;
          font-size: var(--font-size-sm);
          color: var(--text-secondary);
        }

        &__badge {
          font-size: var(--font-size-xs);
          color: var(--color-primary);
          background: var(--color-primary-container, rgba(245, 158, 11, 0.12));
          padding: 2px 8px;
          border-radius: var(--radius-round, 9999px);
          font-weight: var(--font-weight-medium);
        }

        &__delete {
          width: 32px;
          height: 32px;
        }
      }

      .add-currency {
        display: flex;
        gap: var(--space-2);

        &__select {
          flex: 1;
        }
      }

      .dialog-overlay {
        position: fixed;
        inset: 0;
        background: rgba(0, 0, 0, 0.5);
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
        box-shadow: var(--shadow-xl, 0 20px 60px rgba(0, 0, 0, 0.3));

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
export class CurrencySettings implements OnInit {
  readonly rateService = inject(ExchangeRateService);
  private readonly prefService = inject(PreferenceService);
  private readonly accountService = inject(AccountService);

  readonly primaryCurrency = this.prefService.primaryCurrency;

  // Currencies state
  readonly currencies = signal<string[]>(['EUR']);
  readonly accounts = signal<Account[]>([]);
  readonly showRemoveWarning = signal(false);
  readonly currencyToRemove = signal<string | null>(null);

  readonly AVAILABLE_CURRENCIES = ['EUR', 'USD', 'XOF', 'GBP', 'CHF', 'CAD', 'MAD'];

  readonly CURRENCY_SYMBOLS: Record<string, string> = {
    EUR: '€', XOF: 'CFA', USD: '$', GBP: '£', CHF: 'CHF', CAD: 'CA$', MAD: 'MAD',
  };

  readonly CURRENCY_NAMES: Record<string, string> = {
    EUR: 'Euro', XOF: 'Franc CFA', USD: 'Dollar US', GBP: 'Livre sterling',
    CHF: 'Franc suisse', CAD: 'Dollar canadien', MAD: 'Dirham marocain',
  };

  readonly availableCurrenciesToAdd = computed(() => {
    const configured = this.currencies();
    return this.AVAILABLE_CURRENCIES.filter((c) => !configured.includes(c));
  });

  // Form state
  readonly showForm = signal(false);
  readonly editingRate = signal<ExchangeRate | null>(null);
  readonly formTargetCurrency = signal('');
  readonly formRate = signal<number | null>(null);
  readonly formError = signal<string | null>(null);
  readonly isSaving = signal(false);

  // Delete state
  readonly rateToDelete = signal<ExchangeRate | null>(null);
  readonly isDeleting = signal(false);

  // Calculator state
  readonly calcAmount1 = signal<number | null>(null);
  readonly calcAmount2 = signal<number | null>(null);
  readonly calcCurrency1 = signal('EUR');
  readonly calcCurrency2 = signal('USD');

  readonly calculatedRate = computed(() => {
    const a1 = this.calcAmount1();
    const a2 = this.calcAmount2();
    if (a1 && a2 && a1 > 0) {
      return a2 / a1;
    }
    return null;
  });

  readonly availableTargetCurrencies = computed(() => {
    const primary = this.primaryCurrency();
    const existingTargets = this.rateService
      .rates()
      .map((r) => r.targetCurrency);
    return ALL_CURRENCIES.filter(
      (c) => c !== primary && !existingTargets.includes(c),
    );
  });

  readonly allCurrencies = ALL_CURRENCIES;

  ngOnInit(): void {
    this.rateService.loadRates();
    this.currencies.set(this.prefService.currencies());
    this.accountService.getAll(true).subscribe({
      next: (accounts) => this.accounts.set(accounts),
    });
  }

  onDrop(event: CdkDragDrop<string[]>): void {
    const updated = [...this.currencies()];
    moveItemInArray(updated, event.previousIndex, event.currentIndex);
    this.currencies.set(updated);
    this.prefService.update({ currencies: updated });
  }

  addCurrency(currency: string): void {
    if (!currency) return;
    const updated = [...this.currencies(), currency];
    this.currencies.set(updated);
    this.prefService.update({ currencies: updated });
  }

  removeCurrency(currency: string): void {
    if (this.currencies().length <= 1) return;
    if (this.currencies()[0] === currency) return;

    const hasAccounts = this.accounts().some((a) => a.currency === currency && a.actif);
    if (hasAccounts) {
      this.currencyToRemove.set(currency);
      this.showRemoveWarning.set(true);
      return;
    }

    this.doRemoveCurrency(currency);
  }

  doRemoveCurrency(currency: string): void {
    const updated = this.currencies().filter((c) => c !== currency);
    this.currencies.set(updated);
    this.prefService.update({ currencies: updated });
    this.showRemoveWarning.set(false);
    this.currencyToRemove.set(null);
  }

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
      this.formError.set('Veuillez sélectionner une devise cible.');
      return;
    }
    if (!rate || rate <= 0) {
      this.formError.set('Veuillez saisir un taux valide (> 0).');
      return;
    }

    this.formError.set(null);
    this.isSaving.set(true);
    try {
      await firstValueFrom(
        this.rateService.upsert(this.primaryCurrency(), target, rate),
      );
      this.cancelForm();
    } catch {
      this.formError.set("Erreur lors de l'enregistrement du taux.");
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
    } catch {
      this.rateToDelete.set(null);
    } finally {
      this.isDeleting.set(false);
    }
  }
}
