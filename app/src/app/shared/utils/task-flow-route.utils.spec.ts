import { isTaskFlowRoute } from './task-flow-route.utils';

describe('isTaskFlowRoute', () => {
  it.each([
    ['/settings', true],
    ['/settings/accounts', true],
    ['/transactions/import', true],
    ['/transactions/import/review/draft-1', true],
    ['/transactions', false],
    ['/transactions/recurring', false],
    ['/dashboard', false],
  ])('should_return_%s_as_%s_when_deciding_whether_the_fab_is_hidden', (url, expected) => {
    expect(isTaskFlowRoute(url)).toBe(expected);
  });
});
