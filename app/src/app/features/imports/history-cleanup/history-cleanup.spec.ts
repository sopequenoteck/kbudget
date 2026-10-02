import { HttpErrorResponse } from '@angular/common/http';
import { TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { Router, provideRouter } from '@angular/router';
import { Subject, of, throwError } from 'rxjs';

import { HistoryCleanup } from './history-cleanup';
import { AccountService } from '../../../core/services/account';
import { ApiErrorService } from '../../../core/services/api-error';
import { CategoryService } from '../../../core/services/category';
import { HistoryCleanupService } from '../../../core/services/history-cleanup';
import { Account, AccountType } from '../../../core/models/account.model';
import { Category } from '../../../core/models/category.model';
import { TransactionType } from '../../../core/models/transaction.model';
import {
  AdjustmentProposals,
  CleanupMergeResult,
  DuplicateProposals,
  UncategorizedProposals,
} from '../../../core/models/history-cleanup.model';
import { CategorySelect } from '../../../shared/components/category-select/category-select';
import { ToastService } from '../../../shared/components/toast/toast.service';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';
import {
  accountAdjustments,
  accountSummary,
  cleanupAdjustment,
  cleanupCategory,
  cleanupTransaction,
  importedProposal,
  subscriptionProposal,
  uncategorizedGroup,
} from '../../../../testing/history-cleanup-fixtures';

const CATEGORIES: Category[] = [
  cleanupCategory({ id: 'cat-1', nom: 'Courses' }),
  cleanupCategory({ id: 'cat-2', nom: 'Loisirs', icone: '🎮' }),
];

const ACCOUNT: Account = {
  id: 'acc-1',
  nom: 'Courant',
  type: AccountType.COURANT,
  soldeInitial: 0,
  solde: 85,
  icone: '🏦',
  couleur: '#000000',
  isDefault: true,
  actif: true,
  currency: 'EUR',
  bankCode: '',
  bankName: null,
  bankCountry: null,
  bankBrandColor: null,
  bankLogoUrl: null,
  bankCustomName: null,
  bankCustomLogo: null,
};

const MERGE_RESULT = { kept: cleanupTransaction(), removedIds: ['imp-1'] } as CleanupMergeResult;

const duplicates = (
  importedDuplicates: DuplicateProposals['importedDuplicates'] = [],
  subscriptionDuplicates: DuplicateProposals['subscriptionDuplicates'] = [],
): DuplicateProposals => ({ importedDuplicates, subscriptionDuplicates });

/** Les handlers du composant enchainent des promesses : une macrotache les laisse toutes se resoudre. */
const flushPromises = () => new Promise<void>((resolve) => setTimeout(resolve));

describe('HistoryCleanup', () => {
  let cleanupMock: {
    getDuplicates: ReturnType<typeof vi.fn>;
    getUncategorized: ReturnType<typeof vi.fn>;
    getAdjustments: ReturnType<typeof vi.fn>;
    mergeImported: ReturnType<typeof vi.fn>;
    mergeSubscriptionPayments: ReturnType<typeof vi.fn>;
    applyCategory: ReturnType<typeof vi.fn>;
  };
  let categoryServiceMock: { getAll: ReturnType<typeof vi.fn> };
  let accountServiceMock: {
    getAll: ReturnType<typeof vi.fn>;
    adjustBalance: ReturnType<typeof vi.fn>;
  };
  let toastMock: { success: ReturnType<typeof vi.fn>; error: ReturnType<typeof vi.fn> };
  let apiErrorMock: { label: ReturnType<typeof vi.fn> };
  let navigateSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    cleanupMock = {
      getDuplicates: vi.fn().mockReturnValue(of(duplicates())),
      getUncategorized: vi.fn().mockReturnValue(of({ groups: [] })),
      getAdjustments: vi.fn().mockReturnValue(of({ accounts: [] })),
      mergeImported: vi.fn().mockReturnValue(of(MERGE_RESULT)),
      mergeSubscriptionPayments: vi.fn().mockReturnValue(of(MERGE_RESULT)),
      applyCategory: vi.fn().mockReturnValue(of({ categorizedCount: 2, skippedCount: 0 })),
    };
    categoryServiceMock = { getAll: vi.fn().mockReturnValue(of(CATEGORIES)) };
    accountServiceMock = {
      getAll: vi.fn().mockReturnValue(of([ACCOUNT])),
      adjustBalance: vi.fn().mockReturnValue(of(ACCOUNT)),
    };
    toastMock = { success: vi.fn(), error: vi.fn() };
    apiErrorMock = { label: vi.fn().mockReturnValue('Erreur API') };
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const setup = async (
    proposals: {
      duplicates?: DuplicateProposals;
      uncategorized?: UncategorizedProposals;
      adjustments?: AdjustmentProposals;
    } = {},
  ) => {
    if (proposals.duplicates) cleanupMock.getDuplicates.mockReturnValue(of(proposals.duplicates));
    if (proposals.uncategorized) {
      cleanupMock.getUncategorized.mockReturnValue(of(proposals.uncategorized));
    }
    if (proposals.adjustments)
      cleanupMock.getAdjustments.mockReturnValue(of(proposals.adjustments));
    TestBed.configureTestingModule({
      imports: [HistoryCleanup],
      providers: [
        provideTranslocoTesting(),
        provideRouter([]),
        { provide: HistoryCleanupService, useValue: cleanupMock },
        { provide: CategoryService, useValue: categoryServiceMock },
        { provide: AccountService, useValue: accountServiceMock },
        { provide: ToastService, useValue: toastMock },
        { provide: ApiErrorService, useValue: apiErrorMock },
      ],
    });
    navigateSpy = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    const fixture = TestBed.createComponent(HistoryCleanup);
    fixture.detectChanges();
    await flushPromises();
    fixture.detectChanges();
    return fixture;
  };

  type Fixture = Awaited<ReturnType<typeof setup>>;
  const root = (fixture: Fixture) => fixture.nativeElement as HTMLElement;
  const text = (fixture: Fixture) => root(fixture).textContent?.replace(/\s+/g, ' ') ?? '';
  const q = (fixture: Fixture, selector: string) =>
    root(fixture).querySelector<HTMLElement>(selector);
  const qa = (fixture: Fixture, selector: string) =>
    Array.from(root(fixture).querySelectorAll<HTMLElement>(selector));
  const click = (fixture: Fixture, selector: string, index = 0) => {
    qa(fixture, selector)[index].click();
  };
  const settle = async (fixture: Fixture) => {
    await flushPromises();
    fixture.detectChanges();
  };
  const radios = (fixture: Fixture, testId: string) =>
    qa(fixture, `[data-testid="${testId}"]`) as HTMLInputElement[];
  const conflict = () =>
    new HttpErrorResponse({ status: 409, error: { error: 'CLEANUP_PROPOSAL_STALE' } });

  // ---------------------------------------------------------------------
  // Chargement
  // ---------------------------------------------------------------------

  it('should_show_a_skeleton_while_the_proposals_are_loading', async () => {
    const pending = new Subject<DuplicateProposals>();
    cleanupMock.getDuplicates.mockReturnValue(pending);
    const fixture = await setup();

    expect(q(fixture, '.skeleton-item')).not.toBeNull();
    expect(q(fixture, '[data-testid="section-imported"]')).toBeNull();

    pending.next(duplicates());
    pending.complete();
    await settle(fixture);

    expect(q(fixture, '.skeleton-item')).toBeNull();
  });

  it('should_load_the_three_proposals_the_categories_and_the_accounts_at_start', async () => {
    await setup();

    expect(cleanupMock.getDuplicates).toHaveBeenCalledTimes(1);
    expect(cleanupMock.getUncategorized).toHaveBeenCalledTimes(1);
    expect(cleanupMock.getAdjustments).toHaveBeenCalledTimes(1);
    expect(categoryServiceMock.getAll).toHaveBeenCalledTimes(1);
    expect(accountServiceMock.getAll).toHaveBeenCalledWith(false);
  });

  it('should_show_an_error_with_a_retry_when_a_proposal_cannot_be_loaded', async () => {
    cleanupMock.getUncategorized.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup();

    expect(text(fixture)).toContain('Impossible de charger les propositions de rattrapage.');

    cleanupMock.getUncategorized.mockReturnValue(of({ groups: [] }));
    click(fixture, '.empty-state__cta');
    await settle(fixture);

    expect(text(fixture)).toContain('Rien à rattraper');
    expect(cleanupMock.getDuplicates).toHaveBeenCalledTimes(2);
  });

  it('should_still_show_the_proposals_but_disable_realigning_when_accounts_cannot_be_loaded', async () => {
    accountServiceMock.getAll.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup({ adjustments: { accounts: [accountAdjustments()] } });

    expect(q(fixture, '[data-testid="section-adjustments"]')).not.toBeNull();
    expect((q(fixture, '[data-testid="realign"]') as HTMLButtonElement).disabled).toBe(true);
  });

  it('should_go_back_to_the_import_settings', async () => {
    const fixture = await setup();

    click(fixture, '.page-header__back');

    expect(navigateSpy).toHaveBeenCalledWith(['/settings/import']);
  });

  it('should_show_the_page_title_and_description', async () => {
    const fixture = await setup();

    expect(q(fixture, '.page-header__title')?.textContent).toContain("Rattrapage de l'historique");
    expect(text(fixture)).toContain("Rien n'est modifié sans votre validation.");
  });

  // ---------------------------------------------------------------------
  // État vide
  // ---------------------------------------------------------------------

  it('should_show_the_empty_state_when_there_is_nothing_to_catch_up', async () => {
    const fixture = await setup();

    expect(text(fixture)).toContain('Rien à rattraper');
    expect(text(fixture)).toContain(
      'Votre historique ne contient ni doublon probable, ni transaction sans catégorie, ni ajustement à recaler.',
    );
    expect(qa(fixture, 'section').length).toBe(0);
  });

  it('should_not_show_the_empty_state_when_a_section_has_content', async () => {
    const fixture = await setup({ duplicates: duplicates([importedProposal()]) });

    expect(text(fixture)).not.toContain('Rien à rattraper');
  });

  it('should_show_the_empty_state_once_every_proposal_is_dismissed', async () => {
    const fixture = await setup({
      duplicates: duplicates([importedProposal()], [subscriptionProposal()]),
    });

    click(fixture, '[data-testid="dismiss-proposal"]');
    fixture.detectChanges();
    click(fixture, '[data-testid="dismiss-proposal"]');
    await settle(fixture);

    expect(text(fixture)).toContain('Rien à rattraper');
  });

  it('should_show_the_empty_state_when_no_adjustment_is_probably_unnecessary', async () => {
    const fixture = await setup({
      adjustments: {
        accounts: [
          accountAdjustments({ adjustments: [cleanupAdjustment({ probablyUnnecessary: false })] }),
        ],
      },
    });

    expect(q(fixture, '[data-testid="section-adjustments"]')).toBeNull();
    expect(text(fixture)).toContain('Rien à rattraper');
  });

  // ---------------------------------------------------------------------
  // a. Opérations déjà saisies
  // ---------------------------------------------------------------------

  it('should_show_the_imported_transaction_and_its_candidates', async () => {
    const fixture = await setup({ duplicates: duplicates([importedProposal()]) });

    const section = q(fixture, '[data-testid="section-imported"]') as HTMLElement;
    const content = section.textContent?.replace(/\s+/g, ' ') ?? '';

    expect(content).toContain('Opérations déjà saisies');
    expect(content).toContain(
      "La saisie est gardée (libellé, catégorie, liens) ; l'opération importée est supprimée.",
    );
    expect(content).toContain('CARTE BOULANGERIE');
    expect(content).toContain('16 septembre');
    expect(content).toContain('-3,20 €');
    expect(content).toContain('Même opération que :');
    expect(content).toContain('Pain');
    expect(content).toContain('Courses');
    expect(content).toContain('Baguette');
    expect(q(fixture, '.section-header__count')?.textContent).toBe('1');
  });

  it('should_color_the_imported_amount_by_its_direction', async () => {
    const income = cleanupTransaction({
      id: 'imp-in',
      type: TransactionType.RECETTE,
      imported: true,
    });
    const fixture = await setup({
      duplicates: duplicates([importedProposal({ imported: income })]),
    });

    expect(q(fixture, '.review__line .list-row__amount')?.classList).toContain(
      'review__amount--income',
    );
  });

  it('should_preselect_the_first_candidate', async () => {
    const fixture = await setup({ duplicates: duplicates([importedProposal()]) });

    expect(radios(fixture, 'candidate-radio').map((radio) => radio.checked)).toEqual([true, false]);
    expect(qa(fixture, '.cleanup__option--selected')).toHaveLength(1);
  });

  it('should_merge_with_the_preselected_candidate_then_reload_the_proposals', async () => {
    const fixture = await setup({ duplicates: duplicates([importedProposal()]) });

    click(fixture, '[data-testid="merge-imported"]');
    await settle(fixture);

    expect(cleanupMock.mergeImported).toHaveBeenCalledWith({
      importedTransactionId: 'imp-1',
      keptTransactionId: 'cand-1',
    });
    expect(toastMock.success).toHaveBeenCalledWith('Transactions fusionnées.');
    expect(cleanupMock.getDuplicates).toHaveBeenCalledTimes(2);
    expect(cleanupMock.getUncategorized).toHaveBeenCalledTimes(2);
    expect(cleanupMock.getAdjustments).toHaveBeenCalledTimes(2);
    expect(accountServiceMock.getAll).toHaveBeenCalledTimes(2);
  });

  it('should_merge_with_the_candidate_chosen_by_the_user', async () => {
    const fixture = await setup({ duplicates: duplicates([importedProposal()]) });

    radios(fixture, 'candidate-radio')[1].click();
    fixture.detectChanges();
    click(fixture, '[data-testid="merge-imported"]');
    await settle(fixture);

    expect(radios(fixture, 'candidate-radio').length).toBe(2);
    expect(cleanupMock.mergeImported).toHaveBeenCalledWith({
      importedTransactionId: 'imp-1',
      keptTransactionId: 'cand-2',
    });
  });

  it('should_move_the_selection_highlight_to_the_chosen_candidate', async () => {
    const fixture = await setup({ duplicates: duplicates([importedProposal()]) });

    radios(fixture, 'candidate-radio')[1].click();
    fixture.detectChanges();

    const selected = qa(fixture, '.cleanup__option--selected');
    expect(selected).toHaveLength(1);
    expect(selected[0].textContent).toContain('Baguette');
  });

  it('should_dismiss_a_proposal_locally_without_calling_the_api', async () => {
    const fixture = await setup({
      duplicates: duplicates([
        importedProposal(),
        importedProposal({ imported: cleanupTransaction({ id: 'imp-2', libelle: 'CARTE TABAC' }) }),
      ]),
    });

    click(fixture, '[data-testid="dismiss-proposal"]');
    fixture.detectChanges();

    expect(qa(fixture, '[data-testid="imported-proposal"]')).toHaveLength(1);
    expect(text(fixture)).toContain('CARTE TABAC');
    expect(text(fixture)).not.toContain('CARTE BOULANGERIE');
    expect(q(fixture, '.section-header__count')?.textContent).toBe('1');
    expect(cleanupMock.mergeImported).not.toHaveBeenCalled();
    expect(cleanupMock.getDuplicates).toHaveBeenCalledTimes(1);
  });

  it('should_keep_a_dismissed_proposal_hidden_after_a_reload', async () => {
    const dismissed = importedProposal();
    const other = importedProposal({
      imported: cleanupTransaction({ id: 'imp-2', libelle: 'CARTE TABAC' }),
      candidates: [cleanupTransaction({ id: 'cand-9' })],
    });
    const fixture = await setup({ duplicates: duplicates([dismissed, other]) });

    click(fixture, '[data-testid="dismiss-proposal"]');
    fixture.detectChanges();
    click(fixture, '[data-testid="merge-imported"]');
    await settle(fixture);

    expect(cleanupMock.mergeImported).toHaveBeenCalledWith({
      importedTransactionId: 'imp-2',
      keptTransactionId: 'cand-9',
    });
    expect(text(fixture)).not.toContain('CARTE BOULANGERIE');
  });

  it('should_show_the_candidate_without_category_without_a_separator', async () => {
    const fixture = await setup({
      duplicates: duplicates([
        importedProposal({ candidates: [cleanupTransaction({ id: 'cand-1', category: null })] }),
      ]),
    });

    expect(q(fixture, '.review__option-subtitle')?.textContent).not.toContain('·');
  });

  // ---------------------------------------------------------------------
  // b. Paiements d'abonnement en double
  // ---------------------------------------------------------------------

  it('should_show_the_subscription_with_its_period_and_payments', async () => {
    const fixture = await setup({ duplicates: duplicates([], [subscriptionProposal()]) });

    const section = q(fixture, '[data-testid="section-subscriptions"]') as HTMLElement;
    const content = section.textContent?.replace(/\s+/g, ' ') ?? '';

    expect(content).toContain("Paiements d'abonnement en double");
    expect(content).toContain('Netflix');
    expect(content).toContain('Échéance du 10 septembre au 9 octobre');
    expect(content).toContain('Netflix bis');
    expect(content).not.toContain('Relevé');
    expect(q(fixture, '[data-testid="section-imported"]')).toBeNull();
  });

  it('should_preselect_the_payment_suggested_by_the_api', async () => {
    const fixture = await setup({
      duplicates: duplicates([], [subscriptionProposal({ suggestedKeepTransactionId: 'pay-2' })]),
    });

    expect(radios(fixture, 'payment-radio').map((radio) => radio.checked)).toEqual([false, true]);
  });

  it('should_let_the_user_keep_any_payment_when_none_comes_from_a_statement', async () => {
    const fixture = await setup({ duplicates: duplicates([], [subscriptionProposal()]) });

    expect(radios(fixture, 'payment-radio').map((radio) => radio.disabled)).toEqual([false, false]);
  });

  it('should_keep_the_chosen_payment_and_remove_the_others', async () => {
    const proposal = subscriptionProposal({
      transactions: [
        cleanupTransaction({ id: 'pay-1' }),
        cleanupTransaction({ id: 'pay-2' }),
        cleanupTransaction({ id: 'pay-3' }),
      ],
    });
    const fixture = await setup({ duplicates: duplicates([], [proposal]) });

    radios(fixture, 'payment-radio')[2].click();
    fixture.detectChanges();
    click(fixture, '[data-testid="keep-payment"]');
    await settle(fixture);

    expect(cleanupMock.mergeSubscriptionPayments).toHaveBeenCalledWith({
      keptTransactionId: 'pay-3',
      removedTransactionIds: ['pay-1', 'pay-2'],
    });
    expect(toastMock.success).toHaveBeenCalledWith('Paiement conservé, doublons supprimés.');
    expect(cleanupMock.getDuplicates).toHaveBeenCalledTimes(2);
  });

  it('should_only_allow_keeping_the_imported_payment_and_flag_it_as_a_statement', async () => {
    const proposal = subscriptionProposal({
      suggestedKeepTransactionId: 'pay-2',
      transactions: [
        cleanupTransaction({ id: 'pay-1', libelle: 'Netflix' }),
        cleanupTransaction({ id: 'pay-2', libelle: 'PRLV NETFLIX', imported: true }),
        cleanupTransaction({ id: 'pay-3', libelle: 'Netflix bis' }),
      ],
    });
    const fixture = await setup({ duplicates: duplicates([], [proposal]) });

    expect(radios(fixture, 'payment-radio').map((radio) => radio.disabled)).toEqual([
      true,
      false,
      true,
    ]);
    expect(radios(fixture, 'payment-radio').map((radio) => radio.checked)).toEqual([
      false,
      true,
      false,
    ]);
    expect(qa(fixture, '.review__option')[1].textContent).toContain('Relevé');
    expect(qa(fixture, '.review__option')[0].textContent).not.toContain('Relevé');

    click(fixture, '[data-testid="keep-payment"]');
    await settle(fixture);

    expect(cleanupMock.mergeSubscriptionPayments).toHaveBeenCalledWith({
      keptTransactionId: 'pay-2',
      removedTransactionIds: ['pay-1', 'pay-3'],
    });
  });

  it('should_dismiss_a_subscription_proposal_locally_without_calling_the_api', async () => {
    const fixture = await setup({ duplicates: duplicates([], [subscriptionProposal()]) });

    click(fixture, '[data-testid="dismiss-proposal"]');
    fixture.detectChanges();

    expect(q(fixture, '[data-testid="section-subscriptions"]')).toBeNull();
    expect(cleanupMock.mergeSubscriptionPayments).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------
  // c. Sans catégorie
  // ---------------------------------------------------------------------

  it('should_show_a_group_with_its_count_and_total', async () => {
    const fixture = await setup({ uncategorized: { groups: [uncategorizedGroup()] } });

    const item = q(fixture, '[data-testid="uncategorised-group"]') as HTMLElement;
    const content = item.textContent?.replace(/\s+/g, ' ') ?? '';

    expect(content).toContain('BOULANGERIE TEST');
    expect(content).toContain('2 transactions');
    expect(content).toContain('-7,30 €');
    expect(item.querySelector('.list-row__amount')?.classList).toContain('review__amount--expense');
    expect(
      q(fixture, '[data-testid="section-uncategorised"] .section-header__count')?.textContent,
    ).toBe('2');
  });

  it('should_count_the_transactions_of_the_proposed_groups_only_in_the_header', async () => {
    const fixture = await setup({
      uncategorized: {
        groups: [
          uncategorizedGroup({ merchantKey: 'BOULANGERIE TEST', count: 2 }),
          uncategorizedGroup({ merchantKey: 'EPICERIE TEST', count: 3 }),
          uncategorizedGroup({ merchantKey: '', count: 4 }),
        ],
      },
    });

    expect(
      q(fixture, '[data-testid="section-uncategorised"] .section-header__count')?.textContent,
    ).toBe('5');
  });

  it('should_show_the_unit_amount_when_the_group_is_split_by_amount', async () => {
    const fixture = await setup({
      uncategorized: { groups: [uncategorizedGroup({ amount: 4.5, count: 3, totalAmount: 13.5 })] },
    });

    expect(text(fixture)).toContain('3 transactions de 4,50 €');
  });

  it('should_use_the_singular_for_a_group_of_one_transaction', async () => {
    const fixture = await setup({
      uncategorized: { groups: [uncategorizedGroup({ count: 1 })] },
    });

    expect(text(fixture)).toContain('1 transaction');
    expect(text(fixture)).not.toContain('1 transactions');
  });

  it.each([
    ['RULE', "d'après une règle"],
    ['HISTORY_AMOUNT', "d'après l'historique au même montant"],
    ['HISTORY_MERCHANT', "d'après l'historique de ce commerçant"],
  ] as const)(
    'should_show_the_suggestion_with_its_source_when_source_is_%s',
    async (source, label) => {
      const fixture = await setup({
        uncategorized: {
          groups: [uncategorizedGroup({ suggestion: { category: cleanupCategory(), source } })],
        },
      });

      expect(
        q(fixture, '[data-testid="suggestion"]')?.textContent?.replace(/\s+/g, ' ').trim(),
      ).toBe(`Proposé : Courses, ${label}`);
    },
  );

  it('should_apply_the_suggested_category_with_a_rule_when_the_group_has_no_unit_amount', async () => {
    const group = uncategorizedGroup({
      suggestion: { category: cleanupCategory({ id: 'cat-1' }), source: 'RULE' },
    });
    const fixture = await setup({ uncategorized: { groups: [group] } });

    click(fixture, '[data-testid="apply-suggestion"]');
    await settle(fixture);

    expect(cleanupMock.applyCategory).toHaveBeenCalledWith({
      categoryId: 'cat-1',
      transactionIds: ['unc-1', 'unc-2'],
      createRule: true,
    });
    expect(toastMock.success).toHaveBeenCalledWith('2 transactions catégorisées.');
    expect(cleanupMock.getUncategorized).toHaveBeenCalledTimes(2);
  });

  it('should_apply_the_suggested_category_without_a_rule_when_the_group_has_a_unit_amount', async () => {
    const group = uncategorizedGroup({
      amount: 4.5,
      suggestion: { category: cleanupCategory({ id: 'cat-1' }), source: 'HISTORY_AMOUNT' },
    });
    const fixture = await setup({ uncategorized: { groups: [group] } });

    click(fixture, '[data-testid="apply-suggestion"]');
    await settle(fixture);

    expect(cleanupMock.applyCategory).toHaveBeenCalledWith(
      expect.objectContaining({ categoryId: 'cat-1', createRule: false }),
    );
  });

  it('should_not_offer_to_apply_when_the_group_has_no_suggestion', async () => {
    const fixture = await setup({ uncategorized: { groups: [uncategorizedGroup()] } });

    expect(q(fixture, '[data-testid="apply-suggestion"]')).toBeNull();
    expect(q(fixture, '[data-testid="suggestion"]')).toBeNull();
    expect(q(fixture, '[data-testid="choose-category"]')?.classList).not.toContain(
      'review__action--muted',
    );
  });

  it('should_always_offer_to_choose_a_category_and_mute_it_next_to_a_suggestion', async () => {
    const group = uncategorizedGroup({
      suggestion: { category: cleanupCategory(), source: 'RULE' },
    });
    const fixture = await setup({ uncategorized: { groups: [group] } });

    expect(q(fixture, '[data-testid="choose-category"]')?.textContent).toContain(
      'Choisir une catégorie',
    );
    expect(q(fixture, '[data-testid="choose-category"]')?.classList).toContain(
      'review__action--muted',
    );
  });

  it('should_apply_the_category_picked_in_the_sheet', async () => {
    const fixture = await setup({ uncategorized: { groups: [uncategorizedGroup()] } });
    expect(q(fixture, 'app-category-select')).toBeNull();

    click(fixture, '[data-testid="choose-category"]');
    fixture.detectChanges();

    expect(q(fixture, 'app-category-select')).not.toBeNull();
    expect(q(fixture, '.bsheet__top-title')?.textContent).toBe('BOULANGERIE TEST');

    fixture.debugElement
      .query(By.directive(CategorySelect))
      .componentInstance.selected.emit('cat-2');
    await settle(fixture);

    expect(cleanupMock.applyCategory).toHaveBeenCalledWith({
      categoryId: 'cat-2',
      transactionIds: ['unc-1', 'unc-2'],
      createRule: true,
    });
    expect(q(fixture, 'app-category-select')).toBeNull();
  });

  it('should_close_the_sheet_without_applying_anything_when_cancelled', async () => {
    const fixture = await setup({ uncategorized: { groups: [uncategorizedGroup()] } });

    click(fixture, '[data-testid="choose-category"]');
    fixture.detectChanges();
    click(fixture, '.bsheet__action-pill--cancel');
    fixture.detectChanges();

    expect(q(fixture, 'app-category-select')).toBeNull();
    expect(cleanupMock.applyCategory).not.toHaveBeenCalled();
  });

  it('should_add_a_category_created_in_the_sheet_to_the_list_in_alphabetical_order', async () => {
    const fixture = await setup({ uncategorized: { groups: [uncategorizedGroup()] } });

    fixture.componentInstance.onCategoryCreated(cleanupCategory({ id: 'cat-3', nom: 'Animaux' }));

    expect(fixture.componentInstance.categories().map((category) => category.nom)).toEqual([
      'Animaux',
      'Courses',
      'Loisirs',
    ]);
  });

  it('should_not_propose_groups_without_a_merchant_key_but_count_them_in_a_footnote', async () => {
    const fixture = await setup({
      uncategorized: {
        groups: [
          uncategorizedGroup(),
          uncategorizedGroup({ merchantKey: '', count: 3 }),
          uncategorizedGroup({ merchantKey: '', type: TransactionType.RECETTE, count: 2 }),
        ],
      },
    });

    expect(qa(fixture, '[data-testid="uncategorised-group"]')).toHaveLength(1);
    expect(
      q(fixture, '[data-testid="without-merchant"]')?.textContent?.replace(/\s+/g, ' ').trim(),
    ).toBe(
      "5 transactions sans commerçant reconnaissable, à catégoriser depuis l'écran Transactions.",
    );
  });

  it('should_show_no_footnote_when_every_group_has_a_merchant_key', async () => {
    const fixture = await setup({ uncategorized: { groups: [uncategorizedGroup()] } });

    expect(q(fixture, '[data-testid="without-merchant"]')).toBeNull();
  });

  it('should_keep_the_footnote_when_only_groups_without_a_merchant_key_exist', async () => {
    const fixture = await setup({
      uncategorized: { groups: [uncategorizedGroup({ merchantKey: '', count: 1 })] },
    });

    expect(qa(fixture, '[data-testid="uncategorised-group"]')).toHaveLength(0);
    expect(q(fixture, '[data-testid="without-merchant"]')?.textContent).toContain(
      '1 transaction sans commerçant reconnaissable',
    );
    expect(text(fixture)).not.toContain('Rien à rattraper');
  });

  // ---------------------------------------------------------------------
  // d. Ajustements à recaler
  // ---------------------------------------------------------------------

  it('should_show_only_the_probably_unnecessary_adjustments_grouped_by_account', async () => {
    const fixture = await setup({
      adjustments: {
        accounts: [
          accountAdjustments({
            adjustments: [
              cleanupAdjustment({ id: 'adj-a', libelle: 'Ajustement inutile' }),
              cleanupAdjustment({
                id: 'adj-b',
                libelle: 'Ajustement utile',
                probablyUnnecessary: false,
              }),
            ],
          }),
          accountAdjustments({
            account: accountSummary({ id: 'acc-2', nom: 'Epargne' }),
            adjustments: [cleanupAdjustment({ probablyUnnecessary: false })],
          }),
        ],
      },
    });

    expect(text(fixture)).toContain('Ajustement inutile');
    expect(text(fixture)).not.toContain('Ajustement utile');
    expect(qa(fixture, '[data-testid="adjustment-account"]').map((el) => el.textContent)).toEqual([
      'Courant',
    ]);
    expect(
      q(fixture, '[data-testid="section-adjustments"] .section-header__count')?.textContent,
    ).toBe('1');
  });

  it('should_explain_why_the_adjustment_is_unnecessary_with_the_bank_balance', async () => {
    const fixture = await setup({ adjustments: { accounts: [accountAdjustments()] } });

    expect(
      q(fixture, '[data-testid="adjustment-explanation"]')
        ?.textContent?.replace(/\s+/g, ' ')
        .trim(),
    ).toBe(
      'Sans cet ajustement, le solde du 30 septembre 2026 égale celui de la banque (80,00 €).',
    );
    expect(q(fixture, '[data-testid="adjustment"]')?.textContent).toContain('12 septembre');
  });

  it('should_sign_and_color_the_adjustment_amounts', async () => {
    const fixture = await setup({
      adjustments: {
        accounts: [
          accountAdjustments({
            adjustments: [cleanupAdjustment({ montant: 5 }), cleanupAdjustment({ montant: -2.5 })],
          }),
        ],
      },
    });

    const amounts = qa(fixture, '[data-testid="adjustment"] .list-row__amount');

    expect(amounts.map((el) => el.textContent?.replace(/\s+/g, ' ').trim())).toEqual([
      '+5,00 €',
      '-2,50 €',
    ]);
    expect(amounts[0].classList).toContain('review__amount--income');
    expect(amounts[1].classList).toContain('review__amount--expense');
  });

  it('should_realign_on_the_bank_by_removing_a_positive_adjustment_from_the_current_balance', async () => {
    const fixture = await setup({
      adjustments: {
        accounts: [accountAdjustments({ adjustments: [cleanupAdjustment({ montant: 5 })] })],
      },
    });

    click(fixture, '[data-testid="realign"]');
    await settle(fixture);

    expect(accountServiceMock.adjustBalance).toHaveBeenCalledWith('acc-1', {
      newBalance: 80,
      libelle: "Annulation de l'ajustement du 12 septembre 2026",
    });
    expect(toastMock.success).toHaveBeenCalledWith('Solde recalé sur la banque.');
    expect(cleanupMock.getAdjustments).toHaveBeenCalledTimes(2);
    expect(accountServiceMock.getAll).toHaveBeenCalledTimes(2);
  });

  it('should_realign_on_the_bank_by_adding_back_a_negative_adjustment', async () => {
    const fixture = await setup({
      adjustments: {
        accounts: [accountAdjustments({ adjustments: [cleanupAdjustment({ montant: -5 })] })],
      },
    });

    click(fixture, '[data-testid="realign"]');
    await settle(fixture);

    expect(accountServiceMock.adjustBalance).toHaveBeenCalledWith(
      'acc-1',
      expect.objectContaining({ newBalance: 90 }),
    );
  });

  it('should_disable_realigning_when_the_account_is_not_in_the_accounts_list', async () => {
    accountServiceMock.getAll.mockReturnValue(of([{ ...ACCOUNT, id: 'acc-other' }]));
    const fixture = await setup({ adjustments: { accounts: [accountAdjustments()] } });

    const button = q(fixture, '[data-testid="realign"]') as HTMLButtonElement;
    button.click();
    await settle(fixture);

    expect(button.disabled).toBe(true);
    expect(accountServiceMock.adjustBalance).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------
  // Erreurs et état occupé
  // ---------------------------------------------------------------------

  it('should_reload_the_proposals_and_show_the_translated_error_on_a_409', async () => {
    cleanupMock.mergeImported.mockReturnValue(throwError(() => conflict()));
    const fixture = await setup({ duplicates: duplicates([importedProposal()]) });

    click(fixture, '[data-testid="merge-imported"]');
    await settle(fixture);

    expect(apiErrorMock.label).toHaveBeenCalledWith(
      expect.any(HttpErrorResponse),
      "La fusion n'a pas pu être effectuée.",
    );
    expect(toastMock.error).toHaveBeenCalledWith('Erreur API');
    expect(toastMock.success).not.toHaveBeenCalled();
    expect(cleanupMock.getDuplicates).toHaveBeenCalledTimes(2);
    expect(cleanupMock.getAdjustments).toHaveBeenCalledTimes(2);
  });

  it('should_not_reload_when_the_action_fails_with_another_error', async () => {
    cleanupMock.applyCategory.mockReturnValue(
      throwError(() => new HttpErrorResponse({ status: 500 })),
    );
    const fixture = await setup({ uncategorized: { groups: [uncategorizedGroup()] } });

    fixture.componentInstance.categoryTarget.set(fixture.componentInstance.uncategorized()[0]);
    await fixture.componentInstance.onCategorySelected('cat-1');
    await settle(fixture);

    expect(apiErrorMock.label).toHaveBeenCalledWith(
      expect.any(HttpErrorResponse),
      "La catégorie n'a pas pu être appliquée.",
    );
    expect(toastMock.error).toHaveBeenCalledWith('Erreur API');
    expect(cleanupMock.getUncategorized).toHaveBeenCalledTimes(1);
    expect(fixture.componentInstance.busy()).toBe(false);
  });

  it('should_use_the_realign_fallback_message_when_realigning_fails', async () => {
    accountServiceMock.adjustBalance.mockReturnValue(throwError(() => new Error('boom')));
    const fixture = await setup({ adjustments: { accounts: [accountAdjustments()] } });

    click(fixture, '[data-testid="realign"]');
    await settle(fixture);

    expect(apiErrorMock.label).toHaveBeenCalledWith(
      expect.any(Error),
      "Le solde n'a pas pu être recalé.",
    );
  });

  it('should_show_the_load_error_when_the_reload_after_an_action_fails', async () => {
    const fixture = await setup({ duplicates: duplicates([importedProposal()]) });
    cleanupMock.getDuplicates.mockReturnValue(throwError(() => new Error('500')));

    click(fixture, '[data-testid="merge-imported"]');
    await settle(fixture);

    expect(text(fixture)).toContain('Impossible de charger les propositions de rattrapage.');
    expect(fixture.componentInstance.busy()).toBe(false);
  });

  it('should_disable_every_action_while_a_request_is_in_flight', async () => {
    const pending = new Subject<CleanupMergeResult>();
    cleanupMock.mergeImported.mockReturnValue(pending);
    const fixture = await setup({
      duplicates: duplicates([importedProposal()], [subscriptionProposal()]),
      uncategorized: { groups: [uncategorizedGroup()] },
      adjustments: { accounts: [accountAdjustments()] },
    });
    const controls = () =>
      qa(fixture, 'button.review__action, input[type="radio"]') as (
        | HTMLButtonElement
        | HTMLInputElement
      )[];
    expect(controls().every((control) => !control.disabled)).toBe(true);

    click(fixture, '[data-testid="merge-imported"]');
    fixture.detectChanges();

    expect(controls().length).toBeGreaterThan(8);
    expect(controls().every((control) => control.disabled)).toBe(true);

    pending.next(MERGE_RESULT);
    pending.complete();
    await settle(fixture);

    expect(controls().every((control) => !control.disabled)).toBe(true);
  });

  it('should_ignore_a_second_action_while_one_is_in_flight', async () => {
    const pending = new Subject<CleanupMergeResult>();
    cleanupMock.mergeImported.mockReturnValue(pending);
    const fixture = await setup({ duplicates: duplicates([importedProposal()]) });

    const first = fixture.componentInstance.mergeImported(importedProposal());
    await fixture.componentInstance.mergeImported(importedProposal());
    pending.next(MERGE_RESULT);
    pending.complete();
    await first;

    expect(cleanupMock.mergeImported).toHaveBeenCalledTimes(1);
  });
});
