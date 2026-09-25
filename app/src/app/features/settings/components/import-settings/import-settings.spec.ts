import { TestBed } from '@angular/core/testing';
import { ActivatedRoute, provideRouter, Router } from '@angular/router';
import { convertToParamMap } from '@angular/router';
import { of, throwError } from 'rxjs';

import { ImportSettings } from './import-settings';
import { AccountService } from '../../../../core/services/account';
import { ImportService } from '../../../../core/services/import';
import { CategoryService } from '../../../../core/services/category';
import { CategoryRuleService } from '../../../../core/services/category-rule';
import { ApiErrorService } from '../../../../core/services/api-error';
import { Account, AccountType } from '../../../../core/models/account.model';
import { Category } from '../../../../core/models/category.model';
import {
  CategoryRule,
  ImportDraftSummary,
  ImportHistoryEntry,
  ImportProfile,
} from '../../../../core/models/import.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

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
    id: 'draft-1',
    accountId: 'acc-1',
    accountName: 'Courant',
    status: 'PENDING',
    fileName: 'releve.csv',
    totalLines: 5,
    readyCount: 5,
    reviewCount: 0,
    duplicateCount: 0,
    skippedCount: 0,
    createdAt: '2026-03-12T10:00:00',
    expiresAt: '2026-03-19T10:00:00',
    ...overrides,
  };
}

function historyEntry(overrides: Partial<ImportHistoryEntry> = {}): ImportHistoryEntry {
  return {
    id: 'hist-1',
    accountId: 'acc-1',
    accountName: 'Courant',
    transactionCount: 3,
    fileName: 'releve.csv',
    importedAt: '2026-03-01T10:00:00',
    ...overrides,
  };
}

function categoryRule(overrides: Partial<CategoryRule> = {}): CategoryRule {
  return {
    id: 'rule-1',
    pattern: 'CARREFOUR',
    categoryId: 'cat-1',
    categoryName: 'Courses',
    categoryIcon: '🛒',
    createdAt: '2026-03-01T10:00:00',
    ...overrides,
  };
}

function importProfile(overrides: Partial<ImportProfile> = {}): ImportProfile {
  return {
    id: 'profile-1',
    bankCode: 'BOA',
    name: 'Bank of Africa',
    source: 'CUSTOM',
    editable: true,
    ...overrides,
  };
}

