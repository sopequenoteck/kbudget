import { ChangeDetectionStrategy, Component, effect, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { FormsModule } from '@angular/forms';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import {
  phosphorUploadSimple,
  phosphorClockCounterClockwise,
  phosphorArrowCounterClockwise,
  phosphorTrash,
  phosphorFileCsv,
  phosphorFunnelSimple,
  phosphorPencilSimple,
  phosphorPlus,
  phosphorGitBranch,
  phosphorLockSimple,
} from '@ng-icons/phosphor-icons/regular';

import { ImportService } from '../../../../core/services/import';
import { CategoryService } from '../../../../core/services/category';
import { CategoryRuleService } from '../../../../core/services/category-rule';
import { DevLogger } from '../../../../core/services/dev-logger';
import { LanguageService } from '../../../../core/services/language';
import { Category } from '../../../../core/models/category.model';
import { CategoryNamePipe } from '../../../../shared/pipes/category-name.pipe';
import {
  CategoryRule,
  ImportDraftSummary,
  ImportHistoryEntry,
  ImportProfile,
  IMPORT_PROFILE_SOURCE_LABEL_KEYS,
} from '../../../../core/models/import.model';

@Component({
  selector: 'app-import-settings',
  standalone: true,
  imports: [RouterLink, NgIcon, FormsModule, CategoryNamePipe, TranslocoPipe],
  providers: [
    provideIcons({
      phosphorUploadSimple,
      phosphorClockCounterClockwise,
      phosphorArrowCounterClockwise,
      phosphorTrash,
      phosphorFileCsv,
      phosphorFunnelSimple,
      phosphorPencilSimple,
      phosphorPlus,
      phosphorGitBranch,
      phosphorLockSimple,
    }),
  ],
  templateUrl: './import-settings.html',
  styleUrl: './import-settings.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ImportSettings {
  private readonly importService = inject(ImportService);
  private readonly categoryService = inject(CategoryService);
  private readonly categoryRuleService = inject(CategoryRuleService);
  private readonly router = inject(Router);
  private readonly logger = inject(DevLogger);
  private readonly languageService = inject(LanguageService);
  private readonly transloco = inject(TranslocoService);

  readonly IMPORT_PROFILE_SOURCE_LABEL_KEYS = IMPORT_PROFILE_SOURCE_LABEL_KEYS;

  readonly drafts = signal<ImportDraftSummary[]>([]);
  readonly draftsLoading = signal(false);
  readonly history = signal<ImportHistoryEntry[]>([]);
  readonly historyLoading = signal(false);
  readonly deletingDraftId = signal<string | null>(null);

  readonly rules = signal<CategoryRule[]>([]);
  readonly categories = signal<Category[]>([]);

  // Profiles state
  readonly profiles = signal<ImportProfile[]>([]);
  readonly profilesLoading = signal(false);
  readonly deletingProfileId = signal<string | null>(null);

  // Rule form state
  readonly showRuleForm = signal(false);
  readonly editingRuleId = signal<string | null>(null);
  readonly ruleFormPattern = signal('');
  readonly ruleFormCategoryId = signal('');
  readonly ruleFormError = signal<string | null>(null);
  readonly ruleFormSaving = signal(false);

  constructor() {
    effect(() => {
      this.importService.refreshTrigger();
      this.loadDrafts();
      this.loadHistory();
      this.loadProfiles();
    });

    effect(() => {
      this.categoryRuleService.refreshTrigger();
      this.loadRules();
    });

    this.loadCategories();
  }

  private async loadDrafts(): Promise<void> {
    this.draftsLoading.set(true);
    try {
      const data = await firstValueFrom(this.importService.listDrafts());
      this.drafts.set(data);
    } catch (err) {
      this.logger.error('Failed to load drafts', err);
      this.drafts.set([]);
    } finally {
      this.draftsLoading.set(false);
    }
  }

  private async loadHistory(): Promise<void> {
    this.historyLoading.set(true);
    try {
      const response = await firstValueFrom(this.importService.listHistory(0, 20));
      this.history.set(response.content);
    } catch (err) {
      this.logger.error('Failed to load history', err);
      this.history.set([]);
    } finally {
      this.historyLoading.set(false);
    }
  }

  resumeDraft(draftId: string): void {
    this.router.navigate(['/transactions/import/review', draftId]);
  }

  async deleteDraft(draftId: string): Promise<void> {
    this.deletingDraftId.set(draftId);
    try {
      await firstValueFrom(this.importService.deleteDraft(draftId));
    } catch (err) {
      this.logger.error('Failed to delete draft', err);
    } finally {
      this.deletingDraftId.set(null);
    }
  }

  formatDate(dateStr: string): string {
    const d = new Date(dateStr);
    return d.toLocaleDateString(this.languageService.displayLocale(), { day: '2-digit', month: 'short', year: 'numeric' });
  }

  private async loadRules(): Promise<void> {
    try {
      const data = await firstValueFrom(this.categoryRuleService.getAll());
      this.rules.set(data);
    } catch (err) {
      this.logger.error('Failed to load rules', err);
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

  openAddRuleForm(): void {
    this.editingRuleId.set(null);
    this.ruleFormPattern.set('');
    this.ruleFormCategoryId.set('');
    this.ruleFormError.set(null);
    this.showRuleForm.set(true);
  }

  openEditRuleForm(rule: CategoryRule): void {
    this.editingRuleId.set(rule.id);
    this.ruleFormPattern.set(rule.pattern);
    this.ruleFormCategoryId.set(rule.categoryId);
    this.ruleFormError.set(null);
    this.showRuleForm.set(true);
  }

  cancelRuleForm(): void {
    this.showRuleForm.set(false);
    this.editingRuleId.set(null);
    this.ruleFormError.set(null);
  }

  async saveRule(): Promise<void> {
    const pattern = this.ruleFormPattern().trim();
    const categoryId = this.ruleFormCategoryId();

    if (!pattern) {
      this.ruleFormError.set(this.transloco.translate('imports.form.patternRequired'));
      return;
    }
    if (!categoryId) {
      this.ruleFormError.set(this.transloco.translate('imports.form.categoryRequired'));
      return;
    }

    this.ruleFormSaving.set(true);
    this.ruleFormError.set(null);

    try {
      const ruleId = this.editingRuleId();
      if (ruleId) {
        await firstValueFrom(this.categoryRuleService.update(ruleId, { pattern, categoryId }));
      } else {
        await firstValueFrom(this.categoryRuleService.create({ pattern, categoryId }));
      }
      this.showRuleForm.set(false);
      this.editingRuleId.set(null);
    } catch (err) {
      this.logger.error('Failed to save rule', err);
      this.ruleFormError.set(this.transloco.translate('imports.feedback.ruleSaveError'));
    } finally {
      this.ruleFormSaving.set(false);
    }
  }

  async deleteRule(ruleId: string): Promise<void> {
    try {
      await firstValueFrom(this.categoryRuleService.delete(ruleId));
    } catch (err) {
      this.logger.error('Failed to delete rule', err);
    }
  }

  private async loadProfiles(): Promise<void> {
    this.profilesLoading.set(true);
    try {
      const data = await firstValueFrom(this.importService.getProfiles());
      this.profiles.set(data);
    } catch (err) {
      this.logger.error('Failed to load profiles', err);
      this.profiles.set([]);
    } finally {
      this.profilesLoading.set(false);
    }
  }

  async deleteProfile(profileId: string): Promise<void> {
    this.deletingProfileId.set(profileId);
    try {
      await firstValueFrom(this.importService.deleteProfile(profileId));
    } catch (err) {
      this.logger.error('Failed to delete profile', err);
    } finally {
      this.deletingProfileId.set(null);
    }
  }
}
