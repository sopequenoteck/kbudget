# Direction produit — ouverture du projet

> Actée le 26 août 2026. Version du projet au moment de la décision : 5.2.1.
> Autorité : cette direction est traduite en règles dans
> [`.specify/memory/constitution.md`](../.specify/memory/constitution.md) v4.0.0, qui prévaut.
> Exécution : projet **Budget** dans Linear, jalons P1 à P8, issues KKS-307 à KKS-340.

## 1. Le point de départ

k-budget est une application de gestion de budget self-hostée, utilisée quotidiennement
par une quinzaine de proches sur une instance personnelle. Le code est mature : environ
78 000 lignes, plus de 1 900 tests, 102 endpoints, trois composants (API Spring Boot, PWA Angular,
app Flutter), une CI par stack et un gate de release.

Le constat qui a déclenché ce cadrage : **l'application, maintenue en l'état, perd des
utilisateurs**. Les derniers mois de développement ont été consacrés à de la refonte
design Flutter et à du nettoyage qualité — aucune capacité produit nouvelle. La demande
la plus fréquente des utilisateurs actuels est l'agrégation bancaire automatique.

Deux intentions initiales ont servi de point d'entrée à la discussion : aligner Flutter
sur Angular en supprimant son mode autonome, et ajouter un agrégateur bancaire. Aucune
des deux n'a survécu telle quelle.

## 2. La décision centrale

**k-budget devient un projet open source destiné à la communauté self-hosted.**

Pas un SaaS. Chaque utilisateur héberge sa propre instance. Le projet n'exploite aucun
service, ne collecte aucune donnée, et n'a aucun coût récurrent par utilisateur.

Cette décision découle d'une contrainte assumée : opérer un service pour le grand public
suppose une entité juridique, des coûts récurrents, la responsabilité RGPD sur les données
bancaires d'inconnus et un support quotidien. Ce n'est pas tenable pour une personne seule,
et le reconnaître tôt vaut mieux que de le découvrir en production.

### Ce que cette décision ferme

| Intention initiale | Sort | Raison |
|---|---|---|
| SaaS grand public français | Abandonné | Non tenable seul |
| Agrégation bancaire intégrée | Abandonnée | Exige un agrément AISP, donc une entité exploitant un service |
| « Le public français » comme cible | Abandonné | Le grand public ne déploie pas un Spring Boot ; la cible réelle est la communauté self-hosted |

Les utilisateurs actuels restent sur l'instance personnelle, mais **ils ne sont plus la
boussole produit**. Leurs demandes et celles de la nouvelle cible divergent, et confondre
les deux conduirait à construire pour les uns un produit destiné aux autres.

## 3. Positionnement

Le marché self-hosted est déjà occupé : Firefly III et Actual Budget sont matures, ouverts
et installés. Exister suppose de répondre à « qu'est-ce que je fais qu'ils ne font pas ».

**La réponse est la zone francophone — France et Afrique de l'Ouest.**

Le projet référence déjà douze banques ouest-africaines (Ecobank, UBA, Orabank, BSIC,
BTCI, UTB, Coris, NSIA, Sunu, BDT, BOA, SGTO), gère le XOF dans son multi-devises et
suit les dettes en devises multiples. Or :

- Firefly III, Actual Budget, Bankin', Linxo et Finary ne couvrent pas cette zone.
- **Aucun agrégateur DSP2 ne l'atteindra jamais** : la DSP2 est une réglementation
  européenne.

Sur ce périmètre, l'import de relevés n'est donc pas un pis-aller en attendant mieux :
c'est la seule voie possible. La contrainte technique cesse d'être un handicap.

Le second argument de positionnement est la confiance. Sur une application qui touche aux
comptes bancaires, « le serveur est auditable et vous pouvez l'héberger vous-même » est un
argument que les acteurs commerciaux ne peuvent pas produire.

## 4. Les décisions

### 4.1 Licences — AGPL-3.0 et MPL-2.0

`api/` et `app/` passent sous **AGPL-3.0**. La clause réseau empêche un tiers de reprendre
le backend, de le fermer et d'exploiter le service auquel on a renoncé. Le risque réel
n'est pas un géant du cloud, c'est un développeur qui relance le projet en fermé.

