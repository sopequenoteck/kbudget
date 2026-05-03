import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  signal,
} from '@angular/core';
import { Router, RouterLink, ActivatedRoute } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import {
  phosphorArrowUp,
  phosphorArrowDown,
  phosphorCheckCircle,
  phosphorWarningCircle,
  phosphorMinusCircle,
  phosphorXCircle,
  phosphorTrash,
} from '@ng-icons/phosphor-icons/regular';

import { ImportService } from '../../../../core/services/import';
import { CategoryService } from '../../../../core/services/category';
import { CategoryRuleService } from '../../../../core/services/category-rule';
import { DevLogger } from '../../../../core/services/dev-logger';
import { APP_LOCALE } from '../../../../core/constants/locale.constants';
import { AmountPipe } from '../../../../shared/pipes/amount.pipe';
import { ImportDraft, ImportDraftLine, ImportLineUpdate } from '../../../../core/models/import.model';
import { Category } from '../../../../core/models/category.model';

interface SuggestRuleBanner {
  lineId: string;
  cleanLabel: string;
  categoryId: string;
  categoryName: string;
}

@Component({
  selector: 'app-import-review',
  standalone: true,
  imports: [RouterLink, NgIcon, AmountPipe, FormsModule],
  providers: [
    provideIcons({
      phosphorArrowUp,
      phosphorArrowDown,
      phosphorCheckCircle,
      phosphorWarningCircle,
      phosphorMinusCircle,
      phosphorXCircle,
      phosphorTrash,
    }),
  ],
  templateUrl: './import-review.html',
  styleUrl: './import-review.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ImportReview {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly importService = inject(ImportService);
  private readonly categoryService = inject(CategoryService);
  private readonly categoryRuleService = inject(CategoryRuleService);
  private readonly logger = inject(DevLogger);

  readonly draft = signal<ImportDraft | null>(null);
  readonly categories = signal<Category[]>([]);
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly confirming = signal(false);
  readonly confirmError = signal<string | null>(null);
  readonly confirmSuccess = signal(false);
  readonly deleteConfirm = signal(false);
  readonly suggestRuleBanner = signal<SuggestRuleBanner | null>(null);

  readonly selectedLineIds = signal<Set<string>>(new Set());
  readonly batchCategoryId = signal<string>('');
  readonly batchLoading = signal(false);

  readonly hasSelection = computed(() => this.selectedLineIds().size > 0);
  readonly allSelected = computed(() => {
    const d = this.draft();
    if (!d || d.lines.length === 0) return false;
    const sel = this.selectedLineIds();
    return d.lines.every((l) => sel.has(l.id));
  });

  constructor() {
    const draftId = this.route.snapshot.paramMap.get('draftId');
    if (draftId) {
      this.loadDraft(draftId);
      this.loadCategories();
    }
  }

  private async loadDraft(draftId: string): Promise<void> {
    this.loading.set(true);
    this.error.set(false);
    try {
      const data = await firstValueFrom(this.importService.getDraft(draftId));
      this.draft.set(data);
      this.loading.set(false);
    } catch (err) {
      this.logger.error('Failed to load draft', err);
      this.error.set(true);
      this.loading.set(false);
    }
  }

  private async loadCategories(): Promise<void> {
    try {
      const data = await firstValueFrom(this.categoryService.getAll());
      this.categories.set(data);
    } catch (err) {
      this.logger.error('Failed to load categories', err);
    }
  }

  canConfirm(): boolean {
    const d = this.draft();
    if (!d) return false;
    return d.reviewCount === 0 && d.duplicateCount === 0;
  }

  private async updateDraftAfterLineChange(
    lineId: string,
    update: ImportLineUpdate,
  ): Promise<ImportDraftLine | null> {
    const d = this.draft();
    if (!d) return null;
    const updated = await firstValueFrom(this.importService.updateLine(d.id, lineId, update));
    this.draft.update((current) => {
      if (!current) return current;
      const lines = current.lines.map((l) => (l.id === updated.id ? updated : l));
      return {
        ...current,
        lines,
        readyCount: lines.filter((l) => l.status === 'READY').length,
        reviewCount: lines.filter((l) => l.status === 'NEEDS_REVIEW').length,
        duplicateCount: lines.filter((l) => l.status === 'DUPLICATE').length,
        skippedCount: lines.filter((l) => l.status === 'SKIPPED').length,
      };
    });
    return updated;
  }

  async onCategoryChange(line: ImportDraftLine, categoryId: string): Promise<void> {
    try {
      const updated = await this.updateDraftAfterLineChange(line.id, {
        categoryId: categoryId || undefined,
        status: categoryId ? 'READY' : 'NEEDS_REVIEW',
      });
      if (updated?.suggestRule && categoryId && updated.cleanLabel) {
        const cat = this.categories().find((c) => c.id === categoryId);
        this.suggestRuleBanner.set({
          lineId: updated.id,
          cleanLabel: updated.cleanLabel,
          categoryId,
          categoryName: cat?.nom ?? '',
        });
      }
    } catch (err) {
      this.logger.error('Failed to update line', err);
    }
  }

  dismissSuggestRule(): void {
    this.suggestRuleBanner.set(null);
  }

  async acceptSuggestRule(): Promise<void> {
    const banner = this.suggestRuleBanner();
    if (!banner) return;
    try {
      await firstValueFrom(
        this.categoryRuleService.create({
          pattern: banner.cleanLabel,
          categoryId: banner.categoryId,
        }),
      );
    } catch (err) {
      this.logger.error('Failed to create rule', err);
    } finally {
      this.suggestRuleBanner.set(null);
    }
  }

  async onForceImportLine(line: ImportDraftLine): Promise<void> {
    try {
      await this.updateDraftAfterLineChange(line.id, { status: 'READY' });
    } catch (err) {
      this.logger.error('Failed to force import line', err);
    }
  }

  async onSkipLine(line: ImportDraftLine): Promise<void> {
    try {
      await this.updateDraftAfterLineChange(line.id, { status: 'SKIPPED' });
    } catch (err) {
      this.logger.error('Failed to skip line', err);
    }
  }

  async confirmImport(): Promise<void> {
    const d = this.draft();
    if (!d || !this.canConfirm() || this.confirming()) return;

    this.confirming.set(true);
    this.confirmError.set(null);
    try {
      await firstValueFrom(this.importService.confirm(d.id));
      this.confirmSuccess.set(true);
      setTimeout(() => {
        this.router.navigate(['/settings/import']);
      }, 500);
    } catch (err) {
      this.logger.error('Failed to confirm import', err);
      this.confirmError.set("Erreur lors de la confirmation de l'import.");
      this.confirming.set(false);
    }
  }

  requestDelete(): void {
    this.deleteConfirm.set(true);
  }

  cancelDelete(): void {
    this.deleteConfirm.set(false);
  }

  async confirmDelete(): Promise<void> {
    const d = this.draft();
    if (!d) return;
    try {
      await firstValueFrom(this.importService.deleteDraft(d.id));
      this.router.navigate(['/settings/import']);
    } catch (err) {
      this.logger.error('Failed to delete draft', err);
    }
  }

  toggleLineSelection(lineId: string): void {
    this.selectedLineIds.update((sel) => {
      const next = new Set(sel);
      if (next.has(lineId)) {
        next.delete(lineId);
      } else {
        next.add(lineId);
      }
      return next;
    });
  }

  toggleSelectAll(): void {
    const d = this.draft();
    if (!d) return;
    if (this.allSelected()) {
      this.selectedLineIds.set(new Set());
    } else {
      this.selectedLineIds.set(new Set(d.lines.map((l) => l.id)));
    }
  }

  clearSelection(): void {
    this.selectedLineIds.set(new Set());
    this.batchCategoryId.set('');
  }

  private applyBatchResult(updatedLines: ImportDraftLine[]): void {
    const updatedMap = new Map(updatedLines.map((l) => [l.id, l]));
    this.draft.update((d) => {
      if (!d) return d;
      const lines = d.lines.map((l) => updatedMap.get(l.id) ?? l);
      return {
        ...d,
        lines,
        readyCount: lines.filter((l) => l.status === 'READY').length,
        reviewCount: lines.filter((l) => l.status === 'NEEDS_REVIEW').length,
        duplicateCount: lines.filter((l) => l.status === 'DUPLICATE').length,
        skippedCount: lines.filter((l) => l.status === 'SKIPPED').length,
      };
    });
    this.clearSelection();
  }

  async onBatchAssignCategory(): Promise<void> {
    const d = this.draft();
    const catId = this.batchCategoryId();
    if (!d || !catId || this.selectedLineIds().size === 0) return;
    this.batchLoading.set(true);
    try {
      const updated = await firstValueFrom(
        this.importService.batchUpdateLines(d.id, {
          lineIds: Array.from(this.selectedLineIds()),
          categoryId: catId,
          status: 'READY',
        }),
      );
      this.applyBatchResult(updated);
    } catch (err) {
      this.logger.error('Failed to batch assign category', err);
    } finally {
      this.batchLoading.set(false);
    }
  }

  async onBatchSkip(): Promise<void> {
    const d = this.draft();
    if (!d || this.selectedLineIds().size === 0) return;
    this.batchLoading.set(true);
    try {
      const updated = await firstValueFrom(
        this.importService.batchUpdateLines(d.id, {
          lineIds: Array.from(this.selectedLineIds()),
          status: 'SKIPPED',
        }),
      );
      this.applyBatchResult(updated);
    } catch (err) {
      this.logger.error('Failed to batch skip lines', err);
    } finally {
      this.batchLoading.set(false);
    }
  }

  async onBatchValidate(): Promise<void> {
    const d = this.draft();
    if (!d || this.selectedLineIds().size === 0) return;
    this.batchLoading.set(true);
    try {
      const updated = await firstValueFrom(
        this.importService.batchUpdateLines(d.id, {
          lineIds: Array.from(this.selectedLineIds()),
          status: 'READY',
        }),
      );
      this.applyBatchResult(updated);
    } catch (err) {
      this.logger.error('Failed to batch validate lines', err);
    } finally {
      this.batchLoading.set(false);
    }
  }

  statusIcon(status: string): string {
    switch (status) {
      case 'READY':
        return 'phosphorCheckCircle';
      case 'NEEDS_REVIEW':
        return 'phosphorWarningCircle';
      case 'DUPLICATE':
        return 'phosphorMinusCircle';
      case 'SKIPPED':
        return 'phosphorXCircle';
      default:
        return 'phosphorCheckCircle';
    }
  }

  statusLabel(status: string): string {
    switch (status) {
      case 'READY':
        return 'Prête';
      case 'NEEDS_REVIEW':
        return 'À vérifier';
      case 'DUPLICATE':
        return 'Doublon';
      case 'SKIPPED':
        return 'Ignorée';
      default:
        return status;
    }
  }

  formatDate(dateStr: string): string {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    return d.toLocaleDateString(APP_LOCALE, { day: '2-digit', month: '2-digit', year: 'numeric' });
  }
}
