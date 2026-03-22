# Feature Specification: Banques sur les comptes — liste pré-définie avec logos embarqués

**Feature Branch**: `084-bank-accounts`
**Created**: 2026-03-14
**Status**: Done (spec rétroactive)
**Input**: KKS-164 — Toutes les sous-tâches (KKS-197, KKS-198, KKS-199) sont terminées. Spec consolidée cross-plateforme couvrant backend, Angular et Flutter.

## User Scenarios & Testing

### User Story 1 - Sélectionner une banque lors de la création d'un compte (Priority: P1)

L'utilisateur crée un nouveau compte bancaire. Il choisit une banque dans une liste pré-définie (ex. Société Générale, BNP Paribas, Ecobank). Le logo et la couleur de la banque sont automatiquement appliqués au compte, simplifiant le formulaire en supprimant les champs icône et couleur manuels.

**Why this priority**: C'est le parcours principal — la majorité des comptes sont liés à une banque connue. Simplifier la création réduit la friction utilisateur.

**Independent Test**: Créer un compte en sélectionnant une banque connue et vérifier que le logo et la couleur brand s'affichent correctement partout.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur le formulaire de création de compte, **When** il sélectionne "Société Générale" dans le sélecteur de banque, **Then** les champs icône et couleur disparaissent et le logo SG + couleur #e4002b sont assignés automatiquement.
2. **Given** l'utilisateur a sélectionné une banque connue, **When** il valide le formulaire avec un nom et un type, **Then** le compte est créé avec le `bankCode` correspondant et s'affiche avec le logo banque partout (dashboard, listes, sélecteurs).
3. **Given** l'utilisateur modifie un compte existant, **When** il change la banque de "Autre" vers "BNP Paribas", **Then** le logo BNP remplace l'emoji et la couleur brand remplace la couleur manuelle.

---

### User Story 2 - Utiliser une banque non listée (option "Autre") (Priority: P1)

L'utilisateur possède un compte dans une banque non référencée. Il sélectionne "Autre", saisit un nom personnalisé, et peut optionnellement uploader un logo custom. Les champs icône (emoji) et couleur restent éditables.

**Why this priority**: Essentiel pour couvrir 100% des cas — aucun utilisateur ne doit être bloqué par l'absence de sa banque dans la liste.

**Independent Test**: Créer un compte avec "Autre", saisir un nom custom et un logo, vérifier l'affichage.

**Acceptance Scenarios**:

1. **Given** l'utilisateur sélectionne "Autre" dans le sélecteur de banque, **When** le formulaire se met à jour, **Then** les champs nom de banque personnalisé, icône emoji, couleur et upload logo apparaissent.
2. **Given** l'utilisateur a choisi "Autre" et uploadé un logo custom (image compressée), **When** il sauvegarde le compte, **Then** le logo custom s'affiche à la place de l'emoji partout où le compte est affiché.
3. **Given** l'utilisateur a choisi "Autre" sans uploader de logo, **When** le compte est affiché, **Then** l'emoji existant est utilisé comme fallback.

---

### User Story 3 - Consulter la liste des banques pré-définies (Priority: P2)

L'utilisateur parcourt la liste des banques disponibles dans le sélecteur, organisées par pays/région (France, Togo/UEMOA, International). Il peut rechercher une banque par nom en temps réel.

**Why this priority**: L'ergonomie du sélecteur impacte directement l'expérience de création de compte, mais c'est un composant UI et non un parcours métier critique.

**Independent Test**: Ouvrir le sélecteur de banque, vérifier le groupement par pays, tester la recherche.

**Acceptance Scenarios**:

1. **Given** l'utilisateur ouvre le sélecteur de banque, **When** la liste s'affiche, **Then** les banques sont groupées par région (France, Togo/UEMOA, International) avec "Autre" en option distincte.
2. **Given** l'utilisateur tape "Soci" dans le champ de recherche, **When** la liste se filtre, **Then** seules "Société Générale" et "Société Générale Togo" apparaissent.
3. **Given** la liste des banques est chargée, **When** l'utilisateur consulte chaque entrée, **Then** chaque banque affiche son logo SVG et son nom.

---

### User Story 4 - Rétrocompatibilité des comptes existants (Priority: P1)

Les comptes créés avant l'ajout de la fonctionnalité banque continuent de fonctionner sans modification. Ils reçoivent automatiquement `bank_code = 'OTHER'` et conservent leur icône emoji et couleur manuelles.

**Why this priority**: Aucune donnée existante ne doit être altérée — la migration doit être transparente.

**Independent Test**: Vérifier qu'après migration, les comptes existants s'affichent exactement comme avant.

**Acceptance Scenarios**:

1. **Given** des comptes existent avant la migration, **When** la migration s'exécute, **Then** tous les comptes reçoivent `bank_code = 'OTHER'` et les champs `bank_custom_name` et `bank_custom_logo` restent `NULL`.
2. **Given** un compte existant avec `bank_code = 'OTHER'`, **When** il est affiché, **Then** l'emoji et la couleur d'origine sont utilisés (pas de changement visuel).

---

### Edge Cases

