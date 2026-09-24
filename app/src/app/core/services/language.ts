import {
  ENVIRONMENT_INITIALIZER,
  EnvironmentProviders,
  Injectable,
  computed,
  effect,
  inject,
  makeEnvironmentProviders,
} from '@angular/core';
import { TranslocoService } from '@jsverse/transloco';

import { PreferenceService } from './preference';

/** Langues servies par les catalogues Transloco (D5). */
export type Language = 'en' | 'fr';

const SUPPORTED_LANGUAGES: readonly Language[] = ['en', 'fr'];

/**
 * Langue par defaut et de repli (D5). Reste `fr` tant que la preference vaut
 * `null` (FR-017) — KKS-380 introduira la bascule vers l'anglais.
 */
const DEFAULT_LANGUAGE: Language = 'fr';

/**
 * Locale `Intl` derivee de la langue active (D8, FR-016). Le francais produit
 * la locale francaise de France, l'anglais la locale britannique — cf.
 * `docs/i18n.md`.
 */
const DISPLAY_LOCALES: Readonly<Record<Language, string>> = {
  fr: 'fr-FR',
  en: 'en-GB',
};

/**
 * Ramene un code de langue quelconque — `null`, un code regional (`pt-BR`),
 * un code que ce client ne sait pas servir — vers une des deux langues
 * supportees. Ne leve jamais et ne produit jamais de locale invalide :
 * {@link DISPLAY_LOCALES} n'a que deux entrees, la sortie de cette fonction
 * y a toujours une correspondance.
 */
function toSupportedLanguage(code: string | null | undefined): Language {
  if (!code) {
    return DEFAULT_LANGUAGE;
  }
  const base = code.split('-')[0]?.toLowerCase();
  return (SUPPORTED_LANGUAGES as readonly string[]).includes(base)
    ? (base as Language)
    : DEFAULT_LANGUAGE;
}

/**
 * Source unique et reactive de la langue active et de la locale d'affichage
 * (D8, FR-016, FR-017). Remplace l'ancienne constante de locale figee,
 * supprimee : tous ses consommateurs lisent desormais {@link displayLocale}.
 *
 * La source de la langue est {@link PreferenceService.language}, elle-meme
 * alimentee par l'API. Tant qu'elle vaut `null` — tous les comptes existants,
 * et tout compte avant le premier rendu authentifie — la langue active est le
 * francais. Aucune detection de la langue du navigateur (KKS-380).
 */
@Injectable({ providedIn: 'root' })
export class LanguageService {
  private readonly preferenceService = inject(PreferenceService);
  private readonly transloco = inject(TranslocoService);

  readonly activeLanguage = computed<Language>(() =>
    toSupportedLanguage(this.preferenceService.language()),
  );

  readonly displayLocale = computed(() => DISPLAY_LOCALES[this.activeLanguage()]);

  constructor() {
    // Tient Transloco synchronise sur la langue active : un code inconnu ou
    // non supporte retombe sur le francais, jamais sur une clé brute.
    effect(() => {
      const lang = this.activeLanguage();
      if (this.transloco.getActiveLang() !== lang) {
        this.transloco.setActiveLang(lang);
      }
    });
  }
}

/**
 * Force l'instanciation de {@link LanguageService} a la creation de
 * l'injecteur, avant tout composant (D8, FR-017). `providedIn: 'root'` ne
 * cree un service qu'a sa premiere injection : sans ce provider, l'`effect`
 * qui synchronise Transloco sur `PreferenceService.language` ne demarrerait
 * qu'au hasard du premier pipe ou composant qui injecte le service, ce qui
 * retarderait la bascule de langue apres connexion.
 *
 * `ENVIRONMENT_INITIALIZER` (et non `provideAppInitializer`) : il s'execute
 * de facon synchrone a la creation de l'injecteur d'environnement, y compris
 * sous `TestBed`, ou les `APP_INITIALIZER` ne tournent jamais faute de
 * `ApplicationRef.bootstrap` — meme raison que `provideTranslocoTesting`
 * (`src/testing/transloco-testing.ts`).
 */
export function provideLanguageBootstrap(): EnvironmentProviders {
  return makeEnvironmentProviders([
    {
      provide: ENVIRONMENT_INITIALIZER,
      multi: true,
      useValue: () => {
        inject(LanguageService);
      },
    },
  ]);
}
