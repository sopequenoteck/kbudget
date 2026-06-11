# Documentation — KKS-255 : Comptes formulaire Flutter (alignement DESIGN.md v5)

> Date : 2026-05-26
> Issue : KKS-255

---

## Résumé

Le formulaire de compte Flutter (`AccountFormScreen`) a été aligné structurellement et visuellement sur son équivalent Angular (`account-form`), source de vérité DESIGN.md v5. L'ordre des sections a été corrigé (Type de compte avant Banque), quatre section headers uppercase ont été ajoutés, la preview card affiche désormais le type de compte en temps réel, et le dialog de suppression utilise maintenant le standard projet `ConfirmDialogCustom`. Aucune logique métier n'a été modifiée.

---

## Guide utilisateur

### Fonctionnalités

#### Structure du formulaire alignée sur Angular

**Description** : Le formulaire de création et d'édition de compte présente désormais les sections dans le même ordre que l'application Angular :
1. **Preview card** — aperçu live du compte avec border-left coloré, emoji/logo banque, nom et type
2. **TYPE DE COMPTE** — sélection COURANT / ÉPARGNE / ESPÈCES (désactivé en édition)
3. **BANQUE** — sélecteur de banque avec auto-fill couleur
4. **PERSONNALISATION** — emoji, palette de couleurs, logo custom (affiché seulement si "Autre")
5. **DÉTAILS** — nom du compte, devise (création uniquement), solde

**Avant** : L'ordre était Preview → Banque → Type → Personnalisation → Détails (type-cards après la banque).
**Après** : Preview → Type → Banque → Personnalisation → Détails (type-cards en premier, cohérent avec Angular).

#### Preview card avec label de type

**Description** : La preview card en haut du formulaire affiche maintenant le type du compte sous le nom, en majuscules ("COURANT", "ÉPARGNE", "ESPÈCES"). Le label se met à jour instantanément lors du changement de type.

**Usage** : Visible dès l'ouverture du formulaire — le type par défaut "COURANT" est affiché.

#### Devise masquée en mode édition

**Description** : En mode édition, le sélecteur de devise n'est plus affiché (la devise d'un compte ne peut pas être changée après création). Auparavant, le sélecteur était visible mais désactivé.

**Usage** : Comportement automatique — en édition, seul le champ nom et le solde sont modifiables dans la section Détails.

#### Dialog de suppression standardisé

**Description** : Le bouton "Supprimer" (mode édition, bas de formulaire) ouvre désormais le dialog de confirmation standard projet (`ConfirmDialogCustom`) avec le style danger (bouton rouge, icône trash), identique aux autres formulaires de l'application (dettes, abonnements, transactions, budgets).

#### Bloc solde actuel redesigné

**Description** : En mode édition, le solde actuel (champ lecture seule) est maintenant affiché dans un bloc Row avec fond distinct (`surfaceContainerHighest`), label à gauche et montant formaté à droite — conforme au pattern Angular `.account-form__balance-info`.

### Exemples d'utilisation

Ces changements sont visuels et structurels — aucune API ni navigation n'a été modifiée.

```dart
// Ouverture en création (comportement inchangé)
context.push('/accounts/form');

// Ouverture en édition (comportement inchangé)
context.push('/accounts/form', extra: account);

// AccountPreviewCard — nouvelle API (widget partagé)
AccountPreviewCard(
  emoji: '🏦',
  name: 'Compte courant BNP',
  colorHex: '#3b82f6',
  bankCode: 'BNP',
  accountType: AccountType.courant,  // NOUVEAU — affiche "COURANT" sous le nom
)
```

---

## Changements techniques

### Fichiers modifiés

| Fichier | Nature du changement |
|---------|---------------------|
| `flutter/lib/src/features/accounts/presentation/screens/account_form_screen.dart` | 745L → 768L : réordonnancement sections, ajout 4 `_SectionHeader`, passage `accountType` à la preview, masquage devise édition, migration `ConfirmDialogCustom`, remplacement `_ReadOnlyField` par Container/Row, suppression classe `_ReadOnlyField` |
| `flutter/lib/src/features/accounts/presentation/widgets/account_preview_card.dart` | 79L → 102L : ajout `AccountType? accountType`, méthode `_typeLabel()`, `Expanded(Column)` avec label type conditionnel |
| `flutter/test/src/features/accounts/presentation/screens/account_form_screen_test.dart` | 204L → 294L : 6 nouveaux tests widget (SC-001, SC-002, SC-003, SC-005, SC-006, SC-007) — total 14 tests |

### Fichiers créés

Aucun.

### Fichiers supprimés

Aucun — `confirm_delete_dialog.dart` conservé (utilisé par 4 autres formulaires : `debt_form`, `subscription_form`, `transaction_form`, `budget_form`).

