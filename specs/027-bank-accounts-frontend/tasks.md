# Tasks: Comptes bancaires — Frontend (UI + Integration)

**Input**: Design documents from `/specs/027-bank-accounts-frontend/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Tests unitaires pour AccountService (suivant le pattern existant des .spec.ts). Verification build en Phase 8.

**Organization**: Taches groupees par user story pour permettre l'implementation et le test independant de chaque story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Peut s'executer en parallele (fichiers differents, pas de dependances)
- **[Story]**: User story concernee (US1, US2, US3, US4, US5)
- Chemins exacts inclus dans les descriptions

---

## Phase 1: Setup

**Purpose**: Pas de setup necessaire — le projet Angular existe deja, les dependances sont installees.

*(Aucune tache — le projet est deja initialise)*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Modeles, service et composants partages necessaires a TOUTES les user stories

**CRITICAL**: Aucune user story ne peut commencer avant la completion de cette phase

- [X] T001 Creer `app/src/app/core/models/account.model.ts` — enum AccountType (COURANT, EPARGNE, ESPECES), interfaces Account, AccountSummary, AccountRequest, TransferRequest, TransferResponse, TransactionRef selon data-model.md
- [X] T002 [P] Mettre a jour `app/src/app/core/models/transaction.model.ts` — ajouter `account: AccountSummary | null` et `transferId: string | null` a l'interface Transaction, ajouter `accountId?: string` a TransactionRequest, importer AccountSummary depuis account.model
- [X] T003 [P] Mettre a jour `app/src/app/core/models/subscription.model.ts` — ajouter `account: AccountSummary | null` a l'interface Subscription, ajouter `accountId?: string` a SubscriptionRequest, importer AccountSummary depuis account.model
- [X] T004 Creer `app/src/app/core/services/account.ts` — AccountService avec methodes getAll(includeInactive?: boolean), getById(id), create(request), update(id, request), delete(id), setDefault(id), transfer(request) retournant des Observable, signal refreshTrigger. Suivre exactement le pattern de TransactionService (inject ApiService, tap(() => this.refresh()) sur les mutations)
- [X] T005 Mettre a jour `app/src/app/core/services/modal.service.ts` — ajouter 'account' et 'transfer' au type ModalType, ajouter Account a l'union EditableEntity (importer depuis account.model), ajouter les titres dans CREATE_TITLES ('Nouveau compte', 'Nouveau virement') et EDIT_TITLES ('Modifier le compte', 'Virement' pour transfer). Note : 'transfer' n'est jamais en mode edition mais le Record<ModalType, string> exige une valeur pour chaque cle — utiliser un libelle generique
- [X] T006 Creer `app/src/app/shared/components/account-picker/` (account-picker.ts, account-picker.html, account-picker.scss) — composant standalone OnPush. Inputs: accounts (Account[]), selectedAccountId (string | null), required (boolean, defaut true), label (string, defaut 'Compte'). Output: accountSelected (string | null). Afficher chaque compte avec icone, nom et solde. Option "Aucun" si required=false. Suivre le pattern visuel de CategoryPicker (layout liste avec icones) mais implementation simple avec input()/output(), PAS de ControlValueAccessor (pas de recherche ni creation inline necessaires)

**Checkpoint**: Fondation prete — l'implementation des user stories peut commencer

---

## Phase 3: User Story 1 — Consulter mes comptes et soldes sur le dashboard (Priority: P1) MVP

**Goal**: L'utilisateur voit ses comptes et soldes en haut du dashboard

**Independent Test**: Creer 2-3 comptes via l'API, ouvrir le dashboard, verifier que les soldes individuels et le total s'affichent au-dessus des KPI mensuels

### Implementation

- [X] T007 [US1] Mettre a jour `app/src/app/features/dashboard/dashboard.ts` — injecter AccountService, ajouter signals accounts/accountsLoading/accountsError, ajouter methode loadAccounts() appellee dans un effect() lie a accountService.refreshTrigger ET transactionService.refreshTrigger (pour rafraichir les soldes apres une transaction), ajouter computed totalSolde calculant la somme des soldes de tous les comptes actifs
- [X] T008 [US1] Mettre a jour `app/src/app/features/dashboard/dashboard.html` — ajouter une section "Mes comptes" au-dessus de la section KPI existante. Afficher : carte solde total, cartes individuelles par compte (icone, nom, solde avec couleur du compte en bordure/accent). Etat vide si aucun compte ("Aucun compte — Creer mon premier compte" avec lien vers settings/accounts). Solde negatif en rouge (classe amount-expense). Gestion loading/error comme les autres sections
- [X] T009 [US1] Mettre a jour `app/src/app/features/dashboard/dashboard.scss` — styles pour la section comptes : layout en scroll horizontal pour les cartes individuelles, carte solde total plus large, bordure/accent avec la couleur du compte via [style.border-color], classe pour solde negatif, etat vide, responsive mobile-first

**Checkpoint**: Le dashboard affiche les comptes et soldes. US1 testable independamment.

---

## Phase 4: User Story 2 — Gerer mes comptes bancaires (Priority: P1)

**Goal**: L'utilisateur peut creer, modifier, supprimer et configurer ses comptes depuis Settings > Comptes

**Independent Test**: Naviguer vers Settings > Comptes, creer un compte (nom + type), le modifier, definir par defaut, tenter de supprimer

### Implementation

- [X] T010 [P] [US2] Creer `app/src/app/shared/components/account-form/` (account-form.ts, account-form.html, account-form.scss) — composant standalone OnPush avec Reactive Form. Champs : nom (required, maxLength 50), type (select AccountType, disabled en edition), soldeInitial (number, masque en edition), icone (via composant EmojiGrid existant dans shared/components/emoji-grid/), couleur (input type="color" format hex), actif (toggle, affiche en edition uniquement, DISABLED si isDefault=true avec tooltip "Definissez un autre compte par defaut avant de desactiver celui-ci" — FR-004). Inputs: account (Account | null). Outputs: saved (AccountRequest), cancelled (void), deleted (string). Suivre le pattern de TransactionForm
- [X] T011 [US2] Creer `app/src/app/features/settings/components/accounts/` (accounts.ts, accounts.html, accounts.scss) — composant standalone OnPush. Injecter AccountService et ModalService. Charger les comptes (incluant inactifs via toggle ou parametre). Afficher la liste avec : icone, nom, type, solde, badge "Par defaut" si isDefault, badge "Inactif" si !actif. Actions par compte : modifier (ouvre modal 'account'), supprimer (confirmation inline avec message), definir par defaut (bouton/action). Gestion erreurs API : afficher le message de l'erreur 400 (ex: "impossible de supprimer"). Etat vide. Bouton creer en haut
- [X] T012 [US2] Mettre a jour `app/src/app/features/settings/settings.routes.ts` — transformer la route actuelle en layout parent avec enfants : route par defaut `{ path: '', component: Settings }` pour le contenu existant (categories) et route enfant `{ path: 'accounts', loadComponent: () => import('./components/accounts/accounts').then(m => m.Accounts) }`. Ajouter `<router-outlet>` dans settings.html si la structure actuelle ne le supporte pas
- [X] T013 [US2] Mettre a jour `app/src/app/features/settings/settings.html` — ajouter une section de navigation "Comptes" au-dessus de la section "Categories" avec un lien routerLink="accounts" affichant une icone et "Gerer mes comptes"
- [X] T014 [US2] Mettre a jour `app/src/app/shared/components/shell/` (shell.ts et shell.html) — ajouter le cas 'account' dans le switch/if du modal : quand activeModal === 'account', afficher AccountForm avec l'entity en edition. Gerer les events saved (appeler accountService.create ou update), cancelled (fermer modal), deleted (appeler accountService.delete puis fermer modal)

**Checkpoint**: Gestion complete des comptes dans Settings. US2 testable independamment.

---

## Phase 5: User Story 3 — Selectionner un compte dans le formulaire de transaction (Priority: P2)

**Goal**: Le formulaire de transaction inclut un selecteur de compte obligatoire avec pre-selection du compte par defaut

**Independent Test**: Ouvrir le formulaire de creation de transaction, verifier que le compte par defaut est pre-selectionne. Creer une transaction, verifier que le accountId est envoye a l'API

### Implementation

- [X] T015 [US3] Mettre a jour `app/src/app/features/transactions/components/transaction-form/transaction-form.ts` — ajouter controle 'accountId' au FormGroup. Trois cas explicites (FR-015) : (1) CREATION + comptes existent → accountId required, pre-selectionne avec le compte par defaut, (2) CREATION + aucun compte → selecteur masque, message informatif "Creez un compte dans les parametres", accountId non envoye, (3) EDITION d'une transaction legacy sans compte → accountId optionnel, selecteur affiche mais non requis, permet d'assigner un compte. Injecter AccountService, charger les comptes actifs via toSignal(accountService.getAll()), computed pour le compte par defaut et pour l'etat "aucun compte", pre-selectionner le compte existant en edition (transaction().account?.id), inclure accountId dans le TransactionRequest emis (undefined si non selectionne en edition legacy)
- [X] T016 [US3] Mettre a jour `app/src/app/features/transactions/components/transaction-form/transaction-form.html` — ajouter AccountPicker entre le champ date et le champ categorie, avec [accounts]="activeAccounts()" [selectedAccountId]="form.get('accountId')?.value" [required]="true" (accountSelected)="form.get('accountId')?.setValue($event)". Si aucun compte, afficher un message "Creez un compte dans les parametres pour associer vos transactions"

**Checkpoint**: Les transactions sont associees a un compte. US3 testable independamment.

---

## Phase 6: User Story 4 — Selectionner un compte dans le formulaire d'abonnement (Priority: P2)

**Goal**: Le formulaire d'abonnement inclut un selecteur de compte optionnel avec pre-selection du compte par defaut

**Independent Test**: Ouvrir le formulaire de creation d'abonnement, verifier que le compte par defaut est pre-selectionne. Retirer la selection, creer sans compte. Verifier

### Implementation

- [X] T017 [P] [US4] Mettre a jour `app/src/app/features/subscriptions/components/subscription-form/subscription-form.ts` — ajouter controle 'accountId' au FormGroup (optionnel), injecter AccountService, charger les comptes actifs via toSignal(accountService.getAll()), pre-selectionner le compte par defaut en creation ou le compte existant en edition (subscription().account?.id), inclure accountId (ou undefined si vide) dans le SubscriptionRequest emis
- [X] T018 [P] [US4] Mettre a jour `app/src/app/features/subscriptions/components/subscription-form/subscription-form.html` — ajouter AccountPicker entre le champ dateDebut et le champ categorie, avec [required]="false" pour permettre de ne selectionner aucun compte. Label "Compte (optionnel)"

**Checkpoint**: Les abonnements peuvent etre associes a un compte. US4 testable independamment.

---

## Phase 7: User Story 5 — Effectuer un virement entre comptes (Priority: P3)

**Goal**: L'utilisateur peut transferer de l'argent entre deux de ses comptes via un formulaire dedie

**Independent Test**: Creer 2 comptes, effectuer un virement, verifier que les soldes sont mis a jour et que 2 transactions apparaissent

### Implementation

- [X] T019 [US5] Creer `app/src/app/shared/components/transfer-form/` (transfer-form.ts, transfer-form.html, transfer-form.scss) — composant standalone OnPush avec Reactive Form. Champs : fromAccountId (required), toAccountId (required), montant (required, min 0.01), note (optional, maxLength 500). Injecter AccountService, charger comptes actifs. Validation : source !== destination (validator custom cross-field), les deux requis, montant >= 0.01. Si moins de 2 comptes actifs, afficher message. Au submit : appeler accountService.transfer(request). Outputs: saved (TransferResponse), cancelled (void). Gerer erreurs API (afficher message)
- [X] T020 [US5] Mettre a jour `app/src/app/shared/components/shell/` (shell.ts et shell.html) — ajouter le cas 'transfer' dans le switch/if du modal : quand activeModal === 'transfer', afficher TransferForm. Gerer event saved (trigger refreshTrigger sur AccountService ET TransactionService pour rafraichir dashboard et listes, puis fermer modal), cancelled (fermer modal)
- [X] T021 [US5] Mettre a jour le composant FAB (`app/src/app/shared/components/fab/`) — supprimer le type local `ModalType` duplique (ligne 12) et importer `ModalType` depuis `modal.service.ts` a la place. Ajouter 'transfer' au tableau SPEED_DIAL_ACTIONS avec { type: 'transfer', label: 'Virement', icon: '↔️' }. Conditionner l'affichage de cette option a l'existence d'au moins 2 comptes actifs (injecter AccountService, signal computed hasEnoughAccounts). Mettre a jour le type SpeedDialItem pour utiliser le ModalType importe

**Checkpoint**: Virement entre comptes fonctionnel. US5 testable independamment.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Verification finale et coherence globale

- [X] T022 Verifier la gestion des erreurs API sur tous les nouveaux composants (FR-014) — tester les cas d'erreur 400 (suppression compte par defaut, virement meme compte) et verifier que le message de l'API est affiche a l'utilisateur
- [X] T023 Verifier les etats vides sur le dashboard et les formulaires (FR-013) — tester sans aucun compte : dashboard affiche invitation, formulaires affichent message informatif. Verifier egalement le cas edge "compte supprime pendant formulaire ouvert" : le AccountPicker se met a jour via le signal refreshTrigger (la liste de comptes est recalculee, le compte supprime disparait du selecteur)
- [X] T024 Executer `cd app && ng lint && ng build --configuration production` pour verifier l'absence d'erreurs lint et la reussite du build production
- [X] T025 Creer `app/src/app/core/services/account.spec.ts` — tests unitaires AccountService suivant le pattern de transaction.spec.ts / subscription.spec.ts. Couvrir : getAll (avec et sans inactifs), create, update, delete, setDefault, transfer, refreshTrigger apres mutation. Mocker ApiService
- [X] T025b Creer `app/src/app/shared/components/account-picker/account-picker.spec.ts` — tests unitaires AccountPicker suivant le pattern de category-picker.spec.ts. Couvrir : affichage liste comptes, pre-selection, emission event accountSelected, mode required vs optionnel, option "Aucun" quand required=false
- [X] T025c Creer `app/src/app/shared/components/transfer-form/transfer-form.spec.ts` — tests unitaires TransferForm. Couvrir : validation source !== destination, montant minimum 0.01, message si moins de 2 comptes actifs, emission event saved avec TransferRequest correct, gestion erreur API
- [X] T026 Executer `cd app && ng test --watch=false` pour verifier que tous les tests passent (existants + nouveaux)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Rien a faire — projet existant
- **Foundational (Phase 2)**: BLOQUE toutes les user stories
- **US1 (Phase 3)**: Depend de Phase 2. Independant des autres stories
- **US2 (Phase 4)**: Depend de Phase 2. Independant des autres stories
- **US3 (Phase 5)**: Depend de Phase 2. Independant (AccountPicker est dans Phase 2)
- **US4 (Phase 6)**: Depend de Phase 2. Parallelisable avec US3
- **US5 (Phase 7)**: Depend de Phase 2. Independant
- **Polish (Phase 8)**: Depend de toutes les stories completees

### User Story Dependencies

```
Phase 2 (Foundational)
    ├──→ US1 (Dashboard)        ← MVP, faire en premier
    ├──→ US2 (Gestion comptes)  ← Peut etre parallele avec US1
    ├──→ US3 (Transaction form) ┐
    ├──→ US4 (Subscription form)┘ ← Parallelisables entre eux
    └──→ US5 (Virement)         ← Dernier, P3
              │
              ▼
         Phase 8 (Polish)
