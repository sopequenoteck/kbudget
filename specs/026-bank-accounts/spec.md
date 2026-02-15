# Feature Specification: Comptes Bancaires

**Feature Branch**: `026-bank-accounts`
**Created**: 2026-02-15
**Status**: Draft
**Input**: Issue KKS-81 - Comptes bancaires : entite Account + CRUD backend
**Linear**: [KKS-81](https://linear.app/kksdev/issue/KKS-81)

## Clarifications

### Session 2026-02-15

- Q: Le compte par defaut est-il cree automatiquement par le systeme ou l'utilisateur doit-il le creer manuellement ? → A: Le systeme cree automatiquement un compte par defaut lors de la migration. L'utilisateur peut le personnaliser ensuite.
- Q: Le nom du compte doit-il etre unique par utilisateur et quelle longueur maximale ? → A: Nom unique par utilisateur, longueur 1-50 caracteres.
- Q: Le solde initial peut-il etre negatif ? → A: Solde initial libre (positif, zero ou negatif) pour refleter la situation reelle (ex: decouvert).
- Q: Les champs icone et couleur sont-ils obligatoires a la creation d'un compte ? → A: Optionnels avec valeurs par defaut attribuees par le systeme selon le type de compte.
- Q: Un compte sans transaction peut-il etre supprime physiquement ? → A: Suppression physique autorisee si aucune transaction ni abonnement rattache.
- Q: Quel est le perimetre exact de cette feature branch (backend seul ou backend + frontend) ? → A: Backend uniquement (entite, API REST, migration, tests). Le frontend sera traite dans une branche separee.
- Q: Le solde du compte est-il calcule a la volee (SUM SQL) ou stocke dans un champ persistant ? → A: Calcul a la volee via requete SQL SUM a chaque consultation. Pas de champ balance stocke sur l'entite Account.
- Q: Par quel mecanisme la migration des donnees existantes (compte par defaut + rattachement transactions) est-elle executee ? → A: Migration Flyway SQL (script V*.sql versionne, atomique, execute une seule fois).
- Q: Quel format pour le champ de liaison des transactions de virement (transferId) ? → A: UUID partage — les deux transactions du virement portent le meme UUID genere. Champ nullable (null = transaction normale).
- Q: A quel moment le compte par defaut est-il cree pour les nouveaux utilisateurs ? → A: Dans le service d'inscription, juste apres la creation du User.
- Q: Quelle categorie est attribuee aux transactions de virement ? → A: Une categorie systeme "Virement" creee automatiquement (non supprimable par l'utilisateur).
- Q: Le listing des comptes retourne-t-il les comptes actifs uniquement ou tous par defaut ? → A: Actifs uniquement par defaut, avec parametre query `?includeInactive=true` pour inclure les inactifs.
- Q: Le solde initial (initialBalance) est-il modifiable apres la creation du compte ? → A: Non, fige a la creation. L'utilisateur doit creer une transaction d'ajustement pour corriger son solde.
- Q: Que se passe-t-il quand l'utilisateur supprime une transaction de virement (une des deux liees) ? → A: Suppression en cascade — les deux transactions liees sont supprimees ensemble pour garantir la coherence des soldes.
- Q: La modification d'une transaction de virement (ex: montant) est-elle autorisee ? → A: Oui, modification propagee — changer le montant d'un cote met a jour automatiquement l'autre transaction liee.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Gestion des comptes bancaires (Priority: P1)

L'utilisateur souhaite organiser ses finances en definissant ses differents comptes : compte courant, comptes d'epargne, et especes. Il cree un compte en lui donnant un nom, un type, un solde initial, une icone et une couleur pour le differencier visuellement. Il peut modifier ces informations, desactiver un compte qu'il n'utilise plus, ou le reactiver. Un compte est designe comme compte par defaut pour simplifier la saisie des transactions.

**Why this priority**: Fondation de toute la feature. Sans comptes, impossible d'y rattacher des transactions ou de calculer des soldes. C'est le MVP minimal.

**Independent Test**: Peut etre teste en creant, modifiant, listant et desactivant des comptes sans aucune autre fonctionnalite.

**Acceptance Scenarios**:

1. **Given** un utilisateur authentifie avec uniquement le compte auto-genere, **When** il cree un nouveau compte, **Then** le compte est cree et n'est pas marque par defaut (le compte auto-genere reste le defaut).
2. **Given** un utilisateur avec plusieurs comptes, **When** il cree un nouveau compte, **Then** le nouveau compte n'est pas marque par defaut.
3. **Given** un utilisateur avec plusieurs comptes, **When** il designe un autre compte comme defaut, **Then** l'ancien compte par defaut perd ce statut et le nouveau le recoit.
4. **Given** un utilisateur avec un compte actif, **When** il desactive ce compte, **Then** le compte n'apparait plus dans les listes par defaut mais reste accessible via un filtre.
5. **Given** un utilisateur, **When** il liste ses comptes, **Then** il voit uniquement ses propres comptes (isolation des donnees).

---

### User Story 2 - Rattachement des transactions a un compte (Priority: P2)

L'utilisateur souhaite associer chaque transaction (depense ou recette) a un compte bancaire specifique. Lors de la creation d'une transaction, le compte est obligatoire. Les transactions existantes doivent etre migrees vers un compte par defaut.

**Why this priority**: Lie les transactions aux comptes, ce qui est necessaire pour le calcul du solde. Depend de P1.

**Independent Test**: Peut etre teste en creant une transaction rattachee a un compte et en verifiant que le rattachement est persiste.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec au moins un compte, **When** il cree une transaction sans specifier de compte, **Then** la transaction est rattachee au compte par defaut.
2. **Given** un utilisateur avec plusieurs comptes, **When** il cree une transaction en specifiant un compte, **Then** la transaction est rattachee au compte choisi.
3. **Given** un utilisateur, **When** il tente de creer une transaction sans aucun compte existant, **Then** le systeme refuse avec un message explicite.
4. **Given** des transactions existantes sans compte (donnees anterieures), **When** la migration s'execute, **Then** un compte "Compte Principal" est cree automatiquement et toutes les transactions existantes y sont rattachees.

---

### User Story 3 - Rattachement des abonnements a un compte (Priority: P3)

L'utilisateur souhaite optionnellement associer un abonnement a un compte bancaire. Cela permet de savoir quel compte est debite pour chaque abonnement recurrent.

**Why this priority**: Apporte de la coherence avec les transactions mais reste optionnel. Les abonnements peuvent fonctionner sans compte.

**Independent Test**: Peut etre teste en creant un abonnement avec et sans compte rattache.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec des comptes, **When** il cree un abonnement en specifiant un compte, **Then** l'abonnement est rattache a ce compte.
2. **Given** un utilisateur, **When** il cree un abonnement sans specifier de compte, **Then** l'abonnement est cree sans rattachement (le champ reste vide).
3. **Given** un abonnement existant sans compte, **When** l'utilisateur le modifie pour y ajouter un compte, **Then** le rattachement est effectue.

---

### User Story 4 - Consultation du solde d'un compte (Priority: P2)

L'utilisateur souhaite connaitre le solde actuel de chaque compte. Le solde est calcule a partir du solde initial plus la somme des recettes moins la somme des depenses rattachees a ce compte.

**Why this priority**: Donne une vision financiere reelle par compte. Meme importance que le rattachement car c'est la raison d'etre des comptes.

**Independent Test**: Peut etre teste en creant un compte avec un solde initial, y rattachant des transactions, et en verifiant le solde calcule.

**Acceptance Scenarios**:

1. **Given** un compte avec solde initial de 1000.00 et aucune transaction, **When** l'utilisateur consulte le solde, **Then** le solde affiche 1000.00.
2. **Given** un compte avec solde initial de 1000.00, une recette de 500.00 et une depense de 200.00, **When** l'utilisateur consulte le solde, **Then** le solde affiche 1300.00.
3. **Given** un utilisateur avec plusieurs comptes, **When** il consulte la liste des comptes, **Then** chaque compte affiche son solde calcule.

---

### User Story 5 - Virement entre comptes (Priority: P3)

L'utilisateur souhaite effectuer un virement d'un compte a un autre. Le virement genere deux transactions liees : une depense sur le compte source et une recette sur le compte destination, pour le meme montant. Ces deux transactions sont liees entre elles pour la tracabilite.

**Why this priority**: Fonctionnalite avancee qui enrichit l'experience mais n'est pas indispensable au MVP des comptes.

**Independent Test**: Peut etre teste en effectuant un virement et en verifiant que les deux transactions sont creees, liees, et que les soldes des deux comptes sont mis a jour.

**Acceptance Scenarios**:

1. **Given** un utilisateur avec un compte A (solde 1000.00) et un compte B (solde 500.00), **When** il effectue un virement de 200.00 de A vers B, **Then** une depense de 200.00 est creee sur A, une recette de 200.00 est creee sur B, et les deux transactions sont liees.
2. **Given** un utilisateur, **When** il tente un virement avec le meme compte source et destination, **Then** le systeme refuse l'operation.
3. **Given** un utilisateur, **When** il effectue un virement, **Then** les deux transactions portent un libelle indiquant le virement (ex: "Virement vers [nom compte]" / "Virement depuis [nom compte]").
4. **Given** un utilisateur qui consulte une transaction de virement, **When** il regarde les details, **Then** il peut identifier la transaction liee (compte source/destination).

---

### Edge Cases

- Que se passe-t-il si l'utilisateur tente de supprimer un compte qui a des transactions ou abonnements rattaches ? Le systeme doit empecher la suppression et proposer la desactivation. Si aucune donnee n'est rattachee, la suppression physique est autorisee.
- Que se passe-t-il si l'utilisateur desactive le compte par defaut ? Le systeme doit demander de designer un autre compte par defaut avant la desactivation.
- Que se passe-t-il si un virement est effectue avec un montant de 0 ou negatif ? Le systeme doit refuser avec un message d'erreur.
- Que se passe-t-il si le compte source ou destination d'un virement est inactif ? Le systeme doit refuser l'operation.
- Comment sont traites les centimes dans les calculs de solde ? Les montants sont en precision decimale (2 decimales) pour eviter les erreurs d'arrondi.
- Que se passe-t-il si l'utilisateur veut corriger le solde initial apres la creation ? Le solde initial est fige. L'utilisateur doit creer une transaction d'ajustement (recette ou depense) pour corriger le solde courant du compte.
- Que se passe-t-il si l'utilisateur supprime une des deux transactions d'un virement ? Les deux transactions liees sont supprimees en cascade automatiquement.
- Que se passe-t-il si l'utilisateur modifie le montant d'une transaction de virement ? La modification est propagee automatiquement a la transaction liee pour maintenir la coherence.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT permettre a l'utilisateur de creer un compte avec les informations suivantes : nom (unique par utilisateur, 1-50 caracteres), type (Courant, Epargne, Especes), solde initial (positif, zero ou negatif), icone (optionnel, defaut selon type), couleur (optionnel, defaut selon type).
- **FR-002**: Le systeme DOIT creer automatiquement un compte par defaut ("Compte Principal", type Courant, solde initial 0.00) via une migration Flyway SQL pour les utilisateurs existants. Pour les nouveaux utilisateurs, le compte par defaut est cree par le service d'inscription. L'utilisateur peut le renommer et le personnaliser.
- **FR-003**: Le systeme DOIT garantir qu'un seul compte par defaut existe par utilisateur a tout moment.
- **FR-004**: Le systeme DOIT permettre la modification des proprietes suivantes d'un compte : nom, type, icone, couleur, statut actif, statut par defaut. Le solde initial (initialBalance) est fige a la creation et ne peut pas etre modifie. Toute correction de solde se fait via une transaction d'ajustement.
- **FR-005**: Le systeme DOIT empecher la suppression d'un compte ayant des transactions ou des abonnements rattaches et proposer la desactivation a la place. La suppression physique est autorisee uniquement si aucune transaction ni abonnement n'est rattache au compte.
- **FR-006**: Le systeme DOIT empecher la desactivation du compte par defaut tant qu'un autre compte n'a pas ete designe comme defaut.
- **FR-007**: Le systeme DOIT exiger un compte pour chaque nouvelle transaction (champ obligatoire).
- **FR-008**: Le systeme DOIT permettre d'associer optionnellement un abonnement a un compte.
- **FR-009**: Le systeme DOIT calculer le solde d'un compte a la volee (requete SQL SUM) selon la formule : solde initial + somme des recettes - somme des depenses. Le solde n'est pas stocke en base.
- **FR-010**: Le systeme DOIT fournir un solde calcule pour chaque compte dans la liste des comptes. Par defaut, seuls les comptes actifs sont retournes. Un parametre optionnel `includeInactive=true` permet d'inclure les comptes inactifs.
- **FR-011**: Le systeme DOIT permettre d'effectuer un virement entre deux comptes distincts en creant deux transactions liees (depense sur la source, recette sur la destination). Les deux transactions sont automatiquement categorisees avec la categorie systeme "Virement".
- **FR-012**: Le systeme DOIT refuser un virement si le compte source et le compte destination sont identiques.
- **FR-013**: Le systeme DOIT refuser un virement si le montant est nul ou negatif.
- **FR-014**: Le systeme DOIT refuser toute operation impliquant un compte inactif (creation de transaction, virement).
- **FR-015**: Le systeme DOIT isoler les comptes par utilisateur : chaque utilisateur ne voit et ne manipule que ses propres comptes.
- **FR-016**: Le systeme DOIT migrer les transactions existantes (sans compte) vers le compte par defaut auto-genere via le meme script Flyway SQL que FR-002.
- **FR-017**: Le systeme DOIT supprimer en cascade les deux transactions liees d'un virement lorsque l'une d'elles est supprimee, afin de garantir la coherence des soldes entre les comptes.
- **FR-018**: Le systeme DOIT propager automatiquement la modification du montant d'une transaction de virement a la transaction liee. Les deux transactions restent synchronisees en permanence.

### Key Entities

- **Compte (Account)** : Represente un compte financier de l'utilisateur. Attributs : nom (unique par utilisateur, 1-50 car.), type (Courant/Epargne/Especes), solde initial (libre), icone (optionnel, defaut par type), couleur (optionnel, defaut par type), statut actif, statut par defaut. Appartient a un utilisateur.
- **Transaction** : Entite existante. Ajout d'une relation obligatoire vers un Compte. Ajout d'un champ `transferId` (UUID, nullable) : les deux transactions d'un virement partagent le meme UUID ; null pour les transactions normales.
- **Abonnement (Subscription)** : Entite existante. Ajout d'une relation optionnelle vers un Compte.

## Assumptions

- L'application est single-user en usage reel, mais l'isolation par utilisateur est maintenue par convention d'architecture.
- Les montants sont geres avec 2 decimales de precision.
- Le type de compte est limite a 3 valeurs : Courant, Epargne, Especes. Pas de comptes d'investissement ou autres types dans cette version.
- La suppression physique d'un compte est autorisee uniquement si aucune transaction ni abonnement n'y est rattache ; sinon, seule la desactivation est proposee.
- Les transactions de virement sont des transactions normales avec un champ supplementaire de liaison, pas une entite separee.
- Le libelle des transactions de virement est genere automatiquement par le systeme.
- Les transactions de virement sont categorisees avec une categorie systeme "Virement" (isSystem=true, non supprimable). Cette categorie est creee via la migration Flyway.
- Cette feature branch couvre uniquement le backend (entite JPA, API REST, migration Flyway, tests d'integration). Le frontend Angular sera traite dans une branche separee.
- Le solde d'un compte est calcule a la volee (SUM SQL sur les transactions rattachees), pas de champ balance stocke. Suffisant pour le volume single-user.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'API REST permet de creer un compte en une seule requete POST.
- **SC-002**: Le solde calcule d'un compte est toujours exact a 2 decimales pres, quelle que soit le nombre de transactions.
- **SC-003**: Un virement entre deux comptes genere exactement 2 transactions liees et met a jour les soldes des deux comptes de maniere coherente.
- **SC-004**: 100% des transactions creees apres la migration sont rattachees a un compte.
- **SC-005**: Les donnees existantes (transactions sans compte) sont migrees sans perte ni duplication.
- **SC-006**: L'API retourne l'icone et la couleur de chaque compte dans les reponses, permettant l'identification visuelle cote frontend.
