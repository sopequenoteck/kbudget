# Feature Specification: Import de releves bancaires CSV

**Feature Branch**: `099-csv-import`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "Import de releves bancaires CSV — Parsing cote API avec review interactif cote Angular. Option 3 hybride : icone d'import par compte + page dediee /import. Brouillons intelligents, categorisation par apprentissage, deduplication fuzzy."

## Clarifications

### Session 2026-03-20

- Q: Comment determiner le type de transaction (DEPENSE vs RECETTE) a partir du CSV ? → A: Le systeme detecte automatiquement la strategie du CSV (montant signe unique OU double colonne debit/credit) et determine le type en consequence. Le profil d'import enregistre la strategie detectee pour les futurs imports.
- Q: Ou la page /import apparait-elle dans la navigation ? → A: Sous-page des parametres (Settings > Import), accessible aussi via l'icone d'import sur chaque compte.
- Q: Quel libelle utiliser pour les transactions importees ? → A: Le detail (colonne la plus riche) avec nettoyage intelligent (suppression codes bancaires, suffixes IOPD, numeros de reference). Le profil d'import definit la colonne source et les regles de nettoyage.
- Q: Quelle strategie d'atomicite pour la creation en masse des transactions lors de la confirmation ? → A: Tout-ou-rien (transaction BDD unique). Si une ligne echoue, aucune transaction n'est creee et le brouillon reste intact pour correction.
- Q: Comment le systeme determine-t-il quel profil d'import appliquer a un CSV ? → A: D'abord par le bankCode du compte cible (profil pre-configure), puis fallback par analyse du contenu CSV (en-tetes, separateur, structure) si aucun profil ne correspond au bankCode.
- Q: Sur quelle periode le systeme cherche-t-il les doublons lors de la deduplication ? → A: Plage de dates du CSV avec marge (date min/max du fichier + quelques jours de marge). Ni tout l'historique ni une fenetre fixe.
- Q: Peut-on avoir plusieurs brouillons d'import en cours pour le meme compte ? → A: Non, un seul brouillon actif par compte. Un nouvel upload demande de finaliser ou supprimer le brouillon existant.
- Q: L'import CSV doit-il etre derriere un Feature toggle ? → A: Non, toujours disponible pour tous les utilisateurs. Pas de Feature.IMPORT.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Importer un releve CSV depuis un compte (Priority: P1)

L'utilisateur se trouve sur la page de ses comptes. Il clique sur l'icone d'import associee a un compte, selectionne un fichier CSV exporte depuis sa banque, et le systeme parse automatiquement le fichier. L'utilisateur arrive sur un ecran de review ou chaque ligne est pre-analysee avec un statut et un type (DEPENSE/RECETTE determine automatiquement). Les libelles sont nettoyes automatiquement (suppression du bruit technique). Il valide les lignes pretes et corrige celles qui necessitent son attention, puis confirme l'import. Les transactions sont creees en masse dans le compte cible.

**Why this priority**: C'est le coeur de la feature. Sans import + review, rien d'autre n'a de sens. Cela couvre le flow complet de bout en bout.

**Independent Test**: Peut etre teste en uploadant un CSV reel depuis une banque connue, en verifiant que le parsing produit des lignes correctes avec des libelles nettoyes, et que la confirmation cree les transactions dans le bon compte.

**Acceptance Scenarios**:

1. **Given** un compte existant et un fichier CSV valide de la banque associee, **When** l'utilisateur uploade le fichier via l'icone d'import du compte, **Then** le systeme parse le CSV et affiche un brouillon avec toutes les lignes categorisees par statut (READY, NEEDS_REVIEW) et type (DEPENSE/RECETTE)
2. **Given** un brouillon d'import avec des lignes en statut READY, **When** l'utilisateur confirme l'import, **Then** les transactions correspondantes sont creees dans le compte cible avec les bons montants, dates, libelles nettoyes, categories et types
3. **Given** un CSV avec une colonne unique de montant signe, **When** le systeme parse le fichier, **Then** les montants negatifs sont interpretes comme DEPENSE et les positifs comme RECETTE automatiquement
4. **Given** un CSV avec deux colonnes separees debit/credit, **When** le systeme parse le fichier, **Then** le systeme detecte cette structure et determine le type de chaque ligne en consequence
5. **Given** un CSV Societe Generale avec un detail contenant "CARTE X3855 16/03 UEP*SUPER U 101607535098170IOPD", **When** le systeme nettoie le libelle, **Then** le libelle affiche devient "SUPER U" (codes bancaires, prefixes carte, suffixes IOPD supprimes)
6. **Given** un fichier CSV dont le format ne correspond a aucun profil connu (bankCode du compte ni analyse contenu), **When** l'utilisateur uploade le fichier, **Then** le systeme retourne une erreur 422 avec un message explicatif (le mapping manuel est disponible via US5)

