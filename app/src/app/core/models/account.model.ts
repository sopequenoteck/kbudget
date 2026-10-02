import { TransactionType } from './transaction.model';

export enum AccountType {
  COURANT = 'COURANT',
  EPARGNE = 'EPARGNE',
  ESPECES = 'ESPECES',
}

/** Cle de traduction du type d'un compte (accounts.value.*), partagee par le
 * formulaire et la liste pour eviter deux copies (KKS-375). */
export const ACCOUNT_TYPE_LABEL_KEYS: Record<AccountType, string> = {
  [AccountType.COURANT]: 'accounts.value.current',
  [AccountType.EPARGNE]: 'accounts.value.savings',
  [AccountType.ESPECES]: 'accounts.value.cash',
};

export interface Account {
  id: string;
  nom: string;
  type: AccountType;
  soldeInitial: number;
  solde: number;
  icone: string;
  couleur: string;
  isDefault: boolean;
  actif: boolean;
  currency: string;
  bankCode: string;
  bankName: string | null;
  bankCountry: string | null;
  bankBrandColor: string | null;
  bankLogoUrl: string | null;
  bankCustomName: string | null;
  bankCustomLogo: string | null;
  /** KKS-384 : 4 derniers chiffres du compte lus sur le dernier releve importe, `null` sinon. */
  statementAccountSuffix?: string | null;
}

export interface AccountSummary {
  id: string;
  nom: string;
  icone: string;
  couleur: string;
  currency: string;
  bankLogoUrl: string | null;
  bankCustomLogo: string | null;
}

export interface AccountRequest {
  nom: string;
  type: AccountType;
  soldeInitial?: number;
  icone?: string;
  couleur?: string;
  actif?: boolean;
  currency?: string;
  bankCode?: string;
  bankCustomName?: string;
  bankCustomLogo?: string;
}

export interface TransferRequest {
  fromAccountId: string;
  toAccountId: string;
  montant: number;
  note?: string;
  /** Libelle de la transaction de debit (compte source), compose par le
   * client dans sa langue (KKS-396). Optionnel : l'API ecrit un defaut
   * anglais si absent. */
  libelleDebit?: string;
  /** Libelle de la transaction de credit (compte destination), meme regle
   * que {@link libelleDebit} (KKS-396). */
  libelleCredit?: string;
}

export interface AdjustBalanceRequest {
  newBalance: number;
  /** Libelle de la transaction d'ajustement, compose par le client dans sa
   * langue (KKS-396). Optionnel : l'API ecrit un defaut anglais si absent. */
  libelle?: string;
}

export interface TransferResponse {
  transferId: string;
  debitTransaction: TransactionRef;
  creditTransaction: TransactionRef;
}

export interface TransactionRef {
  id: string;
  montant: number;
  libelle: string;
  type: TransactionType;
  date: string;
  accountId: string;
  accountNom: string;
}
