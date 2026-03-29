# Refonte Design — Quiet Utility Dark-First

## Objectif

Transformer l'interface de K-Budget d'un style "dashboard corporate" vers un style **quiet utility dark-first**, inspire par TickTick, Stoic et Apple Journal. L'app doit etre calme, sobre, et laisser les donnees parler d'elles-memes.

## Direction validee

- **Dark-first** : tous les appareils de Kelly sont en dark mode. C'est l'experience primaire.
- **Quiet utility** : pas d'effets decoratifs. Pas de gradients. Pas de glass. L'interface s'efface derriere le contenu.
- **Couleur = information** : vert = revenu, rouge = depense, amber = action/CTA. Jamais de couleur decorative.
- **Typographie + spacing font tout le travail** : la hierarchie visuelle vient des tailles, graisses et espacements, pas des bordures ni des ombres.
- **Elevation par luminosite** : en dark mode, les surfaces plus claires sont plus "elevees". 3 niveaux : fond noir (#0a0a0a) > surface default (#141414) > surface raised (#1e1e1e).

## Processus

**Validation visuelle iterative**, pas de formalisation prealable. On change, on regarde, on reagit, on ajuste. Le DESIGN.md sera reecrit APRES que le resultat soit valide visuellement.

## Ce qui a ete fait (session 1)

### Primitives
- Palette gray remplacee : Tailwind (bleu-teinte) -> gris neutres purs (#0a0a0a a #fafafa)
- Plus aucun sous-ton bleu dans les fonds

### Theme dark — tokens
- Hero gradient : supprime (surface plate)
- Glassmorphism : supprime (glass-bg, glass-border, glass-blur -> surfaces solides)
- Radial gradient fond de page : supprime sur toutes les pages (dashboard, transactions, abonnements, dettes)
- Ombre coloree FAB : neutralisee (noir au lieu d'amber)
- Shadow hero text : supprime
- Couleurs metier attenuees : vert #4ade80 -> #6dc990, rouge #f87171 -> #d97777 (moins saturees)
- Couleurs feedback attenuees dans la meme logique
- Primary amber adouci : #fbbf24 -> #e0a820
- Sidebar active : rgba(255,255,255,0.08) au lieu d'amber-900

### Dashboard — structure
- **Hero section** : greeting + patrimoine + revenus/depenses fusionnes en une seule section (etaient 2 sections separees)
- Greeting passe de titre dominant a texte secondaire discret (sm, text-secondary)
- Revenus/Depenses : plus de cards separees avec dots/variation bars. Maintenant inline dans un conteneur arrondi avec divider
- Variation badges : plus de fond colore (etaient des barres full-width). Maintenant texte simple
- Gap entre hero et sections detail : space-8 (32px) au lieu de space-5 (20px) — le hero respire

### Dashboard — composants
- **Budget items** : plus de cards individuelles. Un seul conteneur arrondi (surface-default), items separes par border-bottom. Emojis sans cercle colore.
- **Operations** : meme traitement — un conteneur arrondi, items plats avec separateurs
- **Progress bars budgets** : 4px au lieu de 10px, opacity 0.7

### Typographie — hierarchie
- Hero amount : 3xl (30px) bold — LE chiffre dominant
- Section titles : base (16px) semibold, text-secondary — fonctionnels, pas imposants
- Summary values : sm (14px) semibold — secondaires
- List titles : sm (14px) medium
- List amounts : sm (14px) semibold
- Labels : xs (12px) medium
- Tertiary (dates, converted) : xs (12px) normal, text-tertiary

### Shell — header et bottom nav
- Header : 56px -> 64px, logo 28px -> 34px, nom xl, padding space-5, surface-raised
- Bottom nav : 64px -> 72px, icones 1.625rem, surface-raised
- Les deux utilisent border (pas shadow) et surface-raised pour se detacher du fond

### List item (composant partage)
- Cercles emoji : plus de fond color-primary-light. Maintenant rgba(255,255,255,0.06), taille reduite
- Titres : sm au lieu de base
- Sous-titres : xs, text-tertiary

## Ce qui a ete fait (session 2)

### Dashboard — polish
- Icones budgets : uniformisees en cercles (comme operations)
- Bordures entre budget items : supprimees (progress bar suffit)
- Montants budgets : reduits en xs + text-tertiary
- Bottom nav active : juste couleur amber, plus de pill M3

### Header dynamique (shell)
- Dashboard : logo K-Budget + cloche + avatar (inchange)
- Autres pages : avatar + titre page + icones contextuelles a droite
- Icones changent selon la route (recherche/filtre/recurrences sur Transactions)

### Page Transactions — redesign complet
- Hero centre : solde dominant (3xl bold), revenus/depenses inline, toggle devise
- Transactions groupees par periode (Aujourd'hui, Hier, Cette semaine, etc.)
- Conteneurs arrondis par groupe avec dividers (coherent dashboard)
- Labels date discrets, rows plates (icone cercle + titre + categorie + montant)
- Conversion devise secondaire affichee sous le montant
- Supprime : 3 summary cards, tabs filtre, bouton recurrences emoji

## Ce qui a ete fait (session 3)

### Header uniforme (shell)
- Header identique sur toutes les pages : logo + "K-Budget" + cloche + avatar
- Plus de header dynamique (avatar a gauche + titre + actions contextuelles)
- Padding header aligne sur le contenu (space-4)
- Supprime : shell-header__left, shell-page-title, pageActions pour transactions

### Page Transactions — hero + section header
- Hero aligne a gauche (plus centre)
- Selecteur mois : "Mars 2026 (◀)(▶)" label a gauche, fleches apres, toggle devise a droite
- Fleches avec border-radius round + border (coherent avec toggle devise)
- Labels "SOLDE", "Recettes", "Depenses" avec style dashboard (uppercase, letter-spacing, text-secondary)
- Conteneur arrondi surface-default autour Recettes/Depenses (comme dashboard)
- Conversion devise secondaire (CFA) sous recettes et depenses via computed signals
- ExchangeRateService.loadRates() ajoute pour charger les taux

### Section header "Transactions" (sticky)
- Titre "Transactions" + icones recherche/filtre/recurrences
- Separateur visuel (pipe) avant l'icone recurrences (navigation)
- Sticky sous le header app (top: header-height)
- Fond dynamique : surface-background normal → surface-raised + pleine largeur quand colle
- Detection via IntersectionObserver sur un sentinel element

### Hierarchie visuelle (global)
- Montants rows : xs (12px) + medium (etait sm + semibold)
- Titres rows : text-secondary (etait text-primary)
- Depenses : text-secondary neutre (plus de rouge) — seules les recettes gardent le vert
- Couleurs de categorie en fond d'icone (hex + 26 = 15% opacite)

## Ce qui a ete fait (session 4)

### Page Transactions recurrentes — refonte complete
- Supprime : header custom (double header), cards individuelles par item, boutons d'action inline (Valider/Passer/Desactiver), badges de statut, emoji brut comme icone
- Alignement sur le vocabulaire visuel du reste : conteneur groupe avec dividers, icones cercle colorees, rows plates
- Titre "Recurrences" aligne a droite, separe de la fleche retour, visible (lg/bold/primary)
- Groupement par statut : En retard (label rouge), Aujourd'hui (label amber), A venir (label neutre)
- Dates relatives : "aujourd'hui", "dans 4 j.", "dans 18 j." (seuil 30j, au-dela date absolue)
- Montants : amount-expense (text-secondary) pour depenses, amount-income (vert) pour recettes uniquement
- Bottom sheet actions au tap sur un item (progressive disclosure) : Marquer comme payee, Passer, Desactiver
- Bouton "Tout paye" sur le groupe En retard (action groupee)

### Resume mensuel (2 lignes)
- Ligne 1 : "BILAN MENSUEL" + net (recettes - charges) en vert/rouge selon signe
- Ligne 2 : "X CHARGES" + total mensuel depenses uniquement
- Distinction conceptuelle : recurrences = obligations (loyer, electricite), abonnements = optionnels (Netflix)
- Le bilan repond a "mes revenus recurrents couvrent-ils mes charges fixes ?"

### Conversion multi-devise
- Montants en devise etrangere affichent la conversion en italique (~ XX €)
- Bilan mensuel convertit tous les montants en devise primaire avant calcul
- Chargement des taux de change (ExchangeRateService.loadRates) a l'ouverture de la page
- Normalisation frequence : hebdo x4.33, annuel /12 pour calcul mensuel

## Ce qui a ete fait (session 5)

### Page Abonnements — refonte complete
- Supprime : summary cards (box-shadow, style ancien), segmented control filtre (Tous/Actifs/Inactifs), badge "Inactif" rouge positionne en absolu, composant ListItem (remplace par rows custom)
- Hero : total mensuel dominant (3xl bold, color-expense) + "≈ XX CFA" conversion + "1 395 €/an · 8 abonnements" en sous-ligne expense color
- Section header sticky : "Abonnements" + "8 actifs" (meme pattern que Transactions)
- Groupement par periode de renouvellement : Cette semaine, Mois prochain, Plus tard, Inactifs (meme vocabulaire que Transactions/Recurrences)
- Dates relatives dans le subtitle : "dans 4 j.", "dans 12 j.", "20 sept." (seuil 30j)
- Rows custom : icone cercle avec couleur categorie (15% opacite), titre text-secondary, subtitle text-tertiary, montant amount-expense
- Conversion multi-devise : chargement ExchangeRateService.loadRates(), affichage "~ 22,86 €" en italique sous les montants XOF
- Inactifs : opacity 50%, groupes en bas sous label "Inactifs"
- Signal financier : hero en color-expense (rouge attenue) pour communiquer "ca coute de l'argent" — les rows restent neutres (text-secondary)

### Decisions de design (session 5)
- Pas de summary row redondante (le hero dit deja le total mensuel, pas besoin de le repeter)
- Le cout annuel est derive mais utile — affiche en sous-ligne, pas dans une carte separee
- Les compteurs (nombre d'abonnements) sont secondaires par rapport aux montants
- Sur une page 100% depenses, le hero DOIT porter la couleur expense sinon la page parait neutre/sans consequence
- Filtre Tous/Actifs/Inactifs supprime : le groupement par periode + section Inactifs en bas suffit

## Ce qui a ete fait (session 6)

### Page detail abonnement — refonte complete
- Supprime : header avec bouton edit inline (back + titre + edit cote a cote), info card separee (Montant/Frequence/Date/Categorie/Compte en rows), total card isolee, bouton "Payer" full-width
- Header aligne sur le pattern recurrences : fleche retour ronde transparente + titre aligne a droite (sans emoji categorie)
- Hero condense : premiere ligne MENSUEL + badge Actif + categorie + date de debut, montant dominant 3xl, conversion devise secondaire, equivalent annuel/mensuel, total paye + nombre de paiements, logo banque + nom du compte
- Plus de card info separee : toutes les metadonnees vivent dans le hero
- Actions en pills compactes : 🗑️ (icone seule, danger) a gauche | spacer | Desactiver · Modifier · Payer (primaire) a droite
- Bouton Payer desactive sur les abonnements inactifs
- Ajout actions manquantes : Desactiver/Activer (toggle via update API), Supprimer (avec confirm)
- Historique paiements : emoji/logo banque devant chaque item, montants en xs/medium/text-secondary (neutres, pas de vert)

### AccountSummary — enrichissement backend
- Ajout `bankLogoUrl` resolu via BankRegistry (logos SVG des banques connues)
- Ajout `bankCustomLogo` (logos uploades manuellement)
- ProductService corrige : utilise `AccountSummary.from()` au lieu du constructeur direct
- Frontend AccountSummary aligne avec les 2 nouveaux champs
- Helper `getAccountLogo()` : priorite bankCustomLogo > bankLogoUrl > fallback emoji

### Fix pre-existant : SubscriptionService.getTotalPaid
- Le type Angular disait `{ total, count }` mais l'API retourne `{ totalPaid, paymentCount }`
- Corrige dans le service, le composant et le template

### Hierarchie typographique alignee DESIGN.md
- Captions (categorie hero, date hero) : xs/normal/tertiary (etait medium)
- Total paye hero : sm/semibold/text-secondary (etait xs/medium/success)
- Compte hero : sm/normal/secondary
- Payment account : sm/medium/text-secondary (etait text-primary)
- Payment date : xs/tertiary (etait secondary)
- Payment amount : xs/medium/text-secondary (etait base/semibold/success)
- Suppression du vert sur tous les montants de la page (hero total + historique) — couleur = information, pas decoration

### Fix ng-icon width 0px
- ng-icon dans un conteneur flex sans texte collapse a width:0 malgre le CSS variable --ng-icon__size
- Fix via `::ng-deep ng-icon { min-width: Xpx }` dans les boutons concernes
- Bug pre-existant egalement present sur la page dettes (meme pattern btn-icon)

## Ce qui a ete fait (session 7)

### Page Dettes — refonte complete
- Supprime : 3 summary cards (Emprunts/Prets/Solde net) avec dots colores et box-shadow, segmented control filtre (Tous/En cours/Rembourse), border-left coloree 3px sur les sections, composant app-list-item partage, sections separees "Prets" / "Emprunts" avec totaux colores
- Hero : solde net dominant (3xl bold), couleur dynamique selon signe (income si positif, expense si negatif), conversion devise secondaire, sous-ligne "X prets · Y emprunts · Z en cours" + toggle devise
- Section header sticky : "Dettes" + "X en cours" (meme pattern abonnements/transactions)
- Groupement par echeance (dueDate) : En retard (label rouge), Aujourd'hui (label amber), Cette semaine, Ce mois-ci, Plus tard, Sans echeance, Remboursees
- Rows custom : icone cercle avec couleur categorie (15% opacite), personne (titre text-secondary), subtitle (categorie · type · date relative), montant restant (vert pour prets, neutre pour emprunts)
- Remboursees : opacity 50%, groupees en bas sous label "Remboursees"
- Conversion multi-devise : chargement ExchangeRateService.loadRates(), affichage italique sous les montants en devise etrangere
- Plus de liste separee prets/emprunts : tout dans une liste unique groupee par echeance temporelle — le sens est communique par la couleur du montant

### Decisions de design (session 7)
- Le hero montre le solde net = "est-ce qu'on me doit plus que je dois ?" — reponse immediate sans calcul mental
- Le montantRestant est affiche (pas montant initial) — c'est ce qui reste a recuperer/rembourser, plus actionnable
- Pas de segmented control : le groupement temporel + section Remboursees en bas suffit (meme decision que pour les abonnements)
- Le type (pret/emprunt) est secondaire — le nom de la personne est le titre, le type vit dans le subtitle en texte plat (pas de badge pill)
- Le solde net hero change de couleur : positif = vert (on me doit plus), negatif = rouge (je dois plus) — signal financier immediat
- Dates relatives a droite (sous le montant) : "14 j. en retard" en rouge, "dans 4 j." en tertiary — separation claire du subtitle a gauche
- Badges pills testes puis retires des rows de liste : ils cassaient le rythme visuel par rapport aux autres pages (abonnements/transactions qui utilisent du texte plat). Badge conserve uniquement sur la page detail.
- dueDate ajoutee au DebtRequest backend (champ manquant) pour supporter le groupement par echeance

### Page detail dette — refonte complete
- Supprime : header avec back + titre + edit cote a cote, 2 amount cards (initial + restant) en grille, section progress bar isolee, section info-rows (date/devise/echeance/categorie/compte/rappel en lignes), boutons Rembourser/Reporter full-width
- Header aligne sur le pattern abonnement : fleche retour + nom personne aligne a droite
- Hero condense : badge type neutre (bordure, pas de couleur) + badge Rembourse + categorie + date, montant restant dominant 3xl (vert=pret, neutre=emprunt), conversion devise, "Initial X € · Y € rembourse · Z paiements", echeance avec icone calendrier (rouge si en retard), rappel avec icone cloche, logo banque + compte
- Progress bar deplacee du hero vers la section paiements — le hero etait surcharge, la progress bar a plus de sens en contexte avec l'historique
- Actions pills compactes : corbeille (danger) a gauche | spacer | Reporter · Modifier · Rembourser (primary amber) a droite
- Ajout action Supprimer (avec confirm) — manquait sur l'ancienne page
- Historique paiements : logo banque devant chaque item, montants en xs/medium/text-secondary (neutres)
- Ordre hero : tags → montant → secondary → echeance → rappel → compte (echeance et rappel avant le compte)

## Ce qui a ete fait (session 8)

### Page Budgets — liste — refonte complete
- Supprime : row "Non budgete" intercalee dans la liste (📦 Autre), hero affichant le total global (budgete + non budgete)
- Hero : montant "Depense" = total budgete uniquement (3xl bold, color-expense), conversion devise secondaire
- Hero meta-lines avec icones Phosphor 14px : ⚠ X en depassement · 🥧 Y budgets (ligne 1), 📥 Z € non budgete (ligne 2, cliquable → page dediee)
- Doughnut chart SVG pur dans le hero : a droite du bloc texte (layout flex row), segments = depenses par categorie, couleurs categories, opacite 0.7, ~130px, stroke 22px, bords francs (butt)
- Section header : ajout pipe separator + icone Phosphor `phosphorTray` pour naviguer vers la page Non budgete (pattern identique aux recurrences sur Transactions)
- Budget items inactifs rendus cliquables → navigation vers la page detail (bouton Activer disponible)
- Fix : double attribut `class` sur budget-row
- Templates et styles extraits en fichiers separes (etaient inline)

### Page Non budgete — nouveau composant dedie
- Route `/budgets/unbudgeted` avec composant `BudgetUnbudgeted` (etait un mode dans budget-detail, reverte car couplage inapproprie)
- Header pattern recurrences : fleche retour + "Non budgete" aligne a droite
- Hero : total depense (3xl bold, color-expense), conversion devise secondaire, meta-line "X categories sans budget"
- Doughnut chart SVG dans le hero (meme composant que la liste) : visualise le poids relatif de chaque categorie non budgetee
- Section header sticky "Par categorie" + compteur transactions
- Groupement par categorie (triees par montant decroissant) : icone emoji + couleur, nom, montant, bouton + pour creer un budget
- Transactions listees sous chaque categorie avec conversion multi-devise

### Page Budget detail — refonte complete
- Templates et styles extraits en fichiers separes (etaient inline)
- Header pattern recurrences/abonnements : fleche retour + icone categorie + nom aligne a droite
- Hero condense : label "DEPENSE" uppercase, montant 3xl, conversion devise, meta-line avec icones (🎯 budget · 🥧/⚠ reste/depassement)
- Actions pills compactes : corbeille (danger) a gauche | spacer | Desactiver/Activer · Modifier
- Section header sticky "Transactions" + compteur
- Progress bar entre section header et transactions (warning amber >=80%, exceeded rouge >100%)
- Transactions groupees par date (Aujourd'hui, Hier, date absolue) avec conversion devise
- Support des budgets inactifs : chargement via getAll(true) quand non trouve dans l'overview
- Ajout `TransactionService.getByMonth()` pour charger les transactions du mois

### Composant DoughnutMini — nouveau composant partage
- SVG pur (pas de librairie chart.js), composant Angular standalone
- Inputs : segments (value + color), size (defaut 130), strokeWidth (defaut 22), gap (defaut 3)
- Arcs calcules via stroke-dasharray/dashoffset sur des cercles SVG
- Opacite 0.7 pour s'aligner avec les couleurs attenuees du dark mode
- Bords francs (stroke-linecap: butt), gaps entre segments
- Utilise sur la page budget liste et la page Non budgete

### Hero meta-lines — pattern propage globalement
- Remplacement de `hero__secondary` (texte plat) par `hero__meta` (lignes avec icones Phosphor 14px, text-tertiary)
- Pages modifiees : budget liste, budget detail, budget unbudgeted, dettes liste, abonnements liste
- Icones par page :
  - Budgets : phosphorWarning (depassement), phosphorChartPie (budgets), phosphorTray (non budgete)
  - Budget detail : phosphorTarget (objectif), phosphorChartPie/phosphorWarning (reste/depassement)
  - Dettes : phosphorHandCoins (prets), phosphorHandshake (emprunts), phosphorClock (en cours)
  - Abonnements : phosphorCalendar (cout annuel), phosphorRepeat (nombre)
  - Non budgete : phosphorSquaresFour (categories)
- Variante `--clickable` avec hover pour les lignes interactives

### Decisions de design (session 8)
- Le hero budget liste montre le total budgete uniquement, pas le total global — la sous-ligne "dont X € non budgete" fait le pont
- "Non budgete" n'est pas un sous-cas du budget detail, c'est une page a part entiere avec sa propre logique (groupement par categorie, CTA creation)
- Le doughnut chart est de l'information visuelle, pas de la decoration — il repond a "quelle proportion ?" que la liste seule ne montre pas
- Le doughnut dans la page Non budgete sert a la priorisation : visualiser quelle categorie budgeter en premier
- Le pattern navigation (pipe + icone Phosphor dans le section header) est repris des Transactions/Recurrences
- Les icones Phosphor 14px dans les meta-lines sont des reperes visuels discrets, pas du bruit — elles facilitent le scan

## Ce qui reste a faire

### Priorite haute
- [x] Propager le style aux pages Abonnements (session 5)
- [x] Page detail abonnement (session 6)
- [x] Page Dettes — liste (session 7)
- [x] Page detail dette (session 7)
- [x] Propager le style a la page Budgets (session 8)
- [ ] Page Settings
- [x] Page Transactions recurrentes (session 4)
- [ ] Modales et formulaires (bottom sheets) — progressive disclosure (debut : bottom sheet actions recurrences)

### Priorite moyenne
- [ ] Micro-interactions (transitions de page, feedback tactile)
- [ ] Empty states (illustrations ou messages soignes)
- [ ] Skeleton loading au lieu de spinners

### A faire en dernier
- [ ] Reecrire DESIGN.md a partir du resultat valide
- [ ] Aligner les tokens Flutter (DESIGN.md Flutter) avec les nouvelles valeurs
- [ ] Appliquer la meme direction a Kassist

## References visuelles

- **TickTick** : clean, utilitaire, listes propres, accent discret
- **Stoic** : calme, minimal, couleurs douces
- **Apple Journal** : natif iOS, invisible, contenu-first

## Anti-patterns identifies

Ce qu'on a retire et qu'il ne faut PAS reintroduire :
- Gradients decoratifs (hero card amber->indigo)
- Glassmorphism / backdrop-filter blur
- Ombres colorees (FAB amber glow)
- Radial gradients en fond de page
- Couleurs saturees Tailwind 400 en dark mode
- Cards individuelles par item de liste (preferer un conteneur groupe)
- Variation badges avec fond colore full-width
- Badge pills repetes dans les rows de liste (preferer texte plat tertiary — badges reserves aux pages detail)