---

### User Story 2 - Page dediee Import avec gestion des brouillons (Priority: P2)

L'utilisateur accede a une page dediee accessible depuis Settings > Import. Cette page affiche la liste de ses brouillons d'import en cours et l'historique de ses imports finalises. Il peut reprendre un brouillon inacheve ou consulter les details d'un import passe. La page est aussi atteignable directement via l'icone d'import sur chaque compte (avec le compte pre-selectionne).

**Why this priority**: La persistance des brouillons et l'historique donnent de la profondeur a la feature. Sans cela, l'import est un geste jetable sans suivi.

**Independent Test**: Peut etre teste en creant un brouillon, en quittant la page, puis en revenant pour le reprendre. L'historique peut etre verifie apres un import finalise.

**Acceptance Scenarios**:

1. **Given** un brouillon d'import cree mais non finalise, **When** l'utilisateur visite Settings > Import, **Then** il voit le brouillon dans la section "En cours" avec le nom du compte, le nombre de lignes, et la date de creation
2. **Given** un import finalise precedemment, **When** l'utilisateur consulte l'historique, **Then** il voit la date, le compte, le nombre de transactions importees, et peut ouvrir les details
3. **Given** un brouillon non finalise depuis plus de 7 jours, **When** le systeme effectue son nettoyage periodique, **Then** le brouillon est automatiquement supprime et n'apparait plus dans la liste
4. **Given** la page Settings > Import, **When** l'utilisateur clique sur "Nouvel import", **Then** il peut selectionner un compte cible et uploader un fichier CSV (meme flow que depuis la page comptes)
5. **Given** l'icone d'import sur un compte, **When** l'utilisateur clique dessus, **Then** il est redirige vers Settings > Import avec le compte pre-selectionne

---

### User Story 3 - Categorisation intelligente et regles de categorisation (Priority: P2)

Le systeme apprend des habitudes de l'utilisateur. Quand un libelle comme "CARREFOUR" a deja ete categorise "Courses" lors d'un import precedent, le systeme propose automatiquement cette categorie pour les futurs imports. L'utilisateur peut aussi creer, modifier et supprimer des regles de categorisation manuellement depuis Settings > Import.

**Why this priority**: C'est ce qui rend l'import "intelligent" et de plus en plus rapide au fil du temps. Apres quelques imports, la majorite des lignes seront automatiquement categorisees.

**Independent Test**: Peut etre teste en important un CSV, en categorisant manuellement une ligne, puis en important un second CSV contenant le meme libelle et en verifiant que la categorie est pre-remplie.

**Acceptance Scenarios**:

1. **Given** une regle de categorisation existante "CARREFOUR" -> "Courses", **When** un nouveau CSV contient une ligne avec le libelle "CARREFOUR PARIS", **Then** la categorie "Courses" est automatiquement suggeree et la ligne a le statut READY
2. **Given** une ligne d'import sans regle correspondante, **When** l'utilisateur assigne manuellement une categorie, **Then** le systeme propose de creer une regle pour ce pattern de libelle
3. **Given** la page Settings > Import section "Regles", **When** l'utilisateur cree une regle avec un pattern et une categorie, **Then** la regle est sauvegardee et appliquee aux futurs imports
4. **Given** une regle existante, **When** l'utilisateur la modifie ou la supprime, **Then** le changement est pris en compte immediatement pour les brouillons en cours

---

### User Story 4 - Deduplication et resolution de conflits (Priority: P2)

Lors du parsing d'un CSV, le systeme detecte les potentiels doublons en comparant chaque ligne avec les transactions existantes du meme compte (basee sur la date, le montant et la similarite du libelle). Les doublons potentiels sont marques et presentes a l'utilisateur avec un comparatif visuel pour qu'il puisse decider de les importer ou non.

**Why this priority**: Evite la creation de transactions en double, ce qui est un probleme frequent lors d'imports multiples couvrant les memes periodes.

**Independent Test**: Peut etre teste en creant une transaction manuellement, puis en important un CSV contenant la meme transaction, et en verifiant que le systeme detecte le doublon.

**Acceptance Scenarios**:

