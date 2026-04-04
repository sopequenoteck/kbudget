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

## Ce qui a ete fait (session 9)

### Page Boutique — liste — refonte complete
- Supprime : segmented control filtre (Actifs/Inactifs/Tous), composant app-list-item partage, box-shadow sur le conteneur liste
- Hero : CA total dominant (3xl bold, color-income vert), meta-lines avec icones Phosphor 14px (phosphorTrendUp marge, phosphorPackage produits, phosphorCube valeur stock)
- Section header sticky : "Produits" + "X actifs" (meme pattern que Transactions/Abonnements/Dettes)
- Groupement par statut : En stock (default), Rupture de stock (label rouge), Inactifs (opacity 0.5)
- Groupes collapsibles : chevron + compteur, Rupture et Inactifs fermes par defaut — focus sur ce qui compte
- Rows custom : icone cercle 36px (image produit ronde ou emoji), titre text-secondary, subtitle "Stock: X · Y ventes", prix de vente a droite, badge "Rupture" rouge si stock=0
- Images produit dans les cercles 36px (object-fit cover, border-radius round)

### Page Boutique — detail — refonte complete
- Supprime : header centre avec emoji/image 80px, grille 7 stat-cards (prix achat/vente/marge/stock/vendu/CA/marge totale), boutons full-width Vendre/Restocker, badge Inactif rouge, bandeau warning inactif, box-shadow partout
- Header pattern recurrences : fleche retour + nom produit aligne a droite
- Image produit : grand format 16:9 arrondi (radius-xl) entre header et hero, object-fit cover. Affichee uniquement si imageUrl existe
- Hero condense : label "PRIX DE VENTE" uppercase + badge statut (bordure neutre si inactif, fond vert si actif) + montant 3xl color-income + "Achat X € · Marge Y €" + meta-lines (stock, vendus, CA, marge totale coloree vert/rouge) + description optionnelle
- Actions pills compactes : corbeille (danger) a gauche | spacer | Modifier · Restocker · Vendre (primary amber) a droite
- Ajout action Supprimer (avec confirm) — manquait sur l'ancienne page
- Historique groupe par date relative : Aujourd'hui, Hier, Ce mois-ci, puis par mois (Fevrier 2026, Janvier 2026...) — meme vocabulaire temporel que les autres pages
- Icones metier au lieu de fleches financieres : phosphorShoppingBag pour les ventes, phosphorPackage pour les restocks — la semantique est "entree/sortie stock", pas "recette/depense"
- Ventes cliquables : ouvrent le formulaire transaction associe via modalService (meme pattern que la page Transactions)
- Montants historique neutres (xs/medium/text-secondary)

