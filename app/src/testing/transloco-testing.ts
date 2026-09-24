import {
  EnvironmentProviders,
  Injectable,
  Provider,
  inject,
  provideEnvironmentInitializer,
} from '@angular/core';
import { Observable, of } from 'rxjs';
import {
  Translation,
  TranslocoLoader,
  TranslocoService,
  provideTransloco,
} from '@jsverse/transloco';
import { provideTranslocoMessageformat } from '@jsverse/transloco-messageformat';

// Vrais catalogues (D10, FR-033) : un utilitaire qui les mockerait
// prouverait la plomberie, jamais le contenu — et n'aurait pas detecte une
// erreur de transcription lors du deplacement du catalogue d'erreurs
// (KKS-373).
import fr from '../../public/i18n/fr.json';
import en from '../../public/i18n/en.json';

const CATALOGUES: Readonly<Record<string, Translation>> = { fr, en };

@Injectable()
class StaticCatalogueLoader implements TranslocoLoader {
  getTranslation(lang: string): Observable<Translation> {
    return of(CATALOGUES[lang] ?? {});
  }
}

/**
 * Fournit Transloco pour la suite Angular (vitest), avec les **vrais**
 * catalogues francais et anglais preinjectes — aucune requete HTTP, aucun
 * mock de traduction — et le francais actif, sans configuration
 * additionnelle (D10, FR-033, US6).
 *
 * Le chargeur est synchrone (`of(...)`) : contrairement au chargeur HTTP de
 * production, il ne fait la aucune hypothese sur l'ordre d'execution d'un
 * `APP_INITIALIZER`, qui n'est pas garanti sous `TestBed`. Le chargement de
 * la langue active est declenche par `provideEnvironmentInitializer`, execute
 * de facon synchrone a la creation de l'injecteur — y compris sous
 * `TestBed` — de sorte qu'un `TestBed.inject(TranslocoService).translate(...)`
 * resout une cle reelle des la premiere ligne d'un spec.
 */
export function provideTranslocoTesting(): (Provider | EnvironmentProviders)[] {
  return [
    provideTransloco({
      config: {
        availableLangs: ['en', 'fr'],
        defaultLang: 'fr',
        fallbackLang: 'fr',
        missingHandler: { useFallbackTranslation: true },
        reRenderOnLangChange: true,
        prodMode: true,
      },
      loader: StaticCatalogueLoader,
    }),
    provideTranslocoMessageformat(),
    provideEnvironmentInitializer(() => {
      const transloco = inject(TranslocoService);
      transloco.load(transloco.getDefaultLang()).subscribe();
    }),
  ];
}
