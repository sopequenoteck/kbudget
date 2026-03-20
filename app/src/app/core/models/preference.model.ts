import { type NotificationType } from './notification.model';

export type Feature = 'SUBSCRIPTIONS' | 'DEBTS' | 'SHOP' | 'BUDGETS';

export interface FeatureMetadata {
  readonly value: Feature;
  readonly label: string;
  readonly icon: string;
  readonly filledIcon: string;
  readonly description: string;
  readonly route: string;
}

export const FEATURES: readonly FeatureMetadata[] = [
  {
    value: 'SUBSCRIPTIONS',
    label: 'Abonnements',
    icon: 'phosphorArrowsClockwise',
    filledIcon: 'phosphorArrowsClockwiseFill',
    description: 'Gérer vos abonnements récurrents',
    route: '/subscriptions',
  },
  {
    value: 'DEBTS',
    label: 'Dettes',
    icon: 'phosphorHandshake',
    filledIcon: 'phosphorHandshakeFill',
    description: 'Suivre vos prêts et emprunts',
    route: '/debts',
  },
  {
    value: 'SHOP',
    label: 'Boutique',
    icon: 'phosphorStorefront',
    filledIcon: 'phosphorStorefrontFill',
    description: 'Gérer vos ventes de produits',
    route: '/shop',
  },
  {
    value: 'BUDGETS',
    label: 'Budgets',
    icon: 'phosphorChartPie',
    filledIcon: 'phosphorChartPieFill',
    description: 'Suivre vos budgets par catégorie',
    route: '/budgets',
  },
] as const;

export interface UserPreference {
  enabledFeatures: Feature[];
  navOrder: Feature[];
  shopAccountId: string | null;
  includeShopInBalance: boolean;
  currencies?: string[];
  enabledNotificationTypes?: NotificationType[];
  timezone?: string;
  textScale?: string;
}

export interface UserPreferenceRequest {
  enabledFeatures: Feature[];
  navOrder?: Feature[] | null;
  shopAccountId?: string | null;
  includeShopInBalance?: boolean | null;
  currencies?: string[] | null;
  enabledNotificationTypes?: NotificationType[] | null;
  timezone?: string | null;
  textScale?: string | null;
}
