# API Contracts: Import CSV

**Base path**: `/api`

---

## Import — Upload & Draft Management

### POST /imports/upload

Upload un fichier CSV et cree un brouillon d'import.

**Content-Type**: `multipart/form-data`

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| file | MultipartFile | oui | Fichier CSV (max 5 Mo) |
| accountId | UUID | oui | Compte cible (form field) |

**Response 201** — `ImportDraftResponse`:
```json
{
  "id": "uuid",
  "accountId": "uuid",
  "accountName": "Compte Courant SG",
  "status": "PENDING",
  "fileName": "releve_mars_2026.csv",
  "totalLines": 47,
  "readyCount": 35,
  "reviewCount": 5,
  "duplicateCount": 7,
  "skippedCount": 0,
  "profileName": "Societe Generale",
  "profileSource": "REGISTRY",
  "createdAt": "2026-03-20T14:30:00",
  "expiresAt": "2026-03-27T14:30:00",
  "lines": [
    {
      "id": "uuid",
      "lineNumber": 1,
      "rawLabel": "CARTE X3855 16/03 UEP*SUPER U 101607535098170IOPD",
      "cleanLabel": "SUPER U",
      "amount": 45.50,
      "date": "2026-03-16",
      "transactionType": "DEPENSE",
      "status": "READY",
      "statusMessage": null,
      "categoryId": "uuid",
      "categoryName": "Courses",
      "duplicateTransactionId": null
    }
  ]
}
```

