import { importLine } from '../../../../testing/import-fixtures';
import { classifyLines, isAlreadyImported, isRestorable } from './import-review.utils';

describe('classifyLines', () => {
  it('should_return_empty_groups_when_there_is_no_line', () => {
    const model = classifyLines([]);

    expect(model.toDecide).toEqual([]);
    expect(model.uncategorised).toEqual([]);
    expect(model.newCount).toBe(0);
  });

  it('should_put_a_duplicate_with_candidates_in_to_decide', () => {
    const line = importLine({ status: 'DUPLICATE', matchCandidateIds: ['tx-1', 'tx-2'] });

    const model = classifyLines([line]);

    expect(model.toDecide).toEqual([line]);
    expect(model.probableDuplicates).toEqual([]);
  });

  it('should_put_a_duplicate_without_candidate_in_probable_duplicates', () => {
    const line = importLine({ status: 'DUPLICATE', duplicateTransactionId: 'tx-9' });

    const model = classifyLines([line]);

    expect(model.probableDuplicates).toEqual([line]);
    expect(model.toDecide).toEqual([]);
  });

  it('should_put_a_line_to_review_in_unreadable', () => {
    const line = importLine({ status: 'NEEDS_REVIEW', statusMessage: 'Date invalide' });

    expect(classifyLines([line]).unreadable).toEqual([line]);
  });

  it('should_split_skipped_lines_between_already_imported_and_skipped_by_the_user', () => {
    const imported = importLine({ status: 'SKIPPED', skipReason: 'ALREADY_IMPORTED' });
    const skipped = importLine({ status: 'SKIPPED' });

    const model = classifyLines([imported, skipped]);

    expect(model.alreadyImported).toEqual([imported]);
    expect(model.skipped).toEqual([skipped]);
    expect(model.newCount).toBe(0);
  });

  it('should_put_a_ready_line_with_a_match_in_matched_and_not_count_it_as_new', () => {
    const line = importLine({ matchedTransactionId: 'tx-1' });

    const model = classifyLines([line]);

    expect(model.matched).toEqual([line]);
    expect(model.newCount).toBe(0);
    expect(model.uncategorised).toEqual([]);
  });

  it('should_split_categorised_lines_by_the_source_of_their_category', () => {
    const rule = importLine({ categoryId: 'c1', categorySource: 'RULE' });
    const history = importLine({ categoryId: 'c1', categorySource: 'HISTORY' });
    const user = importLine({ categoryId: 'c1', categorySource: 'USER' });

    const model = classifyLines([rule, history, user]);

    expect(model.autoCategorised).toEqual([rule, history]);
    expect(model.userCategorised).toEqual([user]);
    expect(model.newCount).toBe(3);
  });

  it('should_group_uncategorised_lines_by_merchant_key_and_sum_their_amounts', () => {
    const first = importLine({ merchantKey: 'SUPER U', cleanLabel: 'SUPER U 16/03', amount: 10 });
    const other = importLine({ merchantKey: 'BOULANGERIE', cleanLabel: 'BOULANGERIE', amount: 3 });
    const second = importLine({ merchantKey: 'SUPER U', cleanLabel: 'SUPER U 20/03', amount: 5.5 });

    const { uncategorised } = classifyLines([first, other, second]);

    expect(uncategorised).toHaveLength(2);
    expect(uncategorised[0]).toMatchObject({
      key: 'SUPER U|DEPENSE',
      label: 'SUPER U 16/03',
      total: 15.5,
      transactionType: 'DEPENSE',
    });
    expect(uncategorised[0].lines).toEqual([first, second]);
    expect(uncategorised[1].lines).toEqual([other]);
  });

  it('should_not_group_lines_of_the_same_merchant_with_different_directions', () => {
    const expense = importLine({ merchantKey: 'AMAZON', transactionType: 'DEPENSE' });
    const refund = importLine({ merchantKey: 'AMAZON', transactionType: 'RECETTE' });

    expect(classifyLines([expense, refund]).uncategorised).toHaveLength(2);
  });

  it('should_keep_lines_without_merchant_key_alone', () => {
    const first = importLine({ merchantKey: '' });
    const second = importLine({ merchantKey: '' });

    const { uncategorised } = classifyLines([first, second]);

    expect(uncategorised.map((group) => group.lines)).toEqual([[first], [second]]);
  });
});

describe('isAlreadyImported', () => {
  it('should_be_true_only_for_a_skipped_line_the_import_discarded', () => {
    expect(
      isAlreadyImported(importLine({ status: 'SKIPPED', skipReason: 'ALREADY_IMPORTED' })),
    ).toBe(true);
    expect(isAlreadyImported(importLine({ status: 'SKIPPED' }))).toBe(false);
    expect(isAlreadyImported(importLine({ status: 'READY', skipReason: 'ALREADY_IMPORTED' }))).toBe(
      false,
    );
  });
});

describe('isRestorable', () => {
  it('should_allow_restoring_a_line_skipped_by_the_user', () => {
    expect(isRestorable(importLine({ status: 'SKIPPED' }))).toBe(true);
  });

  it('should_refuse_restoring_an_already_imported_line', () => {
    expect(isRestorable(importLine({ status: 'SKIPPED', skipReason: 'ALREADY_IMPORTED' }))).toBe(
      false,
    );
  });

  it('should_refuse_restoring_an_unreadable_line', () => {
    expect(isRestorable(importLine({ status: 'SKIPPED', statusMessage: 'Montant invalide' }))).toBe(
      false,
    );
  });

  it('should_refuse_restoring_a_line_that_is_not_skipped', () => {
    expect(isRestorable(importLine({ status: 'READY' }))).toBe(false);
  });
});
