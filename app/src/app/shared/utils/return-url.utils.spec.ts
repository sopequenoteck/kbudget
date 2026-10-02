import { isInternalReturnUrl } from './return-url.utils';

describe('isInternalReturnUrl', () => {
  it.each(['/', '/dashboard', '/transactions?x=1', '/settings/import#top'])(
    'should_accept_internal_path_%s',
    (url) => {
      expect(isInternalReturnUrl(url)).toBe(true);
    },
  );

  it.each(['', 'dashboard', 'http://evil.com', 'HTTPS://evil.com', '//evil.com', '/\\evil.com'])(
    'should_reject_non_internal_url_%s',
    (url) => {
      expect(isInternalReturnUrl(url)).toBe(false);
    },
  );
});
