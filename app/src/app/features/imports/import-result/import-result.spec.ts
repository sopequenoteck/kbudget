import { TestBed } from '@angular/core/testing';

import { ImportResult } from './import-result';
import { ImportConfirmResult } from '../../../core/models/import.model';
import { provideTranslocoTesting } from '../../../../testing/transloco-testing';
import { confirmResult, matchedTransaction } from '../../../../testing/import-fixtures';

describe('ImportResult', () => {
  const setup = (result: ImportConfirmResult, currency = 'EUR') => {
    TestBed.configureTestingModule({
      imports: [ImportResult],
      providers: [provideTranslocoTesting()],
    });
    const fixture = TestBed.createComponent(ImportResult);
    fixture.componentRef.setInput('result', result);
    fixture.componentRef.setInput('currency', currency);
    fixture.detectChanges();
    return fixture;
  };

  const text = (fixture: ReturnType<typeof setup>) =>
    (fixture.nativeElement as HTMLElement).textContent?.replace(/\s+/g, ' ') ?? '';

  it('should_show_the_number_of_transactions_created', () => {
    const fixture = setup(confirmResult({ importedCount: 3 }));

    expect(text(fixture)).toContain('Import terminé');
    expect(text(fixture)).toContain('3 transactions créées');
  });

  it('should_hide_the_matched_and_already_imported_lines_when_they_are_zero', () => {
    const fixture = setup(
      confirmResult({ importedCount: 1, matchedCount: 0, alreadyImportedCount: 0 }),
    );

    expect(text(fixture)).toContain('1 transaction créée');
    expect(text(fixture)).not.toContain('rapprochée');
    expect(text(fixture)).not.toContain('déjà importée');
  });

  it('should_show_the_matched_and_already_imported_counts_when_there_are_some', () => {
    const fixture = setup(confirmResult({ matchedCount: 2, alreadyImportedCount: 7 }));

    expect(text(fixture)).toContain('2 rapprochées de transactions existantes');
    expect(text(fixture)).toContain('7 déjà importées');
  });

  it('should_not_show_a_balance_section_when_the_statement_gave_no_balance', () => {
    const fixture = setup(confirmResult({ balanceCheck: null }));

    const root = fixture.nativeElement as HTMLElement;
    expect(root.querySelector('[data-testid="balance-match"]')).toBeNull();
    expect(root.querySelector('[data-testid="balance-gap"]')).toBeNull();
  });

  it('should_say_the_balance_is_identical_when_the_difference_is_zero', () => {
    const fixture = setup(
      confirmResult({
        balanceCheck: {
          bankBalance: 1842.37,
          balanceDate: '2026-10-01',
          computedBalance: 1842.37,
          difference: 0,
          suspects: [],
        },
      }),
    );

    const root = fixture.nativeElement as HTMLElement;
    expect(root.querySelector('[data-testid="balance-match"]')?.textContent).toContain(
      'Solde identique à celui de la banque',
    );
    expect(root.querySelector('[data-testid="balance-gap"]')).toBeNull();
    expect(text(fixture)).toContain('Solde de la banque : 1 842,37');
    expect(text(fixture)).toContain('1 octobre 2026');
    expect(text(fixture)).not.toContain('absentes du relevé');
  });

  it('should_show_the_gap_and_the_suspect_transactions_when_the_balance_differs', () => {
    const fixture = setup(
      confirmResult({
        balanceCheck: {
          bankBalance: 1842.37,
          balanceDate: '2026-10-01',
          computedBalance: 1238.07,
          difference: -604.3,
          suspects: [
            matchedTransaction({
              id: 't1',
              libelle: 'Pain',
              date: '2026-09-16',
              montant: 4.3,
              type: 'DEPENSE',
            }),
            matchedTransaction({
              id: 't2',
              libelle: 'Remboursement',
              date: '2026-09-20',
              montant: 12,
              type: 'RECETTE',
            }),
          ],
        },
      }),
    );

    const root = fixture.nativeElement as HTMLElement;
    expect(root.querySelector('[data-testid="balance-gap"]')?.textContent).toContain('Écart de');
    expect(root.querySelector('[data-testid="balance-gap"]')?.textContent).toContain('604,30');
    expect(root.querySelector('[data-testid="balance-match"]')).toBeNull();
    expect(text(fixture)).toContain('Opérations de la période absentes du relevé');
    const rows = root.querySelectorAll('.result__row');
    expect(rows).toHaveLength(2);
    expect(rows[0].textContent).toContain('Pain');
    expect(rows[0].textContent).toContain('16 septembre');
    expect(rows[0].textContent).toContain('-4,30');
    expect(rows[1].textContent).toContain('+12,00');
  });

  it('should_show_the_gap_without_suspect_list_when_none_is_identified', () => {
    const fixture = setup(
      confirmResult({
        balanceCheck: {
          bankBalance: 100,
          balanceDate: '2026-10-01',
          computedBalance: 90,
          difference: -10,
          suspects: [],
        },
      }),
    );

    const root = fixture.nativeElement as HTMLElement;
    expect(root.querySelector('[data-testid="balance-gap"]')).not.toBeNull();
    expect(root.querySelector('.result__row')).toBeNull();
    expect(text(fixture)).not.toContain('absentes du relevé');
  });

  it('should_format_amounts_with_the_currency_of_the_account', () => {
    const fixture = setup(
      confirmResult({
        balanceCheck: {
          bankBalance: 1500,
          balanceDate: '2026-10-01',
          computedBalance: 1500,
          difference: 0,
          suspects: [],
        },
      }),
      'XOF',
    );

    expect(text(fixture)).toMatch(/CFA/);
  });

  it('should_emit_done_when_the_button_is_clicked', () => {
    const fixture = setup(confirmResult());
    const done = vi.fn();
    fixture.componentInstance.done.subscribe(done);

    (fixture.nativeElement.querySelector('.result__done') as HTMLButtonElement).click();

    expect(done).toHaveBeenCalledTimes(1);
  });
});
