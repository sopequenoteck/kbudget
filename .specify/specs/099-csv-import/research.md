# Research: Import de releves bancaires CSV

**Branch**: `099-csv-import` | **Date**: 2026-03-20

## R1 — CSV Parsing Library

**Decision**: Apache Commons CSV (`commons-csv:1.11.0`)

**Rationale**: Leger, sans dependances transitives, API intuitive pour parser des CSV avec separateur configurable, detection d'en-tetes, et support des encodages. Jackson CSV est deja sur le classpath via Spring Boot mais son API orientee bean-mapping est moins adaptee au parsing exploratoire (detection auto de colonnes, preview des premieres lignes).

**Alternatives considered**:
- Jackson CSV : deja present (zero cout), mais API moins flexible pour le parsing exploratoire et le mapping dynamique de colonnes
- OpenCSV : plus riche (bean mapping), mais plus lourd et dependances transitives inutiles
- Implementation manuelle : fragile face aux edge cases CSV (guillemets, retours a la ligne dans les valeurs)

## R2 — String Similarity for Deduplication

**Decision**: Apache Commons Text (`commons-text:1.12.0`) avec `JaroWinklerSimilarity`

**Rationale**: Jaro-Winkler est optimise pour les noms courts (commercants) et donne un score normalise [0,1] facilement comparable a un seuil. Seuil recommande : **0.85** (capture les variations comme "CARREFOUR" vs "CARREFOUR CITY" tout en evitant les faux positifs). Levenshtein serait moins adapte car la distance absolue depend de la longueur des chaines.

**Alternatives considered**:
- Levenshtein (Commons Text) : distance absolue, necessite normalisation manuelle
- Implementation manuelle : faisable mais risque de bugs subtils
- Trigram / n-gram : trop lourd pour ce volume de donnees

## R3 — File Upload Strategy

**Decision**: Multipart file upload (`MultipartFile`) avec configuration Spring Boot

**Rationale**: Le CSV peut aller jusqu'a 5 Mo. L'envoi en base64 dans le body JSON gonflerait la taille de ~33% et compliquerait le parsing streaming. Multipart est le standard HTTP pour l'upload de fichiers et Spring Boot le supporte nativement. C'est la premiere utilisation de multipart dans le projet mais c'est justifie par la nature du fichier (texte brut, taille variable).

**Configuration requise** (`application.yaml`):
```yaml
spring:
  servlet:
    multipart:
      max-file-size: 5MB
      max-request-size: 6MB
```

**Alternatives considered**:
- Base64 en JSON body : pattern existant (images produits), mais inadapte aux fichiers > 1 Mo et au parsing streaming
- Lecture cote client + envoi du contenu texte : double parsing (client + serveur), augmente la complexite frontend

## R4 — Batch Transaction Creation

**Decision**: Nouveau endpoint `POST /imports/{draftId}/confirm` qui cree les transactions via `transactionRepository.saveAll()` dans une `@Transactional`

**Rationale**: Pas d'endpoint batch existant. La creation en masse est liee a la confirmation d'un brouillon, pas a un endpoint generique de transactions. L'encapsuler dans le flow d'import (via ImportService) est plus coherent que d'exposer un `POST /transactions/batch` generique (YAGNI).

**Alternatives considered**:
- `POST /transactions/batch` generique : sur-ingenierie, seul l'import en a besoin
- Boucle `save()` unitaire : moins performant que `saveAll()`, meme semantique transactionnelle

## R5 — Import Profile Architecture

**Decision**: Classe statique `ImportProfileRegistry` (pattern identique a `BankRegistry`) + entite `ImportProfile` pour les profils personnalises

**Rationale**: Les profils pre-configures (SG, BNP, etc.) sont des constantes connues a l'avance — une map statique est le pattern existant du projet (cf. `BankRegistry`). Les profils personnalises necessitent une persistance BDD. La resolution se fait en cascade : bankCode du compte → registry statique → profils custom de l'utilisateur → fallback analyse contenu CSV → mapping manuel.

