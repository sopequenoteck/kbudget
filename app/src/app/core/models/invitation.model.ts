export type InvitationStatus = 'ACTIVE' | 'EXPIRED' | 'USED' | 'REVOKED';

export interface Invitation {
  id: number;
  email: string;
  invitedByEmail: string;
  status: InvitationStatus;
  token: string | null;
  createdAt: string;
  expiresAt: string;
  usedAt: string | null;
  revokedAt: string | null;
}

export interface InvitationCreated {
  token: string;
  expiresAt: string;
}

export interface CreateInvitationRequest {
  email: string;
}

export interface AcceptInviteRequest {
  token: string;
  password: string;
  displayName: string;
  currency: string;
  timezone: string;
  /** Nom du compte cree pour le nouvel utilisateur, compose par le client
   * dans sa langue (KKS-396). Optionnel : l'API ecrit un defaut anglais si
   * absent. */
  defaultAccountName?: string;
}

export interface InviteLookup {
  email: string;
}
