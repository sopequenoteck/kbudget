// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

extension EnumByNameSafe<T extends Enum> on Iterable<T> {
  T byNameOrDefault(String name, T defaultValue) {
    for (final value in this) {
      if (value.name == name) return value;
    }
    return defaultValue;
  }
}
