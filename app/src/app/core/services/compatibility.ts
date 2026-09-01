import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

import { environment } from '../../../environments/environment';
import { type CompatibilityStatus, type ServerMeta } from '../models/meta.model';
import { isOlderThan } from './version-compare';
import packageJson from '../../../../package.json';

/**
 * Version de serveur la plus ancienne que ce client sait exploiter (KKS-314).
 *
 * Ne bouge qu'a une rupture de contrat cote serveur. `6.1.0` est la version qui
 * introduit `/api/meta` : un serveur anterieur ne sait pas se decrire.
 */
export const MIN_SERVER_VERSION = '6.1.0';

@Injectable({ providedIn: 'root' })
export class CompatibilityService {
  private readonly http = inject(HttpClient);

  private readonly _status = signal<CompatibilityStatus | null>(null);
  readonly status = this._status.asReadonly();

  /**
   * Interroge `/api/meta` et classe le serveur.
   *
   * L'endpoint vit a la racine de l'API, hors versionnement : un client ne peut
   * pas deviner le prefixe du serveur qu'il interroge, c'est ce qu'il vient lui
   * demander.
   */
  async check(): Promise<CompatibilityStatus> {
    const clientVersion = packageJson.version;
    let meta: ServerMeta;

    try {
      meta = await firstValueFrom(
        this.http.get<ServerMeta>(`${environment.apiRootUrl}/meta`),
      );
    } catch (error: unknown) {
      const status = (error as { status?: number })?.status;

      // 404 : le serveur repond mais ignore /api/meta — il est anterieur a
      // KKS-314, donc trop ancien. Toute autre issue (0, timeout, 5xx) signifie
      // qu'on ne sait pas : hors ligne, jamais incompatible.
      const result: CompatibilityStatus =
        status === 404
          ? { kind: 'serverTooOld', serverVersion: null, requiredVersion: MIN_SERVER_VERSION }
          : { kind: 'offline' };

      this._status.set(result);
      return result;
    }

    let result: CompatibilityStatus;
    if (isOlderThan(clientVersion, meta.minClientVersion)) {
      result = { kind: 'clientTooOld', clientVersion, requiredVersion: meta.minClientVersion };
    } else if (isOlderThan(meta.serverVersion, MIN_SERVER_VERSION)) {
      result = {
        kind: 'serverTooOld',
        serverVersion: meta.serverVersion,
        requiredVersion: MIN_SERVER_VERSION,
      };
    } else {
      result = { kind: 'compatible', meta };
    }

    this._status.set(result);
    return result;
  }
}
