# Politique de compatibilite d'API

k-budget ne sert **qu'une seule version d'API a la fois** (KKS-313). Le prefixe
`/api/v1` existe pour que les clients detectent une incompatibilite, pas pour
maintenir deux contrats en parallele : maintenir `/v1` et `/v2` doublerait une
partie des tests d'API pour une personne seule.

La consequence est directe : **la compatibilite descendante ne repose sur aucun
mecanisme, seulement sur une discipline d'ecriture.** Ce document l'enonce.

Le contexte qui la rend necessaire : en self-host, l'application mobile se met a
jour toute seule via les stores, tandis que le serveur de chaque utilisateur
reste sur la version qu'il a bien voulu deployer. Un client recent parle donc
regulierement a un serveur ancien, et l'inverse. Sans discipline, cela se
manifeste par une erreur de deserialisation chez quelqu'un qui n'a aucun moyen
de comprendre ce qui se passe.

---

## Les six regles

### 1. Ne jamais retirer ni renommer un champ de reponse

On ajoute, on ne retire pas. Un champ devenu inutile est **marque deprecie dans
la documentation et continue d'etre servi**.

Un client ancien qui ne connait pas un nouveau champ l'ignore : ajouter est
toujours sur. Retirer casse tout client qui le lisait, et renommer revient a
retirer puis ajouter.

```java
// NON — casse tout client qui lit `montant`
public record TransactionResponse(BigDecimal amount) {}

// OUI — `montant` reste servi, `amount` s'ajoute
public record TransactionResponse(
        /** @deprecated depuis 6.2.0, utiliser {@code amount}. Toujours servi. */
        BigDecimal montant,
        BigDecimal amount) {}
```

### 2. Ne jamais rendre obligatoire un champ de requete qui ne l'etait pas

Un nouveau champ obligatoire casse **tous** les clients anterieurs d'un coup :
ils ne l'envoient pas, leurs requetes deviennent invalides.

Un nouveau champ de requete est donc optionnel, avec une valeur par defaut cote
serveur. S'il doit devenir obligatoire, cela releve de la regle 6.

```java
// NON — @NotNull sur un champ ajoute apres coup
public record TransactionRequest(@NotNull String currency) {}

// OUI — optionnel, defaut cote serveur
public record TransactionRequest(String currency) {}  // null -> devise du compte
```

### 3. Un changement de contrat passe par un nouvel endpoint

Quand la forme d'une reponse ou la semantique d'une operation doit changer au
point que les regles 1 et 2 ne suffisent plus, on **cree un endpoint** plutot
que de modifier l'existant. L'ancien continue de servir les clients anciens.

C'est le seul moyen de faire evoluer un contrat sans version d'API multiple.

### 4. Une migration Flyway ne doit jamais invalider une reponse deja servie

Le schema de base n'est pas le contrat, mais il le determine. Une colonne
supprimee ou renommee se propage jusqu'a la reponse.

Avant d'ecrire une migration, verifier ce qu'elle change dans les DTOs :

| Migration | Effet sur le contrat |
|-----------|----------------------|
| Ajouter une colonne nullable | Sans effet, sur |
| Ajouter une colonne `NOT NULL` avec defaut | Sans effet sur les lectures |
| Renommer une colonne | **Interdit** si elle alimente un champ de reponse — ajouter la nouvelle, alimenter les deux, retirer l'ancienne apres la regle 6 |
| Supprimer une colonne | **Interdit** si elle alimente un champ de reponse |
| Changer un type | A traiter comme une suppression suivie d'un ajout |

### 5. Un client doit tolerer une valeur d'enum qu'il ne connait pas

Un serveur plus recent peut renvoyer une valeur d'enum absente du client. Un
parsing strict leve une exception ; un parsing tolerant l'ignore et continue.

Le reflexe existe deja cote Flutter, dans
[`app_config.dart`](../flutter/lib/src/domain/models/app_config.dart) — c'est le
modele a generaliser :

```dart
Feature? _decodeFeature(dynamic raw) {
  if (raw == null) return null;
  final key = raw.toString();
  return _featureJsonValues[key] ??
      Feature.values.where((f) => f.name == key).firstOrNull;
}

List<Feature> _safeParseEnabledFeatures(dynamic json) {
  if (json == null) return const [Feature.subscriptions, Feature.debts];
  if (json is! List) return const [Feature.subscriptions, Feature.debts];
  return json.map(_decodeFeature).whereType<Feature>().toList();
}
```

Trois proprietes a retenir : une valeur inconnue devient `null` plutot que de
lever, `whereType` la retire de la liste, et un cas degenere (`null`, type
inattendu) retombe sur un defaut explicite plutot que sur une liste vide
silencieuse.

Le champ `capabilities` de `/api/meta` suit la meme logique : il est expose et
consomme comme une liste de chaines, jamais comme un enum type, precisement pour
qu'un client ancien puisse ignorer une capacite qu'il ne connait pas.

### 6. Une rupture inevitable est assumee, jamais subie

Quand aucune des regles precedentes ne permet l'evolution, la rupture est
possible — mais elle se declare. La procedure est detaillee ci-dessous.

---

## Proceder a une rupture assumee

Une rupture est un changement qu'un client ancien ne peut pas absorber. Elle
impose quatre gestes, dans cet ordre.

### 1. Relever `minClientVersion`

La property `MIN_CLIENT_VERSION` fixe la version de client la plus ancienne
acceptee, exposee par `GET /api/meta` (KKS-314).

