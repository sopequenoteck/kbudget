// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/features/settings/application/language_notifier.dart';
import 'package:k_budget/src/localization/app_localizations.dart';
import 'package:k_budget/src/utils/locale_format.dart';

/// The locale used to display the interface.
///
/// Derived from [languageNotifierProvider]. Tests that need a fixed locale
/// override it in `ProviderScope.overrides`.
final displayLocaleProvider = Provider<Locale>(
  (ref) => Locale(
    ref.watch(languageNotifierProvider.select((state) => state.language)),
  ),
);

/// The `intl` locale identifier derived from [displayLocaleProvider], for
/// `NumberFormat` and `DateFormat` (`fr` -> `fr_FR`, `en` -> `en_GB`). See
/// [intlLocaleFor].
final intlLocaleProvider = Provider<String>(
  (ref) => intlLocaleFor(ref.watch(displayLocaleProvider)),
);

/// The translations for [displayLocaleProvider], for code that has no
/// `BuildContext` — a `Notifier`, a repository — and therefore cannot call
/// `AppLocalizations.of(context)`.
final appLocalizationsProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(ref.watch(displayLocaleProvider)),
);
