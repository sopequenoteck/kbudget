import { readFileSync } from 'node:fs';

interface AssetGroup {
  name: string;
  resources: { files?: string[] };
}

const config = JSON.parse(readFileSync('ngsw-config.json', 'utf8')) as {
  assetGroups: AssetGroup[];
};

describe('ngsw-config.json - worker de secours (KKS-446)', () => {
  it('should_exclude_safety_worker_from_the_app_group_when_it_matches_the_js_glob', () => {
    const files = config.assetGroups.find((group) => group.name === 'app')?.resources.files ?? [];

    expect(files).toContain('/*.js');
    expect(files).toContain('!/safety-worker.js');
  });

  it('should_never_cache_safety_worker_in_any_asset_group_when_it_is_a_remote_fix_channel', () => {
    for (const group of config.assetGroups) {
      expect(group.resources.files ?? []).not.toContain('/safety-worker.js');
    }
  });
});
