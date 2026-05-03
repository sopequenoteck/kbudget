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

const PICKER_HEIGHT = 435;
const PICKER_SPACING = 8;

const EMOJI_LOCALE = 'fr';

const EMOJI_PICKER_THEME: Record<string, Record<string, string>> = {
  dark: {
    '--rgb-background': '31, 41, 55',
    '--rgb-color': '249, 250, 251',
    '--rgb-accent': '251, 191, 36',
    '--rgb-input': '17, 24, 39',
    '--color-border': 'rgba(255, 255, 255, 0.1)',
    '--color-border-over': 'rgba(255, 255, 255, 0.2)',
  },
  light: {
    '--rgb-background': '255, 255, 255',
    '--rgb-color': '17, 24, 39',
    '--rgb-accent': '245, 158, 11',
    '--rgb-input': '255, 255, 255',
    '--color-border': 'rgba(0, 0, 0, 0.08)',
    '--color-border-over': 'rgba(0, 0, 0, 0.15)',
  },
};

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
      const pickerHeight = PICKER_HEIGHT;
      const spaceBelow = window.innerHeight - rect.bottom - PICKER_SPACING;
      if (spaceBelow >= pickerHeight) {
        host.style.top = `${rect.bottom + PICKER_SPACING}px`;
      } else {
        host.style.top = `${rect.top - pickerHeight - PICKER_SPACING}px`;
      }
      host.style.left = `${rect.left}px`;
    }

    const pickerEl = new Picker({
      data,
      theme,
      locale: EMOJI_LOCALE,
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
    Object.entries(EMOJI_PICKER_THEME[theme]).forEach(([k, v]) => el.style.setProperty(k, v));
  }
}
