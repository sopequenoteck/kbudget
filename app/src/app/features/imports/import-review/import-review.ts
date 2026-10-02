import { NgTemplateOutlet } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { firstValueFrom } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import {
  phosphorArrowLeft,
  phosphorCaretDown,
  phosphorCheckCircle,
  phosphorLinkSimple,
  phosphorReceipt,
  phosphorSealCheck,
  phosphorTag,
  phosphorWarningCircle,
} from '@ng-icons/phosphor-icons/regular';

import { AccountService } from '../../../core/services/account';
import { ApiErrorService } from '../../../core/services/api-error';
import { CategoryService } from '../../../core/services/category';
import { DevLogger } from '../../../core/services/dev-logger';
import { ImportService } from '../../../core/services/import';
import { LanguageService } from '../../../core/services/language';
import { Account } from '../../../core/models/account.model';
import { Category } from '../../../core/models/category.model';
import {
  ImportConfirmResult,
  ImportDraft,
  ImportDraftLine,
  ImportLineUpdate,
} from '../../../core/models/import.model';
import { CategorySelect } from '../../../shared/components/category-select/category-select';
import { EmptyState } from '../../../shared/components/empty-state/empty-state';
import { Modal } from '../../../shared/components/modal/modal';
import { ToastService } from '../../../shared/components/toast/toast.service';
import { AmountPipe } from '../../../shared/pipes/amount.pipe';
import { CategoryNamePipe } from '../../../shared/pipes/category-name.pipe';
import {
  formatDayMonthLabel,
  formatFullDateLabel,
  insertSortedByNom,
} from '../../../shared/utils/locale-format.utils';
import { ImportResult } from '../import-result/import-result';
import { classifyLines, isRestorable, UncategorisedGroup } from './import-review.utils';

/** Groupes repliables de la revue, tous replies a l'ouverture. */
export type ReviewGroupId = 'matched' | 'auto' | 'user' | 'imported' | 'skipped';

/** Ce que la feuille de categorie va corriger : une ligne, ou un groupe de commercant (une ligne suffit, l'API propage). */
interface CategoryTarget {
  lineId: string;
  title: string;
}

/**
 * Revue d'un brouillon d'import (KKS-386) : le corps ne montre que les
 * exceptions — lignes a trancher, illisibles, sans categorie regroupees par
 * commercant. Tout ce que l'import a deja decide reste dans des groupes
 * repliables, chacun corrigible.
 */
