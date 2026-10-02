import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { ImportService } from './import';
import { ApiService } from './api';
import { confirmResult, importDetection } from '../../../testing/import-fixtures';

describe('ImportService', () => {
  let service: ImportService;
  let apiService: {
    get: ReturnType<typeof vi.fn>;
    post: ReturnType<typeof vi.fn>;
    put: ReturnType<typeof vi.fn>;
    delete: ReturnType<typeof vi.fn>;
    postFormData: ReturnType<typeof vi.fn>;
  };

  beforeEach(() => {
    apiService = {
      get: vi.fn(),
      post: vi.fn(),
      put: vi.fn(),
      delete: vi.fn(),
      postFormData: vi.fn(),
    };
    TestBed.configureTestingModule({
      providers: [ImportService, { provide: ApiService, useValue: apiService }],
    });
    service = TestBed.inject(ImportService);
  });

  it('should_post_the_file_to_detect_and_return_the_detection', () => {
    const detection = importDetection({ suggestedAccountId: 'acc-1' });
    apiService.postFormData.mockReturnValue(of(detection));
    const file = new File(['a;b'], 'releve.csv');
    let result;

    service.detect(file).subscribe((value) => (result = value));

    expect(result).toEqual(detection);
    const [path, formData] = apiService.postFormData.mock.calls[0] as [string, FormData];
    expect(path).toBe('/imports/detect');
    expect(formData.get('file')).toBe(file);
    expect(formData.has('accountId')).toBe(false);
  });

  it('should_not_refresh_the_import_lists_when_detecting', () => {
    apiService.postFormData.mockReturnValue(of(importDetection()));

    service.detect(new File(['a'], 'releve.csv')).subscribe();

    expect(service.refreshTrigger()).toBe(0);
  });

  it('should_confirm_without_the_opening_balance_by_default', () => {
    apiService.post.mockReturnValue(of(confirmResult()));

    service.confirm('draft-1').subscribe();

    expect(apiService.post).toHaveBeenCalledWith('/imports/drafts/draft-1/confirm', {
      applyOpeningBalance: false,
    });
    expect(service.refreshTrigger()).toBe(1);
  });

  it('should_send_the_opening_balance_choice_when_confirming', () => {
    apiService.post.mockReturnValue(of(confirmResult()));

    service.confirm('draft-1', true).subscribe();

    expect(apiService.post).toHaveBeenCalledWith('/imports/drafts/draft-1/confirm', {
      applyOpeningBalance: true,
    });
  });

  it('should_send_a_line_update_with_the_match_fields', () => {
    apiService.put.mockReturnValue(of({}));

    service.updateLine('draft-1', 'line-1', { matchedTransactionId: 'tx-1' }).subscribe();
    service.updateLine('draft-1', 'line-1', { clearMatch: true }).subscribe();

    expect(apiService.put).toHaveBeenNthCalledWith(1, '/imports/drafts/draft-1/lines/line-1', {
      matchedTransactionId: 'tx-1',
    });
    expect(apiService.put).toHaveBeenNthCalledWith(2, '/imports/drafts/draft-1/lines/line-1', {
      clearMatch: true,
    });
  });
});