**Alternatives considered**:
- Tout en BDD (y compris pre-configures) : complexifie le seeding et les migrations pour des donnees immuables
- Tout statique (pas de custom) : trop limitant, la spec exige des profils personnalises

## R6 — Draft Cleanup Job

**Decision**: `@Scheduled(cron = "0 0 3 * * *")` dans un `ImportDraftCleanupJob` (ou directement dans `ImportService`)

**Rationale**: Pattern identique a `NotificationScheduler` — job quotidien a 3h du matin, boucle sur les users, suppression des brouillons expires. Heure choisie pour eviter les heures de pointe (6h et 8h deja prises par les jobs existants).

**Alternatives considered**:
- TTL en BDD (PostgreSQL pg_cron) : dependance infra supplementaire, viole le principe Self-Hosted Ready
- Verification lazy (a l'acces) : les brouillons expires resteraient en BDD indefiniment

## R7 — Label Cleaning Strategy

**Decision**: Pipeline de regles regex configurables par profil d'import

**Rationale**: Chaque banque a ses propres patterns de bruit dans les libelles (SG : prefixes CARTE, suffixes IOPD, numeros de reference ; BNP : prefixes VIR, etc.). Un pipeline de regles regex par profil permet de personnaliser le nettoyage par banque tout en ayant des regles generiques en fallback (trim, collapse whitespace, suppression numeros > 6 digits).

**Pipeline type** :
1. Regles specifiques au profil (ex: SG → supprimer `CARTE X\d{4} \d{2}/\d{2}`, `\d{15,}IOPD`, `UEP\*`)
2. Regles generiques (supprimer numeros de reference > 6 digits contigus, trim, collapse espaces multiples)
3. Guard : si resultat vide → conserver le libelle original

**Alternatives considered**:
- Nettoyage unique global : ne capture pas les specificites de chaque banque
- NLP / ML : sur-ingenierie pour ce volume et cette complexite

## R8 — Deduplication Query Strategy

**Decision**: Requete `findByUserIdAndAccountIdAndDateBetween` + comparaison en memoire

**Rationale**: Le pattern `findBy...DateBetween` existe deja dans `TransactionRepository`. La fenetre est la plage de dates du CSV ± 3 jours de marge. Le volume est faible (quelques centaines de transactions max sur une plage de 1-3 mois) — la comparaison Jaro-Winkler en memoire est instantanee. Pas besoin d'index full-text ou de fonctions SQL de similarite.

**Alternatives considered**:
- Fonction SQL `similarity()` (pg_trgm) : dependance PostgreSQL extension, complexifie le deploiement
- Index composite unique : trop rigide pour le matching flou du libelle

## R9 — Angular Settings Integration

**Decision**: Nouvelle route `/settings/import` dans le groupe `management`, composant lazy-loaded `ImportSettings`

**Rationale**: Le pattern existant (`settings.routes.ts` + `SECTIONS` array dans `settings.ts`) est clair. Le groupe `management` (aux cotes de `data`, `currencies`) est le plus logique. Le composant sera un hub avec 3 sections : brouillons en cours, historique, regles de categorisation.

## R10 — Encoding Detection

**Decision**: Detection basee sur le profil d'import (champ `encoding`) avec fallback `UTF-8`

**Rationale**: Les banques francaises utilisent principalement ISO-8859-1 (SG, BNP) ou UTF-8. Le profil pre-configure de chaque banque specifie l'encodage. Pour les profils custom ou inconnus, on tente UTF-8 par defaut. Si le parsing echoue (caracteres invalides), on retente en ISO-8859-1. Pas de detection automatique complexe (ICU4J) — les 2 encodages couvrent 99% des cas.

**Alternatives considered**:
- ICU4J charset detection : sur-ingenierie, ajoute une dependance lourde (~8 Mo)
- Toujours UTF-8 : echouerait sur les CSV SG en ISO-8859-1
