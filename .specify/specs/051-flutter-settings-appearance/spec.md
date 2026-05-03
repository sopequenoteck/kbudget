# Feature Specification: Settings — Apparence

**Feature Branch**: `051-flutter-settings-appearance`
**Created**: 2026-02-23
**Status**: Ready
**Input**: KKS-112 — Flutter: Settings — Apparence. Sous-page: thème light/dark (existe déjà) + sélecteur taille texte SM/MD/XL.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Choisir le thème de l'application (Priority: P1)

L'utilisateur ouvre les paramètres d'apparence et bascule entre le thème clair et le thème sombre. Le changement est immédiat et persiste au redémarrage de l'application.

**Why this priority**: Le thème light/dark est la fonctionnalité d'apparence la plus attendue. L'infrastructure existe déjà (ThemeNotifier, persistance), il s'agit de l'exposer dans un écran dédié avec une UX claire.

**Independent Test**: Ouvrir Paramètres → Apparence → basculer entre Clair/Sombre → vérifier que le thème change immédiatement. Fermer et rouvrir l'app → vérifier que le choix est conservé.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran Apparence, **When** il sélectionne "Sombre", **Then** le thème sombre s'applique immédiatement sur tout l'écran (y compris l'écran Apparence lui-même)
2. **Given** l'utilisateur a choisi le thème "Sombre", **When** il ferme et relance l'application, **Then** le thème sombre est toujours actif
3. **Given** l'utilisateur est sur l'écran Apparence, **When** il sélectionne "Clair", **Then** le thème clair s'applique immédiatement

---

### User Story 2 - Ajuster la taille du texte (Priority: P2)

L'utilisateur ajuste la taille du texte de l'application parmi 3 niveaux prédéfinis (Petit, Normal, Grand). Le changement est immédiat et persiste au redémarrage. Un aperçu en temps réel montre l'effet sur un texte d'exemple.

**Why this priority**: Le sélecteur de taille texte est la nouveauté fonctionnelle de cette feature. Il améliore l'accessibilité et le confort de lecture. Indépendant du thème light/dark.

**Independent Test**: Ouvrir Paramètres → Apparence → changer la taille du texte entre les 3 niveaux → vérifier que le texte d'aperçu et l'ensemble de l'application reflètent la taille choisie. Fermer et rouvrir l'app → vérifier que le choix est conservé.

**Acceptance Scenarios**:

1. **Given** l'utilisateur est sur l'écran Apparence avec la taille "Normal" active, **When** il sélectionne "Grand", **Then** le texte d'aperçu s'agrandit immédiatement et toute l'application utilise la taille de texte agrandie
2. **Given** l'utilisateur est sur l'écran Apparence, **When** il sélectionne "Petit", **Then** le texte se réduit dans toute l'application et l'aperçu reflète ce changement
3. **Given** l'utilisateur a choisi "Grand", **When** il ferme et relance l'application, **Then** la taille "Grand" est toujours active
4. **Given** l'utilisateur est sur l'écran Apparence, **When** il observe les 3 options de taille, **Then** l'option actuellement active est visuellement distinguée des autres

---

### Edge Cases

- Que se passe-t-il si l'utilisateur change le thème ET la taille texte dans la même session ? Les deux changements doivent coexister sans conflit.
- Comment l'application se comporte-t-elle si la préférence de taille texte est absente ou invalide au démarrage ? La valeur par défaut "Normal" est appliquée.
- L'écran Apparence lui-même s'adapte-t-il en temps réel quand l'utilisateur modifie la taille du texte ? Oui, l'écran entier (libellés, options) reflète la taille choisie.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le système DOIT afficher un écran "Apparence" accessible depuis les paramètres, remplaçant l'écran placeholder actuel
- **FR-002**: L'écran DOIT proposer un sélecteur de thème sous forme de tile cards sélectionnables (icône + label, bordure/coche sur l'option active) avec deux options : "Clair" et "Sombre"
- **FR-003**: Le changement de thème DOIT être appliqué immédiatement (pas de bouton "Enregistrer")
- **FR-004**: Le choix de thème DOIT persister localement entre les sessions de l'application
- **FR-005**: L'écran DOIT proposer un sélecteur de taille de texte sous forme de tile cards sélectionnables (icône/label, bordure/coche sur l'option active) avec 3 niveaux : Petit (SM), Normal (MD), Grand (XL)
- **FR-006**: Le changement de taille de texte DOIT être appliqué immédiatement à toute l'application
- **FR-007**: Le choix de taille de texte DOIT persister localement entre les sessions
- **FR-008**: L'écran DOIT afficher un aperçu textuel qui reflète en temps réel la taille de texte sélectionnée
- **FR-009**: L'option active (thème et taille) DOIT être visuellement distinguée des autres options
- **FR-010**: La taille de texte par défaut pour les nouveaux utilisateurs DOIT être "Normal" (MD)
- **FR-011**: Le thème par défaut pour les nouveaux utilisateurs DOIT être "Clair" (comportement existant conservé)

### Key Entities

- **Préférence de thème** : Choix utilisateur entre clair et sombre. Attributs : valeur (clair/sombre), persistance locale.
- **Préférence de taille texte** : Choix utilisateur parmi 3 niveaux prédéfinis. Attributs : valeur (petit/normal/grand), facteur d'échelle associé (SM = 0.85, MD = 1.0, XL = 1.3), persistance locale.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut basculer entre thème clair et sombre en 1 interaction depuis l'écran Apparence, avec application immédiate
- **SC-002**: L'utilisateur peut changer la taille du texte en 1 interaction, avec application immédiate sur l'ensemble de l'application
- **SC-003**: Les préférences (thème et taille texte) sont restaurées correctement après fermeture et réouverture de l'application dans 100% des cas
- **SC-004**: L'écran Apparence remplace le placeholder "À venir" et est fonctionnel dès l'ouverture

## Assumptions

- L'infrastructure de thème light/dark existe déjà (ThemeNotifier, AppTheme enum, persistance via AppConfigRepository). L'écran doit la consommer, pas la recréer.
- Les 3 niveaux de taille texte (SM/MD/XL) correspondent à des facteurs d'échelle appliqués à l'ensemble de l'application (SM = 0.85, MD = 1.0, XL = 1.3), pas à des valeurs de taille de police individuelles.
- Le mode "Système" (suivre le thème OS) n'est pas dans le scope — seulement Clair et Sombre comme décrit dans l'issue.
- La taille de texte est une préférence purement locale (pas synchronisée avec le serveur).

## Scope

### Inclus
- Écran Apparence complet (remplace le stub)
- Sélecteur thème clair/sombre
- Sélecteur taille texte 3 niveaux avec aperçu
- Persistance locale des deux préférences
- Application immédiate des changements

### Exclus
- Mode thème "Système" (suit le thème OS)
- Personnalisation de la police (famille de police)
- Personnalisation des couleurs d'accent
- Synchronisation des préférences avec le serveur

## Clarifications

### Session 2026-02-23

- Q: Quels facteurs d'échelle (textScaleFactor) pour les 3 niveaux SM/MD/XL ? → A: SM = 0.85, MD = 1.0, XL = 1.3 (écart modéré)
- Q: Quel pattern UX pour les sélecteurs de thème et taille texte ? → A: Tile cards sélectionnables (icône + label, bordure/coche sur l'option active)
