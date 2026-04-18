import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostListener,
  OnDestroy,
  OnInit,
  ViewEncapsulation,
  computed,
  forwardRef,
  inject,
  input,
  output,
  signal,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { Subject, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged } from 'rxjs/operators';
import { expandCollapse } from '../../animations/expand-collapse';
import { normalize } from '../../utils/string.utils';

@Component({
  selector: 'app-autocomplete',
  standalone: true,
  templateUrl: './autocomplete.html',
  styleUrl: './autocomplete.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  // None : les styles BEM .autocomplete__* sont globalisés pour permettre
  // au contexte parent (ex: .bsheet__libelle input) de theme-r l'input interne.
  // Aucun risque de fuite : toutes les classes sont préfixées .autocomplete__*.
  encapsulation: ViewEncapsulation.None,
  animations: [expandCollapse],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => Autocomplete),
      multi: true,
    },
  ],
})
export class Autocomplete implements OnInit, OnDestroy, ControlValueAccessor {
  private readonly elementRef = inject(ElementRef);

  // --- Inputs ---
  readonly suggestions = input<string[]>([]);
  readonly minChars = input<number>(2);
  readonly maxDisplay = input<number>(5);
  readonly placeholder = input<string>('');
  readonly ariaLabel = input<string>('');

  // --- Outputs ---
  readonly selected = output<string>();
  readonly queryChange = output<string>();

  // --- État interne (signals, pilotés par CVA) ---
  readonly value = signal<string>('');
  readonly disabled = signal<boolean>(false);
  readonly isOpen = signal(false);
  readonly activeIndex = signal(-1);

  // eslint-disable-next-line @typescript-eslint/no-empty-function
  private onChange: (value: string) => void = () => {};
  // eslint-disable-next-line @typescript-eslint/no-empty-function
  private onTouched: () => void = () => {};

  readonly visibleSuggestions = computed(() => {
    const val = normalize(this.value());
    const all = this.suggestions();
    if (!val || val.length < this.minChars()) return all.slice(0, this.maxDisplay());
    return all
      .filter((s) => normalize(s).includes(val))
      .slice(0, this.maxDisplay());
  });

  // Identifiant unique pour ARIA (évite les conflits si plusieurs instances sur la page)
  readonly listboxId = `autocomplete-listbox-${Math.random().toString(36).slice(2)}`;

  readonly activeDescendant = computed(() => {
    const idx = this.activeIndex();
    if (idx < 0) return null;
    return `${this.listboxId}-option-${idx}`;
  });

  // --- Debounce ---
  private readonly inputSubject = new Subject<string>();
  private inputSubscription?: Subscription;

  ngOnInit(): void {
    this.inputSubscription = this.inputSubject
      .pipe(debounceTime(200), distinctUntilChanged())
      .subscribe((val) => {
        if (val.length >= this.minChars()) {
          this.queryChange.emit(val);
          this.isOpen.set(true);
        } else {
          this.isOpen.set(false);
        }
      });
  }

  ngOnDestroy(): void {
    this.inputSubscription?.unsubscribe();
    this.inputSubject.complete();
  }

  // --- ControlValueAccessor ---

  writeValue(value: string | null): void {
    this.value.set(value ?? '');
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

  // --- Gestionnaires ---

  onInput(event: Event): void {
    const val = (event.target as HTMLInputElement).value;
    this.value.set(val);
    this.onChange(val);
    this.activeIndex.set(-1);
    this.inputSubject.next(val);
    // Ferme immédiatement si en-dessous du seuil
    if (val.length < this.minChars()) {
      this.isOpen.set(false);
    }
  }

  onBlur(): void {
    this.onTouched();
  }

  onKeydown(event: KeyboardEvent): void {
    const suggestions = this.visibleSuggestions();
    const len = suggestions.length;

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        if (!this.isOpen() && len > 0) {
          this.isOpen.set(true);
        }
        if (len > 0) {
          this.activeIndex.update((i) => (i < len - 1 ? i + 1 : 0));
        }
        break;

      case 'ArrowUp':
        event.preventDefault();
        if (this.isOpen() && len > 0) {
          this.activeIndex.update((i) => (i > 0 ? i - 1 : len - 1));
        }
        break;

      case 'Enter':
        if (this.isOpen() && this.activeIndex() >= 0) {
          event.preventDefault();
          this.selectAt(this.activeIndex());
        }
        // Si aucune sélection active, on laisse l'event passer (submit du form)
        break;

      case 'Escape':
        // T-032 : ferme sans modifier value (FR-009)
        if (this.isOpen()) {
          event.preventDefault();
          this.close();
        }
        break;
    }
  }

  selectAt(index: number): void {
    const suggestions = this.visibleSuggestions();
    if (index < 0 || index >= suggestions.length) return;
    const chosen = suggestions[index];
    this.value.set(chosen);
    this.onChange(chosen);
    this.onTouched();
    this.selected.emit(chosen);
    this.close();
  }

  onSuggestionClick(index: number): void {
    this.selectAt(index);
  }

  onSuggestionMouseEnter(index: number): void {
    this.activeIndex.set(index);
  }

  close(): void {
    this.isOpen.set(false);
    this.activeIndex.set(-1);
  }

  @HostListener('document:click', ['$event'])
  onClickOutside(event: MouseEvent): void {
    if (!this.elementRef.nativeElement.contains(event.target)) {
      if (this.isOpen()) {
        this.close();
      }
    }
  }
}
