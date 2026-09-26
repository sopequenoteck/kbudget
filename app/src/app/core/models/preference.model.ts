import { type NotificationType } from './notification.model';

export type Feature = 'SUBSCRIPTIONS' | 'DEBTS' | 'BUDGETS';

export interface FeatureMetadata {
  readonly value: Feature;
  readonly labelKey: string;
  readonly icon: string;
  readonly filledIcon: string;
  readonly route: string;
}

export const FEATURES: readonly FeatureMetadata[] = [
  {
    value: 'SUBSCRIPTIONS',
    labelKey: 'common.nav.subscriptions',
    icon: 'phosphorArrowsClockwise',
    filledIcon: 'phosphorArrowsClockwiseFill',
    route: '/subscriptions',
  },
  {
    value: 'DEBTS',
    labelKey: 'common.nav.debts',
    icon: 'phosphorHandshake',
    filledIcon: 'phosphorHandshakeFill',
    route: '/debts',
  },
  {
    value: 'BUDGETS',
    labelKey: 'common.nav.budgets',
    icon: 'phosphorChartPie',
    filledIcon: 'phosphorChartPieFill',
    route: '/budgets',
  },
] as const;

export interface UserPreference {
  enabledFeatures: Feature[];
  navOrder: Feature[];
  currencies?: string[];
  enabledNotificationTypes?: NotificationType[];
  timezone?: string;
  textScale?: string;
  /**
   * Code de langue BCP 47 restreint (KKS-373), `null` tant que l'utilisateur
   * n'a pas choisi — l'app suit alors le navigateur (KKS-380). Choisi via
   * `PUT /users/me/preferences` (`UserPreferenceRequest.language`), remis a
   * `null` via `DELETE /users/me/preferences/language`.
   */
  language?: string | null;
}

export interface UserPreferenceRequest {
  enabledFeatures: Feature[];
  navOrder?: Feature[] | null;
  currencies?: string[] | null;
  enabledNotificationTypes?: NotificationType[] | null;
  timezone?: string | null;
  textScale?: string | null;
  /** `'en' | 'fr'` (KKS-380) — jamais `null` : la remise a `null` passe par
   * `DELETE /users/me/preferences/language`, pas par ce champ. */
  language?: string;
}
