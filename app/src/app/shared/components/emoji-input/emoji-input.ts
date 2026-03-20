import {
  AfterViewChecked,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostListener,
  inject,
  input,
  output,
  signal,
} from '@angular/core';

@Component({
  selector: 'app-emoji-input',
  templateUrl: './emoji-input.html',
  styleUrl: './emoji-input.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: true,
})
export class EmojiInput implements AfterViewChecked {
  private readonly el = inject(ElementRef);

  readonly value = input('');
  readonly valueChange = output<string>();

  readonly isOpen = signal(false);

  private needsMount = false;
  private mounting = false;

  open(): void {
    if (this.isOpen()) return;
    this.needsMount = true;
    this.isOpen.set(true);
  }

  close(): void {
    this.isOpen.set(false);
    this.needsMount = false;
    this.mounting = false;
  }

  ngAfterViewChecked(): void {
    if (this.needsMount && !this.mounting) {
      const host: HTMLDivElement | null = this.el.nativeElement.querySelector('.picker-popover');
      if (host && host.children.length === 0) {
        this.mounting = true;
        this.needsMount = false;
        this.mountPicker(host);
      }
    }
  }

  @HostListener('document:keydown.escape')
  onEscape(): void {
    if (this.isOpen()) this.close();
  }

  onBackdropClick(event: MouseEvent): void {
    event.stopPropagation();
    this.close();
  }

  private async mountPicker(host: HTMLDivElement): Promise<void> {
    const [{ default: data }, { Picker }] = await Promise.all([
      import('@emoji-mart/data'),
      import('emoji-mart'),
    ]);

    if (!this.isOpen()) return;

    const theme = document.documentElement.classList.contains('theme-dark') ? 'dark' : 'light';

    // Position the popover in fixed coordinates relative to the trigger
    const trigger: HTMLElement | null = this.el.nativeElement.querySelector('.emoji-trigger');
    if (trigger) {
      const rect = trigger.getBoundingClientRect();
      const pickerHeight = 435; // emoji-mart default height
      const spaceBelow = window.innerHeight - rect.bottom - 8;
      if (spaceBelow >= pickerHeight) {
        host.style.top = `${rect.bottom + 8}px`;
      } else {
        host.style.top = `${rect.top - pickerHeight - 8}px`;
      }
      host.style.left = `${rect.left}px`;
    }

    const pickerEl = new Picker({
      data,
      theme,
      locale: 'fr',
      onEmojiSelect: (emoji: { native: string }) => {
        if (emoji.native) {
          this.valueChange.emit(emoji.native);
        }
        this.close();
      },
    });
    const el = pickerEl as unknown as HTMLElement;
    host.appendChild(el);

    // DS color tokens — CSS custom properties inherit through shadow DOM
    if (theme === 'dark') {
      el.style.setProperty('--rgb-background', '31, 41, 55'); // gray-800
      el.style.setProperty('--rgb-color', '249, 250, 251'); // gray-50
      el.style.setProperty('--rgb-accent', '251, 191, 36'); // amber-400
      el.style.setProperty('--rgb-input', '17, 24, 39'); // gray-900
      el.style.setProperty('--color-border', 'rgba(255, 255, 255, 0.1)');
      el.style.setProperty('--color-border-over', 'rgba(255, 255, 255, 0.2)');
    } else {
      el.style.setProperty('--rgb-background', '255, 255, 255');
      el.style.setProperty('--rgb-color', '17, 24, 39'); // gray-900
      el.style.setProperty('--rgb-accent', '245, 158, 11'); // amber-500
      el.style.setProperty('--rgb-input', '255, 255, 255');
      el.style.setProperty('--color-border', 'rgba(0, 0, 0, 0.08)');
      el.style.setProperty('--color-border-over', 'rgba(0, 0, 0, 0.15)');
    }
  }
}
