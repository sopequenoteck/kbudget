import { Routes } from '@angular/router';

import { IMPORTS_ROUTES } from './imports.routes';
import { ImportReview } from './import-review/import-review';
import { ImportStart } from './import-start/import-start';
import { TRANSACTIONS_ROUTES } from '../transactions/transactions.routes';

describe('IMPORTS_ROUTES', () => {
  it('should_load_the_start_component_on_the_empty_path', async () => {
    const start = IMPORTS_ROUTES.find((route) => route.path === '')!;

    expect(await (start.loadComponent as () => Promise<unknown>)()).toBe(ImportStart);
  });

  it('should_load_the_review_component_with_the_draft_id_in_the_path', async () => {
    const review = IMPORTS_ROUTES.find((route) => route.path === 'review/:draftId')!;

    expect(await (review.loadComponent as () => Promise<unknown>)()).toBe(ImportReview);
  });

  it('should_be_mounted_under_transactions_import', async () => {
    const mount = TRANSACTIONS_ROUTES.find((route) => route.path === 'import')!;

    expect(await (mount.loadChildren as () => Promise<Routes>)()).toBe(IMPORTS_ROUTES);
  });
});
