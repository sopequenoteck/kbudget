import { ImportDraftLine } from '../../../core/models/import.model';

/** Lignes sans categorie qui partagent un commercant : un seul choix de categorie pour tout le groupe. */
export interface UncategorisedGroup {
  /** `merchantKey|transactionType`, ou `line:<id>` pour une ligne sans cle commercant. */
  key: string;
  /** Libelle de la premiere ligne du groupe. */
  label: string;
  transactionType: string;
  lines: ImportDraftLine[];
  /** Somme des montants du groupe (valeur absolue, le sens est dans `transactionType`). */
  total: number;
}

/** Lignes d'un brouillon rangees par ce que l'utilisateur a a en faire. */
export interface ReviewModel {
  /** `DUPLICATE` avec plusieurs transactions candidates : choisir, creer ou ignorer. */
  toDecide: ImportDraftLine[];
  /** `DUPLICATE` sans candidat : doublon probable par le libelle, importer quand meme ou ignorer. */
  probableDuplicates: ImportDraftLine[];
  /** `NEEDS_REVIEW` : ligne illisible, a ignorer. */
  unreadable: ImportDraftLine[];
  uncategorised: UncategorisedGroup[];
  /** `READY` rapprochee d'une transaction existante : ne cree rien. */
  matched: ImportDraftLine[];
  /** `READY` dont la categorie vient d'une regle ou de l'historique. */
  autoCategorised: ImportDraftLine[];
  /** `READY` dont la categorie a ete choisie pendant la revue. */
  userCategorised: ImportDraftLine[];
  /** `SKIPPED` par l'import : releve precedent, lecture seule. */
  alreadyImported: ImportDraftLine[];
  /** `SKIPPED` par l'utilisateur. */
  skipped: ImportDraftLine[];
  /** `READY` non rapprochee : les transactions que la confirmation va creer. */
  newCount: number;
}

export function isAlreadyImported(line: ImportDraftLine): boolean {
  return line.status === 'SKIPPED' && line.skipReason === 'ALREADY_IMPORTED';
}

/**
 * Une ligne ignoree peut revenir sauf celle que l'import a ecartee (doublon
 * d'un releve precedent) et la ligne illisible, dont le montant n'a pas pu
 * etre lu (KKS-386).
 */
export function isRestorable(line: ImportDraftLine): boolean {
  return line.status === 'SKIPPED' && !line.skipReason && !line.statusMessage;
}

function groupKeyOf(line: ImportDraftLine): string {
  return line.merchantKey ? `${line.merchantKey}|${line.transactionType}` : `line:${line.id}`;
}

/**
 * Regroupe comme l'API propage une correction de categorie : meme cle
 * commercant et meme sens. Une ligne sans cle (libelle sans lettre) reste seule.
 */
function groupUncategorised(lines: ImportDraftLine[]): UncategorisedGroup[] {
  const groups = new Map<string, UncategorisedGroup>();
  for (const line of lines) {
    const key = groupKeyOf(line);
    const group = groups.get(key);
    if (group) {
      group.lines.push(line);
      group.total += line.amount;
    } else {
      groups.set(key, {
        key,
        label: line.cleanLabel,
        transactionType: line.transactionType,
        lines: [line],
        total: line.amount,
      });
    }
  }
  return [...groups.values()];
}

function emptyModel(): ReviewModel {
  return {
    toDecide: [],
    probableDuplicates: [],
    unreadable: [],
    uncategorised: [],
    matched: [],
    autoCategorised: [],
    userCategorised: [],
    alreadyImported: [],
    skipped: [],
    newCount: 0,
  };
}

/** Une ligne `READY` : rapprochee, ou a creer (avec la categorie qu'elle porte, ou sans). */
function classifyReadyLine(
  line: ImportDraftLine,
  model: ReviewModel,
  withoutCategory: ImportDraftLine[],
): void {
  if (line.matchedTransactionId) {
    model.matched.push(line);
    return;
  }
  model.newCount++;
  if (!line.categoryId) {
    withoutCategory.push(line);
  } else if (line.categorySource === 'USER') {
    model.userCategorised.push(line);
  } else {
    model.autoCategorised.push(line);
  }
}

export function classifyLines(lines: ImportDraftLine[]): ReviewModel {
  const model = emptyModel();
  const withoutCategory: ImportDraftLine[] = [];

  for (const line of lines) {
    switch (line.status) {
      case 'DUPLICATE':
        (line.matchCandidateIds.length > 0 ? model.toDecide : model.probableDuplicates).push(line);
        break;
      case 'NEEDS_REVIEW':
        model.unreadable.push(line);
        break;
      case 'SKIPPED':
        (isAlreadyImported(line) ? model.alreadyImported : model.skipped).push(line);
        break;
      case 'READY':
        classifyReadyLine(line, model, withoutCategory);
        break;
    }
  }

  model.uncategorised = groupUncategorised(withoutCategory);
  return model;
}