| Endroit | Quoi |
|---------|------|
| `api/src/main/resources/application.yaml` | `app.meta.min-client-version`, defaut du projet |
| `.env.example`, `docker-compose.yml` | Variable `MIN_CLIENT_VERSION`, surchargeable par instance |
| `docs/deployment.md` | Tableau des variables d'environnement |

**Elle ne bouge qu'ici, jamais a chaque release.** La relever est le signal d'une
rupture ; le faire par reflexe la banaliserait.

### 2. Verifier `MIN_SERVER_VERSION` cote clients

Constante symetrique : la version de serveur la plus ancienne que le client sait
exploiter.

- Angular — [`compatibility.ts`](../app/src/app/core/services/compatibility.ts)
- Flutter — [`compatibility_service.dart`](../flutter/lib/src/data/remote/compatibility_service.dart)

Si la rupture vient du serveur, c'est cette constante qui monte, pas
`minClientVersion`.

### 3. Publier une note de migration

Une entree `CHANGELOG.md` sous `### Changed`, prefixee **BREAKING**, indiquant
ce qui change, qui est affecte, et ce qu'un self-hoster doit faire. La release
prend un numero **majeur** (semver).

Precedent a suivre : la [6.0.0](../CHANGELOG.md), qui a prefixe les endpoints en
`/api/v1`.

### 4. Verifier ce que voit l'utilisateur

Les deux clients affichent un ecran dedie, jamais une erreur technique. La
formulation est portee par
[`server_meta.dart`](../flutter/lib/src/domain/models/server_meta.dart) cote
Flutter et par [`meta.model.ts`](../app/src/app/core/models/meta.model.ts) cote
Angular.

Un point a ne pas perdre : **un serveur injoignable n'est pas un serveur
incompatible.** Une reponse 404 signifie un serveur trop ancien ; une absence de
reponse signifie hors ligne, et le cache prend le relais (constitution,
principe IV). Confondre les deux afficherait « mettez votre serveur a jour » a
quelqu'un simplement coupe du reseau.

---

## Avant de merger

Ces questions figurent dans le
[template de PR](../.github/pull_request_template.md) :

- [ ] Aucun champ de reponse retire ou renomme
- [ ] Aucun champ de requete devenu obligatoire
- [ ] Les migrations Flyway n'invalident aucune reponse servie
- [ ] Les nouvelles valeurs d'enum sont tolerees par les clients anciens
- [ ] Si rupture : `minClientVersion` relevee, note de migration ecrite, version majeure

---

## Ce que ce document ne couvre pas

**Les regles 1 et 2 sont verifiees automatiquement** par
[`ApiContractIT`](../api/src/test/java/fr/kksdev/budget/api/contract/ApiContractIT.java)
(KKS-350). Le test recupere le schema OpenAPI expose par springdoc
(`GET /v3/api-docs`), en extrait une projection — champs de reponse d'un cote,
champs de requete devenus obligatoires de l'autre — et la compare a un snapshot
versionne, [`api-contract.txt`](../api/src/test/resources/api-contract.txt).

Les deux sens de comparaison sont inverses : pour les reponses, le snapshot
doit rester inclus dans le contrat courant (un champ du snapshot absent du
courant = champ retire ou renomme, echec) ; pour les requetes, c'est le
courant qui doit rester inclus dans le snapshot (un champ obligatoire du
courant absent du snapshot = nouvelle obligation apparue, echec). Un ajout de
champ de reponse ou un allegement d'une contrainte de requete passent en
silence — ce sont des evolutions legitimes.

Quand une rupture est assumee (regle 6), le snapshot se regenere puis se relit
au diff avant de committer :

```bash
cd api && JAVA_HOME=<jdk21> mvn test -Dtest=ApiContractIT -Dcontract.update=true
```

**Ce que ce snapshot ne couvre pas : les reponses d'erreur.** springdoc ne
documente que les 200 — l'API ne porte aucune annotation `@ApiResponse` sur
les 4xx, et les declarer sur les 100 operations ajouterait plus de mille lignes
repetitives au snapshot pour un signal deja obtenu autrement.

Le contrat de [`api-errors.md`](api-errors.md) est donc tenu par deux tests
distincts (KKS-357) :

- `ValidationErrorCodeContractTest` verrouille les valeurs de
  `details[].code` sur les DTOs et le validateur reels. Ces codes derivent du
  nom de l'annotation qui a echoue et ne sont ecrits nulle part : remplacer
  `@Size` par une autre contrainte de longueur les renommerait sans qu'aucune
  signature ne bouge.
- `ExceptionHandlerInventoryTest` tient un inventaire versionne des handlers
  declares, dans
  [`api-error-handlers.txt`](../api/src/test/resources/api-error-handlers.txt).
  **La comparaison y est stricte dans les deux sens**, a l'inverse du contrat
  de succes : un handler retire fait retomber son exception sur un `500`, un
  handler ajoute sert un code que personne n'a vu passer. Les deux doivent se
  remarquer.

Les codes eux-memes restent verifies par les tests de leurs emetteurs
(`GlobalExceptionHandlerTest` et les tests des filtres de securite).

---

## Voir aussi

| Document | Contenu |
|----------|---------|
| [`api-examples.md`](api-examples.md) | Versionnement des chemins, contrat de `GET /api/meta` |
| [`api-errors.md`](api-errors.md) | Format des erreurs, matrice des cas geres |
| [`deployment.md`](deployment.md) | `MIN_CLIENT_VERSION` et les autres variables |
| [`.specify/memory/constitution.md`](../.specify/memory/constitution.md) | Principe I — API-First. Fait autorite |