`flutter/` passe sous **MPL-2.0**, et non AGPL. Les conditions d'Apple (DRM, limitation du
nombre d'appareils) sont incompatibles avec GPL et AGPL — VLC a été retiré de l'App Store
en 2011 pour ce motif et n'est revenu qu'après être passé en MPL. MPL-2.0 est un copyleft
par fichier : la protection reste réelle sans le conflit.

*Alternative écartée* : MIT ou Apache-2.0. Adoption plus large, mais aucune protection
contre l'appropriation fermée.

*Incertitude signalée* : ces choix ont des conséquences juridiques réelles et n'ont pas été
validés par un juriste. Le point Apple/GPL est documenté publiquement mais mérite
vérification.

### 4.2 Accord de contribution — obligatoire avant la première PR

Sans CLA, dès la première contribution externe acceptée, la licence devient impossible à
changer sans l'accord de chaque contributeur. Disparaissent alors : la possibilité de
passer un jour en open core, et la capacité de réagir si les conditions des stores
évoluent.

Ce point se referme silencieusement, sans signal d'alerte. Il doit être traité **avant**
l'ouverture du dépôt.

Le nom et le logo sont réservés, hors licence — sans quoi n'importe quel fork peut se
réclamer du projet.

### 4.3 Modèle de l'app mobile — ouverte et payante

Flutter est **open source et payant sur les stores**. On vend la commodité, pas le
logiciel : qui veut la version gratuite compile lui-même ou passe par F-Droid.

**Règle non négociable** : un build compilé par un tiers doit être fonctionnellement
identique à celui du store. Aucun bridage selon l'origine du build — sinon c'est du
propriétaire déguisé, et la communauté le verra en une journée.

*Alternative écartée* : Flutter propriétaire fermé. Cela ferme F-Droid, crée une
dissonance avec un backend AGPL, et heurte frontalement le public visé — celui qui rejette
le plus le propriétaire payant.

**Tension non résolue, assumée** : la PWA Angular est gratuite et fait l'essentiel du
travail. Ce qui justifie l'app payante se réduit au verrouillage biométrique, aux
notifications locales fonctionnant serveur éteint, et à la présence sur les stores. C'est
réel mais mince. Le revenu attendu est symbolique — il finance du temps, pas de
l'infrastructure, ce qui est cohérent puisqu'il n'y a pas d'infrastructure à financer.

À noter : le compte développeur Apple coûte 99 $/an même pour publier gratuitement.

### 4.4 Frontière Angular / Flutter

**Angular est le client de référence. Flutter n'a jamais d'obligation de parité.**

Le premier facteur d'échec identifié est le coût de maintenance de deux clients complets
par une seule personne. Mais le diagnostic précis compte : **ce n'est pas l'existence de
deux clients qui coûte, c'est la parité**. Les douze dernières features (KKS-238 → KKS-255)
ont consisté à aligner Flutter sur Angular écran par écran.

Trois états, et non deux :

| État | Signification | Surfaces |
|---|---|---|
| **Suivi** | Parité maintenue | Transactions, budgets, abonnements, dettes, comptes, catégories, dashboard, notifications |
| **Gelé** | Existe, fonctionne, n'évolue plus — mais reste maintenu | Administration (880 l.), taux de change (1 042 l.) |
| **Jamais** | N'existe pas et n'existera pas | Import CSV (1 777 l. côté Angular, 0 côté Flutter), graphiques avancés, préférences avancées, banques |

Le troisième état est ce qui manquait. Supprimer du code qui fonctionne est rarement
rentable ; ce qui coûte, c'est de le **suivre**. Le gel arrête de payer sans rien détruire.

Précision qui rend le gel honnête : il porte sur les évolutions fonctionnelles, pas sur la
maintenance transverse. Les surfaces gelées sont traduites, suivent les montées de version
et restent testées. « Gelé » n'est pas un synonyme poli de « supprimé plus tard ».

Critère unique pour toute nouvelle surface : *va-t-elle continuer à bouger ?* Si oui et
qu'elle est complexe, Angular seul. Si c'est un CRUD stable, les deux.

