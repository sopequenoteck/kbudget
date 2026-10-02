import {
  AccountAdjustments,
  ImportedDuplicateProposal,
  SubscriptionDuplicateProposal,
  UncategorizedGroup,
} from '../../../core/models/history-cleanup.model';

/** Cle d'une proposition « operation deja saisie » : l'identifiant de la transaction importee. */
export function importedProposalKey(proposal: ImportedDuplicateProposal): string {
  return proposal.imported.id;
}

/** Cle d'une proposition de paiements d'abonnement : l'abonnement et le debut de son echeance. */
export function subscriptionProposalKey(proposal: SubscriptionDuplicateProposal): string {
  return `${proposal.subscriptionId}|${proposal.periodStart}`;
}

/**
 * Choix effectif d'une proposition : celui de l'utilisateur s'il est encore
 * valable (la liste a pu etre rechargee), sinon la valeur par defaut.
 */
export function resolveChoice(
  choices: ReadonlyMap<string, string>,
  key: string,
  validIds: readonly string[],
  defaultId: string | null,
): string | null {
  const chosen = choices.get(key);
  return chosen !== undefined && validIds.includes(chosen) ? chosen : defaultId;
}

/** Candidat preselectionne d'une operation importee : le plus proche en date (le premier). */
export function defaultCandidateId(proposal: ImportedDuplicateProposal): string | null {
  return proposal.candidates[0]?.id ?? null;
}

export function hasImportedPayment(proposal: SubscriptionDuplicateProposal): boolean {
  return proposal.transactions.some((transaction) => transaction.imported);
}

/**
 * Paiements que l'on peut garder : l'API refuse de supprimer une transaction
 * importee, donc des qu'il y en a une, elle seule est conservable.
 */
export function keepablePaymentIds(proposal: SubscriptionDuplicateProposal): string[] {
  const keepable = hasImportedPayment(proposal)
    ? proposal.transactions.filter((transaction) => transaction.imported)
    : proposal.transactions;
  return keepable.map((transaction) => transaction.id);
}

/** Paiement preselectionne : celui que l'API suggere, s'il est conservable, sinon le premier conservable. */
export function defaultKeptPaymentId(proposal: SubscriptionDuplicateProposal): string | null {
  const keepable = keepablePaymentIds(proposal);
  return keepable.includes(proposal.suggestedKeepTransactionId)
    ? proposal.suggestedKeepTransactionId
    : (keepable[0] ?? null);
}

/** Identifiants a supprimer quand `keptId` est conserve : tous les autres paiements de l'echeance. */
export function removedPaymentIds(
  proposal: SubscriptionDuplicateProposal,
  keptId: string,
): string[] {
  return proposal.transactions
    .filter((transaction) => transaction.id !== keptId)
    .map((transaction) => transaction.id);
}

/** Groupes sans categorie, separes entre ceux qu'on propose et ceux dont le commercant n'est pas reconnu. */
export interface UncategorizedSplit {
  /** Groupes a cle commercant non vide. */
  proposable: UncategorizedGroup[];
  /** Transactions des groupes a cle vide : jamais proposees, a categoriser depuis l'ecran Transactions. */
  withoutMerchantCount: number;
}

export function splitUncategorized(groups: readonly UncategorizedGroup[]): UncategorizedSplit {
  const proposable: UncategorizedGroup[] = [];
  let withoutMerchantCount = 0;
  for (const group of groups) {
    if (group.merchantKey.trim() === '') {
      withoutMerchantCount += group.count;
    } else {
      proposable.push(group);
    }
  }
  return { proposable, withoutMerchantCount };
}

/** Identifiant stable d'un groupe dans la liste : commercant, sens et montant unitaire eventuel. */
export function groupKey(group: UncategorizedGroup): string {
  return `${group.merchantKey}|${group.type}|${group.amount ?? ''}`;
}

/** Une regle n'est demandee que si le groupe couvre tous les montants du commercant. */
export function shouldCreateRule(group: UncategorizedGroup): boolean {
  return group.amount === null;
}

/** Devise d'un groupe : celle du compte de sa premiere transaction (euro a defaut). */
export function groupCurrency(group: UncategorizedGroup): string {
  return group.transactions[0]?.account.currency ?? 'EUR';
}

/** Ne garde que les ajustements probablement inutiles, et que les comptes qui en ont. */
export function unneededAdjustments(accounts: readonly AccountAdjustments[]): AccountAdjustments[] {
  return accounts
    .map((entry) => ({
      ...entry,
      adjustments: entry.adjustments.filter((adjustment) => adjustment.probablyUnnecessary),
    }))
    .filter((entry) => entry.adjustments.length > 0);
}

/** Sens d'un montant signe, pour le pipe `amount` : `+` pour un ajustement positif, `-` pour un negatif. */
export function signedAmountType(amount: number): 'RECETTE' | 'DEPENSE' {
  return amount < 0 ? 'DEPENSE' : 'RECETTE';
}

/**
 * Solde a poser pour annuler un ajustement : le solde courant moins son
 * montant signe, arrondi au centime (l'API compare au centime).
 */
export function reversalBalance(currentBalance: number, adjustmentAmount: number): number {
  return Math.round((currentBalance - adjustmentAmount) * 100) / 100;
}

/** Classe de couleur d'un montant selon son sens : recette, depense, sinon aucune. */
export function amountClass(type: string): string {
  if (type === 'RECETTE') return 'review__amount--income';
  if (type === 'DEPENSE') return 'review__amount--expense';
  return '';
}
