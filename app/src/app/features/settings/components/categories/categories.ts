import {
  ChangeDetectionStrategy,
  Component,
  computed,
  effect,
  inject,
  isDevMode,
  signal,
} from '@angular/core';
import { RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { phosphorCaretLeft, phosphorPencilSimple, phosphorPlus, phosphorTag, phosphorTrash, phosphorWarning } from '@ng-icons/phosphor-icons/regular';

import { CategoryService } from '../../../../core/services/category';
import { ModalService } from '../../../../core/services/modal.service';
import { Category } from '../../../../core/models/category.model';
import { EmptyState } from '../../../../shared/components/empty-state/empty-state';

@Component({
  selector: 'app-categories',
  imports: [RouterLink, NgIcon, EmptyState],
  providers: [
    provideIcons({
      phosphorCaretLeft,
      phosphorPencilSimple,
      phosphorPlus,
      phosphorTag,
      phosphorTrash,
      phosphorWarning,
    }),
  ],
  templateUrl: './categories.html',
  styleUrl: './categories.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Categories {
  private readonly categoryService = inject(CategoryService);
  private readonly modalService = inject(ModalService);

  readonly skeletonItems = Array(3);

  readonly categories = signal<Category[]>([]);
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly confirmDeleteId = signal<string | null>(null);

  readonly userCategories = computed(() => this.categories().filter((c) => !c.isSystem));

  constructor() {
    effect(() => {
      this.categoryService.refreshTrigger();
      this.loadCategories();
    });
  }

  async loadCategories(): Promise<void> {
    this.loading.set(true);
    this.error.set(false);

    try {
      const data = await firstValueFrom(this.categoryService.getAll());
      this.categories.set(data);
      this.loading.set(false);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to load categories', err);
      }
      this.error.set(true);
      this.loading.set(false);
    }
  }

  createCategory(): void {
    this.modalService.openModal('category');
  }

  editCategory(category: Category): void {
    this.modalService.openModal('category', category);
  }

  requestDelete(categoryId: string): void {
    this.confirmDeleteId.set(categoryId);
  }

  cancelDelete(): void {
    this.confirmDeleteId.set(null);
  }

  async confirmDelete(): Promise<void> {
    const id = this.confirmDeleteId();
    if (!id) return;

    try {
      await firstValueFrom(this.categoryService.delete(id));
      this.confirmDeleteId.set(null);
    } catch (err) {
      if (isDevMode()) {
        console.error('Failed to delete category', err);
      }
    }
  }
}
