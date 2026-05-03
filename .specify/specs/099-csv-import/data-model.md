# Data Model: Import de releves bancaires CSV

**Branch**: `099-csv-import` | **Date**: 2026-03-20

## Entities

### ImportProfile (JPA Entity — profils personnalises uniquement)

Les profils pre-configures sont dans `ImportProfileRegistry` (classe statique, pattern `BankRegistry`).

| Field | Type | Nullable | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | non | PK, auto-generated | Identifiant unique |
| user | User | non | FK → users | Proprietaire |
| name | String | non | max 100 | Nom du profil (ex: "Ma banque") |
| separator | String | non | max 5, default "," | Separateur CSV |
| dateFormat | String | non | max 20, default "dd/MM/yyyy" | Format de date Java (DateTimeFormatter) |
| dateColumn | String | non | max 50 | Nom de la colonne date |
| amountColumn | String | oui | max 50 | Colonne montant (strategie signee) |
| debitColumn | String | oui | max 50 | Colonne debit (strategie double) |
| creditColumn | String | oui | max 50 | Colonne credit (strategie double) |
| labelColumn | String | non | max 50 | Colonne libelle source |
| encoding | String | non | max 20, default "UTF-8" | Encodage du fichier |
| decimalSeparator | String | non | max 1, default "." | Separateur decimal |
| skipHeaderLines | Integer | non | default 0 | Nombre de lignes a ignorer avant les en-tetes |
| createdAt | LocalDateTime | non | auto | Date de creation |
| updatedAt | LocalDateTime | non | auto | Derniere modification |

**Contrainte metier** : `amountColumn` OU (`debitColumn` + `creditColumn`) doivent etre renseignes (pas les deux strategies simultanement). Validation dans le service.

**Table** : `import_profiles`

---

### ImportDraft

| Field | Type | Nullable | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | non | PK, auto-generated | Identifiant unique |
| user | User | non | FK → users | Proprietaire |
| account | Account | non | FK → accounts | Compte cible |
| status | ImportDraftStatus | non | enum | PENDING, COMPLETED, EXPIRED |
| fileName | String | oui | max 255 | Nom du fichier source |
| totalLines | Integer | non | | Nombre total de lignes parsees |
| readyCount | Integer | non | default 0 | Lignes READY |
| reviewCount | Integer | non | default 0 | Lignes NEEDS_REVIEW |
| duplicateCount | Integer | non | default 0 | Lignes DUPLICATE |
| skippedCount | Integer | non | default 0 | Lignes SKIPPED |
| profileId | UUID | oui | | Profil utilise (null si mapping manuel) |
| profileSource | String | oui | max 20 | "REGISTRY" ou "CUSTOM" |
| createdAt | LocalDateTime | non | auto | Date de creation |
| expiresAt | LocalDateTime | non | | createdAt + 7 jours |

**Contrainte metier** : UNIQUE(user_id, account_id) WHERE status = 'PENDING' — un seul brouillon actif par compte.

**Table** : `import_drafts`

**Enum ImportDraftStatus** : `PENDING`, `COMPLETED`, `EXPIRED`

---

### ImportDraftLine

| Field | Type | Nullable | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | non | PK, auto-generated | Identifiant unique |
| draft | ImportDraft | non | FK → import_drafts, CASCADE | Brouillon parent |
| lineNumber | Integer | non | | Numero de ligne dans le CSV |
| rawLabel | String | non | max 500 | Libelle brut du CSV |
| cleanLabel | String | non | max 500 | Libelle nettoye |
| amount | BigDecimal | non | precision 19, scale 2 | Montant (toujours positif) |
| date | LocalDate | non | | Date de la transaction |
| transactionType | TransactionType | non | enum | DEPENSE ou RECETTE |
| status | ImportLineStatus | non | enum | READY, NEEDS_REVIEW, DUPLICATE, SKIPPED |
| statusMessage | String | oui | max 500 | Message explicatif (erreur, raison du statut) |
| category | Category | oui | FK → categories | Categorie suggeree ou assignee |
| duplicateTransactionId | UUID | oui | | Reference vers la transaction doublon detectee |
| createdAt | LocalDateTime | non | auto | Date de creation |
| updatedAt | LocalDateTime | non | auto | Derniere modification |

