import { TestBed } from '@angular/core/testing';
import { ActivatedRoute, provideRouter } from '@angular/router';
import { of, Subject, throwError } from 'rxjs';

import { ImportReview } from './import-review';
import { ImportService } from '../../../../core/services/import';
import { CategoryService } from '../../../../core/services/category';
import { CategoryRuleService } from '../../../../core/services/category-rule';
import { ImportDraft, ImportDraftLine } from '../../../../core/models/import.model';
import { provideTranslocoTesting } from '../../../../../testing/transloco-testing';
import { Category } from '../../../../core/models/category.model';

function line(overrides: Partial<ImportDraftLine>): ImportDraftLine {
  return {
    id: 'line-1',
    lineNumber: 1,
    rawLabel: 'CARTE X0000 01/03 BOULANGERIE TEST',
    cleanLabel: 'BOULANGERIE TEST',
    amount: 3.2,
    date: '2026-03-02',
    transactionType: 'DEPENSE',
    status: 'READY',
    statusMessage: null,
    categoryId: null,
    categoryName: null,
    duplicateTransactionId: null,
    ...overrides,
  };
}

function draft(lines: ImportDraftLine[]): ImportDraft {
  return {
    id: 'draft-1',
    accountId: 'account-1',
    accountName: 'Compte courant',
    status: 'PENDING',
    fileName: 'releve.csv',
    totalLines: lines.length,
    readyCount: lines.filter((l) => l.status === 'READY').length,
    reviewCount: lines.filter((l) => l.status === 'NEEDS_REVIEW').length,
    duplicateCount: 0,
    skippedCount: 0,
    profileName: null,
    profileSource: null,
    createdAt: '2026-03-12T10:00:00',
    expiresAt: '2026-03-19T10:00:00',
    lines,
  };
}

