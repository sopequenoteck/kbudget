// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

enum TextScale {
  small,
  medium,
  large;

  double get scaleFactor => switch (this) {
        TextScale.small => 0.85,
        TextScale.medium => 1.0,
        TextScale.large => 1.3,
      };

  String get label => switch (this) {
        TextScale.small => 'Petit',
        TextScale.medium => 'Normal',
        TextScale.large => 'Grand',
      };
}
