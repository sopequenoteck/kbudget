# API Contract: Currencies (multi-currency)

## Nouvel endpoint

### GET /api/currencies — Liste des devises supportées

**Auth** : JWT requis

**Response** (`List<CurrencyInfo>` — NEW) :
```json
[
  {
    "code": "EUR",
    "symbol": "€",
    "name": "Euro",
    "decimalPlaces": 2
  },
  {
    "code": "XOF",
    "symbol": "CFA",
    "name": "Franc CFA (BCEAO)",
    "decimalPlaces": 0
  },
  {
    "code": "USD",
    "symbol": "$",
    "name": "Dollar américain",
    "decimalPlaces": 2
  },
  {
    "code": "GBP",
    "symbol": "£",
    "name": "Livre sterling",
    "decimalPlaces": 2
  },
  {
    "code": "CHF",
    "symbol": "CHF",
    "name": "Franc suisse",
    "decimalPlaces": 2
  },
  {
    "code": "CAD",
    "symbol": "CA$",
    "name": "Dollar canadien",
    "decimalPlaces": 2
  },
  {
    "code": "MAD",
    "symbol": "MAD",
    "name": "Dirham marocain",
    "decimalPlaces": 2
  }
]
```

**Notes** :
- La liste est générée depuis l'enum `Currency` côté backend
- Pas de paramètres de filtrage
- Résultat stable et cacheable côté frontend
- Ordre : alphabétique par code
