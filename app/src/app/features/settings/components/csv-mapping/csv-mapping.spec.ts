import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';
import { of, throwError } from 'rxjs';

import { CsvMapping } from './csv-mapping';
import { ImportService } from '../../../../core/services/import';
import { ApiErrorService } from '../../../../core/services/api-error';
import { CsvPreview, ImportDraft } from '../../../../core/models/import.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';

function preview(overrides: Partial<CsvPreview> = {}): CsvPreview {
  return {
    headers: ['Date', 'Libelle', 'Montant'],
    rows: [['01/03/2026', 'CARREFOUR', '-12,50']],
    detectedSeparator: ';',
    detectedEncoding: 'UTF-8',
    detectedSkipHeaderLines: 0,
    totalRows: 1,
    ...overrides,
  };
}

function draft(overrides: Partial<ImportDraft> = {}): ImportDraft {
  return {
    id: 'draft-1',
    accountId: 'acc-1',
    accountName: 'Courant',
    status: 'PENDING',
    fileName: 'releve.csv',
    totalLines: 1,
    readyCount: 1,
    reviewCount: 0,
    duplicateCount: 0,
    skippedCount: 0,
    profileName: null,
    profileSource: null,
    createdAt: '2026-03-12T10:00:00',
    expiresAt: '2026-03-19T10:00:00',
    lines: [],
    ...overrides,
  };
}

