import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  forwardRef,
  inject,
  input,
  OnDestroy,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';

import { CategoryForm } from '../category-form/category-form';
import { Category } from '../../../core/models/category.model';
import { LanguageService } from '../../../core/services/language';
import { normalize } from '../../utils/string.utils';
import { categoryDisplayName } from '../../utils/category-name.utils';
import { CategoryNamePipe } from '../../pipes/category-name.pipe';

@Component({
  selector: 'app-category-select',
  standalone: true,
  imports: [CategoryForm, CategoryNamePipe, TranslocoPipe],
  templateUrl: './category-select.html',
  styleUrl: './category-select.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => CategorySelect),
      multi: true,
    },
  ],
})
export class CategorySelect implements ControlValueAccessor, OnDestroy {
  private readonly transloco = inject(TranslocoService);
  private readonly languageService = inject(LanguageService);

  // --- Inputs ---
  readonly categories = input<Category[]>([]);

  // --- Outputs ---
  readonly selected = output<string>();
  readonly created = output<Category>();
  readonly isCreating = output<boolean>();

  // --- ViewChild ---
  readonly categoryForm = viewChild<CategoryForm>('formRef');

  // --- État interne (CVA) ---
  readonly value = signal<string>('');
  readonly disabled = signal(false);

  // eslint-disable-next-line @typescript-eslint/no-empty-function
  private onChange: (value: string) => void = () => {};
  // eslint-disable-next-line @typescript-eslint/no-empty-function
  private onTouched: () => void = () => {};

  // --- État UI ---
  readonly mode = signal<'list' | 'create'>('list');
  readonly searchTerm = signal('');
  readonly activeIndex = signal(-1);
  readonly listboxId = `category-select-listbox-${Math.random().toString(36).slice(2)}`;

  // --- Computed ---
  // Traduit sur le nom affiche (KKS-395) : une categorie systeme se recherche
  // et se compare sur sa traduction, jamais sur son `nom` brut cote serveur.
  private readonly displayNameOf = computed(() => {
    const lang = this.languageService.activeLanguage();
    return (c: Category) => categoryDisplayName(c.nom, c.systemKey, this.transloco, lang);
  });

  readonly filteredCategories = computed(() => {
    const q = normalize(this.searchTerm());
    if (!q) return this.categories();
    const nameOf = this.displayNameOf();
    return this.categories().filter((c) => normalize(nameOf(c)).includes(q));
  });

  readonly hasExactMatch = computed(() => {
    const q = normalize(this.searchTerm());
    if (!q) return true;
    const nameOf = this.displayNameOf();
    return this.categories().some((c) => normalize(nameOf(c)) === q);
  });

  readonly showCreateButton = computed(
    () => this.searchTerm().length > 0 && !this.hasExactMatch(),
  );

  readonly selectedCategory = computed(
    () => this.categories().find((c) => c.id === this.value()) ?? null,
  );

  readonly activeDescendantId = computed(() => {
    const i = this.activeIndex();
    return i >= 0 ? `${this.listboxId}-option-${i}` : null;
  });

  constructor() {
    effect(() => this.isCreating.emit(this.mode() === 'create'));
  }

  ngOnDestroy(): void {
    if (this.mode() === 'create') {
      this.mode.set('list');
    }
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

  // --- Méthodes internes ---

  selectCategory(cat: Category): void {
    this.value.set(cat.id);
    this.selected.emit(cat.id);
    this.onChange(cat.id);
    this.onTouched();
    this.searchTerm.set('');
    this.activeIndex.set(-1);
  }

  onSearchInput(event: Event): void {
    const val = (event.target as HTMLInputElement).value;
    this.searchTerm.set(val);
    this.activeIndex.set(-1);
  }

  onKeydown(event: KeyboardEvent): void {
    if (this.mode() === 'create') {
      if (event.key === 'Escape') {
        event.preventDefault();
        this.popToList();
      }
      return;
    }

    const items = this.filteredCategories();
    const len = items.length;

    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault();
        this.activeIndex.update((i) => (i < len - 1 ? i + 1 : 0));
        break;

      case 'ArrowUp':
        event.preventDefault();
        this.activeIndex.update((i) => (i > 0 ? i - 1 : len - 1));
        break;

      case 'Enter':
        if (this.activeIndex() >= 0) {
          event.preventDefault();
          const cat = items[this.activeIndex()];
          if (cat) this.selectCategory(cat);
        }
        break;

      case 'Escape':
        this.searchTerm.set('');
        this.activeIndex.set(-1);
        break;
    }
  }

  pushToCreate(): void {
    this.mode.set('create');
  }

  popToList(): void {
    this.mode.set('list');
    // searchTerm conservé (FR-009)
  }

  submitCategoryForm(): void {
    this.categoryForm()?.submit();
  }

  onCategoryCreated(cat: Category): void {
    this.value.set(cat.id);
    this.onChange(cat.id);
    this.onTouched();
    this.created.emit(cat);
    this.selected.emit(cat.id);
    this.searchTerm.set('');
    this.activeIndex.set(-1);
    this.mode.set('list');
  }
}
