import { TestBed } from '@angular/core/testing';
import { ActivatedRoute, Router, convertToParamMap, provideRouter } from '@angular/router';
import { of, throwError } from 'rxjs';

import { ImportStart } from './import-start';
import { AccountService } from '../../../core/services/account';
import { ApiErrorService } from '../../../core/services/api-error';
import { ImportService } from '../../../core/services/import';
import { Account, AccountType } from '../../../core/models/account.model';
import { ImportDraftSummary } from '../../../core/models/import.model';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';
import { importDetection, importDraft } from '../../../../testing/import-fixtures';

function account(overrides: Partial<Account> = {}): Account {
  return {
    id: 'acc-1',
    nom: 'Courant',
    type: AccountType.COURANT,
    soldeInitial: 0,
    solde: 100,
    icone: '🏦',
    couleur: '#000000',
    isDefault: false,
    actif: true,
    currency: 'EUR',
    bankCode: '',
    bankName: null,
    bankCountry: null,
    bankBrandColor: null,
    bankLogoUrl: null,
    bankCustomName: null,
    bankCustomLogo: null,
    ...overrides,
  };
}

function draftSummary(overrides: Partial<ImportDraftSummary> = {}): ImportDraftSummary {
  return {
    id: 'draft-9',
    accountId: 'acc-1',
    accountName: 'Courant',
    status: 'PENDING',
    fileName: 'releve.csv',
    totalLines: 5,
    readyCount: 5,
    reviewCount: 0,
    duplicateCount: 0,
    skippedCount: 0,
    createdAt: '2026-10-01T10:00:00',
    expiresAt: '2026-10-08T10:00:00',
    ...overrides,
  };
}

