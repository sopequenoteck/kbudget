export type NotificationType = 'SUBSCRIPTION_DUE' | 'DEBT_DUE' | 'DEBT_REMINDER' | 'BUDGET_THRESHOLD' | 'BUDGET_EXCEEDED' | 'RECURRING_TRANSACTION_DUE';

export type EntityType = 'SUBSCRIPTION' | 'DEBT' | 'RECURRING_TRANSACTION';

export interface NotificationModel {
  id: string;
  type: NotificationType;
  title: string;
  message: string;
  /**
   * Parametres bruts servis par l'API (KKS-397), utilises par le client pour
   * reconstruire `title`/`message` dans la langue appliquee. `null`/absent
   * pour une notification anterieure a ce ticket : `title`/`message` sont
   * alors affiches tels quels.
   */
  params?: Record<string, string> | null;
  entityType: EntityType | null;
  entityId: string | null;
  read: boolean;
  readAt: string | null;
  createdAt: string;
}

export interface NotificationPage {
  content: NotificationModel[];
  number: number;
  size: number;
  totalElements: number;
  totalPages: number;
}
