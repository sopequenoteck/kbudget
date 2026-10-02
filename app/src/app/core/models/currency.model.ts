export interface CurrencyInfo {
  code: string;
  symbol: string;
  name: string;
  decimalPlaces: number;
}

/**
 * Devises supportees par les selecteurs client (KKS-393), dans l'ordre
 * d'affichage historique — devise de reference en tete. Liste fermee : l'API
 * peut en servir d'autres via {@link CurrencyInfo}, mais seules celles-ci ont
 * un symbole et un nom traduit partages entre composants.
 */
export const SUPPORTED_CURRENCIES = ['EUR', 'USD', 'XOF', 'GBP', 'CHF', 'CAD', 'MAD'] as const;

export type SupportedCurrencyCode = (typeof SUPPORTED_CURRENCIES)[number];

const SUPPORTED_CURRENCY_SET: ReadonlySet<string> = new Set(SUPPORTED_CURRENCIES);

function isSupportedCurrency(code: string): code is SupportedCurrencyCode {
  return SUPPORTED_CURRENCY_SET.has(code);
}

/** Symbole affiche pour chaque devise supportee, partage entre les reglages
 * de devises et l'acceptation d'invitation pour eviter deux copies. */
export const CURRENCY_SYMBOLS: Record<SupportedCurrencyCode, string> = {
  EUR: '€',
  XOF: 'CFA',
  USD: '$',
  GBP: '£',
  CHF: 'CHF',
  CAD: 'CA$',
  MAD: 'MAD',
};

/** Cle de traduction du nom d'une devise (exchangeRates.value.*), partagee
 * par les reglages de devises, l'acceptation d'invitation et le service des
 * devises pour eviter des copies (KKS-393). */
export const CURRENCY_NAME_KEYS: Record<SupportedCurrencyCode, string> = {
  EUR: 'exchangeRates.value.eur',
  XOF: 'exchangeRates.value.xof',
  USD: 'exchangeRates.value.usd',
  GBP: 'exchangeRates.value.gbp',
  CHF: 'exchangeRates.value.chf',
  CAD: 'exchangeRates.value.cad',
  MAD: 'exchangeRates.value.mad',
};

/**
 * Cle de traduction du nom d'une devise, ou `null` pour un code hors de la
 * liste fermee — a l'appelant de retomber sur le code brut ou sur un nom
 * d'origine serveur.
 */
export function currencyNameKey(code: string): string | null {
  return isSupportedCurrency(code) ? CURRENCY_NAME_KEYS[code] : null;
}

/**
 * Symbole d'une devise, ou `null` pour un code hors de la liste fermee —
 * pendant de {@link currencyNameKey} pour les templates qui indexent
 * {@link CURRENCY_SYMBOLS} avec un code non restreint a
 * {@link SupportedCurrencyCode}.
 */
export function currencySymbol(code: string): string | null {
  return isSupportedCurrency(code) ? CURRENCY_SYMBOLS[code] : null;
}
