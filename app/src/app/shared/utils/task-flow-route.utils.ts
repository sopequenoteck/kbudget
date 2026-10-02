/**
 * Parcours dedies a une tache (parametres, import de releve) : le FAB n'y a pas d'usage
 * et n'y est pas affiche (constitution 4.1.0, principe IV). Une mise a jour de la PWA n'y
 * est pas non plus appliquee (`AppUpdateService`) : un rechargement y perdrait la saisie.
 */
export function isTaskFlowRoute(url: string): boolean {
  return url.startsWith('/settings') || url.startsWith('/transactions/import');
}
