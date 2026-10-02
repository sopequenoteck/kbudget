import { parseLocalDate, toLocalIsoDate } from './date.utils';

describe('parseLocalDate', () => {
  it('should_read_date_only_at_local_midnight_when_value_is_date_only', () => {
    const result = parseLocalDate('2026-09-27');
    expect(result.getFullYear()).toBe(2026);
    expect(result.getMonth()).toBe(8);
    expect(result.getDate()).toBe(27);
    expect(result.getHours()).toBe(0);
  });

  it('should_read_date_time_without_zone_unchanged_when_value_has_time', () => {
    const result = parseLocalDate('2026-09-27T14:30:00');
    expect(result.getFullYear()).toBe(2026);
    expect(result.getMonth()).toBe(8);
    expect(result.getDate()).toBe(27);
    expect(result.getHours()).toBe(14);
    expect(result.getMinutes()).toBe(30);
  });

  it('should_read_date_time_with_zone_unchanged_when_value_has_z_suffix', () => {
    const result = parseLocalDate('2026-09-27T00:00:00Z');
    expect(result.getTime()).toBe(new Date('2026-09-27T00:00:00Z').getTime());
  });

  it('should_return_invalid_date_when_value_is_invalid', () => {
    const result = parseLocalDate('not-a-date');
    expect(result.getTime()).toBeNaN();
  });
});

describe('toLocalIsoDate', () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it('should_format_local_date_when_utc_is_already_the_next_day', () => {
    // 23h locale a Los Angeles (UTC-7/-8) : `toISOString()` donnerait le
    // lendemain en UTC.
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 2, 13, 23, 0, 0));

    expect(toLocalIsoDate(new Date())).toBe('2026-03-13');
  });

  it('should_pad_month_and_day_when_below_ten', () => {
    expect(toLocalIsoDate(new Date(2026, 0, 5))).toBe('2026-01-05');
  });
});
