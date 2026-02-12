import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  ElementRef,
  forwardRef,
  HostListener,
  inject,
  signal,
  viewChild,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { CategoryService } from '../../../core/services/category';
import { Category } from '../../../core/models/category.model';
import { Modal } from '../modal/modal';
import { CategoryForm } from '../category-form/category-form';

@Component({
  selector: 'app-category-picker',
  imports: [Modal, CategoryForm],
  templateUrl: './category-picker.html',
  styleUrl: './category-picker.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => CategoryPicker),
      multi: true,
    },
  ],
})
export class CategoryPicker implements ControlValueAccessor {
  private readonly categoryService = inject(CategoryService);
  private readonly elementRef = inject(ElementRef);

  readonly inputRef = viewChild<ElementRef<HTMLInputElement>>('searchInput');

  private readonly refreshTrigger = this.categoryService.refreshTrigger;

  private readonly allCategories = toSignal(this.categoryService.getAll(), {
    initialValue: [] as Category[],
  });

  readonly categories = signal<Category[]>([]);
  readonly searchTerm = signal('');
  readonly isOpen = signal(false);
  readonly highlightedIndex = signal(-1);
  readonly selectedCategoryId = signal<string>('');
  readonly disabled = signal(false);
  readonly showCreateModal = signal(false);

  // eslint-disable-next-line @typescript-eslint/no-empty-function
  private onChange: (value: string) => void = () => {};
  // eslint-disable-next-line @typescript-eslint/no-empty-function
  private onTouched: () => void = () => {};

  constructor() {
    effect(() => {
      this.refreshTrigger();
      const cats = this.allCategories();
      this.categories.set(cats);
    });
  }

  readonly selectedCategory = computed(() => {
    const id = this.selectedCategoryId();
    if (!id) return null;
    return this.categories().find((c) => c.id === id) ?? null;
  });

  readonly filteredCategories = computed(() => {
    const term = this.searchTerm().toLowerCase();
    if (!term) return this.categories();
    return this.categories().filter((c) =>
      c.nom.toLowerCase().includes(term),
    );
  });

  readonly hasExactMatch = computed(() => {
    const term = this.searchTerm().toLowerCase();
    if (!term) return true;
    return this.categories().some(
      (c) => c.nom.toLowerCase() === term,
    );
  });

  writeValue(value: string): void {
    this.selectedCategoryId.set(value || '');
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

  onFocus(): void {
    this.isOpen.set(true);
    this.searchTerm.set('');
    this.highlightedIndex.set(-1);
  }

  onInput(event: Event): void {
    const value = (event.target as HTMLInputElement).value;
    this.searchTerm.set(value);
    this.isOpen.set(true);
    this.highlightedIndex.set(-1);
  }

  selectCategory(category: Category): void {
    this.selectedCategoryId.set(category.id);
    this.onChange(category.id);
    this.onTouched();
    this.isOpen.set(false);
    this.searchTerm.set('');
  }

  clearSelection(): void {
    this.selectedCategoryId.set('');
    this.onChange('');
    this.onTouched();
  }

  openCreateModal(): void {
    this.showCreateModal.set(true);
    this.isOpen.set(false);
  }

  onCategorySaved(category: Category): void {
    this.showCreateModal.set(false);
    this.categories.update((cats) => [...cats, category]);
    this.selectCategory(category);
  }

  onCreateCancelled(): void {
    this.showCreateModal.set(false);
  }

  onKeydown(event: KeyboardEvent): void {
    const filtered = this.filteredCategories();

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        this.highlightedIndex.update((i) =>
          i < filtered.length - 1 ? i + 1 : 0,
        );
        break;
      case 'ArrowUp':
        event.preventDefault();
        this.highlightedIndex.update((i) =>
          i > 0 ? i - 1 : filtered.length - 1,
        );
        break;
      case 'Enter':
        event.preventDefault();
        if (this.highlightedIndex() >= 0 && this.highlightedIndex() < filtered.length) {
          this.selectCategory(filtered[this.highlightedIndex()]);
        }
        break;
      case 'Escape':
        this.isOpen.set(false);
        this.searchTerm.set('');
        break;
    }
  }

  @HostListener('document:click', ['$event'])
  onClickOutside(event: MouseEvent): void {
    if (!this.elementRef.nativeElement.contains(event.target)) {
      this.isOpen.set(false);
      this.searchTerm.set('');
    }
  }
}
