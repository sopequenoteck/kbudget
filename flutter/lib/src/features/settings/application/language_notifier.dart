// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:k_budget/src/data/data_mode_provider.dart';
import 'package:k_budget/src/data/remote/data_sources/preference_remote_data_source.dart';
import 'package:k_budget/src/data/remote/dtos/user_preference_request.dart';
import 'package:k_budget/src/domain/enums/enums.dart';
import 'package:k_budget/src/features/auth/application/auth_notifier.dart';
import 'package:k_budget/src/features/auth/application/auth_state.dart';
import 'package:k_budget/src/features/onboarding/application/onboarding_notifier.dart';
import 'package:k_budget/src/features/settings/application/language_state.dart';

/// Languages the interface is translated into.
const supportedLanguages = ['en', 'fr'];

/// The default and fallback language.
const defaultLanguage = 'en';

/// Native language names, shown as is and never translated.
const languageNativeNames = {'en': 'English', 'fr': 'Français'};

/// Brings any language code (`fr-CA`, `EN`, `pt-BR`) back to a supported
/// language, or `null` when none matches.
String? supportedLanguageOf(String? code) {
  if (code == null || code.isEmpty) {
    return null;
  }
  final base = code.split('-').first.toLowerCase();
  return supportedLanguages.contains(base) ? base : null;
}

/// The first supported language of [locales], else [defaultLanguage].
String detectSystemLanguage(List<Locale> locales) {
  for (final locale in locales) {
    final language = supportedLanguageOf(locale.languageCode);
    if (language != null) {
      return language;
    }
  }
  return defaultLanguage;
}

/// The locales announced by the platform, overridden in tests.
final systemLocalesProvider = Provider<List<Locale>>(
  (ref) => PlatformDispatcher.instance.locales,
);

/// The single source of the displayed language.
final languageNotifierProvider =
    NotifierProvider<LanguageNotifier, LanguageState>(LanguageNotifier.new);

/// Resolves the displayed language, with the same priorities as Angular's
/// `LanguageService` (KKS-380): a non-null preference wins; until the
/// preference is loaded, the language last applied on this device; once it
/// is loaded and null, or in local mode, the system language.
///
/// In server mode, every applied language is stored on the device for the
/// next start. In local mode, the stored language is the preference itself:
/// only an explicit choice writes it, automatic clears it.
///
/// The preference is only written by [selectLanguage], never on its own.
class LanguageNotifier extends Notifier<LanguageState> {
  var _systemLanguage = defaultLanguage;
  bool _preferenceLoaded = false;

  @override
  LanguageState build() {
    _systemLanguage = detectSystemLanguage(ref.watch(systemLocalesProvider));
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated && previous is! AuthAuthenticated) {
        unawaited(_loadServerPreference());
      }
    });
    unawaited(_load());
    return LanguageState(language: _systemLanguage);
  }

  Future<void> _load() async {
    try {
      final mode = await ref.read(dataModeProvider.future);
      final stored = supportedLanguageOf(
        await ref.read(appConfigRepositoryProvider).getLanguage(),
      );
      if (mode == DataMode.local) {
        state = LanguageState(
          language: stored ?? _systemLanguage,
          preference: stored,
        );
        return;
      }
      if (stored != null && !_preferenceLoaded) {
        state = state.copyWith(language: stored);
      }
      if (ref.read(authNotifierProvider) is AuthAuthenticated) {
        await _loadServerPreference();
      }
    } on Exception catch (_) {
      // Keep the system language — nothing stored could be read
    }
  }

  Future<void> _loadServerPreference() async {
    try {
      if (await ref.read(dataModeProvider.future) != DataMode.server) {
        return;
      }
      final dataSource =
          await ref.read(preferenceRemoteDataSourceProvider.future);
      final prefs = await dataSource.getPreferences();
      _preferenceLoaded = true;
      final preference = supportedLanguageOf(prefs.language);
      state = LanguageState(
        language: preference ?? _systemLanguage,
        preference: preference,
      );
      await _remember(state.language);
    } on Exception catch (_) {
      // Keep the current language — the server is unreachable
    }
  }

  /// Applies [language] chosen in the settings, `null` for automatic.
  ///
  /// In server mode the choice is written to the server — `DELETE` for
  /// automatic — and a failed write restores the previous choice without a
  /// message, as Angular does. In local mode it is stored on the device.
  Future<void> selectLanguage(String? language) async {
    final previous = state;
    if (previous.preference == language) {
      return;
    }
    state = LanguageState(
      language: language ?? _systemLanguage,
      preference: language,
    );
    try {
      final mode = await ref.read(dataModeProvider.future);
      if (mode == DataMode.server) {
        await _writeServerPreference(language);
        _preferenceLoaded = true;
        await _remember(state.language);
      } else {
        await ref.read(appConfigRepositoryProvider).setLanguage(language);
      }
    } on Exception catch (_) {
      state = previous;
    }
  }

  Future<void> _writeServerPreference(String? language) async {
    final dataSource =
        await ref.read(preferenceRemoteDataSourceProvider.future);
    if (language == null) {
      await dataSource.clearLanguage();
      return;
    }
    final prefs = await dataSource.getPreferences();
    await dataSource.updatePreferences(
      UserPreferenceRequest(
        enabledFeatures: prefs.enabledFeatures,
        language: language,
      ),
    );
  }

  Future<void> _remember(String language) async {
    try {
      await ref.read(appConfigRepositoryProvider).setLanguage(language);
    } on Exception catch (_) {
      // The next start falls back to the system language
    }
  }
}
