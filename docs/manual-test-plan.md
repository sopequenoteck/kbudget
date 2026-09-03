# Plan de Test Manuel — Migration Angular → Flutter

> **Date** : 2026-02-26
> **Objectif** : Valider que l'application Flutter reproduit fidèlement toutes les fonctionnalités de l'application Angular, et fonctionne correctement en mode local et serveur.
> **Prérequis** : API Spring Boot lancée (profil dev), compte utilisateur existant, au moins 2 comptes bancaires, quelques transactions/abonnements/dettes de test.

---

## Table des matières

1. [Onboarding & Configuration](#1-onboarding--configuration)
2. [Authentification](#2-authentification)
3. [Lock Screen (PIN & Biometrie)](#3-lock-screen)
4. [Dashboard](#4-dashboard)
5. [Transactions](#5-transactions)
6. [Formulaire Transaction](#6-formulaire-transaction)
7. [Virements](#7-virements)
8. [Abonnements](#8-abonnements)
9. [Formulaire Abonnement](#9-formulaire-abonnement)
10. [Dettes](#10-dettes)
11. [Formulaire Dette](#11-formulaire-dette)
12. [FAB Menu (Speed Dial)](#12-fab-menu)
13. [Settings — Hub](#13-settings-hub)
14. [Settings — Comptes](#14-settings-comptes)
15. [Settings — Categories](#15-settings-categories)
16. [Settings — Profil](#16-settings-profil)
17. [Settings — Apparence](#17-settings-apparence)
18. [Settings — Donnees](#18-settings-donnees)
19. [Cas Limites & Edge Cases](#19-cas-limites--edge-cases)
20. [Divergences connues Angular / Flutter](#20-divergences-connues)
21. [Angular — Catégories (KKS-231)](#21-angular--catégories-kks-231)
22. [KKS-235 — Page Mon compte](#22-kks-235--page-mon-compte-angular--flutter)

---

## Legende

| Symbole | Signification |
|---------|---------------|
| OK | Test passe |
| KO | Test echoue |
| N/A | Non applicable (mode local, etc.) |
| -- | Non teste |

---

## 1. Onboarding & Configuration

> **Concerne** : Premier lancement, choix mode local/serveur.
> **Exclusif Flutter** (pas d'equivalent Angular).

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| O-1 | Premier lancement | Installer et lancer l'app | Ecran Onboarding affiche (jamais dashboard) | -- |
| O-2 | Selection mode local | Tap "Mode local" | Card mise en evidence (bordure primary + check) | -- |
| O-3 | Confirmer mode local | Mode local selectionne → Confirmer | Redirect `/dashboard` direct | -- |
| O-4 | Selection mode serveur | Tap "Mode serveur" → Confirmer | Affichage ecran ServerSetup | -- |
| O-5 | URL vide | ServerSetup : champ vide → Verifier | Erreur "L'URL est requise" | -- |
| O-6 | URL invalide | ServerSetup : "abc123" → Verifier | Erreur "URL invalide" | -- |
| O-7 | URL valide accessible | ServerSetup : URL API correcte → Verifier | Banner vert "Connexion reussie" + bouton Confirmer actif | -- |
| O-8 | URL injoignable | ServerSetup : URL fausse → Verifier | Banner rouge avec message d'erreur | -- |
| O-9 | Confirmer serveur | Serveur accessible → Confirmer | Redirect `/login` | -- |
| O-10 | Persistence | Relancer l'app apres onboarding | Plus d'ecran Onboarding | -- |

---

## 2. Authentification

> **Concerne** : Login, reinitialisation a la premiere connexion, acceptation
> d'invitation, gestion des tokens JWT.
> **Mode serveur uniquement.**
>
> **L'inscription publique n'existe pas** (constitution, principe VII) :
> l'onboarding se fait uniquement par invitation d'un administrateur. Les cas
> A-7 a A-12 decrivaient un `RegisterScreen` retire depuis — ni ecran, ni route,
> ni endpoint `/auth/register`. Ils sont remplaces par les parcours reels.
>
> **Longueur de mot de passe** : 12 caracteres minimum a la creation et au
> changement (KKS-351), aucune au login.

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| A-1 | Login champs vides | Champs vides → Se connecter | Erreur "Veuillez saisir votre email" | -- |
| A-2 | Login email invalide | Email sans "@" → Se connecter | Erreur "Email invalide" | -- |
| A-3 | Login mdp vide | Email valide, mdp vide → Se connecter | Erreur "Veuillez saisir votre mot de passe" | -- |
| A-4 | Login credentials incorrects | Email/mdp incorrects | Message d'erreur rouge | -- |
| A-5 | Login succes | Credentials corrects | Redirect `/dashboard` | -- |
| A-6 | Toggle visibility mdp | Tap icone oeil | Toggle masquage/affichage | -- |
| A-7 | Login mdp court accepte | Compte dont le mdp fait moins de 12 caracteres | Connexion acceptee — le login n'impose aucune longueur (KKS-351) | -- |
| A-8 | Invitation : lien valide | Ouvrir `/invite/TOKEN` avec un token valide | Ecran d'acceptation, email pre-rempli et non modifiable | -- |
| A-9 | Invitation : mdp trop court | Saisir 11 caracteres | "12 caracteres minimum", soumission bloquee cote client | -- |
| A-10 | Invitation : mdp a la limite | Saisir exactement 12 caracteres | Accepte, compte cree, redirect `/dashboard` | -- |
| A-11 | Invitation : lien invalide | Ouvrir `/invite/TOKEN-INEXISTANT` | Message d'invitation invalide, pas de formulaire | -- |
| A-12 | Logout | Menu utilisateur → Logout | Retour `/login`, tokens invalides | -- |

### 2.1 — Reinitialisation a la premiere connexion (KKS-309)

> **Prerequis** : un compte provisionne par un administrateur, ou l'admin seed
> cree par `BootstrapSeedRunner` au premier demarrage d'une instance vierge.
> Ces comptes portent `mustResetCredentials=true`.
>
> **A tester sur les deux clients.** Avant KKS-309, Flutter n'avait pas cet
> ecran : l'utilisateur entrait dans le dashboard puis voyait chaque appel
> rejete en 403, sans aucune sortie.

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| FR-1 | Redirection a la connexion | Se connecter avec un compte a reinitialiser | Ecran de reinitialisation, pas le dashboard | -- |
| FR-2 | Contournement par navigation | Tenter d'atteindre `/dashboard` manuellement | Renvoye sur l'ecran de reinitialisation | -- |
| FR-3 | Mot de passe trop court | Saisir 11 caracteres | "12 caracteres minimum", soumission bloquee | -- |
| FR-4 | Confirmation differente | Confirmation ≠ mot de passe | "Les mots de passe ne correspondent pas" | -- |
| FR-5 | Reinitialisation reussie | Donnees valides → Valider | Nouveaux jetons stockes, acces au dashboard | -- |
| FR-6 | Reprise apres redemarrage | Fermer et rouvrir l'app avec des jetons encore valides, puis toucher un ecran metier | Le 403 est intercepte et l'ecran de reinitialisation s'affiche — le flag n'est ni dans le JWT ni persiste (Flutter) | -- |
| FR-7 | Mode local non concerne | Basculer en mode local (Drift) | L'ecran ne se declenche jamais : pas de serveur, donc pas de reinitialisation (Flutter) | -- |

---

## 3. Lock Screen

> **Exclusif Flutter.** PIN + biometrie.

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| L-1 | PIN correct | Saisir PIN correct → Deverrouiller | Redirect `/dashboard` | -- |
| L-2 | PIN incorrect | Saisir PIN faux | "PIN incorrect" + champ vide | -- |
| L-3 | PIN trop court | PIN < 4 chiffres → Deverrouiller | "Le PIN doit contenir au moins 4 chiffres" | -- |
| L-4 | PIN oublie (serveur) | "PIN oublie" → Confirmer | Logout + redirect `/login` | -- |
| L-5 | PIN oublie (local) | "PIN oublie" → Confirmer | Reset verrou + acces dashboard | -- |
| L-6 | Biometrie | Biometrie configuree, ouvrir app | Tentative biometrie automatique | -- |

---

## 4. Dashboard

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| D-1 | Aucun compte | Dashboard sans comptes | Ecran vide "Bienvenue ! Commencez par creer un compte" | -- |
| D-2 | 1 compte | Dashboard avec 1 compte | HeroCard visible, pas de liste secondaire | -- |
| D-3 | Plusieurs comptes | 3 comptes dont 1 par defaut | HeroCard = compte par defaut, 2 autres en liste | -- |
| D-4 | 5+ comptes | ≥5 comptes | Lien "Voir tout" → `/settings/accounts` | -- |
| D-5 | Pull-to-refresh | Tirer vers le bas | Indicateur chargement + donnees rechargees | -- |
| D-6 | Skeleton chargement | Premier chargement | Shimmer skeleton sur sections | -- |
| D-7 | Pas de transactions | Aucune transaction recente | Section vide ou masquee | -- |
| D-8 | 5+ transactions | Beaucoup de transactions | Seulement les 5 dernieres visibles | -- |
| D-9 | KPI mensuel | Mois avec transactions | Recettes (vert), Depenses (rouge), Solde affiche | -- |
| D-10 | Mini-cards abos | Abonnements actifs existants | Total mensuel affiche (annuels / 12) | -- |
| D-11 | Mini-cards dettes | Dettes en cours | Solde net "Je dois" / "On me doit" affiche | -- |
| D-12 | Nom utilisateur | Mode serveur, nom enregistre | "Bonjour [nom]" | -- |
| D-13 | Multi-devises | Comptes en EUR + USD | Totaux agreges par devise | -- |

---

## 5. Transactions

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| T-1 | Chargement initial | Ouvrir onglet Transactions | Skeleton 5 lignes, puis liste ou etat vide | -- |
| T-2 | Mois sans transactions | Naviguer vers un mois vide | "Aucune transaction ce mois" | -- |
| T-3 | Navigation mois | Tap fleche gauche/droite | Mois precedent/suivant charge | -- |
| T-4 | Filtre Depenses | Tap "Depenses" | Seulement les DEPENSE affichees | -- |
| T-5 | Filtre Recettes | Tap "Recettes" | Seulement les RECETTE affichees | -- |
| T-6 | Filtre sans resultats | "Depenses" sur mois sans depenses | "Aucune depense ce mois" | -- |
| T-7 | Tap transaction | Tap sur une transaction | Modal d'edition s'ouvre | -- |
| T-8 | Tap ajustement | Tap sur une transaction AJUSTEMENT | Rien (ignoree, non cliquable) | -- |
| T-9 | Pull-to-refresh | Tirer vers le bas | Rechargement donnees | -- |
| T-10 | Erreur reseau | Couper le reseau (mode serveur) | Icone erreur + bouton "Reessayer" | -- |
| T-11 | Groupement par jour | Transactions sur plusieurs jours | Groupees par date, total journalier affiche | -- |
| T-12 | KPI barre | Mois avec transactions | Recettes/Depenses/Solde corrects (par devise) | -- |

---

## 6. Formulaire Transaction

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| F-1 | Ouverture creation | FAB → Transaction | Modal en mode "Depense" par defaut | -- |
| F-2 | Toggle type | Tap "Recette" | Titre modal change, type change | -- |
| F-3 | Libelle vide | Submit sans libelle | Erreur "Champ requis" | -- |
| F-4 | Montant invalide | Montant = 0 ou negatif | "Le montant doit etre positif" | -- |
| F-5 | Date picker | Tap champ date | Date picker natif (locale fr) | -- |
| F-6 | Note longue | Note > 500 caracteres | Erreur sur le champ note | -- |
| F-7 | Submit valide | Tous champs corrects → Enregistrer | Modal ferme, transaction dans la liste | -- |
| F-8 | Pre-remplissage edit | Tap transaction existante | Champs pre-remplis | -- |
| F-9 | Suppression | Mode edit → icone poubelle | AlertDialog confirmation | -- |
| F-10 | Confirmer suppression | Confirmer dans le dialog | Transaction supprimee, modal ferme | -- |
| F-11 | Annuler suppression | Annuler dans le dialog | Modal reste ouvert | -- |
| F-12 | Aucun compte | Formulaire sans comptes actifs | Message info "Aucun compte disponible" | -- |
| F-13 | Compte par defaut | Ouvrir formulaire creation | Compte par defaut pre-selectionne | -- |
| F-14 | Categorie optionnelle | Submit sans categorie | Erreur sur le picker categorie (verifier) | -- |
| F-15 | Spinner soumission | Clic Enregistrer (API lente) | Boutons desactives + spinner | -- |

---

## 7. Virements

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| V-1 | 0-1 compte actif | Ouvrir FAB | "Virement" absent du menu | -- |
| V-2 | ≥2 comptes actifs | Ouvrir FAB | "Virement" visible | -- |
| V-3 | Ouverture formulaire | FAB → Virement | Modal avec 2 selecteurs de compte | -- |
| V-4 | Meme compte src/dest | Selectionner le meme compte | Erreur "Les comptes doivent etre differents" | -- |
| V-5 | Exclusion mutuelle | Selectionner compte source | Ce compte disparait de la liste destination | -- |
| V-6 | Montant vide | Submit sans montant | Erreur "Champ requis" | -- |
| V-7 | Submit valide | Donnees correctes → Enregistrer | Modal ferme, 2 transactions creees (debit+credit) | -- |
| V-8 | Soldes mis a jour | Apres virement | Soldes des 2 comptes mis a jour dans dashboard | -- |
| V-9 | Devises differentes | Compte EUR → Compte USD | Erreur API (verifier message affiche) | -- |

---

## 8. Abonnements

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| S-1 | Chargement initial | Ouvrir onglet Abonnements | Skeleton card resume + 5 skeleton items | -- |
| S-2 | Aucun abonnement | Liste vide | "Aucun abonnement" | -- |
| S-3 | Filtre Actifs vide | "Actifs" sans actifs | "Aucun abonnement actif" | -- |
| S-4 | Filtre Inactifs | Tap "Inactifs" | Seulement les inactifs | -- |
| S-5 | Card resume | Abonnements actifs existants | Total mensuel (annuels / 12) | -- |
| S-6 | Badge inactif | Abonnement inactif | Badge rouge "Inactif" visible | -- |
| S-7 | Date renouvellement | Abonnement actif | "Prochain le [date]" calcule correctement | -- |
| S-8 | Tap abonnement | Tap sur un item | Modal edition champs pre-remplis | -- |
| S-9 | Pull-to-refresh | Tirer vers le bas | Rechargement | -- |

---

## 9. Formulaire Abonnement

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| SA-1 | Ouverture creation | FAB → Abonnement | Modal en mode Mensuel par defaut | -- |
| SA-2 | Toggle frequence | Tap "Annuel" | Frequence change | -- |
| SA-3 | Nom vide | Submit sans nom | Erreur "Champ requis" | -- |
| SA-4 | Montant invalide | Montant ≤ 0 | Erreur montant | -- |
| SA-5 | Champs optionnels | Submit sans compte ni categorie | Succes (champs optionnels) | -- |
| SA-6 | Switch actif | Actif → Inactif → save | Badge "Inactif" dans la liste | -- |
| SA-7 | Compte inactif lie | Edition abo lie a un compte inactif | Compte inactif reste selectionne/visible | -- |
| SA-8 | Suppression | Mode edit → supprimer | Dialog confirmation + suppression | -- |

---

## 10. Dettes

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| DE-1 | Aucune dette | Liste vide | Pas de card resume, message vide | -- |
| DE-2 | Sections partitionnees | Emprunts + prets | 2 sections distinctes avec sous-totaux | -- |
| DE-3 | Filtre En cours | Tap "En cours" | Seulement non remboursees | -- |
| DE-4 | Filtre Rembourse | Tap "Rembourse" | Seulement remboursees | -- |
| DE-5 | Solde net positif | Prets > Emprunts | Couleur verte/positive | -- |
| DE-6 | Solde net negatif | Emprunts > Prets | Couleur rouge/negative | -- |
| DE-7 | Badge rembourse | Dette remboursee | Badge visible | -- |
| DE-8 | Tap dette | Tap sur un item | Modal edition | -- |
| DE-9 | Multi-devises | Dettes EUR + USD | Sous-totaux par devise | -- |
| DE-10 | Pull-to-refresh | Tirer vers le bas | Rechargement | -- |

---

## 11. Formulaire Dette

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| DF-1 | Ouverture creation | FAB → Dette | Modal en mode Emprunt par defaut | -- |
| DF-2 | Toggle sens | Tap "Pret" | Type change | -- |
| DF-3 | Personne vide | Submit sans personne | Erreur "Champ requis" | -- |
| DF-4 | Creation valide | Donnees correctes | Dette creee, pas de switch rembourse visible | -- |
| DF-5 | Switch rembourse | Editer une dette → switch rembourse | Switch visible uniquement en mode edition | -- |
| DF-6 | Marquer rembourse | Switch → save | Badge "Rembourse" dans la liste | -- |
| DF-7 | Suppression | Mode edit → supprimer | Dialog confirmation + suppression | -- |

---

## 12. FAB Menu

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| FAB-1 | Ouverture | Tap FAB (+) | Menu s'ouvre avec animation (rotation 45°) | -- |
| FAB-2 | Fermeture | Tap FAB a nouveau | Menu se ferme | -- |
| FAB-3 | Item Transaction | Tap "Transaction" | Menu ferme + modal transaction | -- |
| FAB-4 | Item Abonnement | Tap "Abonnement" | Menu ferme + modal abonnement | -- |
| FAB-5 | Item Dette | Tap "Dette" | Menu ferme + modal dette | -- |
| FAB-6 | Virement dashboard | Dashboard + ≥2 comptes → Tap "Virement" | Menu ferme + modal virement | -- |
| FAB-7 | Virement hors dashboard | Page /transactions + ≥2 comptes | "Virement" absent du menu | -- |
| FAB-8 | Virement cache | Dashboard + 0-1 compte actif | "Virement" absent du menu | -- |
| FAB-9 | FAB masque settings | Naviguer vers /settings | FAB invisible | -- |
| FAB-10 | FAB masque sous-settings | Naviguer vers /settings/features | FAB invisible | -- |

---

## 13. Settings — Hub

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| SH-1 | Affichage | Ouvrir Settings | 3 groupes (General, Gestion, Autre) | -- |
| SH-2 | Navigation Profil | Tap "Profil" | → `/settings/profile` | -- |
| SH-3 | Navigation Apparence | Tap "Apparence" | → `/settings/appearance` | -- |
| SH-4 | Navigation Comptes | Tap "Comptes" | → `/settings/accounts` | -- |
| SH-5 | Navigation Categories | Tap "Categories" | → `/settings/categories` | -- |
| SH-6 | Navigation Donnees | Tap "Donnees" | → `/settings/data` | -- |
| SH-7 | Placeholders | Tap "Securite" ou "A propos" | Aucune navigation (grises) | -- |

---

## 14. Settings — Comptes

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| AC-1 | Liste vide | Aucun compte | Etat vide "Aucun compte" | -- |
| AC-2 | Creation | Tap + → remplir → valider | Retour liste + compte ajoute | -- |
| AC-3 | Nom vide | Creation sans nom | Erreur "Champ requis" | -- |
| AC-4 | Solde negatif | Solde initial = -500 | Accepte | -- |
| AC-5 | Changement type | Creation → changer type Epargne | Emoji et couleur changent automatiquement | -- |
| AC-6 | Preview live | Changer emoji/couleur/nom | Preview card mise a jour en temps reel | -- |
| AC-7 | Definir par defaut | Menu ⋮ → "Definir par defaut" | Badge "Defaut" sur ce compte | -- |
| AC-8 | Switch actif (defaut) | Editer compte par defaut | Switch actif desactive + hint | -- |
| AC-9 | Suppression | Menu ⋮ → Supprimer | Dialog confirmation | -- |
| AC-10 | Ajustement solde | Edition → nouveau solde → save | Solde ajuste, transaction AJUSTEMENT creee | -- |
| AC-11 | Devise verrouillee | Edition → champ devise | SelectPicker disabled | -- |
| AC-12 | Compte inactif | Liste avec compte inactif | Opacite 0.5 + badge "Inactif" | -- |
| AC-13 | Pull-to-refresh | Tirer vers le bas | Rechargement | -- |
| AC-14 | Nom duplique | Creer avec un nom existant | Erreur "Nom deja utilise" | -- |

---

## 15. Settings — Categories

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| CA-1 | Liste vide | Aucune categorie user | Etat vide | -- |
| CA-2 | Systeme masquees | Categories isSystem=true | Non affichees dans la liste | -- |
| CA-3 | Creation sans emoji | Submit sans emoji | Erreur emoji obligatoire | -- |
| CA-4 | Creation sans nom | Submit sans nom | Erreur nom obligatoire | -- |
| CA-5 | Nom > 30 chars | Taper plus de 30 caracteres | Bloque par maxLength | -- |
| CA-6 | Nom duplique | Nom d'une categorie existante | Snackbar "Nom deja utilise" | -- |
| CA-7 | Preview live | Changer couleur/emoji | Preview card mise a jour | -- |
| CA-8 | Creation valide | Donnees correctes → valider | Retour liste + categorie ajoutee | -- |
| CA-9 | Suppression | Mode edit → supprimer | Dialog confirmation + suppression | -- |
| CA-10 | Couleur aleatoire | Ouvrir formulaire creation | Couleur pre-selectionnee aleatoirement | -- |

---

## 16. Settings — Profil

> **Mode serveur uniquement.**

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| SP-1 | Chargement | Ouvrir Profil | Skeleton → nom/email lecture seule + devise | -- |
| SP-2 | Changer devise | Tap devise → bottom sheet → choisir | Bouton ✓ apparait en header | -- |
| SP-3 | Sauvegarder devise | Tap ✓ | Snackbar "Devise mise a jour", ✓ disparait | -- |
| SP-4 | Meme devise | Selectionner devise actuelle | ✓ ne s'affiche pas | -- |
| SP-5 | Erreur API | Simuler erreur reseau | Etat erreur + bouton "Reessayer" | -- |
| SP-6 | Bottom sheet devises | Tap devise | Liste complete avec check sur l'actuelle | -- |

---

## 17. Settings — Apparence

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| AP-1 | Affichage | Ouvrir Apparence | Theme actuel : bordure + icone check | -- |
| AP-2 | Theme sombre | Tap "Sombre" | Theme sombre applique instantanement | -- |
| AP-3 | Theme clair | Tap "Clair" | Theme clair applique | -- |
| AP-4 | Persistence theme | Fermer + rouvrir app | Theme persiste | -- |
| AP-5 | Taille texte | Tap "Grand" | Preview mise a jour + taille changee | -- |
| AP-6 | Deja selectionne | Tap theme deja actif | Aucun changement | -- |

---

## 18. Settings — Donnees

> **Exclusif Flutter.**

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| DD-1 | Affichage | Ouvrir Donnees | Source actuelle selectionnee, URL pre-remplie | -- |
| DD-2 | URL vide | Enregistrer sans URL | Snackbar erreur validation | -- |
| DD-3 | URL invalide | URL incorrecte → Enregistrer | Snackbar erreur | -- |
| DD-4 | URL valide | URL correcte → Enregistrer | Snackbar "URL enregistree" | -- |
| DD-5 | Local → Serveur (KO) | Changer sans URL valide | Snackbar erreur, pas de changement | -- |
| DD-6 | Local → Serveur (OK) | URL valide → Confirmer | Dialog → accept → app restart | -- |
| DD-7 | Annuler changement | Changer mode → Annuler dialog | Mode inchange | -- |
| DD-8 | Serveur injoignable | URL fausse → Changer mode | Snackbar erreur, pas de restart | -- |

---

## 19. Cas Limites & Edge Cases

> Scenarios identifies par l'avocat du diable. **Priorite decroissante.**

### Critiques

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| ADV-1 | Virement cross-devises | Compte EUR → Compte USD → virement | **Flutter** : message d'erreur explicite (pas "Erreur generique") | -- |
| ADV-12 | Deep link edition compte | Naviguer directement `/settings/accounts/uuid` (sans passer par la liste) | L'app ne crash PAS (pas de null cast) | -- |
| ADV-5 | Suppression categorie utilisee | Creer categorie + attacher transaction → supprimer categorie | Erreur API geree proprement, pas de flash UI | -- |

### Majeurs

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| ADV-9 | Concurrence 2 devices | Device A et B editent le meme compte → les 2 sauvegardent | Derniere ecriture gagne, pas de crash | -- |
| ADV-10 | Local → Serveur sans sync | Creer donnees en local → basculer serveur | Donnees locales non perdues mais non visibles en serveur | -- |
| ADV-6 | Supprimer compte avec abos | Compte lie a 3 abonnements → supprimer | Erreur explicite (pas de suppression silencieuse) | -- |
| ADV-3 | Double-tap Enregistrer | Double-tap rapide sur bouton submit | Une seule transaction creee | -- |

### Moyens

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| ADV-2 | Token expire pendant submit | Attendre ~15 min sur formulaire → soumettre | Refresh token transparent, formulaire se complete | -- |
| ADV-4 | App background > 15 min | Mettre en arriere-plan 20min → revenir → action | Refresh token ou logout propre | -- |
| ADV-14 | Back Android pendant submit | Soumettre + appuyer back immediatement | Transaction creee malgre retour (pas de crash) | -- |
| ADV-13 | Virgule comme separateur | Taper "12,50" dans un champ montant | Message clair si rejete, ou accepte correctement | -- |
| ADV-15 | Emojis dans les champs | Libelle avec 200 emojis | API accepte ou erreur claire (pas de 500) | -- |
| ADV-8 | Pagination derniere page | 21 elements, scroller | `hasMore` correct, pas de chargement infini | -- |
| ADV-7 | Compte desactive entre-temps | Ouvrir formulaire virement → desactiver compte destination → soumettre | Erreur API geree proprement | -- |
| ADV-11 | Changements de filtres rapides | Cliquer rapidement Actifs/Inactifs/Tous (abonnements) | Derniere selection affichee correctement | -- |

---

## 20. Divergences connues Angular / Flutter

> A prendre en compte lors de la validation. Certaines sont intentionnelles.

| # | Sujet | Angular | Flutter | Impact |
|---|-------|---------|---------|--------|
| D1 | Taille texte | Non disponible | 3 options (Petit/Normal/Grand) | Flutter > Angular |
| D2 | Mode local/serveur | Serveur uniquement | Choix local (Drift) ou serveur (Dio) | Exclusif Flutter |
| D3 | Onboarding | Absent | Ecran choix local/serveur | Exclusif Flutter |
| D4 | Lock Screen | Absent | PIN + biometrie | Exclusif Flutter |
| D5 | Pagination | Tout charge d'un coup | Pagination client-side (20/page) | Comportement different |
| D6 | Filtres abos | Appel API par filtre | Filtrage client-side | Meme resultat, implementation differente |
| D7 | Erreurs virement | Message API affiche | Message generique "Erreur" | **A corriger dans Flutter** |
| D8 | Profil devise | Modifiable | Modifiable (verifier parite) | A verifier |
| D9 | Dashboard sections | Top 3 abos + top 3 dettes | MiniCards resume | Presentation differente |
| D10 | Theme Auto | Clair/Sombre/Auto | Clair/Sombre uniquement | Flutter n'a pas "Auto" |

---

---

## 21. Angular — Catégories (KKS-231)

> **Concerne** : Application Angular uniquement. Tests non-régression Settings + nouveaux parcours inline.
> **Prérequis** : `ng serve` lancé, API Spring Boot active (profil dev), au moins un compte existant.

### 21.1 — Settings — Gestion des catégories (non-régression US4)

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| CAT-1 | Créer une catégorie | Settings → Catégories → `+` → Renseigner nom, icône, couleur → Créer | Catégorie apparaît dans la liste Settings | -- |
| CAT-2 | Modifier une catégorie existante | Settings → Catégories → clic sur une catégorie → Modifier nom → Modifier | Nom mis à jour dans la liste | -- |
| CAT-3 | Supprimer une catégorie | Settings → Catégories → clic sur une catégorie → Supprimer → Confirmer | Catégorie disparaît de la liste | -- |
| CAT-4 | Footer modal Settings fonctionnel | Settings → Catégories → `+` → Renseigner un champ → clic `Annuler` | Modal fermée, catégorie non créée | -- |
| CAT-5 | Bouton Modifier dans le footer | Settings → Catégories → éditer une catégorie → footer affiche « Modifier » | Label correct selon mode create/edit | -- |

### 21.2 — Sélection inline dans les formulaires (US1)

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| CAT-6 | Sélection inline transaction | Nouveau bottom-sheet transaction → pill Catégorie → liste inline s'affiche (aucun overlay) | Aucun bottom-sheet supplémentaire | -- |
| CAT-7 | Sélection confirme la valeur | Expand catégorie ouvert → clic sur une catégorie | Expand se referme, pill affiche la catégorie sélectionnée | -- |
| CAT-8 | Sélection abonnement | Nouveau bottom-sheet abonnement → pill Catégorie → liste inline | Même comportement que CAT-6/CAT-7 | -- |
| CAT-9 | Sélection dette | Nouveau bottom-sheet dette → pill Catégorie → liste inline | Même comportement | -- |
| CAT-10 | Scroll liste (>10 catégories) | Avec >10 catégories créées → ouvrir expand → faire défiler | Liste scrolle jusqu'au max 60vh, footer du sheet reste accessible | -- |

### 21.3 — Recherche inline (US3)

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| CAT-11 | Recherche partielle | Expand catégorie → taper `ali` | Seul « Alimentation » affiché | -- |
| CAT-12 | Insensibilité casse | Expand catégorie → taper `TRANSPORT` | « Transport » affiché | -- |
| CAT-13 | Insensibilité accents | Expand catégorie → taper `cafe` | « Café » affiché (si existant) | -- |
| CAT-14 | Aucun résultat | Taper un terme inexistant | Message « Aucune catégorie trouvée » + bouton « + Créer » | -- |
| CAT-15 | Navigation clavier ArrowDown | Input search focusé → ArrowDown | Premier item highlighté | -- |
| CAT-16 | Navigation clavier Enter | Item highlighté → Enter | Item sélectionné, expand fermé | -- |
| CAT-17 | Escape en mode liste | Recherche active → Escape | Recherche vidée, liste complète | -- |

### 21.4 — Création inline (US2)

| # | Scenario | Etapes | Resultat attendu | Statut |
|---|----------|--------|-------------------|--------|
| CAT-18 | Bouton + Créer | Taper un terme sans correspondance exacte → bouton « + Créer "terme" » | Bouton visible | -- |
| CAT-19 | Passage en mode création | Clic sur « + Créer "terme" » | Mode création s'affiche avec nom pré-rempli | -- |
| CAT-20 | Création réussie auto-sélection | Remplir le form création → ✓ Créer | Catégorie créée + auto-sélectionnée + expand fermé | -- |
| CAT-21 | Retour vers liste | Mode création → ← Retour | Retour vers liste, terme de recherche préservé | -- |
| CAT-22 | Escape en mode création | Mode création → Escape | Retour vers liste (pas fermeture du sheet) | -- |
| CAT-23 | Footer désactivé pendant création | Mode création actif | Boutons Annuler/Enregistrer du sheet grisés | -- |
| CAT-24 | Catégorie créée visible dans Settings | Créer une catégorie depuis le bottom-sheet → aller dans Settings | Nouvelle catégorie visible dans la liste Settings | -- |

---

## 22. KKS-235 — Page Mon compte (Angular + Flutter)

> **Concerne** : Page `Settings > Mon compte` + bouton de deconnexion fixe.
> **Mode serveur uniquement** (les endpoints `/api/v1/users/me/*` ne sont pas dispo en mode local Drift).
> **Prerequis** : compte de test, mot de passe connu, au moins 1 admin secondaire en DB pour le test "dernier admin".

### 22.1 — US-001 : Navigation et deconnexion

| # | Scenario | Pre-conditions | Etapes | Resultat attendu | Statut |
|---|----------|----------------|--------|-------------------|--------|
| MC-1 | Acces depuis Settings | User connecte | Settings → tap "Mon compte" | Navigation vers `/settings/account` | -- |
| MC-2 | Bouton deconnexion fixe | Page Mon compte ouverte | Scroller jusqu'en bas | Bouton "Se deconnecter" visible et accessible (pinned bas d'ecran ou en pied) | -- |
| MC-3 | Deconnexion nominale | User connecte sur Mon compte | Tap "Se deconnecter" → confirmer si dialog | Redirect vers `/login`, refresh tokens revoques cote serveur (verifier impossible de refresh) | -- |

### 22.2 — US-002 : Identite (nom, avatar, email)

| # | Scenario | Pre-conditions | Etapes | Resultat attendu | Statut |
|---|----------|----------------|--------|-------------------|--------|
| MC-4 | Email read-only | Page Mon compte | Inspecter le champ Email | Champ desactive, non editable, valeur correcte | -- |
| MC-5 | Modifier le nom | Page Mon compte | Editer "Nom" → "Kelly K." → Enregistrer | Snackbar succes, GET /api/v1/users/me retourne le nouveau nom | -- |
| MC-6 | Nom vide | Page Mon compte | Vider le nom → Enregistrer | Erreur de validation client (champ requis) | -- |
| MC-7 | Nom > 100 chars | Page Mon compte | Coller 101 caracteres dans nom | Bloque (maxLength) ou erreur 400 explicite | -- |
| MC-8 | Upload avatar JPG | Page Mon compte | Tap zone avatar → choisir fichier .jpg < 2 Mo | Avatar affiche immediatement, ETag retourne | -- |
| MC-9 | Upload avatar PNG | Page Mon compte | Choisir fichier .png < 2 Mo | Avatar affiche, content-type `image/png` | -- |
| MC-10 | Upload format invalide | Page Mon compte | Choisir fichier .gif ou .pdf | Erreur "Format d'image non supporte" (`INVALID_IMAGE_FORMAT` 400) | -- |
| MC-11 | Upload > 2 Mo | Page Mon compte | Choisir fichier image > 2 Mo | Erreur "L'image depasse 2 Mo" (`FILE_TOO_LARGE` 413) | -- |
| MC-12 | Cache avatar (304) | Avatar configure | Recharger la page deux fois (DevTools) | Deuxieme requete `GET /api/v1/users/me/avatar` retourne `304 Not Modified` (header `If-None-Match`) | -- |
| MC-13 | Supprimer avatar | Avatar configure | Tap "Supprimer l'avatar" → confirmer | Avatar disparait, GET retourne `404 AVATAR_NOT_FOUND` | -- |
| MC-14 | Supprimer sans avatar | Aucun avatar | Tenter suppression | Erreur `AVATAR_NOT_FOUND` 404 (ou bouton desactive cote UI) | -- |

### 22.3 — US-003 : Changer le mot de passe

| # | Scenario | Pre-conditions | Etapes | Resultat attendu | Statut |
|---|----------|----------------|--------|-------------------|--------|
| MC-15 | Changement nominal | Page Mon compte | Saisir current valide + new (≥ 12 chars) different → Enregistrer | Succes, nouveaux tokens emis (refresh tokens precedents revoques), user reste connecte | -- |
| MC-16 | Mot de passe actuel incorrect | Page Mon compte | Saisir current faux + new valide | Erreur `PASSWORD_INCORRECT` 401, message "Mot de passe actuel incorrect" | -- |
| MC-17 | Nouveau MDP < 12 chars | Page Mon compte | Saisir current valide + new = "abc123" | Erreur de validation 400 (Bean Validation `@Size(min=12)`) | -- |
| MC-18 | Nouveau MDP identique | Page Mon compte | Saisir current valide + new = current | Erreur `PASSWORD_UNCHANGED` 400 | -- |
| MC-19 | Tokens precedents invalides | Apres MC-15 | Tenter un refresh avec l'ancien refreshToken | Erreur `TOKEN_REVOKED` (401) | -- |

### 22.4 — US-004 : Export des donnees

| # | Scenario | Pre-conditions | Etapes | Resultat attendu | Statut |
|---|----------|----------------|--------|-------------------|--------|
| MC-20 | Export JSON | Compte avec donnees | Tap "Exporter (JSON)" | Telechargement `k-budget-export-YYYY-MM-DD.json`, `Content-Type: application/json; charset=utf-8` | -- |
| MC-21 | Contenu JSON | Apres MC-20 | Ouvrir le fichier JSON | Backup complet : user, preferences, accounts, categories, transactions, subscriptions, debts, budgets, exchangeRates | -- |
| MC-22 | Export CSV | Compte avec transactions | Tap "Exporter (CSV)" | Telechargement `k-budget-transactions-YYYY-MM-DD.csv` | -- |
| MC-23 | BOM UTF-8 dans le CSV | Apres MC-22 | Inspecter les 3 premiers octets du fichier (hexdump) | `EF BB BF` au debut du fichier, ouverture correcte des accents dans Excel | -- |
| MC-24 | Format invalide | URL directe | Appeler `GET /api/v1/users/me/export?format=xml` | Erreur `INVALID_EXPORT_FORMAT` 400 | -- |
| MC-25 | Format manquant | URL directe | Appeler `GET /api/v1/users/me/export` | Erreur `INVALID_EXPORT_FORMAT` 400 | -- |

### 22.5 — US-005 : Suppression du compte

| # | Scenario | Pre-conditions | Etapes | Resultat attendu | Statut |
|---|----------|----------------|--------|-------------------|--------|
| MC-26 | Suppression nominale | User non-admin OU admin avec ≥ 2 admins actifs | Tap "Supprimer mon compte" → saisir `password` + `SUPPRIMER` → confirmer | 204, redirect `/login`, tokens revoques, `users.disabled_at` rempli, budgets/snapshots/refresh_tokens supprimes en cascade | -- |
| MC-27 | Confirmation incorrecte | Page Mon compte | Saisir `password` + `supprimer` (lowercase) | Erreur `CONFIRMATION_REQUIRED` 400 | -- |
| MC-28 | Confirmation vide | Page Mon compte | Saisir `password` + chaine vide | Erreur de validation 400 (Bean `@NotBlank`) | -- |
| MC-29 | MDP incorrect | Page Mon compte | Saisir mauvais password + `SUPPRIMER` | Erreur `PASSWORD_INCORRECT` 401 | -- |
| MC-30 | Dernier admin bloque | User est seul admin actif (desactiver les autres en DB ou ADMIN_EMAILS reduit) | Tenter la suppression avec password + `SUPPRIMER` valides | Erreur `LAST_ADMIN_DELETION_FORBIDDEN` 403, compte non supprime | -- |
| MC-31 | Reconnexion impossible | Apres MC-26 | Tenter `POST /api/v1/auth/login` avec les credentials du compte supprime | Echec auth (compte `disabled_at` non null) | -- |

---

## Notes d'execution

1. **Ordre suggere** : Executer les sections 1 → 18 dans l'ordre, puis les edge cases (section 19), puis les sections feature-specifiques (21, 22)
2. **Modes a tester** : Chaque section (sauf exclusives) doit etre testee en **mode local** ET **mode serveur**
3. **Devices** : Tester sur iOS + Android si possible (comportements natifs differents : back button, date picker, clavier)
4. **Orientation** : Verifier au moins 1 ecran en mode paysage
5. **Theme** : Tester au moins le dashboard + 1 formulaire en mode sombre
6. **Multi-devises** : Creer au moins 1 compte en EUR et 1 en USD pour les tests de formatage
7. **KKS-235** : Section 22 a executer en mode serveur uniquement, prevoir un compte admin secondaire pour pouvoir tester MC-26 et MC-30 distinctement
