import { getTestBed, TestBed } from '@angular/core/testing';
import { BrowserTestingModule, platformBrowserTesting } from '@angular/platform-browser/testing';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient } from '@angular/common/http';

import { TransactionLibelleService } from './transaction-libelle.service';

if (!getTestBed().platform) {
  getTestBed().initTestEnvironment(BrowserTestingModule, platformBrowserTesting());
}

describe('TransactionLibelleService', () => {
  let service: TransactionLibelleService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        TransactionLibelleService,
        provideHttpClient(),
        provideHttpClientTesting(),
      ],
    });
    service = TestBed.inject(TransactionLibelleService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should_call_GET_libelles_with_q_and_limit', () => {
    let result: string[] | undefined;
    service.search('car', 10).subscribe((r) => (result = r));

    const req = httpMock.expectOne((r) => {
      return (
        r.url === '/api/v1/transactions/libelles' &&
        r.params.get('q') === 'car' &&
        r.params.get('limit') === '10'
      );
    });
    expect(req.request.method).toBe('GET');
    req.flush(['Carrefour', 'Carte bleue']);

    expect(result).toEqual(['Carrefour', 'Carte bleue']);
  });

  it('should_return_empty_on_http_error', () => {
    let result: string[] | undefined;
    service.search('err', 20).subscribe((r) => (result = r));

    const req = httpMock.expectOne((r) => r.url === '/api/v1/transactions/libelles');
    req.flush('Erreur serveur', { status: 500, statusText: 'Internal Server Error' });

    expect(result).toEqual([]);
  });

  it('should_not_include_q_param_when_empty', () => {
    let result: string[] | undefined;
    service.search('', 20).subscribe((r) => (result = r));

    const req = httpMock.expectOne((r) => {
      return (
        r.url === '/api/v1/transactions/libelles' &&
        !r.params.has('q') &&
        r.params.get('limit') === '20'
      );
    });
    expect(req.request.method).toBe('GET');
    req.flush(['Loyer', 'Courses']);

    expect(result).toEqual(['Loyer', 'Courses']);
  });
});
