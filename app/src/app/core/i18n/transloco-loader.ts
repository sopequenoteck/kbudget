import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Translation, TranslocoLoader } from '@jsverse/transloco';

/**
 * Charge les catalogues a l'execution depuis `app/public/i18n/` (KKS-373).
 *
 * Aucune traduction n'est incorporee au bundle : une seule image sert toutes
 * les langues (principe VII, D5). Les fichiers sont servis a la racine du
 * site et mis en cache par le service worker (`ngsw-config.json`, D7).
 */
@Injectable({ providedIn: 'root' })
export class TranslocoHttpLoader implements TranslocoLoader {
  private readonly http = inject(HttpClient);

  getTranslation(lang: string): Observable<Translation> {
    return this.http.get<Translation>(`/i18n/${lang}.json`);
  }
}
