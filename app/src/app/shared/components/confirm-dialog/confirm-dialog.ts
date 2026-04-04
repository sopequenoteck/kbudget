import {
  ChangeDetectionStrategy,
  Component,
  effect,
  HostListener,
  inject,
} from '@angular/core';
import { CdkTrapFocus } from '@angular/cdk/a11y';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorReceipt,
  phosphorRepeat,
  phosphorHandCoins,
  phosphorChartPie,
  phosphorPackage,
  phosphorShoppingBag,
  phosphorTrash,
  phosphorX,
  phosphorCheck,
} from '@ng-icons/phosphor-icons/regular';

import { ConfirmService } from '../../../core/services/confirm.service';

@Component({
  selector: 'app-confirm-dialog',
  imports: [CdkTrapFocus, NgIcon],
  templateUrl: './confirm-dialog.html',
  styleUrl: './confirm-dialog.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    provideIcons({
      phosphorReceipt,
      phosphorRepeat,
      phosphorHandCoins,
      phosphorChartPie,
      phosphorPackage,
      phosphorShoppingBag,
      phosphorTrash,
      phosphorX,
      phosphorCheck,
    }),
  ],
})
export class ConfirmDialog {
  readonly confirmService = inject(ConfirmService);

  private previouslyFocusedElement: HTMLElement | null = null;

  constructor() {
    effect(() => {
      if (this.confirmService.isOpen()) {
        this.previouslyFocusedElement = document.activeElement as HTMLElement;
        document.body.style.overflow = 'hidden';
      } else {
        document.body.style.overflow = '';
        this.previouslyFocusedElement?.focus();
        this.previouslyFocusedElement = null;
      }
    });
  }

  @HostListener('document:keydown.escape')
  onEscape(): void {
    if (this.confirmService.isOpen()) {
      this.confirmService.resolve(false);
    }
  }

  onOverlayClick(): void {
    this.confirmService.resolve(false);
  }

  onCancel(): void {
    this.confirmService.resolve(false);
  }

  onConfirm(): void {
    this.confirmService.resolve(true);
  }
}
