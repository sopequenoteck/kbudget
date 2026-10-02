import { HttpErrorResponse } from '@angular/common/http';
import {
  ChangeDetectionStrategy,
  Component,
  computed,
  inject,
  OnInit,
  signal,
} from '@angular/core';
import { Router } from '@angular/router';
import { firstValueFrom, Observable } from 'rxjs';
import { NgIcon, provideIcons } from '@ng-icons/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import {
  phosphorArrowLeft,
  phosphorSealCheck,
  phosphorWarningCircle,
} from '@ng-icons/phosphor-icons/regular';

import { AccountService } from '../../../core/services/account';
import { ApiErrorService } from '../../../core/services/api-error';
import { CategoryService } from '../../../core/services/category';
import { DevLogger } from '../../../core/services/dev-logger';
import { HistoryCleanupService } from '../../../core/services/history-cleanup';
import { LanguageService } from '../../../core/services/language';
import { Account } from '../../../core/models/account.model';
import { Category } from '../../../core/models/category.model';
import {
  AccountAdjustments,
  CleanupAdjustment,
  CleanupTransaction,
  DuplicateProposals,
  ImportedDuplicateProposal,
  SubscriptionDuplicateProposal,
  UncategorizedGroup,
} from '../../../core/models/history-cleanup.model';
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
import {
  amountClass,
  defaultCandidateId,
  defaultKeptPaymentId,
  groupCurrency,
  groupKey,
  importedProposalKey,
  keepablePaymentIds,
  removedPaymentIds,
  resolveChoice,
  reversalBalance,
  shouldCreateRule,
  signedAmountType,
  splitUncategorized,
  subscriptionProposalKey,
  unneededAdjustments,
} from './history-cleanup.utils';

/**
 * Rattrapage de l'historique (KKS-387) : un passage declenche par
 * l'utilisateur qui **propose** des corrections sur les transactions deja en
 * base. Les `GET` ne modifient rien ; chaque action est une validation
 * explicite, suivie d'un rechargement complet (une fusion change le solde
 * calcule, donc les ajustements a recaler).
 */
