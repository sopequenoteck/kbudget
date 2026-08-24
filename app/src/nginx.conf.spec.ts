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
  const assetLocation = /location\s+~\*?\s+([^\r\n{]+)\s*\{/.exec(config);

  expect(assetLocation, 'Regex generique des assets introuvable').not.toBeNull();
  expect('/api/bank-logos/demo.svg').toMatch(new RegExp(assetLocation![1].trim(), 'i'));
  expect(apiBlock).toMatch(/proxy_pass\s+http:\/\/api:8080\/api\/\s*;/);
}

describe('nginx.conf - routage API', () => {
  it('protege les logos SVG de la regex generique des assets', () => {
    expect('/api/bank-logos/demo.svg').toMatch(/^\/api\//);
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
