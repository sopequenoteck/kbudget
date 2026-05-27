# Quickstart — KKS-246 : Settings hub Flutter

## Prérequis

```bash
cd flutter
flutter pub get   # après ajout package_info_plus dans pubspec.yaml
dart run build_runner build --delete-conflicting-outputs  # si Freezed/Drift impacté
```

## Tester le hub

```bash
cd flutter && flutter run
```

Naviguer vers **Réglages** → vérifier les 7 sections en scroll.

## Vérifier la suppression des routes

Les routes suivantes ne doivent plus exister :
- `/settings/appearance`
- `/settings/features`
- `/settings/notifications`

Test : saisir manuellement une deep link vers ces routes → doit rediriger vers le hub ou 404.

## Vérifier le thème Auto

1. Réglages → Apparence → sélectionner "Auto"
2. Changer la préférence système du device (clair ↔ sombre)
3. L'app doit suivre la préférence sans redémarrage

## Vérifier le footer

- **Mode local** : le footer affiche "K-Budget vX.Y.Z · Mode local"
- **Mode server** : le footer affiche le statut serveur après init (vert = online, rouge = offline)

## Vérifier la navigation drag-and-drop

1. Réglages → section Navigation
2. Drag un module (ex: Abonnements) vers une autre position
3. Quitter les réglages → la bottom nav reflète le nouvel ordre
4. Fermer et rouvrir l'app → l'ordre est persisté

## Points de vigilance

- `mounted` guard obligatoire dans tous les callbacks async (`_runHealthCheck`, `PackageInfo.fromPlatform`)
- `NeverScrollableScrollPhysics` sur `ReorderableListView` pour éviter les conflits de scroll
- Thème `system` : tester sur un device réel (simulateur ne reflète pas toujours le changement système)
