import {
  EnvironmentProviders,
  Injectable,
  InjectionToken,
  computed,
  effect,
  inject,
  provideEnvironmentInitializer,
  signal,
} from '@angular/core';
import { firstValueFrom } from 'rxjs';
import { TranslocoService } from '@jsverse/transloco';

import { PreferenceService } from './preference';
import { DevLogger } from './dev-logger';

/** Langues servies par les catalogues Transloco (D5, KKS-380). */
export type Language = 'en' | 'fr';

export const SUPPORTED_LANGUAGES: readonly Language[] = ['en', 'fr'];

const SUPPORTED_LANGUAGE_SET: ReadonlySet<Language> = new Set(SUPPORTED_LANGUAGES);

/**
 * Langue par defaut et de repli (KKS-380) : l'anglais est la langue source
 * de `docs/i18n.md`, jamais traduite en retard. Ne s'applique que si ni la
 * preference, ni le stockage local, ni le navigateur ne pointent vers une
 * langue supportee.
 */
const DEFAULT_LANGUAGE: Language = 'en';

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
 * Noms natifs des langues, jamais traduits (KKS-380) : une seule liste,
 * utilisee par le selecteur de langue des reglages. Une langue supplementaire
 * n'a qu'a etendre {@link SUPPORTED_LANGUAGES} et cette table.
 */
export const LANGUAGE_NATIVE_NAMES: Readonly<Record<Language, string>> = {
  en: 'English',
  fr: 'Français',
};

/** Cle `localStorage` de la derniere langue appliquee sur cet appareil. */
const STORAGE_KEY = 'kbudget.language';

/** Sous-ensemble de `Storage` dont {@link LanguageService} a besoin — permet
 * de fournir un faux stockage en test (jeton {@link LANGUAGE_STORAGE}). */
export interface LanguageStorageLike {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
}

/**
 * Langues annoncees par le navigateur (KKS-380). Jeton remplacable en test —
 * `provideTranslocoTesting` l'ecrase avec `['fr']` pour garder la suite
 * existante en francais sans toucher aux specs (D10).
 */
export const BROWSER_LANGUAGES = new InjectionToken<readonly string[]>('BROWSER_LANGUAGES', {
  factory: () => {
    try {
      if (navigator.languages && navigator.languages.length > 0) {
        return navigator.languages;
      }
      return navigator.language ? [navigator.language] : [];
    } catch {
      return [];
    }
  },
});

/**
 * Stockage de la derniere langue appliquee (KKS-380). Jeton remplacable en
 * test, avec un repli memoire si `localStorage` est indisponible (mode
 * prive, quota depasse).
 */
export const LANGUAGE_STORAGE = new InjectionToken<LanguageStorageLike>('LANGUAGE_STORAGE', {
  factory: (): LanguageStorageLike => {
    try {
      const probeKey = '__kbudget_storage_probe__';
      localStorage.setItem(probeKey, '1');
      localStorage.removeItem(probeKey);
      return localStorage;
    } catch {
      return createMemoryLanguageStorage();
    }
  },
});

/** Stockage en memoire, vide a la creation : repli de {@link LANGUAGE_STORAGE}
 * quand `localStorage` est indisponible, et stockage des tests. */
export function createMemoryLanguageStorage(): LanguageStorageLike {
  const memory = new Map<string, string>();
  return {
    getItem: (key: string) => memory.get(key) ?? null,
    setItem: (key: string, value: string) => {
      memory.set(key, value);
    },
  };
}

/**
 * Ramene un code de langue quelconque — `null`, un code regional (`pt-BR`),
 * une entree hors de {@link SUPPORTED_LANGUAGES} — vers une langue
 * supportee, ou `null` si aucune ne correspond.
 */
function extractSupportedLanguage(code: string | null | undefined): Language | null {
  if (!code) {
    return null;
  }
  const base = code.split('-')[0]?.toLowerCase();
  return base && SUPPORTED_LANGUAGE_SET.has(base as Language) ? (base as Language) : null;
}

/** Comme {@link extractSupportedLanguage}, mais retombe sur
 * {@link DEFAULT_LANGUAGE} plutot que `null` — usage : code de preference. */
function toSupportedLanguage(code: string | null | undefined): Language {
  return extractSupportedLanguage(code) ?? DEFAULT_LANGUAGE;
}

/** Premiere langue supportee de la liste annoncee par le navigateur, sinon
 * {@link DEFAULT_LANGUAGE}. */
function detectBrowserLanguage(languages: readonly string[]): Language {
  for (const code of languages) {
    const match = extractSupportedLanguage(code);
    if (match) {
      return match;
    }
  }
  return DEFAULT_LANGUAGE;
}

function readStoredLanguage(storage: LanguageStorageLike): Language | null {
  try {
    return extractSupportedLanguage(storage.getItem(STORAGE_KEY));
  } catch {
    return null;
  }
}

function writeStoredLanguage(storage: LanguageStorageLike, lang: Language, logger: DevLogger): void {
  try {
    storage.setItem(STORAGE_KEY, lang);
  } catch (e) {
    logger.error('Failed to persist the applied language', e);
  }
}

/**
 * Langue initiale a precharger avant le premier rendu (D4, KKS-380) : la
 * derniere langue appliquee sur cet appareil, sinon le navigateur. Partagee
 * entre `app.config.ts` (precharge le bon catalogue) et
 * {@link LanguageService} (valeur initiale de la langue appliquee), pour
 * qu'aucun ecran ne s'affiche d'abord dans une autre langue.
 */
