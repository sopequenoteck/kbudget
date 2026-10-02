import { TestBed } from '@angular/core/testing';
import { ActivatedRoute, Router, convertToParamMap, provideRouter } from '@angular/router';
import { Subject, of, throwError } from 'rxjs';

import { ImportReview } from './import-review';
import { AccountService } from '../../../core/services/account';
import { ApiErrorService } from '../../../core/services/api-error';
import { CategoryService } from '../../../core/services/category';
import { ImportService } from '../../../core/services/import';
import { Account, AccountType } from '../../../core/models/account.model';
import { Category } from '../../../core/models/category.model';
import { ImportDraft, ImportDraftLine } from '../../../core/models/import.model';
import { ToastService } from '../../../shared/components/toast/toast.service';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';
import {
  confirmResult,
  importDraft,
  importLine,
  matchedTransaction,
} from '../../../../testing/import-fixtures';

const CATEGORIES: Category[] = [
  { id: 'cat-1', nom: 'Courses', icone: '🛒', couleur: '#f59e0b', isSystem: false },
  { id: 'cat-2', nom: 'Loisirs', icone: '🎮', couleur: '#6366f1', isSystem: false },
];

const ACCOUNT: Account = {
  id: 'acc-1',
  nom: 'Courant',
  type: AccountType.COURANT,
  soldeInitial: 0,
  solde: 100,
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
  statementAccountSuffix: '1596',
};

/** Les handlers du composant enchainent des promesses : une macrotache les laisse toutes se resoudre. */
const flushPromises = () => new Promise<void>((resolve) => setTimeout(resolve));

