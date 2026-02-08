import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  effect,
  input,
  output,
  viewChild,
  viewChildren,
} from '@angular/core';

export type ModalType = 'transaction' | 'subscription' | 'debt';

export interface SpeedDialItem {
  readonly type: ModalType;
  readonly label: string;
  readonly icon: string;
}

export const SPEED_DIAL_ACTIONS: readonly SpeedDialItem[] = [
  { type: 'transaction', label: 'Transaction', icon: '💰' },
  { type: 'subscription', label: 'Abonnement', icon: '🔄' },
  { type: 'debt', label: 'Dette', icon: '🤝' },
] as const;

@Component({
  selector: 'app-fab',
  imports: [],
  templateUrl: './fab.html',
  styleUrl: './fab.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Fab {
  readonly isOpen = input.required<boolean>();
  readonly isHidden = input<boolean>(false);
  readonly toggled = output<void>();
  readonly actionSelected = output<ModalType>();

  readonly fabButton = viewChild<ElementRef<HTMLButtonElement>>('fabButton');
  readonly menuItems = viewChildren<ElementRef<HTMLButtonElement>>('menuItem');

  readonly actions = SPEED_DIAL_ACTIONS;
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
