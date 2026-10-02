import { getRelativeDueDateInfo, RelativeDueDateKeys } from './relative-due-date.utils';

const TODAY = new Date(2026, 2, 13); // 13 mars 2026

const fullKeys: RelativeDueDateKeys = {
  today: 'domain.list.today',
  tomorrow: 'domain.list.tomorrow',
  daysUntil: 'domain.list.daysUntil',
  yesterday: 'domain.list.yesterday',
  daysOverdue: 'domain.list.daysOverdue',
};

const futureOnlyKeys: RelativeDueDateKeys = {
  today: 'domain.list.today',
  tomorrow: 'domain.list.tomorrow',
  daysUntil: 'domain.list.daysUntil',
};

describe('getRelativeDueDateInfo', () => {
  it('should_return_today_key_when_target_is_today', () => {
    const result = getRelativeDueDateInfo(new Date(2026, 2, 13), TODAY, 'fr-FR', fullKeys);
    expect(result).toEqual({ key: 'domain.list.today' });
  });

  it('should_return_tomorrow_key_when_target_is_one_day_ahead', () => {
    const result = getRelativeDueDateInfo(new Date(2026, 2, 14), TODAY, 'fr-FR', fullKeys);
    expect(result).toEqual({ key: 'domain.list.tomorrow' });
  });

  it('should_return_days_until_key_with_count_when_target_is_within_thirty_days', () => {
    const result = getRelativeDueDateInfo(new Date(2026, 2, 20), TODAY, 'fr-FR', fullKeys);
    expect(result).toEqual({ key: 'domain.list.daysUntil', params: { count: 7 } });
  });

  it('should_return_formatted_date_when_target_is_more_than_thirty_days_ahead', () => {
    const result = getRelativeDueDateInfo(new Date(2026, 5, 1), TODAY, 'fr-FR', fullKeys);
    expect(result.key).toBeUndefined();
    expect(result.formatted).toBeTruthy();
  });

  it('should_return_yesterday_key_when_target_is_one_day_overdue_and_key_provided', () => {
    const result = getRelativeDueDateInfo(new Date(2026, 2, 12), TODAY, 'fr-FR', fullKeys);
    expect(result).toEqual({ key: 'domain.list.yesterday' });
  });

  it('should_return_days_overdue_key_with_count_when_target_is_several_days_overdue', () => {
    const result = getRelativeDueDateInfo(new Date(2026, 2, 10), TODAY, 'fr-FR', fullKeys);
    expect(result).toEqual({ key: 'domain.list.daysOverdue', params: { count: 3 } });
  });

  it('should_return_days_overdue_key_when_target_is_one_day_overdue_and_no_yesterday_key', () => {
    const keys: RelativeDueDateKeys = { ...futureOnlyKeys, daysOverdue: 'domain.list.daysOverdue' };
    const result = getRelativeDueDateInfo(new Date(2026, 2, 12), TODAY, 'fr-FR', keys);
    expect(result).toEqual({ key: 'domain.list.daysOverdue', params: { count: 1 } });
  });

  it('should_return_formatted_date_when_target_is_overdue_and_no_overdue_keys_provided', () => {
    // Cas subscriptions : la date cible ne peut jamais etre passee en pratique,
    // aucune cle de retard n'est definie pour ce domaine.
    const result = getRelativeDueDateInfo(new Date(2026, 2, 10), TODAY, 'fr-FR', futureOnlyKeys);
    expect(result.key).toBeUndefined();
    expect(result.formatted).toBeTruthy();
  });

  it('should_ignore_hours_when_comparing_dates', () => {
    const targetWithTime = new Date(2026, 2, 13, 23, 59, 59);
    const todayWithTime = new Date(2026, 2, 13, 0, 30, 0);
    const result = getRelativeDueDateInfo(targetWithTime, todayWithTime, 'fr-FR', fullKeys);
    expect(result).toEqual({ key: 'domain.list.today' });
  });

  it('should_format_the_date_using_the_given_locale', () => {
    const result = getRelativeDueDateInfo(new Date(2026, 5, 1), TODAY, 'en-GB', fullKeys);
    expect(result.formatted).toContain('Jun');
  });

  it('should_zero_pad_the_day_when_two_digit_format_requested', () => {
    const result = getRelativeDueDateInfo(new Date(2026, 5, 1), TODAY, 'fr-FR', fullKeys, '2-digit');
    expect(result.formatted).toContain('01');
  });

  it('should_not_zero_pad_the_day_by_default', () => {
    const result = getRelativeDueDateInfo(new Date(2026, 5, 1), TODAY, 'fr-FR', fullKeys);
    expect(result.formatted).not.toContain('01');
  });
});
