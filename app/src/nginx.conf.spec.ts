import { readFileSync } from 'node:fs';

const nginxConfig = readFileSync('nginx.conf', 'utf8');

function extractLocationBlock(config: string, locationHeader: RegExp): string {
  const match = locationHeader.exec(config);
  expect(match, `Bloc Nginx introuvable: ${locationHeader}`).not.toBeNull();

  const openingBrace = config.indexOf('{', match!.index);
  let depth = 0;

  for (let index = openingBrace; index < config.length; index += 1) {
    if (config[index] === '{') depth += 1;
    if (config[index] === '}') depth -= 1;

    if (depth === 0) return config.slice(openingBrace + 1, index);
  }

  throw new Error('Bloc Nginx non ferme');
}

function assertApiRoutingIsProtected(config: string): void {
  const apiBlock = extractLocationBlock(config, /location\s+\^~\s+\/api\/\s*\{/);

  expect(apiBlock).toMatch(/proxy_pass\s+http:\/\/api:8080\/api\/\s*;/);
}

describe('nginx.conf - routage API', () => {
  it('protege les logos SVG de toute regex de location par le prefixe prioritaire', () => {
    // `^~` l'emporte sur toute location regex : une regle de cache par extension ne peut pas
    // intercepter /api/bank-logos/*.svg, qui doit etre servi par le conteneur api.
    expect(() => assertApiRoutingIsProtected(nginxConfig)).not.toThrow();
  });

  it('rejette les régressions de priorite et de proxy API', () => {
    const withoutPrefixPriority = nginxConfig.replace('location ^~ /api/', 'location /api/');
    const withWrongProxy = nginxConfig.replace(
      'proxy_pass http://api:8080/api/;',
      'proxy_pass http://frontend:8080/api/;',
    );

    expect(() => assertApiRoutingIsProtected(withoutPrefixPriority)).toThrow();
    expect(() => assertApiRoutingIsProtected(withWrongProxy)).toThrow();
  });
});

interface NginxLocation {
  modifier: string;
  path: string;
  body: string;
}

/** Commentaires retires : un mot cite dans une explication (« immutable », « {8} ») n'est pas une directive. */
function withoutComments(config: string): string {
  return config.replaceAll(/^\s*#.*$/gm, '');
}

/** Les location du fichier ; aucun bloc ne contient d'accolade imbriquee. */
const LOCATION_PATTERN = /location\s+(=|\^~|~\*?)?\s*("[^"]+"|[^\s{]+)\s*\{([^}]*)\}/g;

function parseLocations(config: string): NginxLocation[] {
  return [...withoutComments(config).matchAll(LOCATION_PATTERN)].map((match) => ({
    modifier: match[1] ?? '',
    path: match[2].replaceAll('"', ''),
    body: match[3],
  }));
}

function exactLocation(path: string): NginxLocation {
  const found = parseLocations(nginxConfig).find(
    (location) => location.modifier === '=' && location.path === path,
  );
  expect(found, `location = ${path} introuvable`).toBeDefined();
  return found as NginxLocation;
}

function cacheControlOf(location: NginxLocation): string[] {
  return [...location.body.matchAll(/add_header\s+Cache-Control\s+([^;]+);/g)].map((m) => m[1].trim());
}

describe('nginx.conf - en-tetes de cache (KKS-446)', () => {
  it.each([
    ['/index.html', '"no-cache, no-transform" always'],
    ['/ngsw-worker.js', '"no-cache" always'],
    ['/ngsw.json', '"no-cache" always'],
    ['/manifest.webmanifest', '"no-cache" always'],
    ['/safety-worker.js', '"no-cache" always'],
  ])('should_serve_%s_with_exact_cache_control_when_requested', (path, expected) => {
    expect(cacheControlOf(exactLocation(path))).toEqual([expected]);
  });

  it('should_forbid_transform_on_index_html_when_a_proxy_could_rewrite_it', () => {
    expect(cacheControlOf(exactLocation('/index.html'))[0]).toContain('no-transform');
  });

  it('should_emit_every_cache_control_with_always_when_a_revalidation_answers_304', () => {
    const headers = parseLocations(nginxConfig).flatMap(cacheControlOf);

    expect(headers.length).toBeGreaterThan(0);
    for (const header of headers) {
      expect(header).toMatch(/\balways$/);
    }
  });

  it('should_not_use_expires_when_it_would_add_a_second_cache_control', () => {
    expect(withoutComments(nginxConfig)).not.toMatch(/^\s*expires\s/m);
  });

  it('should_declare_no_add_header_outside_a_location_when_inheritance_is_all_or_nothing', () => {
    const outsideLocations = withoutComments(nginxConfig).replaceAll(LOCATION_PATTERN, '');

    expect(outsideLocations).not.toContain('add_header');
  });

  it('should_not_add_headers_to_the_api_proxy_when_it_must_forward_the_api_answer_untouched', () => {
    const api = parseLocations(nginxConfig).find((location) => location.modifier === '^~');

    expect(api?.path).toBe('/api/');
    expect(api?.body).not.toContain('add_header');
  });

  describe('fichiers a empreinte', () => {
    const fingerprinted = parseLocations(nginxConfig).filter((location) =>
      location.body.includes('immutable'),
    );

    it('should_limit_immutable_to_the_fingerprint_regex_and_media_when_caching_for_a_year', () => {
      expect(fingerprinted.map((location) => `${location.modifier} ${location.path}`)).toEqual([
        String.raw`~ ^/[^/]+-[A-Z0-9]{8}\.(?:js|css)$`,
        '^~ /media/',
      ]);
      for (const location of fingerprinted) {
        expect(cacheControlOf(location)).toEqual(['"public, max-age=31536000, immutable" always']);
      }
    });

    const hashRegex = (): RegExp => {
      const location = fingerprinted.find((candidate) => candidate.modifier === '~');
      expect(location, 'regex des fichiers a empreinte introuvable').toBeDefined();
      return new RegExp(location!.path);
    };

    it.each(['/main-34LHKCSC.js', '/chunk-233JN6NA.js', '/styles-RIKCPSOA.css', '/polyfills-A1B2C3D4.js'])(
      'should_treat_%s_as_fingerprinted_when_built_with_output_hashing',
      (url) => {
        expect(url).toMatch(hashRegex());
      },
    );

    it.each([
      '/ngsw-worker.js',
      '/safety-worker.js',
      '/worker-basic.min.js',
      '/ngsw.json',
      '/manifest.webmanifest',
      '/favicon.ico',
      '/icons/icon-192x192.png',
      '/icons/budget-icon.svg',
      '/i18n/fr.json',
      '/main-34lhkcsc.js',
      '/main-34LHKC.js',
      '/api/bank-logos/demo-ABCD1234.js',
    ])('should_never_treat_%s_as_fingerprinted_when_it_has_no_build_hash', (url) => {
      expect(url).not.toMatch(hashRegex());
    });
  });

  describe('repli', () => {
    const fallback = (): NginxLocation => {
      const found = parseLocations(nginxConfig).find(
        (location) => location.modifier === '' && location.path === '/',
      );
      expect(found, 'location / introuvable').toBeDefined();
      return found as NginxLocation;
    };

    it('should_revalidate_unhashed_assets_when_served_by_the_fallback_location', () => {
      expect(cacheControlOf(fallback())).toEqual(['"no-cache" always']);
      expect(fallback().body).not.toContain('immutable');
    });

    it('should_fall_back_to_index_html_when_the_route_is_a_spa_route', () => {
      // La redirection interne du try_files retombe sur « location = /index.html » (no-transform).
      expect(fallback().body).toMatch(/try_files\s+\$uri\s+\$uri\/\s+\/index\.html\s*;/);
    });
  });
});
