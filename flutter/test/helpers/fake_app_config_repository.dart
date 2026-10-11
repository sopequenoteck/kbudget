// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/domain/models/app_config.dart';
import 'package:k_budget/src/domain/repositories/app_config_repository.dart';

/// An in-memory [AppConfigRepository] that only knows `getConfig` and
/// `saveConfig`, which is all the app lock uses. It counts reads and writes
/// and can fail or hold them back.
class FakeAppConfigRepository extends Fake implements AppConfigRepository {
  /// Creates the repository holding [config].
  FakeAppConfigRepository([this.config = const AppConfig()]);

  /// The stored configuration.
  AppConfig config;

  /// Number of `getConfig` calls.
  var reads = 0;

  /// Number of `saveConfig` calls.
  var writes = 0;

  /// Makes `getConfig` throw.
  Object? readError;

  /// Makes `saveConfig` throw.
  Object? writeError;

  /// When set, `saveConfig` waits for it before storing.
  Completer<void>? writeGate;

  /// Completers that the next `saveConfig` calls wait for, one each, in order.
  final writeGateQueue = <Completer<void>>[];

  /// When set, `getConfig` waits for it before answering.
  Completer<void>? readGate;

  @override
  Future<AppConfig> getConfig() async {
    reads++;
    await readGate?.future;
    final error = readError;
    if (error != null) {
      throw error;
    }
    return config;
  }

  @override
  Future<void> saveConfig(AppConfig config) async {
    writes++;
    final error = writeError;
    if (error != null) {
      throw error;
    }
    if (writeGateQueue.isNotEmpty) {
      await writeGateQueue.removeAt(0).future;
    }
    await writeGate?.future;
    this.config = config;
  }
}
