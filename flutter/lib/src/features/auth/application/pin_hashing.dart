// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Number of random bytes of a PIN salt.
const pinSaltBytes = 16;

/// Returns a new random salt, as lowercase hexadecimal.
///
/// A new salt is generated each time the PIN is set, so the same PIN never
/// gives the same hash twice. [random] is only replaceable for tests.
String generatePinSalt({Random? random}) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(pinSaltBytes, (_) => source.nextInt(256));
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

/// Returns `sha256(salt + pin)` as lowercase hexadecimal.
///
/// A 4-digit PIN is not protected by its hash: the protection is the secure
/// storage and the limit on wrong entries.
String hashPin(String salt, String pin) =>
    sha256.convert(utf8.encode('$salt$pin')).toString();

/// Compares two strings without stopping at the first difference, so the
/// time taken does not reveal how many leading characters match.
bool constantTimeEquals(String a, String b) {
  final left = utf8.encode(a);
  final right = utf8.encode(b);
  var diff = left.length ^ right.length;
  final longest = max(left.length, right.length);
  for (var i = 0; i < longest; i++) {
    final x = i < left.length ? left[i] : 0;
    final y = i < right.length ? right[i] : 0;
    diff |= x ^ y;
  }
  return diff == 0;
}
