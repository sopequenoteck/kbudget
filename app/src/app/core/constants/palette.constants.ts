/** Palette couleurs partagée pour les pickers utilisateur (comptes, catégories, etc.). */
export const PALETTE_COLORS: readonly string[] = [
  '#ef4444',
  '#f97316',
  '#f59e0b',
  '#84cc16',
  '#22c55e',
  '#10b981',
  '#14b8a6',
  '#06b6d4',
  '#3b82f6',
  '#6366f1',
  '#8b5cf6',
  '#ec4899',
  '#78716c',
] as const;

export function randomColor(): string {
  return PALETTE_COLORS[Math.floor(Math.random() * PALETTE_COLORS.length)];
}