- Que se passe-t-il si un logo SVG embarqué est manquant ou corrompu ? L'emoji du compte est utilisé comme fallback (cascade définie par FR-010).
- Comment se comporte le sélecteur avec une recherche vide ? Toutes les banques pré-définies sont affichées, groupées par région.
- Que se passe-t-il si l'utilisateur uploade un logo custom trop volumineux ? Compression côté client selon FR-011.
- Que se passe-t-il si le `bankCode` sauvegardé ne correspond à aucune banque pré-définie ? Le système traite ce cas comme "Autre" avec fallback emoji.

## Requirements

### Functional Requirements

- **FR-001**: Le système DOIT fournir une liste pré-définie de 29 banques (15 France, 12 Togo/UEMOA, 1 International, 1 "Autre") avec code, nom, pays, couleur brand et logo SVG embarqué.
- **FR-002**: Le système DOIT exposer la liste des banques via un endpoint public accessible sans authentification.
- **FR-003**: Lors de la création ou modification d'un compte, l'utilisateur DOIT pouvoir sélectionner une banque dans la liste pré-définie.
- **FR-004**: Lorsqu'une banque connue est sélectionnée, le logo banque DOIT remplacer l'icône emoji et la couleur brand DOIT remplacer la couleur manuelle.
- **FR-005**: Lorsque "Autre" est sélectionné, l'utilisateur DOIT pouvoir saisir un nom de banque personnalisé et optionnellement uploader un logo custom.
- **FR-006**: Les champs `icone` et `couleur` DOIVENT rester en base de données pour rétrocompatibilité mais NE DOIVENT être utilisés que si `bank_code = 'OTHER'`.
- **FR-007**: Le sélecteur de banque DOIT afficher les banques groupées par pays/région avec une fonctionnalité de recherche en temps réel.
- **FR-008**: Les logos SVG DOIVENT être embarqués en tant qu'assets statiques dans les deux clients (Angular et Flutter).
- **FR-009**: La migration DOIT enrichir la table `accounts` avec 3 colonnes (`bank_code`, `bank_custom_name`, `bank_custom_logo`) et assigner `'OTHER'` par défaut aux comptes existants.
- **FR-010**: L'affichage du compte DOIT suivre une cascade de résolution : logo SVG banque > logo custom base64 > emoji fallback.
- **FR-011**: Les logos custom uploadés DOIVENT être compressés côté client avant stockage (max 512px Flutter via image_picker, max 1024px Angular via canvas, qualité 0.85).
- **FR-012**: Les réponses API des comptes DOIVENT inclure les informations banque résolues (nom, couleur, URL du logo).

### Key Entities

- **Bank** : Constante embarquée dans le code (pas en base). Attributs : code (identifiant unique), nom affiché, pays (FR/TG/International), couleur brand (hex), logo (asset SVG). 29 entrées au total (28 banques + 1 "Autre").
- **Account** (enrichi) : 3 nouveaux attributs — `bankCode` (String, défaut "OTHER"), `bankCustomName` (String, nullable), `bankCustomLogo` (TEXT, nullable, base64 data URI).

## Success Criteria

### Measurable Outcomes

- **SC-001**: L'utilisateur peut créer un compte avec banque sélectionnée en 2-3 interactions (sélection banque, nom, type) sans configurer manuellement icône et couleur.
- **SC-002**: 100% des comptes existants continuent de s'afficher correctement après migration, sans aucune modification manuelle requise.
- **SC-003**: Les 28 banques pré-définies (hors "Autre") s'affichent avec leur logo et couleur corrects sur les 3 plateformes (API, Angular, Flutter).
- **SC-004**: La recherche dans le sélecteur de banque filtre les résultats sans latence perceptible (filtrage client-side sur 29 éléments, pas de requête réseau).
- **SC-005**: L'affichage d'un compte suit toujours la cascade de résolution correcte (logo banque > logo custom > emoji) sans cas de logo manquant non géré.

## Scope réalisé

Cette spec couvre les 3 sous-tâches terminées de KKS-164 :

| Issue   | Scope                                                                                                                                                                                                              | Branche spec              | Status |
|---------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------|--------|
| KKS-197 | Backend : migration Flyway V19, Bank record + BankRegistry (29 banques), BankController GET /banks, Account enrichi, 27 tests                                                                                     | 081-backend-bank-accounts | Done   |
| KKS-198 | Angular : BankService (cache signal), BankSelect (groupement, recherche), AccountBankIcon (cascade résolution), AccountForm enrichi, image.utils.ts, 347 tests                                                     | 082-angular-bank-accounts | Done   |
| KKS-199 | Flutter : Bank model (Freezed), BankRemoteDataSource, BankRepository, BankSelectPicker (bottom sheet), AccountBankIcon (cascade SVG/base64/emoji), AccountFormScreen enrichi, Drift migration v3, 29 SVG, 604 tests | 083-flutter-bank-accounts | Done   |

## Assumptions

- Les logos SVG sont sourcés depuis des sources publiques et n'ont pas de restrictions de licence pour un usage personnel self-hosted.
- La liste des banques est statique et ne nécessite pas de mise à jour dynamique — toute modification requiert un déploiement.
- La compression des logos custom est suffisante côté client pour éviter des problèmes de taille en base de données (base64 data URI en colonne TEXT).
- Les 3 regroupements géographiques (France avec 15 banques, Togo/UEMOA avec 12 banques, International avec 1 banque) couvrent les besoins de l'utilisateur unique.