La démonstration que le dispositif fonctionne existe déjà : l'import CSV, 1 777 lignes qui
n'existent que côté web, en production, sans que personne ne s'en plaigne.

**Exclusivités Flutter** : verrouillage biométrique, notifications locales planifiées
fonctionnant serveur injoignable, widget d'écran d'accueil.

**Un alignement unique** est accordé sur le périmètre *Suivi* — le delta mesuré se réduit
à l'écran de détail transaction. Après quoi la frontière s'applique sans exception.

### 4.5 Mode autonome Flutter — supprimé

Flutter cesse d'être une application autonome pour devenir un client de l'API. Périmètre
mesuré : environ 700 lignes et 20 points de couplage.

**Distinction à ne pas manquer** : le mode autonome disparaît, **le cache hors ligne
reste**. L'instance de l'utilisateur est chez lui, derrière un VPN ou un reverse proxy
fragile : elle sera injoignable régulièrement. Supprimer toute tolérance au réseau absent
reviendrait à livrer une app qui affiche une erreur une fois sur cinq.

### 4.6 Contrat d'API — une seule version, plus la détection

Aucune version dans les chemins aujourd'hui. Le préfixe `/v1` est posé maintenant, pendant
que la seule instance existante est sous contrôle : après l'ouverture, préfixer casse
toutes les installations.

Mais **le versioning n'est pas le vrai sujet**. Servir deux contrats en parallèle
doublerait une partie des tests d'intégration de l'API — cela n'arrivera pas. Ce qu'il faut, c'est que
le client sache à quoi il parle : un endpoint `/api/meta` public et non versionné, appelé
au démarrage, qui permet d'afficher « votre serveur est trop ancien » au lieu d'une erreur
de désérialisation incompréhensible.

La compatibilité repose ensuite sur trois règles d'écriture : jamais retirer ni renommer un
champ de réponse, jamais rendre obligatoire un champ qui ne l'était pas, un changement de
contrat passe par un nouvel endpoint.

### 4.7 Alimentation des données — profils d'import communautaires

L'agrégation étant écartée, le besoin « ne pas saisir à la main » trouve sa réponse dans
l'import de relevés.

État réel : `ImportProfileRegistry` ne contient **qu'un seul profil** — Société Générale —
codé en dur en Java. Les 28 autres banques ont un logo, pas de profil. Pour en ajouter une,
il faut aujourd'hui écrire du Java, compiler, publier une release. Seul le mainteneur peut
le faire, et avec 28 banques, cela n'arrivera pas.

**Un profil devient une donnée, pas du code** : un fichier par banque, douze champs,
chargé au démarrage. Trois conséquences : contribuer ne demande plus d'être développeur, la
validation devient automatisable via un CSV d'exemple, et un self-hoster peut déposer son
profil sans forker ni attendre une release.

C'est la seule surface du projet où quelqu'un peut apporter de la valeur **sans rien
comprendre à l'architecture** — la porte d'entrée qui transforme des utilisateurs en
contributeurs.

**Piège à cadrer dès le premier jour** : demander des CSV d'exemple conduira des
contributeurs à pousser leurs vrais relevés dans un dépôt public. Fixtures synthétiques
obligatoires, modèle de PR avec confirmation explicite, vérification systématique avant
merge. Sur un projet de finances personnelles, une fuite de ce type coûterait la
crédibilité entière.

*Alternative gardée en réserve* : un connecteur où l'utilisateur apporte ses propres clés
d'agrégateur (modèle Firefly III / Actual Budget). Écarté tant que le projet est maintenu
seul : les connecteurs bancaires sont ce qui casse le plus souvent, et ils ne servent pas
la zone qui différencie le projet.

### 4.8 Langues — anglais par défaut, français à parité

Paradoxe à tenir : la communauté qui découvre le projet est anglophone, mais la
différenciation est francophone.

L'anglais est la langue par défaut de l'interface et de la vitrine — sans quoi le projet
est invisible sur les canaux où il se fait connaître. Le français est traité comme langue
de premier rang et **n'est jamais en retard**.

