import {
  ApplicationConfig,
  provideAppInitializer,
  provideBrowserGlobalErrorListeners,
  isDevMode,
  inject,
} from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';
import { provideHttpClient, withInterceptors, withXhr } from '@angular/common/http';
import { provideAnimations } from '@angular/platform-browser/animations';
import { firstValueFrom } from 'rxjs';
import { TranslocoService, provideTransloco } from '@jsverse/transloco';
import { provideTranslocoMessageformat } from '@jsverse/transloco-messageformat';

import { AppUpdateService } from './core/pwa/app-update';
import { provideAppUpdateCanApply } from './core/pwa/app-update-can-apply';
import { authInterceptor } from './core/interceptors/auth.interceptor';
import { TranslocoHttpLoader } from './core/i18n/transloco-loader';
import {
  BROWSER_LANGUAGES,
  LANGUAGE_STORAGE,
  provideLanguageBootstrap,
  resolveBootstrapLanguage,
} from './core/services/language';

import { routes } from './app.routes';
import { provideServiceWorker } from '@angular/service-worker';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideAnimations(),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withXhr(), withInterceptors([authInterceptor])),
    provideServiceWorker('ngsw-worker.js', {
      enabled: !isDevMode(),
      registrationStrategy: 'registerWhenStable:30000',
    }),
    // Transloco (KKS-373, D5 ; anglais par defaut depuis KKS-380) : anglais
    // par defaut et de repli — langue source de `docs/i18n.md`, jamais
    // traduite en retard. Transpileur MessageFormat pour l'ICU. Catalogues
    // charges a l'execution depuis `/i18n/`, jamais incorpores au bundle.
    // Ne pas regler `interpolation` sur `{ }` : l'interpolation de Transloco
    // passerait alors avant MessageFormat et viderait tout bloc de pluriel ICU.
    // MessageFormat traite deja les parametres simples `{name}`, ce qui garde
    // les chaines identiques a celles de l'ARB Flutter (docs/i18n.md).
    provideTransloco({
      config: {
        availableLangs: ['en', 'fr'],
        defaultLang: 'en',
        fallbackLang: 'en',
        missingHandler: { useFallbackTranslation: true },
        reRenderOnLangChange: true,
        prodMode: !isDevMode(),
      },
      loader: TranslocoHttpLoader,
    }),
    provideTranslocoMessageformat(),
    // D4, D6 (KKS-380) : precharge la langue initiale *resolue* — derniere
    // langue appliquee sur cet appareil (`localStorage`), sinon le
    // navigateur — jamais `getDefaultLang()` seul, sans quoi un ecran non
    // authentifie (connexion, invitation, reinitialisation) s'afficherait
    // d'abord dans la langue par defaut avant que `LanguageService` ne
    // corrige. Meme resolution que la valeur initiale de
    // `LanguageService.activeLanguage` (KKS-380). `setActiveLang` une fois
    // le catalogue charge : sans cela, Transloco reste sur `defaultLang`
    // ('en') jusqu'au premier passage de l'`effect` de `LanguageService`, et
    // un appareil memorisant `fr` verrait le tout premier ecran en anglais.
    provideAppInitializer(async () => {
      const transloco = inject(TranslocoService);
      const storage = inject(LANGUAGE_STORAGE);
      const browserLanguages = inject(BROWSER_LANGUAGES);
      const lang = resolveBootstrapLanguage(storage, browserLanguages);
      await firstValueFrom(transloco.load(lang));
      transloco.setActiveLang(lang);
    }),
    // KKS-373 (D8) : demarre `LanguageService` des la creation de
    // l'injecteur, avant tout composant — voir le commentaire de la fonction
    // pour la justification du choix d'`ENVIRONMENT_INITIALIZER`.
    provideLanguageBootstrap(),
    // KKS-446 : recherche d'une nouvelle version au lancement et au retour au
    // premier plan. Sans effet quand le service worker est inactif. Service
    // partage par k-design (KKS-619) ; le critere de K·Budget (parcours de
    // tache) lui est fourni par `APP_UPDATE_CAN_APPLY`.
    provideAppUpdateCanApply(),
    provideAppInitializer(() => inject(AppUpdateService).start()),
  ],
};
