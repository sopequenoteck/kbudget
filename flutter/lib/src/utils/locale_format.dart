// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// The `intl` locale identifier for [locale] (`fr` -> `fr_FR`, `en` ->
/// `en_GB`), for use with `NumberFormat` and `DateFormat`.
String intlLocaleFor(Locale locale) => switch (locale.languageCode) {
      'en' => 'en_GB',
      _ => 'fr_FR',
    };

/// Formate un taux de change pour [intlLocale] : 0 a 6 decimales, comme le
/// pipe Angular `number: '1.0-6'` (`655,957` et `1,1` en francais).
String formatRate(double rate, String intlLocale) =>
    (NumberFormat.decimalPattern(intlLocale)
          ..minimumFractionDigits = 0
          ..maximumFractionDigits = 6)
        .format(rate);
