## Ce que fait cette PR

<!-- Une ou deux phrases. Le detail va dans les commits. -->

## Compatibilite d'API

Ne cocher que si la PR touche l'API, ses DTOs, une migration Flyway ou le
parsing cote client. Les regles sont dans
[`docs/api-compatibility.md`](../docs/api-compatibility.md).

- [ ] Aucun champ de reponse retire ou renomme — on ajoute, on ne retire pas
- [ ] Aucun champ de requete devenu obligatoire
- [ ] Les migrations Flyway n'invalident aucune reponse deja servie
- [ ] Les nouvelles valeurs d'enum sont tolerees par les clients anciens
- [ ] **Si rupture assumee** : `minClientVersion` relevee, note de migration
      dans le `CHANGELOG`, version majeure

> Une seule version d'API est servie a la fois. La compatibilite descendante ne
> repose sur aucun mecanisme, seulement sur cette relecture.

## Verifications

- [ ] Tests passes sur les stacks touchees
- [ ] Documentation mise a jour si le comportement change
- [ ] Version incrementee dans les **quatre** fichiers si c'est une release
      (`VERSION`, `api/pom.xml`, `app/package.json`, `flutter/pubspec.yaml`)
