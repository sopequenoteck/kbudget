import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
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
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';

import { Account } from '../../../../core/models/account.model';
import {
  SUPPORTED_CURRENCIES,
  currencyNameKey,
  currencySymbol,
} from '../../../../core/models/currency.model';
import { LanguageService } from '../../../../core/services/language';
import { escapeHtml } from '../../../../shared/utils/html-escape.utils';

@Component({
  selector: 'app-currency-list',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, NgIcon, CdkDropList, CdkDrag, TranslocoPipe],
  viewProviders: [
    provideIcons({ phosphorDotsSixVertical, phosphorTrash, phosphorPlus }),
  ],
  template: `
    <!-- Section : Mes devises -->
    <div class="settings-section">
      <div class="settings-section__header">
        <span class="settings-section__title">{{ 'exchangeRates.page.currenciesTitle' | transloco }}</span>
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
              <span class="currency-item__symbol">{{ currencySymbol(currency) ?? currency }}</span>
              <span class="currency-item__name">{{ (currencyNameKey(currency) ?? currency) | transloco }}</span>
              @if (i === 0) {
                <span class="currency-item__badge">{{ 'exchangeRates.value.primary' | transloco }}</span>
              }
              @if (i > 0) {
                <button class="btn-action btn-action--danger" (click)="removeCurrency(currency)" [attr.aria-label]="'exchangeRates.action.removeCurrencyAria' | transloco">
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
      <!-- eslint-disable-next-line @angular-eslint/template/click-events-have-key-events,@angular-eslint/template/interactive-supports-focus -->
      <div class="dialog-overlay" (click)="showAddSheet.set(false)">
        <!-- eslint-disable-next-line @angular-eslint/template/click-events-have-key-events,@angular-eslint/template/interactive-supports-focus -->
        <div class="dialog" (click)="$event.stopPropagation()">
          <p class="dialog__title">{{ 'exchangeRates.dialog.addCurrencyTitle' | transloco }}</p>
          @for (c of availableCurrenciesToAdd(); track c) {
            <button class="dialog__option" (click)="addCurrency(c); showAddSheet.set(false)">
              <span class="dialog__option-symbol">{{ currencySymbol(c) ?? c }}</span>
              <span>{{ (currencyNameKey(c) ?? c) | transloco }}</span>
            </button>
          }
        </div>
      </div>
    }

    <!-- Warning : devise utilisée par des comptes -->
    @if (showRemoveWarning()) {
      <!-- eslint-disable-next-line @angular-eslint/template/click-events-have-key-events,@angular-eslint/template/interactive-supports-focus -->
      <div class="dialog-overlay" (click)="showRemoveWarning.set(false)">
        <!-- eslint-disable-next-line @angular-eslint/template/click-events-have-key-events,@angular-eslint/template/interactive-supports-focus -->
        <div class="dialog" (click)="$event.stopPropagation()">
          <p
            class="dialog__message"
            [innerHTML]="'exchangeRates.dialog.removeMessage' | transloco: removeMessageParams()!"
          ></p>
          <div class="dialog__actions">
            <button class="btn btn--ghost" (click)="showRemoveWarning.set(false)">{{ 'common.action.cancel' | transloco }}</button>
            <button class="btn btn--danger" (click)="doRemoveCurrency(currencyToRemove()!)">{{ 'exchangeRates.action.remove' | transloco }}</button>
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
        font-size: var(--font-size-2xs); color: var(--text-tertiary); background: transparent;
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

  private readonly transloco = inject(TranslocoService);
  private readonly languageService = inject(LanguageService);

  readonly currenciesChange = output<string[]>();

  readonly currencySymbol = currencySymbol;
  readonly currencyNameKey = currencyNameKey;
  readonly SUPPORTED_CURRENCIES = SUPPORTED_CURRENCIES;

  readonly showAddSheet = signal(false);
  readonly showRemoveWarning = signal(false);
  readonly currencyToRemove = signal<string | null>(null);

  readonly availableCurrenciesToAdd = computed(() => {
    const configured = new Set(this.currencies());
    return SUPPORTED_CURRENCIES.filter((c) => !configured.has(c));
  });

  /**
   * Parametres du dialogue de retrait, echappes avant interpolation dans le
   * `[innerHTML]` du template : a defaut d'un nom connu, `currency` retombe
   * sur le code brut fourni en entree — pas une liste fermee cote client.
   * Lit `activeLanguage()` avant de traduire pour se reevaluer au changement
   * de langue (precedent budget-list, KKS-379) : `translate()` seul n'est
   * pas un signal, `computed()` ne s'y abonnerait pas.
   */
  readonly removeMessageParams = computed(() => {
    const currency = this.currencyToRemove();
    if (!currency) return null;
    this.languageService.activeLanguage();
    const key = currencyNameKey(currency);
    const name = key ? this.transloco.translate(key) : currency;
    return { currency: escapeHtml(name) };
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
