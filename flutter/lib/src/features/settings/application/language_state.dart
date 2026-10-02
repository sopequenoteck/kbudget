// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'language_state.freezed.dart';

/// The displayed language and the language preference behind it.
@freezed
class LanguageState with _$LanguageState {
  /// Creates a state displaying [language], chosen by [preference].
  const factory LanguageState({
    /// The applied language code (`en`, `fr`).
    required String language,

    /// The explicit choice, `null` for automatic.
    String? preference,
  }) = _LanguageState;
}
