// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

const _legacyDatabaseName = 'k_budget.sqlite';

// SQLite peut laisser ces fichiers a cote de la base.
const _legacyDatabaseSuffixes = ['', '-wal', '-shm', '-journal'];

/// Efface la base SQLite de l'ancien mode local (KKS-335).
///
/// Au mieux : un fichier absent, un plugin indisponible ou une erreur
/// d'ecriture ne doivent jamais empecher le demarrage. [directory] permet de
/// cibler un autre dossier que celui des documents de l'application.
Future<void> deleteLegacyLocalDatabase({
  Future<Directory> Function()? directory,
}) async {
  if (kIsWeb) return;
  try {
    final dir = await (directory ?? getApplicationDocumentsDirectory)();
    for (final suffix in _legacyDatabaseSuffixes) {
      final file = File(
        '${dir.path}${Platform.pathSeparator}$_legacyDatabaseName$suffix',
      );
      if (await file.exists()) {
        await file.delete();
      }
    }
  } on Object catch (_) {
    // Best effort: leftover bytes on disk are harmless.
  }
}
