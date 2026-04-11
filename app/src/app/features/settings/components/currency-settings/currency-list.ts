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
      <div class="settings-section__header">
        <span class="settings-section__title">Mes devises</span>
        @if (availableCurrenciesToAdd().length > 0) {
          <button class="add-btn" (click)="showAddSheet.set(true)">
            <ng-icon name="phosphorPlus" size="16" />
          </button>
        }
      </div>
      <div class="section-content">
        <div class="currencies-list" cdkDropList (cdkDropListDropped)="onDrop($event)">
          @for (currency of currencies(); track currency; let i = $index) {
            <div class="currency-item" cdkDrag>
              <div class="currency-item__handle" cdkDragHandle>
                <ng-icon name="phosphorDotsSixVertical" size="18" />
              </div>
              <span class="currency-item__symbol">{{ CURRENCY_SYMBOLS[currency] || currency }}</span>
              <span class="currency-item__name">{{ CURRENCY_NAMES[currency] || currency }}</span>
              @if (i === 0) {
                <span class="currency-item__badge">Principale</span>
              }
              @if (i > 0) {
                <button class="btn-action btn-action--danger" (click)="removeCurrency(currency)" aria-label="Supprimer cette devise">
                  <ng-icon name="phosphorTrash" size="16" />
                </button>
              }
            </div>
          }
        </div>
      </div>
    </div>

    <!-- Sélection devise -->
    @if (showAddSheet()) {
      <div class="dialog-overlay" (click)="showAddSheet.set(false)">
        <div class="dialog" (click)="$event.stopPropagation()">
          <p class="dialog__title">Ajouter une devise</p>
          @for (c of availableCurrenciesToAdd(); track c) {
            <button class="dialog__option" (click)="addCurrency(c); showAddSheet.set(false)">
              <span class="dialog__option-symbol">{{ CURRENCY_SYMBOLS[c] }}</span>
              <span>{{ CURRENCY_NAMES[c] }}</span>
            </button>
          }
        </div>
      </div>
    }

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
  styles: [`
    .settings-section__header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 var(--space-4);
      margin-bottom: var(--space-2);
    }

    .settings-section__title {
      font-size: var(--font-size-xs);
      font-weight: var(--font-weight-semibold);
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--text-tertiary);
    }

    .add-btn {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 28px;
      height: 28px;
      padding: 0;
      border: 1px solid var(--border-default);
      border-radius: var(--radius-round);
      background: transparent;
      color: var(--text-tertiary);
      cursor: pointer;
      &:active { color: var(--text-primary); background-color: var(--hover-bg); }
    }

    .section-content {
      background: var(--surface-default);
      border-radius: var(--radius-xl);
      overflow: hidden;
    }

    .currencies-list { display: flex; flex-direction: column; }

    .currency-item {
      display: flex;
      align-items: center;
      gap: var(--space-3);
      padding: var(--space-3) var(--space-4);
      border-bottom: 1px solid var(--border-default);

      &__handle { color: var(--text-tertiary); cursor: grab; display: flex; align-items: center; }
      &__symbol { font-weight: var(--font-weight-semibold); min-width: 40px; color: var(--text-secondary); font-size: var(--font-size-sm); }
      &__name { flex: 1; font-size: var(--font-size-sm); color: var(--text-tertiary); }
      &__badge {
        font-size: 10px; color: var(--text-tertiary); background: transparent;
        border: 1px solid var(--border-default); padding: var(--space-1) var(--space-2);
        border-radius: var(--radius-round); font-weight: var(--font-weight-medium);
      }
    }

    .btn-action {
      display: inline-flex; align-items: center; justify-content: center;
      width: 32px; height: 32px; border: none; border-radius: var(--radius-round);
      background: transparent; color: var(--text-tertiary); cursor: pointer;

      &--danger { color: var(--color-expense); }
      &:active { background-color: var(--hover-bg); }
    }

    .btn {
      display: inline-flex; align-items: center; gap: var(--space-1-5);
      padding: var(--space-1) var(--space-3); border-radius: var(--radius-round);
      font-size: var(--font-size-xs); font-weight: var(--font-weight-medium);
      font-family: inherit; cursor: pointer; border: none;

      &--ghost { background: transparent; border: 1px solid var(--border-default); color: var(--text-secondary); }
      &--danger { background-color: var(--color-expense); color: white; }
    }

    .dialog-overlay {
      position: fixed; inset: 0; background: var(--surface-overlay);
      display: flex; align-items: center; justify-content: center; z-index: 1000; padding: var(--space-4);
    }
    .dialog {
      background: var(--surface-default); border-radius: var(--radius-xl);
      padding: var(--space-5); max-width: 400px; width: 100%;

      &__title {
        font-size: var(--font-size-sm); font-weight: var(--font-weight-semibold);
        color: var(--text-primary); margin-bottom: var(--space-3);
      }
      &__message { font-size: var(--font-size-sm); color: var(--text-secondary); margin-bottom: var(--space-4); line-height: 1.5; }
      &__actions { display: flex; justify-content: flex-end; gap: var(--space-2); }
      &__option {
        display: flex; align-items: center; gap: var(--space-3);
        width: 100%; padding: var(--space-3) 0; border: none; border-bottom: 1px solid var(--border-default);
        background: transparent; color: var(--text-secondary); font-size: var(--font-size-sm);
        font-family: inherit; cursor: pointer; text-align: left;
        &:last-child { border-bottom: none; }
        &:active { color: var(--text-primary); }
      }
      &__option-symbol {
        font-weight: var(--font-weight-semibold); min-width: 40px; color: var(--text-tertiary);
      }
    }

    .cdk-drag-preview {
      display: flex; align-items: center; gap: var(--space-3);
      padding: var(--space-3) var(--space-4); background-color: var(--surface-raised);
      border-radius: var(--radius-lg); box-shadow: var(--shadow-lg); font-size: var(--font-size-sm);
    }
    .cdk-drag-placeholder { opacity: 0.3; }
  `],
})
export class CurrencyList {
  readonly currencies = input.required<string[]>();
  readonly accounts = input.required<Account[]>();

  readonly currenciesChange = output<string[]>();

  readonly CURRENCY_SYMBOLS = CURRENCY_SYMBOLS;
  readonly CURRENCY_NAMES = CURRENCY_NAMES;
  readonly AVAILABLE_CURRENCIES = AVAILABLE_CURRENCIES;

  readonly showAddSheet = signal(false);
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