L'API, elle, ne se traduit pas : elle émet des codes d'erreur — le catalogue existe déjà
depuis l'unification des erreurs — et chaque client en affiche une traduction locale. Cela
évite un quatrième catalogue et la gestion d'`Accept-Language`.

Côté Angular, l'i18n doit être chargée à l'exécution : une compilation par langue
obligerait à publier une image Docker par langue, ce qui est incompatible avec le
self-host.

### 4.9 Distribution — installation en cinq minutes

`docker compose up -d` et ça marche, PostgreSQL incluse. C'est le standard de facto des
concurrents et la condition d'entrée sur ce marché.

Trois règles : publier sur GHCR en référence (Docker Hub limite les téléchargements
anonymes, et les self-hosters téléchargent anonymement) ; **ne jamais recommander `latest`**
dans la documentation, car en self-host on épingle une version ; **ne pas recommander
Watchtower** à la communauté — une migration Flyway qui échoue à trois heures du matin chez
un inconnu est un ticket indiagnostiquable.

## 5. Séquencement

| Jalon | Contenu | Pourquoi à ce moment |
|---|---|---|
| **P1** | Défauts bloquants + révision de la constitution | Deux défauts touchent déjà la production ; la constitution conditionne formellement le reste |
| **P2** | Contrat d'API | Seul chantier impossible à rattraper après l'ouverture |
| **P3** | Cadre juridique | Sans licence, rien n'est open source même publié |
| **P4** | Installation tout-en-un, puis **ouverture du dépôt** | Il faut que ça s'installe avant que quiconque essaie |
| **P5** | Internationalisation | Le poste le plus lourd |
| **P6** | Profils communautaires | Demande des contributeurs, donc de la visibilité |
| **P7** | Frontière Angular / Flutter | Peut avancer en parallèle |
| **P8** | Stores et **annonce publique** | L'annonce ne se fait qu'une fois |

**Règle structurante : ouvrir n'est pas annoncer.** Le dépôt devient public dès P4, sans
communication — cela ne coûte rien et permet de roder l'installation et le processus de
contribution. L'annonce publique attend P8 : elle ne se fait qu'une fois, et un projet mal
reçu au premier contact n'a pas de seconde chance.

Échéance visée : **fin décembre 2026**.

## 6. Risques

**L'i18n est le principal risque sur l'échéance.** Environ 78 000 lignes de français codé
en dur sur trois composants, pour 600 à 900 chaînes uniques après dédoublonnage. C'est un
travail long, peu gratifiant, et qui bloque l'annonce.

**Le support est le risque sur la durée.** Ouvrir au public, c'est ouvrir un canal de
support. Le modèle self-host limite l'exposition — pas d'incident de service à gérer — mais
les questions d'installation, de réseau et de certificats arriveront.

**L'app payante face au public visé.** La communauté self-hosted est la plus réticente au
propriétaire payant. Le code ouvert et la présence sur F-Droid désamorcent l'essentiel de
l'objection, mais elle sera formulée.

**La concurrence installée.** Firefly III et Actual Budget ont une avance considérable en
notoriété. Le pari est la niche francophone, pas la comparaison frontale.

## 7. Ce qui n'est pas décidé

- Le devenir du cache hors ligne Flutter une fois Drift retiré — à trancher **avant** de
  commencer la suppression, pas après.
- Le prix de l'application sur les stores.
- La politique d'acceptation des langues communautaires (seuil minimal de complétude avant
  activation).
- Le sort des répertoires `.specify/` et `.devflow/` une fois le dépôt public.
- Le passage éventuel en open core, si une traction inattendue apparaissait. L'accord de
  contribution est précisément ce qui garde cette porte ouverte.

## 8. Références

- Règles opposables : [`.specify/memory/constitution.md`](../.specify/memory/constitution.md) v4.0.0
- Backlog d'exécution : projet **Budget** dans Linear, jalons P1 à P8 (KKS-307 → KKS-340)
- Dettes techniques connues : [`dette-technique.md`](dette-technique.md)
- Vision fonctionnelle : [`vision.md`](vision.md)