1. **Given** une transaction existante du 15/03 de -45.50 EUR "CARREFOUR", **When** le CSV contient une ligne du 15/03 de -45.50 EUR "CARREFOUR CITY", **Then** la ligne est marquee DUPLICATE avec un lien vers la transaction existante
2. **Given** une ligne marquee DUPLICATE, **When** l'utilisateur choisit "Importer quand meme", **Then** la ligne passe en statut READY et sera importee a la confirmation
3. **Given** une ligne marquee DUPLICATE, **When** l'utilisateur choisit "Ignorer", **Then** la ligne passe en statut SKIPPED et ne sera pas importee
4. **Given** un brouillon d'import avec des lignes en statut DUPLICATE, **When** l'utilisateur visualise ces lignes, **Then** il voit la transaction existante qui correspond et peut choisir de conserver ou d'ignorer le doublon

---

### User Story 5 - Profils d'import par banque et mapping custom (Priority: P3)

Le systeme reconnait automatiquement le format CSV de certaines banques grace a des profils pre-configures (colonnes, separateur, format de date, sens debit/credit, strategie montant, regles de nettoyage du libelle). Pour les banques non reconnues, l'utilisateur peut mapper les colonnes manuellement et sauvegarder ce mapping comme profil personnalise pour ses futurs imports.

**Why this priority**: Ameliore l'experience en eliminant le mapping repetitif, mais l'import fonctionne deja sans cette feature grace au mapping manuel ponctuel (US1).

**Independent Test**: Peut etre teste en important un CSV d'une banque connue (mapping automatique) puis un CSV d'une banque inconnue (mapping manuel + sauvegarde du profil).

**Acceptance Scenarios**:

1. **Given** un CSV exporte depuis une banque connue du registre, **When** l'utilisateur uploade le fichier, **Then** le systeme detecte automatiquement le format et parse sans intervention
2. **Given** un CSV d'une banque inconnue, **When** l'utilisateur mappe les colonnes manuellement, **Then** le systeme propose de sauvegarder ce mapping comme profil personnalise
3. **Given** un profil personnalise sauvegarde, **When** l'utilisateur importe un autre CSV de la meme banque, **Then** le profil est automatiquement applique
4. **Given** la page Settings > Import section "Profils", **When** l'utilisateur consulte ses profils, **Then** il voit les profils pre-configures (lecture seule) et ses profils personnalises (editables/supprimables)

---

### User Story 6 - Actions groupees et progression (Priority: P3)

Lors du review d'un brouillon, l'utilisateur peut effectuer des actions en masse : categoriser plusieurs lignes d'un coup, ignorer un lot de doublons, ou valider toutes les lignes pretes. Un indicateur de progression affiche en temps reel le nombre de lignes par statut (pretes / a verifier / doublons / ignorees).

**Why this priority**: Ameliore l'ergonomie pour les gros imports (100+ lignes) mais n'est pas bloquant pour les imports de taille normale.

**Independent Test**: Peut etre teste en important un CSV de 50+ lignes et en utilisant les actions groupees pour traiter rapidement les lignes.

**Acceptance Scenarios**:

1. **Given** un brouillon avec 10 lignes en NEEDS_REVIEW, **When** l'utilisateur selectionne 5 lignes et applique une categorie, **Then** les 5 lignes sont mises a jour et passent en statut READY
2. **Given** un brouillon de 50 lignes, **When** l'utilisateur consulte le review, **Then** un indicateur affiche "32 pretes / 12 a verifier / 4 doublons / 2 ignorees"
3. **Given** un brouillon ou toutes les lignes sont READY ou SKIPPED, **When** l'utilisateur voit l'indicateur de progression, **Then** le bouton "Confirmer l'import" devient actif

---

### Edge Cases

