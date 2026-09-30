// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/features/settings/application/display_locale_provider.dart';

/// Pins the display language, French by default.
///
/// The test binding announces `en_US`: without this override, the texts
/// built by notifiers through `appLocalizationsProvider` would switch to
/// English, and the language notifier would read the device storage.
Override displayLocaleOverride([Locale locale = const Locale('fr')]) =>
    displayLocaleProvider.overrideWithValue(locale);
