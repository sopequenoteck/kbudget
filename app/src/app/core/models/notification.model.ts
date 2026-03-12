export type NotificationType = 'SUBSCRIPTION_DUE' | 'DEBT_DUE' | 'DEBT_REMINDER' | 'BUDGET_THRESHOLD' | 'BUDGET_EXCEEDED';

export type EntityType = 'SUBSCRIPTION' | 'DEBT';

export interface NotificationModel {
  id: string;
  type: NotificationType;
  title: string;
  message: string;
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
