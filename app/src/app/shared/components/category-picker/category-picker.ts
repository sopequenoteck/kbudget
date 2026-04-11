import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  forwardRef,
  inject,
  signal,
} from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ControlValueAccessor, FormsModule, NG_VALUE_ACCESSOR } from '@angular/forms';
import { CategoryService } from '../../../core/services/category';
import { Category } from '../../../core/models/category.model';
import { SelectPicker } from '../select-picker/select-picker';
import { SelectPickerItem } from '../select-picker/select-picker.model';
import { Modal } from '../modal/modal';
import { CategoryForm } from '../category-form/category-form';

@Component({
  selector: 'app-category-picker',
  standalone: true,
  imports: [FormsModule, SelectPicker, Modal, CategoryForm],
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

  private readonly refreshTrigger = this.categoryService.refreshTrigger;

  private readonly allCategories = toSignal(this.categoryService.getAll(), {
    initialValue: [] as Category[],
  });

  readonly categories = signal<Category[]>([]);
  readonly selectedCategoryId = signal<string>('');
  readonly disabled = signal(false);
  readonly showCreateModal = signal(false);
  readonly searchTerm = signal('');

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

  readonly categoryItems = computed<SelectPickerItem[]>(() =>
    this.categories().map((c) => ({
      id: c.id,
      label: c.nom,
      icon: c.icone,
      secondaryText: null,
      color: null,
    })),
  );

  readonly hasExactMatch = computed(() => {
    const term = this.searchTerm().toLowerCase();
    if (!term) return true;
    return this.categories().some((c) => c.nom.toLowerCase() === term);
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

  onPickerChange(value: string): void {
    this.selectedCategoryId.set(value);
    this.onChange(value);
    this.onTouched();
  }

  onSearchTermChange(term: string): void {
    this.searchTerm.set(term);
  }

  openCreateModal(): void {
    this.showCreateModal.set(true);
  }

  onCategorySaved(category: Category): void {
    this.showCreateModal.set(false);
    this.categories.update((cats) => [...cats, category]);
    this.selectedCategoryId.set(category.id);
    this.onChange(category.id);
    this.onTouched();
  }

  onCreateCancelled(): void {
    this.showCreateModal.set(false);
  }
}
