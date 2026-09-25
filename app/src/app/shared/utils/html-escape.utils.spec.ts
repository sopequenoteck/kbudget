import { escapeHtml } from './html-escape.utils';

describe('escapeHtml', () => {
  it('should_escape_ampersand', () => {
    expect(escapeHtml('Café & Co')).toBe('Café &amp; Co');
  });

  it('should_escape_less_than', () => {
    expect(escapeHtml('a < b')).toBe('a &lt; b');
  });

  it('should_escape_greater_than', () => {
    expect(escapeHtml('a > b')).toBe('a &gt; b');
  });

  it('should_escape_double_quote', () => {
    expect(escapeHtml('say "hi"')).toBe('say &quot;hi&quot;');
  });

  it('should_escape_single_quote', () => {
    expect(escapeHtml("l'import")).toBe('l&#39;import');
  });

  it('should_escape_an_html_injection_attempt', () => {
    expect(escapeHtml('<img src=x onerror=alert(1)>Café & Co')).toBe(
      '&lt;img src=x onerror=alert(1)&gt;Café &amp; Co',
    );
  });

  it('should_return_string_unchanged_when_no_special_character', () => {
    expect(escapeHtml('BOULANGERIE TEST')).toBe('BOULANGERIE TEST');
  });
});
