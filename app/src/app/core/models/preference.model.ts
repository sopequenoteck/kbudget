export type Feature = 'SUBSCRIPTIONS' | 'DEBTS' | 'SHOP';

export interface FeatureMetadata {
  readonly value: Feature;
  readonly label: string;
  readonly icon: string;
  readonly description: string;
  readonly route: string;
}

export const FEATURES: readonly FeatureMetadata[] = [
  {
    value: 'SUBSCRIPTIONS',
    label: 'Abonnements',
    icon: '🔄',
    description: 'Gérer vos abonnements récurrents',
    route: '/subscriptions',
  },
  {
    value: 'DEBTS',
    label: 'Dettes',
    icon: '🤝',
    description: 'Suivre vos prêts et emprunts',
    route: '/debts',
  },
  {
    value: 'SHOP',
    label: 'Boutique',
    icon: '🏪',
    description: 'Gérer vos ventes de produits',
    route: '/shop',
  },
] as const;

export interface UserPreference {
  enabledFeatures: Feature[];
  navOrder: Feature[];
  shopAccountId: string | null;
  includeShopInBalance: boolean;
}

export interface UserPreferenceRequest {
  enabledFeatures: Feature[];
  navOrder?: Feature[] | null;
  shopAccountId?: string | null;
  includeShopInBalance?: boolean | null;
}
