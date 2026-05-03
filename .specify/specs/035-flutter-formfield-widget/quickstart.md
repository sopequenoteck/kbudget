# Quickstart: Widget FormField

**Feature**: 035-flutter-formfield-widget

## Scénario 1 — Champ texte basique avec label

```dart
AppFormField(
  label: 'Montant',
  child: TextField(
    decoration: InputDecoration.collapsed(hintText: 'Ex: 42.50'),
  ),
)
```

**Résultat attendu** : Label "Montant" au-dessus, conteneur gris sans bordure (radius xl), champ texte à l'intérieur. Bordure amber au focus.

## Scénario 2 — Champ avec erreur de validation

```dart
AppFormField(
  label: 'Email',
  showError: true,
  errorMessage: 'Format invalide',
  child: TextField(
    decoration: InputDecoration.collapsed(hintText: 'exemple@email.com'),
  ),
)
```

**Résultat attendu** : Label + champ + message "Format invalide" en rouge sous le conteneur.

## Scénario 3 — Sans erreur visible (message ignoré)

```dart
AppFormField(
  label: 'Nom',
  showError: false,
  errorMessage: 'Ce champ est requis',
  child: TextField(
    decoration: InputDecoration.collapsed(hintText: 'Jean Dupont'),
  ),
)
```

**Résultat attendu** : Pas de message d'erreur visible, même si `errorMessage` est fourni.

## Scénario 4 — Composition avec un widget personnalisé

```dart
AppFormField(
  label: 'Catégorie',
  child: GestureDetector(
    onTap: () => _openCategoryPicker(),
    child: Row(
      children: [
        Text(selectedCategory?.name ?? 'Sélectionner'),
        const Spacer(),
        Icon(Icons.chevron_right),
      ],
    ),
  ),
)
```

**Résultat attendu** : Le widget personnalisé s'affiche dans le conteneur stylé avec le label au-dessus.

## Scénario 5 — Thème sombre

```dart
// Même code que scénario 1, dans un contexte ThemeMode.dark
AppFormField(
  label: 'Montant',
  child: TextField(
    decoration: InputDecoration.collapsed(hintText: 'Ex: 42.50'),
  ),
)
```

**Résultat attendu** : Conteneur avec fond gris foncé, label en couleur secondaire du thème sombre, bordure amber au focus.

## API du widget

| Paramètre | Type | Requis | Défaut | Description |
|------------|------|--------|--------|-------------|
| label | String | oui | — | Texte du label affiché au-dessus |
| child | Widget | oui | — | Widget enfant (champ de saisie) |
| showError | bool | non | false | Affiche le message d'erreur |
| errorMessage | String | non | '' | Texte du message d'erreur |