@Component({
  selector: 'app-history-cleanup',
  standalone: true,
  imports: [NgIcon, AmountPipe, CategoryNamePipe, CategorySelect, EmptyState, Modal, TranslocoPipe],
  providers: [provideIcons({ phosphorArrowLeft, phosphorSealCheck, phosphorWarningCircle })],
  templateUrl: './history-cleanup.html',
  styleUrl: './history-cleanup.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HistoryCleanup implements OnInit {
  private readonly router = inject(Router);
  private readonly cleanupService = inject(HistoryCleanupService);
  private readonly categoryService = inject(CategoryService);
  private readonly accountService = inject(AccountService);
  private readonly languageService = inject(LanguageService);
  private readonly apiError = inject(ApiErrorService);
  private readonly toast = inject(ToastService);
  private readonly logger = inject(DevLogger);
  private readonly transloco = inject(TranslocoService);

  readonly loading = signal(true);
  readonly loadFailed = signal(false);
  /** Une action est en cours : toutes les autres sont desactivees le temps de l'aller-retour. */
  readonly busy = signal(false);

  readonly duplicates = signal<DuplicateProposals | null>(null);
  readonly uncategorized = signal<UncategorizedGroup[]>([]);
  readonly adjustments = signal<AccountAdjustments[]>([]);
  readonly categories = signal<Category[]>([]);
  readonly accounts = signal<Account[]>([]);

  /** Propositions ecartees par l'utilisateur, pour la session seulement (aucun appel). */
  readonly dismissed = signal<ReadonlySet<string>>(new Set());
  /** Choix de l'utilisateur par proposition (cle -> identifiant de transaction). */
  readonly choices = signal<ReadonlyMap<string, string>>(new Map());
  readonly categoryTarget = signal<UncategorizedGroup | null>(null);
  readonly categoryCreating = signal(false);

  readonly importedProposals = computed(() =>
    (this.duplicates()?.importedDuplicates ?? []).filter(
      (proposal) => !this.dismissed().has(importedProposalKey(proposal)),
    ),
  );
  readonly subscriptionProposals = computed(() =>
    (this.duplicates()?.subscriptionDuplicates ?? []).filter(
      (proposal) => !this.dismissed().has(subscriptionProposalKey(proposal)),
    ),
  );

  private readonly uncategorizedSplit = computed(() => splitUncategorized(this.uncategorized()));
  readonly uncategorizedGroups = computed(() => this.uncategorizedSplit().proposable);
  readonly withoutMerchantCount = computed(() => this.uncategorizedSplit().withoutMerchantCount);
  /** Compteur de l'en-tete : les transactions des groupes proposes, comme la revue d'import. */
  readonly uncategorizedCount = computed(() =>
    this.uncategorizedGroups().reduce((total, group) => total + group.count, 0),
  );
  /** La section reste visible pour sa phrase de pied meme quand aucun groupe n'est propose. */
  readonly showUncategorized = computed(
    () => this.uncategorizedGroups().length > 0 || this.withoutMerchantCount() > 0,
  );

  readonly adjustmentAccounts = computed(() => unneededAdjustments(this.adjustments()));
  readonly adjustmentCount = computed(() =>
    this.adjustmentAccounts().reduce((total, entry) => total + entry.adjustments.length, 0),
  );

  readonly nothingToCatchUp = computed(
    () =>
      this.importedProposals().length === 0 &&
      this.subscriptionProposals().length === 0 &&
      !this.showUncategorized() &&
      this.adjustmentCount() === 0,
  );

  ngOnInit(): void {
    void this.load();
  }

  async load(): Promise<void> {
    this.loading.set(true);
    this.loadFailed.set(false);
    try {
      const [categories] = await Promise.all([
        firstValueFrom(this.categoryService.getAll()),
        this.fetchProposals(),
      ]);
      this.categories.set(categories);
    } catch (err) {
      this.logger.error('Failed to load the history clean-up', err);
      this.loadFailed.set(true);
    } finally {
      this.loading.set(false);
    }
  }

  /** Relit les trois propositions et les comptes (le solde courant sert a recaler). */
  private async fetchProposals(): Promise<void> {
    const [duplicates, uncategorized, adjustments, accounts] = await Promise.all([
      firstValueFrom(this.cleanupService.getDuplicates()),
      firstValueFrom(this.cleanupService.getUncategorized()),
      firstValueFrom(this.cleanupService.getAdjustments()),
      firstValueFrom(this.accountService.getAll(false)).catch((err: unknown) => {
        // Sans compte, rien ne se recale mais le reste du rattrapage reste utilisable.
        this.logger.error('Failed to load accounts', err);
        return [] as Account[];
      }),
    ]);
    this.duplicates.set(duplicates);
    this.uncategorized.set(uncategorized.groups);
    this.adjustments.set(adjustments.accounts);
    this.accounts.set(accounts);
  }

  private async refresh(): Promise<void> {
    try {
      await this.fetchProposals();
    } catch (err) {
      this.logger.error('Failed to reload the history clean-up', err);
      this.loadFailed.set(true);
    }
  }

  goBack(): void {
    this.router.navigate(['/settings/import']);
  }

  // --- Affichage ---

  shortDate(isoDate: string): string {
    return formatDayMonthLabel(isoDate, this.languageService.displayLocale());
  }

  fullDate(isoDate: string): string {
    return formatFullDateLabel(isoDate, this.languageService.displayLocale());
  }

  // Fonctions pures exposees au template.
  readonly amountClass = amountClass;
  readonly signedType = signedAmountType;
  readonly importedKey = importedProposalKey;
  readonly subscriptionKey = subscriptionProposalKey;
  readonly groupTrackKey = groupKey;
  readonly currencyOf = groupCurrency;

  // --- Choix des radios ---

  chosenCandidateId(proposal: ImportedDuplicateProposal): string | null {
    return resolveChoice(
      this.choices(),
      importedProposalKey(proposal),
      proposal.candidates.map((candidate) => candidate.id),
      defaultCandidateId(proposal),
    );
  }

  chosenPaymentId(proposal: SubscriptionDuplicateProposal): string | null {
    return resolveChoice(
      this.choices(),
      subscriptionProposalKey(proposal),
      keepablePaymentIds(proposal),
      defaultKeptPaymentId(proposal),
    );
  }

  /** Une transaction importee ne peut pas etre supprimee : des qu'il y en a une, elle seule se garde. */
  isPaymentKeepable(
    proposal: SubscriptionDuplicateProposal,
    transaction: CleanupTransaction,
  ): boolean {
    return keepablePaymentIds(proposal).includes(transaction.id);
  }

  choose(key: string, transactionId: string): void {
    this.choices.update((current) => new Map(current).set(key, transactionId));
  }

  /** « Ce n'est pas un doublon » / « Ignorer » : masque la proposition pour la session. */
  dismiss(key: string): void {
    this.dismissed.update((current) => new Set(current).add(key));
  }

  // --- Actions ---

  mergeImported(proposal: ImportedDuplicateProposal): Promise<void> {
    const keptId = this.chosenCandidateId(proposal);
    if (!keptId) return Promise.resolve();
    return this.run(
      () =>
        this.cleanupService.mergeImported({
          importedTransactionId: proposal.imported.id,
          keptTransactionId: keptId,
        }),
      () => this.transloco.translate('imports.feedback.cleanupMerged'),
      'imports.feedback.cleanupMergeError',
    );
  }

  keepPayment(proposal: SubscriptionDuplicateProposal): Promise<void> {
    const keptId = this.chosenPaymentId(proposal);
    if (!keptId) return Promise.resolve();
    return this.run(
      () =>
        this.cleanupService.mergeSubscriptionPayments({
          keptTransactionId: keptId,
          removedTransactionIds: removedPaymentIds(proposal, keptId),
        }),
      () => this.transloco.translate('imports.feedback.cleanupPaymentsMerged'),
      'imports.feedback.cleanupMergeError',
    );
  }

  applySuggestion(group: UncategorizedGroup): Promise<void> {
    const suggestion = group.suggestion;
    return suggestion ? this.applyCategory(group, suggestion.category.id) : Promise.resolve();
  }

  openCategorySheet(group: UncategorizedGroup): void {
    this.categoryTarget.set(group);
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
    const group = this.categoryTarget();
    this.categoryTarget.set(null);
    this.categoryCreating.set(false);
    if (!group) return;
    await this.applyCategory(group, categoryId);
  }

  private applyCategory(group: UncategorizedGroup, categoryId: string): Promise<void> {
    return this.run(
      () =>
        this.cleanupService.applyCategory({
          categoryId,
          transactionIds: group.transactions.map((transaction) => transaction.id),
          createRule: shouldCreateRule(group),
        }),
      (result) =>
        this.transloco.translate('imports.feedback.cleanupCategorised', {
          count: result.categorizedCount,
        }),
      'imports.feedback.cleanupCategoriseError',
    );
  }

  /** Le compte tel que la liste des comptes le connait : son solde courant sert a recaler. */
  private accountOf(entry: AccountAdjustments): Account | undefined {
    return this.accounts().find((account) => account.id === entry.account.id);
  }

  canRealign(entry: AccountAdjustments): boolean {
    return this.accountOf(entry) !== undefined;
  }

  realign(entry: AccountAdjustments, adjustment: CleanupAdjustment): Promise<void> {
    const account = this.accountOf(entry);
    if (!account) return Promise.resolve();
    return this.run(
      () =>
        this.accountService.adjustBalance(account.id, {
          newBalance: reversalBalance(account.solde, adjustment.montant),
          libelle: this.transloco.translate('imports.value.adjustmentReversal', {
            date: this.fullDate(adjustment.date),
          }),
        }),
      () => this.transloco.translate('imports.feedback.cleanupRealigned'),
      'imports.feedback.cleanupRealignError',
    );
  }

  /**
   * Un aller-retour : l'action, un toast, puis le rechargement des trois
   * propositions. Un 409 (proposition perimee) recharge aussi, l'erreur dit
   * a l'utilisateur que la liste a bouge.
   */
  private async run<T>(
    call: () => Observable<T>,
    successMessage: (result: T) => string,
    errorKey: string,
  ): Promise<void> {
    if (this.busy()) return;
    this.busy.set(true);
    try {
      let reload = true;
      try {
        const result = await firstValueFrom(call());
        this.toast.success(successMessage(result));
      } catch (err) {
        this.logger.error('History clean-up action failed', err);
        this.toast.error(this.apiError.label(err, this.transloco.translate(errorKey)));
        reload = err instanceof HttpErrorResponse && err.status === 409;
      }
      if (reload) await this.refresh();
    } finally {
      this.busy.set(false);
    }
  }
}
