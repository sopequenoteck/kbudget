import { TransactionType } from './transaction.model';

export enum AccountType {
  COURANT = 'COURANT',
  EPARGNE = 'EPARGNE',
  ESPECES = 'ESPECES',
}

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
}

export interface AccountSummary {
  id: string;
  nom: string;
  icone: string;
  couleur: string;
}

export interface AccountRequest {
  nom: string;
  type: AccountType;
  soldeInitial?: number;
  icone?: string;
  couleur?: string;
  actif?: boolean;
}

export interface TransferRequest {
  fromAccountId: string;
  toAccountId: string;
  montant: number;
  note?: string;
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