describe('ImportReview', () => {
  let importServiceMock: {
    getDraft: ReturnType<typeof vi.fn>;
    updateLine: ReturnType<typeof vi.fn>;
    batchUpdateLines: ReturnType<typeof vi.fn>;
  };

  const readyLine = line({ id: 'ready', status: 'READY' });
  const reviewLine = line({ id: 'review', status: 'NEEDS_REVIEW' });

  const setup = async (lines: ImportDraftLine[], categories$ = of<Category[]>([])) => {
    importServiceMock = {
      getDraft: vi.fn().mockReturnValue(of(draft(lines))),
      updateLine: vi
        .fn()
        .mockImplementation((_d: string, id: string) =>
          of(line({ id, categoryId: 'cat-1', categoryName: 'Courses' })),
        ),
      batchUpdateLines: vi.fn().mockReturnValue(of([])),
    };

    TestBed.configureTestingModule({
      imports: [ImportReview],
      providers: [
        provideTranslocoTesting(),
        provideRouter([]),
        { provide: ActivatedRoute, useValue: { snapshot: { paramMap: { get: () => 'draft-1' } } } },
        { provide: ImportService, useValue: importServiceMock },
        { provide: CategoryService, useValue: { getAll: vi.fn().mockReturnValue(categories$) } },
        { provide: CategoryRuleService, useValue: { create: vi.fn().mockReturnValue(of({})) } },
      ],
    });

    const fixture = TestBed.createComponent(ImportReview);
    fixture.detectChanges();
    await fixture.whenStable();
    return fixture;
  };

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('should_not_send_status_when_categorizing_a_ready_line', async () => {
    const fixture = await setup([readyLine]);

    await fixture.componentInstance.onCategoryChange(readyLine, 'cat-1');

    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', 'ready', {
      categoryId: 'cat-1',
      status: undefined,
    });
  });

  it('should_send_ready_when_categorizing_a_line_to_review', async () => {
    const fixture = await setup([reviewLine]);

    await fixture.componentInstance.onCategoryChange(reviewLine, 'cat-1');

    expect(importServiceMock.updateLine).toHaveBeenCalledWith('draft-1', 'review', {
      categoryId: 'cat-1',
      status: 'READY',
    });
  });

  it('should_reload_draft_when_category_changed_so_propagated_lines_show', async () => {
    const fixture = await setup([readyLine]);
    importServiceMock.getDraft.mockClear();

    await fixture.componentInstance.onCategoryChange(readyLine, 'cat-1');

    expect(importServiceMock.getDraft).toHaveBeenCalledWith('draft-1');
  });

  it('should_show_error_when_category_change_fails', async () => {
    const fixture = await setup([readyLine]);
    importServiceMock.updateLine.mockReturnValue(throwError(() => new Error('400')));

    await fixture.componentInstance.onCategoryChange(readyLine, 'cat-1');
    fixture.detectChanges();

    const alert = fixture.nativeElement.querySelector('[role="alert"]') as HTMLElement;
    expect(alert.textContent).toContain("La catégorie n'a pas pu être enregistrée.");
  });

  it('should_send_category_only_when_batch_assigning', async () => {
    const fixture = await setup([readyLine, reviewLine]);
    const component = fixture.componentInstance;
    component.selectedLineIds.set(new Set(['ready', 'review']));
    component.batchCategoryId.set('cat-1');

    await component.onBatchAssignCategory();

    expect(importServiceMock.batchUpdateLines).toHaveBeenCalledWith('draft-1', {
      lineIds: ['ready', 'review'],
      categoryId: 'cat-1',
    });
  });

  it('should_show_error_when_batch_action_fails', async () => {
    const fixture = await setup([readyLine]);
    importServiceMock.batchUpdateLines.mockReturnValue(throwError(() => new Error('400')));
    const component = fixture.componentInstance;
    component.selectedLineIds.set(new Set(['ready']));

    await component.onBatchSkip();
    fixture.detectChanges();

    const alert = fixture.nativeElement.querySelector('[role="alert"]') as HTMLElement;
    expect(alert.textContent).toContain("L'action groupée a échoué");
  });

  it.each([
    ['assign', (c: ImportReview) => c.onBatchAssignCategory()],
    ['validate', (c: ImportReview) => c.onBatchValidate()],
  ])('should_show_error_when_batch_%s_fails', async (_name, action) => {
    const fixture = await setup([readyLine]);
    importServiceMock.batchUpdateLines.mockReturnValue(throwError(() => new Error('400')));
    const component = fixture.componentInstance;
    component.selectedLineIds.set(new Set(['ready']));
    component.batchCategoryId.set('cat-1');

    await action(component);

    expect(component.actionError()).toContain("L'action groupée a échoué");
  });

  it('should_reload_draft_without_request_when_category_is_cleared', async () => {
    const fixture = await setup([readyLine]);
    importServiceMock.getDraft.mockClear();

    await fixture.componentInstance.onCategoryChange(readyLine, '');

    expect(importServiceMock.updateLine).not.toHaveBeenCalled();
    expect(importServiceMock.getDraft).toHaveBeenCalledWith('draft-1');
  });

  it('should_keep_current_draft_when_reload_fails', async () => {
    const fixture = await setup([readyLine]);
    importServiceMock.getDraft.mockReturnValue(throwError(() => new Error('503')));

    await fixture.componentInstance.onCategoryChange(readyLine, '');

    expect(fixture.componentInstance.draft()?.lines).toHaveLength(1);
  });

  it('should_show_suggested_category_when_categories_load_after_draft', async () => {
    const categories$ = new Subject<Category[]>();
    const suggested = line({ id: 'suggested', categoryId: 'cat-2', categoryName: 'Loisirs' });
    const fixture = await setup([suggested], categories$);

    categories$.next([
      { id: 'cat-1', nom: 'Courses', icone: '🛒', couleur: '#000000' } as Category,
      { id: 'cat-2', nom: 'Loisirs', icone: '🎮', couleur: '#000000' } as Category,
    ]);
    categories$.complete();
    await fixture.whenStable();
    fixture.detectChanges();

    const select = fixture.nativeElement.querySelector('#cat-suggested') as HTMLSelectElement;
    expect(select.value).toBe('cat-2');
  });
});
