# Research: 083-flutter-bank-accounts

## R1 — SVG Assets : source et stratégie d'embarquement

**Decision**: Copier les 29 fichiers SVG depuis `api/src/main/resources/static/bank-logos/` vers `flutter/assets/banks/`. Les noms de fichiers correspondent aux codes banque en minuscules (`sg.svg`, `bnp.svg`, etc.).

**Rationale**: Flutter ne peut pas charger des SVG depuis une URL serveur de manière aussi fiable que des assets embarqués. L'approche locale garantit un rendu instantané sans dépendance réseau, cohérent avec le mode offline de l'app. Le package `flutter_svg` lit nativement les assets.

**Alternatives considered**:
- Charger les SVG depuis le serveur via `SvgPicture.network()` : nécessite une connexion, plus lent, cache complexe à gérer.
- Convertir les SVG en PNG : perte de qualité, taille d'assets accrue.

## R2 — Package flutter_svg

**Decision**: Ajouter `flutter_svg: ^2.0.16` (dernière stable) au `pubspec.yaml`.

**Rationale**: Package standard pour le rendu SVG dans Flutter, 99% pub score, utilisé dans des millions d'apps. Supporte les assets locaux via `SvgPicture.asset()` avec contrôle de taille (`width`, `height`).

**Alternatives considered**:
- `jovial_svg` : moins populaire, API plus complexe.
- Convertir en `IconData` : inadapté pour des logos multi-couleurs.

## R3 — Data mode pour les banques

**Decision**: Server-only (`BankRepositoryRemote` via Dio). Pas de Drift/SQLite pour la table `banks`. Le `banksProvider` est un `FutureProvider` qui charge les banques une seule fois depuis `GET /api/banks`.

**Rationale**: La liste des banques est statique (29 entrées rarement modifiées). Un FutureProvider avec cache en mémoire est suffisant. Pas besoin de persistance locale car :
1. Les logos sont des assets embarqués (pas besoin de réseau pour l'affichage).
2. Les métadonnées banque (nom, couleur, pays) sont stables.
3. En mode offline, les comptes existants ont déjà `bankCode` — le widget `AccountBankIcon` résout le logo localement.

**Alternatives considered**:
- Drift table `banks` avec sync : sur-ingénierie pour 29 entrées statiques.
- Hardcoder les banques dans le code Flutter : divergence possible avec le backend.

## R4 — Drift schema migration

**Decision**: Ajouter 3 colonnes nullable à la table `Accounts` dans `database.dart` : `bankCode` (TextColumn, nullable), `bankCustomName` (TextColumn, nullable), `bankCustomLogo` (TextColumn, nullable). Incrémenter `schemaVersion` et ajouter un step de migration.

**Rationale**: Les comptes existants en SQLite n'ont pas de champs bank. Les colonnes nullable permettent la rétrocompatibilité. La migration Drift ajoute les colonnes avec `ALTER TABLE`.

**Alternatives considered**:
- Recréer la table : perte de données, inutilement destructif.
- Ne pas migrer (server-only) : briserait le mode local/Drift.

## R5 — AccountBankIcon : approche widget vs mixin

**Decision**: Widget StatelessWidget dédié dans `common_widgets/account_bank_icon.dart` avec paramètres `Account account` et `double size`.

**Rationale**: Aligné avec l'Angular (`AccountBankIcon` component). Widget réutilisable avec cascade de résolution claire : `SvgPicture.asset` → `Image.memory` → `Text` (emoji). Encapsule toute la logique de résolution en un seul endroit.

**Alternatives considered**:
- Méthode utilitaire retournant un Widget : moins composable, pas de gestion d'état interne (erreurs).
- Extension sur Account : pollue le modèle avec du UI.

## R6 — BankSelectPicker : composant dédié vs SelectPicker enrichi

**Decision**: Composant dédié `BankSelectPicker` (ConsumerWidget) utilisant `AppModal.show()` en bottom sheet. Ne réutilise PAS le `SelectPicker` générique car le groupement par pays et l'option "Autre" persistante nécessitent un layout custom.

**Rationale**: Le `SelectPicker` est conçu pour des listes plates. Le `BankSelectPicker` a besoin de :
1. Groupement par région (headers de section)
2. SVG logos dans chaque item
3. Option "Autre" toujours visible même pendant le filtrage
4. Dot couleur brand à côté de chaque banque

L'Angular a fait le même choix (composant BankSelect dédié, pas de réutilisation du SelectPicker).

**Alternatives considered**:
- Enrichir SelectPicker avec groupement + imageUrl : complexifierait un widget déjà fonctionnel pour un cas d'usage unique.

## R7 — Compression logo custom

**Decision**: Réutiliser `image_utils.dart` existant (`fileToBase64DataUri`) avec `maxWidth=512` et `quality=80` (vs 1024/85 pour les produits). Identique aux paramètres Angular.

**Rationale**: Le logo banque est affiché en 24-32px — une résolution source de 512px est largement suffisante. La qualité à 80% donne un bon ratio taille/qualité pour un logo.

**Alternatives considered**:
- Mêmes paramètres que les produits (1024px) : inutilement lourd pour un logo.
- Pas de compression : data URIs trop volumineux en base64.