describe('ImportSettings', () => {
  let accountServiceMock: { getAll: ReturnType<typeof vi.fn>; refreshTrigger: ReturnType<typeof vi.fn> };
  let importServiceMock: {
    refreshTrigger: ReturnType<typeof vi.fn>;
    listDrafts: ReturnType<typeof vi.fn>;
    listHistory: ReturnType<typeof vi.fn>;
    getProfiles: ReturnType<typeof vi.fn>;
    deleteDraft: ReturnType<typeof vi.fn>;
    deleteProfile: ReturnType<typeof vi.fn>;
    upload: ReturnType<typeof vi.fn>;
  };
  let categoryServiceMock: { getAll: ReturnType<typeof vi.fn> };
  let categoryRuleServiceMock: {
    refreshTrigger: ReturnType<typeof vi.fn>;
    getAll: ReturnType<typeof vi.fn>;
    create: ReturnType<typeof vi.fn>;
    update: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
  };
  let apiErrorServiceMock: { label: ReturnType<typeof vi.fn> };
  let routerMock: { navigate: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    accountServiceMock = {
      getAll: vi.fn().mockReturnValue(of([account({ isDefault: true }), account({ id: 'acc-2' })])),
      refreshTrigger: vi.fn().mockReturnValue(0),
    };
    importServiceMock = {
      refreshTrigger: vi.fn().mockReturnValue(0),
      listDrafts: vi.fn().mockReturnValue(of([draftSummary()])),
      listHistory: vi.fn().mockReturnValue(of({ content: [historyEntry()] })),
      getProfiles: vi.fn().mockReturnValue(of([importProfile()])),
      deleteDraft: vi.fn().mockReturnValue(of(undefined)),
      deleteProfile: vi.fn().mockReturnValue(of(undefined)),
      upload: vi.fn().mockReturnValue(of(draftSummary())),
    };
    categoryServiceMock = { getAll: vi.fn().mockReturnValue(of<Category[]>([])) };
    categoryRuleServiceMock = {
      refreshTrigger: vi.fn().mockReturnValue(0),
      getAll: vi.fn().mockReturnValue(of([categoryRule()])),
      create: vi.fn().mockReturnValue(of(categoryRule())),
      update: vi.fn().mockReturnValue(of(categoryRule())),
      delete: vi.fn().mockReturnValue(of(undefined)),
    };
    apiErrorServiceMock = { label: vi.fn().mockReturnValue('Erreur API') };
  });

  const setup = async (queryParams: Record<string, string> = {}) => {
    TestBed.configureTestingModule({
      imports: [ImportSettings],
      providers: [
        provideTranslocoTesting(),
        provideRouter([]),
        {
          provide: ActivatedRoute,
          useValue: { queryParamMap: of(convertToParamMap(queryParams)) },
        },
        { provide: AccountService, useValue: accountServiceMock },
        { provide: ImportService, useValue: importServiceMock },
        { provide: CategoryService, useValue: categoryServiceMock },
        { provide: CategoryRuleService, useValue: categoryRuleServiceMock },
        { provide: ApiErrorService, useValue: apiErrorServiceMock },
      ],
    });

    routerMock = { navigate: vi.spyOn(TestBed.inject(Router), 'navigate').mockResolvedValue(true) };

    const fixture = TestBed.createComponent(ImportSettings);
    fixture.detectChanges();
    await fixture.whenStable();
    fixture.detectChanges();
    return fixture;
  };

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('should_create_the_component', async () => {
    const fixture = await setup();
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_select_default_account_when_loaded', async () => {
    const fixture = await setup();
    expect(fixture.componentInstance.selectedAccountId()).toBe('acc-1');
  });

  it('should_select_first_account_when_no_default', async () => {
    accountServiceMock = {
      getAll: vi.fn().mockReturnValue(of([account({ id: 'acc-3', isDefault: false })])),
      refreshTrigger: vi.fn().mockReturnValue(0),
    };
    TestBed.configureTestingModule({
      imports: [ImportSettings],
      providers: [
        provideTranslocoTesting(),
        provideRouter([]),
        { provide: ActivatedRoute, useValue: { queryParamMap: of(convertToParamMap({})) } },
        { provide: AccountService, useValue: accountServiceMock },
        {
          provide: ImportService,
          useValue: {
            refreshTrigger: vi.fn().mockReturnValue(0),
            listDrafts: vi.fn().mockReturnValue(of([])),
            listHistory: vi.fn().mockReturnValue(of({ content: [] })),
            getProfiles: vi.fn().mockReturnValue(of([])),
          },
        },
        { provide: CategoryService, useValue: { getAll: vi.fn().mockReturnValue(of([])) } },
        {
          provide: CategoryRuleService,
          useValue: { refreshTrigger: vi.fn().mockReturnValue(0), getAll: vi.fn().mockReturnValue(of([])) },
        },
        { provide: ApiErrorService, useValue: { label: vi.fn() } },
      ],
    });
    const fixture = TestBed.createComponent(ImportSettings);
    fixture.detectChanges();
    await fixture.whenStable();

    expect(fixture.componentInstance.selectedAccountId()).toBe('acc-3');
  });

  it('should_keep_query_param_account_when_provided', async () => {
    const fixture = await setup({ accountId: 'acc-2' });
    expect(fixture.componentInstance.selectedAccountId()).toBe('acc-2');
  });

  it('should_reset_drafts_when_load_fails', async () => {
    importServiceMock.listDrafts.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup();
    expect(fixture.componentInstance.drafts()).toEqual([]);
  });

  it('should_reset_history_when_load_fails', async () => {
    importServiceMock.listHistory.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup();
    expect(fixture.componentInstance.history()).toEqual([]);
  });

  it('should_reset_profiles_when_load_fails', async () => {
    importServiceMock.getProfiles.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup();
    expect(fixture.componentInstance.profiles()).toEqual([]);
  });

  it('should_render_french_page_title', async () => {
    const fixture = await setup();
    expect(fixture.nativeElement.querySelector('.import-title').textContent).toContain('Import CSV');
  });

  it('should_render_profile_source_label', async () => {
    const fixture = await setup();
    const badge = fixture.nativeElement.querySelector('.profile-list__badge');
    expect(badge.textContent).toContain('Personnalisé');
  });

  it('should_render_registry_profile_source_label', async () => {
    importServiceMock.getProfiles.mockReturnValue(of([importProfile({ source: 'REGISTRY' })]));
    const fixture = await setup();
    const badge = fixture.nativeElement.querySelector('.profile-list__badge');
    expect(badge.textContent).toContain('Pré-configuré');
  });

  it('should_navigate_to_review_when_resuming_draft', async () => {
    const fixture = await setup();
    fixture.componentInstance.resumeDraft('draft-1');
    expect(routerMock.navigate).toHaveBeenCalledWith(['/settings/import/review', 'draft-1']);
  });

  it('should_delete_draft_and_clear_deleting_id', async () => {
    const fixture = await setup();
    await fixture.componentInstance.deleteDraft('draft-1');
    expect(importServiceMock.deleteDraft).toHaveBeenCalledWith('draft-1');
    expect(fixture.componentInstance.deletingDraftId()).toBeNull();
  });

  it('should_clear_deleting_id_when_draft_deletion_fails', async () => {
    importServiceMock.deleteDraft.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup();
    await fixture.componentInstance.deleteDraft('draft-1');
    expect(fixture.componentInstance.deletingDraftId()).toBeNull();
  });

  it('should_delete_profile_and_clear_deleting_id', async () => {
    const fixture = await setup();
    await fixture.componentInstance.deleteProfile('profile-1');
    expect(importServiceMock.deleteProfile).toHaveBeenCalledWith('profile-1');
    expect(fixture.componentInstance.deletingProfileId()).toBeNull();
  });

  it('should_clear_deleting_id_when_profile_deletion_fails', async () => {
    importServiceMock.deleteProfile.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup();
    await fixture.componentInstance.deleteProfile('profile-1');
    expect(fixture.componentInstance.deletingProfileId()).toBeNull();
  });

  it('should_delete_rule', async () => {
    const fixture = await setup();
    await fixture.componentInstance.deleteRule('rule-1');
    expect(categoryRuleServiceMock.delete).toHaveBeenCalledWith('rule-1');
  });

  it('should_not_throw_when_rule_deletion_fails', async () => {
    categoryRuleServiceMock.delete.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup();
    await expect(fixture.componentInstance.deleteRule('rule-1')).resolves.toBeUndefined();
  });

  it('should_open_add_rule_form_with_empty_fields', async () => {
    const fixture = await setup();
    fixture.componentInstance.openAddRuleForm();
    expect(fixture.componentInstance.showRuleForm()).toBe(true);
    expect(fixture.componentInstance.editingRuleId()).toBeNull();
    expect(fixture.componentInstance.ruleFormPattern()).toBe('');
  });

  it('should_open_edit_rule_form_with_prefilled_fields', async () => {
    const fixture = await setup();
    fixture.componentInstance.openEditRuleForm(categoryRule());
    expect(fixture.componentInstance.editingRuleId()).toBe('rule-1');
    expect(fixture.componentInstance.ruleFormPattern()).toBe('CARREFOUR');
    expect(fixture.componentInstance.ruleFormCategoryId()).toBe('cat-1');
  });

  it('should_cancel_rule_form', async () => {
    const fixture = await setup();
    fixture.componentInstance.openEditRuleForm(categoryRule());
    fixture.componentInstance.cancelRuleForm();
    expect(fixture.componentInstance.showRuleForm()).toBe(false);
    expect(fixture.componentInstance.editingRuleId()).toBeNull();
  });

  it('should_set_translated_error_when_pattern_missing', async () => {
    const fixture = await setup();
    fixture.componentInstance.ruleFormCategoryId.set('cat-1');
    await fixture.componentInstance.saveRule();
    expect(fixture.componentInstance.ruleFormError()).toBe('Le pattern est requis.');
    expect(categoryRuleServiceMock.create).not.toHaveBeenCalled();
  });

  it('should_set_translated_error_when_category_missing', async () => {
    const fixture = await setup();
    fixture.componentInstance.ruleFormPattern.set('CARREFOUR');
    await fixture.componentInstance.saveRule();
    expect(fixture.componentInstance.ruleFormError()).toBe('La catégorie est requise.');
    expect(categoryRuleServiceMock.create).not.toHaveBeenCalled();
  });

  it('should_create_rule_when_no_editing_id', async () => {
    const fixture = await setup();
    fixture.componentInstance.ruleFormPattern.set('CARREFOUR');
    fixture.componentInstance.ruleFormCategoryId.set('cat-1');
    await fixture.componentInstance.saveRule();
    expect(categoryRuleServiceMock.create).toHaveBeenCalledWith({
      pattern: 'CARREFOUR',
      categoryId: 'cat-1',
    });
    expect(fixture.componentInstance.showRuleForm()).toBe(false);
  });

  it('should_update_rule_when_editing_id_set', async () => {
    const fixture = await setup();
    fixture.componentInstance.openEditRuleForm(categoryRule());
    await fixture.componentInstance.saveRule();
    expect(categoryRuleServiceMock.update).toHaveBeenCalledWith('rule-1', {
      pattern: 'CARREFOUR',
      categoryId: 'cat-1',
    });
  });

  it('should_set_translated_error_when_rule_save_fails', async () => {
    categoryRuleServiceMock.create.mockReturnValue(throwError(() => new Error('500')));
    const fixture = await setup();
    fixture.componentInstance.ruleFormPattern.set('CARREFOUR');
    fixture.componentInstance.ruleFormCategoryId.set('cat-1');
    await fixture.componentInstance.saveRule();
    expect(fixture.componentInstance.ruleFormError()).toBe('Erreur lors de la sauvegarde de la règle.');
    expect(fixture.componentInstance.ruleFormSaving()).toBe(false);
  });

  it('should_change_selected_account', async () => {
    const fixture = await setup();
    fixture.componentInstance.onAccountChange('acc-2');
    expect(fixture.componentInstance.selectedAccountId()).toBe('acc-2');
  });

  it('should_ignore_file_selection_when_no_file_chosen', async () => {
    const fixture = await setup();
    const inputValue = { files: [] as File[], value: 'x' };
    fixture.componentInstance.onFileSelected({ target: inputValue } as unknown as Event);
    expect(importServiceMock.upload).not.toHaveBeenCalled();
    expect(inputValue.value).toBe('');
  });

  it('should_set_translated_error_when_no_account_selected_for_upload', async () => {
    const fixture = await setup();
    fixture.componentInstance.selectedAccountId.set('');
    const file = new File(['a'], 'releve.csv');
    fixture.componentInstance.onFileSelected({ target: { files: [file], value: '' } } as unknown as Event);
    await fixture.whenStable();
    expect(fixture.componentInstance.uploadError()).toBe('Veuillez sélectionner un compte.');
    expect(importServiceMock.upload).not.toHaveBeenCalled();
  });

  it('should_navigate_to_review_when_upload_succeeds', async () => {
    const fixture = await setup();
    const file = new File(['a'], 'releve.csv');
    fixture.componentInstance.onFileSelected({ target: { files: [file], value: '' } } as unknown as Event);
    await fixture.whenStable();
    expect(routerMock.navigate).toHaveBeenCalledWith(['/settings/import/review', 'draft-1']);
  });

  it('should_set_translated_error_when_draft_already_exists', async () => {
    importServiceMock.upload.mockReturnValue(throwError(() => ({ status: 409 })));
    const fixture = await setup();
    const file = new File(['a'], 'releve.csv');
    fixture.componentInstance.onFileSelected({ target: { files: [file], value: '' } } as unknown as Event);
    await fixture.whenStable();
    expect(fixture.componentInstance.uploadError()).toBe(
      "Un brouillon d'import existe déjà pour ce compte. Supprimez-le avant d'en créer un nouveau.",
    );
    expect(fixture.componentInstance.uploading()).toBe(false);
  });

  it('should_navigate_to_mapping_when_format_not_recognized', async () => {
    importServiceMock.upload.mockReturnValue(throwError(() => ({ status: 422 })));
    const fixture = await setup();
    const file = new File(['a'], 'releve.csv');
    fixture.componentInstance.onFileSelected({ target: { files: [file], value: '' } } as unknown as Event);
    await fixture.whenStable();
    expect(routerMock.navigate).toHaveBeenCalledWith(['/settings/import/mapping'], {
      state: { file, accountId: 'acc-1' },
    });
    expect(fixture.componentInstance.uploading()).toBe(true);
  });

  it('should_set_api_error_label_when_upload_fails_with_other_status', async () => {
    importServiceMock.upload.mockReturnValue(throwError(() => ({ status: 500 })));
    const fixture = await setup();
    const file = new File(['a'], 'releve.csv');
    fixture.componentInstance.onFileSelected({ target: { files: [file], value: '' } } as unknown as Event);
    await fixture.whenStable();
    expect(apiErrorServiceMock.label).toHaveBeenCalledWith({ status: 500 }, 'Erreur lors de l\'import. Veuillez réessayer.');
    expect(fixture.componentInstance.uploadError()).toBe('Erreur API');
    expect(fixture.componentInstance.uploading()).toBe(false);
  });

  it('should_click_hidden_file_input_when_triggered', async () => {
    const fixture = await setup();
    const input = fixture.nativeElement.querySelector('#csv-file-input') as HTMLInputElement;
    const clickSpy = vi.spyOn(input, 'click');
    fixture.componentInstance.triggerFileInput();
    expect(clickSpy).toHaveBeenCalled();
  });

  it('should_format_date_using_display_locale', async () => {
    const fixture = await setup();
    const formatted = fixture.componentInstance.formatDate('2026-03-12T10:00:00');
    expect(formatted).toContain('2026');
  });
});