### Détail des changements dans `account_form_screen.dart`

| Changement | Localisation | FR |
|------------|-------------|-----|
| Réordonnancement sections body | ListView children | FR-001 |
| `_SectionHeader('TYPE DE COMPTE')` | Avant `AccountTypeSelector` | FR-002 |
| `_SectionHeader('BANQUE')` | Avant `BankSelectPicker` | FR-003 |
| `_SectionHeader('PERSONNALISATION')` | Dans bloc `if OTHER` | FR-004 |
| `_SectionHeader('DÉTAILS')` | Avant champ nom | FR-005 |
| `accountType: _selectedType` sur `AccountPreviewCard` | Callsite L415 | FR-008 |
| `if (!_isEditMode) SelectPicker(...)` | Devise L523 | FR-009 |
| `ConfirmDialogCustom.show(...)` dans `_onDelete()` | L344 | FR-010 |
| Container/Row `surfaceContainerHighest` | Solde actuel L569 | FR-011 |
| Suppression classe `_ReadOnlyField` | Ex-L713 | FR-011 |
| Classe privée `_SectionHeader` | L751 | FR-002..005 |

### Dépendances ajoutées

Aucune — `ConfirmDialogCustom` et `AppTypography/AppSpacing/AppRadius` étaient déjà disponibles.

### Import retiré

`confirm_delete_dialog.dart` retiré de `account_form_screen.dart` uniquement.

---

## Configuration

Aucune configuration supplémentaire requise. Les changements sont purement UI — pas de provider, de route ni de variable d'environnement modifiés.

---

## Tests et validation

### Tests widget — `account_form_screen_test.dart`

**Tests existants conservés (8)**

| Test | Statut |
|------|--------|
| `should_showCreateMode_when_noAccount` | ✅ PASS |
| `should_showEditMode_when_accountProvided` | ✅ PASS |
| `should_prefillDefaults_when_typeSelected` | ✅ PASS |
| `should_showValidationError_when_nameEmpty` | ✅ PASS |
| `should_callCreate_when_submitInCreateMode` | ✅ PASS |
| `should_callUpdate_when_submitInEditMode` | ✅ PASS |
| `should_showDeleteButton_when_editMode` | ✅ PASS |
| `should_showActiveSwitch_when_editMode` | ✅ PASS |

**Nouveaux tests ajoutés (6)**

| Test | SC couvert | Statut |
|------|-----------|--------|
| `should_showTypeSectionBeforeBank_when_createMode` | SC-001 | ✅ PASS |
| `should_showSectionHeaders_when_createMode` | SC-002 | ✅ PASS |
| `should_showTypeLabel_when_defaultTypeInPreview` | SC-003 | ✅ PASS |
| `should_hideCurrencyPicker_when_editMode` | SC-005 | ✅ PASS |
| `should_useConfirmDialogCustom_when_deletePressed` | SC-006 | ✅ PASS |
| `should_showCurrentBalanceBlock_when_editMode` | SC-007 | ✅ PASS |

### Analyse statique

| Commande | Résultat |
|----------|---------|
| `flutter analyze` | 33 infos (29 pré-existants + 4 `prefer_const_constructors` sur `_SectionHeader` — inoffensifs), 0 erreur, 0 warning nouveau |
| `flutter test test/src/features/accounts/` | 60/60 PASS |

### Validation manuelle (checklist SC)

- [x] SC-001 : Type-cards apparaissent avant le sélecteur de banque
- [x] SC-002 : 4 section headers présents ("TYPE DE COMPTE", "BANQUE", "PERSONNALISATION", "DÉTAILS")
- [x] SC-003 : Preview card affiche "COURANT" sous le nom par défaut
- [x] SC-004 : Preview se met à jour en temps réel au tap sur une type-card (couvert par T-031 + rebuild `setState`)
- [x] SC-005 : Sélecteur devise absent en mode édition
- [x] SC-006 : Dialog suppression = `ConfirmDialogCustom` style danger (bouton rouge, icône trash)
- [x] SC-007 : Solde actuel dans un bloc Row avec fond `surfaceContainerHighest`
- [x] SC-008 : `flutter analyze` → 0 erreur nouvelle
- [x] SC-009 : `flutter test test/src/features/accounts/` → 60 tests PASS, 0 FAIL

### Points d'attention (review-impl)

- **W-001** : `SizedBox(height: AppSpacing.space0)` dans la branche `else` du bloc Personnalisation — no-op fonctionnel, code superflu non bloquant (pré-existant au ticket, conservé tel quel).
- **SC-004** : La mise à jour de la preview en temps réel est couverte par le comportement `setState` + rebuild de `AccountPreviewCard`, mais n'a pas de test automatique dédié — validé manuellement uniquement.