**Table** : `import_draft_lines`

**Enum ImportLineStatus** : `READY`, `NEEDS_REVIEW`, `DUPLICATE`, `SKIPPED`

---

### CategoryRule

| Field | Type | Nullable | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | non | PK, auto-generated | Identifiant unique |
| user | User | non | FK → users | Proprietaire |
| pattern | String | non | max 200 | Pattern de matching (containment, case-insensitive) |
| category | Category | non | FK → categories | Categorie cible |
| createdAt | LocalDateTime | non | auto | Date de creation (ordre de priorite) |

**Contrainte metier** : UNIQUE(user_id, pattern) — un seul pattern par utilisateur.

**Table** : `category_rules`

---

### ImportHistory

| Field | Type | Nullable | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | non | PK, auto-generated | Identifiant unique |
| user | User | non | FK → users | Proprietaire |
| account | Account | non | FK → accounts | Compte cible |
| transactionCount | Integer | non | | Nombre de transactions importees |
| fileName | String | oui | max 255 | Nom du fichier source |
| importedAt | LocalDateTime | non | auto | Date de l'import |

**Table** : `import_history`

---

## Relationships

```
User 1──N ImportProfile     (profils personnalises)
User 1──N ImportDraft        (brouillons)
User 1──N CategoryRule       (regles de categorisation)
User 1──N ImportHistory      (historique)

Account 1──0..1 ImportDraft  (un seul brouillon actif par compte)
Account 1──N ImportHistory   (historique par compte)

ImportDraft 1──N ImportDraftLine (lignes du brouillon)

Category 1──N CategoryRule   (categorie cible des regles)
Category 1──N ImportDraftLine (categorie suggeree)
```

## State Transitions

### ImportDraft.status

```
                    upload CSV
                        │
                        ▼
                    PENDING ──── confirm ────→ COMPLETED
                        │                         │
                        │                         ▼
                    7 jours                  ImportHistory cree
                        │                   ImportDraft supprime
                        ▼
                    EXPIRED
                        │
                        ▼
                    Supprime (cleanup job)
```

### ImportDraftLine.status

```
                    parsing CSV
                        │
            ┌───────────┼───────────┐
            ▼           ▼           ▼
         READY    NEEDS_REVIEW   DUPLICATE
            │           │           │
            │     user corrige      │
            │           │     ┌─────┴─────┐
            │           ▼     ▼           ▼
            │        READY   READY     SKIPPED
            │           │     │
            └───────────┴─────┘
                        │
                   user ignore
                        │
                        ▼
                    SKIPPED
```

## Flyway Migration

**Version** : V22

**Tables creees** :
- `import_profiles`
- `import_drafts`
- `import_draft_lines`
- `category_rules`
- `import_history`

**Index** :
- `import_drafts(user_id, account_id)` — lookup brouillon par compte
- `import_draft_lines(draft_id)` — FK cascade
- `category_rules(user_id)` — regles par utilisateur
- `import_history(user_id)` — historique par utilisateur

## ImportProfileRegistry (statique, pas en BDD)

Structure par profil pre-configure (record Java) :

```java
record ImportProfileConfig(
    String bankCode,          // cle de resolution (ex: "SG")
    String name,              // nom affiche (ex: "Societe Generale")
    String separator,         // ex: ";"
    String dateFormat,        // ex: "dd/MM/yyyy"
    String dateColumn,        // ex: "Date de l'operation"
    String amountColumn,      // ex: "Montant" (null si double colonne)
    String debitColumn,       // null si colonne unique
    String creditColumn,      // null si colonne unique
    String labelColumn,       // ex: "Detail"
    String encoding,          // ex: "ISO-8859-1"
    String decimalSeparator,  // ex: ","
    int skipHeaderLines,      // ex: 1 (SG a une ligne d'en-tete de compte)
    List<String> cleanupPatterns  // regex de nettoyage du libelle
)
```

**Profils initiaux** : Societe Generale (SG). Autres banques ajoutees au besoin.