### Decisions de design (session 9)
- Le hero boutique liste montre le CA total (chiffre d'affaires) en vert (color-income) — la boutique genere du revenu, le signal doit etre positif
- Les prix dans les rows restent neutres (text-secondary) — seul le hero porte la couleur
- Groupes collapsibles testes et valides : Rupture et Inactifs fermes par defaut evite le bruit visuel, le compteur dans le label donne l'info sans ouvrir
- L'image produit en grand format sur le detail est necessaire pour un produit physique (contrairement aux abonnements/dettes qui n'ont pas d'image)
- Les fleches financieres (TrendUp/TrendDown) etaient confuses sur l'historique produit : une vente fait SORTIR du stock mais est une RECETTE — la double semantique creait un conflit. Les icones metier (ShoppingBag/Package) resolvent ce conflit
- Pas de page detail transaction : le clic sur une vente ouvre directement le formulaire d'edition (progressive disclosure, pas de navigation supplementaire)

## Direction validee — Surfaces modales

Deux types de surfaces, deux roles distincts :

### Bottom sheet — formulaires et saisie

Le bottom sheet est le conteneur unique pour toute creation et edition. Pas de modal empile par-dessus, pas de navigation multi-step. Tout vit dans le sheet, qui grandit/retrecit via inline expand.

**Pattern creation :**
1. **Montant en hero** — clavier numerique immediat a l'ouverture, montant affiche en 3xl (meme langage que les pages detail). C'est le champ dominant.
2. **Label** — input discret en dessous, fond surface-raised, pas de bordure visible
3. **3 categories les plus utilisees** (30 derniers jours) affichees en chips. Tap = selectionne. Si aucune ne convient → inline expand : barre de recherche + suggestions live (max 3 resultats affiches)
4. **Barre d'icones Phosphor** pour les champs secondaires — chaque icone declenche un inline expand dans le sheet (le sheet grandit, pas de deuxieme surface) :
   - Calendrier → date picker
   - Wallet → selecteur compte
   - Repeat → toggle recurrence + frequence
   - Note → champ texte
5. **Bouton validation** en bas

**Pattern edition :**
1. **Zone lecture** (haut du sheet) — infos non modifiables affichees comme dans les heroes : label uppercase xs/tertiary, valeur sm/semibold/secondary. Pas de champ, pas de bordure.
2. **Zone action** (en dessous) — champs modifiables derriere les memes icones Phosphor. Champs pre-remplis avec les valeurs actuelles. Meme principe d'inline expand.

**Contrainte iPhone :** Le clavier iOS prend ~50% du viewport (466px restants sur iPhone 14 Pro). Le montant hero + label doivent rester visibles au-dessus du clavier. Les categories et la barre d'icones scrollent sous le fold quand le clavier est ouvert.

**Regle :** Un seul niveau de profondeur. Jamais deux surfaces empilees. Le bottom sheet est l'unique conteneur actif.

### Modal centre — confirmations et alertes

Reserve aux actions qui demandent une interruption volontaire du flux :
- Suppression (irreversible)
- Desactivation
- Confirmation d'action groupee ("Tout marquer comme paye")

Court, focalise, deux boutons max. Le modal centre bloque le flux — c'est voulu.

## Direction validee — Realignement heroes

Les heroes du dashboard et des transactions datent des sessions 1-3 et divergent du pattern qui s'est cristallise ensuite (sessions 5-9). A realigner sur la grammaire commune :

- Label uppercase xs/letter-spacing/text-secondary
- Montant dominant 3xl bold
- Conversion devise secondaire
- Meta-lines avec icones Phosphor 14px/text-tertiary

### Dashboard — a reprendre
- Supprimer le greeting "Bonjour Kelly SOSSOE" ou le reduire a un element minimal
- "PATRIMOINE TOTAL" → label uppercase xs (deja fait mais le greeting prend trop de place au-dessus)
- Revenus/Depenses → meta-lines avec icones Phosphor (comme dettes/abonnements)
- Gagner de l'espace vertical — chaque pixel compte sur iPhone 14 Pro

### Transactions — a reprendre
- "SOLDE" → label uppercase xs (deja fait)
- Recettes/Depenses → meta-lines avec icones Phosphor au lieu du conteneur arrondi inline
- Aligner le selecteur mois sur le style des autres pages

## Direction validee — Settings (session 10)

### Diagnostic

Les Settings existants (11 sous-pages) souffrent de 3 problemes :
1. Aucun lien visuel avec les pages principales de l'app (pas de vocabulaire partage)
2. Chaque sous-page reinvente sa structure (profile-section, accounts-section, cat-section, about-section, notif-section — meme pattern copie 6 fois avec des noms differents)
3. L'organisation en 3 groupes (General / Gestion / Autre) est un heritage d'avant la refonte

### Decision : casser et reconstruire

**De 11 pages → 1 hub + 2 sous-pages.**

### Structure finale

**Hub Settings — page unique scrollable, tout inline :**

1. **Mon compte** (ancrage visuel, haut de page)
   - Avatar centre + nom + email en dessous
   - Deconnexion dans ce meme conteneur
   - Pas de hero 3xl — la zone avatar fait ancrage sans forcer un chiffre

2. **Apparence** (inline)
   - Segmented control theme (Clair / Sombre / Auto)
   - Segmented control taille texte (Petit / Normal / Grand)
   - Preview texte

3. **Notifications** (inline)
   - Toggles par type de notification
   - Timezone

4. **Navigation** (inline)
   - 4 lignes : Abonnements, Dettes, Budgets, Boutique
   - Chaque ligne = toggle active/desactive + drag handle pour l'ordre nav
   - Un seul controle fait les deux jobs (activer + ordonner)
   - Accueil et Transactions implicitement toujours la, pas affiches (locked)

5. **Gestion** (liens vers sous-pages)
   - Comptes → sous-page CRUD (+ acces Import depuis un compte)
   - Categories → sous-page CRUD
   - Rows avec chevron (navigation)

6. **Footer**
   - Version, environnement, sante serveur
   - Texte xs/tertiary, discret, pas une page

**Sous-pages (2 seulement) :**
- **Comptes** : header (fleche retour + titre droite) → section header avec compteur + bouton add → conteneur arrondi avec rows CRUD. Import accessible depuis un compte.
- **Categories** : meme pattern que Comptes.

### Ce qui disparait

- **7 sous-pages supprimees** : Profil, Apparence, Notifications, Fonctionnalites & Navigation, Donnees, A propos, Securite (placeholder)
- **Page Devises & Taux** : automatisee a la creation de compte avec devise differente. La devise est portee par le compte, le taux se resout automatiquement. Pas besoin de page dediee.
- **Import** : sort des Settings. Accessible depuis la page Comptes (on importe dans un compte, pas dans les parametres).

### Vocabulaire visuel du hub

- Label section : uppercase xs / letter-spacing / text-tertiary
- Conteneurs arrondis : surface-default / radius-xl
- Rows : padding space-3 space-4 / dividers border-default
- Controles a droite : toggles, segmented controls, drag handles, chevrons
- Pas de hero financier. La zone Mon Compte fait ancrage visuel.

Le vocabulaire est identique aux listes groupees des pages financieres (abonnements par periode, dettes par echeance), sauf que le contenu des rows est des controles au lieu de donnees.

### Vocabulaire visuel des sous-pages (Comptes, Categories)

Alignees sur le pattern des pages principales :
- Header : fleche retour + titre aligne a droite
- Section header : label avec compteur + bouton add
- Conteneur arrondi : surface-default, rows avec dividers
- Actions CRUD : boutons pills compactes (pattern detail abonnement/dette)

### Justification (recherche UX)

Les apps de reference (TickTick, Stoic, Copilot Money) et les guidelines iOS/Material Design convergent sur le meme pattern pour les settings :
- **Single-page quand possible** : si < 15-20 controles, tout sur un ecran scrollable
- **Groupement par contexte** : pas par type de controle
- **Controles inline montrent l'etat actuel** : toggle = on/off visible, segmented = selection visible
- **Chevrons = navigation vers contenu dynamique** (listes CRUD)
- **Priorite visuelle** : qui (compte) en haut, comment (preferences) au milieu, quoi (gestion) en bas

## Ce qui a ete fait (session 10)

### Hero Dashboard — realignement grammaire commune
- Supprime : greeting statique "Bonjour Kelly SOSSOE" (sm/medium/secondary)
- Ajoute : greeting dynamique contextuel (sm/normal/secondary) — salutation temporelle (Bonjour/Bon apres-midi/Bonsoir) + signal financier (charges en retard > budgets depasses > mois positif/negatif > mois calme)
- Greeting = futur composant a part (logique propre, dependencies propres)
- Revenus/Depenses : conteneur arrondi surface-default avec divider → meta-lines Phosphor (TrendUp/TrendDown 14px), deux groupes cote a cote
- Currency pills : de space-between (avec greeting) a flex-end quand seul, puis space-between avec le nouveau greeting
- Zero state : "0,00 €" rouge → "0 revenus" / "0 depenses" en tertiary neutre — le zero n'est pas une depense

### Hero Transactions — realignement grammaire commune
- Recettes/Depenses : conteneur arrondi surface-default avec divider → meta-lines Phosphor (TrendUp/TrendDown 14px), deux groupes cote a cote
- Conversions devise secondaire : sous chaque montant (pas inline), alignees verticalement
- Hero toujours visible : ne disparait plus quand le summary est null (mois sans transactions). Affiche SOLDE 0,00 € + "0 revenus" / "0 depenses"
- Solde colore : vert si positif, rouge si negatif, neutre si zero (comme le hero dettes)

### Empty state Transactions — contextuel + incitatif
- Icone phosphorReceipt 48px + "Aucune transaction en [mois annee]" + lien "Ajouter une transaction" (xs/medium/primary, ouvre le formulaire creation)
- Remplacement du texte generique "Aucune transaction"

### Toggle devise — harmonisation globale
- Abonnements et Dettes : toggle deplace de hero__top-row isolee (flex-end) vers la meme ligne que le label uppercase (hero__amount-top : label a gauche, toggle a droite)
- Boutique : toggle devise ajoute (n'existait pas), meme pattern label + toggle
- Supprime : hero__top-row sur abonnements et dettes (devenue inutile)

Cartographie finale du toggle devise :

| Page | Gauche | Droite |
|------|--------|--------|
| Dashboard | Greeting dynamique | Currency pills |
| Transactions | Nav mois | Toggle devise |
| Abonnements | TOTAL MENSUEL (label) | Toggle devise |
| Dettes | SOLDE NET (label) | Toggle devise |
| Budgets | Nav mois | Toggle devise |
| Boutique | CHIFFRE D'AFFAIRES (label) | Toggle devise |

### Decisions de design (session 10)
- Le greeting dynamique justifie sa place parce qu'il dit quelque chose de nouveau a chaque ouverture — un greeting statique ne le justifie pas
- "0 revenus" au lieu de "0,00 €" : le texte est plus honnete quand il ne s'est rien passe. "Couleur = information" : pas de rouge sur un zero
- Le hero ne doit jamais disparaitre — la structure reste stable quel que soit l'etat des donnees
- Le toggle devise doit toujours etre ancre a un element existant (label, nav mois, greeting), jamais flotter seul
- Les empty states sont un moment de design important — a traiter page par page avant d'extraire un composant partage

## Ce qui a ete fait (session 11)

### Settings — refonte complete (hub unique)
- Supprime : 11 sous-pages (Profil, Apparence, Notifications, Fonctionnalites & Navigation, Donnees, A propos, Securite placeholder, Devises & Taux, Rate Calculator) + routing settings.routes.ts entier
- 9 composants orphelins supprimes : about, appearance, data-settings, features, notification-settings, placeholder, profile, currency-settings, rate-calculator (-2794 lignes)
- **Hub scrollable unique** remplace les 3 groupes (General / Gestion / Autre) et leurs sous-pages :

1. **Mon compte** (ancrage visuel, haut de page)
   - Avatar cercle avec initiales + bouton camera overlay
   - Nom + email en dessous
   - Bouton Deconnexion dans le meme conteneur (phosphorSignOut)
   - Pas de hero 3xl — la zone avatar fait ancrage

2. **Gestion** (liens vers sous-pages)
   - Comptes & Devises → sous-page CRUD (phosphorBank, teal)
   - Categories → sous-page CRUD (phosphorTag, orange)
   - Rows avec icone cercle coloree + description + chevron

3. **Apparence** (inline)
   - Segmented control theme (Clair / Sombre / Auto) avec icones Phosphor (phosphorSun, phosphorMoon, phosphorDevices)
   - Segmented control taille texte (Petit / Normal / Grand)
   - Preview texte en temps reel

4. **Notifications** (inline)
   - Toggles par type : rappels recurrentes, rappels dettes, alertes budgets
   - Selecteur timezone

5. **Navigation** (inline)
   - 4 rows : Abonnements, Dettes, Budgets, Boutique
   - Chaque row = toggle active/desactive + drag handle (phosphorDotsSixVertical)
   - Drag & drop reordonnancement (CdkDragDrop)
   - Accueil et Transactions implicitement toujours la (locked)

6. **Footer** (inline, discret)
   - Version + environnement + sante serveur sur une ligne
   - Texte xs/tertiary

### Sous-pages conservees (2 seulement)
- **Comptes & Devises** : header (fleche retour + "Comptes & Devises" + icone Phosphor) → conteneur arrondi rows CRUD. Devises & taux integres (plus de page separee)
- **Categories** : meme pattern. Icone Phosphor dans le header

### Vocabulaire visuel du hub
- Label section : uppercase xs / letter-spacing / text-tertiary (identique aux hero labels)
- Conteneurs arrondis : surface-default / radius-xl
- Rows : padding space-3 space-4 / dividers border-default
- Controles a droite : toggles, segmented controls, drag handles, chevrons
- Meme vocabulaire que les listes groupees des pages financieres, sauf contenu = controles au lieu de donnees

### Shell — adaptation pour Settings
- FAB cache sur toutes les routes `/settings/**` via `isOnSettingsRoute` computed signal

### Modal — refonte bottom sheet / dialog adaptatif
- Mobile (< 768px) : panel ancre en bas (bottom sheet), arrondi uniquement en haut (radius-xl radius-xl 0 0), animation slide-up
- Desktop (>= 768px) : dialog centre, border-radius full, animation scale-in
- Ajout input `hideHeader` : permet aux formulaires de gerer leur propre header (handle bar + toggle au lieu du titre modal)
- Gestion focus : sauvegarde `previouslyFocusedElement` a l'ouverture, restauration a la fermeture
- Slot `ng-content select="[modal-header-actions]"` dans le header pour controles additionnels

### Confirm Dialog — nouveau composant global
- Composant standalone separe du Modal (plus compact, toujours centre, pas de bottom sheet)
- `ConfirmService` singleton (signals) : `confirm()` retourne `Promise<boolean>`, pattern imperatif sans abonnement
- Panel max-width 320px, padding space-4, surface-raised, animations modal-fade-in + modal-scale-in
- Deux variantes : `default` (bouton amber) et `danger` (bouton rouge)
- Focus trap (CdkTrapFocus), fermeture Escape, restoration focus, overflow hidden body
- Accessibilite : `role="alertdialog"`, `aria-labelledby`, `aria-describedby`
- Integre dans shell.html (apres toast, hors stacking context)

### Confirm Dialog — structure visuelle
- **Header** : icone metier + titre en row, aligne a gauche, separe par border-bottom
- **Titre** = element concret (nom + montant/info), pas "Supprimer le X" generique
- **Message** = question de confirmation ("Voulez-vous vraiment supprimer..."), aligne sous le titre (padding-left = icone 20px + gap), font-size xs, text-secondary
- **Actions** : alignees a droite, separees par border-top. Boutons pills compacts (space-1 space-3), sans bordure visible, texte + icone uniquement
- **Bouton cancel** : text-secondary, icone phosphorX
- **Bouton confirm** : color-primary (default) ou color-expense (danger), icone phosphorCheck ou phosphorTrash selon variante

### Migration ConfirmService — toutes les pages
- Remplacement de `window.confirm()` natif par `confirmService.confirm()` avec config contextuelle
- Pattern uniforme : titre = element concret, message = question de confirmation
- Pages migrees avec icone metier : TransactionForm (phosphorReceipt), BudgetForm (phosphorChartPie), BudgetDetail (phosphorChartPie), DebtDetail (phosphorHandCoins), ProductForm (phosphorPackage), ShopDetail (phosphorPackage + phosphorShoppingBag pour vente), SubscriptionDetail (phosphorRepeat)

### Transaction Form — refonte bottom sheet
- Supprime : formulaire classique champs empiles, header modal standard
- **Handle bar** centree (36px x 4px, radius round) — indicateur visuel bottom sheet
- **Toggle depense/recette** a droite du handle. Actif = color-primary, inactif = text-tertiary. Pas de border, juste la couleur du texte
- **Row 2 — Montant + Libelle** : montant hero (40px, bold) a gauche, couleur contextuelle rouge/vert selon type. Libelle aligne a droite avec underline seul. `inputmode="decimal"` pour clavier numerique iPhone
- **Note preview** : si une note existe, affichee en italique xs/tertiary sous la row montant+libelle, alignee a droite, max 2 lignes avec troncature
- **Row 3 — Icones + Pills** : icone note (gauche, tertiary si vide, color-secondary opacity 0.7 si remplie) + icone recurrence (gauche, masquee en edition) | pills date + categorie + compte (droite)
- **Pills meta** : icone calendrier (color-secondary 0.7) + "Aujourd'hui/Hier/15 avr.", icone tag (couleur categorie 0.7) + nom categorie, icone wallet (couleur compte 0.7) + nom compte tronque
- **Sections expandables** : une seule active a la fois via signal. S'affichent inline entre row 3 et row 4
- **Row 4 — Actions** : bouton Annuler (text-secondary, mode creation) ou corbeille (danger, mode edition) a gauche | bouton Enregistrer/Modifier (primary) a droite
- ShortDatePipe inline : "Aujourd'hui", "Hier", "Demain", "15 avr."
- CategoryService injecte pour afficher le nom et la couleur de la categorie selectionnee
- AccountService : couleur du compte propagee a l'icone wallet

### Fix date locale
- `new Date().toISOString().split('T')[0]` retournait la date UTC — affichait "Hier" apres minuit en Europe
- Remplace par `getFullYear()/getMonth()/getDate()` (fuseau local) pour `today` et la valeur initiale du champ date

### Utilitaires formulaire — extraction
- `form.utils.ts` : `normalizeDecimal()` (virgule → point iPhone), `decimalMin()` validateur custom, `isFieldInvalid()`, `validateForm()`
- Utilise dans TransactionForm, BudgetForm, ProductForm — supprime la duplication

### CategoryService — refreshTrigger
- Signal `refreshTrigger` pour notifier les composants dependants apres create/update/delete
- Les formulaires qui affichent des categories reagissent au changement sans polling

### Decisions de design (session 11)
- Le hub Settings est un ecran scrollable unique parce qu'il y a < 15 controles — pas besoin de navigation
- Devises & Taux integres dans Comptes parce qu'une devise est portee par un compte, pas par un setting global
- Le confirm dialog est separe du modal : deux surfaces, deux roles. Le modal = conteneur formulaire (bottom sheet). Le confirm = interruption volontaire (toujours centre, compact)
- Le bottom sheet transaction form gere son propre header (handle bar + toggle) parce que le header modal standard ne convient pas — le formulaire a besoin d'un toggle type, pas d'un titre
- Montant hero 40px dans le formulaire = meme langage que les pages detail (montant dominant), continuite visuelle
- Les sections expandables (une seule a la fois) evitent le formulaire-qui-expose-tout-d'un-coup
- `window.confirm()` remplace par le confirm dialog partage : coherence visuelle, icones metier, variante danger
- Le titre du confirm dialog doit etre l'element concret (nom + montant), pas une action generique ("Supprimer le budget") — l'utilisateur voit immediatement CE qu'il supprime
- Le message pose la question de confirmation — c'est le role du message, pas du titre
- L'icone metier et le titre sont en row (pas empiles) : lecture horizontale naturelle, plus compact
- Le message est aligne sous le titre (pas sous l'icone) pour creer une hierarchie visuelle claire : icone = repere, titre = info, message = question
- Boutons sans bordure visible, compacts — le separator border-top suffit a delimiter la zone actions
- Les icones du formulaire suivent le pattern doughnut (opacity 0.7) : couleurs attenueees, pas les valeurs Tailwind 400 brutes
- Icones fixes (note, calendrier) en color-secondary 0.7 — marque l'etat "il y a une valeur" sans etre criard. Icone note tertiary quand vide
- Icones dynamiques (categorie, compte) portent la couleur de l'entite a opacity 0.7 — coherence avec le doughnut chart
- La note en preview (italique, xs, tertiary, alignee droite) vit sous la row montant+libelle — pas dans les pills, c'est du contenu secondaire
- Bouton Annuler en mode creation (a gauche) — remplace le vide. En edition, la corbeille prend cette place
- La date initiale doit utiliser le fuseau local, pas UTC — important pour les utilisateurs apres minuit

## Ce qui reste a faire

### Priorite haute
- [x] Propager le style aux pages Abonnements (session 5)
- [x] Page detail abonnement (session 6)
- [x] Page Dettes — liste (session 7)
- [x] Page detail dette (session 7)
- [x] Propager le style a la page Budgets (session 8)
- [x] Page Boutique — liste + detail (session 9)
- [x] Page Transactions recurrentes (session 4)
- [x] Realigner hero Dashboard (session 10)
- [x] Realigner hero Transactions (session 10)
- [x] Settings — refonte hub unique + 2 sous-pages (session 11)
- [x] Modal centre — confirmations via ConfirmDialog + ConfirmService (session 11)
- [x] Bottom sheet formulaires — creation transaction (montant hero + toggle + icones + expand) (session 11)
- [ ] Empty states — design par page puis composant partage
- [ ] Bottom sheet formulaires — edition (zone lecture + zone action)
- [ ] Bottom sheet formulaires — propager le pattern transaction aux autres formulaires (budget, dette, abonnement, produit)
- [ ] Migrer RepayDialog et SellDialog vers le bottom sheet partage

### Priorite moyenne
- [ ] Date picker inline custom — remplacer `<input type="date">` natif par un calendrier integre dans la section expand (respecter "un seul niveau de profondeur")
- [ ] Micro-interactions (transitions de page, feedback tactile)
- [ ] Skeleton loading au lieu de spinners

### A faire en dernier
- [ ] Reecrire DESIGN.md a partir du resultat valide
- [ ] Aligner les tokens Flutter (DESIGN.md Flutter) avec les nouvelles valeurs
- [ ] Appliquer la meme direction a Kassist

## References visuelles

- **TickTick** : clean, utilitaire, listes propres, accent discret
- **Stoic** : calme, minimal, couleurs douces
- **Apple Journal** : natif iOS, invisible, contenu-first
- **Apple Wallet** : montant dominant a la saisie, clavier numerique immediat
- **Apple Reminders** : bottom sheet unique, champs qui se deploient inline

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
- Empiler deux surfaces modales (bottom sheet + modal par-dessus)
- Formulaires qui exposent tous les champs d'un coup
- Segmented controls pour filtrer (preferer groupement + sections en bas)
