import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  ElementRef,
  HostListener,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router, RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { trigger, transition, style, animate, query } from '@angular/animations';
import { filter } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorGear,
  phosphorSignOut,
  phosphorHouse,
  phosphorCurrencyDollar,
  phosphorArrowsClockwise,
  phosphorHandshake,
  phosphorChartPie,
} from '@ng-icons/phosphor-icons/regular';
import {
  phosphorArrowsClockwiseFill,
  phosphorHandshakeFill,
  phosphorHouseFill,
  phosphorCurrencyDollarFill,
  phosphorChartPieFill,
} from '@ng-icons/phosphor-icons/fill';

import { AuthService } from '../../../core/services/auth';
import { PreferenceService } from '../../../core/services/preference';
import { NotificationService } from '../../../core/services/notification';
import { StompService } from '../../../core/services/stomp';
import { NotificationBadge } from '../notification-badge/notification-badge';
import { NotificationPanel } from '../notification-panel/notification-panel';
import { FEATURES, type Feature } from '../../../core/models/preference.model';
import { ThemeService } from '../../../core/services/theme';
import { ModalService, type ModalType } from '../../../core/services/modal.service';
import { type Transaction, TransactionType } from '../../../core/models/transaction.model';
import { Frequency, type Subscription } from '../../../core/models/subscription.model';
import { DebtType, type Debt } from '../../../core/models/debt.model';
import { TransactionForm } from '../../../features/transactions/components/transaction-form/transaction-form';
import { SubscriptionForm } from '../../../features/subscriptions/components/subscription-form/subscription-form';
import { DebtForm } from '../../../features/debts/components/debt-form/debt-form';
import { CategoryForm } from '../category-form/category-form';
import { AccountForm } from '../account-form/account-form';
import { TransferForm } from '../transfer-form/transfer-form';
import { BudgetForm } from '../../../features/budgets/components/budget-form/budget-form';
import { RepayDialog } from '../../../features/debts/components/repay-dialog/repay-dialog';
import { BottomNav } from '../bottom-nav/bottom-nav';
import { Fab } from '../fab/fab';
import { Modal } from '../modal/modal';
import { Toast } from '../toast/toast';
import { ConfirmDialog } from '../confirm-dialog/confirm-dialog';

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [
    RouterOutlet,
    RouterLink,
    RouterLinkActive,
    NgIcon,
    BottomNav,
    Fab,
    Modal,
    TransactionForm,
    SubscriptionForm,
    DebtForm,
    CategoryForm,
    AccountForm,
    TransferForm,
    BudgetForm,
    RepayDialog,
    NotificationBadge,
    NotificationPanel,
    Toast,
    ConfirmDialog,
  ],
  providers: [
    provideIcons({
      phosphorGear,
      phosphorSignOut,
      phosphorHouse,
      phosphorHouseFill,
      phosphorCurrencyDollar,
      phosphorCurrencyDollarFill,
      phosphorArrowsClockwise,
      phosphorArrowsClockwiseFill,
      phosphorHandshake,
      phosphorHandshakeFill,
      phosphorChartPie,
      phosphorChartPieFill,
    }),
  ],
  animations: [
    trigger('routeAnimation', [
      transition('* <=> *', [
        query(':enter', [style({ opacity: 0 })], { optional: true }),
        query(':leave', [animate('100ms ease-out', style({ opacity: 0 }))], { optional: true }),
        query(':enter', [animate('100ms ease-in', style({ opacity: 1 }))], { optional: true }),
      ]),
    ]),
  ],
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Shell {
  private readonly outlet = viewChild(RouterOutlet);
  readonly categoryFormRef = viewChild<CategoryForm>('categoryFormRef');
  readonly categoryFormSubmitting = computed(() => this.categoryFormRef()?.submitting() ?? false);
  readonly categoryFormIsEditMode = computed(() => this.categoryFormRef()?.isEditMode ?? false);
  private readonly authService = inject(AuthService);
  private readonly preferenceService = inject(PreferenceService);
  private readonly notificationService = inject(NotificationService);
  private readonly stompService = inject(StompService);
  private readonly themeService = inject(ThemeService);
  private readonly router = inject(Router);
  private readonly elementRef = inject(ElementRef);
  readonly modalService = inject(ModalService);
  private readonly navigationEnd = toSignal(
    this.router.events.pipe(filter((e) => e instanceof NavigationEnd)),
  );

  readonly userName = this.authService.currentUser;
  readonly sidebarOpen = signal(false);
  readonly dropdownOpen = signal(false);
  readonly userInitials = computed(() => {
    const user = this.userName();
    if (!user?.name) return '?';
    return user.name
      .split(' ')
      .map((part) => part[0])
      .join('')
      .toUpperCase()
      .slice(0, 2);
  });
  readonly speedDialOpen = signal(false);
  readonly notificationPanelOpen = signal(false);
  readonly transactionType = signal(TransactionType.DEPENSE);
  readonly TransactionType = TransactionType;
  readonly subscriptionFrequency = signal(Frequency.MENSUEL);
  readonly Frequency = Frequency;
  readonly debtType = signal(DebtType.EMPRUNT);
  readonly DebtType = DebtType;
  readonly navItems = computed(() => {
    const fixed = [
      { label: 'Accueil', route: '/dashboard', icon: 'phosphorHouse', filledIcon: 'phosphorHouseFill' },
      { label: 'Transactions', route: '/transactions', icon: 'phosphorCurrencyDollar', filledIcon: 'phosphorCurrencyDollarFill' },
    ];
    const navOrder = this.preferenceService.navOrder();
    const enabled = this.preferenceService.enabledFeatures();
    const optional = navOrder
      .filter((f: Feature) => enabled.includes(f))
      .map((f: Feature) => {
        const meta = FEATURES.find((m) => m.value === f)!;
        return { label: meta.label, route: meta.route, icon: meta.icon, filledIcon: meta.filledIcon };
      });
    return [...fixed, ...optional];
  });
  readonly currentRoute = computed(() => {
    const e = this.navigationEnd();
    return e instanceof NavigationEnd ? e.urlAfterRedirects : this.router.url;
  });
  readonly isOnSettingsRoute = computed(() => this.currentRoute().startsWith('/settings'));

  constructor() {
    effect(() => {
      this.navigationEnd();
      this.speedDialOpen.set(false);
      this.dropdownOpen.set(false);
      this.modalService.resetModal();
    });

    // Sync type toggles when editing existing entities
    effect(() => {
      const modal = this.modalService.activeModal();
      if (modal === 'transaction') {
        const entity = this.modalService.editingEntity() as Transaction | null;
        this.transactionType.set(entity?.type ?? TransactionType.DEPENSE);
      }
    });

    effect(() => {
      const modal = this.modalService.activeModal();
      if (modal === 'subscription') {
        const entity = this.modalService.editingEntity() as Subscription | null;
        this.subscriptionFrequency.set(entity?.frequence ?? Frequency.MENSUEL);
      }
    });

    effect(() => {
      const modal = this.modalService.activeModal();
      if (modal === 'debt') {
        const entity = this.modalService.editingEntity() as Debt | null;
        this.debtType.set(entity?.sens ?? DebtType.EMPRUNT);
      }
    });

    // Load user preferences after authentication
    effect(() => {
      if (this.authService.isAuthenticated()) {
        this.preferenceService.loadPreferences();
      }
    });

    effect(() => {
      if (this.authService.isAuthenticated()) {
        this.notificationService.loadUnreadCount();
        this.stompService.connect();
      } else {
        this.stompService.disconnect();
      }
    });

    // Redirect if current route is a disabled feature
    effect(() => {
      const items = this.navItems();
      const nav = this.navigationEnd();
      if (nav instanceof NavigationEnd) {
        const url = nav.urlAfterRedirects;
        const validRoutes = items.map((i) => i.route);
        const isSettings = url.startsWith('/settings');
        const isDashboard = url === '/dashboard' || url === '/';
        const isKnownRoute = validRoutes.some((r) => url.startsWith(r));
        if (!isSettings && !isDashboard && !isKnownRoute && this.preferenceService.isLoaded()) {
          this.router.navigate(['/dashboard']);
        }
      }
    });
  }

  toggleNotificationPanel(): void {
    const wasOpen = this.notificationPanelOpen();
    this.notificationPanelOpen.set(!wasOpen);
    if (!wasOpen) {
      this.notificationService.loadNotifications();
    }
  }

  closeNotificationPanel(): void {
    this.notificationPanelOpen.set(false);
  }

  toggleSidebar(): void {
    this.sidebarOpen.update((open) => !open);
  }

  closeSidebar(): void {
    this.sidebarOpen.set(false);
  }

  onNavClick(): void {
    this.closeSidebar();
  }

  toggleDropdown(): void {
    this.dropdownOpen.update((open) => !open);
  }

  closeDropdown(): void {
    this.dropdownOpen.set(false);
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const menuEl = this.elementRef.nativeElement.querySelector('.shell-user-menu');
    if (menuEl && !menuEl.contains(event.target as Node)) {
      this.closeDropdown();
    }
  }

  @HostListener('document:keydown.escape')
  onEscapeKey(): void {
    this.closeDropdown();
  }

  getRouteAnimationData(): string | undefined {
    return this.outlet()?.activatedRouteData?.['animation'];
  }

  onLogout(): void {
    this.closeDropdown();
    this.authService.logout();
  }

  onTransactionTypeChange(type: TransactionType): void {
    this.transactionType.set(type);
  }

  onFrequencyChange(freq: Frequency): void {
    this.subscriptionFrequency.set(freq);
  }

  onFabToggle(): void {
    this.speedDialOpen.update((open) => !open);
  }

  onSpeedDialAction(type: ModalType): void {
    this.speedDialOpen.set(false);
    this.modalService.openModal(type);
  }

  onModalClose(): void {
    this.modalService.closeModal();
  }

  triggerCategorySubmit(): void {
    this.categoryFormRef()?.submit();
  }
}
