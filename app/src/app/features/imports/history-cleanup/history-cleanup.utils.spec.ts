import {
  accountAdjustments,
  cleanupAdjustment,
  cleanupTransaction,
  importedProposal,
  subscriptionProposal,
  uncategorizedGroup,
} from '../../../../testing/history-cleanup-fixtures';
import {
  amountClass,
  defaultCandidateId,
  defaultKeptPaymentId,
  groupCurrency,
  groupKey,
  hasImportedPayment,
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

describe('history-cleanup.utils', () => {
  describe('proposal keys', () => {
    it('should_key_an_imported_proposal_by_the_imported_transaction_id', () => {
      expect(importedProposalKey(importedProposal())).toBe('imp-1');
    });

    it('should_key_a_subscription_proposal_by_subscription_and_period_start', () => {
      expect(subscriptionProposalKey(subscriptionProposal())).toBe('sub-1|2026-09-10');
    });

    it('should_key_a_group_by_merchant_type_and_unit_amount', () => {
      expect(groupKey(uncategorizedGroup({ amount: 4.5 }))).toBe('BOULANGERIE TEST|DEPENSE|4.5');
      expect(groupKey(uncategorizedGroup({ amount: null }))).toBe('BOULANGERIE TEST|DEPENSE|');
    });
  });

  describe('resolveChoice', () => {
    it('should_return_the_user_choice_when_it_is_still_valid', () => {
      const choices = new Map([['k', 'b']]);

      expect(resolveChoice(choices, 'k', ['a', 'b'], 'a')).toBe('b');
    });

    it('should_return_the_default_when_the_user_has_not_chosen', () => {
      expect(resolveChoice(new Map(), 'k', ['a', 'b'], 'a')).toBe('a');
    });

    it('should_return_the_default_when_the_choice_is_no_longer_in_the_list', () => {
      const choices = new Map([['k', 'gone']]);

      expect(resolveChoice(choices, 'k', ['a', 'b'], 'a')).toBe('a');
    });

    it('should_return_null_when_there_is_no_default_and_no_choice', () => {
      expect(resolveChoice(new Map(), 'k', [], null)).toBeNull();
    });
  });

  describe('imported duplicates', () => {
    it('should_preselect_the_first_candidate', () => {
      expect(defaultCandidateId(importedProposal())).toBe('cand-1');
    });

    it('should_return_null_when_there_is_no_candidate', () => {
      expect(defaultCandidateId(importedProposal({ candidates: [] }))).toBeNull();
    });
  });

  describe('subscription duplicates', () => {
    const withStatement = () =>
      subscriptionProposal({
        suggestedKeepTransactionId: 'pay-2',
        transactions: [
          cleanupTransaction({ id: 'pay-1' }),
          cleanupTransaction({ id: 'pay-2', imported: true }),
          cleanupTransaction({ id: 'pay-3' }),
        ],
      });

    it('should_allow_keeping_any_payment_when_none_is_imported', () => {
      const proposal = subscriptionProposal();

      expect(hasImportedPayment(proposal)).toBe(false);
      expect(keepablePaymentIds(proposal)).toEqual(['pay-1', 'pay-2']);
    });

    it('should_only_allow_keeping_the_imported_payment_when_there_is_one', () => {
      const proposal = withStatement();

      expect(hasImportedPayment(proposal)).toBe(true);
      expect(keepablePaymentIds(proposal)).toEqual(['pay-2']);
    });

    it('should_preselect_the_payment_suggested_by_the_api', () => {
      expect(
        defaultKeptPaymentId(subscriptionProposal({ suggestedKeepTransactionId: 'pay-2' })),
      ).toBe('pay-2');
    });

    it('should_fall_back_to_the_first_keepable_payment_when_the_suggestion_is_not_keepable', () => {
      const proposal = { ...withStatement(), suggestedKeepTransactionId: 'pay-1' };

      expect(defaultKeptPaymentId(proposal)).toBe('pay-2');
    });

    it('should_return_null_when_there_is_no_payment', () => {
      expect(defaultKeptPaymentId(subscriptionProposal({ transactions: [] }))).toBeNull();
    });

    it('should_remove_every_payment_but_the_kept_one', () => {
      expect(removedPaymentIds(withStatement(), 'pay-2')).toEqual(['pay-1', 'pay-3']);
    });

    it('should_remove_nothing_when_the_kept_payment_is_the_only_one', () => {
      const proposal = subscriptionProposal({
        transactions: [cleanupTransaction({ id: 'pay-1' })],
      });

      expect(removedPaymentIds(proposal, 'pay-1')).toEqual([]);
    });
  });

  describe('splitUncategorized', () => {
    it('should_return_nothing_when_there_is_no_group', () => {
      expect(splitUncategorized([])).toEqual({ proposable: [], withoutMerchantCount: 0 });
    });

    it('should_keep_groups_with_a_merchant_key_as_proposable', () => {
      const group = uncategorizedGroup();

      expect(splitUncategorized([group])).toEqual({ proposable: [group], withoutMerchantCount: 0 });
    });

    it('should_sum_the_counts_of_the_groups_without_a_merchant_key', () => {
      const proposable = uncategorizedGroup();
      const noMerchant = uncategorizedGroup({ merchantKey: '', count: 3 });
      const blank = uncategorizedGroup({ merchantKey: '  ', count: 2 });

      const split = splitUncategorized([noMerchant, proposable, blank]);

      expect(split.proposable).toEqual([proposable]);
      expect(split.withoutMerchantCount).toBe(5);
    });
  });

  describe('group helpers', () => {
    it('should_create_a_rule_only_when_the_group_has_no_unit_amount', () => {
      expect(shouldCreateRule(uncategorizedGroup({ amount: null }))).toBe(true);
      expect(shouldCreateRule(uncategorizedGroup({ amount: 4.5 }))).toBe(false);
      expect(shouldCreateRule(uncategorizedGroup({ amount: 0 }))).toBe(false);
    });

    it('should_use_the_currency_of_the_first_transaction_of_a_group', () => {
      const group = uncategorizedGroup({
        transactions: [
          cleanupTransaction({ account: { ...cleanupTransaction().account, currency: 'XOF' } }),
        ],
      });

      expect(groupCurrency(group)).toBe('XOF');
    });

    it('should_default_to_euro_when_a_group_has_no_transaction', () => {
      expect(groupCurrency(uncategorizedGroup({ transactions: [] }))).toBe('EUR');
    });
  });

  describe('unneededAdjustments', () => {
    it('should_return_nothing_when_there_is_no_account', () => {
      expect(unneededAdjustments([])).toEqual([]);
    });

    it('should_keep_only_the_probably_unnecessary_adjustments', () => {
      const unneeded = cleanupAdjustment({ id: 'adj-a' });
      const needed = cleanupAdjustment({ id: 'adj-b', probablyUnnecessary: false });

      const result = unneededAdjustments([accountAdjustments({ adjustments: [needed, unneeded] })]);

      expect(result).toHaveLength(1);
      expect(result[0].adjustments).toEqual([unneeded]);
    });

    it('should_drop_the_accounts_left_without_adjustment', () => {
      const result = unneededAdjustments([
        accountAdjustments({
          adjustments: [cleanupAdjustment({ probablyUnnecessary: false })],
        }),
      ]);

      expect(result).toEqual([]);
    });

    it('should_not_mutate_the_source_accounts', () => {
      const source = accountAdjustments({
        adjustments: [cleanupAdjustment({ probablyUnnecessary: false })],
      });

      unneededAdjustments([source]);

      expect(source.adjustments).toHaveLength(1);
    });
  });

  describe('amounts', () => {
    it('should_give_a_positive_amount_the_income_side_and_a_negative_one_the_expense_side', () => {
      expect(signedAmountType(5)).toBe('RECETTE');
      expect(signedAmountType(-5)).toBe('DEPENSE');
      expect(signedAmountType(0)).toBe('RECETTE');
    });

    it('should_subtract_a_positive_adjustment_from_the_current_balance', () => {
      expect(reversalBalance(85, 5)).toBe(80);
    });

    it('should_add_back_a_negative_adjustment_to_the_current_balance', () => {
      expect(reversalBalance(85, -5)).toBe(90);
    });

    it('should_round_the_reversal_balance_to_the_cent', () => {
      expect(reversalBalance(0.3, 0.1)).toBe(0.2);
      expect(reversalBalance(100.1, 0.3)).toBe(99.8);
    });

    it('should_keep_the_balance_when_the_adjustment_is_zero', () => {
      expect(reversalBalance(42.5, 0)).toBe(42.5);
    });

    it('should_pick_the_colour_class_from_the_transaction_type', () => {
      expect(amountClass('RECETTE')).toBe('review__amount--income');
      expect(amountClass('DEPENSE')).toBe('review__amount--expense');
      expect(amountClass('AJUSTEMENT')).toBe('');
    });
  });
});
