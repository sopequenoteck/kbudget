import { ChangeDetectionStrategy, Component, effect, inject, signal } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { FormsModule } from '@angular/forms';
import { NgIcon, provideIcons } from '@ng-icons/core';
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

import { AccountService } from '../../../../core/services/account';
import { ImportService } from '../../../../core/services/import';
import { CategoryService } from '../../../../core/services/category';
import { CategoryRuleService } from '../../../../core/services/category-rule';
import { DevLogger } from '../../../../core/services/dev-logger';
import { ApiErrorService } from '../../../../core/services/api-error';
import { APP_LOCALE } from '../../../../core/constants/locale.constants';
import { Account } from '../../../../core/models/account.model';
import { Category } from '../../../../core/models/category.model';
import {
  CategoryRule,
  ImportDraftSummary,
  ImportHistoryEntry,
  ImportProfile,
} from '../../../../core/models/import.model';

@Component({
  selector: 'app-import-settings',
  standalone: true,
  imports: [RouterLink, NgIcon, FormsModule],
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
  private readonly accountService = inject(AccountService);
  private readonly importService = inject(ImportService);
  private readonly categoryService = inject(CategoryService);
  private readonly categoryRuleService = inject(CategoryRuleService);
  private readonly apiError = inject(ApiErrorService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly logger = inject(DevLogger);

  private readonly queryParams = toSignal(this.route.queryParamMap);

  readonly accounts = signal<Account[]>([]);
  readonly selectedAccountId = signal<string>('');
  readonly uploading = signal(false);
  readonly uploadError = signal<string | null>(null);

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
      this.accountService.refreshTrigger();
      this.loadAccounts();
    });

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

    effect(() => {
      const params = this.queryParams();
      if (params) {
        const accountId = params.get('accountId');
        if (accountId) this.selectedAccountId.set(accountId);
      }
    });
  }

  private async loadAccounts(): Promise<void> {
    try {
      const data = await firstValueFrom(this.accountService.getAll(false));
      this.accounts.set(data);
      if (data.length > 0 && !this.selectedAccountId()) {
        const defaultAcc = data.find((a) => a.isDefault) ?? data[0];
        this.selectedAccountId.set(defaultAcc.id);
      }
    } catch (err) {
      this.logger.error('Failed to load accounts', err);
    }
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

  onAccountChange(accountId: string): void {
    this.selectedAccountId.set(accountId);
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (file) {
      this.uploadFile(file);
    }
    input.value = '';
  }

  triggerFileInput(): void {
    const input = document.getElementById('csv-file-input') as HTMLInputElement;
    input?.click();
  }

  resumeDraft(draftId: string): void {
    this.router.navigate(['/settings/import/review', draftId]);
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
    return d.toLocaleDateString(APP_LOCALE, { day: '2-digit', month: 'short', year: 'numeric' });
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
      this.ruleFormError.set('Le pattern est requis.');
      return;
    }
    if (!categoryId) {
      this.ruleFormError.set('La catégorie est requise.');
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
      this.ruleFormError.set('Erreur lors de la sauvegarde de la règle.');
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

  private async uploadFile(file: File): Promise<void> {
    const accountId = this.selectedAccountId();
    if (!accountId) {
      this.uploadError.set('Veuillez sélectionner un compte.');
      return;
    }

    this.uploading.set(true);
    this.uploadError.set(null);

    try {
      const draft = await firstValueFrom(this.importService.upload(file, accountId));
      this.router.navigate(['/settings/import/review', draft.id]);
    } catch (err: unknown) {
      this.logger.error('Failed to upload CSV', err);
      const httpErr = err as { status?: number; error?: { message?: string } };
      if (httpErr?.status === 409) {
        this.uploadError.set(
          "Un brouillon d'import existe déjà pour ce compte. Supprimez-le avant d'en créer un nouveau.",
        );
        this.uploading.set(false);
      } else if (httpErr?.status === 422) {
        // Format not recognized — navigate to manual mapping
        this.router.navigate(['/settings/import/mapping'], {
          state: { file, accountId },
        });
        // don't reset uploading — navigation is in progress
      } else {
        this.uploadError.set(
          this.apiError.label(httpErr, "Erreur lors de l'import. Veuillez réessayer."),
        );
        this.uploading.set(false);
      }
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