export function resolveBootstrapLanguage(
  storage: LanguageStorageLike,
  browserLanguages: readonly string[],
): Language {
  return readStoredLanguage(storage) ?? detectBrowserLanguage(browserLanguages);
}

/**
 * Source unique et reactive de la langue active et de la locale d'affichage
 * (D8, FR-016, FR-017, KKS-380). Distingue la langue **demandee**
 * ({@link requestedLanguage} : preference, stockage, navigateur) de la
 * langue **appliquee** ({@link activeLanguage} : ne change qu'une fois son
 * catalogue Transloco charge) — un `computed()` qui traduit en lisant
 * {@link activeLanguage} ne rend donc jamais une cle brute ou l'ancienne
 * langue pendant un chargement (voir `CurrencyService.currencyItems`).
 *
 * Priorite de {@link requestedLanguage} : une preference non nulle
 * l'emporte toujours ; sinon, tant que les preferences n'ont pas fini de
 * charger ({@link PreferenceService.loaded}), la derniere langue appliquee
 * sur cet appareil ; une fois les preferences chargees et la preference
 * nulle, le navigateur.
 */
@Injectable({ providedIn: 'root' })
export class LanguageService {
  private readonly preferenceService = inject(PreferenceService);
  private readonly transloco = inject(TranslocoService);
  private readonly logger = inject(DevLogger);
  private readonly browserLanguages = inject(BROWSER_LANGUAGES);
  private readonly storage = inject(LANGUAGE_STORAGE);

  /**
   * Langue detectee depuis le navigateur, independante de la preference et
   * du stockage — alimente le libelle « Automatique (English) »/
   * « Automatique (Français) » du selecteur de reglages.
   */
  readonly detectedBrowserLanguage: Language = detectBrowserLanguage(this.browserLanguages);

  readonly requestedLanguage = computed<Language>(() => {
    const pref = this.preferenceService.language();
    if (pref) {
      return toSupportedLanguage(pref);
    }
    if (this.preferenceService.loaded()) {
      return this.detectedBrowserLanguage;
    }
    return readStoredLanguage(this.storage) ?? this.detectedBrowserLanguage;
  });

  private readonly _appliedLanguage = signal<Language>(
    resolveBootstrapLanguage(this.storage, this.browserLanguages),
  );

  /** Langue appliquee (D4) : suit {@link requestedLanguage}, avec un
   * decalage — elle ne change qu'apres le chargement du catalogue. */
  readonly activeLanguage = this._appliedLanguage.asReadonly();

  readonly displayLocale = computed(() => DISPLAY_LOCALES[this.activeLanguage()]);

  /** Derniere langue demandee traitee (chargement en cours ou termine) — pas
   * un signal : n'est lu qu'en dehors du graphe reactif, pour eviter qu'un
   * effet qui ecrit `_appliedLanguage` boucle sur sa propre lecture. */
  private lastRequestedLanguage: Language | null = null;

  constructor() {
    effect(() => {
      const requested = this.requestedLanguage();
      this.applyLanguage(requested);
    });
  }

  private applyLanguage(lang: Language): void {
    if (this.lastRequestedLanguage === lang) {
      return;
    }
    this.lastRequestedLanguage = lang;
    firstValueFrom(this.transloco.load(lang))
      .then(() => {
        // Deux chargements peuvent se resoudre dans le desordre (`fr` puis
        // `en` demandes, `en` resolu apres un retour a `fr`) : n'applique
        // que si `lang` est toujours la derniere langue demandee, sinon la
        // resolution la plus recente ecraserait un choix plus ancien.
        if (this.lastRequestedLanguage !== lang) {
          return;
        }
        this.transloco.setActiveLang(lang);
        this._appliedLanguage.set(lang);
        writeStoredLanguage(this.storage, lang, this.logger);
      })
      .catch((e) => {
        this.logger.error(`Failed to load the "${lang}" language catalogue`, e);
        // Garde la langue appliquee precedente (D4) ; autorise un futur
        // reessai de `lang` si elle redevient la langue demandee — mais pas
        // si une demande plus recente est deja en cours de traitement.
        if (this.lastRequestedLanguage === lang) {
          this.lastRequestedLanguage = this._appliedLanguage();
        }
      });
  }
}

/**
 * Force l'instanciation de {@link LanguageService} a la creation de
 * l'injecteur, avant tout composant (D8, FR-017). `providedIn: 'root'` ne
 * cree un service qu'a sa premiere injection : sans ce provider, l'`effect`
 * qui synchronise Transloco sur la langue demandee ne demarrerait qu'au
 * hasard du premier pipe ou composant qui injecte le service, ce qui
 * retarderait la bascule de langue apres connexion.
 *
 * `provideEnvironmentInitializer` (et non `provideAppInitializer`) : il s'execute
 * de facon synchrone a la creation de l'injecteur d'environnement, y compris
 * sous `TestBed`, ou les `APP_INITIALIZER` ne tournent jamais faute de
 * `ApplicationRef.bootstrap` — meme raison que `provideTranslocoTesting`
 * (`src/testing/transloco-testing.ts`).
 */
export function provideLanguageBootstrap(): EnvironmentProviders {
  return provideEnvironmentInitializer(() => {
    inject(LanguageService);
  });
}