- Que se passe-t-il si le fichier CSV est vide ou ne contient que des en-tetes ?
- Que se passe-t-il si le fichier depasse la taille maximale (5 Mo) ?
- Que se passe-t-il si le CSV contient des lignes avec des montants invalides (texte au lieu de nombre) ?
- Que se passe-t-il si le CSV contient des dates dans un format non reconnu ?
- Que se passe-t-il si l'utilisateur tente d'importer dans un compte inactif ?
- Que se passe-t-il si le meme fichier CSV est uploade deux fois pour le meme compte ? Si un brouillon actif existe deja pour ce compte, le systeme retourne une erreur 409 et demande de finaliser ou supprimer le brouillon existant avant un nouvel upload. Si le brouillon precedent a ete finalise, un nouveau brouillon est cree et la deduplication detectera les doublons avec les transactions deja importees.
- Que se passe-t-il si une regle de categorisation matche plusieurs categories ? La premiere regle matchee (par ordre de creation) l'emporte.
- Que se passe-t-il si le compte cible est supprime pendant qu'un brouillon est en cours ? Le brouillon devient invalide et est marque comme tel avec un message explicite.
- Comment gerer les CSV avec des montants en devise differente du compte cible ? Les montants sont importes tels quels dans la devise du compte ; la devise du CSV est informative.
- Que se passe-t-il si le CSV contient une ligne d'en-tete de compte (comme SG) avant les en-tetes de colonnes ? Le systeme ignore les lignes avant la ligne d'en-tetes de colonnes detectee.
- Que se passe-t-il si le nettoyage du libelle produit une chaine vide ? Le libelle original non nettoye est conserve.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Le systeme DOIT permettre l'upload d'un fichier CSV depuis la page des comptes (icone par compte) et depuis Settings > Import
- **FR-002**: Le systeme DOIT parser le fichier CSV cote serveur et retourner un brouillon structure avec un statut et un type (DEPENSE/RECETTE) par ligne
- **FR-003**: Le systeme DOIT detecter automatiquement le format CSV en priorite par le bankCode du compte cible (profil pre-configure), puis par analyse du contenu CSV (en-tetes, separateur, structure) en fallback si aucun profil ne correspond au bankCode
- **FR-004**: Le systeme DOIT permettre le mapping manuel des colonnes quand le format n'est pas reconnu
- **FR-005**: Le systeme DOIT persister les brouillons d'import cote serveur pour permettre la reprise ulterieure, avec un maximum d'un brouillon actif par compte (un nouvel upload requiert de finaliser ou supprimer le brouillon existant)
- **FR-006**: Le systeme DOIT expirer et supprimer automatiquement les brouillons non finalises apres 7 jours
- **FR-007**: Le systeme DOIT detecter les doublons potentiels en comparant date, montant et similarite du libelle avec les transactions existantes du compte sur la plage de dates du CSV (date min/max du fichier + quelques jours de marge)
- **FR-008**: Le systeme DOIT permettre a l'utilisateur de resoudre chaque doublon individuellement (importer ou ignorer)
- **FR-009**: Le systeme DOIT proposer une categorisation automatique basee sur les regles de mapping de l'utilisateur
- **FR-010**: Le systeme DOIT permettre la creation, modification et suppression de regles de categorisation (pattern libelle -> categorie)
- **FR-011**: Le systeme DOIT proposer la creation d'une regle quand l'utilisateur categorise manuellement une ligne d'import
- **FR-012**: Le systeme DOIT creer les transactions en masse lors de la confirmation de l'import, dans une transaction BDD unique (tout-ou-rien : si une ligne echoue, aucune transaction n'est creee et le brouillon reste intact)
- **FR-013**: Le systeme DOIT enregistrer un historique de chaque import finalise (date, compte, nombre de transactions)
- **FR-014**: Le systeme DOIT permettre les actions groupees sur les lignes d'un brouillon (categoriser, ignorer, valider)
- **FR-015**: Le systeme DOIT afficher un indicateur de progression par statut (READY, NEEDS_REVIEW, DUPLICATE, SKIPPED)
- **FR-016**: Le systeme DOIT permettre la sauvegarde de profils d'import personnalises (mapping colonnes) pour reutilisation
- **FR-017**: Le systeme DOIT valider le fichier avant parsing : format CSV, taille maximale, encodage
- **FR-018**: Le systeme DOIT isoler les donnees d'import par utilisateur (brouillons, regles, profils, historique)
- **FR-019**: Le systeme DOIT refuser l'import dans un compte inactif
- **FR-020**: Le systeme DOIT gerer les lignes avec des donnees invalides (montant non numerique, date invalide) en les marquant NEEDS_REVIEW avec un message d'erreur explicite
- **FR-021**: Le systeme DOIT detecter automatiquement la strategie de montant du CSV (colonne unique signee OU double colonne debit/credit) et determiner le type de transaction (DEPENSE/RECETTE) en consequence
- **FR-022**: La page Import DOIT etre accessible via Settings > Import et via l'icone d'import sur chaque compte (avec pre-selection du compte)
- **FR-023**: Le systeme DOIT nettoyer intelligemment les libelles importes (suppression codes bancaires, prefixes carte, suffixes IOPD, numeros de reference) tout en preservant le nom du commercant. Si le nettoyage produit une chaine vide, le libelle original est conserve.

