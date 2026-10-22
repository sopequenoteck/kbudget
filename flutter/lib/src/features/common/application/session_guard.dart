// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';

/// Garde de session d'un notifier par compte (KKS-558).
///
/// Riverpod reutilise l'instance du notifier quand `build()` est rejoue a un
/// changement de session : une requete lancee par le compte precedent reprend
/// apres son `await` et ecrirait son resultat dans l'etat du compte suivant.
/// `build()` appelle [watchSession] avec son `ref` (ou [bindSession] si le
/// notifier ne doit pas etre reconstruit) ; chaque methode asynchrone capture
/// [session] avant son premier `await` et abandonne toute ecriture si
/// [isStale] le dit.
///
/// La session est lue sur [AuthNotifier.sessionId], qui avance des que l'etat
/// de session change. Un compteur tenu ici serait en retard : Riverpod differe
/// la reconstruction jusqu'a la prochaine lecture, ferme entre-temps les
/// abonnements poses dans `build()`, et fusionne deconnexion puis connexion en
/// un seul `build()` qui revoit l'etat « authentifie » : comparer l'etat
/// d'authentification ne suffirait pas, il faut un jeton. Le notifier
/// d'authentification est garde plutot que `ref`, dont Riverpod refuse l'usage
/// tant que la reconstruction differee n'a pas eu lieu.
mixin SessionGuard {
  late AuthNotifier _auth;

  /// Lie le notifier a la session dans `build()`, sans l'observer : pour un
  /// notifier qui ne doit pas etre reconstruit au changement de session mais
  /// doit ignorer une reponse d'une session precedente (KKS-562).
  @protected
  void bindSession(Ref<Object?> ref) {
    _auth = ref.read(authNotifierProvider.notifier);
  }

  /// Observe la session dans `build()` : l'etat est reconstruit a chaque
  /// changement et repart vide (KKS-546).
  @protected
  void watchSession(Ref<Object?> ref) {
    bindSession(ref);
    ref.watch(authNotifierProvider);
  }

  /// Jeton de la session courante, a capturer avant un `await`.
  @protected
  int get session => _auth.sessionId;

  /// Vrai si la session a change depuis la capture de [token].
  @protected
  bool isStale(int token) => token != session;
}
