import { type Feature } from './preference.model';

/** Reponse de `GET /api/meta` — description que le serveur donne de lui-meme (KKS-314). */
export interface ServerMeta {
  serverVersion: string;
  apiVersion: string;
  minClientVersion: string;
  capabilities: Feature[];
}

/**
 * Resultat de la verification de compatibilite au demarrage.
 *
 * `offline` est distinct de `serverTooOld` : un serveur injoignable n'est pas un
 * serveur incompatible. Confondre les deux afficherait « mettez votre serveur a
 * jour » a un utilisateur simplement coupe du reseau, alors que la constitution
 * (principe IV) impose de degrader proprement dans ce cas.
 */
export type CompatibilityStatus =
  | { kind: 'compatible'; meta: ServerMeta }
  | { kind: 'offline' }
  | { kind: 'serverTooOld'; serverVersion: string | null; requiredVersion: string }
  | { kind: 'clientTooOld'; clientVersion: string; requiredVersion: string };
