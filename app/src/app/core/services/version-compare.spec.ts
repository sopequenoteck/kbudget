import { describe, expect, it } from 'vitest';

import { compareVersions, isOlderThan } from './version-compare';

describe('compareVersions', () => {
  it('should_return_zero_when_versions_are_equal', () => {
    expect(compareVersions('6.0.0', '6.0.0')).toBe(0);
  });

  it('should_order_by_major_first', () => {
    expect(compareVersions('5.9.9', '6.0.0')).toBeLessThan(0);
    expect(compareVersions('7.0.0', '6.9.9')).toBeGreaterThan(0);
  });

  it('should_order_by_minor_when_major_is_equal', () => {
    expect(compareVersions('6.1.0', '6.2.0')).toBeLessThan(0);
  });

  it('should_order_by_patch_when_major_and_minor_are_equal', () => {
    expect(compareVersions('6.0.1', '6.0.2')).toBeLessThan(0);
  });

  it('should_compare_numerically_and_not_lexicographically', () => {
    // "10" < "9" en comparaison de chaines : le piege que ce comparateur evite.
    expect(compareVersions('6.10.0', '6.9.0')).toBeGreaterThan(0);
  });

  it('should_ignore_prerelease_and_build_suffixes', () => {
    expect(compareVersions('6.0.0-rc.1', '6.0.0')).toBe(0);
    expect(compareVersions('6.0.0+build.5', '6.0.0')).toBe(0);
  });

  it('should_treat_missing_segments_as_zero', () => {
    expect(compareVersions('6', '6.0.0')).toBe(0);
    expect(compareVersions('6.1', '6.0.0')).toBeGreaterThan(0);
  });
});

describe('isOlderThan', () => {
  it('should_return_true_when_strictly_older', () => {
    expect(isOlderThan('5.4.0', '6.0.0')).toBe(true);
  });

  it('should_return_false_when_equal', () => {
    expect(isOlderThan('6.0.0', '6.0.0')).toBe(false);
  });

  it('should_return_false_when_newer', () => {
    expect(isOlderThan('6.1.0', '6.0.0')).toBe(false);
  });
});
