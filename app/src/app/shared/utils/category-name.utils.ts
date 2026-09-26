import { TranslocoService } from '@jsverse/transloco';

import { systemCategoryNameKey } from '../../core/models/category.model';

/**
 * Nom affiche d'une categorie (KKS-395) : traduit la clef systeme quand elle
 * est connue (`systemKey`), sinon retombe sur `nom` — categorie utilisateur,
 * ou clef qu'un serveur plus recent envoie mais que ce client ne connait
 * pas. Un nom saisi par l'utilisateur ne passe jamais par `transloco`
 * puisqu'il n'est traduit que lorsque `systemKey` resout une clef connue.
 *
 * Partagee par le pipe `categoryName` (templates) et les `computed()` qui
 * traduisent en TypeScript — tri, recherche, libelle passe a un composant
 * sans pipe (exception documentee CLAUDE.md, KKS-380) — pour n'ecrire cette
 * regle qu'une fois.
 */
export function categoryDisplayName(
  nom: string,
  systemKey: string | null | undefined,
  transloco: TranslocoService,
  lang: string,
): string {
  const key = systemCategoryNameKey(systemKey);
  return key ? transloco.translate(key, {}, lang) : nom;
}
