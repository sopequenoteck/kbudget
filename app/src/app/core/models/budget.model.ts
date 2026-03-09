export interface Budget {
  id: string;
  montant: number;
  currency: string;
  frequence: string;
  seuilNotification: number;
  actif: boolean;
  category: { id: string; nom: string; icone: string; couleur: string };
  spent: number;
  updatedAt: string;
}

export interface BudgetRequest {
  categoryId: string;
  montant: number;
  frequence: string;
  currency?: string;
  seuilNotification?: number;
  actif?: boolean;
}

export interface BudgetOverview {
  month: string;
  totalBudget: number;
  totalSpent: number;
  percentage: number;
  currency: string;
  items: BudgetOverviewItem[];
  unbudgetedItems: UnbudgetedItem[];
  unbudgetedTotal: number;
}

export interface BudgetOverviewItem {
  budgetId: string;
  categoryId: string;
  categoryNom: string;
  categoryIcone: string;
  categoryCouleur: string;
  montantBudget: number;
  montantBudgetNormalise: number;
  currency: string;
  montantDepense: number;
  percentage: number;
  frequence: string;
  actif?: boolean;
}

export interface BudgetHistory {
  month: string;
  totalBudget: number;
  totalSpent: number;
  percentage: number;
  currency: string;
  items: BudgetHistoryItem[];
  unbudgetedItems: UnbudgetedItem[];
  unbudgetedTotal: number;
}

export interface BudgetHistoryItem {
  categoryId: string;
  categoryNom: string;
  categoryIcone: string;
  categoryCouleur: string;
  montantBudget: number;
  currency: string;
  tauxChange: number | null;
  montantDepense: number;
  percentage: number;
  createdAt: string;
}

export interface UnbudgetedItem {
  categoryId: string;
  categoryNom: string;
  categoryIcone: string;
  categoryCouleur: string;
  montantDepense: number;
}

export const FREQUENCIES = [
  { value: 'HEBDOMADAIRE', label: 'Hebdomadaire' },
  { value: 'MENSUEL', label: 'Mensuel' },
  { value: 'ANNUEL', label: 'Annuel' },
] as const;

export type BudgetItem = BudgetOverviewItem | BudgetHistoryItem;

export function isOverviewItem(item: BudgetItem): item is BudgetOverviewItem {
  return 'budgetId' in item;
}

export function budgetAmount(item: BudgetItem): number {
  if (isOverviewItem(item)) {
    return item.montantBudgetNormalise;
  }
  return item.tauxChange != null ? item.montantBudget * item.tauxChange : item.montantBudget;
}