**Error 400**: Fichier invalide (pas CSV, trop gros, vide, encodage non supporte)
**Error 400**: Compte inactif
**Error 409**: Brouillon actif existant pour ce compte (retourne l'id du brouillon existant)
**Error 422**: Format CSV non reconnu et pas de profil (necessite mapping manuel)

---

### POST /imports/upload-with-mapping

Upload un fichier CSV avec mapping manuel des colonnes.

**Content-Type**: `multipart/form-data`

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| file | MultipartFile | oui | Fichier CSV (max 5 Mo) |
| accountId | UUID | oui | Compte cible |
| mapping | String (JSON) | oui | Mapping des colonnes (JSON stringify) |

**Mapping JSON**:
```json
{
  "separator": ";",
  "dateFormat": "dd/MM/yyyy",
  "dateColumn": "Date",
  "amountColumn": "Montant",
  "debitColumn": null,
  "creditColumn": null,
  "labelColumn": "Libelle",
  "encoding": "UTF-8",
  "decimalSeparator": ",",
  "skipHeaderLines": 0,
  "saveAsProfile": true,
  "profileName": "Ma banque"
}
```

**Response 201** — `ImportDraftResponse` (meme format que POST /imports/upload)

---

### GET /imports/preview

Preview des premieres lignes d'un CSV pour aider au mapping manuel.

**Content-Type**: `multipart/form-data`

**Parameters**:
| Name | Type | Required | Description |
|------|------|----------|-------------|
| file | MultipartFile | oui | Fichier CSV |
| separator | String | non | Separateur (default: auto-detect) |
| encoding | String | non | Encodage (default: UTF-8) |
| skipHeaderLines | Integer | non | Lignes a ignorer (default: 0) |

**Response 200** — `CsvPreviewResponse`:
```json
{
  "headers": ["Date de l'operation", "Detail", "Montant"],
  "rows": [
    ["16/03/2026", "CARTE X3855 16/03 UEP*SUPER U", "-45.50"],
    ["15/03/2026", "VIR SEPA M DUPONT", "150.00"]
  ],
  "detectedSeparator": ";",
  "detectedEncoding": "ISO-8859-1",
  "totalRows": 47
}
```

---

### GET /imports/drafts

Liste les brouillons actifs de l'utilisateur.

**Response 200** — `List<ImportDraftSummaryResponse>`:
```json
[
  {
    "id": "uuid",
    "accountId": "uuid",
    "accountName": "Compte Courant SG",
    "status": "PENDING",
    "fileName": "releve_mars_2026.csv",
    "totalLines": 47,
    "readyCount": 35,
    "reviewCount": 5,
    "duplicateCount": 7,
    "skippedCount": 0,
    "createdAt": "2026-03-20T14:30:00",
    "expiresAt": "2026-03-27T14:30:00"
  }
]
```

---

### GET /imports/drafts/{draftId}

Detail d'un brouillon avec toutes ses lignes.

**Response 200** — `ImportDraftResponse` (meme format que POST /imports/upload)
**Error 404**: Brouillon non trouve

---

### PUT /imports/drafts/{draftId}/lines/{lineId}

Met a jour une ligne de brouillon (categorie, statut).

**Request Body** — `ImportLineUpdateRequest`:
```json
{
  "categoryId": "uuid",
  "status": "READY"
}
```

**Response 200** — `ImportDraftLineResponse` (ligne mise a jour)
**Error 400**: Transition de statut invalide

---

### PUT /imports/drafts/{draftId}/lines/batch

Met a jour plusieurs lignes en masse (action groupee).

**Request Body** — `ImportLineBatchUpdateRequest`:
```json
{
  "lineIds": ["uuid1", "uuid2", "uuid3"],
  "categoryId": "uuid",
  "status": "READY"
}
```

**Response 200** — `List<ImportDraftLineResponse>` (lignes mises a jour)

---

### POST /imports/drafts/{draftId}/confirm

Confirme l'import : cree les transactions pour toutes les lignes READY.

**Response 200** — `ImportConfirmResponse`:
```json
{
  "importedCount": 35,
  "skippedCount": 12,
  "historyId": "uuid"
}
```

**Error 400**: Brouillon avec des lignes non resolues (NEEDS_REVIEW ou DUPLICATE — toutes les lignes doivent etre READY ou SKIPPED)
**Error 409**: Brouillon deja finalise

---

### DELETE /imports/drafts/{draftId}

Supprime un brouillon et toutes ses lignes.

**Response 204**

---

## Category Rules

### GET /imports/rules

Liste les regles de categorisation de l'utilisateur.

**Response 200** — `List<CategoryRuleResponse>`:
```json
[
  {
    "id": "uuid",
    "pattern": "CARREFOUR",
    "categoryId": "uuid",
    "categoryName": "Courses",
    "categoryIcon": "shopping-cart",
    "createdAt": "2026-03-15T10:00:00"
  }
]
```

---

### POST /imports/rules

Cree une nouvelle regle de categorisation.

**Request Body** — `CategoryRuleRequest`:
```json
{
  "pattern": "CARREFOUR",
  "categoryId": "uuid"
}
```

**Response 201** — `CategoryRuleResponse`
**Error 409**: Pattern deja existant pour cet utilisateur

---

### PUT /imports/rules/{ruleId}

Modifie une regle de categorisation.

**Request Body** — `CategoryRuleRequest`
**Response 200** — `CategoryRuleResponse`

---

### DELETE /imports/rules/{ruleId}

Supprime une regle de categorisation.

**Response 204**

---

## Import Profiles (custom)

### GET /imports/profiles

Liste les profils d'import (pre-configures + personnalises).

**Response 200** — `List<ImportProfileResponse>`:
```json
[
  {
    "id": null,
    "bankCode": "SG",
    "name": "Societe Generale",
    "source": "REGISTRY",
    "editable": false
  },
  {
    "id": "uuid",
    "bankCode": null,
    "name": "Ma banque togolaise",
    "source": "CUSTOM",
    "editable": true
  }
]
```

---

### DELETE /imports/profiles/{profileId}

Supprime un profil personnalise.

**Response 204**
**Error 400**: Tentative de suppression d'un profil pre-configure

---

## Import History

### GET /imports/history

Liste l'historique des imports finalises.

**Query Parameters**:
| Name | Type | Required | Default |
|------|------|----------|---------|
| page | int | non | 0 |
| size | int | non | 20 |

**Response 200** — `Page<ImportHistoryResponse>`:
```json
{
  "content": [
    {
      "id": "uuid",
      "accountId": "uuid",
      "accountName": "Compte Courant SG",
      "transactionCount": 35,
      "fileName": "releve_mars_2026.csv",
      "importedAt": "2026-03-20T15:00:00"
    }
  ],
  "totalElements": 5,
  "totalPages": 1
}
```
