import {
  ChangeDetectionStrategy,
  Component,
  computed,
  ElementRef,
  effect,
  inject,
  input,
  output,
  viewChild,
  viewChildren,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorPlusBold,
  phosphorCurrencyDollarBold,
  phosphorArrowsClockwiseBold,
  phosphorHandshakeBold,
  phosphorArrowsLeftRightBold,
  phosphorPackageBold,
  phosphorTagBold,
  phosphorChartPieBold,
} from '@ng-icons/phosphor-icons/bold';

import { type ModalType } from '../../../core/services/modal.service';
import { AccountService } from '../../../core/services/account';
import { Account } from '../../../core/models/account.model';
import { PreferenceService } from '../../../core/services/preference';

export interface SpeedDialItem {
  readonly type: ModalType;
  readonly label: string;
  readonly icon: string;
}

const BASE_ACTIONS: readonly SpeedDialItem[] = [
  { type: 'transaction', label: 'Transaction', icon: 'phosphorCurrencyDollarBold' },
  { type: 'subscription', label: 'Abonnement', icon: 'phosphorArrowsClockwiseBold' },
  { type: 'debt', label: 'Dette', icon: 'phosphorHandshakeBold' },
] as const;

const TRANSFER_ACTION: SpeedDialItem = { type: 'transfer', label: 'Virement', icon: 'phosphorArrowsLeftRightBold' };
const PRODUCT_ACTION: SpeedDialItem = { type: 'product', label: 'Nouveau produit', icon: 'phosphorPackageBold' };
const SELL_ACTION: SpeedDialItem = { type: 'sell', label: 'Vente rapide', icon: 'phosphorTagBold' };
const BUDGET_ACTION: SpeedDialItem = { type: 'budget', label: 'Nouveau budget', icon: 'phosphorChartPieBold' };

@Component({
  selector: 'app-fab',
  standalone: true,
  imports: [NgIcon],
  providers: [
    provideIcons({
      phosphorPlusBold,
      phosphorCurrencyDollarBold,
      phosphorArrowsClockwiseBold,
      phosphorHandshakeBold,
      phosphorArrowsLeftRightBold,
      phosphorPackageBold,
      phosphorTagBold,
      phosphorChartPieBold,
    }),
  ],
  templateUrl: './fab.html',
  styleUrl: './fab.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Fab {
  private readonly accountService = inject(AccountService);
  private readonly preferenceService = inject(PreferenceService);

  readonly isOpen = input.required<boolean>();
  readonly isHidden = input<boolean>(false);
  readonly currentRoute = input<string>('');
  readonly toggled = output<void>();
  readonly actionSelected = output<ModalType>();

  readonly fabButton = viewChild<ElementRef<HTMLButtonElement>>('fabButton');
  readonly menuItems = viewChildren<ElementRef<HTMLButtonElement>>('menuItem');

  private readonly allAccounts = toSignal(this.accountService.getAll(), {
    initialValue: [] as Account[],
  });

  readonly hasEnoughAccounts = computed(
    () => this.allAccounts().filter((a) => a.actif).length >= 2,
  );

  readonly isOnDashboardRoute = computed(
    () => this.currentRoute() === '/dashboard' || this.currentRoute() === '/',
  );
  readonly isOnBudgetsRoute = computed(() => this.currentRoute().startsWith('/budgets'));
  readonly isOnShopRoute = computed(() => this.currentRoute().startsWith('/shop'));

  readonly actions = computed<SpeedDialItem[]>(() => {
    if (this.isOnBudgetsRoute() && this.preferenceService.isEnabled('BUDGETS')) {
      return [BUDGET_ACTION];
    }
    if (this.isOnShopRoute() && this.preferenceService.isEnabled('SHOP')) {
      return [PRODUCT_ACTION, SELL_ACTION];
    }

    const base = BASE_ACTIONS.filter((action) => {
      if (action.type === 'subscription') return this.preferenceService.isEnabled('SUBSCRIPTIONS');
      if (action.type === 'debt') return this.preferenceService.isEnabled('DEBTS');
      return true;
    });
    const result = [...base];
    if (this.isOnDashboardRoute() && this.hasEnoughAccounts()) {
      result.push(TRANSFER_ACTION);
    }
    return result;
  });
  private animating = false;

  constructor() {
    effect(() => {
      if (this.isOpen()) {
        const items = this.menuItems();
        if (items.length > 0) {
          items[0].nativeElement.focus();
        }
      } else {
        this.fabButton()?.nativeElement.focus();
      }
    });
  }

  onToggle(): void {
    if (this.animating) return;
    this.animating = true;
    setTimeout(() => (this.animating = false), 200);
    this.toggled.emit();
  }

  onAction(type: ModalType): void {
    this.actionSelected.emit(type);
  }

  onMenuKeydown(event: KeyboardEvent): void {
    const items = this.menuItems();
    if (items.length === 0) return;

    const currentIndex = items.findIndex((item) => item.nativeElement === document.activeElement);

    switch (event.key) {
      case 'ArrowUp': {
        event.preventDefault();
        const prevIndex = currentIndex > 0 ? currentIndex - 1 : items.length - 1;
        items[prevIndex].nativeElement.focus();
        break;
      }
      case 'ArrowDown': {
        event.preventDefault();
        const nextIndex = currentIndex < items.length - 1 ? currentIndex + 1 : 0;
        items[nextIndex].nativeElement.focus();
        break;
      }
      case 'Escape':
        event.preventDefault();
        this.toggled.emit();
        break;
    }
  }
}