describe('ImportStart', () => {
  let importServiceMock: {
    detect: ReturnType<typeof vi.fn>;
    upload: ReturnType<typeof vi.fn>;
    listDrafts: ReturnType<typeof vi.fn>;
  };
  let accountServiceMock: { getAll: ReturnType<typeof vi.fn> };
  let apiErrorMock: { label: ReturnType<typeof vi.fn> };
  let navigateSpy: ReturnType<typeof vi.spyOn>;

  const file = new File(['a;b'], 'releve.csv');
  const fileEvent = (selected?: File) =>
    ({ target: { files: selected ? [selected] : [], value: 'x' } }) as unknown as Event;

  beforeEach(() => {
    importServiceMock = {
      detect: vi.fn().mockReturnValue(of(importDetection())),
      upload: vi.fn().mockReturnValue(of(importDraft([], { id: 'draft-1' }))),
      listDrafts: vi.fn().mockReturnValue(of([draftSummary()])),
    };
    accountServiceMock = {
      getAll: vi
        .fn()
        .mockReturnValue(
          of([
            account({ id: 'acc-1', nom: 'Courant', isDefault: true }),
            account({ id: 'acc-2', nom: 'Livret', icone: '💰', statementAccountSuffix: '1596' }),
          ]),
        ),
    };
    apiErrorMock = { label: vi.fn().mockReturnValue('Erreur API') };
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const setup = (queryParams: Record<string, string> = {}) => {
    TestBed.configureTestingModule({
      imports: [ImportStart],
      providers: [
        provideTranslocoTesting(),
        provideRouter([]),
        {
          provide: ActivatedRoute,
          useValue: { snapshot: { queryParamMap: convertToParamMap(queryParams) } },
        },
        { provide: ImportService, useValue: importServiceMock },
        { provide: AccountService, useValue: accountServiceMock },
        { provide: ApiErrorService, useValue: apiErrorMock },
      ],
    });
    navigateSpy = vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true);
    const fixture = TestBed.createComponent(ImportStart);
    fixture.detectChanges();
    return fixture;
  };

  const chooseFile = async (fixture: ReturnType<typeof setup>, selected: File = file) => {
    await fixture.componentInstance.onFileSelected(fileEvent(selected));
    fixture.detectChanges();
  };

  const el = (fixture: ReturnType<typeof setup>) => fixture.nativeElement as HTMLElement;

  it('should_show_only_the_file_choice_before_a_file_is_selected', async () => {
    const fixture = setup();
    await fixture.whenStable();

    expect(el(fixture).querySelector('.start__file')).not.toBeNull();
    expect(el(fixture).querySelector('[role="radiogroup"]')).toBeNull();
    expect(importServiceMock.detect).not.toHaveBeenCalled();
  });

  it('should_ignore_a_file_selection_without_a_file', async () => {
    const fixture = setup();
    await fixture.componentInstance.onFileSelected(fileEvent());

    expect(importServiceMock.detect).not.toHaveBeenCalled();
    expect(fixture.componentInstance.file()).toBeNull();
  });

  it('should_preselect_the_suggested_account_when_the_api_recognises_one', async () => {
    importServiceMock.detect.mockReturnValue(of(importDetection({ suggestedAccountId: 'acc-2' })));
    const fixture = setup();

    await chooseFile(fixture);

    expect(importServiceMock.detect).toHaveBeenCalledWith(file);
    expect(fixture.componentInstance.accountId()).toBe('acc-2');
    expect(el(fixture).textContent).toContain('Reconnu : Société Générale · compte …1596');
    const selected = el(fixture).querySelector('input[type="radio"]:checked');
    expect(selected?.closest('label')?.textContent).toContain('Livret');
  });

  it('should_show_the_account_suffix_in_the_account_rows_when_known', async () => {
    const fixture = setup();

    await chooseFile(fixture);

    const rows = Array.from(el(fixture).querySelectorAll('label.list-row'));
    expect(rows).toHaveLength(2);
    expect(rows[0].textContent).not.toContain('…');
    expect(rows[1].textContent).toContain('…1596');
  });

  it('should_prefer_the_suggestion_over_the_account_of_the_url', async () => {
    importServiceMock.detect.mockReturnValue(of(importDetection({ suggestedAccountId: 'acc-2' })));
    const fixture = setup({ accountId: 'acc-1' });

    await chooseFile(fixture);

    expect(fixture.componentInstance.accountId()).toBe('acc-2');
  });

  it('should_fall_back_to_the_account_of_the_url_when_nothing_is_suggested', async () => {
    const fixture = setup({ accountId: 'acc-2' });

    await chooseFile(fixture);

    expect(fixture.componentInstance.accountId()).toBe('acc-2');
  });

  it('should_ignore_a_suggested_or_url_account_the_user_does_not_have', async () => {
    importServiceMock.detect.mockReturnValue(of(importDetection({ suggestedAccountId: 'ghost' })));
    const fixture = setup({ accountId: 'other-ghost' });

    await chooseFile(fixture);

    expect(fixture.componentInstance.accountId()).toBeNull();
  });

  it('should_require_an_explicit_account_and_never_preselect_the_default_one', async () => {
    const fixture = setup();

    await chooseFile(fixture);

    expect(fixture.componentInstance.accountId()).toBeNull();
    expect(fixture.componentInstance.canSubmit()).toBe(false);
    const submit = el(fixture).querySelector('.start__submit') as HTMLButtonElement;
    expect(submit.disabled).toBe(true);
    expect(el(fixture).textContent).toContain('Veuillez sélectionner un compte.');
  });

  it('should_enable_the_analysis_once_an_account_is_chosen_by_a_click', async () => {
    const fixture = setup();
    await chooseFile(fixture);

    (el(fixture).querySelectorAll('input[type="radio"]')[0] as HTMLInputElement).click();
    fixture.detectChanges();

    expect(fixture.componentInstance.accountId()).toBe('acc-1');
    expect((el(fixture).querySelector('.start__submit') as HTMLButtonElement).disabled).toBe(false);
  });

  it('should_upload_the_file_on_the_chosen_account_then_open_the_review', async () => {
    importServiceMock.detect.mockReturnValue(of(importDetection({ suggestedAccountId: 'acc-2' })));
    const fixture = setup();
    await chooseFile(fixture);

    await fixture.componentInstance.analyse();

    expect(importServiceMock.upload).toHaveBeenCalledWith(file, 'acc-2');
    expect(navigateSpy).toHaveBeenCalledWith(['/transactions/import/review', 'draft-1']);
  });

  it('should_not_upload_when_no_account_is_chosen', async () => {
    const fixture = setup();
    await chooseFile(fixture);

    await fixture.componentInstance.analyse();

    expect(importServiceMock.upload).not.toHaveBeenCalled();
  });

  it('should_offer_to_resume_the_draft_in_progress_when_the_account_already_has_one', async () => {
    importServiceMock.upload.mockReturnValue(throwError(() => ({ status: 409 })));
    importServiceMock.detect.mockReturnValue(of(importDetection({ suggestedAccountId: 'acc-1' })));
    const fixture = setup();
    await chooseFile(fixture);

    await fixture.componentInstance.analyse();
    fixture.detectChanges();

    expect(fixture.componentInstance.conflict()).toEqual({ draftId: 'draft-9' });
    expect(fixture.componentInstance.uploading()).toBe(false);
    const link = el(fixture).querySelector('.start__link') as HTMLAnchorElement;
    expect(link.getAttribute('href')).toBe('/transactions/import/review/draft-9');
    expect(link.textContent).toContain('Reprendre le brouillon en cours');
  });

  it('should_show_the_conflict_without_link_when_the_draft_cannot_be_found', async () => {
    importServiceMock.upload.mockReturnValue(throwError(() => ({ status: 409 })));
    importServiceMock.listDrafts.mockReturnValue(of([draftSummary({ accountId: 'acc-2' })]));
    importServiceMock.detect.mockReturnValue(of(importDetection({ suggestedAccountId: 'acc-1' })));
    const fixture = setup();
    await chooseFile(fixture);

    await fixture.componentInstance.analyse();
    fixture.detectChanges();

    expect(fixture.componentInstance.conflict()).toEqual({ draftId: null });
    expect(el(fixture).querySelector('.start__link')).toBeNull();
    expect(el(fixture).textContent).toContain("Un brouillon d'import est déjà en cours");
  });

  it('should_show_the_conflict_without_link_when_listing_drafts_fails', async () => {
    importServiceMock.upload.mockReturnValue(throwError(() => ({ status: 409 })));
    importServiceMock.listDrafts.mockReturnValue(throwError(() => new Error('500')));
    importServiceMock.detect.mockReturnValue(of(importDetection({ suggestedAccountId: 'acc-1' })));
    const fixture = setup();
    await chooseFile(fixture);

    await fixture.componentInstance.analyse();

    expect(fixture.componentInstance.conflict()).toEqual({ draftId: null });
  });

  it('should_clear_the_conflict_when_another_account_is_chosen', async () => {
    importServiceMock.upload.mockReturnValue(throwError(() => ({ status: 409 })));
    importServiceMock.detect.mockReturnValue(of(importDetection({ suggestedAccountId: 'acc-1' })));
    const fixture = setup();
    await chooseFile(fixture);
    await fixture.componentInstance.analyse();

    fixture.componentInstance.selectAccount('acc-2');

    expect(fixture.componentInstance.conflict()).toBeNull();
    expect(fixture.componentInstance.accountId()).toBe('acc-2');
  });

  it('should_open_the_mapping_when_the_upload_does_not_recognise_the_format', async () => {
    importServiceMock.upload.mockReturnValue(throwError(() => ({ status: 422 })));
    importServiceMock.detect.mockReturnValue(of(importDetection({ suggestedAccountId: 'acc-1' })));
    const fixture = setup();
    await chooseFile(fixture);

    await fixture.componentInstance.analyse();

    expect(navigateSpy).toHaveBeenCalledWith(['/settings/import/mapping'], {
      state: { file, accountId: 'acc-1' },
    });
  });

  it('should_show_the_api_error_label_when_the_upload_fails', async () => {
    importServiceMock.upload.mockReturnValue(throwError(() => ({ status: 500 })));
    importServiceMock.detect.mockReturnValue(of(importDetection({ suggestedAccountId: 'acc-1' })));
    const fixture = setup();
    await chooseFile(fixture);

    await fixture.componentInstance.analyse();
    fixture.detectChanges();

    expect(apiErrorMock.label).toHaveBeenCalledWith(
      { status: 500 },
      "Erreur lors de l'import. Veuillez réessayer.",
    );
    expect(fixture.componentInstance.error()).toBe('Erreur API');
    expect(fixture.componentInstance.uploading()).toBe(false);
    expect(el(fixture).querySelector('[role="alert"]')?.textContent).toContain('Erreur API');
  });

  it('should_offer_the_manual_mapping_when_the_format_is_not_recognised', async () => {
    importServiceMock.detect.mockReturnValue(
      of(importDetection({ recognized: false, profileName: null, accountSuffix: null })),
    );
    const fixture = setup({ accountId: 'acc-2' });

    await chooseFile(fixture);

    expect(fixture.componentInstance.recognized()).toBe(false);
    expect(el(fixture).textContent).toContain("Le format de ce fichier n'est pas reconnu");
    expect(el(fixture).textContent).not.toContain('Analyser le relevé');

    fixture.componentInstance.openMapping();

    expect(navigateSpy).toHaveBeenCalledWith(['/settings/import/mapping'], {
      state: { file, accountId: 'acc-2' },
    });
  });

  it('should_not_open_the_mapping_without_an_account', async () => {
    importServiceMock.detect.mockReturnValue(of(importDetection({ recognized: false })));
    const fixture = setup();
    await chooseFile(fixture);

    fixture.componentInstance.openMapping();
    fixture.detectChanges();

    expect(navigateSpy).not.toHaveBeenCalled();
    expect((el(fixture).querySelector('.start__submit') as HTMLButtonElement).disabled).toBe(true);
  });

  it('should_show_the_recognised_profile_without_suffix_when_the_file_has_no_account_number', async () => {
    importServiceMock.detect.mockReturnValue(of(importDetection({ accountSuffix: null })));
    const fixture = setup();

    await chooseFile(fixture);

    expect(el(fixture).textContent).toContain('Reconnu : Société Générale');
    expect(el(fixture).textContent).not.toContain('compte …');
  });

  it('should_drop_the_file_and_show_an_error_when_detection_fails', async () => {
    importServiceMock.detect.mockReturnValue(throwError(() => ({ status: 400 })));
    const fixture = setup();

    await chooseFile(fixture);

    expect(fixture.componentInstance.file()).toBeNull();
    expect(fixture.componentInstance.detection()).toBeNull();
    expect(fixture.componentInstance.error()).toBe('Erreur API');
    expect(fixture.componentInstance.detecting()).toBe(false);
  });

  it('should_show_an_error_when_accounts_cannot_be_loaded', async () => {
    accountServiceMock.getAll.mockReturnValue(throwError(() => new Error('500')));
    const fixture = setup();
    await fixture.whenStable();

    expect(fixture.componentInstance.error()).toBe('Impossible de charger vos comptes.');
    expect(fixture.componentInstance.accountsLoading()).toBe(false);
  });

  it('should_show_an_empty_message_when_the_user_has_no_account', async () => {
    accountServiceMock.getAll.mockReturnValue(of([]));
    const fixture = setup();

    await chooseFile(fixture);

    expect(el(fixture).textContent).toContain('Aucun compte disponible.');
    expect(el(fixture).querySelector('[role="radiogroup"]')).toBeNull();
  });

  it('should_go_back_to_the_transactions', () => {
    const fixture = setup();

    fixture.componentInstance.goBack();

    expect(navigateSpy).toHaveBeenCalledWith(['/transactions']);
  });
});
