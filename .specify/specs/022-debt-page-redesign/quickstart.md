# Quickstart: Validation du redesign page Dettes

**Branch**: `022-debt-page-redesign`

## Prérequis

1. Backend lancé : `cd api && mvn spring-boot:run`
2. Frontend lancé : `cd app && ng serve`
3. Données de test : avoir des dettes mixtes (emprunts + prêts, en cours + remboursées, avec et sans catégorie)

## Checklist de validation manuelle

### KPI Cards
- [ ] 3 cartes KPI visibles en haut (Je dois, On me doit, Solde net)
- [ ] Style cohérent avec page transactions (cards blanches, shadow-md, pas de border-top)
- [ ] Montants colorés (rouge pour Je dois, vert pour On me doit, conditionnel pour Solde)
- [ ] KPI reflètent uniquement les dettes en cours (pas les remboursées)
- [ ] Changer le filtre statut ne change PAS les KPI

### Filtre
- [ ] Un seul segmented control (Tous / En cours / Remboursé)
- [ ] Pas de filtre par sens visible
- [ ] Filtrage fonctionne sur les deux sections

### Sections groupées
- [ ] Section "On me doit" en premier (accent vert à gauche)
- [ ] Section "Je dois" en second (accent rouge à gauche)
- [ ] Chaque section a un header avec titre + total
- [ ] Section disparaît si aucune dette après filtre

### Items
- [ ] Icône = emoji catégorie (ou fallback 💸/💰 selon type)
- [ ] Titre = nom de la personne
- [ ] Sous-titre = nom catégorie ou "Emprunt"/"Prêt"
- [ ] Montant coloré selon type
- [ ] Date relative à droite
- [ ] Items remboursés : opacité réduite + "· Remboursé" dans le sous-titre

### Edge cases
- [ ] Aucune dette → état vide global, pas de KPI
- [ ] Toutes du même sens → seule la section correspondante s'affiche
- [ ] Filtre "Remboursé" sans dettes remboursées → état vide
- [ ] Loading → spinner
- [ ] Erreur → message + bouton Réessayer
- [ ] Clic sur un item → modale s'ouvre
- [ ] FAB (+) → créer une dette

### Responsive
- [ ] Page lisible sur 320px de large
- [ ] KPI cards ne débordent pas sur petit écran
