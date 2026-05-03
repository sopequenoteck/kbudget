# Data Model: Currency Dashboard

**Feature Branch**: `070-currency-dashboard`
**Date**: 2026-03-06

## Nouvelles entites

### ExchangeRate

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| id | UUID | PK, auto-generated | Identifiant unique |
| user | User (FK) | NOT NULL | Proprietaire du taux |
| baseCurrency | Currency (enum) | NOT NULL | Devise de base (= devise principale) |
| targetCurrency | Currency (enum) | NOT NULL | Devise cible |
| rate | BigDecimal | NOT NULL, > 0, scale 6 | Taux de conversion (1 base = rate target) |
| updatedAt | LocalDateTime | @UpdateTimestamp | Derniere mise a jour |

**Contraintes**:
- Unicite : `UNIQUE(user_id, base_currency, target_currency)`
- `baseCurrency != targetCurrency` (validation Bean)
- `rate > 0` (validation Bean)
- `rate` a maximum 6 decimales (validation Bean)

**Stockage DB** : `DECIMAL(20,6)` pour le taux, `VARCHAR(3)` pour les devises, `@Enumerated(EnumType.STRING)`.

```java
@Entity
@Table(name = "exchange_rates",
       uniqueConstraints = @UniqueConstraint(
           columnNames = {"user_id", "base_currency", "target_currency"}))
@Data @NoArgsConstructor @AllArgsConstructor @Builder
public class ExchangeRate {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "base_currency", nullable = false, length = 3)
    private Currency baseCurrency;

    @Enumerated(EnumType.STRING)
    @Column(name = "target_currency", nullable = false, length = 3)
    private Currency targetCurrency;

    @Column(nullable = false, precision = 20, scale = 6)
    private BigDecimal rate;

    @UpdateTimestamp
    private LocalDateTime updatedAt;
}
```

## Entites modifiees

### UserPreference (enrichi)

Ajout du champ `currencies` :

| Champ | Type | Contraintes | Description |
|-------|------|-------------|-------------|
| currencies | List\<Currency\> | NOT NULL, default [EUR] | Liste ordonnee des devises. Index 0 = devise principale. |

**Stockage DB** : `VARCHAR(100)`, converter custom `CurrencyListConverter` (meme pattern que `FeatureListConverter`).

```java
// Ajout dans UserPreference.java
@Convert(converter = CurrencyListConverter.class)
@Column(name = "currencies", nullable = false, length = 100)
@Builder.Default
private List<Currency> currencies = List.of(Currency.EUR);
```

### User (modification)

Suppression du champ `defaultCurrency` (migration V14). Remplace par `UserPreference.currencies[0]`.

## Entites inchangees (reference)

### Account, Transaction, Subscription, Debt

Ces entites conservent leur champ `currency` existant. Aucune modification.

## Relations

```
User 1──* ExchangeRate (user_id FK)
User 1──1 UserPreference (user_id FK, enrichi avec currencies)
ExchangeRate ──> Currency (base_currency, target_currency : enums)
UserPreference ──> Currency[] (currencies : liste ordonnee)
```

## Transitions d'etat

### Changement de devise principale

```
[User tape pill XOF]
  → Client : reorder currencies en memoire [XOF, EUR, ...]
  → Client : recalcul instantane via inversion (1/rate)
  → Debounce 2s ou navigation hors dashboard
  → PUT /users/me/preferences { currencies: [XOF, EUR, ...] }
  → Backend : detecte changement de currencies[0]
  → Backend : rebaseRates(userId, XOF) — inverse tous les taux
  → Backend : sauvegarde UserPreference + ExchangeRates
  → Response 200
```

### Ajout d'une devise

```
[User ajoute USD dans Settings]
  → PUT /users/me/preferences { currencies: [EUR, XOF, USD] }
  → Backend : sauvegarde currencies
  → Si parite fixe connue (ex: EUR/XOF) : pre-remplir le taux
  → Si taux flottant : pas de taux cree automatiquement
  → Dashboard : avertissement pour USD si pas de taux
```

## Migrations Flyway

### V13 — Ajout currencies + exchange_rates

```sql
-- Ajout colonne currencies a user_preferences
ALTER TABLE user_preferences ADD COLUMN currencies VARCHAR(100) NOT NULL DEFAULT 'EUR';

-- Initialiser depuis users.default_currency
UPDATE user_preferences up
SET currencies = u.default_currency
FROM users u
WHERE up.user_id = u.id;

-- Table exchange_rates
CREATE TABLE exchange_rates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    base_currency VARCHAR(3) NOT NULL,
    target_currency VARCHAR(3) NOT NULL,
    rate DECIMAL(20,6) NOT NULL CHECK (rate > 0),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, base_currency, target_currency),
    CHECK (base_currency != target_currency)
);

CREATE INDEX idx_exchange_rates_user ON exchange_rates(user_id);
```

### V14 — Suppression User.defaultCurrency

```sql
ALTER TABLE users DROP COLUMN default_currency;
```

## Modeles clients

### Flutter (Freezed)

```dart
@freezed
class ExchangeRate with _$ExchangeRate {
  const factory ExchangeRate({
    required String id,
    required Currency baseCurrency,
    required Currency targetCurrency,
    required double rate,
    DateTime? updatedAt,
  }) = _ExchangeRate;

  factory ExchangeRate.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRateFromJson(json);
}
```

> Note : `Currency` est l'enum Dart existant dans `domain/enums/`. La serialisation JSON (String ↔ Currency) est geree par `json_serializable` via `@JsonEnum`.

### Angular (TypeScript)

```typescript
export interface ExchangeRate {
  id: string;
  baseCurrency: string;
  targetCurrency: string;
  rate: number;
  updatedAt: string;
}
```