@Component({
  selector: 'app-import-review',
  standalone: true,
  imports: [
    NgIcon,
    AmountPipe,
    CategoryNamePipe,
    CategorySelect,
    EmptyState,
    ImportResult,
    Modal,
    NgTemplateOutlet,
    TranslocoPipe,
  ],
  providers: [
    provideIcons({
      phosphorArrowLeft,
      phosphorCaretDown,
      phosphorCheckCircle,
      phosphorLinkSimple,
      phosphorReceipt,
      phosphorSealCheck,
      phosphorTag,
      phosphorWarningCircle,
    }),
  ],
  templateUrl: './import-review.html',
  styleUrl: './import-review.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ImportReview implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly importService = inject(ImportService);
  private readonly categoryService = inject(CategoryService);
  private readonly accountService = inject(AccountService);
  private readonly languageService = inject(LanguageService);
  private readonly apiError = inject(ApiErrorService);
  private readonly toast = inject(ToastService);
  private readonly logger = inject(DevLogger);
  private readonly transloco = inject(TranslocoService);

  readonly draft = signal<ImportDraft | null>(null);
  readonly loading = signal(true);
  readonly loadFailed = signal(false);
  readonly categories = signal<Category[]>([]);
  readonly accounts = signal<Account[]>([]);
  /** Une action est en cours : toutes les autres sont desactivees le temps de l'aller-retour. */
  readonly busy = signal(false);
  readonly confirming = signal(false);
  readonly result = signal<ImportConfirmResult | null>(null);
  /** Premier import seulement : aligner le solde d'ouverture sur celui de la banque, actif par defaut. */
  readonly alignOpeningBalance = signal(true);
  readonly expandedGroups = signal<ReadonlySet<ReviewGroupId>>(new Set());
  readonly categoryTarget = signal<CategoryTarget | null>(null);
  readonly categoryCreating = signal(false);

  private readonly draftId = this.route.snapshot.paramMap.get('draftId');

  readonly model = computed(() => classifyLines(this.draft()?.lines ?? []));

  readonly account = computed(() => {
    const accountId = this.draft()?.accountId;
    return this.accounts().find((a) => a.id === accountId) ?? null;
  });
  readonly currency = computed(() => this.account()?.currency ?? 'EUR');
  readonly accountSuffix = computed(
    () => this.draft()?.statementAccountSuffix ?? this.account()?.statementAccountSuffix ?? null,
  );

  readonly categoryById = computed(() => new Map(this.categories().map((c) => [c.id, c])));

  /** Lignes qui bloquent la confirmation : a trancher et illisibles. */
  readonly toDecideCount = computed(
    () => this.model().toDecide.length + this.model().probableDuplicates.length,
  );
  readonly unreadableCount = computed(() => this.model().unreadable.length);
  readonly blockingCount = computed(() => this.toDecideCount() + this.unreadableCount());

  /** Variante de la phrase qui dit ce qui bloque : `both`, `decide` ou `unreadable`. */
  readonly blockedKind = computed(() => {
    if (this.toDecideCount() > 0 && this.unreadableCount() > 0) return 'both';
    return this.toDecideCount() > 0 ? 'decide' : 'unreadable';
  });

  readonly autoCategorisedCount = computed(() => this.model().autoCategorised.length);
  /** Rien a faire : ni a trancher, ni illisible, ni sans categorie. */
  readonly nothingToResolve = computed(
    () => this.blockingCount() === 0 && this.model().uncategorised.length === 0,
  );
  readonly canConfirm = computed(
    () =>
      this.draft() !== null &&
      this.blockingCount() === 0 &&
      this.model().newCount + this.model().matched.length > 0 &&
      !this.busy() &&
      !this.confirming(),
  );

  /** Compteur de lignes sans categorie, pour l'en-tete de section. */
  readonly uncategorisedLineCount = computed(() =>
    this.model().uncategorised.reduce((total, group) => total + group.lines.length, 0),
  );

  ngOnInit(): void {
    void this.load();
  }

  async load(): Promise<void> {
    const draftId = this.draftId;
    if (!draftId) {
      this.loadFailed.set(true);
      this.loading.set(false);
      return;
    }
    this.loading.set(true);
    this.loadFailed.set(false);
    try {
      const [draft, categories, accounts] = await Promise.all([
        firstValueFrom(this.importService.getDraft(draftId)),
        firstValueFrom(this.categoryService.getAll()),
        firstValueFrom(this.accountService.getAll(false)).catch((err: unknown) => {
          // Sans compte, la revue reste utilisable : devise par defaut, pas de suffixe de repli.
          this.logger.error('Failed to load accounts', err);
          return [] as Account[];
        }),
      ]);
      this.draft.set(draft);
      this.categories.set(categories);
      this.accounts.set(accounts);
    } catch (err) {
      this.logger.error('Failed to load draft', err);
      this.loadFailed.set(true);
    } finally {
      this.loading.set(false);
    }
  }

  goToTransactions(): void {
    this.router.navigate(['/transactions']);
  }

  // --- Affichage ---

  shortDate(isoDate: string): string {
    return formatDayMonthLabel(isoDate, this.languageService.displayLocale());
  }

  fullDate(isoDate: string): string {
    return formatFullDateLabel(isoDate, this.languageService.displayLocale());
  }

  isExpanded(group: ReviewGroupId): boolean {
    return this.expandedGroups().has(group);
  }

  toggleGroup(group: ReviewGroupId): void {
    this.expandedGroups.update((current) => {
      const next = new Set(current);
      if (!next.delete(group)) next.add(group);
      return next;
    });
  }

  categoryOf(line: ImportDraftLine): Category | null {
    return line.categoryId ? (this.categoryById().get(line.categoryId) ?? null) : null;
  }

  canRestore(line: ImportDraftLine): boolean {
    return isRestorable(line);
  }

  // --- Actions sur les lignes ---

  chooseCandidate(line: ImportDraftLine, transactionId: string): Promise<void> {
    return this.updateLine(line.id, { matchedTransactionId: transactionId });
  }

  /** Cree une transaction a la place de tout candidat, ou defait un rapprochement. */
  createNew(line: ImportDraftLine): Promise<void> {
    return this.updateLine(line.id, { clearMatch: true });
  }

  undoMatch(line: ImportDraftLine): Promise<void> {
    return this.updateLine(line.id, { clearMatch: true });
  }

  skip(line: ImportDraftLine): Promise<void> {
    return this.updateLine(line.id, { status: 'SKIPPED' });
  }

  /** Importe un doublon probable, ou restaure une ligne ignoree. */
  makeReady(line: ImportDraftLine): Promise<void> {
    return this.updateLine(line.id, { status: 'READY' });
  }

  /**
   * Un seul `PUT` par correction : l'API propage la categorie aux lignes du
   * meme commercant et cree la regle (KKS-383), puis le brouillon est relu.
   */
  private async updateLine(lineId: string, update: ImportLineUpdate): Promise<void> {
    const draft = this.draft();
    if (!draft || this.busy()) return;
    this.busy.set(true);
    try {
      await firstValueFrom(this.importService.updateLine(draft.id, lineId, update));
      this.draft.set(await firstValueFrom(this.importService.getDraft(draft.id)));
    } catch (err) {
      this.logger.error('Failed to update the import line', err);
      this.toast.error(
        this.apiError.label(err, this.transloco.translate('imports.feedback.lineUpdateError')),
      );
    } finally {
      this.busy.set(false);
    }
  }

  // --- Categorie ---

  openCategoryForGroup(group: UncategorisedGroup): void {
    this.categoryTarget.set({ lineId: group.lines[0].id, title: group.label });
  }

  openCategoryForLine(line: ImportDraftLine): void {
    this.categoryTarget.set({ lineId: line.id, title: line.cleanLabel });
  }

  closeCategorySheet(): void {
    if (this.categoryCreating()) return;
    this.categoryTarget.set(null);
  }

  onCategoryCreated(category: Category): void {
    this.categories.update((list) =>
      insertSortedByNom(list, category, this.languageService.displayLocale()),
    );
  }

  async onCategorySelected(categoryId: string): Promise<void> {
    const target = this.categoryTarget();
    this.categoryTarget.set(null);
    this.categoryCreating.set(false);
    if (!target) return;
    await this.updateLine(target.lineId, { categoryId });
  }

  // --- Confirmation ---

  async confirm(): Promise<void> {
    const draft = this.draft();
    if (!draft || !this.canConfirm()) return;
    this.confirming.set(true);
    try {
      const applyOpeningBalance =
        draft.proposedOpeningBalance !== null && this.alignOpeningBalance();
      this.result.set(
        await firstValueFrom(this.importService.confirm(draft.id, applyOpeningBalance)),
      );
    } catch (err) {
      this.logger.error('Failed to confirm the import', err);
      this.toast.error(
        this.apiError.label(err, this.transloco.translate('imports.feedback.confirmError')),
      );
    } finally {
      this.confirming.set(false);
    }
  }
}
