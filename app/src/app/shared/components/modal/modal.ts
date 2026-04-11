import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  effect,
  inject,
  input,
  output,
  viewChild,
} from '@angular/core';
import { CdkTrapFocus } from '@angular/cdk/a11y';
import { ModalService } from '../../../core/services/modal.service';

@Component({
  selector: 'app-modal',
  standalone: true,
  imports: [CdkTrapFocus],
  templateUrl: './modal.html',
  styleUrl: './modal.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Modal {
  readonly isOpen = input.required<boolean>();
  readonly title = input.required<string>();
  readonly hideHeader = input<boolean>(false);
  readonly closed = output<void>();

  readonly closeBtn = viewChild<ElementRef<HTMLButtonElement>>('closeBtn');
  readonly modalService = inject(ModalService);

  private previouslyFocusedElement: HTMLElement | null = null;

  constructor() {
    effect(() => {
      if (this.isOpen()) {
        this.previouslyFocusedElement = document.activeElement as HTMLElement;
        document.body.style.overflow = 'hidden';
      } else {
        document.body.style.overflow = '';
        this.previouslyFocusedElement?.focus();
        this.previouslyFocusedElement = null;
      }
    });
  }

  onOverlayClick(): void {
    this.closed.emit();
  }

  onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      event.preventDefault();
      this.closed.emit();
    }
  }
}
