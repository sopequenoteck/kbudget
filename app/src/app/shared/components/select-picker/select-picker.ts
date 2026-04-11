import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  ElementRef,
  forwardRef,
  HostListener,
  inject,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { CdkTrapFocus } from '@angular/cdk/a11y';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { SelectPickerItem } from './select-picker.model';

@Component({
  selector: 'app-select-picker',
  standalone: true,
  imports: [CdkTrapFocus],
  templateUrl: './select-picker.html',
  styleUrl: './select-picker.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => SelectPicker),
      multi: true,
    },
  ],
})
export class SelectPicker implements ControlValueAccessor {
  private readonly elementRef = inject(ElementRef);

  readonly items = input<SelectPickerItem[]>([]);
  readonly placeholder = input('Selectionner...');
  readonly searchable = input<boolean | null>(null);
  readonly searchThreshold = input(5);
  readonly searchPlaceholder = input('Rechercher...');
  readonly clearable = input(true);
  readonly emptyMessage = input('Aucun element disponible');

  readonly opened = output<void>();
  readonly closed = output<void>();
  readonly searchTermChange = output<string>();

  readonly isOpen = signal(false);
  readonly selectedId = signal('');
  readonly searchTerm = signal('');
  readonly disabled = signal(false);
  readonly highlightedIndex = signal(-1);
  readonly dropAbove = signal(false);

  private readonly triggerRef = viewChild<ElementRef<HTMLElement>>('trigger');
  private readonly searchInputRef = viewChild<ElementRef<HTMLInputElement>>('searchInput');

  // eslint-disable-next-line @typescript-eslint/no-empty-function
  private onChange: (value: string) => void = () => {};
  // eslint-disable-next-line @typescript-eslint/no-empty-function
  private onTouched: () => void = () => {};

  constructor() {
    effect(() => {
      const currentItems = this.items();
      const currentId = this.selectedId();
      if (currentId && !currentItems.some((item) => item.id === currentId)) {
        this.selectedId.set('');
        this.onChange('');
      }
    });
  }

  readonly selectedItem = computed(() => {
    const id = this.selectedId();
    if (!id) return null;
    return this.items().find((item) => item.id === id) ?? null;
  });

  readonly showSearch = computed(() => {
    const override = this.searchable();
    if (override !== null) return override;
    return this.items().length >= this.searchThreshold();
  });

  readonly filteredItems = computed(() => {
    const term = this.searchTerm().toLowerCase();
    if (!term) return this.items();
    return this.items().filter((item) => item.label.toLowerCase().includes(term));
  });

  writeValue(value: string): void {
    this.selectedId.set(value || '');
  }

  registerOnChange(fn: (value: string) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled.set(isDisabled);
  }

  toggle(): void {
    if (this.disabled()) return;
    if (this.isOpen()) {
      this.close();
    } else {
      this.open();
    }
  }

  open(): void {
    if (this.disabled() || this.isOpen()) return;
    this.updateDropPosition();
    this.isOpen.set(true);
    this.searchTerm.set('');
    this.highlightedIndex.set(-1);
    this.opened.emit();
    setTimeout(() => this.searchInputRef()?.nativeElement.focus());
  }

  close(): void {
    if (!this.isOpen()) return;
    this.isOpen.set(false);
    this.searchTerm.set('');
    this.highlightedIndex.set(-1);
    this.closed.emit();
    this.onTouched();
    this.triggerRef()?.nativeElement.focus();
  }

  selectItem(item: SelectPickerItem): void {
    this.selectedId.set(item.id);
    this.onChange(item.id);
    this.onTouched();
    this.close();
  }

  clearSelection(event: MouseEvent): void {
    event.stopPropagation();
    this.selectedId.set('');
    this.onChange('');
    this.onTouched();
  }

  onSearchInput(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.searchTerm.set(value);
    this.highlightedIndex.set(-1);
    this.searchTermChange.emit(value);
  }

  onKeydown(event: KeyboardEvent): void {
    switch (event.key) {
      case 'Enter':
      case ' ':
        if (!this.isOpen()) {
          event.preventDefault();
          this.open();
        } else if (event.key === 'Enter') {
          event.preventDefault();
          const filtered = this.filteredItems();
          const idx = this.highlightedIndex();
          if (idx >= 0 && idx < filtered.length) {
            this.selectItem(filtered[idx]);
          }
        }
        break;
      case 'ArrowDown':
        event.preventDefault();
        if (!this.isOpen()) {
          this.open();
        } else {
          const filtered = this.filteredItems();
          this.highlightedIndex.update((i) => (i < filtered.length - 1 ? i + 1 : 0));
        }
        break;
      case 'ArrowUp':
        event.preventDefault();
        if (this.isOpen()) {
          const filtered = this.filteredItems();
          this.highlightedIndex.update((i) => (i > 0 ? i - 1 : filtered.length - 1));
        }
        break;
      case 'Escape':
        if (this.isOpen()) {
          event.preventDefault();
          this.close();
        }
        break;
    }
  }

  @HostListener('document:click', ['$event'])
  onClickOutside(event: MouseEvent): void {
    if (!this.elementRef.nativeElement.contains(event.target)) {
      if (this.isOpen()) {
        this.close();
      }
    }
  }

  private updateDropPosition(): void {
    const trigger = this.triggerRef()?.nativeElement;
    if (!trigger) return;
    const rect = trigger.getBoundingClientRect();
    const spaceBelow = window.innerHeight - rect.bottom;
    this.dropAbove.set(spaceBelow < 224);
  }
}
