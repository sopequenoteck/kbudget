import { type NotificationType } from './notification.model';

export type Feature = 'SUBSCRIPTIONS' | 'DEBTS' | 'BUDGETS';

export interface FeatureMetadata {
  readonly value: Feature;
  readonly labelKey: string;
  readonly icon: string;
  readonly filledIcon: string;
  readonly description: string;
  readonly route: string;
}

export const FEATURES: readonly FeatureMetadata[] = [
  {
    value: 'SUBSCRIPTIONS',
    labelKey: 'common.nav.subscriptions',
    icon: 'phosphorArrowsClockwise',
    filledIcon: 'phosphorArrowsClockwiseFill',
    description: 'Gérer vos abonnements récurrents',
    route: '/subscriptions',
  },
  {
    value: 'DEBTS',
    labelKey: 'common.nav.debts',
    icon: 'phosphorHandshake',
    filledIcon: 'phosphorHandshakeFill',
    description: 'Suivre vos prêts et emprunts',
    route: '/debts',
  },
  {
    value: 'BUDGETS',
    labelKey: 'common.nav.budgets',
    icon: 'phosphorChartPie',
    filledIcon: 'phosphorChartPieFill',
    description: 'Suivre vos budgets par catégorie',
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
   * n'a pas choisi. Aucun client n'ecrit ce champ dans ce lot (FR-042) : il
   * n'apparait donc pas dans `UserPreferenceRequest`.
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
}
