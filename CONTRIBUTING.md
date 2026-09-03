# Contribuer a k-budget

Merci de l'interet porte au projet.

> Ce document est en francais. Sa traduction anglaise fait partie de KKS-319,
> avec le reste des fichiers de gouvernance.

## Accord de contribution (CLA)

**Toute pull request doit etre couverte par le [CLA](CLA.md).** Une
verification automatique le rappelle a l'ouverture de votre premiere PR : il
suffit d'y repondre par un commentaire, rien a imprimer ni a envoyer.

```
I have read the CLA Document and I hereby sign the CLA
```

Vous signez une seule fois. Vos contributions suivantes sont couvertes
automatiquement.

### Pourquoi ce projet en demande un

Un CLA est parfois mal percu, parce qu'il autorise le mainteneur a changer la
licence. La reticence est legitime et merite une reponse directe plutot qu'une
ligne dans un formulaire.

k-budget est maintenu par une seule personne. Deux situations rendent la
relicence necessaire en pratique, pas en theorie :

- **Les conditions des stores changent.** `flutter/` est sous MPL-2.0
  precisement parce que les conditions d'Apple sont incompatibles avec l'AGPL :
  VLC a ete retire de l'App Store en 2011 pour cette raison, et n'y est revenu
  qu'apres un changement de licence. Si ces conditions se durcissent encore, le
  projet doit pouvoir reagir.
- **La viabilite.** Garder ouverte l'option d'une offre hebergee sous d'autres
  termes est peut-etre ce qui permettra au projet de continuer d'exister.

Sans CLA, ces deux portes se ferment definitivement des la premiere
contribution externe fusionnee : toute relicence exigerait alors l'accord ecrit
de chaque contributeur, y compris ceux devenus injoignables.

**En echange, le projet s'engage** a ce que vos contributions restent
disponibles sous une licence approuvee par l'Open Source Initiative. Une
relicence peut changer laquelle ; elle ne peut pas les retirer du logiciel
libre. Cet engagement figure dans le [CLA](CLA.md) lui-meme, il n'est pas
qu'une promesse de ce document.

Vous conservez tous vos droits sur vos contributions et restez libre de les
reutiliser comme bon vous semble.

## Les deux licences du depot

Le depot n'est pas sous une licence unique. Verifiez laquelle s'applique a ce
que vous modifiez :

| Repertoire | Licence |
|------------|---------|
| `api/`, `app/` | **AGPL-3.0-only** ([`LICENSE`](LICENSE)) |
| `flutter/` | **MPL-2.0** ([`flutter/LICENSE`](flutter/LICENSE)) |

**Tout nouveau fichier source dans `flutter/lib` doit porter l'en-tete MPL** —
la MPL est un copyleft par fichier, un fichier sans en-tete perd l'information
des qu'il quitte le depot :

```dart
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
```

Le nom « k-budget » et le logo sont reserves et ne sont couverts par aucune de
ces licences. Un fork est libre d'exister, sous un autre nom.

## Avant d'ouvrir une pull request

Le projet suit une constitution — [`.specify/memory/constitution.md`](.specify/memory/constitution.md) —
qui fait autorite sur toute autre documentation. Ses huit principes cadrent ce
qui est accepte, notamment l'isolation des donnees par utilisateur, la
simplicite (pas de CQRS, DDD ni Event Sourcing) et le fait qu'**Angular est le
client de reference** : une feature nait cote Angular, Flutter n'a aucune
obligation de parite.

Les conventions de code, les commandes de build et de test sont dans
[`CLAUDE.md`](CLAUDE.md).

### Verifications attendues

| Stack | Commandes |
|-------|-----------|
| API | `cd api && mvn verify` |
| Angular | `cd app && npm test && npx ng lint` |
| Flutter | `cd flutter && flutter analyze && flutter test` |

La CI rejoue ces verifications. Le job **Tests APP (runner GitHub)** tourne sur
l'infrastructure GitHub et non sur le runner prive : c'est celui qui vous
donnera un retour exploitable sur une PR issue d'un fork.

Le [modele de PR](.github/pull_request_template.md) porte une liste de controle
sur la compatibilite d'API. Elle n'est pas decorative : le projet ne sert
**qu'une seule version d'API a la fois**, et la compatibilite descendante ne
repose sur aucun mecanisme automatique. Les six regles sont dans
[`docs/api-compatibility.md`](docs/api-compatibility.md).

## Signaler un probleme

Le suivi se fait sur **Linear**, pas dans les issues GitHub. Ouvrez une
discussion ou une pull request ; le ticket correspondant sera cree cote projet.
