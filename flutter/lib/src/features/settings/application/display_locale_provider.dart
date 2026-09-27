// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/utils/locale_format.dart';

/// The locale used to display the interface.
///
/// Fixed to French until the language preference (KKS-405) is wired in.
/// Tests that need another locale override it in `ProviderScope.overrides`.
final displayLocaleProvider = Provider<Locale>((ref) => const Locale('fr'));

/// The `intl` locale identifier derived from [displayLocaleProvider], for
/// `NumberFormat` and `DateFormat` (`fr` -> `fr_FR`, `en` -> `en_GB`). See
/// [intlLocaleFor].
final intlLocaleProvider = Provider<String>((ref) {
  return intlLocaleFor(ref.watch(displayLocaleProvider));
});
