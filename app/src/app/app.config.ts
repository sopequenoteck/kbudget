import {
  ApplicationConfig,
  provideAppInitializer,
  provideBrowserGlobalErrorListeners,
  isDevMode,
  inject,
} from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideAnimations } from '@angular/platform-browser/animations';
import { firstValueFrom } from 'rxjs';
import { TranslocoService, provideTransloco } from '@jsverse/transloco';
import { provideTranslocoMessageformat } from '@jsverse/transloco-messageformat';

import { authInterceptor } from './core/interceptors/auth.interceptor';
import { TranslocoHttpLoader } from './core/i18n/transloco-loader';
import { provideLanguageBootstrap } from './core/services/language';

import { routes } from './app.routes';
import { provideServiceWorker } from '@angular/service-worker';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideAnimations(),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withInterceptors([authInterceptor])),
    provideServiceWorker('ngsw-worker.js', {
      enabled: !isDevMode(),
      registrationStrategy: 'registerWhenStable:30000',
    }),
    // Transloco (KKS-373, D5) : francais par defaut et de repli, transpileur
    // MessageFormat pour l'ICU. Catalogues charges a l'execution depuis
    // `/i18n/`, jamais incorpores au bundle.
    // Ne pas regler `interpolation` sur `{ }` : l'interpolation de Transloco
    // passerait alors avant MessageFormat et viderait tout bloc de pluriel ICU.
    // MessageFormat traite deja les parametres simples `{name}`, ce qui garde
    // les chaines identiques a celles de l'ARB Flutter (docs/i18n.md).
    provideTransloco({
      config: {
        availableLangs: ['en', 'fr'],
        defaultLang: 'fr',
        fallbackLang: 'fr',
        missingHandler: { useFallbackTranslation: true },
        reRenderOnLangChange: true,
        prodMode: !isDevMode(),
      },
      loader: TranslocoHttpLoader,
    }),
    provideTranslocoMessageformat(),
    // D6 : la langue par defaut est chargee avant le premier rendu — sans
    // cela, une resolution synchrone de cle (ApiErrorService) pourrait
    // rendre la cle brute plutot qu'un texte. Les ecrans non authentifies
    // (connexion, invitation, reinitialisation) s'affichent avant toute
    // lecture de preference : on ne precharge que le francais, jamais on
    // n'attend le serveur pour peindre le premier ecran.
    provideAppInitializer(() => {
      const transloco = inject(TranslocoService);
      return firstValueFrom(transloco.load(transloco.getDefaultLang()));
    }),
    // KKS-373 (D8) : demarre `LanguageService` des la creation de
    // l'injecteur, avant tout composant — voir le commentaire de la fonction
    // pour la justification du choix d'`ENVIRONMENT_INITIALIZER`.
    provideLanguageBootstrap(),
  ],
};
