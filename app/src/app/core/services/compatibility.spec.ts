import { TestBed } from '@angular/core/testing';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient } from '@angular/common/http';

import { CompatibilityService, MIN_SERVER_VERSION } from './compatibility';
import { type ServerMeta } from '../models/meta.model';
import packageJson from '../../../../package.json';

const META_URL = '/api/meta';

const validMeta: ServerMeta = {
  serverVersion: '9.9.9',
  apiVersion: 'v1',
  minClientVersion: '0.0.1',
  capabilities: ['SUBSCRIPTIONS', 'DEBTS', 'BUDGETS'],
};

describe('CompatibilityService', () => {
  let service: CompatibilityService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [CompatibilityService, provideHttpClient(), provideHttpClientTesting()],
    });
    service = TestBed.inject(CompatibilityService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should_call_meta_without_version_prefix', async () => {
    const promise = service.check();
    // Le prefixe de version est precisement ce que le client vient decouvrir :
    // demander /api/v1/meta supposerait connu ce qu'on cherche a savoir.
    httpMock.expectOne(META_URL).flush(validMeta);
    await promise;
  });

  it('should_report_compatible_when_both_versions_satisfy', async () => {
    const promise = service.check();
    httpMock.expectOne(META_URL).flush(validMeta);
    const status = await promise;

    expect(status.kind).toBe('compatible');
  });

  it('should_report_serverTooOld_when_meta_returns_404', async () => {
    const promise = service.check();
    httpMock
      .expectOne(META_URL)
      .flush('Not Found', { status: 404, statusText: 'Not Found' });
    const status = await promise;

    expect(status).toEqual({
      kind: 'serverTooOld',
      serverVersion: null,
      requiredVersion: MIN_SERVER_VERSION,
    });
  });

  it('should_report_offline_and_not_serverTooOld_when_request_fails', async () => {
    // Distinction critique : un serveur injoignable n'est pas un serveur
    // incompatible. Les confondre afficherait « mettez votre serveur a jour »
    // a un utilisateur simplement hors ligne.
    const promise = service.check();
    httpMock.expectOne(META_URL).error(new ProgressEvent('network error'));
    const status = await promise;

    expect(status.kind).toBe('offline');
  });

  it('should_report_offline_when_server_returns_500', async () => {
    const promise = service.check();
    httpMock
      .expectOne(META_URL)
      .flush('Boom', { status: 500, statusText: 'Internal Server Error' });
    const status = await promise;

    expect(status.kind).toBe('offline');
  });

  it('should_report_serverTooOld_when_server_version_below_minimum', async () => {
    const promise = service.check();
    httpMock.expectOne(META_URL).flush({ ...validMeta, serverVersion: '1.0.0' });
    const status = await promise;

    expect(status).toEqual({
      kind: 'serverTooOld',
      serverVersion: '1.0.0',
      requiredVersion: MIN_SERVER_VERSION,
    });
  });

  it('should_report_clientTooOld_when_client_below_minClientVersion', async () => {
    const promise = service.check();
    httpMock.expectOne(META_URL).flush({ ...validMeta, minClientVersion: '999.0.0' });
    const status = await promise;

    expect(status).toEqual({
      kind: 'clientTooOld',
      clientVersion: packageJson.version,
      requiredVersion: '999.0.0',
    });
  });

  it('should_prioritise_clientTooOld_over_serverTooOld', async () => {
    // Les deux conditions peuvent etre vraies simultanement. Demander a
    // l'utilisateur de mettre a jour son app est actionnable ; lui demander de
    // mettre a jour un serveur qui exige deja plus recent que lui ne l'est pas.
    const promise = service.check();
    httpMock
      .expectOne(META_URL)
      .flush({ ...validMeta, serverVersion: '1.0.0', minClientVersion: '999.0.0' });
    const status = await promise;

    expect(status.kind).toBe('clientTooOld');
  });

  it('should_expose_status_as_signal_after_check', async () => {
    expect(service.status()).toBeNull();

    const promise = service.check();
    httpMock.expectOne(META_URL).flush(validMeta);
    await promise;

    expect(service.status()?.kind).toBe('compatible');
  });
});