### Key Entities

- **ImportProfile**: Definit comment parser un format CSV specifique. Contient le nom de la banque ou un nom personnalise, le mapping des colonnes (date, montant, libelle source), le separateur, le format de date, la strategie de montant (colonne unique signee ou double colonne debit/credit), les regles de nettoyage du libelle, et la logique debit/credit. Peut etre pre-configure (lecture seule) ou personnalise par l'utilisateur. La strategie detectee est enregistree dans le profil pour les futurs imports.
- **ImportDraft**: Represente un import en cours de traitement. Lie a un compte cible et a un utilisateur. Contient le statut global, le nombre de lignes par statut, la date de creation et d'expiration. Peut etre en cours, finalise ou expire.
- **ImportDraftLine**: Une ligne individuelle du CSV parsee. Contient le montant, le libelle nettoye, le libelle brut original, la date, le type de transaction (DEPENSE/RECETTE), la categorie suggeree, le statut (READY, NEEDS_REVIEW, DUPLICATE, SKIPPED), et optionnellement une reference vers la transaction doublon detectee. Appartient a un ImportDraft.
- **CategoryRule**: Regle de categorisation automatique. Associe un pattern de libelle (matching partiel, insensible a la casse) a une categorie. Appartient a un utilisateur. En cas de match multiple, la premiere regle par ordre de creation l'emporte. Appliquee automatiquement lors du parsing des futurs imports.
- **ImportHistory**: Enregistrement d'un import finalise. Contient la date, le compte, le nombre de transactions creees, et optionnellement le nom du fichier source. Sert de trace pour l'historique sur la page Settings > Import.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: L'utilisateur peut importer un releve CSV et creer les transactions correspondantes en moins de 5 minutes pour un fichier de 50 lignes
- **SC-002**: Apres 3 imports, au moins 70% des lignes sont automatiquement categorisees grace aux regles apprises
- **SC-003**: Le systeme detecte correctement 95%+ des doublons reels (meme date, meme montant, libelle similaire)
- **SC-004**: L'utilisateur peut reprendre un brouillon inacheve sans perte de donnees pendant 7 jours
- **SC-005**: Le mapping manuel des colonnes pour une banque inconnue ne prend pas plus de 2 minutes et n'est necessaire qu'une seule fois par format de banque
- **SC-006**: Les actions groupees permettent de traiter un import de 100+ lignes aussi rapidement qu'un import de 20 lignes (temps de review proportionnel au nombre de lignes a verifier, pas au total)
- **SC-007**: Le parsing d'un fichier CSV de 200 lignes s'effectue en moins de 3 secondes
- **SC-008**: Les libelles nettoyes sont lisibles et identifient clairement le commercant ou l'operation (suppression du bruit technique sans perte d'information utile)

## Related Enhancements (hors scope)

- **Autocompletion des libelles de transaction** : lors de la saisie manuelle d'une transaction (pas seulement a l'import), le champ libelle propose en autocompletion les libelles deja utilises par l'utilisateur. Cela favorise la coherence des libelles et accelere la saisie. A traiter dans une feature separee (impacte le formulaire de transaction sur Angular et Flutter).

## Assumptions

- Les releves bancaires sont au format CSV (pas OFX, QFX, PDF ou autres formats)
- L'utilisateur dispose deja de comptes crees dans l'application avant d'importer
- Les banques du BankRegistry existant (29 banques FR/TG/International) servent de base pour les profils pre-configures, dont Societe Generale (format : separateur `;`, date `dd/MM/yyyy`, colonne montant unique signee, virgule decimale, encodage ISO-8859-1, ligne d'en-tete de compte a ignorer, colonne detail comme source libelle avec nettoyage specifique)
- La taille maximale d'un fichier CSV est fixee a 5 Mo (couvre largement un an de releve)
- L'encodage supporte est UTF-8 et ISO-8859-1 (les deux formats les plus courants des banques francaises)
- La deduplication utilise un matching exact sur date + montant et un matching flou sur le libelle (Jaro-Winkler, seuil 0.85 — defini dans research.md R2)
- Les regles de categorisation utilisent un matching par containment (le pattern est contenu dans le libelle), insensible a la casse ; en cas de multi-match, la premiere regle par date de creation l'emporte
- Un brouillon non finalise expire apres 7 jours
- Cette iteration couvre le backend (Spring Boot) et le frontend Angular uniquement. Flutter sera traite dans une iteration ulterieure
