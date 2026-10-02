export interface Category {
  id: string;
  nom: string;
  icone: string;
  couleur: string;
  isSystem: boolean;
  /**
   * Clef stable d'une categorie systeme (KKS-395), traduite cote client —
   * `null` pour une categorie utilisateur, ou pour une clef qu'un serveur
   * plus recent connait mais pas ce client.
   */
  systemKey?: string | null;
}

export interface CategoryRequest {
  nom: string;
  icone: string;
  couleur: string;
}

/** Valeurs fermees de `Category.systemKey` (KKS-395), une par categorie
 * systeme creee par l'API (`Abonnement`, `Dette`, `Virement`, `Ajustement`). */
export type SystemCategoryKey = 'SUBSCRIPTION' | 'DEBT' | 'TRANSFER' | 'ADJUSTMENT';

const SYSTEM_CATEGORY_KEY_SET: ReadonlySet<string> = new Set<SystemCategoryKey>([
  'SUBSCRIPTION',
  'DEBT',
  'TRANSFER',
  'ADJUSTMENT',
]);

function isSystemCategoryKey(key: string): key is SystemCategoryKey {
  return SYSTEM_CATEGORY_KEY_SET.has(key);
}

/** Cle de traduction du nom d'une categorie systeme (categories.value.*),
 * partagee par le pipe `categoryName` et les `computed()` qui traduisent en
 * TypeScript pour eviter des copies (KKS-395, pendant de `CURRENCY_NAME_KEYS`
 * — KKS-393). */
export const SYSTEM_CATEGORY_NAME_KEYS: Record<SystemCategoryKey, string> = {
  SUBSCRIPTION: 'categories.value.subscription',
  DEBT: 'categories.value.debt',
  TRANSFER: 'categories.value.transfer',
  ADJUSTMENT: 'categories.value.adjustment',
};

/**
 * Cle de traduction du nom d'une categorie systeme, ou `null` pour une
 * categorie utilisateur (`systemKey` absent) ou une clef hors de la liste
 * fermee — a l'appelant de retomber sur le `nom` brut (KKS-395).
 */
export function systemCategoryNameKey(systemKey: string | null | undefined): string | null {
  if (!systemKey) return null;
  return isSystemCategoryKey(systemKey) ? SYSTEM_CATEGORY_NAME_KEYS[systemKey] : null;
}
