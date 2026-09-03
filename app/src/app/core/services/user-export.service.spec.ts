import { TestBed } from '@angular/core/testing';
import { HttpClient, HttpResponse, HttpHeaders } from '@angular/common/http';
import { of } from 'rxjs';
import { firstValueFrom } from 'rxjs';

import { UserExportService } from './user-export.service';

describe('UserExportService', () => {
  let service: UserExportService;
  let httpClient: { get: ReturnType<typeof vi.fn> };
  let mockCreateObjectURL: ReturnType<typeof vi.fn>;
  let mockRevokeObjectURL: ReturnType<typeof vi.fn>;
  let createdAnchor: { href: string; download: string; click: ReturnType<typeof vi.fn> };

  beforeEach(() => {
    httpClient = { get: vi.fn() };

    mockCreateObjectURL = vi.fn().mockReturnValue('blob:http://localhost/fake-url');
    mockRevokeObjectURL = vi.fn();

    vi.stubGlobal('URL', {
      createObjectURL: mockCreateObjectURL,
      revokeObjectURL: mockRevokeObjectURL,
    });

    createdAnchor = { href: '', download: '', click: vi.fn() };
    vi.spyOn(document, 'createElement').mockImplementation((tag: string) => {
      if (tag === 'a') return createdAnchor as unknown as HTMLElement;
      return document.createElement(tag);
    });

    TestBed.configureTestingModule({
      providers: [UserExportService, { provide: HttpClient, useValue: httpClient }],
    });

    service = TestBed.inject(UserExportService);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  describe('exportJson', () => {
    it('should_trigger_download_when_exportJson_called', async () => {
      const blob = new Blob(['{"schemaVersion":"1.0.0"}'], { type: 'application/json' });
      const headers = new HttpHeaders({
        'Content-Disposition': 'attachment; filename="kbudget-export-usr1-20260430.json"',
      });
      const response = new HttpResponse({ body: blob, headers });

      httpClient.get.mockReturnValue(of(response));

      await firstValueFrom(service.exportJson());

      expect(httpClient.get).toHaveBeenCalledWith(
        expect.stringContaining('/users/me/export?format=json'),
        expect.objectContaining({ responseType: 'blob', observe: 'response' }),
      );
      expect(mockCreateObjectURL).toHaveBeenCalledWith(blob);
      expect(createdAnchor.download).toBe('kbudget-export-usr1-20260430.json');
      expect(createdAnchor.click).toHaveBeenCalled();
      expect(mockRevokeObjectURL).toHaveBeenCalledWith('blob:http://localhost/fake-url');
    });

    it('should_use_fallback_filename_when_no_content_disposition', async () => {
      const blob = new Blob(['{}'], { type: 'application/json' });
      const response = new HttpResponse({ body: blob, headers: new HttpHeaders() });

      httpClient.get.mockReturnValue(of(response));

      await firstValueFrom(service.exportJson());

      expect(createdAnchor.download).toMatch(/^kbudget-export-\d{8}\.json$/);
    });
  });

  describe('exportCsv', () => {
    it('should_trigger_download_when_exportCsv_called', async () => {
      const blob = new Blob(['Date,Libellé'], { type: 'text/csv' });
      const headers = new HttpHeaders({
        'Content-Disposition': 'attachment; filename="kbudget-transactions-usr1-20260430.csv"',
      });
      const response = new HttpResponse({ body: blob, headers });

      httpClient.get.mockReturnValue(of(response));

      await firstValueFrom(service.exportCsv());

      expect(httpClient.get).toHaveBeenCalledWith(
        expect.stringContaining('/users/me/export?format=csv'),
        expect.objectContaining({ responseType: 'blob', observe: 'response' }),
      );
      expect(createdAnchor.download).toBe('kbudget-transactions-usr1-20260430.csv');
      expect(createdAnchor.click).toHaveBeenCalled();
    });

    it('should_use_fallback_filename_when_no_content_disposition', async () => {
      const blob = new Blob(['Date,Libellé'], { type: 'text/csv' });
      const response = new HttpResponse({ body: blob, headers: new HttpHeaders() });

      httpClient.get.mockReturnValue(of(response));

      await firstValueFrom(service.exportCsv());

      expect(createdAnchor.download).toMatch(/^kbudget-transactions-\d{8}\.csv$/);
    });
  });
});
