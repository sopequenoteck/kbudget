# Clarify Log — KKS-246

**Date** : 2026-05-27  
**Méthode** : Session interactive (résolutions inline avant review-spec)

---

## Clarification 1 — Toggle notifications si feature désactivée

**Question** : Faut-il griser ou masquer le toggle d'un type de notification si la feature associée est désactivée ?

**Réponse** : **Masquer** — le toggle est entièrement absent si la feature est désactivée.

**Impact sur spec** : FR-017 ajouté. Scénario US4 mis à jour.

---

## Clarification 2 — Stockage version app Flutter

**Question** : Où est stockée la version app côté Flutter (constante, pubspec.yaml, autre) ?

**Réponse** : La version Flutter n'est exposée nulle part dans le code actuellement. Elle est uniquement dans `pubspec.yaml` (`1.0.0+1`). La version Flutter est **indépendante** de la version Angular (`5.0.0`) — Flutter est un produit standalone.

**Décision** : Ajouter `package_info_plus` aux dépendances pour lire la version au runtime depuis `pubspec.yaml`.

**Impact sur spec** : FR-016 ajouté. Assumption mise à jour.