describe('ImportReview', () => {
  let importServiceMock: {
    getDraft: ReturnType<typeof vi.fn>;
    updateLine: ReturnType<typeof vi.fn>;
    confirm: ReturnType<typeof vi.fn>;
  };
  let categoryServiceMock: { getAll: ReturnType<typeof vi.fn> };
  let accountServiceMock: { getAll: ReturnType<typeof vi.fn> };
  let toastMock: { error: ReturnType<typeof vi.fn> };
  let apiErrorMock: { label: ReturnType<typeof vi.fn> };
  let navigateSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    importServiceMock = {
      getDraft: vi.fn().mockReturnValue(of(importDraft())),
      updateLine: vi.fn().mockReturnValue(of(importLine())),
      confirm: vi.fn().mockReturnValue(of(confirmResult())),
    };
    categoryServiceMock = { getAll: vi.fn().mockReturnValue(of(CATEGORIES)) };
    accountServiceMock = { getAll: vi.fn().mockReturnValue(of([ACCOUNT])) };
    toastMock = { error: vi.fn() };
    apiErrorMock = { label: vi.fn().mockReturnValue('Erreur API') };
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const setup = async (
    draft: ImportDraft | null = importDraft(),
    draftId: string | null = 'draft-1',
  ) => {
    if (draft) importServiceMock.getDraft.mockReturnValue(of(draft));
    TestBed.configureTestingModule({
      imports: [ImportReview],
      providers: [
        provideTranslocoTesting(),
        provideRouter([]),
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { paramMap: convertToParamMap(draftId ? { draftId } : {}) } },
        },
        { provide: ImportService, useValue: importServiceMock },
        { provide: CategoryService, useValue: categoryServiceMock },
        { provide: AccountService, useValue: accountServiceMock },
        { provide: ToastService, useValue: toastMock },
        { provide: ApiErrorService, useValue: apiErrorMock },
      ],
    });
    navigateSpy = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    const fixture = TestBed.createComponent(ImportReview);
    fixture.detectChanges();
    await flushPromises();
    fixture.detectChanges();
    return fixture;
  };

  type Fixture = Awaited<ReturnType<typeof setup>>;
  const root = (fixture: Fixture) => fixture.nativeElement as HTMLElement;
  const text = (fixture: Fixture) => root(fixture).textContent?.replace(/\s+/g, ' ') ?? '';
  const q = <T extends HTMLElement>(fixture: Fixture, selector: string) =>
    root(fixture).querySelector<T>(selector);
  const qa = (fixture: Fixture, selector: string) =>
    Array.from(root(fixture).querySelectorAll<HTMLElement>(selector));
  const click = (fixture: Fixture, selector: string, index = 0) => {
    qa(fixture, selector)[index].click();
  };
  const settle = async (fixture: Fixture) => {
    await flushPromises();
    fixture.detectChanges();
  };

  const superU = (overrides: Partial<ImportDraftLine> = {}) =>
    importLine({ merchantKey: 'SUPER U', cleanLabel: 'SUPER U', ...overrides });

  // ---------------------------------------------------------------------
  // Chargement
  // ---------------------------------------------------------------------

  it('should_show_a_skeleton_while_the_draft_is_loading', async () => {
    const pending = new Subject<ImportDraft>();
    importServiceMock.getDraft.mockReturnValue(pending);
    const fixture = await setup(null);

    expect(q(fixture, '.skeleton-hero')).not.toBeNull();
    expect(q(fixture, '.hero')).toBeNull();

    pending.next(importDraft());
    pending.complete();
    await settle(fixture);

    expect(q(fixture, '.skeleton-hero')).toBeNull();
    expect(q(fixture, '.hero')).not.toBeNull();
  });

  it('should_show_an_error_with_a_retry_when_the_draft_cannot_be_loaded', async () => {
    importServiceMock.getDraft.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup(null);

    expect(text(fixture)).toContain('Erreur de chargement du brouillon');

    importServiceMock.getDraft.mockReturnValue(of(importDraft()));
    click(fixture, '.empty-state__cta');
    await settle(fixture);

    expect(q(fixture, '.hero')).not.toBeNull();
    expect(importServiceMock.getDraft).toHaveBeenCalledTimes(2);
  });

  it('should_fail_to_load_when_the_route_has_no_draft_id', async () => {
    const fixture = await setup(null, null);

    expect(importServiceMock.getDraft).not.toHaveBeenCalled();
    expect(fixture.componentInstance.loadFailed()).toBe(true);
  });

  it('should_still_show_the_review_when_accounts_cannot_be_loaded', async () => {
    accountServiceMock.getAll.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup(
      importDraft([], { statementBalance: 100, statementBalanceDate: '2026-10-01' }),
    );

    expect(q(fixture, '.hero')).not.toBeNull();
    expect(fixture.componentInstance.currency()).toBe('EUR');
  });

  // ---------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------

  it('should_show_the_account_with_its_suffix_and_the_bank_balance_in_the_hero', async () => {
    const fixture = await setup(
      importDraft([superU()], {
        statementAccountSuffix: '1596',
        statementBalance: 1842.37,
        statementBalanceDate: '2026-10-01',
      }),
    );

    expect(q(fixture, '.hero__amount-label')?.textContent).toContain('Courant · …1596');
    expect(q(fixture, '[data-testid="bank-balance"]')?.textContent?.replace(/\s/g, ' ')).toContain(
      '1 842,37',
    );
    expect(text(fixture)).toContain('Solde de la banque au 1 octobre 2026');
  });

  it('should_fall_back_to_the_suffix_of_the_account_when_the_file_has_none', async () => {
    const fixture = await setup(importDraft([superU()]));

    expect(q(fixture, '.hero__amount-label')?.textContent).toContain('…1596');
  });

  it('should_hide_the_bank_balance_when_the_statement_gives_none', async () => {
    const fixture = await setup(importDraft([superU()]));

    expect(q(fixture, '[data-testid="bank-balance"]')).toBeNull();
  });

  it('should_count_new_already_imported_matched_and_automatic_lines_in_the_meta_lines', async () => {
    const lines = [
      superU({ categoryId: 'cat-1', categorySource: 'RULE', categoryName: 'Courses' }),
      superU({ categoryId: 'cat-1', categorySource: 'HISTORY', categoryName: 'Courses' }),
      superU(),
      superU({ matchedTransactionId: 'tx-1', matchedTransaction: matchedTransaction() }),
      superU({ status: 'SKIPPED', skipReason: 'ALREADY_IMPORTED' }),
      superU({ status: 'SKIPPED', skipReason: 'ALREADY_IMPORTED' }),
    ];
    const fixture = await setup(importDraft(lines));

    expect(q(fixture, '[data-testid="meta-new"]')?.textContent).toContain(
      '3 nouvelles transactions',
    );
    expect(q(fixture, '[data-testid="meta-already-imported"]')?.textContent).toContain(
      '2 déjà importées',
    );
    expect(q(fixture, '[data-testid="meta-matched"]')?.textContent).toContain('1 rapprochée');
    expect(q(fixture, '[data-testid="meta-auto"]')?.textContent).toContain(
      '2 catégorisées automatiquement',
    );
  });

  it('should_hide_the_meta_lines_that_are_zero', async () => {
    const fixture = await setup(importDraft([superU()]));

    expect(q(fixture, '[data-testid="meta-new"]')).not.toBeNull();
    expect(q(fixture, '[data-testid="meta-already-imported"]')).toBeNull();
    expect(q(fixture, '[data-testid="meta-matched"]')).toBeNull();
    expect(q(fixture, '[data-testid="meta-auto"]')).toBeNull();
  });

  // ---------------------------------------------------------------------
  // Sans categorie, regroupees par commercant
  // ---------------------------------------------------------------------

  it('should_group_uncategorised_lines_by_merchant_with_their_count_and_total', async () => {
    const lines = [
      superU({ cleanLabel: 'SUPER U 16/03', amount: 10 }),
      importLine({ merchantKey: 'BOULANGERIE', cleanLabel: 'BOULANGERIE', amount: 3 }),
      superU({ cleanLabel: 'SUPER U 20/03', amount: 5.5 }),
    ];
    const fixture = await setup(importDraft(lines));

    const groups = qa(fixture, '[data-testid="uncategorised-group"]');
    expect(groups).toHaveLength(2);
    expect(groups[0].textContent).toContain('SUPER U 16/03');
    expect(groups[0].textContent).toContain('2 opérations');
    expect(groups[0].textContent).toContain('-15,50');
    expect(groups[1].textContent).toContain('1 opération');
    expect(
      q(fixture, '[data-testid="section-uncategorised"] .section-header__count')?.textContent,
    ).toContain('3');
  });

  it('should_send_a_single_update_on_one_line_of_the_group_when_a_category_is_chosen', async () => {
    const first = superU({ cleanLabel: 'SUPER U 16/03' });
    const second = superU({ cleanLabel: 'SUPER U 20/03' });
    const categorised = [
      { ...first, categoryId: 'cat-1', categorySource: 'USER' as const, categoryName: 'Courses' },
      { ...second, categoryId: 'cat-1', categorySource: 'USER' as const, categoryName: 'Courses' },
    ];
    const fixture = await setup(importDraft([first, second]));
    importServiceMock.getDraft.mockReturnValue(of(importDraft(categorised)));

    click(fixture, '[data-testid="uncategorised-group"]');
    fixture.detectChanges();
    expect(q(fixture, 'app-category-select')).not.toBeNull();
    await fixture.componentInstance.onCategorySelected('cat-1');
    await settle(fixture);

    expect(importServiceMock.updateLine).toHaveBeenCalledTimes(1);
    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', first.id, {
      categoryId: 'cat-1',
    });
    expect(importServiceMock.getDraft).toHaveBeenCalledTimes(2);
    expect(q(fixture, '[data-testid="uncategorised-group"]')).toBeNull();
    expect(q(fixture, '[data-testid="group-user"]')).not.toBeNull();
    expect(fixture.componentInstance.categoryTarget()).toBeNull();
  });

  it('should_choose_the_category_from_the_sheet_by_clicking_a_category', async () => {
    const fixture = await setup(importDraft([superU()]));
    click(fixture, '[data-testid="uncategorised-group"]');
    fixture.detectChanges();

    click(fixture, '.cs__item', 1);
    await settle(fixture);

    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', expect.any(String), {
      categoryId: 'cat-2',
    });
  });

  it('should_close_the_category_sheet_without_updating_when_cancelled', async () => {
    const fixture = await setup(importDraft([superU()]));
    fixture.componentInstance.openCategoryForGroup(
      fixture.componentInstance.model().uncategorised[0],
    );
    fixture.detectChanges();

    click(fixture, '.bsheet__action-pill--cancel');
    fixture.detectChanges();

    expect(fixture.componentInstance.categoryTarget()).toBeNull();
    expect(importServiceMock.updateLine).not.toHaveBeenCalled();
  });

  it('should_keep_the_category_sheet_open_while_a_category_is_being_created', async () => {
    const fixture = await setup(importDraft([superU()]));
    fixture.componentInstance.openCategoryForGroup(
      fixture.componentInstance.model().uncategorised[0],
    );
    fixture.componentInstance.categoryCreating.set(true);

    fixture.componentInstance.closeCategorySheet();

    expect(fixture.componentInstance.categoryTarget()).not.toBeNull();
  });

  it('should_add_a_created_category_to_the_available_categories_in_name_order', async () => {
    const fixture = await setup(importDraft([superU()]));

    fixture.componentInstance.onCategoryCreated({
      id: 'cat-3',
      nom: 'Cadeaux',
      icone: '🎁',
      couleur: '#000000',
      isSystem: false,
    });

    expect(fixture.componentInstance.categories().map((c) => c.nom)).toEqual([
      'Cadeaux',
      'Courses',
      'Loisirs',
    ]);
  });

  it('should_ignore_a_selected_category_when_no_target_is_open', async () => {
    const fixture = await setup(importDraft([superU()]));

    await fixture.componentInstance.onCategorySelected('cat-1');

    expect(importServiceMock.updateLine).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------
  // Confirmation
  // ---------------------------------------------------------------------

  it('should_let_the_user_confirm_with_lines_that_have_no_category', async () => {
    const fixture = await setup(importDraft([superU(), importLine({ merchantKey: 'AUTRE' })]));

    const button = q<HTMLButtonElement>(fixture, '[data-testid="confirm-import"]')!;
    expect(button.disabled).toBe(false);
    expect(button.textContent).toContain("Confirmer l'import (2 transactions)");
    expect(q(fixture, '[data-testid="blocked-message"]')).toBeNull();

    button.click();
    await settle(fixture);

    expect(importServiceMock.confirm).toHaveBeenCalledWith('draft-1', false);
  });

  it('should_block_the_confirmation_and_say_why_when_a_line_is_left_to_decide', async () => {
    const fixture = await setup(
      importDraft([
        superU(),
        importLine({
          status: 'DUPLICATE',
          matchCandidateIds: ['tx-1', 'tx-2'],
          matchCandidates: [],
        }),
      ]),
    );

    expect((q(fixture, '[data-testid="confirm-import"]') as HTMLButtonElement).disabled).toBe(true);
    expect(q(fixture, '[data-testid="blocked-message"]')?.textContent).toContain(
      'tranchez 1 ligne',
    );
    expect(q(fixture, '[data-testid="blocked-message"]')?.textContent).not.toContain(
      'erreur de lecture',
    );

    await fixture.componentInstance.confirm();
    expect(importServiceMock.confirm).not.toHaveBeenCalled();
  });

  it('should_block_the_confirmation_and_say_why_when_a_line_is_unreadable', async () => {
    const fixture = await setup(
      importDraft([
        superU(),
        importLine({ status: 'NEEDS_REVIEW', statusMessage: 'Montant invalide' }),
      ]),
    );

    expect((q(fixture, '[data-testid="confirm-import"]') as HTMLButtonElement).disabled).toBe(true);
    expect(q(fixture, '[data-testid="blocked-message"]')?.textContent).toContain(
      '1 erreur de lecture',
    );
    expect(q(fixture, '[data-testid="blocked-message"]')?.textContent).not.toContain('tranchez');
  });

  it('should_name_both_kinds_of_blocking_lines_when_there_are_both', async () => {
    const fixture = await setup(
      importDraft([
        importLine({ status: 'DUPLICATE', duplicateTransactionId: 'tx-9' }),
        importLine({ status: 'DUPLICATE', matchCandidateIds: ['tx-1'] }),
        importLine({ status: 'NEEDS_REVIEW', statusMessage: 'Date invalide' }),
        importLine({ status: 'NEEDS_REVIEW', statusMessage: 'Date invalide' }),
      ]),
    );

    const message = q(fixture, '[data-testid="blocked-message"]')?.textContent ?? '';
    expect(message).toContain('2 lignes');
    expect(message).toContain('2 erreurs de lecture');
  });

  it('should_not_allow_confirming_when_nothing_would_be_imported', async () => {
    const fixture = await setup(
      importDraft([importLine({ status: 'SKIPPED', skipReason: 'ALREADY_IMPORTED' })]),
    );

    expect((q(fixture, '[data-testid="confirm-import"]') as HTMLButtonElement).disabled).toBe(true);
  });

  it('should_allow_confirming_when_only_matched_lines_remain', async () => {
    const fixture = await setup(
      importDraft([
        importLine({ matchedTransactionId: 'tx-1', matchedTransaction: matchedTransaction() }),
      ]),
    );

    expect((q(fixture, '[data-testid="confirm-import"]') as HTMLButtonElement).disabled).toBe(
      false,
    );
  });

  it('should_show_the_result_state_after_the_confirmation_and_hide_the_action_bar', async () => {
    importServiceMock.confirm.mockReturnValue(
      of(confirmResult({ importedCount: 2, matchedCount: 1 })),
    );
    const fixture = await setup(importDraft([superU(), superU()]));

    click(fixture, '[data-testid="confirm-import"]');
    await settle(fixture);

    expect(q(fixture, 'app-import-result')).not.toBeNull();
    expect(q(fixture, '[data-testid="confirm-import"]')).toBeNull();
    expect(q(fixture, '[data-testid="section-uncategorised"]')).toBeNull();
    expect(text(fixture)).toContain('2 transactions créées');

    click(fixture, '.result__done');
    expect(navigateSpy).toHaveBeenCalledWith(['/transactions']);
  });

  it('should_show_an_error_and_stay_on_the_review_when_the_confirmation_fails', async () => {
    importServiceMock.confirm.mockReturnValue(throwError(() => ({ status: 400 })));
    const fixture = await setup(importDraft([superU()]));

    await fixture.componentInstance.confirm();
    fixture.detectChanges();

    expect(toastMock.error).toHaveBeenCalledWith('Erreur API');
    expect(apiErrorMock.label).toHaveBeenCalledWith(
      { status: 400 },
      "Erreur lors de la confirmation de l'import.",
    );
    expect(fixture.componentInstance.result()).toBeNull();
    expect(fixture.componentInstance.confirming()).toBe(false);
    expect(q(fixture, '[data-testid="confirm-import"]')).not.toBeNull();
  });

  // ---------------------------------------------------------------------
  // Solde d'ouverture
  // ---------------------------------------------------------------------

  it('should_not_offer_the_opening_balance_when_none_is_proposed', async () => {
    const fixture = await setup(importDraft([superU()], { proposedOpeningBalance: null }));

    expect(q(fixture, '[data-testid="align-opening-balance"]')).toBeNull();

    await fixture.componentInstance.confirm();
    expect(importServiceMock.confirm).toHaveBeenCalledWith('draft-1', false);
  });

  it('should_offer_the_opening_balance_checked_by_default_and_send_it_at_confirmation', async () => {
    const fixture = await setup(importDraft([superU()], { proposedOpeningBalance: 946.67 }));

    const toggle = q<HTMLInputElement>(fixture, '[data-testid="align-opening-balance"]')!;
    expect(toggle.checked).toBe(true);
    expect(text(fixture)).toContain('Aligner le solde initial sur la banque (946,67');

    await fixture.componentInstance.confirm();

    expect(importServiceMock.confirm).toHaveBeenCalledWith('draft-1', true);
  });

  it('should_not_apply_the_opening_balance_when_the_user_turns_it_off', async () => {
    const fixture = await setup(importDraft([superU()], { proposedOpeningBalance: 946.67 }));
    const toggle = q<HTMLInputElement>(fixture, '[data-testid="align-opening-balance"]')!;

    toggle.checked = false;
    toggle.dispatchEvent(new Event('change'));
    fixture.detectChanges();
    await fixture.componentInstance.confirm();

    expect(fixture.componentInstance.alignOpeningBalance()).toBe(false);
    expect(importServiceMock.confirm).toHaveBeenCalledWith('draft-1', false);
  });

  // ---------------------------------------------------------------------
  // A trancher
  // ---------------------------------------------------------------------

  const ambiguous = () =>
    importLine({
      cleanLabel: 'CAFE DU COIN',
      amount: 4.5,
      status: 'DUPLICATE',
      matchCandidateIds: ['tx-1', 'tx-2'],
      matchCandidates: [
        matchedTransaction({ id: 'tx-1', libelle: 'Cafe', date: '2026-09-17', montant: 4.5 }),
        matchedTransaction({
          id: 'tx-2',
          libelle: 'Petit dejeuner',
          date: '2026-09-18',
          montant: 4.5,
        }),
      ],
    });

  it('should_list_each_candidate_with_its_label_date_and_amount', async () => {
    const fixture = await setup(importDraft([ambiguous()]));

    const candidates = qa(fixture, '[data-testid="match-candidate"]');
    expect(candidates).toHaveLength(2);
    expect(candidates[0].textContent).toContain('Cafe');
    expect(candidates[0].textContent).toContain('17 septembre');
    expect(candidates[0].textContent).toContain('-4,50');
    expect(candidates[1].textContent).toContain('Petit dejeuner');
    expect(
      q(fixture, '[data-testid="section-to-decide"] .section-header__count')?.textContent,
    ).toContain('1');
  });

  it('should_match_the_line_with_the_chosen_candidate', async () => {
    const line = ambiguous();
    const fixture = await setup(importDraft([line]));

    click(fixture, '[data-testid="match-candidate"]', 1);
    await settle(fixture);

    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', line.id, {
      matchedTransactionId: 'tx-2',
    });
  });

  it('should_create_a_new_transaction_when_the_user_declines_every_candidate', async () => {
    const line = ambiguous();
    const fixture = await setup(importDraft([line]));

    click(fixture, '[data-testid="create-new"]');
    await settle(fixture);

    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', line.id, {
      clearMatch: true,
    });
  });

  it('should_skip_a_line_to_decide', async () => {
    const line = ambiguous();
    const fixture = await setup(importDraft([line]));

    click(fixture, '[data-testid="skip-line"]');
    await settle(fixture);

    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', line.id, {
      status: 'SKIPPED',
    });
  });

  it('should_offer_to_import_a_probable_duplicate_anyway_or_to_skip_it', async () => {
    const line = importLine({ status: 'DUPLICATE', duplicateTransactionId: 'tx-9' });
    const fixture = await setup(importDraft([line]));

    expect(text(fixture)).toContain('Ressemble à une transaction déjà présente');
    expect(qa(fixture, '[data-testid="match-candidate"]')).toHaveLength(0);

    click(fixture, '[data-testid="import-anyway"]');
    await settle(fixture);
    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', line.id, {
      status: 'READY',
    });

    click(fixture, '[data-testid="skip-line"]');
    await settle(fixture);
    expect(importServiceMock.updateLine).toHaveBeenLastCalledWith('draft-1', line.id, {
      status: 'SKIPPED',
    });
  });

  it('should_show_unreadable_lines_with_their_message_and_let_the_user_skip_them', async () => {
    const line = importLine({
      status: 'NEEDS_REVIEW',
      rawLabel: 'LIGNE ILLISIBLE',
      statusMessage: 'Montant invalide: abc',
    });
    const fixture = await setup(importDraft([line]));

    const row = q(fixture, '[data-testid="unreadable-line"]')!;
    expect(row.textContent).toContain('LIGNE ILLISIBLE');
    expect(row.textContent).toContain('Montant invalide: abc');

    click(fixture, '[data-testid="skip-line"]');
    await settle(fixture);

    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', line.id, {
      status: 'SKIPPED',
    });
  });

  // ---------------------------------------------------------------------
  // Etat vide
  // ---------------------------------------------------------------------

  it('should_show_that_everything_is_resolved_when_no_exception_is_left', async () => {
    const fixture = await setup(
      importDraft([
        superU({ categoryId: 'cat-1', categorySource: 'RULE', categoryName: 'Courses' }),
      ]),
    );

    expect(text(fixture)).toContain('Tout est résolu');
    expect(q(fixture, '[data-testid="section-to-decide"]')).toBeNull();
    expect(q(fixture, '[data-testid="section-unreadable"]')).toBeNull();
    expect(q(fixture, '[data-testid="section-uncategorised"]')).toBeNull();
  });

  it('should_not_show_the_resolved_message_while_exceptions_remain', async () => {
    const fixture = await setup(importDraft([superU()]));

    expect(text(fixture)).not.toContain('Tout est résolu');
  });

  // ---------------------------------------------------------------------
  // Groupes repliables
  // ---------------------------------------------------------------------

  it('should_collapse_every_group_by_default_and_expand_on_demand', async () => {
    const lines = [
      superU({ matchedTransactionId: 'tx-1', matchedTransaction: matchedTransaction() }),
      superU({ categoryId: 'cat-1', categorySource: 'RULE', categoryName: 'Courses' }),
      superU({ categoryId: 'cat-1', categorySource: 'USER', categoryName: 'Courses' }),
      superU({ status: 'SKIPPED', skipReason: 'ALREADY_IMPORTED' }),
      superU({ status: 'SKIPPED' }),
    ];
    const fixture = await setup(importDraft(lines));

    for (const group of ['matched', 'auto', 'user', 'imported', 'skipped']) {
      expect(q(fixture, `[data-testid="group-${group}"] .list-group`)).toBeNull();
      expect(
        q(fixture, `[data-testid="group-${group}"] .group-label`)?.getAttribute('aria-expanded'),
      ).toBe('false');
    }

    click(fixture, '[data-testid="group-matched"] .group-label');
    fixture.detectChanges();
    expect(q(fixture, '[data-testid="group-matched"] .list-group')).not.toBeNull();
    expect(
      q(fixture, '[data-testid="group-matched"] .group-label')?.getAttribute('aria-expanded'),
    ).toBe('true');

    click(fixture, '[data-testid="group-matched"] .group-label');
    fixture.detectChanges();
    expect(q(fixture, '[data-testid="group-matched"] .list-group')).toBeNull();
  });

  it('should_show_the_group_counts_in_the_group_headers', async () => {
    const fixture = await setup(
      importDraft([
        superU({ status: 'SKIPPED', skipReason: 'ALREADY_IMPORTED' }),
        superU({ status: 'SKIPPED', skipReason: 'ALREADY_IMPORTED' }),
      ]),
    );

    expect(q(fixture, '[data-testid="group-imported"] .group-label__count')?.textContent).toContain(
      '2',
    );
  });

  it('should_describe_a_matched_line_and_undo_the_match', async () => {
    const line = superU({
      matchedTransactionId: 'tx-1',
      matchedTransaction: matchedTransaction({ libelle: 'Tabac', date: '2026-09-18' }),
    });
    const fixture = await setup(importDraft([line]));
    click(fixture, '[data-testid="group-matched"] .group-label');
    fixture.detectChanges();

    expect(q(fixture, '[data-testid="matched-line"]')?.textContent).toContain(
      'Rapprochée de « Tabac » du 18 septembre',
    );

    click(fixture, '[data-testid="undo-match"]');
    await settle(fixture);

    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', line.id, {
      clearMatch: true,
    });
  });

  it('should_say_so_when_the_matched_transaction_no_longer_exists', async () => {
    const fixture = await setup(
      importDraft([superU({ matchedTransactionId: 'tx-gone', matchedTransaction: null })]),
    );
    click(fixture, '[data-testid="group-matched"] .group-label');
    fixture.detectChanges();

    expect(q(fixture, '[data-testid="matched-line"]')?.textContent).toContain("n'existe plus");
    expect(q(fixture, '[data-testid="undo-match"]')).not.toBeNull();
  });

  it('should_show_the_origin_of_an_automatic_category_and_let_the_user_change_it', async () => {
    const rule = superU({ categoryId: 'cat-1', categorySource: 'RULE', categoryName: 'Courses' });
    const history = superU({
      categoryId: 'cat-2',
      categorySource: 'HISTORY',
      categoryName: 'Loisirs',
    });
    const fixture = await setup(importDraft([rule, history]));
    click(fixture, '[data-testid="group-auto"] .group-label');
    fixture.detectChanges();

    const rows = qa(fixture, '[data-testid="auto-line"]');
    expect(rows[0].textContent).toContain('Courses');
    expect(rows[0].textContent).toContain('Règle');
    expect(rows[0].textContent).toContain('🛒');
    expect(rows[1].textContent).toContain('Historique');

    rows[1].click();
    fixture.detectChanges();
    expect(q(fixture, 'app-category-select')).not.toBeNull();
    await fixture.componentInstance.onCategorySelected('cat-1');
    await settle(fixture);

    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', history.id, {
      categoryId: 'cat-1',
    });
  });

  it('should_let_the_user_change_a_category_picked_during_the_review', async () => {
    const line = superU({ categoryId: 'cat-1', categorySource: 'USER', categoryName: 'Courses' });
    const fixture = await setup(importDraft([line]));
    click(fixture, '[data-testid="group-user"] .group-label');
    fixture.detectChanges();

    expect(q(fixture, '[data-testid="user-line"]')?.textContent).toContain('Courses');

    click(fixture, '[data-testid="user-line"]');
    fixture.detectChanges();

    expect(fixture.componentInstance.categoryTarget()?.lineId).toBe(line.id);
  });

  it('should_show_already_imported_lines_read_only', async () => {
    const fixture = await setup(
      importDraft([
        superU({ status: 'SKIPPED', skipReason: 'ALREADY_IMPORTED', cleanLabel: 'FRAIS' }),
      ]),
    );
    click(fixture, '[data-testid="group-imported"] .group-label');
    fixture.detectChanges();

    const row = q(fixture, '[data-testid="imported-line"]')!;
    expect(row.textContent).toContain('FRAIS');
    expect(row.querySelector('button')).toBeNull();
  });

  it('should_restore_a_line_skipped_by_the_user', async () => {
    const line = superU({ status: 'SKIPPED' });
    const fixture = await setup(importDraft([line]));
    click(fixture, '[data-testid="group-skipped"] .group-label');
    fixture.detectChanges();

    click(fixture, '[data-testid="restore-line"]');
    await settle(fixture);

    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', line.id, {
      status: 'READY',
    });
  });

  it('should_not_offer_to_restore_an_unreadable_skipped_line', async () => {
    const line = superU({ status: 'SKIPPED', statusMessage: 'Montant invalide: abc' });
    const fixture = await setup(importDraft([line]));
    click(fixture, '[data-testid="group-skipped"] .group-label');
    fixture.detectChanges();

    expect(q(fixture, '[data-testid="restore-line"]')).toBeNull();
    expect(q(fixture, '[data-testid="skipped-line"]')?.textContent).toContain(
      'Montant invalide: abc',
    );
  });

  // ---------------------------------------------------------------------
  // Erreurs d'action
  // ---------------------------------------------------------------------

  it('should_report_a_failed_line_update_with_a_toast_and_keep_the_draft', async () => {
    importServiceMock.updateLine.mockReturnValue(throwError(() => ({ status: 500 })));
    const fixture = await setup(importDraft([ambiguous()]));

    click(fixture, '[data-testid="skip-line"]');
    await settle(fixture);

    expect(toastMock.error).toHaveBeenCalledWith('Erreur API');
    expect(apiErrorMock.label).toHaveBeenCalledWith(
      { status: 500 },
      "Cette modification n'a pas pu être enregistrée.",
    );
    expect(importServiceMock.getDraft).toHaveBeenCalledTimes(1);
    expect(fixture.componentInstance.busy()).toBe(false);
  });

  it('should_ignore_a_second_action_while_one_is_in_progress', async () => {
    const pending = new Subject<ImportDraftLine>();
    importServiceMock.updateLine.mockReturnValue(pending);
    const line = ambiguous();
    const fixture = await setup(importDraft([line]));

    const first = fixture.componentInstance.skip(line);
    const second = fixture.componentInstance.createNew(line);
    pending.next(importLine());
    pending.complete();
    await Promise.all([first, second]);

    expect(importServiceMock.updateLine).toHaveBeenCalledTimes(1);
  });

  it('should_do_nothing_when_updating_a_line_without_a_loaded_draft', async () => {
    importServiceMock.getDraft.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup(null);

    await fixture.componentInstance.skip(importLine());

    expect(importServiceMock.updateLine).not.toHaveBeenCalled();
  });

  // ---------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------

  it('should_go_back_to_the_transactions_from_the_back_button', async () => {
    const fixture = await setup(importDraft([superU()]));

    click(fixture, '.page-header__back');

    expect(navigateSpy).toHaveBeenCalledWith(['/transactions']);
  });
});
