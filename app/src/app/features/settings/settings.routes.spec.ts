import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { HistoryCleanup } from '../imports/history-cleanup/history-cleanup';
import { SETTINGS_ROUTES } from './settings.routes';

describe('SETTINGS_ROUTES', () => {
  it('should_redirect_the_old_review_url_to_the_new_review_with_the_draft_id', async () => {
    TestBed.configureTestingModule({
      providers: [
        provideRouter([
          { path: 'settings', children: SETTINGS_ROUTES },
          { path: 'transactions/import/review/:draftId', children: [] },
        ]),
      ],
    });
    const router = TestBed.inject(Router);

    await router.navigateByUrl('/settings/import/review/draft-42');

    expect(router.url).toBe('/transactions/import/review/draft-42');
  });

  it('should_keep_the_mapping_under_settings', () => {
    const paths = SETTINGS_ROUTES.map((route) => route.path);

    expect(paths).toContain('import/mapping');
    expect(paths).toContain('import');
  });

  it('should_load_the_history_cleanup_under_settings_import', async () => {
    const route = SETTINGS_ROUTES.find((candidate) => candidate.path === 'import/history-cleanup');
    expect(route?.loadComponent).toBeDefined();

    const component = await (route?.loadComponent as () => Promise<unknown>)();

    expect(component).toBe(HistoryCleanup);
  });
});
