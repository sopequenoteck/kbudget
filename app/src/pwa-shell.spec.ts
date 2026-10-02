import { readFileSync } from 'node:fs';

interface Manifest {
  id?: string;
  start_url: string;
  scope: string;
  theme_color: string;
  background_color: string;
}

const indexHtml = readFileSync('src/index.html', 'utf8');
const manifest = JSON.parse(readFileSync('public/manifest.webmanifest', 'utf8')) as Manifest;

/** Contenu de la premiere balise `<meta name="...">` trouvee, null si absente. */
function metaContent(name: string): string | null {
  const tag = new RegExp(String.raw`<meta\s+name="${name}"\s+content="([^"]*)"`).exec(indexHtml);
  return tag ? tag[1] : null;
}

describe('index.html - shell mobile de la PWA (KKS-447)', () => {
  it('should_extend_the_viewport_under_the_notch_when_viewport_fit_is_cover', () => {
    expect(metaContent('viewport')).toContain('viewport-fit=cover');
  });

  it('should_keep_the_device_width_viewport_when_viewport_fit_is_added', () => {
    expect(metaContent('viewport')).toContain('width=device-width');
  });

  it('should_let_the_header_slide_under_the_status_bar_when_the_ios_pwa_is_installed', () => {
    expect(metaContent('apple-mobile-web-app-status-bar-style')).toBe('black-translucent');
  });

  it('should_start_with_the_dark_header_surface_when_no_theme_is_applied_yet', () => {
    expect(metaContent('theme-color')).toBe('#1e1e1e');
  });
});

describe('manifest.webmanifest - identite et couleurs (KKS-447)', () => {
  it('should_keep_the_implicit_identity_when_an_id_is_declared', () => {
    // L'identite implicite est l'URL de `start_url` resolue : `./` sur le manifeste servi a la
    // racine donne `/`. Un autre `id` creerait une seconde installation.
    const resolvedStartUrl = new URL(
      manifest.start_url,
      'https://example.test/manifest.webmanifest',
    );

    expect(manifest.id).toBe('/');
    expect(new URL(manifest.id ?? '', 'https://example.test/').href).toBe(resolvedStartUrl.href);
  });

  it('should_use_the_dark_background_when_the_manifest_cannot_follow_the_theme', () => {
    expect(manifest.background_color).toBe('#0a0a0a');
  });

  it('should_use_the_dark_theme_color_when_the_manifest_cannot_follow_the_theme', () => {
    expect(manifest.theme_color).toBe('#1e1e1e');
  });

  it('should_keep_the_scope_on_the_start_url_when_the_id_is_declared', () => {
    expect(new URL(manifest.scope, 'https://example.test/manifest.webmanifest').href).toBe(
      new URL(manifest.start_url, 'https://example.test/manifest.webmanifest').href,
    );
  });
});
