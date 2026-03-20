import {
  ChangeDetectionStrategy,
  Component,
  computed,
  input,
  output,
  signal,
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorDotsSixVertical,
  phosphorTrash,
  phosphorPlus,
} from '@ng-icons/phosphor-icons/regular';
import { CdkDropList, CdkDrag, CdkDragDrop, moveItemInArray } from '@angular/cdk/drag-drop';

import { Account } from '../../../../core/models/account.model';

const CURRENCY_SYMBOLS: Record<string, string> = {
  EUR: '€', XOF: 'CFA', USD: '$', GBP: '£', CHF: 'CHF', CAD: 'CA$', MAD: 'MAD',
};

const CURRENCY_NAMES: Record<string, string> = {
  EUR: 'Euro', XOF: 'Franc CFA', USD: 'Dollar US', GBP: 'Livre sterling',
  CHF: 'Franc suisse', CAD: 'Dollar canadien', MAD: 'Dirham marocain',
};

const AVAILABLE_CURRENCIES = ['EUR', 'USD', 'XOF', 'GBP', 'CHF', 'CAD', 'MAD'];

@Component({
  selector: 'app-currency-list',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, NgIcon, CdkDropList, CdkDrag],
  viewProviders: [
    provideIcons({ phosphorDotsSixVertical, phosphorTrash, phosphorPlus }),
  ],
  template: `
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
  `,
  styles: [
    `
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
export class CurrencyList {
  readonly currencies = input.required<string[]>();
  readonly accounts = input.required<Account[]>();

  readonly currenciesChange = output<string[]>();

  readonly CURRENCY_SYMBOLS = CURRENCY_SYMBOLS;
  readonly CURRENCY_NAMES = CURRENCY_NAMES;
  readonly AVAILABLE_CURRENCIES = AVAILABLE_CURRENCIES;

  readonly showRemoveWarning = signal(false);
  readonly currencyToRemove = signal<string | null>(null);

  readonly availableCurrenciesToAdd = computed(() => {
    const configured = this.currencies();
    return AVAILABLE_CURRENCIES.filter((c) => !configured.includes(c));
  });

  onDrop(event: CdkDragDrop<string[]>): void {
    const updated = [...this.currencies()];
    moveItemInArray(updated, event.previousIndex, event.currentIndex);
    this.currenciesChange.emit(updated);
  }

  addCurrency(currency: string): void {
    if (!currency) return;
    const updated = [...this.currencies(), currency];
    this.currenciesChange.emit(updated);
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
    this.currenciesChange.emit(updated);
    this.showRemoveWarning.set(false);
    this.currencyToRemove.set(null);
  }
}