```

### Within Each User Story

- Modeles/services avant composants UI
- Core implementation avant integration
- Story complete avant de passer a la suivante (sauf parallelisme)

### Parallel Opportunities

- **Phase 2** : T002 et T003 en parallele (fichiers de modeles differents)
- **Phase 4** : T010 en parallele avec T011 (composants differents)
- **Phase 5 + Phase 6** : US3 et US4 en parallele (fichiers completement differents)
- **Phase 7** : T019 est independant, T020 et T021 modifient des fichiers differents mais T020 depend de T019

---

## Parallel Example: Phase 2 (Foundational)

```
# Etape 1 — Modeles (parallelisables) :
T001: Creer account.model.ts
T002: [P] Mettre a jour transaction.model.ts
T003: [P] Mettre a jour subscription.model.ts

# Etape 2 — Service (depend des modeles) :
T004: Creer AccountService

# Etape 3 — Composants partages (parallelisables, dependent du service) :
T005: Mettre a jour ModalService
T006: Creer AccountPicker
```

## Parallel Example: US3 + US4 (en parallele)

```
# Developer A (US3) :
T015: Mettre a jour transaction-form.ts
T016: Mettre a jour transaction-form.html

# Developer B (US4, en parallele) :
T017: [P] Mettre a jour subscription-form.ts
T018: [P] Mettre a jour subscription-form.html
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Completer Phase 2: Foundational (T001-T006)
2. Completer Phase 3: US1 — Dashboard comptes (T007-T009)
3. **STOP et VALIDER** : Le dashboard affiche les soldes
4. Deployer/demo si pret

### Incremental Delivery

1. Phase 2 → Fondation prete
2. US1 (Dashboard) → Tester → **MVP livrable**
3. US2 (Gestion comptes) → Tester → L'utilisateur peut gerer ses comptes
4. US3 + US4 (Formulaires) → Tester → Les transactions/abonnements sont lies aux comptes
5. US5 (Virement) → Tester → Feature complete
6. Phase 8 (Polish) → Verification finale → **Release**

---

## Notes

- [P] = fichiers differents, pas de dependances
- [Story] = traçabilite vers la user story de la spec
- Chaque story est independamment completable et testable
- Commit apres chaque tache ou groupe logique
- S'arreter a chaque checkpoint pour valider la story
- Le backend API est deja operationnel — cette feature est purement frontend
