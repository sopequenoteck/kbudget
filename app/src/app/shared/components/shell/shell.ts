import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { NavigationEnd, Router, RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { filter } from 'rxjs';

import { AuthService } from '../../../core/services/auth';
import { Fab, type ModalType } from '../fab/fab';
import { Modal } from '../modal/modal';

const MODAL_TITLES: Record<ModalType, string> = {
  transaction: 'Nouvelle transaction',
  subscription: 'Nouvel abonnement',
  debt: 'Nouvelle dette',
};

@Component({
  selector: 'app-shell',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Fab, Modal],
  templateUrl: './shell.html',
  styleUrl: './shell.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Shell {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly navigationEnd = toSignal(
    this.router.events.pipe(filter((e) => e instanceof NavigationEnd)),
  );

  readonly userName = this.authService.currentUser;
  readonly sidebarOpen = signal(false);
  readonly speedDialOpen = signal(false);
  readonly activeModal = signal<ModalType | null>(null);
  readonly modalOpen = computed(() => this.activeModal() !== null);
  readonly modalTitle = computed(() => {
    const type = this.activeModal();
    return type ? MODAL_TITLES[type] : '';
  });

  constructor() {
    effect(() => {
      this.navigationEnd();
      this.speedDialOpen.set(false);
      this.activeModal.set(null);
    });
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

  onLogout(): void {
    this.authService.logout();
  }

  onFabToggle(): void {
    this.speedDialOpen.update((open) => !open);
  }

  onSpeedDialAction(type: ModalType): void {
    this.speedDialOpen.set(false);
    this.activeModal.set(type);
  }

  onModalClose(): void {
    this.activeModal.set(null);
  }
}