describe('CsvMapping', () => {
  let importServiceMock: {
    preview: ReturnType<typeof vi.fn>;
    uploadWithMapping: ReturnType<typeof vi.fn>;
  };
  let apiErrorServiceMock: { label: ReturnType<typeof vi.fn> };
  let navigateSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    importServiceMock = {
      preview: vi.fn().mockReturnValue(of(preview())),
      uploadWithMapping: vi.fn().mockReturnValue(of(draft())),
    };
    apiErrorServiceMock = { label: vi.fn().mockReturnValue('Erreur API') };
  });

  const setup = (navigationState?: { file?: File; accountId?: string }) => {
    TestBed.configureTestingModule({
      imports: [CsvMapping],
      providers: [
        provideTranslocoTesting(),
        provideRouter([]),
        { provide: ImportService, useValue: importServiceMock },
        { provide: ApiErrorService, useValue: apiErrorServiceMock },
      ],
    });

    const router = TestBed.inject(Router);
    navigateSpy = vi.spyOn(router, 'navigate').mockResolvedValue(true);
    vi.spyOn(router, 'getCurrentNavigation').mockReturnValue(
      navigationState ? ({ extras: { state: navigationState } } as ReturnType<Router['getCurrentNavigation']>) : null,
    );

    const fixture = TestBed.createComponent(CsvMapping);
    fixture.detectChanges();
    return fixture;
  };

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('should_create_the_component', () => {
    const fixture = setup();
    expect(fixture.componentInstance).toBeTruthy();
  });

  it('should_not_load_preview_when_no_router_state', () => {
    const fixture = setup();
    expect(importServiceMock.preview).not.toHaveBeenCalled();
    expect(fixture.componentInstance.fileName()).toBe('');
  });

  it('should_load_preview_and_prefill_state_when_file_provided', async () => {
    const file = new File(['a'], 'releve.csv');
    const fixture = setup({ file, accountId: 'acc-1' });
    await fixture.whenStable();

    expect(fixture.componentInstance.fileName()).toBe('releve.csv');
    expect(fixture.componentInstance.accountId()).toBe('acc-1');
    expect(importServiceMock.preview).toHaveBeenCalledWith(file, ';', 'UTF-8', 0);
    expect(fixture.componentInstance.preview()).toEqual(preview());
  });

  it('should_autoselect_columns_from_detected_headers', async () => {
    const file = new File(['a'], 'releve.csv');
    const fixture = setup({ file, accountId: 'acc-1' });
    await fixture.whenStable();

    expect(fixture.componentInstance.dateColumn()).toBe('Date');
    expect(fixture.componentInstance.labelColumn()).toBe('Libelle');
    expect(fixture.componentInstance.amountColumn()).toBe('Montant');
  });

  it('should_apply_detected_separator_encoding_and_skip_lines', async () => {
    importServiceMock.preview.mockReturnValue(
      of(preview({ detectedSeparator: ',', detectedEncoding: 'ISO-8859-1', detectedSkipHeaderLines: 2 })),
    );
    const file = new File(['a'], 'releve.csv');
    const fixture = setup({ file, accountId: 'acc-1' });
    await fixture.whenStable();

    expect(fixture.componentInstance.separator()).toBe(',');
    expect(fixture.componentInstance.encoding()).toBe('ISO-8859-1');
    expect(fixture.componentInstance.skipHeaderLines()).toBe(2);
  });

  it('should_not_override_skip_lines_when_detected_value_is_zero', async () => {
    const file = new File(['a'], 'releve.csv');
    const fixture = setup({ file, accountId: 'acc-1' });
    fixture.componentInstance.skipHeaderLines.set(3);
    await fixture.componentInstance.loadPreview();

    expect(fixture.componentInstance.skipHeaderLines()).toBe(3);
  });

  it('should_set_translated_error_when_preview_fails', async () => {
    importServiceMock.preview.mockReturnValue(throwError(() => new Error('500')));
    const file = new File(['a'], 'releve.csv');
    const fixture = setup({ file, accountId: 'acc-1' });
    await fixture.whenStable();

    expect(fixture.componentInstance.previewError()).toBe(
      'Impossible de prévisualiser le fichier. Vérifiez les paramètres.',
    );
    expect(fixture.componentInstance.previewLoading()).toBe(false);
  });

  it('should_do_nothing_when_loading_preview_without_a_file', async () => {
    const fixture = setup();
    await fixture.componentInstance.loadPreview();
    expect(importServiceMock.preview).not.toHaveBeenCalled();
  });

  it('should_reload_preview_when_separator_changes', () => {
    const fixture = setup();
    const spy = vi.spyOn(fixture.componentInstance, 'loadPreview');
    fixture.componentInstance.onSeparatorChange();
    expect(spy).toHaveBeenCalled();
  });

  it('should_reload_preview_when_encoding_changes', () => {
    const fixture = setup();
    const spy = vi.spyOn(fixture.componentInstance, 'loadPreview');
    fixture.componentInstance.onEncodingChange();
    expect(spy).toHaveBeenCalled();
  });

  it('should_reload_preview_when_skip_header_lines_changes', () => {
    const fixture = setup();
    const spy = vi.spyOn(fixture.componentInstance, 'loadPreview');
    fixture.componentInstance.onSkipHeaderLinesChange();
    expect(spy).toHaveBeenCalled();
  });

  it('should_be_invalid_when_date_column_missing', () => {
    const fixture = setup();
    fixture.componentInstance.labelColumn.set('Libelle');
    fixture.componentInstance.amountColumn.set('Montant');
    expect(fixture.componentInstance.isValid()).toBe(false);
  });

  it('should_be_invalid_when_label_column_missing', () => {
    const fixture = setup();
    fixture.componentInstance.dateColumn.set('Date');
    fixture.componentInstance.amountColumn.set('Montant');
    expect(fixture.componentInstance.isValid()).toBe(false);
  });

  it('should_be_invalid_when_single_mode_missing_amount_column', () => {
    const fixture = setup();
    fixture.componentInstance.dateColumn.set('Date');
    fixture.componentInstance.labelColumn.set('Libelle');
    expect(fixture.componentInstance.isValid()).toBe(false);
  });

  it('should_be_invalid_when_split_mode_missing_debit_or_credit_column', () => {
    const fixture = setup();
    fixture.componentInstance.dateColumn.set('Date');
    fixture.componentInstance.labelColumn.set('Libelle');
    fixture.componentInstance.amountMode.set('split');
    fixture.componentInstance.debitColumn.set('Debit');
    expect(fixture.componentInstance.isValid()).toBe(false);
  });

  it('should_be_invalid_when_saving_profile_without_a_name', () => {
    const fixture = setup();
    fixture.componentInstance.dateColumn.set('Date');
    fixture.componentInstance.labelColumn.set('Libelle');
    fixture.componentInstance.amountColumn.set('Montant');
    fixture.componentInstance.saveAsProfile.set(true);
    fixture.componentInstance.profileName.set('   ');
    expect(fixture.componentInstance.isValid()).toBe(false);
  });

  it('should_be_valid_when_single_mode_fully_filled', () => {
    const fixture = setup();
    fixture.componentInstance.dateColumn.set('Date');
    fixture.componentInstance.labelColumn.set('Libelle');
    fixture.componentInstance.amountColumn.set('Montant');
    expect(fixture.componentInstance.isValid()).toBe(true);
  });

  it('should_be_valid_when_split_mode_fully_filled', () => {
    const fixture = setup();
    fixture.componentInstance.dateColumn.set('Date');
    fixture.componentInstance.labelColumn.set('Libelle');
    fixture.componentInstance.amountMode.set('split');
    fixture.componentInstance.debitColumn.set('Debit');
    fixture.componentInstance.creditColumn.set('Credit');
    expect(fixture.componentInstance.isValid()).toBe(true);
  });

  it('should_do_nothing_when_importing_without_a_file', async () => {
    const fixture = setup();
    await fixture.componentInstance.import();
    expect(importServiceMock.uploadWithMapping).not.toHaveBeenCalled();
  });

  it('should_do_nothing_when_importing_with_invalid_mapping', async () => {
    const file = new File(['a'], 'releve.csv');
    const fixture = setup({ file, accountId: 'acc-1' });
    await fixture.whenStable();
    fixture.componentInstance.dateColumn.set('');

    await fixture.componentInstance.import();
    expect(importServiceMock.uploadWithMapping).not.toHaveBeenCalled();
  });

  it('should_navigate_to_review_when_import_succeeds', async () => {
    const file = new File(['a'], 'releve.csv');
    const fixture = setup({ file, accountId: 'acc-1' });
    await fixture.whenStable();
    fixture.componentInstance.dateColumn.set('Date');
    fixture.componentInstance.labelColumn.set('Libelle');
    fixture.componentInstance.amountColumn.set('Montant');

    await fixture.componentInstance.import();

    expect(importServiceMock.uploadWithMapping).toHaveBeenCalledWith(
      file,
      'acc-1',
      expect.objectContaining({ dateColumn: 'Date', labelColumn: 'Libelle', amountColumn: 'Montant' }),
    );
    expect(navigateSpy).toHaveBeenCalledWith(['/settings/import/review', 'draft-1']);
  });

  it('should_send_debit_and_credit_columns_when_split_mode', async () => {
    const file = new File(['a'], 'releve.csv');
    const fixture = setup({ file, accountId: 'acc-1' });
    await fixture.whenStable();
    fixture.componentInstance.dateColumn.set('Date');
    fixture.componentInstance.labelColumn.set('Libelle');
    fixture.componentInstance.amountMode.set('split');
    fixture.componentInstance.debitColumn.set('Debit');
    fixture.componentInstance.creditColumn.set('Credit');

    await fixture.componentInstance.import();

    expect(importServiceMock.uploadWithMapping).toHaveBeenCalledWith(
      file,
      'acc-1',
      expect.objectContaining({ amountColumn: null, debitColumn: 'Debit', creditColumn: 'Credit' }),
    );
  });

  it('should_send_trimmed_profile_name_when_saving_as_profile', async () => {
    const file = new File(['a'], 'releve.csv');
    const fixture = setup({ file, accountId: 'acc-1' });
    await fixture.whenStable();
    fixture.componentInstance.dateColumn.set('Date');
    fixture.componentInstance.labelColumn.set('Libelle');
    fixture.componentInstance.amountColumn.set('Montant');
    fixture.componentInstance.saveAsProfile.set(true);
    fixture.componentInstance.profileName.set('  Ma banque  ');

    await fixture.componentInstance.import();

    expect(importServiceMock.uploadWithMapping).toHaveBeenCalledWith(
      file,
      'acc-1',
      expect.objectContaining({ saveAsProfile: true, profileName: 'Ma banque' }),
    );
  });

  it('should_set_api_error_label_when_import_fails', async () => {
    importServiceMock.uploadWithMapping.mockReturnValue(throwError(() => ({ error: {} })));
    const file = new File(['a'], 'releve.csv');
    const fixture = setup({ file, accountId: 'acc-1' });
    await fixture.whenStable();
    fixture.componentInstance.dateColumn.set('Date');
    fixture.componentInstance.labelColumn.set('Libelle');
    fixture.componentInstance.amountColumn.set('Montant');

    await fixture.componentInstance.import();

    expect(apiErrorServiceMock.label).toHaveBeenCalledWith(
      { error: {} },
      'Erreur lors de l\'import. Vérifiez le mapping et réessayez.',
    );
    expect(fixture.componentInstance.importError()).toBe('Erreur API');
    expect(fixture.componentInstance.importing()).toBe(false);
  });
});
